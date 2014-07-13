package beef.script.compiler {
	import beef.script.Instruction;
	/**
	 * GOTOのジャンプ先解決に使う情報を格納
	 */
	public class UnresolvedLabelJump extends UnresolvedJump {
		private var mLabel:String;
		public function get label():String {
			return this.mLabel;
		}
		
		public function UnresolvedLabelJump(label:String, inst:Instruction, address:int) {
			super(inst,address);
			if ( label == null ) throw new ArgumentError("label must be not null");
			this.mLabel = label;
		}
	}
}
