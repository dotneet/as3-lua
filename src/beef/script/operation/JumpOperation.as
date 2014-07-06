package beef.script.operation {
	import beef.script.ScriptRuntime;

	/**
	 * @author shinji
	 */
	public class JumpOperation extends ScriptOperation {
		public var address:int;
		public function JumpOperation() {
		}
		public override function execute(script:ScriptRuntime):void {
			trace("jump to " + address);
			script.jump(address);
		}
	}
}
