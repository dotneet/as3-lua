package beef.script {
	import beef.script.expr.NilValue;
	import beef.script.sysfunc.LoadFileFunction;
	import beef.script.event.ScriptEvent;
	import beef.script.expr.BooleanValue;
	import beef.script.expr.NumberValue;
	import beef.script.expr.StringValue;
	import beef.script.expr.Value;
	import beef.script.sysfunc.PrintFunction;
	import beef.script.sysfunc.SystemFunction;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	/**
	 * 
	 * 実装の参考にしたソース: https://code.google.com/p/lufacode/
	 */
	[Event(name="runtime_error", type="beef.script.event.ScriptEvent")]
	[Event(name="finish", type="beef.script.event.ScriptEvent")]
	public class ScriptRuntime extends EventDispatcher {
		/** 未実行 */
		public static const STATE_NOT_RUN:int = 0;
		/** 実行中 */
		public static const STATE_RUNNING:int = 1;
		/** 停止中 */
		public static const STATE_STOP:int = 2;
		/** 終了 */
		public static const STATE_FINISH:int = 3;
		
		protected var mProgramCounter:int = 0;
		protected var mStack:Vector.<Frame> = new Vector.<Frame>();
		protected var mFunctions:Dictionary = new Dictionary();
		protected var mGlobals:Dictionary = new Dictionary();
		// 最後に実行された式の結果
		protected var mLastExpressionResult:Value;
		// print()の出力バッファー
		protected var mPrintBuffer:String = '';
		public function get printBuffer():String {
			return mPrintBuffer;
		}
		
		// 実行状態
		protected var mState:int = STATE_NOT_RUN;
		public function get state():int {
			return mState;
		}
		public function get isStop():Boolean {
			return mState == STATE_STOP;
		}
		
		public function ScriptRuntime():void {
			mGlobals["print"] = new PrintFunction();
			mGlobals["loadfile"] = new LoadFileFunction();
		}
		
		/**
		 * スタックフレームが独立したメモリ空間を共有するScriptRuntimeを作成する。
		 */
		public function createThread():ScriptRuntime {
			var t:ScriptRuntime = new ScriptRuntime();
			t.mGlobals = this.mGlobals;
			t.mFunctions = this.mFunctions;
			return t;
		}
		
		public function get currentFrame():Frame {
			return mStack[mStack.length - 1];
		}
		
		public function get globals():Dictionary {
			return mGlobals;
		}
		
		public function set lastExpressionResult(value:Value):void {
			mLastExpressionResult = value;
		}
		
		public function get lastExpressionResult():Value {
			return mLastExpressionResult;
		}
		
		public function jump(counter:int):void {
			mProgramCounter = counter;
		}
		
		public function addFunction(name:String, fn:ScriptFunction):void {
			mFunctions[name] = fn;
			mGlobals[name] = fn;
		}
		
		public function findFunction(name:String):ScriptFunction {
			return mFunctions[name];
		}
		
		public function appendPrintText(text:String):void {
			mPrintBuffer += text;
		}
		
		public function clearPrintBuffer():void {
			mPrintBuffer = '';
		}
		
		public function execute(chunk:ScriptFunction):void {
			if ( mState != STATE_NOT_RUN && mState != STATE_FINISH ) {
				throw new ScriptError('ScriptRuntime is already running.');
			}
			
			mState = STATE_RUNNING;
			mPrintBuffer = '';
			
			// トップレベルの関数をグローバル変数として登録
			var globalFuncs:Dictionary = chunk.functions;
			for ( var funcName:String in  globalFuncs ) {
				mGlobals[funcName] = globalFuncs[funcName];
			}
			
			var topFrame:Frame = new Frame();
			topFrame.func = chunk;
			mStack.push(topFrame);
			
			run();
		}
		
		private function run():void {
			//try {
				while ( mStack.length > 0 && mState == STATE_RUNNING ) {
					var currentFrame:Frame = mStack[mStack.length - 1];
					var ope:Instruction = currentFrame.func.instructions[ currentFrame.pc++ ];
					executeOperation(ope);
				}
			//} catch (error:Error) {
			//	dispatchEvent(new ScriptEvent(ScriptEvent.RUNTIME_ERROR, error));
			//}
			if ( mState == STATE_RUNNING ) { // stopの場合は完了にしない
				mState = STATE_FINISH;
				dispatchEvent(new ScriptEvent(ScriptEvent.FINISH));
			}
		}
		
		/**
		 * stop()で停止した状態から処理を継続する
		 */
		public function resume():void {
			if ( mState != STATE_STOP ) {
				throw new ScriptError('ScriptRuntime is not stop.');
			}
			mState = STATE_RUNNING;
			run();
		}
		
		/**
		 * 命令の実行を停止して制御を戻す
		 */
		public function stop():void {
			mState = STATE_STOP;
		}
		
		private function executeOperation(ope:Instruction):void {
			var frame:Frame = mStack[mStack.length - 1];
			var name:StringValue;
			
			log("EXEC:" + frame.pc + ":" + ope);
			
			switch( ope.op ) {
				case Instruction.OPE_MOVE:
					frame.register[ope.a] = frame.register[ope.b] == null ? NilValue.INSTANCE : frame.register[ope.b];
					break;
				case Instruction.OPE_LOADK:
					frame.register[ope.a] = frame.func.getConst(ope.b);
					break;
				case Instruction.OPE_LOADBOOL:
					frame.register[ope.a] = (ope.b == 0) ? BooleanValue.FALSE : BooleanValue.TRUE;
					if ( ope.c ) {
						frame.pc++;
					}
					break;
				case Instruction.OPE_LOADNIL:
					for(var nilreg : uint = ope.a;nilreg <= ope.b; nilreg++) {
                    	frame.register[nilreg] = NilValue.INSTANCE;
                    }
					break;
				case Instruction.OPE_GETGLOBAL:
					name = frame.func.getConst(ope.b) as StringValue;
					frame.register[ope.a] = mGlobals[name.value];
					break;
				case Instruction.OPE_SETGLOBAL:
					name = frame.func.getConst(ope.b) as StringValue;
					mGlobals[name.value] = frame.register[ope.a] == null ? NilValue.INSTANCE : frame.register[ope.a];
					break;
				case Instruction.OPE_GETUPVAL:
				case Instruction.OPE_SETUPVAL:
				case Instruction.OPE_GETTABLE:
				case Instruction.OPE_SETTABLE:
					throw new ScriptError('unsupported operation.');
				case Instruction.OPE_ADD:
					frame.register[ope.a] = new NumberValue(resolveRK(frame, ope.b).asNumber().value + resolveRK(frame, ope.c).asNumber().value);
					break;
				case Instruction.OPE_SUB:
					frame.register[ope.a] = new NumberValue(resolveRK(frame, ope.b).asNumber().value - resolveRK(frame, ope.c).asNumber().value);
					break;
				case Instruction.OPE_MUL:
					frame.register[ope.a] = new NumberValue(resolveRK(frame, ope.b).asNumber().value * resolveRK(frame, ope.c).asNumber().value);
					break;
				case Instruction.OPE_DIV:
					frame.register[ope.a] = new NumberValue(resolveRK(frame, ope.b).asNumber().value / resolveRK(frame, ope.c).asNumber().value);
					break;
				case Instruction.OPE_MOD:
					frame.register[ope.a] = new NumberValue(resolveRK(frame, ope.b).asNumber().value % resolveRK(frame, ope.c).asNumber().value);
					break;
				case Instruction.OPE_POW:
					frame.register[ope.a] = new NumberValue(Math.pow(resolveRK(frame, ope.b).asNumber().value, resolveRK(frame, ope.c).asNumber().value));
					break;
				case Instruction.OPE_UNM:
					frame.register[ope.a] = new NumberValue(-resolveRK(frame, ope.b).asNumber().value);
					break;
				case Instruction.OPE_NOT:
					frame.register[ope.a] = new BooleanValue(!resolveRK(frame, ope.b).asBoolean().value);
					break;
				case Instruction.OPE_LEN:
				case Instruction.OPE_CONCAT:
					throw new ScriptError('unsupported operation.');
				case Instruction.OPE_JMP:
					frame.pc += ope.a;
					break;
				case Instruction.OPE_EQ:
                case Instruction.OPE_LT:
                case Instruction.OPE_LE:
					compare(ope, frame);
					break;
                case Instruction.OPE_TEST:
	                var cBool : Boolean = (ope.c == 0 ? false : true);
	                var aBool : Boolean = Value(frame.register[ope.a]).asBoolean().value;
					
	                if ( aBool != cBool ) {
	                    frame.pc++;
	                }
                    break;
				case Instruction.OPE_TESTSET:
					var testsetB:Boolean = Value(frame.register[ope.b]).asBoolean().value;
	                if ( !ope.c && testsetB ) {
	                    frame.pc++;
	                } else if(!testsetB) {
	                    frame.pc++;
	                } else {
	                    frame.register[ope.a] = frame.register[ope.b];
	                }
					break;
				case Instruction.OPE_CALL:
					call(ope, frame);
					break;
				case Instruction.OPE_RETURN:
					var numReturnVals : int = ope.b - 1;
	                var returns : Vector.<Value>;
	                if ( numReturnVals == -1) {
						returns = frame.register.slice(ope.a);
	                } else if(numReturnVals == 0) {
	                    returns = new Vector.<Value>();
	                } else  {
	                    returns = frame.register.slice(ope.a, ope.a + numReturnVals);
	                }
	                
	                mStack.pop();
					
	                if(!mStack.length) {
						return;
	                }
					var finishedFrame:Frame = frame;
	                frame = (mStack[mStack.length - 1] as Frame);
	                
	                for(var regpos : uint = finishedFrame.returnRegister;regpos < finishedFrame.returnRegister + returns.length; regpos++) {
						frame.register[regpos] = returns[regpos - finishedFrame.returnRegister];
	                }
					return;
				default:
					throw new ScriptError('Undefined Instruction: OPE=' + ope.op);
			}
		}
		
		private function compare(ope:Instruction, frame:Frame):void {
			var r:int = resolveRK(frame, ope.b).asNumber().value - resolveRK(frame, ope.c).asNumber().value;
			
			switch ( ope.op ) {
				case Instruction.OPE_EQ:
					if ( (r == 0) != (ope.a == 1) ) {
						frame.pc++;
					}
					break;
				case Instruction.OPE_LT:
					if ( (r < 0) != (ope.a == 1) ) {
						frame.pc++;
					}
					break;
				case Instruction.OPE_LT:
					if ( (r <= 0) != (ope.a == 1) ) {
						frame.pc++;
					}
					break;
			}
		}
		
		private function call(ope:Instruction, frame:Frame):void {
			var params:Vector.<Value>;
			var numParams:int = ope.b - 1;
			if ( numParams == -1 ) {
				params = frame.register.slice(ope.a + 1);
			} else if ( numParams == 0 ) {
				params = new Vector.<Value>();
			} else {
				params = frame.register.slice(ope.a + 1, ope.a + 1 + numParams);
			}
			var fn:ScriptFunction = frame.register[ope.a] as ScriptFunction;
			if ( fn == null ) {
				log("call対象の関数がない");
				throw new ScriptError('存在しない関数の呼び出しが発生しました');
			}
			if ( fn is SystemFunction ) {
				var ret:Value = fn.call(this, params);
				frame.register[ope.a] = ret;
			} else {
				var fr:Frame = new Frame();
				fr.func = fn;
				for ( var i:int = 0; i < params.length; i++ ) {
					fr.register[i] = params[i];
				}
				fr.returnRegister = ope.a;
				fr.returns = ope.c - 1;
				mStack.push(fr);
			}
		}
		
		// RK(n) の解決
		private function resolveRK(frame:Frame, i:int):Value {
			if ( i < Compiler.MAX_STACK ) {
				return frame.register[i];
			} else {
				return frame.func.getConst(i - Compiler.MAX_STACK);
			}
		}
		
		private function log(msg:String):void {
			//trace(msg);
		}
	}
}
