package beef.script {
	/**
	 * GOTOのジャンプ先解決に使う情報を格納
	 */
	internal class UnresolvedJump {
		public var label:String;
		public var inst:Instruction;	// JMP Operation
		public var address:int;
		public function UnresolvedJump(label:String, inst:Instruction, address:int) {
			this.label = label;
			this.inst = inst;
			this.address = address;
		}
	}
}
