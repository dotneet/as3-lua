package beef.script.operation {
	import beef.script.event.ScriptEvent;
	import beef.script.ScriptFunction;
	import beef.script.ScriptRuntime;
	import beef.script.expr.NumberValue;
	import beef.script.expr.Value;

	/**
	 * @author shinji
	 */
	public class FuncCallOperation extends ScriptOperation {
		protected var mName:String;
		protected var mParams:Vector.<Value>;
		
		public function FuncCallOperation(name:String, params:Vector.<Value>) {
			mName = name;
			mParams = params;
		}
		
		public override function execute(runtime:ScriptRuntime):void {
			trace("FuncCallOperation:" + mName);
			var fn:ScriptFunction = runtime.findFunction(mName);
			if ( fn != null ) {
				fn.call(runtime, mParams);
			} else {
				trace("FuncCallOperation: function not found.");
				runtime.dispatchEvent(new ScriptEvent(ScriptEvent.RUNTIME_ERROR));
			}
			runtime.lastExpressionResult = new NumberValue(1);
		}
	}
}
