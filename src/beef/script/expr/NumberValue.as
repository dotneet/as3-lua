package beef.script.expr {
	import beef.script.expr.Value;

	/**
	 * @author shinji
	 */
	public class NumberValue extends Value {
		protected var mValue:Number;
		public function NumberValue(value:Number) {
			mValue = value;
		}
		public function get value():Number {
			return mValue;
		}
		public override function asBoolean():BooleanValue {
			return ( mValue ) ? BooleanValue.TRUE : BooleanValue.FALSE;
		}
		public override function asNumber():NumberValue {
			return this;
		}
		public override function asString():StringValue {
			return new StringValue(mValue.toString());
		}
		public function toString():String {
			return "[NumberVallue " + value + "]";
		}
	}
}
