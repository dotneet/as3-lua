package beef.script.ast {
	/**
	 * @author shinji
	 */
	public class Token {
		public static const TYPE_IDENT:int = 1;
		public static const TYPE_NUMBER:int = 2;
		public static const TYPE_STRING:int = 3;
		
		public static const TYPE_LPARENT:int = 10; // (
		public static const TYPE_RPARENT:int = 11; // )
		public static const TYPE_LBRACE:int = 12; // (
		public static const TYPE_RBRACE:int = 13; // (
		public static const TYPE_LBRACKET:int = 14; // (
		public static const TYPE_RBRACKET:int = 15; // (
		
		public static const TYPE_COMMA:int = 20;   // ,
		public static const TYPE_PERIOD:int = 21;     // . 
		public static const TYPE_DPERIOD:int = 22;     // ..
		public static const TYPE_TPERIOD:int = 23;     // ...
		public static const TYPE_COLON:int = 24;      // :
		public static const TYPE_DCOLON:int = 25;      // ::
		public static const TYPE_SEMICOLON:int = 26;  // ;
		
		public static const TYPE_EQUAL:int = 104;   // =
		public static const TYPE_CARET:int = 105;	// ^
		public static const TYPE_DEQUAL:int = 106;   // ==
		public static const TYPE_TILDA_EQUAL:int = 107;   // ~=
		public static const TYPE_LESS_EQUAL:int = 108;   // <=
		public static const TYPE_GREAT_EQUAL:int = 109;   // >=
		public static const TYPE_LESS:int = 110;   // <
		public static const TYPE_GREAT:int = 111;   // >
		
		public static const TYPE_PLUS:int = 130;
		public static const TYPE_MINUS:int = 131;
		public static const TYPE_ASTARISK:int = 132;
		public static const TYPE_SLASH:int = 133;
		public static const TYPE_PERCENT:int = 134;
		public static const TYPE_SHARP:int = 136;
		
		// 予約語
		public static const TYPE_IF:int = 200;
		public static const TYPE_THEN:int = 202;
		public static const TYPE_ELSE:int = 203;
		public static const TYPE_ELSEIF:int = 204;
		public static const TYPE_END:int = 205;
		public static const TYPE_GOTO:int = 206;
		public static const TYPE_FUNCTION:int = 207;
		public static const TYPE_AND:int = 208;
		public static const TYPE_BREAK:int = 209;
		public static const TYPE_DO:int = 210;
		public static const TYPE_IN:int = 211;
		public static const TYPE_LOCAL:int = 212;
		public static const TYPE_NIL:int = 213;
		public static const TYPE_NOT:int = 214;
		public static const TYPE_OR:int = 215;
		public static const TYPE_REPEAT:int = 216;
		public static const TYPE_UNTIL:int = 217;
		public static const TYPE_TRUE:int = 218;
		public static const TYPE_FALSE:int = 219;
		public static const TYPE_WHILE:int = 220;
		public static const TYPE_RETURN:int = 221;
		public static const TYPE_FOR:int = 222;
		
		private var mLine:int;
		private var mToken:String;
		private var mType:int;
		
		public function Token(line:Number, token:String, type:int):void {
			this.mLine = line;
			this.mToken = token;
			this.mType = type;
		}
		
		public function get line():int {
			return mLine;
		}
		public function get token():String {
			return mToken;
		}
		public function get type():int {
			return mType;
		}
		
		public function isLiteral():Boolean {
			return mType == TYPE_STRING || mType == TYPE_NUMBER || mType == TYPE_NIL || mType == TYPE_TRUE || mType == TYPE_FALSE;
		}
		
		public function isLiteralOrIdent():Boolean {
			return isLiteral() || mType == TYPE_IDENT;
		}
		
		public function isUnaryOperator():Boolean {
			return mType == TYPE_MINUS || mType == TYPE_NOT;
		}
		
		public function toString():String {
			return "<Token: line=" + mLine + " token:" + mToken + " type:" + mType + ">";
		}
	}
}
