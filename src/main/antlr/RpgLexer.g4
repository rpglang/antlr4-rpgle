/**
 * Define a grammar called RpgLexer
 */
 
lexer grammar RpgLexer;

@members {
	public boolean isEndOfToken() {
		return " (;".indexOf(_input.LA(1)) >=0;
	}
	int lastTokenType = 0;
	public void emit(Token token) {
		super.emit(token);
		lastTokenType = token.getType();
	}
	protected int getLastTokenType(){
		return lastTokenType;
	}
} 

// Parser Rules
	//End Source.  Not more parsing after this.
END_SOURCE :  '**' {getCharPositionInLine()==2}? ~[\r\n]~[\r\n]~[\r\n]~[\r\n*]~[\r\n]* EOL  -> pushMode(EndOfSourceMode) ;
    //Ignore or skip leading 5 white space.
LEAD_WS5 :  '     ' {getCharPositionInLine()==5}? -> skip;
LEAD_WS5_Comments :  WORD5 {getCharPositionInLine()==5}? -> channel(HIDDEN);
	//5 position blank means FREE, unless..
FREE_SPEC : {getCharPositionInLine()==5}? [ ] -> pushMode(OpCode),skip;
    // 6th position asterisk is a comment
COMMENT_SPEC_FIXED : {getCharPositionInLine()==5}? .'*' -> pushMode(FIXED_CommentMode),channel(HIDDEN) ;
    // X specs
DS_FIXED : D {getCharPositionInLine()==6}? -> pushMode(FIXED_DefSpec) ;
FS_FIXED : F {getCharPositionInLine()==6}? -> pushMode(FIXED_FileSpec) ;
OS_FIXED : O {getCharPositionInLine()==6}? -> pushMode(FIXED_OutputSpec) ;
CS_FIXED : C {getCharPositionInLine()==6}? -> pushMode(FIXED_CalcSpec),pushMode(OnOffIndicatorMode),pushMode(IndicatorMode) ;
CS_ExecSQL:C  '/' {getCharPositionInLine()==7}? EXEC_SQL -> pushMode(FIXED_CalcSpec_SQL);
IS_FIXED : I {getCharPositionInLine()==6}? -> pushMode(FIXED_InputSpec) ;
PS_FIXED : P {getCharPositionInLine()==6}? -> pushMode(FIXED_ProcedureSpec) ;
HS_FIXED : H {getCharPositionInLine()==6}? -> pushMode(HeaderSpecMode) ;

BLANK_LINE : [ ] {getCharPositionInLine()==6}? [ ]* NEWLINE -> skip;
BLANK_SPEC_LINE1 : . NEWLINE {getCharPositionInLine()==7}?-> skip;
BLANK_SPEC_LINE : .[ ] {getCharPositionInLine()==7}? [ ]* NEWLINE -> skip;
COMMENTS : [ ] {getCharPositionInLine()>=6}? [ ]*? '//' -> pushMode(FIXED_CommentMode),channel(HIDDEN) ;
EMPTY_LINE :
	'                                                                           '
	{getCharPositionInLine()>=80}? -> pushMode(FIXED_CommentMode),channel(HIDDEN) ;

	//Directives are not necessarily blank at pos 5
DIRECTIVE :  . {getCharPositionInLine()>=6}? [ ]*? '/' -> pushMode(DirectiveMode) ;

OPEN_PAREN : '(';
CLOSE_PAREN : ')';
NUMBER : ([0-9]+([.][0-9]*)?) | [.][0-9]+ ;
SEMI : ';';
COLON : ':';
ID : ('*' {getCharPositionInLine()>7}? '*'? [a-zA-Z])?
        [#@%$a-zA-Z]{getCharPositionInLine()>7}? [#@$a-zA-Z0-9_]* ;
NEWLINE : ('\r'? '\n') -> skip;
WS : [ \t] {getCharPositionInLine()>6}? [ \t]* -> skip ; // skip spaces, tabs

mode DirectiveTitle;
TITLE_Text : ~[\r\n]+ -> type(DIR_OtherText);
TITLE_EOL : NEWLINE -> type(EOL),popMode,popMode;

mode DirectiveMode;
DIR_NOT: N O T ;
DIR_DEFINED: D E F I N E D ;
DIR_FREE: {_input.LA(-1)=='/'}? F R E E  -> pushMode(SKIP_REMAINING_WS);
DIR_ENDFREE: {_input.LA(-1)=='/'}? E N D  '-' F R E E  -> pushMode(SKIP_REMAINING_WS);
DIR_TITLE:{_input.LA(-1)=='/'}? (T I T L E ) -> pushMode(DirectiveTitle);
DIR_EJECT: {_input.LA(-1)=='/'}? E J E C T  -> pushMode(SKIP_REMAINING_WS);
DIR_SPACE: {_input.LA(-1)=='/'}? S P A C E ;
DIR_SET: {_input.LA(-1)=='/'}?  S E T ;
DIR_RESTORE: {_input.LA(-1)=='/'}? R E S T O R E ;
DIR_COPY: {_input.LA(-1)=='/'}? C O P Y ;
DIR_INCLUDE: {_input.LA(-1)=='/'}? I N C L U D E ;
DIR_EOF: {_input.LA(-1)=='/'}? E O F ;
DIR_DEFINE: {_input.LA(-1)=='/'}? (D E F I N E );
DIR_UNDEFINE: {_input.LA(-1)=='/'}? (U N D E F I N E );
DIR_IF: {_input.LA(-1)=='/'}? (I F );
DIR_ELSE: {_input.LA(-1)=='/'}? (E L S E );
DIR_ELSEIF: {_input.LA(-1)=='/'}? (E L S E I F );
DIR_ENDIF: {_input.LA(-1)=='/'}? (E N D I F );
DIR_Number: NUMBER -> type(NUMBER);
DIR_WhiteSpace: [ ] -> type(WS),skip;
DIR_OtherText : ~[/'"\r\n \t,()]+ ;
DIR_Comma : [,] -> skip;
DIR_Slash : [/] ;
DIR_OpenParen: [(] -> type(OPEN_PAREN);
DIR_CloseParen: [)] -> type(CLOSE_PAREN);
DIR_DblStringLiteralStart: ["] -> pushMode(InDoubleStringMode),type(StringLiteralStart) ;
DIR_StringLiteralStart: ['] -> pushMode(InStringMode),type(StringLiteralStart) ;
DIR_EOL : [ ]* NEWLINE {setText(getText().trim());} -> type(EOL),popMode;

mode SKIP_REMAINING_WS;
DIR_FREE_OTHER_TEXT: ~[\r\n]* -> popMode,skip;

mode EndOfSourceMode;
EOS_Text : ~[\r\n]+ ;
EOS_EOL : NEWLINE -> type(EOL);

// -----------------  ---------------------
mode OpCode;
OP_WS: [ \t] {getCharPositionInLine()>6}? [ \t]* -> skip;
OP_ACQ: A C Q {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_BEGSR: B E G S R {isEndOfToken()}?-> mode(FREE);
OP_CALLP: C A L L P {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_CHAIN: C H A I N {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_CLEAR: C L E A R {isEndOfToken()}?-> mode(FREE);
OP_CLOSE: C L O S E {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_COMMIT: C O M M I T {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_DEALLOC: D E A L L O C {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_DELETE: D E L E T E {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_DOU: D O U {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_DOW: D O W {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_DSPLY: D S P L Y {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_DUMP: D U M P {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_ELSE: E L S E {isEndOfToken()}?-> mode(FREE);
OP_ELSEIF: E L S E I F {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_ENDDO: E N D D O {isEndOfToken()}?-> mode(FREE);
OP_ENDFOR: E N D F O R {isEndOfToken()}?-> mode(FREE);
OP_ENDIF: E N D I F {isEndOfToken()}?-> mode(FREE);
OP_ENDMON: E N D M O N {isEndOfToken()}?-> mode(FREE);
OP_ENDSL: E N D S L {isEndOfToken()}?-> mode(FREE);
OP_ENDSR: E N D S R {isEndOfToken()}?-> mode(FREE);
OP_EVAL: E V A L {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_EVALR: E V A L R {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_EVAL_CORR: E V A L [-]C O R R {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_EXCEPT: E X C E P T {isEndOfToken()}?-> mode(FREE);
OP_EXFMT: E X F M T {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_EXSR: E X S R {isEndOfToken()}?-> mode(FREE);
OP_FEOD: F E O D {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_FOR: F O R {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_FORCE: F O R C E {isEndOfToken()}?-> mode(FREE);
OP_IF: I F {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_IN: I N {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_ITER: I T E R {isEndOfToken()}?-> mode(FREE);
OP_LEAVE: L E A V E {isEndOfToken()}?-> mode(FREE);
OP_LEAVESR: L E A V E S R {isEndOfToken()}?-> mode(FREE);
OP_MONITOR: M O N I T O R {isEndOfToken()}?-> mode(FREE);
OP_NEXT: N E X T {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_ON_ERROR: O N [-]E R R O R {isEndOfToken()}?-> mode(FREE);
OP_OPEN: O P E N {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_OTHER: O T H E R {isEndOfToken()}?-> mode(FREE);
OP_OUT: O U T {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_POST: P O S T {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_READ: R E A D {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_READC: R E A D C {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_READE: R E A D E {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_READP: R E A D P {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_READPE: R E A D P E {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_REL: R E L {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_RESET: R E S E T {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_RETURN: R E T U R N {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_ROLBK: R O L B K {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_SELECT: S E L E C T {isEndOfToken()}?-> mode(FREE);
OP_SETGT: S E T G T {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_SETLL: S E T L L {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_SORTA: S O R T A {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_TEST: T E S T {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_UNLOCK: U N L O C K {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_UPDATE: U P D A T E {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_WHEN: W H E N {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_WRITE: W R I T E {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_XML_INTO: X M L [-]I N T O {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_XML_SAX: X M L [-]S A X {isEndOfToken()}?-> mode(FREE),pushMode(FreeOpExtender);
OP_NoSpace: -> skip,mode(FREE);//,pushMode(FreeOpExtender);

mode FREE;
//OP_COMMIT: C O M M I T  -> mode(FREE),pushMode(FreeOpExtender);
DS_Standalone : D  C  L  '-' S  ;//-> pushMode(F_SPEC_FREE);
DS_DataStructureStart : D  C  L  '-' D S  ;//-> pushMode(F_SPEC_FREE);
DS_DataStructureEnd : E  N  D  '-' D S  ;//-> pushMode(F_SPEC_FREE);
DS_PrototypeStart : D  C  L  '-' P R  ;//-> pushMode(F_SPEC_FREE);
DS_PrototypeEnd : E  N  D  '-' P R  ;//-> pushMode(F_SPEC_FREE);
DS_Parm : D  C  L  '-' P A R M  ;
DS_SubField : D  C  L  '-' S U B F  ;
DS_ProcedureInterfaceStart : D  C  L  '-' P I  ;//-> pushMode(F_SPEC_FREE);
DS_ProcedureInterfaceEnd : E  N  D  '-' P I  ;//-> pushMode(F_SPEC_FREE);
DS_ProcedureStart : D  C  L  '-' P R O C  ;//-> pushMode(F_SPEC_FREE);
DS_ProcedureEnd : E  N  D  '-' P R O C  ;//-> pushMode(F_SPEC_FREE);
DS_Constant : D  C  L  '-' C  ;//-> pushMode(F_SPEC_FREE);

FS_FreeFile : D  C  L  '-' F  ;//-> pushMode(F_SPEC_FREE);
H_SPEC : C  T  L  '-' O P T ;
FREE_CONT: '...' [ ]* NEWLINE WORD5[ ]+ {setText("...");} -> type(CONTINUATION);
FREE_COMMENTS80 : ~[\r\n] {getCharPositionInLine()>80}? ~[\r\n]* -> channel(HIDDEN); // skip comments after 80
EXEC_SQL: E X E C [ ]+S Q L -> pushMode(SQL_MODE) ;

// Built In functions
BIF_ABS: '%'A B S ;
BIF_ADDR: '%'A D D R ;
BIF_ALLOC: '%'A L L O C ;
BIF_BITAND: '%'B I T A N D ;
BIF_BITNOT: '%'B I T N O T ;
BIF_BITOR: '%'B I T O R ;
BIF_BITXOR: '%'B I T X O R ;
BIF_CHAR: '%'C H A R ;
BIF_CHECK: '%'C H E C K ;
BIF_CHECKR: '%'C H E C K R ;
BIF_DATE: '%'D A T E ;
BIF_DAYS: '%'D A Y S ;
BIF_DEC: '%'D E C ;
BIF_DECH: '%'D E C H ;
BIF_DECPOS: '%'D E C P O S ;
BIF_DIFF: '%'D I F F ;
BIF_DIV: '%'D I V ;
BIF_EDITC: '%'E D I T C ;
BIF_EDITFLT: '%'E D I T F L T ;
BIF_EDITW: '%'E D I T W ;
BIF_ELEM: '%'E L E M ;
BIF_EOF: '%'E O F ;
BIF_EQUAL: '%'E Q U A L ;
BIF_ERROR: '%'E R R O R ;
BIF_FIELDS: '%'F I E L D S ;
BIF_FLOAT: '%'F L O A T ;
BIF_FOUND: '%'F O U N D ;
BIF_GRAPH: '%'G R A P H ;
BIF_HANDLER: '%'H A N D L E R ;
BIF_HOURS: '%'H O U R S ;
BIF_INT: '%'I N T ;
BIF_INTH: '%'I N T H ;
BIF_KDS: '%'K D S ;
BIF_LEN: '%'L E N ;
BIF_LOOKUP: '%'L O O K U P ;
BIF_LOOKUPLT: '%'L O O K U P L T ;
BIF_LOOKUPLE: '%'L O O K U P L E ;
BIF_LOOKUPGT: '%'L O O K U P G T ;
BIF_LOOKUPGE: '%'L O O K U P G E ;
BIF_MINUTES: '%'M I N U T E S ;
BIF_MONTHS: '%'M O N T H S ;
BIF_MSECONDS: '%'M S E C O N D S ;
BIF_NULLIND: '%'N U L I N D ;
BIF_OCCUR: '%'O C U R ;
BIF_OPEN: '%'O P E N ;
BIF_PADDR: '%'P A D D R ;
BIF_PARMS: '%'P A R M S ;
BIF_PARMNUM: '%'P A R M N U M ;
BIF_REALLOC: '%'R E A L L O C ;
BIF_REM: '%'R E M ;
BIF_REPLACE: '%'R E P L A C E ;
BIF_SCAN: '%'S C A N ;
BIF_SCANRPL: '%'S C A N R P L ;
BIF_SECONDS: '%'S E C O N D ;
BIF_SHTDN: '%'S H T D N ;
BIF_SIZE: '%'S I Z E ;
BIF_SQRT: '%'S Q R T ;
BIF_STATUS: '%'S T A T U S ;
BIF_STR: '%'S T R ;
BIF_SUBARR: '%'S U B A R R ;
BIF_SUBDT: '%'S U B D T ;
BIF_SUBST: '%'S U B S T ;
BIF_THIS: '%'T H I S ;
BIF_TIME: '%'T I M E ;
BIF_TIMESTAMP: '%'T I M E S T A M P ;
BIF_TLOOKUP: '%'T L O O K U P ;
BIF_TLOOKUPLT: '%'T L O O K U P L T ;
BIF_TLOOKUPLE: '%'T L O O K U P L E ;
BIF_TLOOKUPGT: '%'T L O O K U P G T ;
BIF_TLOOKUPGE: '%'T L O O K U P G E ;
BIF_TRIM: '%'T R I M ;
BIF_TRIML: '%'T R I M L ;
BIF_TRIMR: '%'T R I M R ;
BIF_UCS2: '%'U C S '2';
BIF_UNS: '%'U N S ;
BIF_UNSH: '%'U N S H ;
BIF_XFOOT: '%'X F O O T ;
BIF_XLATE: '%'X L A T E ;
BIF_XML: '%'X M L ;
BIF_YEARS: '%'Y E A R S ;

// Symbolic Constants
SPLAT_ALL: '*'A L L ;
SPLAT_NONE: '*'N O N E ;
SPLAT_YES: '*'Y E S ;
SPLAT_NO: '*'N O ;
SPLAT_ILERPG: '*'I L E R P G ;
SPLAT_COMPAT: '*'C O M P A T ;
SPLAT_CRTBNDRPG: '*'C R T B N D R P G ;
SPLAT_CRTRPGMOD: '*'C R T R P G M O D ;
SPLAT_VRM: '*'V [0-9]R [0-9]M [0-9];
SPLAT_ALLG: '*'A L L G ;
SPLAT_ALLU: '*'A L L U ;
SPLAT_ALLTHREAD: '*'A L L T H R E A D ;
SPLAT_ALLX: '*'A L L X ;
SPLAT_BLANKS: ('*'B L A N K S  | '*'B L A N K );
SPLAT_CANCL: '*'C A N C L ;
SPLAT_CYMD: '*'C Y M D ('0' | '/' | '-' | '.' | ',' | '&')?;
SPLAT_CMDY: '*'C M D Y ('0' | '/' | '-' | '.' | ',' | '&')?;
SPLAT_CDMY: '*'C D M Y ('0' | '/' | '-' | '.' | ',' | '&')?;
SPLAT_MDY: '*'M D Y ('0' | '/' | '-' | '.' | ',' | '&')?;
SPLAT_DMY: '*'D M Y ('0' | '/' | '-' | '.' | ',' | '&')?;
SPLAT_DFT: '*'D F T ;
SPLAT_YMD: '*'Y M D ('0' | '/' | '-' | '.' | ',' | '&')?;
SPLAT_JUL: '*'J U L ('0' | '/' | '-' | '.' | ',' | '&')?;
SPLAT_JAVA: '*'J A V A ;
SPLAT_ISO: '*'I S O ('0' | '-')?;
SPLAT_USA: '*'U S A ('0' | '/')?;
SPLAT_EUR: '*'E U R ('0' | '.')?;
SPLAT_JIS: '*'J I S ('0' | '-')?;
SPLAT_DATE: '*'D A T E ;
SPLAT_DAY:  '*'D A Y ;
SPlAT_DETC: '*'D E T C ;
SPLAT_DETL: '*'D E T L ;
SPLAT_DTAARA: '*'D T A A R A ;
SPLAT_END:  '*'E N D ;
SPLAT_ENTRY: '*'E N T R Y ;
SPLAT_EQUATE: '*'E Q U A T E ;
SPLAT_EXTDFT: '*'E X T D F T ;
SPLAT_EXT: '*'E X T ;
SPLAT_FILE: '*'F I L E ;
SPLAT_GETIN: '*'G E T I N ;
SPLAT_HIVAL: '*'H I V A L ;
SPLAT_INIT: '*'I N I T ;
SPLAT_INDICATOR: ('*'I N [0-9][0-9] | '*'I N '('[0-9][0-9]')');
SPLAT_INZSR: '*'I N Z S R ;
SPLAT_IN: '*'I N ;
SPLAT_INPUT: '*'I N P U T ;
SPLAT_OUTPUT: '*'O U T P U T ;
SPLAT_JOBRUN: '*'J O B R U N ;
SPLAT_JOB: '*'J O B ;
SPLAT_LDA: '*'L D A ;
SPLAT_LIKE: '*'L I K E ;
SPLAT_LONGJUL: '*'L O N G J U L ;
SPLAT_LOVAL: '*'L O V A L ;
SPLAT_KEY: '*'K E Y ;
SPLAT_MONTH: '*'M O N T H ;
SPLAT_NEXT: '*'N E X T ;
SPLAT_NOIND: '*'N O I N D ;
SPLAT_NOKEY: '*'N O K E Y ;
SPLAT_NULL: '*'N U L L ;
SPLAT_OFL: '*'O F L ;
SPLAT_ON: '*'O N ;
SPLAT_ONLY: '*'O N L Y ;
SPLAT_OFF: '*'O F F ;
SPLAT_PDA: '*'P D A ;
SPLAT_PLACE: '*'P L A C E ;
SPLAT_PSSR: '*'P S S R ;
SPLAT_ROUTINE: '*'R O U T I N E ;
SPLAT_START: '*'S T A R T ;
SPLAT_SYS: '*'S Y S ;
SPLAT_TERM: '*'T E R M ;
SPLAT_TOTC: '*'T O T C ;
SPLAT_TOTL: '*'T O T L ;
SPLAT_USER: '*'U S E R ;
SPLAT_VAR: '*'V A R ;
SPLAT_YEAR: '*'Y E A R ;
SPLAT_ZEROS: ('*'Z E R O S  | '*'Z E R O );
SPLAT_HMS: '*'H M S ('0' | '/' | '-' | '.' | ',' | '&')?;
SPLAT_INLR: '*'I N L R ;
SPLAT_INOF: '*'I N O F ;
SPLAT_DATA: '*'D A T A ;
SPLAT_ASTFILL: '*'A S T F I L ;
SPLAT_CURSYM: '*'C U R S Y M ;
SPLAT_MAX: '*'M A X ;
SPLAT_LOCK: '*'L O C K ;
SPLAT_PROGRAM: '*'P R O G R A M ;
SPLAT_EXTDESC: '*'E X T D E S C ;
//Durations
SPLAT_D: '*'{getLastTokenType() == COLON}? D ;
SPLAT_H: '*'{getLastTokenType() == COLON}? H ;
SPLAT_HOURS: '*'{getLastTokenType() == COLON}? H O U R S ;
SPLAT_DAYS: '*' {getLastTokenType() == COLON}? D A Y S;
SPLAT_M: '*'{getLastTokenType() == COLON}? M ;
SPLAT_MINUTES: '*'{getLastTokenType() == COLON}? M I N U T E S ;
SPLAT_MONTHS: '*'{getLastTokenType() == COLON}? M O N T H S ;
SPLAT_MN: '*'{getLastTokenType() == COLON}? M N ; //Minutes
SPLAT_MS: '*'{getLastTokenType() == COLON}? M S ; //Minutes
SPLAT_MSECONDS: '*'{getLastTokenType() == COLON}? M S E C O N D S ;
SPLAT_S: '*'{getLastTokenType() == COLON}? S ;
SPLAT_SECONDS: '*'{getLastTokenType() == COLON}? S E C O N D S ;
SPLAT_Y: '*'{getLastTokenType() == COLON}? Y ;
SPLAT_YEARS: '*' {getLastTokenType() == COLON}? Y E A R S;


// Reserved Words
UDATE : U  D  A  T  E  ;
DATE : '*' D  A  T  E  ;
UMONTH : U  M  O  N  T  H  ;
MONTH : '*' M  O  N  T  H  ;
UYEAR : U  Y  E  A  R  ;
YEAR : '*' Y  E  A  R  ;
UDAY : U  D  A  Y  ;
DAY : '*' D  A  Y  ;
PAGE : P  A  G  E  [1-7]? ;


//DataType
CHAR: C H A R ;
VARCHAR: [Va]A R C H A R ;
UCS2: U C S [2];
DATE_: D A T E ;
VARUCS2: [Va]A R U C S [2];
GRAPH: G R A P H ;
VARGRAPH: [Va]A R G R A P H ;
IND: I N D ;
PACKED: P A C K E D ;
ZONED: Z O N E D ;
BINDEC: B I N D E C ;
INT: I N T ;
UNS: U N S ;
FLOAT: F L O A T ;
TIME: T I M E ;
TIMESTAMP: T I M E S T A M P ;
POINTER: P O I N T E R ;
OBJECT: O B J E C T ;

// More Keywords
KEYWORD_ALIAS : A L I A S ;
KEYWORD_ALIGN : A L I G N ;
KEYWORD_ALT : A L T ;
KEYWORD_ALTSEQ : A L T S E Q ;
KEYWORD_ASCEND : A S C E N D ;
KEYWORD_BASED : B A S E D ;
KEYWORD_CCSID : C C S I D ;
KEYWORD_CLASS : C L A S S ;
KEYWORD_CONST : C O N S T ;
KEYWORD_CTDATA : C T D A T A ;
KEYWORD_DATFMT : D A T F M T ;
KEYWORD_DESCEND : D E S C E N D ;
KEYWORD_DIM : D I M ;
KEYWORD_DTAARA : D T A A R A ;
KEYWORD_EXPORT : E X P O R T ;
KEYWORD_EXT : E X T ;
KEYWORD_EXTFLD : E X T F L D ;
KEYWORD_EXTFMT : E X T F M T ;
KEYWORD_EXTNAME : E X T N A M E ;
KEYWORD_EXTPGM : E X T P G M ;
KEYWORD_EXTPROC : E X T P R O C ;
KEYWORD_FROMFILE : F R O M F I L E ;
KEYWORD_IMPORT : I M P O R T ;
KEYWORD_INZ : I N Z ;
KEYWORD_LEN : L E N ;
KEYWORD_LIKE : L I K E ;
KEYWORD_LIKEDS : L I K E D S ;
KEYWORD_LIKEFILE : L I K E F I L E ;
KEYWORD_LIKEREC : L I K E R E C ;
KEYWORD_NOOPT : N O O P T ;
KEYWORD_OCCURS : O C C U R S ;
KEYWORD_OPDESC : O P D E S C ;
KEYWORD_OPTIONS : O P T I O N S ;
KEYWORD_OVERLAY : O V E R L A Y ;
KEYWORD_PACKEVEN : P A C K E V E N ;
KEYWORD_PERRCD : P E R R C D ;
KEYWORD_PREFIX : P R E F I X ;
KEYWORD_POS : P O S ;
KEYWORD_PROCPTR : P R O C P T R ;
KEYWORD_QUALIFIED : Q U A L I F I E D ;
KEYWORD_RTNPARM : R T N P A R M ;
KEYWORD_STATIC : S T A T I C ;
KEYWORD_TEMPLATE : T E M P L A T E ;
KEYWORD_TIMFMT : T I M F M T ;
KEYWORD_TOFILE : T O F I L E ;
KEYWORD_VALUE : V A L U E ;
KEYWORD_VARYING : V A R Y I N G ;
// File spec keywords
KEYWORD_BLOCK : B L O C K ;
KEYWORD_COMMIT : C O M M I T ;
KEYWORD_DEVID : D E V I D ;
KEYWORD_EXTDESC : E X T D E S C ;
KEYWORD_EXTFILE  : E X T F I L E ;
KEYWORD_EXTIND  : E X T I N D ;
KEYWORD_EXTMBR  : E X T M B R ;
KEYWORD_FORMLEN : F O R M L E N ;
KEYWORD_FORMOFL : F O R M O F L ;
KEYWORD_IGNORE : I G N O R E ;
KEYWORD_INCLUDE : I N C L U D E ;
KEYWORD_INDDS : I N D D S ;
KEYWORD_INFDS : I N F D S ;
KEYWORD_INFSR : I N F S R ;
KEYWORD_KEYLOC : K E Y L O C ;
KEYWORD_MAXDEV : M A X D E V ;
KEYWORD_OFLIND : O F L I N D ;
KEYWORD_PASS : P A S S ;
KEYWORD_PGMNAME : P G M N A M E ;
KEYWORD_PLIST : P L I S T ;
KEYWORD_PRTCTL : P R T C T L ;
KEYWORD_RAFDATA : R A F D A T A ;
KEYWORD_RECNO : R E C N O ;
KEYWORD_RENAME : R E N A M E ;
KEYWORD_SAVEDS : S A V E D S ;
KEYWORD_SAVEIND : S A V E I N D ;
KEYWORD_SFILE : S F I L E ;
KEYWORD_SLN : S L N ;
KEYWORD_SQLTYPE : S Q L T Y P E {_modeStack.contains(FIXED_DefSpec)}?;
KEYWORD_USROPN : U S R O P N ;
KEYWORD_DISK : D I S K ;
KEYWORD_WORKSTN : W O R K S T N ;
KEYWORD_PRINTER : P R I N T E R ;
KEYWORD_SPECIAL : S P E C I A L ;
KEYWORD_KEYED : K E Y E D ;
KEYWORD_USAGE : U S A G E ;
KEYWORD_PSDS: P S D S ;

AMPERSAND: '&';

// Boolean operators
AND : A  N  D  ;
OR : O  R  ;
NOT : N  O  T  ;

// Arithmetical Operators
PLUS : '+' ;
MINUS : '-' ;
EXP : '**' ;
ARRAY_REPEAT: {_input.LA(2) == ')' && _input.LA(-1) == '('}? '*' ;
MULT_NOSPACE: {_input.LA(2) != 32}? '*';
MULT: {_input.LA(2) == 32}? '*' ;
DIV : '/' ;

// Assignment Operators
CPLUS : '+=' ;
CMINUS : '-=' ;
CMULT : '*=' ;
CDIV : '/=' ;
CEXP : '**=' ;

// Comparison Operators
GT : '>' ;
LT : '<' ;
GE : '>=' ;
LE : '<=' ;
NE : '<>' ;

//--------------
//OP_E: '(' [aAdDeEhHmMnNpPrRtTzZ][aAdDeEhHmMnNpPrRtTzZ]? ')';
FREE_OPEN_PAREN: OPEN_PAREN -> type(OPEN_PAREN);
FREE_CLOSE_PAREN: CLOSE_PAREN -> type(CLOSE_PAREN);
FREE_DOT: '.';
FREE_NUMBER_CONT: NUMBER {_modeStack.peek()==FIXED_DefSpec}? -> pushMode(NumberContinuation),type(NUMBER);
FREE_NUMBER: NUMBER -> type(NUMBER);
EQUAL: '=';

FREE_COLON: COLON -> type(COLON);
FREE_BY: B Y ;
FREE_TO: T O ;
FREE_DOWNTO: D O W N T O ;
FREE_ID: ID -> type(ID);
//FREE_STRING: ['] ~[']* ['];
HexLiteralStart: X ['] -> pushMode(InStringMode) ;
DateLiteralStart: D ['] -> pushMode(InStringMode) ;
TimeLiteralStart: T ['] -> pushMode(InStringMode) ;
TimeStampLiteralStart: Z ['] -> pushMode(InStringMode) ;
GraphicLiteralStart: G ['] -> pushMode(InStringMode) ;
UCS2LiteralStart: U ['] -> pushMode(InStringMode) ;
StringLiteralStart: ['] -> pushMode(InStringMode) ;
FREE_COMMENTS:  [ ]*? '//' {getCharPositionInLine()>=8}? -> pushMode(FIXED_CommentMode_HIDDEN),channel(HIDDEN) ;
FREE_WS: [ \t] {getCharPositionInLine()>6}? [ \t]* -> skip;
FREE_CONTINUATION : '...'
	{_modeStack.peek()!=FIXED_CalcSpec && _modeStack.peek()!=FIXED_DefSpec}?
	WS* NEWLINE -> type(CONTINUATION);
C_FREE_CONTINUATION_DOTS : '...' {_modeStack.peek()==FIXED_CalcSpec}? WS* NEWLINE
	(WORD5 C  ~[*] '                            ') {setText("...");} -> type(CONTINUATION);
D_FREE_CONTINUATION_DOTS : '...' {_modeStack.peek()==FIXED_DefSpec}? WS* NEWLINE
	(WORD5 D  ~[*] '                            ') {setText("...");} -> type(CONTINUATION);
C_FREE_CONTINUATION: NEWLINE {_modeStack.peek()==FIXED_CalcSpec}?
	(
		(WORD5 ~[\r\n] [*] ~[\r\n]* NEWLINE) //Skip mid statement comments
	|	(WORD5 ~[\r\n] [ ]* NEWLINE) //Skip mid statement blanks
	)*
	 WORD5 C  ~[*] '                            ' -> skip;
D_FREE_CONTINUATION: NEWLINE {_modeStack.peek() == FIXED_DefSpec}?
	WORD5 D  ~[*] '                                    ' -> skip;
F_FREE_CONTINUATION: NEWLINE {_modeStack.peek() == FIXED_FileSpec}?
	WORD5 F  ~[*] '                                    ' -> skip;
FREE_LEAD_WS5 :   '     ' {getCharPositionInLine()==5}? -> skip;
FREE_LEAD_WS5_Comments :  WORD5 {getCharPositionInLine()==5}? -> channel(HIDDEN);
FREE_FREE_SPEC :  [ ][ ] {getCharPositionInLine()==7}? -> skip;

C_FREE_NEWLINE: NEWLINE {_modeStack.peek()==FIXED_CalcSpec}? -> popMode,popMode;
O_FREE_NEWLINE: NEWLINE {_modeStack.peek()==FIXED_OutputSpec_PGMFIELD}? -> type(EOL),popMode,popMode,popMode;
D_FREE_NEWLINE: NEWLINE {_modeStack.peek() == FIXED_DefSpec}? -> type(EOL),popMode,popMode;
F_FREE_NEWLINE: NEWLINE {_modeStack.peek() == FIXED_FileSpec}? -> type(EOL),popMode,popMode;
FREE_NEWLINE:   NEWLINE {_modeStack.peek()!=FIXED_CalcSpec}? -> skip,popMode;
FREE_SEMI: SEMI -> popMode, pushMode(FREE_ENDED);  //Captures // immediately following the semi colon

mode NumberContinuation;
NumberContinuation_CONTINUATION: ([ ]* NEWLINE)
	WORD5 D  ~[*] '                            ' [ ]* -> skip;
NumberPart: NUMBER -> popMode;
NumberContinuation_ANY: -> popMode,skip;

mode FixedOpCodes; //Referenced (not used)
OP_ADD: A D D ;
OP_ADDDUR: OP_ADD D U R ;
OP_ALLOC: A L L O C ;
OP_ANDxx: A N D [0-9][0-9];
OP_ANDEQ: A N D E Q ;
OP_ANDNE: A N D N E ;
OP_ANDLE: A N D L E ;
OP_ANDLT: A N D L T ;
OP_ANDGE: A N D G E ;
OP_ANDGT: A N D G T ;
OP_BITOFF: B I T O F F ;
OP_BITON: B I T O N ;
OP_CABxx: C A B [0-9][0-9];
OP_CABEQ: C A B E Q ;
OP_CABNE: C A B N E ;
OP_CABLE: C A B L E ;
OP_CABLT: C A B L T ;
OP_CABGE: C A B G E ;
OP_CABGT: C A B G T ;
OP_CALL: C A L L ;
OP_CALLB: OP_CALL B ;
OP_CASEQ: C A S E Q ;
OP_CASNE: C A S N E ;
OP_CASLE: C A S L E ;
OP_CASLT: C A S L T ;
OP_CASGE: C A S G E ;
OP_CASGT: C A S G T ;
OP_CAS: C A S ;
OP_CAT: C A T ;
OP_CHECK: C H E C K ;
OP_CHECKR: C H E C K R ;
OP_COMP: C O M P ;
OP_DEFINE: D E F I N E ;
OP_DIV: D I V ;
OP_DO: D O ;
OP_DOUEQ: D O U E Q ;
OP_DOUNE: D O U N E ;
OP_DOULE: D O U L E ;
OP_DOULT: D O U L T ;
OP_DOUGE: D O U G E ;
OP_DOUGT: D O U G T ;
OP_DOWEQ: D O W E Q ;
OP_DOWNE: D O W N E ;
OP_DOWLE: D O W L E ;
OP_DOWLT: D O W L T ;
OP_DOWGE: D O W G E ;
OP_DOWGT: D O W G T ;
OP_END: E N D ;
OP_ENDCS: E N D C S ;
OP_EXTRCT: E X T R C T ;
OP_GOTO: G O T O ;
OP_IFEQ: I F E Q ;
OP_IFNE: I F N E ;
OP_IFLE: I F L E ;
OP_IFLT: I F L T ;
OP_IFGE: I F G E ;
OP_IFGT: I F G T ;
OP_KFLD: K F L D ;
OP_KLIST: K L I S T ;
OP_LOOKUP: L O O K U P ;
OP_MHHZO: M H H Z O ;
OP_MHLZO: M H L Z O ;
OP_MLHZO: M L H Z O ;
OP_MLLZO: M L L Z O ;
OP_MOVE: M O V E ;
OP_MOVEA: M O V E A ;
OP_MOVEL: M O V E L ;
OP_MULT: M U L T ;
OP_MVR: M V R ;
OP_OCCUR: O C C U R ;
OP_OREQ: O R E Q ;
OP_ORNE: O R N E ;
OP_ORLE: O R L E ;
OP_ORLT: O R L T ;
OP_ORGE: O R G E ;
OP_ORGT: O R G T ;
OP_PARM: P A R M ;
OP_PLIST: P L I S T ;
OP_REALLOC: R E A L L O C ;
OP_SCAN: S C A N ;
OP_SETOFF: S E T O F F ;
OP_SETON: S E T O N ;
OP_SHTDN: S H T D N ;
OP_SQRT: S Q R T ;
OP_SUB: S U B ;
OP_SUBDUR: S U B D U R ;
OP_SUBST: S U B S T ;
OP_TAG: T A G ;
OP_TESTB: T E S T B ;
OP_TESTN: T E S T N ;
OP_TESTZ: T E S T Z ;
OP_TIME: T I M E ;
OP_WHENEQ: W H E N E Q ;
OP_WHENNE: W H E N N E ;
OP_WHENLE: W H E N L E ;
OP_WHENLT: W H E N L T ;
OP_WHENGE: W H E N G E ;
OP_WHENGT: W H E N G T ;
OP_XFOOT: X F O O T ;
OP_XLATE: X L A T E ;
OP_Z_ADD: Z '-'A D D ;
OP_Z_SUB: Z '-'S U B ;

mode FREE_ENDED;
FE_BLANKS : [ ]+ -> skip;
FE_COMMENTS: '//' -> popMode,pushMode(FIXED_CommentMode_HIDDEN),channel(HIDDEN) ;
FE_NEWLINE : NEWLINE -> popMode,skip;

mode InStringMode;
	//  Any char except +,- or ', or a + or - followed by more than just whitespace
StringContent: (
       ~['\r\n+-]
       | [+-] [ ]* {_input.LA(1)!=' ' && _input.LA(1)!='\r' && _input.LA(1)!='\n'}? // Plus is ok as long as it's not the last char
       )+;// space or not
StringEscapedQuote: [']['] {setText("'");};
StringLiteralEnd: ['] -> popMode;
FIXED_FREE_STRING_CONTINUATION: ('+' [ ]* NEWLINE)
  {_modeStack.contains(FIXED_CalcSpec) || _modeStack.contains(FIXED_DefSpec)
     || _modeStack.contains(FIXED_OutputSpec)}?
   -> pushMode(EatCommentLinesPlus),pushMode(EatCommentLines),skip;
FIXED_FREE_STRING_CONTINUATION_MINUS: ('-' [ ]* NEWLINE)
  {_modeStack.contains(FIXED_CalcSpec) || _modeStack.contains(FIXED_DefSpec)
     || _modeStack.contains(FIXED_OutputSpec)}?
   -> pushMode(EatCommentLines),skip;
FREE_STRING_CONTINUATION: {!_modeStack.contains(FIXED_CalcSpec)
     && !_modeStack.contains(FIXED_DefSpec)
     && !_modeStack.contains(FIXED_OutputSpec)}?
      '+' [ ]* NEWLINE '       ' [ ]* -> skip;
FREE_STRING_CONTINUATION_MINUS: {!_modeStack.contains(FIXED_CalcSpec)
     && !_modeStack.contains(FIXED_DefSpec)
     && !_modeStack.contains(FIXED_OutputSpec)}?
      '-' [ ]* NEWLINE '       ' -> skip;
PlusOrMinus: [+-];

mode InDoubleStringMode;
	//  Any char except +,- or ", or a + or - followed by more than just whitespace
DblStringContent: ~["\r\n]+ -> type(StringContent);
DblStringLiteralEnd: ["] -> popMode,type(StringLiteralEnd);


//This mode is basically a language independent flag.
mode EatCommentLinesPlus;
EatCommentLinesPlus_Any: -> popMode,skip;

// Inside continuations, ignore comment and blank lines.
mode EatCommentLines;
EatCommentLines_WhiteSpace: WORD5~[\r\n]{getCharPositionInLine()==6}?[ ]* NEWLINE -> skip;
EatCommentLines_StarComment:
   WORD5~[\r\n]{getCharPositionInLine()==6}? [*] ~[\r\n]* NEWLINE -> skip;
FIXED_FREE_STRING_CONTINUATION_Part2:
   (
     WORD5
     ( C {_modeStack.contains(FIXED_CalcSpec)}?
      | D {_modeStack.contains(FIXED_DefSpec)}?
      | O {_modeStack.contains(FIXED_OutputSpec)}?
     )
     ~[*]
     ( '                            ' {_modeStack.contains(FIXED_CalcSpec)}?
       | '                                    ' {_modeStack.contains(FIXED_DefSpec)}?
       | '                                             ' {_modeStack.contains(FIXED_OutputSpec)}?
     )
     ([ ]* {_modeStack.peek() == EatCommentLinesPlus}?
      |
     )  // If it plus continuation eat whitespace.
   )
   -> type(CONTINUATION),skip ;
//Deliberate match no char, pop out again
EatCommentLines_NothingLeft: -> popMode,skip;

mode InFactorStringMode;
InFactor_StringContent:(
~[\r\n']
		{(getCharPositionInLine()>=12 && getCharPositionInLine()<=25)
			|| (getCharPositionInLine()>=36 && getCharPositionInLine()<=49)
			|| (getCharPositionInLine()>=50 && getCharPositionInLine()<=63)
		}?
)+ -> type(StringContent);

InFactor_StringEscapedQuote: ['][']
		{(getCharPositionInLine()>=12 && getCharPositionInLine()<=24)
			|| (getCharPositionInLine()>=36 && getCharPositionInLine()<=48)
			|| (getCharPositionInLine()>=50 && getCharPositionInLine()<=62)
		}?
		 -> type(StringEscapedQuote);

InFactor_StringLiteralEnd: [']
		{(getCharPositionInLine()>=12 && getCharPositionInLine()<=25)
			|| (getCharPositionInLine()>=36 && getCharPositionInLine()<=49)
			|| (getCharPositionInLine()>=50 && getCharPositionInLine()<=63)
		}?
		 -> type(StringLiteralEnd),popMode;

InFactor_EndFactor: {(getCharPositionInLine()==25)
			|| (getCharPositionInLine()==49)
			|| (getCharPositionInLine()==61)
}? -> skip,popMode;

// -----------------  ---------------------
mode FIXED_CommentMode;
BLANK_COMMENTS_TEXT : [ ]+ -> skip;
COMMENTS_TEXT : ~[\r\n]+ {setText(getText().trim());} -> channel(HIDDEN);
COMMENTS_EOL : NEWLINE -> popMode,skip;

mode FIXED_CommentMode_HIDDEN;
COMMENTS_TEXT_SKIP : [ ]+ -> skip;
COMMENTS_TEXT_HIDDEN :  ~[\r\n]* -> channel(HIDDEN);
COMMENTS_EOL_HIDDEN : NEWLINE ->  channel(HIDDEN),popMode;

mode SQL_MODE;
SQL_WS: [ \t\r\n]+ -> skip;
//SINGLE_QTE: ['];
//DOUBLE_QTE: ["];
SEMI_COLON: SEMI -> type(SEMI),popMode, popMode;
WORDS: ~[ ;\r\n] (~[;\r\n]+ ~[ ;\r\n])?;

// ----------------- Everything FIXED_ProcedureSpec of a tag ---------------------
mode FIXED_ProcedureSpec;
PS_NAME :  NAME5 NAME5 NAME5 {getCharPositionInLine()==21}? {setText(getText().trim());};
PS_CONTINUATION_NAME : [ ]* ~[\r\n ]+ PS_CONTINUATION {setText(getText().substring(0,getText().length()-3));} -> pushMode(CONTINUATION_ELIPSIS) ;
PS_CONTINUATION : '...' ;

PS_RESERVED1: '  ' {getCharPositionInLine()==23}? -> skip;
PS_BEGIN: B {getCharPositionInLine()==24}?;
PS_END: E {getCharPositionInLine()==24}?;
PS_RESERVED2: '                   ' {getCharPositionInLine()==43}? -> skip;
PS_KEYWORDS : ~[\r\n] {getCharPositionInLine()==44}? (~[\r\n] {getCharPositionInLine()<=80}?)*;
PS_WS80 : [ ] {getCharPositionInLine()>80}? [ ]* NEWLINE -> skip;
PS_COMMENTS80: FREE_COMMENTS80-> channel(HIDDEN),popMode;
PS_Any: -> popMode,skip;

// ----------------- Everything FIXED_DefSpec of a tag ---------------------
mode FIXED_DefSpec;
BLANK_SPEC :
	'                                                                           '
	{getCharPositionInLine()==81}?;
CONTINUATION_NAME : {getCharPositionInLine()<21}? [ ]* NAMECHAR+ CONTINUATION {setText(getText().substring(0,getText().length()-3).trim());} -> pushMode(CONTINUATION_ELIPSIS) ;
CONTINUATION : '...' ;
NAME : NAME5 NAME5 NAME5 {getCharPositionInLine()==21}? {setText(getText().trim());};
EXTERNAL_DESCRIPTION: [eE ] {getCharPositionInLine()==22}? ;
DATA_STRUCTURE_TYPE: [sSuU ] {getCharPositionInLine()==23}? ;
DEF_TYPE_C: C [ ] {getCharPositionInLine()==25}?;
DEF_TYPE_PI: P I {getCharPositionInLine()==25}?;
DEF_TYPE_PR: P R {getCharPositionInLine()==25}?;
DEF_TYPE_DS: D S {getCharPositionInLine()==25}?;
DEF_TYPE_S: S [ ] {getCharPositionInLine()==25}?;
DEF_TYPE_BLANK: [ ][ ] {getCharPositionInLine()==25}?;
DEF_TYPE: [a-zA-Z0-9 ][a-zA-Z0-9 ] {getCharPositionInLine()==25}?;
FROM_POSITION: WORD5 [a-zA-Z0-9+\- ][a-zA-Z0-9 ]{getCharPositionInLine()==32}?;
TO_POSITION: WORD5[a-zA-Z0-9+\- ][a-zA-Z0-9 ]{getCharPositionInLine()==39}? ;
DATA_TYPE: [a-zA-Z* ]{getCharPositionInLine()==40}? ;
DECIMAL_POSITIONS: [0-9+\- ][0-9 ]{getCharPositionInLine()==42}? ;
RESERVED :  ' ' {getCharPositionInLine()==43}? -> pushMode(FREE);
//KEYWORDS : ~[\r\n] {getCharPositionInLine()==44}? ~[\r\n]* ;
D_WS : [ \t] {getCharPositionInLine()>=81}? [ \t]* -> skip  ; // skip spaces, tabs, newlines
D_COMMENTS80 : ~[\r\n] {getCharPositionInLine()>=81}? ~[\r\n]* -> channel(HIDDEN); // skip comments after 80
EOL : NEWLINE ->  popMode;

mode CONTINUATION_ELIPSIS;
CE_WS: WS ->skip;
CE_COMMENTS80 :  ~[\r\n ] {getCharPositionInLine()>=81}? ~[\r\n]* -> channel(HIDDEN); // skip comments after 80
CE_LEAD_WS5 :  LEAD_WS5 ->skip;
CE_LEAD_WS5_Comments : LEAD_WS5_Comments -> channel(HIDDEN);
CE_D_SPEC_FIXED : D {_modeStack.peek()==FIXED_DefSpec && getCharPositionInLine()==6}? -> skip,popMode ;
CE_P_SPEC_FIXED : P {_modeStack.peek()==FIXED_ProcedureSpec && getCharPositionInLine()==6}? -> skip,popMode ;
CE_NEWLINE: NEWLINE ->skip;

// ----------------- Everything FIXED_FileSpec of a tag ---------------------
mode FIXED_FileSpec;
FS_BLANK_SPEC : BLANK_SPEC -> type(BLANK_SPEC);
FS_RecordName : WORD5 WORD5 {getCharPositionInLine()==16}? ;
FS_Type: [a-zA-Z ] {getCharPositionInLine()==17}?;
FS_Designation: [a-zA-Z ] {getCharPositionInLine()==18}? ;
FS_EndOfFile: [eE ] {getCharPositionInLine()==19}?;
FS_Addution: [aA ] {getCharPositionInLine()==20}?;
FS_Sequence: [aAdD ] {getCharPositionInLine()==21}?;
FS_Format: [eEfF ] {getCharPositionInLine()==22}?;
FS_RecordLength: WORD5 {getCharPositionInLine()==27}?;
FS_Limits: [lL ] {getCharPositionInLine()==28}?;
FS_LengthOfKey: [0-9 ][0-9 ][0-9 ][0-9 ][0-9 ] {getCharPositionInLine()==33}?;
FS_RecordAddressType: [a-zA-Z ] {getCharPositionInLine()==34}?;
FS_Organization: [a-zA-Z ] {getCharPositionInLine()==35}?;
FS_Device: WORD5 [a-zA-Z ][a-zA-Z ] {getCharPositionInLine()==42}?;
FS_Reserved: [ ] {getCharPositionInLine()==43}? -> pushMode(FREE);
FS_WhiteSpace : [ \t] {getCharPositionInLine()>80}? [ \t]* -> skip  ; // skip spaces, tabs, newlines
FS_EOL : NEWLINE -> type(EOL),popMode;

mode FIXED_OutputSpec;
OS_BLANK_SPEC : BLANK_SPEC -> type(BLANK_SPEC);
OS_RecordName : WORD5 WORD5 {getCharPositionInLine()==16}?;
OS_AndOr: '         ' (A N D  | O R  ' ') '  ' ->
	pushMode(OnOffIndicatorMode),pushMode(OnOffIndicatorMode),pushMode(OnOffIndicatorMode);
OS_FieldReserved:  '              ' {getCharPositionInLine()==20}?
    -> pushMode(FIXED_OutputSpec_PGMFIELD),
	pushMode(OnOffIndicatorMode),pushMode(OnOffIndicatorMode),pushMode(OnOffIndicatorMode);
OS_Type: [a-zA-Z ] {getCharPositionInLine()==17}?;
OS_AddDelete: ( A D D  | D E L ) {getCharPositionInLine()==20}? -> pushMode(FIXED_OutputSpec_PGM1),
	pushMode(OnOffIndicatorMode),pushMode(OnOffIndicatorMode),pushMode(OnOffIndicatorMode);
OS_FetchOverflow: (' ' | [fFrR]) '  ' {getCharPositionInLine()==20}? -> pushMode(OnOffIndicatorMode),
	pushMode(OnOffIndicatorMode),pushMode(OnOffIndicatorMode);
OS_ExceptName: WORD5 WORD5 {getCharPositionInLine()==39}?;
OS_Space3: [ 0-9][ 0-9][ 0-9] {getCharPositionInLine()==42 || getCharPositionInLine()==45
	|| getCharPositionInLine()==48 || getCharPositionInLine()==51}? ;
OS_RemainingSpace:  '                             ' {getCharPositionInLine()==80}?;
OS_Comments : CS_Comments -> channel(HIDDEN); // skip comments after 80
OS_WS : [ \t] {getCharPositionInLine()>80}? [ \t]* -> type(WS),skip  ; // skip spaces, tabs, newlines
OS_EOL : NEWLINE -> type(EOL),popMode;//,skip;

mode FIXED_OutputSpec_PGM1;
O1_ExceptName: WORD5 WORD5 {getCharPositionInLine()==39}? -> type(OS_ExceptName);
O1_RemainingSpace: '                                         ' {getCharPositionInLine()==80}?
	-> type(OS_RemainingSpace),popMode;

mode FIXED_OutputSpec_PGMFIELD;
OS_FieldName: WORD5 WORD5 ~[\r\n] ~[\r\n] ~[\r\n] ~[\r\n] {getCharPositionInLine()==43}? ;
OS_EditNames: [ 0-9A-Za-z] {getCharPositionInLine()==44}?;
OS_BlankAfter: [ bB] {getCharPositionInLine()==45}?;
OS_Reserved1: [ ] {getCharPositionInLine()==46}?-> skip;
OS_EndPosition: WORD5 {getCharPositionInLine()==51}?;
OS_DataFormat: [ 0-9A-Za-z] {getCharPositionInLine()==52}? -> pushMode(FREE);
OS_Any: -> popMode;

mode FIXED_CalcSpec;
// Symbolic Constants
CS_Factor1_SPLAT_ALL : SPLAT_ALL {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_ALL);
CS_Factor1_SPLAT_NONE : SPLAT_NONE {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_NONE);
CS_Factor1_SPLAT_ILERPG : SPLAT_ILERPG {11+7<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_ILERPG);
CS_Factor1_SPLAT_CRTBNDRPG : SPLAT_CRTBNDRPG {11+10<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_CRTBNDRPG);
CS_Factor1_SPLAT_CRTRPGMOD : SPLAT_CRTRPGMOD {11+10<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_CRTRPGMOD);
CS_Factor1_SPLAT_VRM :  SPLAT_VRM{11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_VRM);
CS_Factor1_SPLAT_ALLG : SPLAT_ALLG {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_ALLG);
CS_Factor1_SPLAT_ALLU : SPLAT_ALLU {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_ALLU);
CS_Factor1_SPLAT_ALLX : SPLAT_ALLX {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_ALLX);
CS_Factor1_SPLAT_BLANKS : SPLAT_BLANKS {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_BLANKS);
CS_Factor1_SPLAT_CANCL : SPLAT_CANCL {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_CANCL);
CS_Factor1_SPLAT_CYMD : SPLAT_CYMD {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_CYMD);
CS_Factor1_SPLAT_CMDY : SPLAT_CMDY {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_CMDY);
CS_Factor1_SPLAT_CDMY : SPLAT_CDMY {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_CDMY);
CS_Factor1_SPLAT_MDY : SPLAT_MDY {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_MDY);
CS_Factor1_SPLAT_DMY : SPLAT_DMY {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_DMY);
CS_Factor1_SPLAT_YMD : SPLAT_YMD {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_YMD);
CS_Factor1_SPLAT_JUL : SPLAT_JUL {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_JUL);
CS_Factor1_SPLAT_ISO : SPLAT_ISO {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_ISO);
CS_Factor1_SPLAT_USA : SPLAT_USA {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_USA);
CS_Factor1_SPLAT_EUR : SPLAT_EUR {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_EUR);
CS_Factor1_SPLAT_JIS : SPLAT_JIS {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_JIS);
CS_Factor1_SPLAT_DATE : SPLAT_DATE {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_DATE);
CS_Factor1_SPLAT_DAY : SPLAT_DAY {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_DAY);
CS_Factor1_SPLAT_DETC : SPlAT_DETC {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPlAT_DETC);
CS_Factor1_SPLAT_DETL : SPLAT_DETL {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_DETL);
CS_Factor1_SPLAT_DTAARA : SPLAT_DTAARA {11+7<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_DTAARA);
CS_Factor1_SPLAT_END : SPLAT_END {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_END);
CS_Factor1_SPLAT_ENTRY : SPLAT_ENTRY {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_ENTRY);
CS_Factor1_SPLAT_EQUATE : SPLAT_EQUATE {11+7<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_EQUATE);
CS_Factor1_SPLAT_EXTDFT : SPLAT_EXTDFT {11+7<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_EXTDFT);
CS_Factor1_SPLAT_EXT : SPLAT_EXT {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_EXT);
CS_Factor1_SPLAT_FILE : SPLAT_FILE {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_FILE);
CS_Factor1_SPLAT_GETIN : SPLAT_GETIN {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_GETIN);
CS_Factor1_SPLAT_HIVAL : SPLAT_HIVAL {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_HIVAL);
CS_Factor1_SPLAT_INIT : SPLAT_INIT {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_INIT);
CS_Factor1_SPLAT_INDICATOR : SPLAT_INDICATOR {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_INDICATOR);
CS_Factor1_SPLAT_INZSR : SPLAT_INZSR {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_INZSR);
CS_Factor1_SPLAT_IN : SPLAT_IN {11+3<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_IN);
CS_Factor1_SPLAT_JOBRUN : SPLAT_JOBRUN {11+7<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_JOBRUN);
CS_Factor1_SPLAT_JOB : SPLAT_JOB {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_JOB);
CS_Factor1_SPLAT_LDA : SPLAT_LDA {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_LDA);
CS_Factor1_SPLAT_LIKE : SPLAT_LIKE {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_LIKE);
CS_Factor1_SPLAT_LONGJUL : SPLAT_LONGJUL {11+8<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_LONGJUL);
CS_Factor1_SPLAT_LOVAL : SPLAT_LOVAL {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_LOVAL);
CS_Factor1_SPLAT_MONTH : SPLAT_MONTH {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_MONTH);
CS_Factor1_SPLAT_NOIND : SPLAT_NOIND {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_NOIND);
CS_Factor1_SPLAT_NOKEY : SPLAT_NOKEY {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_NOKEY);
CS_Factor1_SPLAT_NULL : SPLAT_NULL {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_NULL);
CS_Factor1_SPLAT_OFL : SPLAT_OFL {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_OFL);
CS_Factor1_SPLAT_ON : SPLAT_ON {11+3<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_ON);
CS_Factor1_SPLAT_OFF : SPLAT_OFF {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_OFF);
CS_Factor1_SPLAT_PDA : SPLAT_PDA {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_PDA);
CS_Factor1_SPLAT_PLACE : SPLAT_PLACE {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_PLACE);
CS_Factor1_SPLAT_PSSR : SPLAT_PSSR {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_PSSR);
CS_Factor1_SPLAT_ROUTINE : SPLAT_ROUTINE {11+8<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_ROUTINE);
CS_Factor1_SPLAT_START : SPLAT_START {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_START);
CS_Factor1_SPLAT_SYS : SPLAT_SYS {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_SYS);
CS_Factor1_SPLAT_TERM : SPLAT_TERM {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_TERM);
CS_Factor1_SPLAT_TOTC : SPLAT_TOTC {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_TOTC);
CS_Factor1_SPLAT_TOTL : SPLAT_TOTL {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_TOTL);
CS_Factor1_SPLAT_USER : SPLAT_USER {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_USER);
CS_Factor1_SPLAT_VAR : SPLAT_VAR {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_VAR);
CS_Factor1_SPLAT_YEAR : SPLAT_YEAR {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_YEAR);
CS_Factor1_SPLAT_ZEROS : SPLAT_ZEROS {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_ZEROS);
CS_Factor1_SPLAT_HMS : SPLAT_HMS {11+4<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_HMS);
CS_Factor1_SPLAT_INLR : SPLAT_INLR {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_INLR);
CS_Factor1_SPLAT_INOF : SPLAT_INOF {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_INOF);
//DurationCodes
CS_Factor1_SPLAT_D : SPLAT_D {11+2<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_D);
CS_Factor1_SPLAT_DAYS : SPLAT_DAYS {11+5<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_DAYS);
CS_Factor1_SPLAT_H : SPLAT_H {11+2<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_H);
CS_Factor1_SPLAT_HOURS : SPLAT_HOURS {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_HOURS);
CS_Factor1_SPLAT_MINUTES : SPLAT_MINUTES {11+8<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_MINUTES);
CS_Factor1_SPLAT_MONTHS : SPLAT_MONTHS {11+7<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_MONTHS);
CS_Factor1_SPLAT_M : SPLAT_M {11+2<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_M);
CS_Factor1_SPLAT_MN : SPLAT_MN {11+3<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_MN);
CS_Factor1_SPLAT_MS : SPLAT_MS {11+3<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_MS);
CS_Factor1_SPLAT_MSECONDS : SPLAT_MSECONDS {11+9<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_MSECONDS);
CS_Factor1_SPLAT_SECONDS : SPLAT_SECONDS {11+8<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_SECONDS);
CS_Factor1_SPLAT_YEARS : SPLAT_YEARS {11+6<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_YEARS);
CS_Factor1_SPLAT_Y : SPLAT_Y {11+2<= getCharPositionInLine() && getCharPositionInLine()<=24}? -> type(SPLAT_Y);

//Factor 2
CS_Factor2_SPLAT_ALL : SPLAT_ALL {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_ALL);
CS_Factor2_SPLAT_NONE : SPLAT_NONE {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_NONE);
CS_Factor2_SPLAT_ILERPG : SPLAT_ILERPG {35+7<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_ILERPG);
CS_Factor2_SPLAT_CRTBNDRPG : SPLAT_CRTBNDRPG {35+10<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_CRTBNDRPG);
CS_Factor2_SPLAT_CRTRPGMOD : SPLAT_CRTRPGMOD {35+10<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_CRTRPGMOD);
CS_Factor2_SPLAT_VRM : SPLAT_VRM {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_VRM);
CS_Factor2_SPLAT_ALLG : SPLAT_ALLG {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_ALLG);
CS_Factor2_SPLAT_ALLU : SPLAT_ALLU {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_ALLU);
CS_Factor2_SPLAT_ALLX : SPLAT_ALLX {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_ALLX);
CS_Factor2_SPLAT_BLANKS : SPLAT_BLANKS {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_BLANKS);
CS_Factor2_SPLAT_CANCL : SPLAT_CANCL {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_CANCL);
CS_Factor2_SPLAT_CYMD : SPLAT_CYMD {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_CYMD);
CS_Factor2_SPLAT_CMDY : SPLAT_CMDY {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_CMDY);
CS_Factor2_SPLAT_CDMY : SPLAT_CDMY {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_CDMY);
CS_Factor2_SPLAT_MDY : SPLAT_MDY {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_MDY);
CS_Factor2_SPLAT_DMY : SPLAT_DMY {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_DMY);
CS_Factor2_SPLAT_YMD : SPLAT_YMD {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_YMD);
CS_Factor2_SPLAT_JUL : SPLAT_JUL {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_JUL);
CS_Factor2_SPLAT_ISO : SPLAT_ISO {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_ISO);
CS_Factor2_SPLAT_USA : SPLAT_USA {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_USA);
CS_Factor2_SPLAT_EUR : SPLAT_EUR {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_EUR);
CS_Factor2_SPLAT_JIS : SPLAT_JIS {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_JIS);
CS_Factor2_SPLAT_DATE : SPLAT_DATE {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_DATE);
CS_Factor2_SPLAT_DAY : SPLAT_DAY {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_DAY);
CS_Factor2_SPLAT_DETC : SPlAT_DETC {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPlAT_DETC);
CS_Factor2_SPLAT_DETL : SPLAT_DETL {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_DETL);
CS_Factor2_SPLAT_DTAARA : SPLAT_DTAARA {35+7<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_DTAARA);
CS_Factor2_SPLAT_END : SPLAT_END {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_END);
CS_Factor2_SPLAT_ENTRY : SPLAT_ENTRY {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_ENTRY);
CS_Factor2_SPLAT_EQUATE : SPLAT_EQUATE {35+7<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_EQUATE);
CS_Factor2_SPLAT_EXTDFT : SPLAT_EXTDFT {35+7<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_EXTDFT);
CS_Factor2_SPLAT_EXT : SPLAT_EXT {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_EXT);
CS_Factor2_SPLAT_FILE : SPLAT_FILE {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_FILE);
CS_Factor2_SPLAT_GETIN : SPLAT_GETIN {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_GETIN);
CS_Factor2_SPLAT_HIVAL : SPLAT_HIVAL {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_HIVAL);
CS_Factor2_SPLAT_INIT : SPLAT_INIT {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_INIT);
CS_Factor2_SPLAT_INDICATOR : SPLAT_INDICATOR {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_INDICATOR);
CS_Factor2_SPLAT_INZSR : SPLAT_INZSR {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_INZSR);
CS_Factor2_SPLAT_IN : SPLAT_IN {35+3<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_IN);
CS_Factor2_SPLAT_JOBRUN : SPLAT_JOBRUN {35+7<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_JOBRUN);
CS_Factor2_SPLAT_JOB : SPLAT_JOB {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_JOB);
CS_Factor2_SPLAT_LDA : SPLAT_LDA {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_LDA);
CS_Factor2_SPLAT_LIKE : SPLAT_LIKE {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_LIKE);
CS_Factor2_SPLAT_LONGJUL : SPLAT_LONGJUL {35+8<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_LONGJUL);
CS_Factor2_SPLAT_LOVAL : SPLAT_LOVAL {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_LOVAL);
CS_Factor2_SPLAT_MONTH : SPLAT_MONTH {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_MONTH);
CS_Factor2_SPLAT_NOIND : SPLAT_NOIND {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_NOIND);
CS_Factor2_SPLAT_NOKEY : SPLAT_NOKEY {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_NOKEY);
CS_Factor2_SPLAT_NULL : SPLAT_NULL {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_NULL);
CS_Factor2_SPLAT_OFL : SPLAT_OFL {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_OFL);
CS_Factor2_SPLAT_ON : SPLAT_ON {35+3<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_ON);
CS_Factor2_SPLAT_OFF : SPLAT_OFF {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_OFF);
CS_Factor2_SPLAT_PDA : SPLAT_PDA {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_PDA);
CS_Factor2_SPLAT_PLACE : SPLAT_PLACE {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_PLACE);
CS_Factor2_SPLAT_PSSR : SPLAT_PSSR {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_PSSR);
CS_Factor2_SPLAT_ROUTINE : SPLAT_ROUTINE {35+8<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_ROUTINE);
CS_Factor2_SPLAT_START : SPLAT_START {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_START);
CS_Factor2_SPLAT_SYS : SPLAT_SYS {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_SYS);
CS_Factor2_SPLAT_TERM : SPLAT_TERM {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_TERM);
CS_Factor2_SPLAT_TOTC : SPLAT_TOTC {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_TOTC);
CS_Factor2_SPLAT_TOTL : SPLAT_TOTL {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_TOTL);
CS_Factor2_SPLAT_USER : SPLAT_USER {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_USER);
CS_Factor2_SPLAT_VAR : SPLAT_VAR {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_VAR);
CS_Factor2_SPLAT_YEAR : SPLAT_YEAR {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_YEAR);
CS_Factor2_SPLAT_ZEROS : SPLAT_ZEROS {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_ZEROS);
CS_Factor2_SPLAT_HMS : SPLAT_HMS {35+4<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_HMS);
CS_Factor2_SPLAT_INLR : SPLAT_INLR {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_INLR);
CS_Factor2_SPLAT_INOF : SPLAT_INOF {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_INOF);
//Duration
CS_Factor2_SPLAT_D : SPLAT_D {35+2<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_D);
CS_Factor2_SPLAT_DAYS : SPLAT_DAYS {35+5<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_DAYS);
CS_Factor2_SPLAT_H : SPLAT_H {35+2<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_H);
CS_Factor2_SPLAT_HOURS : SPLAT_HOURS {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_HOURS);
CS_Factor2_SPLAT_MINUTES : SPLAT_MINUTES {35+8<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_MINUTES);
CS_Factor2_SPLAT_MONTHS : SPLAT_MONTHS {35+7<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_MONTHS);
CS_Factor2_SPLAT_M : SPLAT_M {35+2<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_M);
CS_Factor2_SPLAT_MN : SPLAT_MN {35+3<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_MN);
CS_Factor2_SPLAT_MS : SPLAT_MS {35+3<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_MS);
CS_Factor2_SPLAT_MSECONDS : SPLAT_MSECONDS {35+9<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_MSECONDS);
CS_Factor2_SPLAT_SECONDS : SPLAT_SECONDS {35+8<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_SECONDS);
CS_Factor2_SPLAT_YEARS : SPLAT_YEARS {35+6<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_YEARS);
CS_Factor2_SPLAT_Y : SPLAT_Y {35+2<= getCharPositionInLine() && getCharPositionInLine()<=48}? -> type(SPLAT_Y);

//Result

//Duration
CS_Result_SPLAT_D : SPLAT_D {49+2<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_D);
CS_Result_SPLAT_DAYS : SPLAT_DAYS {49+5<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_DAYS);
CS_Result_SPLAT_H : SPLAT_H {49+2<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_H);
CS_Result_SPLAT_HOURS : SPLAT_HOURS {49+6<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_HOURS);
CS_Result_SPLAT_MINUTES : SPLAT_MINUTES {49+8<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_MINUTES);
CS_Result_SPLAT_MONTHS : SPLAT_MONTHS {49+7<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_MONTHS);
CS_Result_SPLAT_M : SPLAT_M {49+2<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_M);
CS_Result_SPLAT_MN : SPLAT_MN {49+3<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_MN);
CS_Result_SPLAT_MS : SPLAT_MS {49+3<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_MS);
CS_Result_SPLAT_MSECONDS : SPLAT_MSECONDS {49+9<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_MSECONDS);
CS_Result_SPLAT_SECONDS : SPLAT_SECONDS {49+8<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_SECONDS);
CS_Result_SPLAT_YEARS : SPLAT_YEARS {49+6<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_YEARS);
CS_Result_SPLAT_Y : SPLAT_Y {49+2<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_Y);
CS_Result_SPLAT_S : SPLAT_S {49+2<= getCharPositionInLine() && getCharPositionInLine()<=62}? -> type(SPLAT_S);

CS_BlankFactor: '              '
		{(getCharPositionInLine()==25)
			|| (getCharPositionInLine()==49)
			|| (getCharPositionInLine()==63)}?
;
//Factor to end of line is blank
CS_BlankFactor_EOL: '              ' {getCharPositionInLine()==25}? [ ]* NEWLINE -> type(EOL),popMode;
CS_FactorWs: (' '
	{(getCharPositionInLine()>=12 && getCharPositionInLine()<=25)
			|| (getCharPositionInLine()>=36 && getCharPositionInLine()<=49)
	}?
		)+ -> skip;
CS_FactorWs2: (' '
	{(getCharPositionInLine()>=50 && getCharPositionInLine()<=63)
	}?
		)+ -> skip;

/*
 * This rather awkward token matches a literal. including whitespace literals
 */
CS_FactorContentHexLiteral: X [']
	{(getCharPositionInLine()>=13 && getCharPositionInLine()<=25)
			|| (getCharPositionInLine()>=37 && getCharPositionInLine()<=49)
			|| (getCharPositionInLine()>=51 && getCharPositionInLine()<=63)
	}?
		 -> type(HexLiteralStart),pushMode(InFactorStringMode);

CS_FactorContentDateLiteral: D [']
	{(getCharPositionInLine()>=13 && getCharPositionInLine()<=25)
			|| (getCharPositionInLine()>=37 && getCharPositionInLine()<=49)
			|| (getCharPositionInLine()>=51 && getCharPositionInLine()<=63)
	}?
		 -> type(DateLiteralStart),pushMode(InFactorStringMode);

CS_FactorContentTimeLiteral: T [']
	{(getCharPositionInLine()>=13 && getCharPositionInLine()<=25)
			|| (getCharPositionInLine()>=37 && getCharPositionInLine()<=49)
			|| (getCharPositionInLine()>=51 && getCharPositionInLine()<=63)
	}?
		-> type(TimeLiteralStart),pushMode(InFactorStringMode);

CS_FactorContentGraphicLiteral: G [']
	{(getCharPositionInLine()>=13 && getCharPositionInLine()<=25)
			|| (getCharPositionInLine()>=37 && getCharPositionInLine()<=49)
			|| (getCharPositionInLine()>=51 && getCharPositionInLine()<=63)
	}?
		-> type(GraphicLiteralStart),pushMode(InFactorStringMode);

CS_FactorContentUCS2Literal: U [']
	{(getCharPositionInLine()>=13 && getCharPositionInLine()<=25)
			|| (getCharPositionInLine()>=37 && getCharPositionInLine()<=49)
			|| (getCharPositionInLine()>=51 && getCharPositionInLine()<=63)
	}?
		-> type(UCS2LiteralStart),pushMode(InFactorStringMode);

CS_FactorContentStringLiteral: [']
 	{(getCharPositionInLine()>=12 && getCharPositionInLine()<=25)
			|| (getCharPositionInLine()>=36 && getCharPositionInLine()<=49)
			|| (getCharPositionInLine()>=50 && getCharPositionInLine()<=63)
	}?
		-> type(StringLiteralStart),pushMode(InFactorStringMode);

CS_FactorContent: (~[\r\n' :]
	{(getCharPositionInLine()>=12 && getCharPositionInLine()<=25)
			|| (getCharPositionInLine()>=36 && getCharPositionInLine()<=49)
	}?
		)+;
CS_ResultContent: (~[\r\n' :]
	{(getCharPositionInLine()>=50 && getCharPositionInLine()<=63)}?
		)+ -> type(CS_FactorContent);
CS_FactorColon: ([:]
	{(getCharPositionInLine()>12 && getCharPositionInLine()<25)
			|| (getCharPositionInLine()>36 && getCharPositionInLine()<49)
			|| (getCharPositionInLine()>50 && getCharPositionInLine()<63)
	}?
		) -> type(COLON);//pushMode(FIXED_CalcSpec_2PartFactor),
CS_OperationAndExtender_Blank:
   '          '{getCharPositionInLine()==35}?;
CS_OperationAndExtender_WS:
	([ ]{getCharPositionInLine()>=26 && getCharPositionInLine()<36}?)+ -> skip;
CS_Operation_ACQ: OP_ACQ {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_ACQ);
CS_Operation_ADD: OP_ADD {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_ADD);
CS_Operation_ADDDUR: OP_ADDDUR {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_ADDDUR);
CS_Operation_ALLOC: OP_ALLOC {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ALLOC);
CS_Operation_ANDEQ: OP_ANDEQ {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ANDEQ);
CS_Operation_ANDNE: OP_ANDNE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ANDNE);
CS_Operation_ANDLE: OP_ANDLE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ANDLE);
CS_Operation_ANDLT: OP_ANDLT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ANDLT);
CS_Operation_ANDGE: OP_ANDGE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ANDGE);
CS_Operation_ANDGT: OP_ANDGT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ANDGT);
CS_Operation_ANDxx: OP_ANDxx {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ANDxx);
CS_Operation_BEGSR: OP_BEGSR {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_BEGSR);
CS_Operation_BITOFF: OP_BITOFF {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_BITOFF);
CS_Operation_BITON: OP_BITON {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_BITON);
CS_Operation_CABxx: OP_CABxx {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CABxx);
CS_Operation_CABEQ: OP_CABEQ {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CABEQ);
CS_Operation_CABNE: OP_CABNE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CABNE);
CS_Operation_CABLE: OP_CABLE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CABLE);
CS_Operation_CABLT: OP_CABLT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CABLT);
CS_Operation_CABGE: OP_CABGE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CABGE);
CS_Operation_CABGT: OP_CABGT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CABGT);
CS_Operation_CALL: OP_CALL {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_CALL);
CS_Operation_CALLB: OP_CALLB {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CALLB);
CS_Operation_CALLP: OP_CALLP {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CALLP),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_CASEQ: OP_CASEQ {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CASEQ);
CS_Operation_CASNE: OP_CASNE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CASNE);
CS_Operation_CASLE: OP_CASLE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CASLE);
CS_Operation_CASLT: OP_CASLT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CASLT);
CS_Operation_CASGE: OP_CASGE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CASGE);
CS_Operation_CASGT: OP_CASGT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CASGT);
CS_Operation_CAS: OP_CAS {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_CAS);
CS_Operation_CAT: OP_CAT {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_CAT);
CS_Operation_CHAIN: OP_CHAIN {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CHAIN);
CS_Operation_CHECK: OP_CHECK {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CHECK);
CS_Operation_CHECKR: OP_CHECKR {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_CHECKR);
CS_Operation_CLEAR: OP_CLEAR {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CLEAR);
CS_Operation_CLOSE: OP_CLOSE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_CLOSE);
CS_Operation_COMMIT: OP_COMMIT {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_COMMIT);
CS_Operation_COMP: OP_COMP {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_COMP);
CS_Operation_DEALLOC: OP_DEALLOC {getCharPositionInLine()>=32 && getCharPositionInLine()<36}? -> type(OP_DEALLOC);
CS_Operation_DEFINE: OP_DEFINE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DEFINE);
CS_Operation_DELETE: OP_DELETE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DELETE);
CS_Operation_DIV: OP_DIV {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_DIV);
CS_Operation_DO: OP_DO {getCharPositionInLine()>=27 && getCharPositionInLine()<36}? -> type(OP_DO);
CS_Operation_DOU: OP_DOU {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_DOU),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_DOUEQ: OP_DOUEQ {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOUEQ);
CS_Operation_DOUNE: OP_DOUNE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOUNE);
CS_Operation_DOULE: OP_DOULE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOULE);
CS_Operation_DOULT: OP_DOULT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOULT);
CS_Operation_DOUGE: OP_DOUGE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOUGE);
CS_Operation_DOUGT: OP_DOUGT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOUGT);
CS_Operation_DOW: OP_DOW {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_DOW),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_DOWEQ: OP_DOWEQ {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOWEQ);
CS_Operation_DOWNE: OP_DOWNE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOWNE);
CS_Operation_DOWLE: OP_DOWLE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOWLE);
CS_Operation_DOWLT: OP_DOWLT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOWLT);
CS_Operation_DOWGE: OP_DOWGE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOWGE);
CS_Operation_DOWGT: OP_DOWGT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DOWGT);
CS_Operation_DSPLY: OP_DSPLY {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_DSPLY);
CS_Operation_DUMP: OP_DUMP {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_DUMP);
CS_Operation_ELSE: OP_ELSE {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_ELSE);
CS_Operation_ELSEIF: OP_ELSEIF {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_ELSEIF),pushMode(FREE);
CS_Operation_END: OP_END {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_END);
CS_Operation_ENDCS: OP_ENDCS {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ENDCS);
CS_Operation_ENDDO: OP_ENDDO {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ENDDO);
CS_Operation_ENDFOR: OP_ENDFOR {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_ENDFOR);
CS_Operation_ENDIF: OP_ENDIF {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ENDIF);
CS_Operation_ENDMON: OP_ENDMON {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_ENDMON);
CS_Operation_ENDSL: OP_ENDSL {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ENDSL);
CS_Operation_ENDSR: OP_ENDSR {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ENDSR);
CS_Operation_EVAL: OP_EVAL {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_EVAL),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_EVALR: OP_EVALR {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_EVALR),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_EVAL_CORR: OP_EVAL_CORR {getCharPositionInLine()>=34 && getCharPositionInLine()<36}? -> type(OP_EVAL_CORR),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_EXCEPT: OP_EXCEPT {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_EXCEPT);
CS_Operation_EXFMT: OP_EXFMT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_EXFMT);
CS_Operation_EXSR: OP_EXSR {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_EXSR);
CS_Operation_EXTRCT: OP_EXTRCT {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_EXTRCT);
CS_Operation_FEOD: OP_FEOD {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_FEOD);
CS_Operation_FOR: OP_FOR {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_FOR),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_FORCE: OP_FORCE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_FORCE);
CS_Operation_GOTO: OP_GOTO {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_GOTO);
CS_Operation_IF: OP_IF {getCharPositionInLine()>=27 && getCharPositionInLine()<36}? -> type(OP_IF),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_IFEQ: OP_IFEQ {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_IFEQ);
CS_Operation_IFNE: OP_IFNE {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_IFNE);
CS_Operation_IFLE: OP_IFLE {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_IFLE);
CS_Operation_IFLT: OP_IFLT {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_IFLT);
CS_Operation_IFGE: OP_IFGE {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_IFGE);
CS_Operation_IFGT: OP_IFGT {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_IFGT);
CS_Operation_IN: OP_IN {getCharPositionInLine()>=27 && getCharPositionInLine()<36}? -> type(OP_IN);
CS_Operation_ITER: OP_ITER {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_ITER);
CS_Operation_KFLD: OP_KFLD {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_KFLD);
CS_Operation_KLIST: OP_KLIST {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_KLIST);
CS_Operation_LEAVE: OP_LEAVE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_LEAVE);
CS_Operation_LEAVESR: OP_LEAVESR {getCharPositionInLine()>=32 && getCharPositionInLine()<36}? -> type(OP_LEAVESR);
CS_Operation_LOOKUP: OP_LOOKUP {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_LOOKUP);
CS_Operation_MHHZO: OP_MHHZO {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_MHHZO);
CS_Operation_MHLZO: OP_MHLZO {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_MHLZO);
CS_Operation_MLHZO: OP_MLHZO {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_MLHZO);
CS_Operation_MLLZO: OP_MLLZO {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_MLLZO);
CS_Operation_MONITOR: OP_MONITOR {getCharPositionInLine()>=32 && getCharPositionInLine()<36}? -> type(OP_MONITOR);
CS_Operation_MOVE: OP_MOVE {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_MOVE);
CS_Operation_MOVEA: OP_MOVEA {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_MOVEA);
CS_Operation_MOVEL: OP_MOVEL {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_MOVEL);
CS_Operation_MULT: OP_MULT {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_MULT);
CS_Operation_MVR: OP_MVR {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_MVR);
CS_Operation_NEXT: OP_NEXT {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_NEXT);
CS_Operation_OCCUR: OP_OCCUR {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_OCCUR);
CS_Operation_ON_ERROR: OP_ON_ERROR {getCharPositionInLine()>=33 && getCharPositionInLine()<36}? -> type(OP_ON_ERROR),pushMode(FREE);
CS_Operation_OPEN: OP_OPEN {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_OPEN);
CS_Operation_OREQ: OP_OREQ {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_OREQ);
CS_Operation_ORNE: OP_ORNE {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_ORNE);
CS_Operation_ORLE: OP_ORLE {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_ORLE);
CS_Operation_ORLT: OP_ORLT {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_ORLT);
CS_Operation_ORGE: OP_ORGE {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_ORGE);
CS_Operation_ORGT: OP_ORGT {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_ORGT);
CS_Operation_OTHER: OP_OTHER {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_OTHER);
CS_Operation_OUT: OP_OUT {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_OUT);
CS_Operation_PARM: OP_PARM {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_PARM);
CS_Operation_PLIST: OP_PLIST {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_PLIST);
CS_Operation_POST: OP_POST {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_POST);
CS_Operation_READ: OP_READ {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_READ);
CS_Operation_READC: OP_READC {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_READC);
CS_Operation_READE: OP_READE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_READE);
CS_Operation_READP: OP_READP {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_READP);
CS_Operation_READPE: OP_READPE {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_READPE);
CS_Operation_REALLOC: OP_REALLOC {getCharPositionInLine()>=32 && getCharPositionInLine()<36}? -> type(OP_REALLOC);
CS_Operation_REL: OP_REL {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_REL);
CS_Operation_RESET: OP_RESET {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_RESET);
CS_Operation_RETURN: OP_RETURN {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_RETURN),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_ROLBK: OP_ROLBK {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_ROLBK);
CS_Operation_SCAN: OP_SCAN {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_SCAN);
CS_Operation_SELECT: OP_SELECT {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_SELECT);
CS_Operation_SETGT: OP_SETGT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_SETGT);
CS_Operation_SETLL: OP_SETLL {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_SETLL);
CS_Operation_SETOFF: OP_SETOFF {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_SETOFF);
CS_Operation_SETON: OP_SETON {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_SETON);
CS_Operation_SORTA: OP_SORTA {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_SORTA),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_SHTDN: OP_SHTDN {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_SHTDN);
CS_Operation_SQRT: OP_SQRT {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_SQRT);
CS_Operation_SUB: OP_SUB {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_SUB);
CS_Operation_SUBDUR: OP_SUBDUR {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_SUBDUR);
CS_Operation_SUBST: OP_SUBST {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_SUBST);
CS_Operation_TAG: OP_TAG {getCharPositionInLine()>=28 && getCharPositionInLine()<36}? -> type(OP_TAG);
CS_Operation_TEST: OP_TEST {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_TEST);
CS_Operation_TESTB: OP_TESTB {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_TESTB);
CS_Operation_TESTN: OP_TESTN {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_TESTN);
CS_Operation_TESTZ: OP_TESTZ {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_TESTZ);
CS_Operation_TIME: OP_TIME {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_TIME);
CS_Operation_UNLOCK: OP_UNLOCK {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_UNLOCK);
CS_Operation_UPDATE: OP_UPDATE {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_UPDATE);
CS_Operation_WHEN: OP_WHEN {getCharPositionInLine()>=29 && getCharPositionInLine()<36}? -> type(OP_WHEN),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_WHENEQ: OP_WHENEQ {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_WHENEQ);
CS_Operation_WHENNE: OP_WHENNE {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_WHENNE);
CS_Operation_WHENLE: OP_WHENLE {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_WHENLE);
CS_Operation_WHENLT: OP_WHENLT {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_WHENLT);
CS_Operation_WHENGE: OP_WHENGE {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_WHENGE);
CS_Operation_WHENGT: OP_WHENGT {getCharPositionInLine()>=31 && getCharPositionInLine()<36}? -> type(OP_WHENGT);
CS_Operation_WRITE: OP_WRITE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_WRITE);
CS_Operation_XFOOT: OP_XFOOT {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_XFOOT);
CS_Operation_XLATE: OP_XLATE {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_XLATE);
CS_Operation_XML_INTO: OP_XML_INTO {getCharPositionInLine()>=33 && getCharPositionInLine()<36}? -> type(OP_XML_INTO),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_XML_SAX: OP_XML_SAX {getCharPositionInLine()>=32 && getCharPositionInLine()<36}? -> type(OP_XML_SAX),pushMode(FREE),pushMode(FixedOpExtender);
CS_Operation_Z_ADD: OP_Z_ADD {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_Z_ADD);
CS_Operation_Z_SUB: OP_Z_SUB {getCharPositionInLine()>=30 && getCharPositionInLine()<36}? -> type(OP_Z_SUB);


CS_OperationAndExtender:
   ([a-zA-Z0-9\\-]
    {getCharPositionInLine()>=26 && getCharPositionInLine()<36}?)+;
CS_OperationExtenderOpen: OPEN_PAREN{getCharPositionInLine()>=26 && getCharPositionInLine()<36}? -> type(OPEN_PAREN);
CS_OperationExtenderClose: CLOSE_PAREN{getCharPositionInLine()>=26 && getCharPositionInLine()<36}?
  ( ' '{getCharPositionInLine()>=26 && getCharPositionInLine()<36}?)*
  {setText(getText().trim());}
  -> type(CLOSE_PAREN);

CS_FieldLength: [+\- 0-9][+\- 0-9][+\- 0-9][+\- 0-9][+\- 0-9] {getCharPositionInLine()==68}?;
CS_DecimalPositions: [ 0-9][ 0-9] {getCharPositionInLine()==70}?
	-> pushMode(IndicatorMode),pushMode(IndicatorMode),pushMode(IndicatorMode); // 3 Indicators in a row
CS_WhiteSpace : [ \t] {getCharPositionInLine()>=77}? [ \t]* -> skip  ; // skip spaces, tabs, newlines
CS_Comments : ~[\r\n] {getCharPositionInLine()>80}? ~[\r\n]*  ;
CS_FixedComments : ~[\r\n] {getCharPositionInLine()>=77}? ~[\r\n]*  ;
CS_EOL : NEWLINE -> type(EOL),popMode;

mode FixedOpExtender;
CS_FixedOperationAndExtender_WS:
	([ ]
	  {getCharPositionInLine()>=26 && getCharPositionInLine()<36}?
	)+ -> skip;
CS_FixedOperationExtenderOpen: OPEN_PAREN {getCharPositionInLine()>=26 && getCharPositionInLine()<36}?
		-> type(OPEN_PAREN),popMode,pushMode(FixedOpExtender2);
CS_FixedOperationExtenderReturn: {getCharPositionInLine()>=25 && getCharPositionInLine()<=35}? ->skip,popMode;

mode FixedOpExtender2;
CS_FixedOperationAndExtender2_WS:
	([ ]
		{getCharPositionInLine()>=26 && getCharPositionInLine()<36}?)+ -> skip;
CS_FixedOperationAndExtender2:
   ([a-zA-Z0-9\\-]
   	{getCharPositionInLine()>=26 && getCharPositionInLine()<36}?)+ -> type(CS_OperationAndExtender);
CS_FixedOperationExtender2Close: CLOSE_PAREN {getCharPositionInLine()>=26 && getCharPositionInLine()<36}?
  (' '
  	{getCharPositionInLine()>=26 && getCharPositionInLine()<36}?
  )*
  {setText(getText().trim());}
  -> type(CLOSE_PAREN);
CS_FixedOperationExtender2Return: {getCharPositionInLine()==35}? ->skip,popMode;


mode FreeOpExtender;
FreeOpExtender_OPEN_PAREN: OPEN_PAREN -> popMode,type(OPEN_PAREN),pushMode(FreeOpExtender2);
//Deliberate match no char, pop out again
FreeOpExtender_Any: -> popMode,skip;

mode FreeOpExtender2;
FreeOpExtender2_CLOSE_PAREN: CLOSE_PAREN -> popMode,type(CLOSE_PAREN);
FreeOpExtender2_WS: WS -> skip;
FreeOpExtender_Extender: [a-zA-Z0-9\\-] -> type(CS_OperationAndExtender);

mode OnOffIndicatorMode;
BlankFlag: [ ] ->popMode,pushMode(IndicatorMode);
NoFlag: N  ->popMode,pushMode(IndicatorMode);

mode IndicatorMode;
BlankIndicator: [ ][ ] ->popMode;
GeneralIndicator: ([0][1-9] | [1-9][0-9]) ->popMode;
FunctionKeyIndicator: K [A-NP-Ya-np-y] ->popMode;
ControlLevelIndicator: L [1-9] ->popMode;
ControlLevel0Indicator: L [0] ->popMode;
LastRecordIndicator: L R  ->popMode;
MatchingRecordIndicator: M R  ->popMode;
HaltIndicator: H [1-9] ->popMode;
ReturnIndicator: R T  ->popMode;
ExternalIndicator: U [1-8] ->popMode;
OverflowIndicator: O [A-GVa-gv] ->popMode;
SubroutineIndicator: S R  ->popMode;
AndIndicator: A N  ->popMode;
OrIndicator: O R  ->popMode;
DoubleSplatIndicator: '**';
FirstPageIndicator: [1]P ;
OtherTextIndicator: ~[\r\n]~[\r\n];


mode FIXED_CalcSpec_SQL;
CSQL_EMPTY_TEXT: [ ] {getCharPositionInLine()>=8}? [ ]* -> skip;
CSQL_TEXT: ~[\r\n] {getCharPositionInLine()>=8}? ~[\r\n]*;
CSQL_LEADBLANK : '     ' {getCharPositionInLine()==5}?-> skip;
CSQL_LEADWS : WORD5 {getCharPositionInLine()==5}?-> skip;
CSQL_END :
	 C  '/' E N D [-]E X E C  WS ~[\r\n]* {setText(getText().trim());} -> popMode ;
CSQL_CONT: [cC ] '+' -> skip;
CSQL_CSplat: [cC ] '*' -> skip,pushMode(FIXED_CalcSpec_SQL_Comments);
CSQL_EOL: NEWLINE -> skip;
CSQL_Any:  -> skip,popMode;

mode FIXED_CalcSpec_SQL_Comments;
CSQLC_LEADWS : CSQL_LEADWS-> skip;
CSQLC_CSplat : [cC ] '*' -> skip;
CSQLC_WS : [ \t] {getCharPositionInLine()>=8}? [ \t]* -> skip;
CSQLC_Comments : ~[\r\n ] {getCharPositionInLine()>=8}? ~[\r\n]* -> channel(HIDDEN);
CSQLC_Any : NEWLINE? -> skip,popMode;


mode FIXED_CalcSpec_X2;
C2_FACTOR2_CONT: ~[\r\n]{getCharPositionInLine()==36}?
		~[\r\n]* REPEAT_FIXED_CalcSpec_X2;
C2_FACTOR2: ~[\r\n]{getCharPositionInLine()==36}?
		~[\r\n]* ->popMode;
C2_OTHER: ~('\r' | '\n') {getCharPositionInLine()<36}?  ->skip;

fragment
REPEAT_FIXED_CalcSpec_X2 : '+' [ ]+ NEWLINE;

mode FIXED_InputSpec;
IS_BLANK_SPEC :
    '                                                                           '
    {getCharPositionInLine()==80}? -> type(BLANK_SPEC);
IS_FileName: WORD5_WCOLON WORD5_WCOLON {getCharPositionInLine()==16}?;
IS_FieldReserved: '                        ' {getCharPositionInLine()==30}? -> pushMode(FIXED_I_FIELD_SPEC),skip ;
IS_ExtFieldReserved:  '              ' {getCharPositionInLine()==20}?-> pushMode(FIXED_I_EXT_FIELD_SPEC),skip ;
IS_LogicalRelationship :  ('AND' | 'OR '| ' OR') {getCharPositionInLine()==18}?;
IS_ExtRecordReserved : '    ' {getCharPositionInLine()==20}? -> pushMode(FIXED_I_EXT_REC_SPEC),pushMode(IndicatorMode) ;
IS_Sequence : WORD_WCOLON WORD_WCOLON {getCharPositionInLine()==18}?;
IS_Number : [ 1nN] {getCharPositionInLine()==19}?;
IS_Option: [ oO] {getCharPositionInLine()==20}? -> pushMode(IndicatorMode);
IS_RecordIdCode:  WORD5_WCOLON WORD5_WCOLON WORD5_WCOLON WORD5_WCOLON
		WORD_WCOLON WORD_WCOLON WORD_WCOLON WORD_WCOLON {getCharPositionInLine()==46}?; //TODO better lexing
IS_WS : [ \t] {getCharPositionInLine()>=47}? [ \t]* -> type(WS),skip  ; // skip spaces, tabs
IS_COMMENTS : ~[\r\n] {getCharPositionInLine()>80}? ~[\r\n]* -> channel(HIDDEN) ; // skip spaces, tabs, newlines
IS_EOL : NEWLINE -> type(EOL),popMode;

mode FIXED_I_EXT_FIELD_SPEC;
IF_Name: WORD5_WCOLON WORD5_WCOLON {getCharPositionInLine()==30}?;
IF_Reserved: '                  ' {getCharPositionInLine()==48}? -> skip;
IF_FieldName: WORD5_WCOLON WORD5_WCOLON WORD_WCOLON WORD_WCOLON
	WORD_WCOLON WORD_WCOLON {getCharPositionInLine()==62}? ->pushMode(IndicatorMode),pushMode(IndicatorMode);
IF_Reserved2: '  ' {getCharPositionInLine()==68}? ->pushMode(IndicatorMode),pushMode(IndicatorMode),pushMode(IndicatorMode),skip; // 3 Indicators in a row
IF_WS : [ \t] {getCharPositionInLine()>=75}? [ \t]* -> type(WS),popMode,skip  ; // skip spaces, tabs

mode FIXED_I_EXT_REC_SPEC;
IR_WS : [ \t]{getCharPositionInLine()>=23}? [ \t]* -> type(WS),popMode  ; // skip spaces, tabs

mode FIXED_I_FIELD_SPEC;
IFD_DATA_ATTR: WORD_WCOLON WORD_WCOLON WORD_WCOLON WORD_WCOLON {getCharPositionInLine()==34}?;
IFD_DATETIME_SEP: ~[\r\n] {getCharPositionInLine()==35}?;
IFD_DATA_FORMAT: [A-Z ] {getCharPositionInLine()==36}?;
IFD_FIELD_LOCATION: WORD5_WCOLON WORD5_WCOLON {getCharPositionInLine()==46}?;
IFD_DECIMAL_POSITIONS: [ 0-9][ 0-9] {getCharPositionInLine()==48}?;
IFD_FIELD_NAME: WORD5_WCOLON WORD5_WCOLON WORD_WCOLON WORD_WCOLON WORD_WCOLON WORD_WCOLON {getCharPositionInLine()==62}?;
IFD_CONTROL_LEVEL : ('L'[0-9] | '  ') {getCharPositionInLine()==64}?;
IFD_MATCHING_FIELDS: ('M'[0-9] | '  ') {getCharPositionInLine()==66}? ->pushMode(IndicatorMode),pushMode(IndicatorMode),
	pushMode(IndicatorMode),pushMode(IndicatorMode);
IFD_BLANKS: '      ' {getCharPositionInLine()==80}? -> skip;
IFD_COMMENTS : ~[\r\n]{getCharPositionInLine()>80}? ~[\r\n]* -> channel(HIDDEN) ; // skip spaces, tabs, newlines
IFD_EOL : NEWLINE -> type(EOL),popMode,popMode;

mode HeaderSpecMode;
HS_OPEN_PAREN: OPEN_PAREN -> type(OPEN_PAREN);
HS_CLOSE_PAREN: CLOSE_PAREN -> type(CLOSE_PAREN);
HS_StringLiteralStart: ['] -> type(StringLiteralStart),pushMode(InStringMode) ;
HS_COLON: ':' -> type(COLON);
HS_ID: [#@%$*a-zA-Z] [&#@\-$*a-zA-Z0-9_/,.]* -> type(ID);
HS_WhiteSpace : [ \t]+ -> skip  ; // skip spaces, tabs, newlines
HS_CONTINUATION: NEWLINE
	WORD5 H  ~[*] -> skip;
HS_EOL : NEWLINE -> type(EOL),popMode;

fragment WORD5 : ~[\r\n]~[\r\n]~[\r\n]~[\r\n]~[\r\n];
fragment NAME5 : NAMECHAR NAMECHAR NAMECHAR NAMECHAR NAMECHAR;
// valid characters in symbolic names.
fragment NAMECHAR : [A-Za-z0-9$#@_ ];
// names cannot start with _ or numbers
fragment INITNAMECHAR : [A-Za-z$#@];
fragment WORD_WCOLON : ~[\r\n];//[a-zA-Z0-9 :*];
fragment WORD5_WCOLON : WORD_WCOLON WORD_WCOLON WORD_WCOLON WORD_WCOLON WORD_WCOLON;

// Case insensitive alphabet fragments
fragment A: [aA];
fragment B: [bB];
fragment C: [cC];
fragment D: [dD];
fragment E: [eE];
fragment F: [fF];
fragment G: [gG];
fragment H: [hH];
fragment I: [iI];
fragment J: [jJ];
fragment K: [kK];
fragment L: [lL];
fragment M: [mM];
fragment N: [nN];
fragment O: [oO];
fragment P: [pP];
fragment Q: [qQ];
fragment R: [rR];
fragment S: [sS];
fragment T: [tT];
fragment U: [uU];
fragment V: [vV];
fragment W: [wW];
fragment X: [xX];
fragment Y: [yY];
fragment Z: [zZ];
