package beef.script.expr {
	/**
	 * @author shinji
	 */
	public class StringValue extends Value {
		protected var mValue:String;
		public function StringValue(value:String):void {
			mValue = value;
		}
		public function get value():String {
			return mValue;
		}
		public override function asBoolean():BooleanValue {
			return ( mValue ) ? BooleanValue.TRUE : BooleanValue.FALSE;
		}
		public override function asNumber():NumberValue {
			var n:int = parseInt(mValue);
			return new NumberValue(n);
		}
		public override function asString():StringValue {
			return this;
		}
		public function toString():String {
			return "[StringVallue " + value + "]";
		}
	}
}
