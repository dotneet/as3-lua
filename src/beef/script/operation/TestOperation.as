package beef.script.operation {
	import beef.script.ScriptRuntime;
	import beef.script.expr.BooleanValue;

	/**
	 * @author shinji
	 */
	public class TestOperation extends ScriptOperation {
		// テスト失敗時のアドレス
		public var jumpAddress:int;
		
		/**
		 * 直前に実行された式の結果に基づいてジャンプする
		 */
		public function TestOperation() {
		}
		
		public override function execute(script:ScriptRuntime):void {
			if ( script.lastExpressionResult.asBoolean() === BooleanValue.FALSE ) {
				log("test failed. jump to " + jumpAddress);
				script.jump(jumpAddress);
			} else {
				log("test success");
			}
		}
	}
}
