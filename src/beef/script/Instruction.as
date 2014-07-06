package beef.script {
	
	public class Instruction {		
		public static const OPE_MOVE:int = 0;
		public static const OPE_LOADK:int = 1;
		public static const OPE_LOADBOOL:int = 2;
		public static const OPE_LOADNIL:int = 3;
		public static const OPE_GETUPVAL:int = 4;
		public static const OPE_GETGLOBAL:int = 5;
		public static const OPE_GETTABLE:int = 6;
		public static const OPE_SETGLOBAL:int = 7;
		public static const OPE_SETUPVAL:int = 8;
		public static const OPE_SETTABLE:int = 9;
		public static const OPE_NEWTABLE:int = 10; 
		public static const OPE_SELF:int = 11;
		public static const OPE_ADD:int = 12;
		public static const OPE_SUB:int = 13;
		public static const OPE_MUL:int = 14;
		public static const OPE_DIV:int = 15;
		public static const OPE_MOD:int = 16;
		public static const OPE_POW:int = 17;
		public static const OPE_UNM:int = 18;
		public static const OPE_NOT:int = 19;
		public static const OPE_LEN:int = 20;
		public static const OPE_CONCAT:int = 21;
		public static const OPE_JMP:int = 22;
		public static const OPE_EQ:int = 23;
		public static const OPE_LT:int = 24;
		public static const OPE_LE:int = 25;
		public static const OPE_TEST:int = 26;
		public static const OPE_TESTSET:int = 27;
		public static const OPE_CALL:int = 28;
		public static const OPE_TAILCALL:int = 29; 
		public static const OPE_RETURN:int = 30;
		public static const OPE_FORLOOP:int = 31;
		public static const OPE_FORPREP:int = 32;
		public static const OPE_TFORLOOP:int = 33;
		public static const OPE_SETLIST:int = 34;
		public static const OPE_CLOSE:int = 35;
		public static const OPE_CLOSURE:int = 36;
		public static const OPE_VARARG:int = 37;
		
		public static const OPE2NAME:Object = {
			0:'MOVE',
			1:'LOADK',
			2:'LOADBOOL',
			3:'LOADNIL',
			4:'GETUPVAL',
			5:'GETGLOBAL',
			6:'GETTABLE',
			7:'SETGLOBAL',
			8:'SETUPVAL',
			9:'SETTABLE',
			10:'NEWTABLE',
			11:'SELF',
			12:'ADD',
			13:'SUB',
			14:'MUL',
			15:'DIV',
			16:'MOD',
			17:'POW',
			18:'UNM',
			19:'NOT',
			20:'LEN',
			21:'CONCAT',
			22:'JMP',
			23:'EQ',
			24:'LT',
			25:'LE',
			26:'TEST',
			27:'TESTSET',
			28:'CALL',
			29:'TAILCALL',
			30:'RETURN',
			31:'FORLOOP',
			32:'FORPREP',
			33:'TFORLOOP',
			34:'SETLIST',
			35:'CLOSE',
			36:'CLOSURE',
			37:'VARARG'
		};
		
		private var mOp:int;
		private var mA:int;
		private var mB:int;
		private var mC:int;
		
		public function Instruction(op:int,a:int,b:int,c:int) {
			mOp = op;
			mA = a;
			mB = b;
			mC = c;
		}
		
		public function get op():int {
			return mOp;
		}
		public function get a():int {
			return mA;
		}
		public function get b():int {
			return mB;
		}
		public function get c():int {
			return mC;
		}
		public function set a(v:int):void {
			mA = v;
		}
		public function set b(v:int):void {
			mB = v;
		}
		public function set c(v:int):void {
			mC = v;
		}
		
		public function toString():String {
			return '[Instruction: ' + OPE2NAME[mOp] + ' ' + mA + ' ' + mB + ' ' + mC + ']';
		}
	}
}
