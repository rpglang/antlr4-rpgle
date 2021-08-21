package org.rpgleparser.integration;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.TokenSource;
import org.antlr.v4.runtime.atn.PredictionMode;
import org.antlr.v4.runtime.tree.ParseTree;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.rpgleparser.RpgLexer;
import org.rpgleparser.RpgParser;
import org.rpgleparser.tokens.PreprocessTokenSource;
import org.rpgleparser.utils.FixedWidthBufferedReader;
import org.rpgleparser.utils.TestUtils;
import org.rpgleparser.utils.TestUtils.ErrorListener;
import org.rpgleparser.utils.TreeUtils;

/**
 * Run a test over each *.rpgle file in src/test/resources/org/rpgleparser/tests
 * @author ryaneberly
 *
 */
public class TestFiles {
	
	File sourceFile;
	boolean autoReplaceFailed=false;
	static String singleTestName=null;
	static{
		try{
			singleTestName= getBundle("org.rpgleparser.tests.test").getString("RunSingleTest");
		}catch(Exception ignored){}
	}

	public TestFiles(File sourceFile) {
		super();
		this.sourceFile = sourceFile;
		try{
			autoReplaceFailed="Y".equalsIgnoreCase(getBundle("org.rpgleparser.tests.test").getString("AutoReplaceFailedTestResults"));
		}catch(Exception e){}
	}
	
	@Test
	public void test() throws IOException, URISyntaxException{
	@ParameterizedTest(name = "{index}{0}")
	@MethodSource("primeNumbers")
	public void test(File sourceFile) throws IOException, URISyntaxException{
		final String inputString = TestUtils.loadFile(sourceFile);
		final File expectedFile = new File(sourceFile.getPath().replaceAll("\\.rpgle", ".expected.txt"));
		final String expectedFileText = expectedFile.exists()?TestUtils.loadFile(expectedFile):null;
		final String expectedTokens = getTokens(expectedFileText);
		String expectedTree = getTree(expectedFileText);
		final List<String> errors = new ArrayList<String>();
        final ANTLRInputStream input = new ANTLRInputStream(new FixedWidthBufferedReader(inputString));
		final RpgLexer rpglexer = new RpgLexer(input);
        final TokenSource lexer = new PreprocessTokenSource(rpglexer);
        final CommonTokenStream tokens = new CommonTokenStream(lexer);

        final RpgParser parser = new RpgParser(tokens);

        final ErrorListener errorListener = new ErrorListener(errors, rpglexer, parser);
        rpglexer.addErrorListener(errorListener);
        parser.addErrorListener(errorListener);

		final String actualTokens = TestUtils.printTokens(lexer,rpglexer.getVocabulary());
        boolean rewriteExpectFile=false;
		if(expectedTokens != null && expectedTokens.trim().length()>0 ){
			if(autoReplaceFailed && !expectedTokens.equals(actualTokens)){
				rewriteExpectFile=true;
			}else{
				assertEquals(expectedTokens, actualTokens, "Token lists do not match");
			}
		}
		rpglexer.reset();

		parser.getInterpreter().setPredictionMode(PredictionMode.SLL);
		parser.reset();
		final ParseTree parseTree = parser.r();

		final String actualTree = TreeUtils.printTree(parseTree, parser);
		if(!errors.isEmpty()){
			System.out.println("/*===TOKENS===*/\r\n" + actualTokens + "\r\n");
			System.out.println("/*===TREE===*/\r\n" + actualTree + "\r\n/*======*/");
		}
		assertTrue(errors.isEmpty());

    	if(expectedTree==null || expectedTree.trim().length() == 0||rewriteExpectFile){
    		writeExpectFile(expectedFile,actualTokens,actualTree);
    		System.out.println("Tree written to " + expectedFile);
		}else{
			if(autoReplaceFailed && !actualTree.equals(expectedTree)){
				System.out.println("Replaced content of " + expectedFile);
				expectedTree = actualTree;
				writeExpectFile(expectedFile,actualTokens,actualTree);
			}
        	assertEquals(expectedTree, actualTree, "Parse trees do not match");
        }
	}

    private void writeExpectFile(File expectedFile, String actualTokens,
			String actualTree) throws IOException {
		final FileOutputStream fos = new FileOutputStream(expectedFile,false);
		fos.write("/*===TOKENS===*/\r\n".getBytes());
		fos.write(actualTokens.getBytes());
		fos.write("\r\n/*===TREE===*/\r\n".getBytes());
		fos.write(actualTree.getBytes());
		fos.write("\r\n/*======*/".getBytes());
		fos.close();

	}

	private String getTokens(String expectedFileText) {
		if(expectedFileText != null && expectedFileText.contains("/*===TOKENS===*/")){
			int startIdx = expectedFileText.indexOf("/*===TOKENS===*/") + 16;
			while(expectedFileText.charAt(startIdx) == '\r' || expectedFileText.charAt(startIdx) == '\n'){
				startIdx++;
			}
			int endIndex = expectedFileText.indexOf("/*===",startIdx);
			if(endIndex > startIdx){
				while(expectedFileText.charAt(endIndex-1) == '\r' || expectedFileText.charAt(endIndex-1) == '\n'){
					endIndex--;
				}
				return expectedFileText.substring(startIdx, endIndex);
			}
		}
		return null;
	}

	private String getTree(String expectedFileText) {
		if(expectedFileText != null && expectedFileText.contains("/*===TREE===*/")){
			int startIdx = expectedFileText.indexOf("/*===TREE===*/") + 14;
			while(expectedFileText.charAt(startIdx) == '\r' || expectedFileText.charAt(startIdx) == '\n'){
				startIdx++;
			}
			int endIndex = expectedFileText.indexOf("/*======*/",startIdx);
			if(endIndex > startIdx){
				while(expectedFileText.charAt(endIndex-1) == '\r' || expectedFileText.charAt(endIndex-1) == '\n'){
					endIndex--;
				}
				return expectedFileText.substring(startIdx, endIndex);
			}
		}
		if(expectedFileText != null && expectedFileText.contains("/*===")){
			return null;
		}
		return expectedFileText;
	}

	public static Stream<File> primeNumbers() throws URISyntaxException, IOException {
    	final List<File> listing = new ArrayList<>();
    	fillResourceListing(new File("src/test/resources/org/rpgleparser/tests"), listing);
		return listing.stream();
	}

	private static void fillResourceListing(File file, List<File> retval)  {
    	if(file != null){
    		if(file.isDirectory()){
    			for(File subfile: file.listFiles()){
    				fillResourceListing(subfile, retval);
    			}
    		}else if(file.getName().toLowerCase().endsWith(".rpgle")){
    			if(singleTestName == null || singleTestName.equals(file.getName())){
    				retval.add(file);
    			}
    			else if(singleTestName.equals("*LAST")){
    				if(retval.size()==0 || file.lastModified() > retval.get(0).lastModified()){
    					retval.clear();
    					retval.add(file);
    				}
    			}
    		}
    	}
    }
}
