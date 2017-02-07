# Beef

ActionScript3.0(AS3) implementation of Lua.
Beef intend to be used as a game script.

## Features
 - parse and execute a Lua code.
 - call as3.0 method from Lua.
 - virtual thread.(script-truntime can share context with other script-runtime.)
 - unicode Identifier.(incompatible with Lua)

## Following specifications is not implemented
 - Metatable
 - Coroutines
 - almost standard function.
 - for-in,repeate statment.

## Code Example.

### call AS3 method from Lua

#### 1. Create an AS3 Class called as a Lua function.
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

### Lua Code Examaple.
```Lua
local a = 10
g = a * a + 10
c,d = a,g

a = 1
::ONEMORE::
a = a + 1
print(a)
if a < 10 then goto ONEMORE; end

function square(a)
  print(a * a)
end

square(50)
```

## License
>The MIT License (MIT)
>
>Copyright (c) <2017> devneko<dotneet@gmail.com>
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
