# Beef - AS3 imepementation of Lua.

##概要
ActionScript3.0によるLuaインタプリタ実装です。
難しい構文や標準関数の多くが未サポートです。
Luaの関数としてActionScript3.0のコードを呼び出すことができます。
これによりLuaスクリプトからAS3アプリケーションを制御させることができます。

## 非互換機能(Incompatible Feature)
 - Unicode識別子(日本語などを変数名や関数名に使用できます)

## 未実装機能(Not Impelemented).
 - Metatable
 - table
 - Coroutines

## Code Example.

```as3
var source:String = "print('ABCDEFG')";
var c:Compiler = new Compiler();
var fn:ScriptFunction = c.parse(source);
var runtime:ScriptRuntime = new ScriptRuntime();
runtime.execute(fn);
trace(runtime.printBuffer);
```

## その他

### AS3のコードを呼び出すには
beef.script.sysfunc.SystemFunctionを継承したクラスを作成してcall()を実装します。
ScriptRuntime#addFunction()を呼び出してクラスを登録します。

一定時間スクリプトの実行を止める関数を作成する例
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

作成した機能を関数として登録する例
```as3
scriptRuntime.addFunction('WaitTime', new FuncWaitTime());
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
