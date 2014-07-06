package beef.script {
	/**
	 * @author shinji
	 */
	public class ScriptError extends Error {
		public function ScriptError(message : * = "", id : * = 0) {
			super(message, id);
		}
	}
}
