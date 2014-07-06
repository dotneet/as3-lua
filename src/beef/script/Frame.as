package beef.script {
	import beef.script.expr.Value;
	public class Frame {
		public var pc:int;
		public var retval:Value;
		public var register:Vector.<Value> = new Vector.<Value>(Compiler.MAX_STACK);
		public var func:ScriptFunction;
		public var returnRegister:int;
		public var returns:int;
		
		public function dumpRegister():void {
			for ( var idx:String in register ) {
				trace(idx + ":" + register[idx]);
			}
		}
	}
}
