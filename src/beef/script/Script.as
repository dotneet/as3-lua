package beef.script {
	import beef.script.expr.Value;
	import beef.script.operation.ScriptOperation;

	import flash.utils.Dictionary;
	/**
	 * @author shinji
	 */
	public class Script {
		protected var mProgramCounter:int = 0;
		protected var mOperations:Vector.<ScriptOperation> = new Vector.<ScriptOperation>();
		protected var mJumpLabels:Dictionary = new Dictionary();
		protected var mFunctions:Dictionary = new Dictionary();
		// 最後に実行された式の結果
		protected var mLastExpressionResult:Value;
		
		public function Script() {
		}
		
		public function set lastExpressionResult(value:Value):void {
			mLastExpressionResult = value;
		}
		public function get lastExpressionResult():Value {
			return mLastExpressionResult;
		}
		
		public function get jumpLabels():Dictionary {
			return mJumpLabels;
		}
		
		public function get operations():Vector.<ScriptOperation> {
			return mOperations;
		}
		
		public function addOperation(ope:ScriptOperation):int {
			return mOperations.push(ope);
		}
		
		public function addJumpLabel(label:String):void {
			mJumpLabels[label] = mOperations.length;
		}
		
		public function lastAddress():int {
			return mOperations.length;
		}
		
		public function dump():void {
			for ( var label:String in mJumpLabels ) {
				trace(label + ":" + mJumpLabels[label]);
			}
			for each ( var ope:ScriptOperation in mOperations ) {
				trace(ope);
			}
		}
	}
}
