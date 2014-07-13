package beef.script.compiler {
	import beef.script.Instruction;

	public class UnresolvedJump {
		private var mInst : Instruction;
		public function get inst():Instruction {
			return mInst;
		}
		
		// JMP Operation Address
		private var mAddress : int;
		public function get address():int {
			return mAddress;
		}

		public function UnresolvedJump(inst : Instruction, address : int) : void {
			if ( inst == null ) throw new ArgumentError("inst must be not null");
			if ( address < 0 ) throw new ArgumentError("address must be positive numver");
			mInst = inst;
			mAddress = address;
		}
	}
}
