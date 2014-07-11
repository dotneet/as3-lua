package beef.script.expr {
	/**
	 * @author shinji
	 */
	public class Value {
		public function asBoolean():BooleanValue {
			throw new Error("asBoolean()が実装されていません");
		}
		public function asNumber():NumberValue {
			throw new Error("asNumber()が実装されていません");
		}
		public function asString():StringValue {
			throw new Error("asString()が実装されていません");
		}
	}
}
