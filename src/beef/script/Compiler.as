package beef.script {
	import beef.script.compiler.RefVar;
	import beef.script.compiler.Token;
	import beef.script.compiler.UnresolvedJump;
	import beef.script.expr.NumberValue;
	import beef.script.expr.StringValue;
	import beef.script.expr.Value;

	import flash.utils.Dictionary;


	public class Compiler {
		public static const LOG_NONE:int = 0;
		public static const LOG_INFO:int = 1;
		public static const LOG_DEBUG:int = 2;
		
		protected var mStack:Vector.<ScriptFunction> = new Vector.<ScriptFunction>();
		
		protected var mFunctions:Dictionary = new Dictionary();
		protected var mErrors:Vector.<String> = new Vector.<String>();
		protected var mTokens:Vector.<Token>;
		protected var mPos:int;
		protected var mLogLevel:int = LOG_NONE;
		protected var mFuncSeqNum:int = 1;
		
		protected var mUnresolvedBreaks:Vector.<UnresolvedJump> = new Vector.<UnresolvedJump>();
		
		public function Compiler() {
			var mainFunc:ScriptFunction = new ScriptFunction();
			mStack.push(mainFunc);
			mFunctions["__MAIN__"] = mainFunc;
		}
		
		public function set logLevel(level:int):void {
			mLogLevel = level;
		}
		public function get logLevel():int {
			return mLogLevel;
		}
		
		public function get errors():Vector.<String> {
			return mErrors;
		}
		
		public function parse(source:String):ScriptFunction {
			// trace("source:" + source);
			
			var lexer:Lexer = new Lexer();
			mTokens = lexer.tokenize(source);
			mPos = 0;
			
			parseChunk();
			
			if ( hasMoreToken() ) {
				error("found invalid token:" + getToken(0));
			}
			
			return stack;
		}
		
		public function getChunk():ScriptFunction {
			return stack;
		}
		
		protected function parseChunk():void {
			parseBlock();
			addInstruction(Instruction.OPE_RETURN, 0, 0, 0);
			var unresolved:Vector.<String> = stack.resolveGotoStatement();
			for each( var label:String in unresolved ) {
				error("label[" + label + "] is not defined.");
			}
		}
		
		protected function parseBlock():void {
			log("parseBlock");
			stack.pushLocalScope();
			parseBlockWithoutNewStack();
			stack.popLocalScope();
		}
		
		protected function parseBlockWithoutNewStack() : void {
			while ( true ) {
				if ( look(Token.TYPE_IDENT) ) {
					if ( look(Token.TYPE_LPARENT, 1) ) {
						parseFuncCall();
					} else if ( look(Token.TYPE_COMMA, 1) || look(Token.TYPE_EQUAL, 1) || look(Token.TYPE_PERIOD, 1) || look(Token.TYPE_LBRACKET, 1) ) {
						parseAssignment(false);
					} else {
						error("syntax error:" + currentToken);
						consume();
					}
				} else if ( look(Token.TYPE_LOCAL) ) {
					parseDefLocal();
				} else if ( look(Token.TYPE_FUNCTION) ) {
					parseFunction(true);
				} else if ( look(Token.TYPE_DCOLON) ) {
					parseLabel();
				} else if ( look(Token.TYPE_GOTO) ) {
					parseGotoStatement();
				} else if ( look(Token.TYPE_IF) ) {
					parseIfStatement();
				} else if ( look(Token.TYPE_WHILE) ) {
					parseWhileStatement();
				} else if ( look(Token.TYPE_FOR) ) {
					parseForStatement();
				} else if ( look(Token.TYPE_SEMICOLON) ) {
					consume();
				} else {
					break;
				}
			}
			
			if ( look(Token.TYPE_BREAK) ) {
				consume();
				var breakAddress:int = nextAddress;
				var unresoleveBreak:Instruction = addInstruction(Instruction.OPE_JMP, 0, 0, 0);
				mUnresolvedBreaks.push(new UnresolvedJump(unresoleveBreak, breakAddress));
			}
			if ( look(Token.TYPE_RETURN) ) {
				parseReturnStatement();
				while ( look(Token.TYPE_SEMICOLON) ) {
					consume();
				}
			}
		}
		
		protected function parseReturnStatement():void {
			consume(Token.TYPE_RETURN);
			var base:int = freereg();
			var expCount:int = parseExpList();
			addInstruction(Instruction.OPE_RETURN, base, expCount + 1, 0);
		}
		
		protected function parseExpList():int {
			var expCount:int = 0;
			while ( currentToken.isLiteralOrIdent() || 
					currentToken.isUnaryOperator() ||
					look(Token.TYPE_FUNCTION) ||
					look(Token.TYPE_LPARENT) || 
					look(Token.TYPE_LBRACE) ) {
				expCount++;
				parseExp();
				if ( look(Token.TYPE_COMMA) ) {
					consume();
				} else {
					break;
				}
			}
			return expCount;
		}
		
		protected function parseAssignment(newLocal:Boolean):void {
			var varlist:Vector.<RefVar> = parseVarList(newLocal);
			
			if ( !consume(Token.TYPE_EQUAL) ) {
				if ( !newLocal ) {
					error('assignment statement syntax is incorrect.');
					return;
				}	
			}
			
			// load nil to all assigned variables.
			var gblNameIdx:int = 0;
			for each (var ref : RefVar in varlist.slice(1)) {
				if ( ref.type == RefVar.TYPE_LOCAL ) {
					addInstruction(Instruction.OPE_LOADNIL, ref.register, ref.register, 0);
				} else if ( ref.type == RefVar.TYPE_GLOBAL ) {
					var tmp : int = stack.freereg;
					stack.addStackPositon(1);
					addInstruction(Instruction.OPE_LOADNIL, tmp, tmp, 0);
					addInstruction(Instruction.OPE_SETGLOBAL, tmp, gblNameIdx, 0);
				} else {
					throw new ScriptError('table is not implemented');
				}
			}
			
			var basereg:int = freereg();
			parseExpList();
			var expreg:int = basereg;
			for each ( ref in varlist ) {
				if ( ref.type == RefVar.TYPE_GLOBAL ) {
					gblNameIdx = addConst(new StringValue(ref.name));
				}
				
				if ( ref.type == RefVar.TYPE_LOCAL ) {
					addInstruction(Instruction.OPE_MOVE, ref.register, expreg++, 0);
				} else if ( ref.type == RefVar.TYPE_GLOBAL ) {
					addInstruction(Instruction.OPE_SETGLOBAL, expreg++, gblNameIdx, 0);
				} else if ( ref.type == RefVar.TYPE_REFERENCE ) {
					addInstruction(Instruction.OPE_SETTABLE, ref.register, ref.keyRegister, expreg++);
				} else {
					throw new ScriptError('unknown error');
				}
			}
			stack.freereg = basereg;
		}
		
		protected function parseDefLocal():void {
			consume(Token.TYPE_LOCAL);
			parseAssignment(true);
		}
		
		protected function parseVarList(newLocal:Boolean):Vector.<RefVar> {
			var varlist:Vector.<RefVar> = new Vector.<RefVar>();
			while ( look(Token.TYPE_IDENT) ) {
				var name:String = getToken(0).token;
				consume();
				var register:int = 0;
				if ( newLocal ) {
					register = stack.addLocal(name);
				} else {
					register = stack.findLocal(name);
				}
				if ( look(Token.TYPE_PERIOD) || look(Token.TYPE_LBRACKET) ) {
					var tmpRegister:int = 0;
					if ( register == -1 ) {
						var gblNameIdx:int = addConst(new StringValue(name));
						var nameRegister:int = freereg();
						addInstruction(Instruction.OPE_LOADK, increg(), gblNameIdx, 0);
						register = freereg();
						addInstruction(Instruction.OPE_GETGLOBAL, increg(), nameRegister, 0);
					}
					while ( look(Token.TYPE_PERIOD) || look(Token.TYPE_LBRACKET) ) {
						if ( look(Token.TYPE_PERIOD) ) {
							consume();
							if ( look(Token.TYPE_IDENT) ) {
								var keyStr:String = getToken(0).token;
								consume();
								var keyRegister:int = addConst(new StringValue(keyStr));
								
								if ( look(Token.TYPE_PERIOD) || look(Token.TYPE_LBRACKET) ) {
									tmpRegister = increg();
									addInstruction(Instruction.OPE_GETTABLE, tmpRegister, register, rk(keyRegister));
									register = tmpRegister; 
								} else {
									varlist.push(new RefVar(RefVar.TYPE_REFERENCE, name, register, rk(keyRegister)));
								}
							} else {
								error("unexpected token:" + getToken(0));
							}
						} else if ( look(Token.TYPE_LBRACKET) ) {
							consume();
							var expReg:int = freereg();
							parseExp();
							consume();
							
							if ( look(Token.TYPE_PERIOD) || look(Token.TYPE_LBRACKET) ) {
								tmpRegister = increg();
								addInstruction(Instruction.OPE_GETTABLE, tmpRegister, register, expReg);
								register = tmpRegister; 
							} else {
								varlist.push(new RefVar(RefVar.TYPE_REFERENCE, name, register, expReg));
							}
						}
					}
				} else {
					if ( register != -1 ) {
						varlist.push(new RefVar(RefVar.TYPE_LOCAL, name, register, 0));
					} else {
						varlist.push(new RefVar(RefVar.TYPE_GLOBAL, name, 0, 0));
					}	
				}
				if ( look(Token.TYPE_COMMA) ) {
					consume();
				} else {
					break;
				}
			}
			return varlist;
		}
		
		// 識別子 + '(' + 引数リスト + ')'
		protected function parseFuncCall():void {
			log("parseFuncCall");
			
			var funcName:String = getToken(0).token;
			consume();
			var funcReg:int = increg();
			
			var localIdx:int = stack.findLocal(funcName);
			if ( localIdx != -1 ) {
				addInstruction(Instruction.OPE_MOVE, funcReg, localIdx, 0);
			} else {
				var idx:int = addConst(new StringValue(funcName));
				addInstruction(Instruction.OPE_GETGLOBAL, funcReg, idx, 0);
			}
			
			var paramNums:int = parseArgs();
			// ope.a = 戻り値格納レジスタ, ope.b = パラメータ数+1
			addInstruction(Instruction.OPE_CALL, funcReg, paramNums + 1, 0);
		}
		
		// 'GOTO' + 識別子
		protected function parseGotoStatement():void {
			log("parseGotoStatement");
			
			consume();
			if ( look(Token.TYPE_IDENT) ) {
				var label:String = getToken(0).token;
				var addr:int = nextAddress;
				var jmpIns:Instruction = addInstruction(Instruction.OPE_JMP, 0, 0, 0);
				stack.addUnresolevedGoto(label,addr,jmpIns);
				consume();
			} else {
				error("\'GOTO\'/ require label.");
				consume();
			}
		}
		
		// (数値|文字列) { ',' ... }
		protected function parseArgs():Number {
			consume(); // '('
			var r:Number = 0;
			while ( currentToken.isLiteralOrIdent() ) {
				r++;
				parseExp();
				if ( look(Token.TYPE_COMMA) ) {
					consume();
				} else {
					break;
				}
			}
			if ( !consume(Token.TYPE_RPARENT) ) {
				error('not found right parent for argument list.');
			}
			return r;
		}
		
		protected function parseExp():void {
			parseExpCond();
		}
		
		protected function parseExpCond():void {
			// TODO: 論理演算式
			parseExpOr();
		}
		
		protected function parseExpOr():void {
			var base:int = freereg();
			parseExpAnd();
			var jmps:Vector.<UnresolvedJump> = new Vector.<UnresolvedJump>();
			while ( look(Token.TYPE_OR) ) {
				consume();
				addInstruction(Instruction.OPE_TEST, base, 0, 1);
				var jmp:Instruction = addInstruction(Instruction.OPE_JMP,0,0,0);
				jmps.push(new UnresolvedJump(jmp, nextAddress));
				stack.freereg = base;
				parseExpAnd();
			}
			var addr:int = nextAddress;
			for each ( var uj:UnresolvedJump in jmps ) {
				uj.inst.b = addr - uj.address;
			}
		}
		
		protected function parseExpAnd():void {
			var base:int = freereg();
			parseExpEqual();
			var jmps:Vector.<UnresolvedJump> = new Vector.<UnresolvedJump>();
			while ( look(Token.TYPE_AND) ) {
				consume();
				addInstruction(Instruction.OPE_TEST, base, 0, 0);
				var jmp:Instruction = addInstruction(Instruction.OPE_JMP,0,0,0);
				jmps.push(new UnresolvedJump(jmp, nextAddress));
				stack.freereg = base;
				parseExpEqual();
			}
			var addr:int = nextAddress;
			for each ( var uj:UnresolvedJump in jmps ) {
				uj.inst.b = addr - uj.address;
			}
		}
		
		protected function parseExpEqual():void {
			var base:int = freereg();
			parseExpLessGreat();
			while ( look(Token.TYPE_DEQUAL) || look(Token.TYPE_TILDA_EQUAL) ) {
				var type:int = getToken(0).type;
				consume();
				parseExpLessGreat();
				if ( type == Token.TYPE_DEQUAL ) {
					addInstruction(Instruction.OPE_EQ, 1, base, base + 1);
				} else if ( type == Token.TYPE_TILDA_EQUAL ) {
					addInstruction(Instruction.OPE_EQ, 0, base, base + 1);
				}
				addInstruction(Instruction.OPE_JMP, 0, 1, 0);
				addInstruction(Instruction.OPE_LOADBOOL, base, 0, 1);
				addInstruction(Instruction.OPE_LOADBOOL, base, 1, 0);
				stack.freereg = base + 1;
			}
		}
		
		protected function parseExpLessGreat():void {
			var base:int = freereg();
			parseExpAddSub();
			while ( look(Token.TYPE_LESS) || look(Token.TYPE_LESS_EQUAL) || look(Token.TYPE_GREAT) || look(Token.TYPE_GREAT_EQUAL) ) {
				var type:int = getToken(0).type;
				consume();
				parseExpAddSub();
				if ( type == Token.TYPE_LESS ) {
					addInstruction(Instruction.OPE_LT, 1, base, base + 1);
				} else if ( type == Token.TYPE_LESS_EQUAL ) {
					addInstruction(Instruction.OPE_LE, 1, base, base + 1);
				} else if ( type == Token.TYPE_GREAT ) {
					addInstruction(Instruction.OPE_LT, 1, base + 1, base);
				} else if ( type == Token.TYPE_GREAT_EQUAL ) {
					addInstruction(Instruction.OPE_LE, 1, base + 1, base);
				}
				addInstruction(Instruction.OPE_JMP, 0, 1, 0);
				addInstruction(Instruction.OPE_LOADBOOL, base, 0, 1);
				addInstruction(Instruction.OPE_LOADBOOL, base, 1, 0);
				stack.freereg = base + 1;
			}
		}
		
		protected function parseExpAddSub():void {
			var base:int = freereg();
			parseExpMulDiv();
			while ( look(Token.TYPE_PLUS) || look(Token.TYPE_MINUS) ) {
				var type:int = getToken(0).type;
				consume();
				parseExpMulDiv();
				if ( type == Token.TYPE_PLUS ) {
					addInstruction(Instruction.OPE_ADD, base, base, base + 1);
				} else if ( type == Token.TYPE_MINUS ) {
					addInstruction(Instruction.OPE_SUB, base, base, base + 1);
				}
				stack.freereg = base + 1;
			}
		}
		
		protected function parseExpMulDiv():void {
			// TODO: 四則演算命令はconstにアクセスできるのでリテラルの場合はレジスタを使わないようにできる
			var base:int = freereg();
			parseExpModePow();
			while ( look(Token.TYPE_ASTARISK) || look(Token.TYPE_SLASH) ) {
				var type:int = getToken(0).type;
				consume();
				parseExpModePow();
				if ( type == Token.TYPE_ASTARISK ) {
					addInstruction(Instruction.OPE_MUL, base, base, base + 1);
				} else if ( type == Token.TYPE_SLASH ) {
					addInstruction(Instruction.OPE_DIV, base, base, base + 1);
				}
				stack.freereg = base + 1;
			}
		}
		
		protected function parseExpModePow():void {
			var base:int = freereg();
			parseExpUnary();
			while ( look(Token.TYPE_PERCENT) || look(Token.TYPE_CARET) || look(Token.TYPE_DPERIOD) ) {
				var type:int = getToken(0).type;
				consume();
				parseExpUnary();
				if ( type == Token.TYPE_PERCENT ) {
					addInstruction(Instruction.OPE_MOD, base, base, base + 1);
				} else if ( type == Token.TYPE_CARET ) {
					addInstruction(Instruction.OPE_POW, base, base, base + 1);
				} else if ( type == Token.TYPE_DPERIOD ) {
					addInstruction(Instruction.OPE_CONCAT, base, base, base + 1);
				}
				stack.freereg = base + 1;
			}
		}
		
		protected function parseExpConcat():void {
			var base:int = freereg();
			parseExpUnary();
			var concatCount:int = 0;
			while ( look(Token.TYPE_DPERIOD) ) {
				consume();
				parseExpUnary();
				concatCount++;
			}
			if ( concatCount > 0 ) {
				addInstruction(Instruction.OPE_CONCAT, base, base, base + concatCount);
				//stack.freereg = base + 1;
			}
		}
		
		protected function parseExpUnary():void {
			var reg:int = freereg();
			if ( look(Token.TYPE_MINUS) ) {
				consume();
				parseExp();
				addInstruction(Instruction.OPE_UNM, reg, reg, 0);
			} else if ( look(Token.TYPE_NOT) ) {
				consume();
				parseExp();
				addInstruction(Instruction.OPE_NOT, reg, reg, 0);
			} else {
				parseExpFactor();
			}
		}
		
		protected function parseExpFactor():void {
			var reg:int = freereg();
			var hasError:Boolean = false;
			var token:Token = getToken(0);
			if ( token.isLiteral() ) {
				parseValue();
			} else if ( look(Token.TYPE_IDENT) ) {
				if ( look(Token.TYPE_LPARENT,1) ) {
					parseFuncCall();
				} else {
					parseVar();
				}
			} else if ( look(Token.TYPE_FUNCTION) ) {
				parseFunction();
			} else if ( look(Token.TYPE_LPARENT) ) {
				consume();
				parseExp();
				if ( look(Token.TYPE_RPARENT ) ) {
					consume();
				} else {
					error("not found right parent.");
					hasError = true;
				}
			} else if ( look(Token.TYPE_LBRACE) ){
				var hashSize:int = 0;
				var arraySize:int = 0;
				var tableRegister:int = increg();
				var newtableOpe:Instruction = addInstruction(Instruction.OPE_NEWTABLE, tableRegister, arraySize, hashSize);
				consume();
				while ( !look(Token.TYPE_RBRACE) ) {
					if ( look(Token.TYPE_IDENT) && look(Token.TYPE_EQUAL,1) ) {
						var keyName:String = getToken(0).token;
						consume();
						consume();
						var expReg:int = freereg();
						parseExp();
						hashSize++;
						var nameReg:int = addConst(new StringValue(keyName));
						addInstruction(Instruction.OPE_SETTABLE, tableRegister, rk(nameReg), expReg);
					} else {
						parseExp();
						arraySize++;
					}
					if ( !look(Token.TYPE_COMMA) ) {
						break;
					}
					consume();
				}
				
				newtableOpe.b = arraySize;
				newtableOpe.c = hashSize;
				addInstruction(Instruction.OPE_SETLIST, tableRegister, tableRegister, 1);
				consume();	// right brace
			} else {
				error("found syntax error");
				hasError = true;
			}
			if ( !hasError ) {
				while ( look(Token.TYPE_PERIOD) || look(Token.TYPE_LBRACKET) ) {
					parseTableVar(reg);
				}
			}
		}
		
		protected function parseValue():Value {
			log("parseValue");
			
			var i:int;
			var r:Value = null;
			if ( look(Token.TYPE_NUMBER) ) {
				r = new NumberValue(Number(getToken(0).token));
				i = addConst(r);
				addInstruction(Instruction.OPE_LOADK, increg(), i, 0);
			} else if ( look(Token.TYPE_STRING) ) {
				r = new StringValue(getToken(0).token);
				i = addConst(r);
				addInstruction(Instruction.OPE_LOADK, increg(), i, 0);
			} else if ( look(Token.TYPE_TRUE) ) {
				i = increg();
				addInstruction(Instruction.OPE_LOADBOOL, i, 1, 0);
			} else if ( look(Token.TYPE_FALSE) ) {
				i = increg();
				addInstruction(Instruction.OPE_LOADBOOL, i, 0, 0);
			} else if ( look(Token.TYPE_NIL) ) {
				i = increg();
				addInstruction(Instruction.OPE_LOADNIL, i, i, 0);
			} else {
				error("found syntax error");
			}
			consume();
			
			return r;
		}
		
		protected function parseVar():void {
			var name:String = getToken(0).token;
			consume();
			
			var localIdx:int = stack.findLocal(name);
			if ( localIdx != -1 ) {
				addInstruction(Instruction.OPE_MOVE, increg(), localIdx, 0);
			} else {
				var i:int = addConst(new StringValue(name));
				var r:int = increg();
				addInstruction(Instruction.OPE_GETGLOBAL, r, i, 0);
			}
		}
		
		protected function parseTableVar(valueReg:int):void {
			if ( look(Token.TYPE_PERIOD) ) {
				consume();
				var name:String = getToken(0).token;
				var nameConstId:int = addConst(new StringValue(name));
				
				addInstruction(Instruction.OPE_GETTABLE, valueReg, valueReg, rk(nameConstId));
				consume();
			} else if (look(Token.TYPE_LBRACKET) ) {
				consume();
				var expReg:int = freereg();
				parseExp();
				addInstruction(Instruction.OPE_GETTABLE, valueReg, valueReg, expReg);
				consume(Token.TYPE_RBRACKET);
				stack.freereg = expReg;
			}	
		}
		
		// '::' + 識別子 + '::'
		protected function parseLabel():void {
			log("parseLabel");
			
			consume(Token.TYPE_DCOLON);
			if ( look(Token.TYPE_IDENT) ) {
				addLabel(getToken(0).token, nextAddress);
				consume();
			} else {
				error("found invalid label");
			}
			if ( !consume(Token.TYPE_DCOLON) ) {
				error("incorrect label syntax");
			}
		}
		
		protected function parseFunction(fromTopLevel:Boolean = false):void {
			consume(Token.TYPE_FUNCTION);
			var funcName:String = null;
			if ( look(Token.TYPE_IDENT) ) {
				funcName = getToken(0).token;
				consume();
			}
			
			var params:Vector.<String>;
			if ( consume(Token.TYPE_LPARENT) ) {
				params = parseParameterList();
				if ( !consume(Token.TYPE_RPARENT) ) {
					error('not found left parent');
				}
			} else {
				error('function require argument list.');
			}
			
			var func:ScriptFunction = createFunction(funcName, params);
			mStack.push(func);
			
			parseBlock();
			
			if ( !consume(Token.TYPE_END) ) {
				error('not found \'end\' of function.');		
			}
			
			addInstruction(Instruction.OPE_RETURN, 0, 0, 0);
			var unresolved:Vector.<String> = stack.resolveGotoStatement();
			for each( var label:String in unresolved ) {
				error("label[" + label + "] is not defined.");
			}
			mStack.pop();
			
			if ( !fromTopLevel ) {
				var i:int = addConst(func);
				addInstruction(Instruction.OPE_LOADK, increg(), i, 0);
			}
		}
		
		protected function parseParameterList():Vector.<String> {
			var nameList:Vector.<String> = new Vector.<String>();
			while ( look(Token.TYPE_IDENT) ) {
				nameList.push(getToken(0).token);
				consume();
				if ( !consume(Token.TYPE_COMMA) ) {
					break;
				}
			}
			return nameList;
		}
		
		// "IF" + command + "THEN" + statement_block + "ELSE" + statement_block + "END"
		protected function parseIfStatement():void {
			log("parseIfStatement");
			
			consume();
			var r0:int = stack.freereg;
			parseExp();
			stack.freereg = r0;
			addInstruction(Instruction.OPE_TEST, r0, 0, 0);
			var elseJmp:Instruction = addInstruction(Instruction.OPE_JMP, 0, 0, 0);
			var elseAddress:int = nextAddress;
			var thenJmp:Instruction;
			var thenJmps:Vector.<UnresolvedJump> = new Vector.<UnresolvedJump>();
			if ( look(Token.TYPE_THEN) ) {
				consume();
				parseBlock();
				
				while ( look(Token.TYPE_ELSEIF) ) {
					consume();
					
					thenJmp = addInstruction(Instruction.OPE_JMP, 0, 0, 0);
					thenJmps.push(new UnresolvedJump(thenJmp, nextAddress - 1));
					
					elseJmp.b = nextAddress - elseAddress;
					
					r0 = stack.freereg;
					parseExp();
					stack.freereg = r0;
					addInstruction(Instruction.OPE_TEST, r0, 0, 0);
					elseJmp = addInstruction(Instruction.OPE_JMP, 0, 0, 0);
					elseAddress = nextAddress;
					if ( !look(Token.TYPE_THEN) ) {
						error("not found \'then\' of elseif statement.");
						break;
					}
					consume();
					parseBlock();
				}
				
				if ( look(Token.TYPE_ELSE) ) {
					thenJmp = addInstruction(Instruction.OPE_JMP, 0, 0, 0);
					thenJmps.push(new UnresolvedJump(thenJmp, nextAddress - 1));
					
					elseJmp.b = nextAddress - elseAddress;
					consume();
					parseBlock();
				} else {
					elseJmp.b = nextAddress - elseAddress;
				}
				for each ( var jmp:UnresolvedJump in thenJmps ) {
					jmp.inst.b = nextAddress - jmp.address - 1;
				}
				
				if ( !consume(Token.TYPE_END) ) {
					error('not found \'end\' of if statement.');
				}
			}
		}
		
		protected function parseWhileStatement():void {
			consume(Token.TYPE_WHILE);
			var base:int = stack.freereg;
			var testAddr:int = nextAddress;
			parseExp();
			addInstruction(Instruction.OPE_TEST, base, 0, 0);
			var jmpAddr:int = nextAddress;
			var jmpOpe:Instruction = addInstruction(Instruction.OPE_JMP, 0, 0, 0);
			if ( look(Token.TYPE_DO) ) {
				consume();
				parseBlock();
				addInstruction(Instruction.OPE_JMP, 0, testAddr - nextAddress - 1, 0);
			}
			jmpOpe.b = nextAddress - jmpAddr - 1;
			resolveBreakStatements(nextAddress);
			
			if ( !consume(Token.TYPE_END) ) {
				error('not found \'end\' of while statement.');
			}
			stack.freereg = base;
		}
		
		protected function parseForStatement():void {
			consume(Token.TYPE_FOR);
			var base:int = stack.freereg;
			if ( look(Token.TYPE_IDENT) && look(Token.TYPE_EQUAL,1) ) {
				var name:String = getToken(0).token;
				consume();
				consume();
				
				var indexRegister:int = stack.freereg;
				parseExp();	// for index
				if ( !consume(Token.TYPE_COMMA) ) {
					error('syntx error: for statment incorrect');
				}
				parseExp();	// for limit
				if ( consume(Token.TYPE_COMMA) ) {
					parseExp();	// for step
				} else {
					var stepConst:int = addConst(new NumberValue(1));
					addInstruction(Instruction.OPE_LOADK, increg(), stepConst, 0);
				}
				if ( consume(Token.TYPE_DO) ) {
					stack.pushLocalScope();
					addLocal(name);
					var prepAddress:int = nextAddress;
					var prepInst:Instruction = addInstruction(Instruction.OPE_FORPREP, indexRegister, 0, 0);
					parseBlockWithoutNewStack();
					prepInst.b = nextAddress - prepAddress - 1;
					addInstruction(Instruction.OPE_FORLOOP, indexRegister, prepAddress - nextAddress, 0);
					stack.popLocalScope();
					if ( !consume(Token.TYPE_END) ) {
						error("not found 'end' of for-statement");
					}
				} else {
					error("not found 'do' keywrod in for-statement");
				}
				
			} else {
				error('for-in statment not implemented.');
			}
			stack.freereg = base;
		}
		
		protected function resolveBreakStatements(toAddress:int):void {
			for each ( var unresolved:UnresolvedJump in mUnresolvedBreaks ) {
				unresolved.inst.b = toAddress - unresolved.address - 1;
			}
			mUnresolvedBreaks = new Vector.<UnresolvedJump>();
		}
		
		protected function addInstruction(op:int, a:int, b:int, c:int):Instruction {
			var inst:Instruction = new Instruction(op, a, b, c);
			stack.addInstruction(inst);
			return inst;
		}
		protected function createFunction(name:String,params:Vector.<String>):ScriptFunction {
			var fn:ScriptFunction = new ScriptFunction(params, mFuncSeqNum++);
			if ( name != null ) {
				stack.addFunction(name, fn);
			}
			return fn;
		}
		protected function addConst(value:Value):int {
			var idx:int = stack.findConst(value);
			if ( idx == -1 ) {
				return stack.addConst(value);
			}
			return idx;
		}
		protected function addLocal(name:String):int {
			return stack.addLocal(name) - 1;
		}
		protected function addLabel(name:String, addr:int):void {
			stack.addLabel(name, addr);
		}
		
		protected function increg():int {
			var i:int = freereg();
			stack.addStackPositon(1);
			return i;
		}
		protected function freereg():int {
			return stack.freereg;
		}
		protected function get stack():ScriptFunction {
			return mStack[mStack.length - 1];
		}
		protected function get nextAddress():int {
			return stack.instructions.length;
		}
		
		
		protected function get currentToken():Token {
			if ( mTokens.length <= mPos ) {
				return null;
			}
			return mTokens[mPos];
		}
		
		protected function look(type:int,n:int=0):Boolean {
			if ( mTokens.length <= mPos+n ) {
				return false;
			}
			return mTokens[mPos+n].type == type;
		}
		
		protected function hasMoreToken():Boolean {
			return mPos < mTokens.length;
		}
		
		protected function getToken(n:int):Token {
			return mTokens[mPos+n];
		}
		protected function consume(type:int = -1):Boolean {
			if ( (type == -1) || (type == getToken(0).type) ) {
				mPos += 1;
				return true;
			}
			return false;
		}
		protected function error(msg:String):void {
			var line:int = 0;
			if ( currentToken ) {
				line = currentToken.line;
			}
			mErrors.push(line + ":" + msg);
		}
		
		private function log(msg:String):void {
			if ( mLogLevel > LOG_NONE ) {
				trace(msg);
			}
		}
		
		private function rk(constIdx:int):int {
			return LuaConstants.MAX_STACK + constIdx;
		}
		
		public function dumpLastResult():void {
			stack.dump();
			for each ( var fn:ScriptFunction in stack.functions ) {
				fn.dump();
			}
		}
	}
}
