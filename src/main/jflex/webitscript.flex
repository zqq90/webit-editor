package webit.script.editor;

import java.util.List;
import java.util.LinkedList;
import jsyntaxpane.Token;
import jsyntaxpane.TokenType;
import jsyntaxpane.lexers.DefaultJFlexLexer;

%%
%public
%class WebitScriptLexer
%extends DefaultJFlexLexer
%function _yylex
%unicode
%char
%type Token

%{
    //================ >> user code
    
    private static final byte PARAN     = 1;
    private static final byte BRACKET   = 2;
    private static final byte CURLY     = 3;
    private static final byte INTERPOLATION = 4;
    private static final byte STATEMENT     = 5;
    
    public WebitScriptLexer() {
        super();
    }

    @Override
    public int yychar() {
        return yychar;
    }

    private LinkedList<Token> caches = new LinkedList<Token>();

    private void addToken(Token token){
        caches.add(token);
    }
    
    private void resetStart(){
        //back the point;
        
        zzAtBOL  = true;
        zzAtEOF  = false;
        zzEOFDone = false;

        zzCurrentPos = zzMarkedPos = 0;
        yyline = yychar = yycolumn = 0;

        tokenStart = yychar; tokenLength = 0;
        yybegin(YYTEXT);
    }
    

    public Token yylex() throws java.io.IOException {
        if(caches.isEmpty() == false){
            return caches.pollFirst();
        }
        Token token = _yylex();
        tokenStart = yychar+yylength(); tokenLength = 0;
        if(caches.isEmpty() == false){
            caches.addLast(token);
            return caches.pollFirst();
        }else{
            return token;
        }
    }

    private boolean interpolationFlag = false;
    
    private Token popTextStatementSymbol(boolean interpolationFlag){
        this.interpolationFlag = interpolationFlag;
        yybegin(YYSTATEMENT);
        if(tokenLength!=0){
            addToken(token(TokenType.TEXT_BLOCK, tokenStart, tokenLength));
        }
        return new Token(TokenType.TEXT_DELIMITER,  yychar() + offset + yylength()-2,2,(byte) (interpolationFlag? INTERPOLATION : STATEMENT));
    }

    //================ << user code
%}


/* main character classes */
LineTerminator = \r|\n|\r\n
InputCharacter = [^\r\n]

WhiteSpace = {LineTerminator} | [ \t\f]

/* comments */
Comment = {TraditionalComment} | {EndOfLineComment} | 
          {DocumentationComment}

TraditionalComment = "/*" [^*] ~"*/" | "/*" "*"+ "/"
EndOfLineComment = "//" {InputCharacter}* {LineTerminator}?
DocumentationComment = "/*" "*"+ [^/*] ~"*/"

/* identifiers */
Identifier = [:jletter:][:jletterdigit:]*
/* Identifier = {Identifier0} | "for." {Identifier0} */

/* integer literals */

BinIntegerLiteral = 0 [bB] [01] {1,32}
BinLongLiteral = 0 [bB] [01] {1,64} [lL]

DecIntegerLiteral = 0 | [1-9][0-9]*
DecLongLiteral    = {DecIntegerLiteral} [lL]

HexIntegerLiteral = 0 [xX] 0* {HexDigit} {1,8}
HexLongLiteral    = 0 [xX] 0* {HexDigit} {1,16} [lL]
HexDigit          = [0-9a-fA-F]

OctIntegerLiteral = 0+ [1-3]? {OctDigit} {1,15}
OctLongLiteral    = 0+ 1? {OctDigit} {1,21} [lL]
OctDigit          = [0-7]

/* floating point literals */
DoubleLiteralPart = ({FLit1}|{FLit2}|{FLit3}) {Exponent}?
FloatLiteral  = {DoubleLiteralPart} [fF]
DoubleLiteral = {DoubleLiteralPart} [dD]

FLit1    = [0-9]+ \. [0-9]+ 
FLit2    = \. [0-9]+ 
FLit3    = [0-9]+ 
Exponent = [eE] [+-]? [0-9]+

/* string and character literals */
/* StringCharacter = [^\r\n\"\\] */
StringCharacter = [^\"\\]

SingleCharacter = [^\r\n\'\\]

/* Delimiter */

DelimiterStatementStart     = "<%"
DelimiterStatementEnd       = "%>"
DelimiterInterpolationStart   = "${"
/* DelimiterInterpolationEnd     = "}"*/

DelimiterStatementStartMatch   = [\\]* {DelimiterStatementStart}
DelimiterInterpolationStartMatch   = [\\]* {DelimiterInterpolationStart}


%state YYTEXT, YYSTATEMENT, STRING, CHARLITERAL

%%

<YYINITIAL>{
    .|\n     {  resetStart(); }
     <<EOF>> { return null; }
}

/* text block */
<YYTEXT>{

  /* if to YYSTATEMENT */
  {DelimiterStatementStartMatch}        { int length = yylength()-2; if(length%2 == 0){tokenLength +=length; return popTextStatementSymbol(false);} else {tokenLength += yylength();} }

  /* if to PLACEHOLDER */
  {DelimiterInterpolationStartMatch}      { int length = yylength()-2; if(length%2 == 0){tokenLength +=length; return popTextStatementSymbol(true);} else {tokenLength += yylength();} }
  

  .|\n                                  { tokenLength += yylength(); }

 <<EOF>>                        { if(tokenLength!=0){addToken(token(TokenType.TEXT_BLOCK, tokenStart, tokenLength));} return null; }
}


/* code block */
<YYSTATEMENT> {

  /* keywords */
  "break"                        |
  "case"                         |
  "continue"                     |
  "do"                           |
  "else"                         |
  "for"                          |
  "default"                      |
  "instanceof"                   |
  "new"                          |
  "if"                           |
  "super"                        |
  "switch"                       |
  "while"                        |
  "var"                          |
  "#"                            |
  "return"                       |
  "this"                         |
  "throw"                        |
  "try"                          |
  "catch"                        |
  "finally"                      |
  "native"                       |
  "static"                       |
  "echo"                         |
  "const"                        |
  "true"                         |
  "false"                        |
  "null"                         { return token(TokenType.KEYWORD); }

  "function"                     |
  "import"                       |
  "include"                      |
  "@import"                      { return token(TokenType.KEYWORD2); }
  
  /* separators */

  "("                            { return token(TokenType.OPERATOR,  PARAN); }
  ")"                            { return token(TokenType.OPERATOR, -PARAN); }
  "{"                            { return token(TokenType.OPERATOR,  CURLY); }
  "}"                            { if(!interpolationFlag){return token(TokenType.OPERATOR, -CURLY);}else{yybegin(YYTEXT); tokenStart = yychar+yylength(); tokenLength=0;return token(TokenType.TEXT_DELIMITER, -INTERPOLATION);} }
  "["                            { return token(TokenType.OPERATOR,  BRACKET); }
  "]"                            { return token(TokenType.OPERATOR, -BRACKET); }
  
  ";"                            |
  ","                            |
  "."                            |
  ".."                           |
  "="                            |
  ">"                            |
  "<"                            |
  "!"                            |
  "~"                            |
  "?"                            |
  ":"                            |
  "?:"                           |
  "=="                           |
  "<="                           |
  ">="                           |
  "!="                           |
  "&&"                           |
  "||"                           |
  "++"                           |
  "--"                           |
  "+"                            |
  "-"                            |
  "*"                            |
  "/"                            |
  "&"                            |
  "|"                            |
  "^"                            |
  "%"                            |
  "<<"                           |
  ">>"                           |
  ">>>"                          |
  "+="                           |
  "-="                           |
  "*="                           |
  "/="                           |
  "&="                           |
  "|="                           |
  "^="                           |
  "%="                           |
  "<<="                          |
  ">>="                          |
  ">>>="                         |
  "@"                            |
  "=>"                           { return token(TokenType.OPERATOR); } 

  
  /* string literal */
  \"                             { yybegin(STRING); tokenStart = yychar; tokenLength = 1; }

  /* character literal */
  \'                             { yybegin(CHARLITERAL); tokenStart = yychar; tokenLength = 1;  }

  /* numeric literals */

  /* Note: This is matched together with the minus, because the number is too big to 
     be represented by a positive integer. */
  "-2147483648"                  |
  {BinIntegerLiteral}            |
  {BinLongLiteral}               |
  {DecIntegerLiteral}            |
  {DecLongLiteral}               |
  {HexIntegerLiteral}            |
  {HexLongLiteral}               |
  {OctIntegerLiteral}            |
  {OctLongLiteral}               |
  {FloatLiteral}                 |
  {DoubleLiteralPart}            |
  {DoubleLiteral}                { return token(TokenType.NUMBER); }
  
  /* comments */
  {Comment}                      { return token(TokenType.COMMENT); }

  /* whitespace */
  {WhiteSpace}                   { /* ignore */ }

  /* identifiers */
  {Identifier}                   { return token(TokenType.IDENTIFIER); }

  /* %> */
  {DelimiterStatementEnd}        { yybegin(YYTEXT); tokenStart = yychar+yylength(); tokenLength=0;  return token(TokenType.TEXT_DELIMITER, -STATEMENT);  }

}



<STRING> {
  \"                             { yybegin(YYSTATEMENT); /* length also includes the trailing quote */ return token(TokenType.STRING, tokenStart, tokenLength + 1); }
  
  {StringCharacter}+             |
  "\\b"                          |
  "\\t"                          |
  "\\n"                          |
  "\\f"                          |
  "\\r"                          |
  "\\\""                         |
  "\\'"                          |
  "\\\\"                         |
  \\[0-3]?{OctDigit}?{OctDigit}  |

  \\{LineTerminator}             { tokenLength += yylength(); }
  
  /* error cases */
  \\.                            { tokenLength += 2; }
  <<EOF>>                        { if(tokenLength!=0){addToken(token(TokenType.STRING, tokenStart, tokenLength));} return null; }
}

<CHARLITERAL> {
  {SingleCharacter}\'            { yybegin(YYSTATEMENT);
                                     /* length also includes the trailing quote*/
                                     return token(TokenType.STRING, tokenStart, tokenLength + 1); }
  
  {SingleCharacter}+             { tokenLength += yylength(); }
  
  /* escape sequences */

  \\.                            { tokenLength += 2; }
  {LineTerminator}               { yybegin(YYSTATEMENT); }
  <<EOF>>                        { if(tokenLength!=0){addToken(token(TokenType.STRING, tokenStart, tokenLength));} return null; }
}

/* error fallback */
.|\n                             {  }
<<EOF>>                          { return null; }

