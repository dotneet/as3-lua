package beef.script.operation {
	import beef.script.ScriptRuntime;
	/**
	 * @author shinji
	 */
	public class ScriptOperation {
		public function execute(script:ScriptRuntime):void {
			throw new Error("ScriptOperation::execute()が実装されていません");
		}
		protected function log(msg:String):void {
			trace(msg);
		}
	}
}
