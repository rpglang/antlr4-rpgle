package org.rpgleparser;

import org.antlr.v4.runtime.CommonToken;
import org.junit.jupiter.api.Test;
import org.rpgleparser.utils.TestUtils;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class TestP {

    @Test
    public void testProcedureInterfaceWithContinuationName() {
        String inputString =
                "     P getThingAvailable...\r\n" +
                        "     P                 B\r\n" +
                        "     D                 PI                  like(typeQuantity)\r\n" +
                        "     D  SomeNumber                         like(typeP50u)                 const\r\n"+
                        "     P                 E\r\n" ;
        inputString = TestUtils.padSourceLines(inputString, false);
        List<String> errors = new ArrayList<String>();
        List<CommonToken> tokenList = TestUtils.getParsedTokens(inputString, errors);
        assertTrue(errors.isEmpty());
    }
    
    
    @Test
    public void testProcedureInterfaceWithContinuationName1() {
        String inputString =
                "     P Function        B  \r\n" +
                "     D                 PI                  like(typeQuantity)\r\n" +
                "     D  SomeNumber                         like(typeP50u)                 const\r\n"+
        		"     P                 E\r\n" ;
        inputString = TestUtils.padSourceLines(inputString, false);
        List<String> errors = new ArrayList<String>();
        List<CommonToken> tokenList = TestUtils.getParsedTokens(inputString, errors);
        assertTrue(errors.isEmpty());
    }
    

}
