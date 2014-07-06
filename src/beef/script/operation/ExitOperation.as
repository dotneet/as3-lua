package beef.script.operation {
	import beef.script.ScriptRuntime;
	import beef.script.operation.ScriptOperation;
	import beef.script.Script;

	/**
	 * スクリプトを終了させる
	 */
	public class ExitOperation extends ScriptOperation {
		public override function execute(script : ScriptRuntime) : void {
			log("exit script");
			script.jump(-1);
		}
	}
}
