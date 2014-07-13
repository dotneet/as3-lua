package beef.script.sysfunc {
	import air.update.utils.FileUtils;

	import beef.script.Compiler;
	import beef.script.ScriptFunction;
	import beef.script.ScriptRuntime;
	import beef.script.expr.BooleanValue;
	import beef.script.expr.Value;

	import flash.filesystem.File;

	public class LoadFileFunction extends SystemFunction {
		public function LoadFileFunction() {
			super();
		}
		
		public override function call(runtime:ScriptRuntime, params:Vector.<Value>):Value {
			var filePath:String = params[0].asString().value;
			var source:String = FileUtils.readUTFBytesFromFile(new File(filePath));
			var compiler:Compiler = new Compiler();
			var chunk:ScriptFunction = compiler.parse(source);
			runtime.createThread().execute(chunk);
			return BooleanValue.TRUE;
		}
	}
}
