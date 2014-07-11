package unittest {
	import beef.script.Compiler;
	import beef.script.ScriptFunction;
	import beef.script.ScriptRuntime;

	import flexunit.framework.Assert;

	public class TestSyntax {
		private function execLiner(source : String) : String {
			return execAndPrint("result = " + source, "result");
		}

		private function execAndPrint(source : String, varname : String) : String {
			var compiler : Compiler = new Compiler();
			var script : ScriptFunction = compiler.parse(source + ";" + "print(" + varname + ")");
			if ( compiler.errors.length ) {
				for each ( var error:String in compiler.errors ) {
					trace(error);
				}
				return null;
			}
			var runtime : ScriptRuntime = new ScriptRuntime();
			runtime.execute(script);
			return runtime.printBuffer;
		}

		[Test]
		public function mathSyntax() : void {
			Assert.assertEquals(10, execLiner("3 + 7"));
			Assert.assertEquals(-4, execLiner("3 - 7"));
			Assert.assertEquals(4, execLiner("7 - 3"));
			Assert.assertEquals(21, execLiner("3 * 7"));
			Assert.assertEquals(3, execLiner("6 / 2"));
			Assert.assertEquals(4, execLiner("11 % 7"));
			Assert.assertEquals(25, execLiner("5 ^ 2"));
		}

		[Test]
		public function assign() : void {
			Assert.assertEquals(100, execAndPrint("a = 100", "a"));
			Assert.assertEquals(100, execAndPrint("local a = 100", "a"));
			Assert.assertEquals(1, execAndPrint("local a,b,c = 1,2,3", "a"));
			Assert.assertEquals(2, execAndPrint("local a,b,c = 1,2,3", "b"));
			Assert.assertEquals(3, execAndPrint("local a,b,c = 1,2,3", "c"));
			Assert.assertEquals("nil", execAndPrint("local a,b,c = 1", "b"));
			Assert.assertEquals(1, execAndPrint("local a = 1,2,3", "a"));
			Assert.assertEquals(2, execAndPrint("local a = 1; a = 2", "a"));
		}
		
		[Test]
		public function ifStatement() : void {
			Assert.assertEquals(2, execAndPrint("a = 1; if true then a = 2; else a = 3; end", "a"));
			Assert.assertEquals(3, execAndPrint("a = 1; if false then a = 2; else a = 3; end", "a"));
			Assert.assertEquals(4, execAndPrint("a = 1; if false then a = 2; elseif false then a = 3; else a = 4; end", "a"));
		}
		
		[Test]
		public function condition() : void {
			Assert.assertEquals("true", execAndPrint("a = 1 == 1", "a"));
			Assert.assertEquals("false", execAndPrint("a = 1 == 2", "a"));
			Assert.assertEquals("true", execAndPrint("a = 1 == 2 or 1 == 1", "a"));
			Assert.assertEquals("false", execAndPrint("a = 1 == 2 or 1 == 3", "a"));
			Assert.assertEquals("true", execAndPrint("a = 1 == 1 and 1 == 1", "a"));
			Assert.assertEquals("false", execAndPrint("a = 1 == 1 and 1 ~= 1", "a"));
		}
		
		[Test]
		public function unaryOperator() : void {
			Assert.assertEquals("true", execLiner("not false"));
			Assert.assertEquals("false", execLiner("not true"));
			Assert.assertEquals("false", execLiner("not 1"));
			Assert.assertEquals("true", execLiner("not 0"));
		}
		
		[Test]
		public function returnStatement() : void {
			Assert.assertEquals("10", execAndPrint("function f() return 10; end; local a = f();", "a"));
			Assert.assertEquals("1", execAndPrint("function f() return 1,2,3; end; local a,b,c = f();", "a"));
			Assert.assertEquals("2", execAndPrint("function f() return 1,2,3; end; local a,b,c = f();", "b"));
			Assert.assertEquals("3", execAndPrint("function f() return 1,2,3; end; local a,b,c = f();", "c"));
		}
	}
}
