package beef.script.compiler {
	public class RefVar {
		/** registerはローカル変数を示す */
		public static const TYPE_LOCAL:int = 1;
		/** nameはグローバル変数を示す */
		public static const TYPE_GLOBAL:int = 2;
		/** registerの変数にテーブルへの参照があることを示す */
		public static const TYPE_REFERENCE:int = 3;
		
		public var type:int;
		/** 変数名 */
		public var name:String;
		/** ローカル変数またはテーブルへの参照を保持するレジスタ */
		public var register:int;
		/** テーブルのkeyを保持するレジスタ */
		public var keyRegister:int;
		
		public function RefVar(type:int, name:String, register:int, keyRegister:int) {
			this.type = type;
			this.name = name;
			this.register = register;
			this.keyRegister = keyRegister;
		}
	}
}
