package beef.script.operation {
	import beef.script.ScriptRuntime;

	/**
	 * @author shinji
	 */
	public class LabelJumpOperation extends ScriptOperation {
		protected var mLabel:String;
		public function LabelJumpOperation(label:String) {
			mLabel = label;
		}
		public override function execute(script:ScriptRuntime):void {
			log("jump to " + mLabel);
		}
	}
}
