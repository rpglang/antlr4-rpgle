package org.rpgleparser;

import org.antlr.v4.runtime.CommonToken;
import org.junit.jupiter.api.Test;
import org.rpgleparser.utils.TestUtils;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.rpgleparser.utils.TestUtils.expectTokensForSourceLines;

public class TestC {

    @Test
    public void testContinuation() {
        String inputString =
                "     C                   EVAL      QuiteLongFieldName...\r\n" +
                        "     C                             ThatCannotAlwaysFitInOneLine = 'abc'\r\n";
        expectTokensForSourceLines(inputString,
                "C", "", "", "", "", "EVAL", "QuiteLongFieldName", "...",
                "ThatCannotAlwaysFitInOneLine", "=", "'", "abc", "'", "");
    }

    @Test
    public void testCSpec() {
        String inputString =
                "     C  NL9FACTOR1       XXAL      FACTOR2\r\n";
        inputString = TestUtils.padSourceLines(inputString, false);
//        TestUtils.printTokens(inputString, false);
//        TestUtils.showParseTree(inputString, false);
        List<String> errors = new ArrayList<String>();
        List<CommonToken> tokenList = TestUtils.getParsedTokens(inputString, errors);
        assertEquals(RpgLexer.CS_FactorContent, tokenList.get(4).getType());
        assertTrue(errors.isEmpty());
        assertEquals(RpgLexer.CS_OperationAndExtender, tokenList.get(5).getType());
        assertEquals(RpgLexer.CS_FactorContent, tokenList.get(6).getType());
        assertEquals("FACTOR1", tokenList.get(4).getText());
        assertEquals("XXAL", tokenList.get(5).getText());
        assertEquals("FACTOR2", tokenList.get(6).getText());
    }

//	@Test
//	public void testCSpec_EVAL(){
//		String inputString="     C     FACTOR1       EVAL      FACTOR2 is really long long long\r\n";
//		inputString = TestUtils.padSourceLines(inputString);
//		List<String> errors = new ArrayList<String>();
//      List<CommonToken> tokenList = TestUtils.getParsedTokens(inputString, errors);
//      assertThat(errors, is(empty()));
//		assertEquals(RpgLexer.C_FACTOR,tokenList.get(4).getType());
//		assertEquals(RpgLexer.C2_FACTOR2,tokenList.get(6).getType());
//		assertEquals("FACTOR1",tokenList.get(4).getText().trim());
//		assertEquals("FACTOR2 is really long long long",tokenList.get(6).getText().trim());
//	}

    @Test
    public void testCSpec_ENTRYPLIST() {
        String inputString =
                "     C     *ENTRY        PLIST\r\n" +
                "     C                   PARM                    TODAY";
        expectTokensForSourceLines(inputString,
                "C", "", "", "", "*ENTRY", "PLIST","","","","","", "", "","\r\n",
        		"C", "", "", "", "", "PARM","","TODAY","","","", "", "","\r\n");
    }

    @Test
    public void testCSpec_IF() {
        String inputString =
                "     C                   IF        WHOS = 'G'\r\n"
		+"     C                   ENDIF";
        expectTokensForSourceLines(inputString,
        		"C","","","","","IF","WHOS","=","'","G","'","","C","","","","","ENDIF","","","","","","","","");
    }

    @Test
    public void testCSpec_TIME() {
        String inputString =
                "     C                   TIME                    CTIME             6 0\r\n";
        expectTokensForSourceLines(inputString,
                "C", "", "", "", "", "TIME", "", "CTIME","6","0","", "", "","\r\n");
    }

    @Test
    public void testCSpec_MOVEL() {
        String inputString =
                "     C                   MOVEL     'P'           B8BATX\r\n";
        expectTokensForSourceLines(inputString,
                "C", "", "", "", "", "MOVEL", "'","P","'", "B8BATX","","","","","","\r\n");
    }

    @Test
    public void testCSpec_ExecSQL() {
        String inputString =
                "     C/Exec SQL\r\n" +
                        "     C+ call GETCANCPOLICYOS(:ReWritePol,\r\n" +
                        "     C+                      :ActiveSts,\r\n" +
                        "     C+                      :AmountOS)\r\n" +
                        "     C/End-Exec";
        expectTokensForSourceLines(inputString,
                "C/Exec SQL",
                "call GETCANCPOLICYOS(:ReWritePol,", ":ActiveSts,",
                ":AmountOS)", "C/End-Exec");
    }

    @Test
    public void testCSpec_ExecSQLWComments() {
        String inputString =
                "     C/Exec SQL\r\n" +
                        "     C+ call GETCANCPOLICYOS(:ReWritePol,\r\n" +
                        "c123 C+                      :ActiveSts,\r\n" +
                        "     C+                      :AmountOS)\r\n" +
                        "     C/End-Exec";
        expectTokensForSourceLines(inputString,
                "C/Exec SQL",
                "call GETCANCPOLICYOS(:ReWritePol,", ":ActiveSts,",
                ":AmountOS)", "C/End-Exec");
    }

    //Remove test, PARM must be preceded by CALL,CALLB or PLIST
//    @Test
//    public void testCSpec_Comments() {
//        String inputString =
//                "     C                   PARM                    POLNBR                         POLICY NUMBER\r\n";
//        expectTokensForSourceLines(inputString,
//                "C", "", "", "", "", "PARM", "", "POLNBR", "", "", "", "", "","POLICY NUMBER", "");
//    }

    @Test
    public void testCSpec_Comments2() {
        String inputString =
                "     C                   IF        WHOS = 'G'                                   Home office cpy\r\n"
        		+"     C                   ENDIF";
        expectTokensForSourceLines(inputString,
        		"C","","","","","IF","WHOS","=","'","G","'","","C","","","","","ENDIF","","","","","","","","");
    }

    @Test
    public void testCSpec_Callp() {
        String inputString =
                "     C                   callp     Cmd('OVRPRTF FILE(QSYSPRT) OUTQ(PRT30\\)' +\r\n" +
                        "     C                             ' DRAWER(5) HOLD(*YES) SAVE(*YES) ' +\r\n" +
                        "     C                             'DEVTYPE(*AFPDS) PAGRTT(0) ':200)\r\n" +
                        "     C                   open      QSYSPRT";
        expectTokensForSourceLines(inputString,
                "C", "", "", "", "", "callp", "Cmd", "(", "'",
                "OVRPRTF FILE(QSYSPRT) OUTQ(PRT30\\)", "'", "+", "'",
                "DRAWER(5) HOLD(*YES) SAVE(*YES)", "'", "+", "'",
                "DEVTYPE(*AFPDS) PAGRTT(0)", "'", ":", "200", ")", "", "C", "",
                "", "", "", "open", "QSYSPRT", "", "", "", "", "", "", "");
    }

    @Test
    public void testCSpecWithSTrangeChars() {
        String inputString =
                        "     C                   EVAL      §§SVAR=§§SVAR";
        String paddedInput = TestUtils.padSourceLines(inputString, false);
        List<String> errors = new ArrayList<String>();
        boolean gui = false;
		TestUtils.parseAndGetTokens(paddedInput, errors, gui);
    }
    
    @Test
    public void testCSpec_Comments3() {
        String inputString =
                "                                                                                Get next number2\r\n" +
                        "     C                   eval      @IRDRW = 'PHAR'";
        expectTokensForSourceLines(inputString,
                "C", "", "", "", "", "eval", "@IRDRW", "=", "'", "PHAR", "'", "");
    }

    @Test
    public void testCSpec_SetONLR() {
        String inputString =
                "     C                   seton                                        lr    		";
        expectTokensForSourceLines(inputString,
                "C", "", "", "", "", "seton", "", "", "", "", "lr", "", "", "");
    }

    @Test
    public void testCSpec_ACQ() {
        String inputString =
                "     C  NL9FACTOR1       ACQ       FACTOR2\r\n";
        expectTokensForSourceLines(inputString,
        		"C","","N","L9","FACTOR1","ACQ","FACTOR2","","","","","","","");
    }

    @Test
    public void testCSpec_ADD() {
        String inputString =
                "     C  NL9FACTOR1       ADD       FACTOR2       RESULT\r\n";
        expectTokensForSourceLines(inputString,
        		"C","","N","L9","FACTOR1","ADD","FACTOR2","RESULT","","","","","","");
    }
    @Test
    public void testCSpec_ADD_H() {
        String inputString =
                "     C  NL9FACTOR1       ADD (H)   FACTOR2       RESULT\r\n";
        expectTokensForSourceLines(inputString,
        		"C","","N","L9","FACTOR1","ADD","(","H",")","FACTOR2","RESULT","","","","","","");
    }
    @Test
    public void testCSpec_CALLB_notExtender() {
        String inputString =
                "     C  NL9              CALLB     FACTOR2       RESULT\r\n";
        expectTokensForSourceLines(inputString,
        		"C","","N","L9","","CALLB","FACTOR2","RESULT","","","","","","");
    }    
    @Test
    public void testCSpec_CALLB_1Extender() {
        String inputString =
                "     C  NL9              CALLB(D)  FACTOR2       RESULT\r\n";
        expectTokensForSourceLines(inputString,
        		"C","","N","L9","","CALLB","(","D",")","FACTOR2","RESULT","","","","","","");
    }
    @Test
    public void testCSpec_CALLB_2Extenders() {
        String inputString =
                "     C  NL9              CALLB(D E)FACTOR2       RESULT\r\n";
        expectTokensForSourceLines(inputString,
        		"C","","N","L9","","CALLB","(","D","E",")","FACTOR2","RESULT","","","","","","");
    }
}
