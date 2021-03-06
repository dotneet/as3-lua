package unittest {
	import beef.script.Compiler;
	import beef.script.ScriptFunction;
	import beef.script.ScriptRuntime;

	import flexunit.framework.Assert;

	public class TestSyntax {
		private var showLog:Boolean = false;
		
		private function execLiner(source : String) : String {
			return execAndPrint("result = " + source, "result");
		}

		private function execAndPrint(source : String, varname : String) : String {
			var compiler : Compiler = new Compiler();
			var script : ScriptFunction = compiler.parse(source + ";" + "print(" + varname + ")");
			if ( showLog ) {
				trace(source);
				script.dump();
			}
			if ( compiler.errors.length ) {
				for each ( var error:String in compiler.errors ) {
					trace(error);
				}
				return null;
			}
			var runtime : ScriptRuntime = new ScriptRuntime();
			if  (showLog) {
				runtime.logLevel = ScriptRuntime.LOG_DEBUG;
			}
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
			
			Assert.assertEquals(3, execAndPrint("local a = 1; a = a + 2", "a"));
			Assert.assertEquals("aa", execAndPrint("a = \"a\"; a = a .. a", "a"));
		}
		
		[Test]
		public function lambda() : void {
			Assert.assertEquals(100, execAndPrint("f = function(n) return n * n; end; b = f(10)", "b"));
			
			var script:String = 
				"local f = function(x) local y = x * x; return y; end; " +
				"local r = f(2)";
			Assert.assertEquals(4, execAndPrint(script, "r"));
				
		}
		
		[Test]
		public function ifStatement() : void {
			Assert.assertEquals(2, execAndPrint("a = 1; if true then a = 2; else a = 3; end", "a"));
			Assert.assertEquals(3, execAndPrint("a = 1; if false then a = 2; else a = 3; end", "a"));
			Assert.assertEquals(4, execAndPrint("a = 1; if false then a = 2; elseif false then a = 3; else a = 4; end", "a"));
		}
		
		[Test]
		public function whileStatement() : void {
			Assert.assertEquals(5, execAndPrint("a = 1; while a < 5 do a = a + 1 end", "a"));
			Assert.assertEquals(10, execAndPrint("a = 1; b = 1; while a < 5 or b < 10 do a = a + 1; b = b + 1 end", "a"));
			// break
			Assert.assertEquals(3, execAndPrint("a = 1; while a < 5 do if a == 3 then break end a = a + 1 end", "a"));
		}
		
		[Test]
		public function forStatement():void {
			Assert.assertEquals("123", execAndPrint("a = 1; for i = 1,3 do print(i) end", "''"));
			Assert.assertEquals(10, execAndPrint("a = 1; for i = 0,10,2 do a = i end", "a"));
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
			Assert.assertEquals("true", execLiner("not nil"));
			Assert.assertEquals("false", execLiner("not 1"));
			Assert.assertEquals("false", execLiner("not 0"));
		}
		
		[Test]
		public function concatStr() : void {
			Assert.assertEquals("aabb", execAndPrint("a='aa'..'bb'", "a"));
			Assert.assertEquals("aabb12", execAndPrint("a='aa'..'bb'..12", "a"));
			Assert.assertEquals("110", execAndPrint("a=1..0*1..1", "a"));
		}
		
		[Test]
		public function returnStatement() : void {
			Assert.assertEquals("2", execAndPrint("function f(x) local r = x + x; return r; end; local a = f(1);", "a"));
			Assert.assertEquals("1", execAndPrint("function f() return 1,2,3; end; local a,b,c = f();", "a"));
			Assert.assertEquals("2", execAndPrint("function f() return 1,2,3; end; local a,b,c = f();", "b"));
			Assert.assertEquals("3", execAndPrint("function f() return 1,2,3; end; local a,b,c = f();", "c"));
		}
		
		[Test]
		public function table():void {
			Assert.assertEquals("nil", execAndPrint("a = { }", "a[0]"));
			Assert.assertEquals("1", execAndPrint("a = {1,2,3}", "a[1]"));
			Assert.assertEquals("2", execAndPrint("a = {1,2,3}", "a[2]"));
			Assert.assertEquals("3", execAndPrint("a = {1,2,3}", "a[3]"));
			
			Assert.assertEquals("5", execAndPrint("a = {1,b=5,3}", "a.b"));
			Assert.assertEquals("5", execAndPrint("a = {1,b={c=5},3}", "a.b.c"));
			
			Assert.assertEquals("10", execAndPrint("a = {}; a.b = 10", "a.b"));
			var script:String = "function f1() return 0; end;" +
			"local f2 = function(p) " +
			"  local attr=\"b\"; " +
			"  local value=\"v\"; " +
			"  a = {}; " +
			"  a[attr] = value" +
			"  return value;" +
			"end; " +
			"r = f2(10)";
			var compiler:Compiler = new Compiler();
			compiler.parse(script).dump();
			Assert.assertEquals("v", execAndPrint(script,"r"));
			Assert.assertEquals("10", execAndPrint("local a = {}; a.b = 10", "a.b"));
			Assert.assertEquals("nil", execAndPrint("local a = {}; a.b = 10", "a.c"));
		}
		
		[Test]
		public function callFunction():void {
			Assert.assertEquals("10", execAndPrint("function f() return 10; end;local a = f()", "a"));
			Assert.assertEquals("11", execAndPrint("function f(a) return a; end;local a = f(11)", "a"));
			Assert.assertEquals("12", execAndPrint("function f() return 12; end; function p(a) return a; end; local a = p(f())", "a"));
			
			Assert.assertEquals("10", execAndPrint("function f(a) return a*a; end;f(2); local i = 10; f(2); i = i", "i"));
		}
	}
}
