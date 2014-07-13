package beef.script.sysfunc {
	import beef.script.ScriptRuntime;
	import beef.script.expr.BooleanValue;
	import beef.script.expr.Value;

	public class PrintFunction extends SystemFunction {
		public function PrintFunction() {
			super();
		}
		
		public override function call(runtime:ScriptRuntime, params:Vector.<Value>):Value {
			for each ( var item:Value in params ) {
				runtime.appendPrintText(item.asString().value);
			}
			return BooleanValue.TRUE;
		}
	}
}
