package beef.script {
	import beef.script.ast.Token;
	/**
	 * @author shinji
	 */
	public class Lexer {
		
		private static const RESERVED_WORDS:Object = {
			'and':Token.TYPE_AND,
			'break':Token.TYPE_BREAK,
			'do': Token.TYPE_DO,
			'else': Token.TYPE_ELSE,
			'elseif':Token.TYPE_ELSEIF,
			'end': Token.TYPE_END,
			'false': Token.TYPE_FALSE,
			'for': Token.TYPE_FOR,
			'function': Token.TYPE_FUNCTION,
			'goto': Token.TYPE_GOTO,
			'if': Token.TYPE_IF,
			'in': Token.TYPE_IN,
			'local': Token.TYPE_LOCAL,
			'nil': Token.TYPE_NIL,
			'not': Token.TYPE_NOT,
			'or': Token.TYPE_OR,
			'repeat': Token.TYPE_REPEAT,
			'return': Token.TYPE_RETURN,
			'then': Token.TYPE_THEN,
			'true': Token.TYPE_TRUE,
			'until': Token.TYPE_FALSE,
			'while': Token.TYPE_WHILE
			};
			
		
		public function tokenize(source:String):Vector.<Token> {
			// 改行コードを\nに統一
			source = source.replace("\r\n", "\n");
			source = source.replace("\r", "\n");
			
			var result:Vector.<Token> = new Vector.<Token>();
			var pos:int = 0;
			
			var line:int = 1;
			var token:String = '';
			var c:String = '';
			
			var next:Function = function():String {
				return source.charAt(pos++);
			};
			var push:Function = function(type:int,word:String):void {
				log("PUSH:" + line + ":" + type + ":" + word);
				result.push(new Token(line, word, type));
			};
			
			c = next();
			
			var eof:Boolean = (c === "");
			while ( !eof ) {
				while ( isSpace(c) ) {
					if ( c === "\n" ) {
						line++;
					}
					c = next();
				}
				if ( c === "" ) {
					break;
				}
				
				token = c;
				switch ( true) {
				case (c === '('):
					push(Token.TYPE_LPARENT, '(');
					c = next();
					break;
				case (c === ')'):
					push(Token.TYPE_RPARENT, ')');
					c = next();
					break;
				case (c === ','): push(Token.TYPE_COMMA, ','); c = next(); break;
				case (c === ':'):
					c = next();
					if ( c === ':' ) {
						push(Token.TYPE_DCOLON, '::');
						c = next();
					} else {
						push(Token.TYPE_COLON, ':');
					}
					break;
				case (c === ';'): push(Token.TYPE_SEMICOLON, ';'); c = next(); break;
				case (c === '+'): push(Token.TYPE_PLUS, '+'); c = next(); break;
				case (c === '-'):
					c = next();
					if ( c == '-' ) { // コメント行
						var comment:String = '';
						c = next();
						while ( c !== '\n' && c !== '' ) {
							comment += c;
							c = next();
						}
						c = next();
						// 複数行のコメント
						if ( comment.substr(0,2) == '[[' ) {
							do {
								while ( c != ']' && c !== '' ) {
									c = next();
								}
								c = next();
							} while ( c != ']' && c !== '' );
						}
					} else if ( !isNaN(parseInt(c)) ) {
						while ( !isNaN(parseInt(c)) ) {
							token += c;
							c = next();
						}
						if ( c == '.' ) {
							token += c;
							c = next();
							while ( !isNaN(parseInt(c)) ) {
								token += c;
								c = next();
							}
						}
						push(Token.TYPE_NUMBER, token);
					} else {
						push(Token.TYPE_MINUS, '-');
					}
					break;
				case (c === '*'): push(Token.TYPE_ASTARISK, '*'); c = next(); break;
				case (c === '/'): push(Token.TYPE_MINUS, '/'); c = next(); break;
				case (c === '%'): push(Token.TYPE_PERCENT, '%'); c = next(); break;
				case (c === '^'): push(Token.TYPE_CARET, '^'); c = next(); break;
				case (c === '='):
					c = next();
					if ( c === '=' ) {
						push(Token.TYPE_DEQUAL, '==');
						c = next();
					} else {
						push(Token.TYPE_EQUAL, '=');
					}
					break;
				case (c === '~'):
					c = next();
					if ( c === '=' ) {
						push(Token.TYPE_TILDA_EQUAL, '~=');
						c = next();
					} else {
						error('字句解析エラー:チルダ発見');
					}
					break;
				case (c === '>'):
					c = next();
					if ( c === '=' ) {
						push(Token.TYPE_GREAT_EQUAL, '>=');
						 c = next();
					} else {
						push(Token.TYPE_GREAT, '>');
					}
					break;
				case (c === '<'):
					c = next();
					if ( c === '=' ) {
						push(Token.TYPE_LESS_EQUAL, '<=');
						 c = next();
					} else {
						push(Token.TYPE_LESS, '<');
					}
					break;
				case (c === "'"):
				case (c === "\""):
					var closeChar:String = c;
					c = next();
					while ( c != closeChar && c !== '' ) {
						token += c;
						c = next();
					}
					if ( c == closeChar ) {
						c = next();
					}
					push(Token.TYPE_STRING, replaceEscapeCharacter(token.substr(1)));
					break;
				case (c === '['):
					c = next();
					if ( c != '[' ) {
						error("不正な文字を検出:" + c + ":" + c.charCodeAt());
					} else {
						c = next();
						if ( c == "\n" ) {
							c = next();
						}
						var str:String = '';
						do {
							str += c;
							c = next();
							while ( c != ']' && c !== '' ) {
								str += c;
								c = next();
							}
							c = next();
						} while ( c != ']' && c !== '' );
						push(Token.TYPE_STRING, str);
					}
					break;
				case (!isNaN(parseInt(c))):
					c = next();
					while ( !isNaN(parseInt(c)) ) {
						token += c;
						c = next();
					}
					if ( c == '.' ) {
						token += c;
						c = next();
						while ( !isNaN(parseInt(c)) ) {
							token += c;
							c = next();
						}
					}
					push(Token.TYPE_NUMBER, token);
					break;
				case (isWord(c)):
					c = next();
					while ( isWord(c) ) {
						token += c;
						c = next();
					}
					
					if ( RESERVED_WORDS[token] ) {
						push(RESERVED_WORDS[token], token);
					} else {
						push(Token.TYPE_IDENT, token);
					}
					
					break;
				default:
					error("不正な文字を検出:" + c + ":" + c.charCodeAt());
					c = next();
					break;
				}
			}
			
			return result;
		}
		
		static private var wordRegex:RegExp = /[^\x00-\x2F\x3A-\x40\x5B-\x5E\x60\x7B-\x7F\x80-\x9F]/;
		private function isWord(c:String):Boolean {
			return wordRegex.test(c);
		}
		
		public static var spaceChars:Array = [' ', '\n', '\t', '\r'];
		private function isSpace(c:String):Boolean {
			for each ( var s:String in spaceChars ) {
				if ( s === c ) {
					return true;
				}
			}
			return false;
		}
		
		private static var escapeChars:Array = [
			[/\\a/g, "\a"],
			[/\\b/g, "\b"],
			[/\\f/g, "\f"],
			[/\\n/g, "\n"],
			[/\\r/g, "\r"],
			[/\\t/g, "\t"],
			[/\\v/g, "\v"],
			[/\\\\/g, "\\"],
			[/\\\"/g, "\""],
			[/\\\'/g, "\'"],
		];
		// エスケープシーケンスを本来の文字コードに変換する
		private function replaceEscapeCharacter(str:String):String {
			for each ( var pair:Array in escapeChars ) {
				str = str.replace(pair[0], pair[1]);
			}
			return str;
		}
		
		private function log(msg:String):void {
			// trace(msg);
		}
		
		private function error(msg:String):void {
			trace(msg);
		}
	}
}

