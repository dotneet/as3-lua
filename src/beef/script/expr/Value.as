package beef.script.expr {
	
	public class Value {
		public function asBoolean():BooleanValue {
			throw new Error("asBoolean() is not implemented.");
		}
		public function asNumber():NumberValue {
			throw new Error("asNumber() is not implemented.");
		}
		public function asString():StringValue {
			throw new Error("asString() is not implemented.");
		}
	}
}
