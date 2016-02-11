package beef.script {
	import flash.utils.getQualifiedClassName;
	import beef.script.expr.BooleanValue;
	import beef.script.expr.NumberValue;
	import beef.script.expr.StringValue;
	import beef.script.expr.Value;
	import beef.script.compiler.UnresolvedLabelJump;

	import flash.utils.Dictionary;
	public class ScriptFunction extends Value {
		// upvalues数
		private var mNumOfUpvalues:int;
		// パラメーター一覧
		private var mParams:Vector.<String> = new Vector.<String>();
		// ローカル変数テーブル TODO:ブロックスコープを表現するためにスタックにしないといけない
		private var mLocals:Vector.<Vector.<String>> = new Vector.<Vector.<String>>();
		// 定数テーブル
		private var mConsts:Vector.<Value> = new Vector.<Value>();
		// 関数テーブル
		private var mFunctions:Dictionary = new Dictionary();
		// ラベルテーブル(GOTOのジャンプ先解決用)
		private var mLabels:Dictionary = new Dictionary();
		private var mUnresolevedGotos:Vector.<UnresolvedLabelJump> = new Vector.<UnresolvedLabelJump>();
		
		private var mInstructions:Vector.<Instruction> = new Vector.<Instruction>();
		
		// 未使用のレジスタ位置
		private var mFreereg:int = 0;
		
		private var mSequenceNumber:int = 0;
		
		public function ScriptFunction(params:Vector.<String>=null, sequenceNumber:int = 0) {
			if ( params != null ) {
				mParams = params;
			}
			mSequenceNumber = sequenceNumber;
			mLocals.push(new Vector.<String>());
			for each ( var name:String in params ) {
				addLocal(name);
			}
		}
		
		public function addInstruction(instruction:Instruction):uint {
			return mInstructions.push(instruction);
		}
		public function addFunction(name:String,func:ScriptFunction):void {
			mFunctions[name] = func;
		}
		public function addLocal(name:String):uint {
			mLocals[mLocals.length - 1].push(name);
			return mFreereg++;
		}
		
		/**
		 *  新しいローカル変数スコープを作成する
		 */
		public function pushLocalScope():void {
			mLocals.push(new Vector.<String>());
		}
		
		/**
		 *  現在のローカル変数スコープを破棄する
		 */
		public function popLocalScope():Vector.<String> {
			mFreereg -= mLocals[mLocals.length - 1].length;
			return mLocals.pop();
		}
		
		public function addConst(value:Value):uint {
			return mConsts.push(value) - 1;
		}
		
		public function addLabel(name:String, addr:int):void {
			mLabels[name] = addr;
		}
		public function addUnresolevedGoto(name:String, addr:int, inst:Instruction):void {
			mUnresolevedGotos.push(new UnresolvedLabelJump(name,inst,addr));
		}
		
		/**
		 * ローカル変数のレジスタ番号を返す。
		 * ローカル変数が存在しない場合は -1
		 */
		public function findLocal(search:String):int {
			var register:int = 0;
			for each ( var scope:Vector.<String> in mLocals ) {
				for each ( var name:String in scope ) {
					if ( name == search ) {
						return register;
					}
					register++;
				}
			}
			return -1;
		}
		
		public function getConst(i:int):Value {
			return mConsts[i];
		}
		public function findConst(v:Value):int {
			for ( var i:int = 0; i < mConsts.length; i++ ) {
				var c:Value = mConsts[i];
				if ( flash.utils.getQualifiedClassName(c) == flash.utils.getQualifiedClassName(v) ) {
					if ( c.asString().value == v.asString().value ) {
						return i;
					}
				}
			}
			return -1;
		}
		
		public function get instructions():Vector.<Instruction> {
			return mInstructions;
		}
		public function get functions():Dictionary {
			return mFunctions;
		}
		
		public function call(runtime:ScriptRuntime, params:Vector.<Value>):Value {
			throw new Error("call()が実装されていません");
		}
		
		public function get lastreg():int {
			return mFreereg - 1;
		}
		public function get freereg():int {
			return mFreereg;
		}
		public function set freereg(f:int):void {
			mFreereg = f;
		}
		
		public function addStackPositon(n:int):int {
			return (mFreereg += n);
		}
		
		public override function asBoolean():BooleanValue {
			return BooleanValue.TRUE;
		}
		
		public override function asNumber():NumberValue {
			return new NumberValue(1);
		}
		
		public override function asString():StringValue {
			return new StringValue("Function()#" + mSequenceNumber);
		}
		
		/** 
		 * GOTOのJMP命令のジャンプ先アドレスの解決を行う
		 * @return 解決できなかったラベルの一覧
		 */
		public function resolveGotoStatement():Vector.<String> {
			// 解決できなかったラベル
			var unresolevedLabels:Vector.<String> = new Vector.<String>();
			for each ( var u:UnresolvedLabelJump in mUnresolevedGotos ) {
				if ( mLabels[u.label] === undefined ) {
					unresolevedLabels.push(u.label);
				} else {
					var toAddr:int = mLabels[u.label];
					u.inst.b = (toAddr - u.address - 1);
				}
			}
			return unresolevedLabels;
		}
		
		public function dump():void {
			trace(dumpStr());
		}
		
		public function dumpStr(depth:int=0):String {
			var s:String = '';
			var idx:String;
			var depthSpace:String = '';
			for ( var i:int = 0; i < depth; i++ ) {
				depthSpace += '    ';
			}
			var idxValue:String = '';
			for ( idx in mLocals ) {
				for ( idxValue in mLocals[idx] ) {
					s += depthSpace + ".local " + mLocals[idx][idxValue] + " : stack " + idx +  " " + idxValue + "\n";
				}
			}
			for ( idx in mConsts ) {
				s += depthSpace + ".const " + mConsts[idx] + " : " + idx + "\n";
			}
			for ( idx in mInstructions ) {
				s += depthSpace + idx + "  " + mInstructions[idx] + "\n";
			}
			for ( var name:String in mFunctions ) {
				s += "\n";
				var f:ScriptFunction = mFunctions[name];
				s += depthSpace + "*FUNCTION:" + name + "\n";
				s += f.dumpStr(depth+1);
			}
			return s;
		}
	}

}


