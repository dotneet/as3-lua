package beef.script.expr {

	/**
	 * @author shinji
	 */
	public class BooleanValue extends Value {
		public static const TRUE:BooleanValue = new BooleanValue(true);
		public static const FALSE:BooleanValue = new BooleanValue(false);
		
		protected var mValue:Boolean;
		public function BooleanValue(value:Boolean) {
			mValue = value;
		}
		
		public function get value():Boolean {
			return mValue;
		}
		
		public override function asBoolean():BooleanValue {
			return this;
		}
		
		public override function asNumber():NumberValue {
			return mValue ? new NumberValue(1) : new NumberValue(0);
		}
		
		public override function asString():StringValue {
			return new StringValue(mValue ? 'true' : 'false');
		}
		
		public function toString():String {
			return "[BooleanVallue " + value + "]";
		}
	}
}
