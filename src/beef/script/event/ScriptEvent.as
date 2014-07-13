package beef.script.event {
	import flash.events.Event;
	
	public class ScriptEvent extends Event {
		public static const RUNTIME_ERROR:String = 'runtime_error';
		public static const RUN:String = 'run';
		public static const STOP:String = 'stop';
		public static const RESUME:String = 'resume';
		public static const FINISH:String = 'finish';
		
		protected var mError:Error;
		public function get error():Error {
			return mError;
		}
		
		public function ScriptEvent(type:String, error:Error = null):void {
			super(type);
			mError = error;
		}
	}
}
