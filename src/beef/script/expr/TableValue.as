package beef.script.expr {
	import flash.utils.Dictionary;
	import beef.script.expr.Value;

	public class TableValue extends Value {
		protected var mArray:Dictionary = new Dictionary();
		protected var mHash:Dictionary = new Dictionary();
		protected var mArraySize:int;
		protected var mHashSize:int;
		
		public function TableValue(arraySize:int, hashSize:int) {
			mArraySize = arraySize;
			mHashSize = hashSize;
		}
		
		public function get arraySize():int {
			return mArraySize;
		}
		public function get hashSize():int {
			return mHashSize;
		}
		
		public function setValue(key:Value, value:Value):Boolean {
			if ( key is NumberValue ) {
				var index:int = key.asNumber().value;
				mArray[index] = value;
			} else if ( key is StringValue ) {
				var keyStr:String = key.asString().value;
				mHash[keyStr] = value;
			} else {
				return false;
			}
			return true;
		}
		
		public function getValue(key:Value):Value {
			if ( key is NumberValue ) {
				var index:int = key.asNumber().value;
				if ( mArray.hasOwnProperty(index) ) {
					return mArray[index];
				}
				return NilValue.INSTANCE;
			} else if ( key is StringValue ) {
				var keyStr:String = key.asString().value;
				if ( mHash.hasOwnProperty(keyStr) ) {
					return mHash[keyStr];
				}
				return NilValue.INSTANCE;
			}
			return null;
		}
		
		public override function asString():StringValue {
			return new StringValue("table");
		}
		
		public override function asBoolean():BooleanValue {
			return BooleanValue.TRUE;
		}
		
		public override function asNumber():NumberValue {
			return new NumberValue(NaN);
		}
	}
}
