# Beef

ActionScript3.0(AS3) implementation of Lua.
Beef intended to used as game script.

## Features
 - parse and execute a Lua code.
 - call as3.0 method from Lua.
 - virtual thread.(script-truntime can share context with other script-runtime.)
 - unicode Identifier.(incompatible with Lua)

## Not Implemented Lua Specification
 - Metatable
 - table
 - Coroutines
 - almost standard function.

## Code Example.

### call AS3 method from Lua

#### 1. Create AS3 Class which called as Lua function.
```as3
public class FuncWaitTime extends SystemFunction {
    public function FuncWaitTime() {
      super();
    }
    public override function call(runtime:ScriptRuntime, params:Vector.<Value>):Value {
      runtime.stop();
      var millis:Number = params[0].asNumber().value;
      setTimeout(function():void{ runtime.resume();}, millis);
      return BooleanValue.TRUE;
    }
  }
}
```

#### 2. Call AS3 code from Lua.
```as3
var source:String = "wait_time(1000)";
var c:Compiler = new Compiler();
var fn:ScriptFunction = c.parse(source);
var runtime:ScriptRuntime = new ScriptRuntime();
runtime.addFunction('wait_time', new FuncWaitTime());
runtime.execute(fn);
```

## License
>The MIT License (MIT)
>
>Copyright (c) <year> <copyright holders>
>
>Permission is hereby granted, free of charge, to any person obtaining a copy
>of this software and associated documentation files (the "Software"), to deal
>in the Software without restriction, including without limitation the rights
>to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
>copies of the Software, and to permit persons to whom the Software is
>furnished to do so, subject to the following conditions:
>
>The above copyright notice and this permission notice shall be included in
>all copies or substantial portions of the Software.
>
>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
>IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
>FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
>AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
>LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
>OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
>THE SOFTWARE.
