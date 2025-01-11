%option noyywrap

%x COMMENTSINGLE
%x COMMENTMULTI
%x STRING

%{
#include<cstdio>
#include<cstdlib>
#include<string>
#include<vector>
#include "1905016.cpp"

using namespace std;

int line_count=1,error_count=0;
SymbolTable st(10);

FILE *logout;
FILE *tokenout;
string comment,plainString,convertedString;

void countNewLine(const char* val,int length) {
    for (int i=0;i<length;i++) {
        if (val[i]=='\n') line_count++;
    }
}

%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n

%%

{WHITESPACE}    {
                    /* DO NOTHING */
                }

{NEWLINE} {line_count++;}


"if"	{
			fprintf(tokenout,"<IF, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <IF> Lexeme %s found\n",line_count,yytext);
		}

"else"	{
			fprintf(tokenout,"<ELSE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <ELSE> Lexeme %s found\n",line_count,yytext);
		}

"for"	{
			fprintf(tokenout,"<FOR, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <FOR> Lexeme %s found\n",line_count,yytext);
		}

"while"	{
			fprintf(tokenout,"<WHILE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <WHILE> Lexeme %s found\n",line_count,yytext);
		}

"do"	{
			fprintf(tokenout,"<DO, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <DO> Lexeme %s found\n",line_count,yytext);
		}

"break"	{
			fprintf(tokenout,"<BREAK, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <BREAK> Lexeme %s found\n",line_count,yytext);
		}

"int"	{
			fprintf(tokenout,"<INT, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <INT> Lexeme %s found\n",line_count,yytext);
		}

"char"	{
			fprintf(tokenout,"<CHAR, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <CHAR> Lexeme %s found\n",line_count,yytext);
		}

"float"	{
			fprintf(tokenout,"<FLOAT, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <FLOAT> Lexeme %s found\n",line_count,yytext);
		}

"double"	{
			fprintf(tokenout,"<DOUBLE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <DOUBLE> Lexeme %s found\n",line_count,yytext);
		}

"void"	{
			fprintf(tokenout,"<VOID, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <VOID> Lexeme %s found\n",line_count,yytext);
		}

"return"	{
			fprintf(tokenout,"<RETURN, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RETURN> Lexeme %s found\n",line_count,yytext);
		}

"switch"	{
			fprintf(tokenout,"<SWITCH, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <SWITCH> Lexeme %s found\n",line_count,yytext);
		}

"case"	{
			fprintf(tokenout,"<CASE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <CASE> Lexeme %s found\n",line_count,yytext);
		}

"default"	{
			fprintf(tokenout,"<DEFAULT, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <DEFAULT> Lexeme %s found\n",line_count,yytext);
		}

"continue"	{
			fprintf(tokenout,"<CONTINUE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <CONTINUE> Lexeme %s found\n",line_count,yytext);
		}
		
{DIGIT}+ 	{
				fprintf(tokenout,"<CONST_INT, %s>\n",yytext);
				fprintf(logout,"Line# %d: Token <CONST_INT> Lexeme %s found\n",line_count,yytext);
			}

(({DIGIT}+(\.{DIGIT}+)?)|(\.{DIGIT}+))(E[+-]?{DIGIT}+)?	{
                                                            fprintf(tokenout,"<CONST_FLOAT, %s>\n",yytext);
                                                            fprintf(logout,"Line# %d: Token <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
                                                        }

'[^\\\n']' 	    {
                    fprintf(tokenout,"<CONST_CHAR, %c>\n",yytext[1]);
                    fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %c found\n",line_count,yytext[1]);
                }

'\\['"nt\\afrbv0]'  {
            char ch;
            switch(yytext[2]) {
                case 'n':
                    ch = '\n';
                    break;
                case 't':
                    ch = '\t';
                    break;
                case 'a':
                    ch = '\a';
                    break;
                case 'f':
                    ch = '\f';
                    break;
                case 'r':
                    ch = '\r';
                    break;
                case 'b':
                    ch = '\b';
                    break;
                case 'v':
                    ch = '\v';
                    break;
                case '0':
                    ch = '\0';
                    break;
                default:
                    ch = yytext[2];
            }
            fprintf(tokenout,"<CONST_CHAR, %c>\n",ch);
            fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %c found\n",line_count,ch);
        }

[+-]	{
            fprintf(tokenout,"<ADDOP, %s>\n",yytext);
            fprintf(logout,"Line# %d: Token <ADDOP> Lexeme %s found\n",line_count,yytext);
        }

[*/%]	{
            fprintf(tokenout,"<MULOP, %s>\n",yytext);
            fprintf(logout,"Line# %d: Token <MULOP> Lexeme %s found\n",line_count,yytext);
        }

("++")|("--")	{
                    fprintf(tokenout,"<INCOP, %s>\n",yytext);
                    fprintf(logout,"Line# %d: Token <INCOP> Lexeme %s found\n",line_count,yytext);
                }

("<")|("<=")|(">")|(">=")|("==")|("!=")	{
                                            fprintf(tokenout,"<RELOP, %s>\n",yytext);
                                            fprintf(logout,"Line# %d: Token <RELOP> Lexeme %s found\n",line_count,yytext);
                                        }

"="	    {
            fprintf(tokenout,"<ASSIGNOP, %s>\n",yytext);
            fprintf(logout,"Line# %d: Token <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
        }

("&&")|("||")	{
                    fprintf(tokenout,"<LOGICOP, %s>\n",yytext);
                    fprintf(logout,"Line# %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext);
                }

[&|^]|("<<")|(">>")	{
                        fprintf(tokenout,"<BITOP, %s>\n",yytext);
                        fprintf(logout,"Line# %d: Token <BITOP> Lexeme %s found\n",line_count,yytext);
                    }

"!"		{
			fprintf(tokenout,"<NOT, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <NOT> Lexeme %s found\n",line_count,yytext);
		}

"("		{
			fprintf(tokenout,"<LPAREN, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LPAREN> Lexeme %s found\n",line_count,yytext);
		}

")"		{
			fprintf(tokenout,"<RPAREN, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RPAREN> Lexeme %s found\n",line_count,yytext);
		}

"{"		{
            st.enterScope();
			fprintf(tokenout,"<LCURL, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LCURL> Lexeme %s found\n",line_count,yytext);
		}

"}"		{
            st.exitScope();
			fprintf(tokenout,"<RCURL, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RCURL> Lexeme %s found\n",line_count,yytext);
		}

"["		{
			fprintf(tokenout,"<LSQUARE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <LSQUARE> Lexeme %s found\n",line_count,yytext);
		}

"]"		{
			fprintf(tokenout,"<RSQUARE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <RSQUARE> Lexeme %s found\n",line_count,yytext);
		}

","		{
			fprintf(tokenout,"<COMMA, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <COMMA> Lexeme %s found\n",line_count,yytext);
		}

";"		{
			fprintf(tokenout,"<SEMICOLON, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <SEMICOLON> Lexeme %s found\n",line_count,yytext);
		}

({LETTER}|_)({LETTER}|_|{DIGIT})*	{
                                        bool ok = st.insert(yytext,"ID");
                                        fprintf(tokenout,"<ID, %s>\n",yytext);
                                        fprintf(logout,"Line# %d: Token <ID> Lexeme %s found\n",line_count,yytext);
                                        if (ok) st.printAllScopeTable(logout);
                                        else fprintf(logout,"\t%s already exists in the current ScopeTable\n",yytext);
                                    }

\"  {
        BEGIN STRING;
        plainString = convertedString = "";
        plainString += yytext;
    }

<STRING>[^"\n]   {
                plainString += yytext;
                convertedString += yytext;
            }

<STRING>\\\n    {
                    plainString += yytext;
                }

<STRING>\\. {
                plainString += yytext;
                char ch;
                switch(yytext[1]) {
                    case 'n':
                        ch = '\n';
                        break;
                    case 't':
                        ch = '\t';
                        break;
                    case 'a':
                        ch = '\a';
                        break;
                    case 'f':
                        ch = '\f';
                        break;
                    case 'r':
                        ch = '\r';
                        break;
                    case 'b':
                        ch = '\b';
                        break;
                    case 'v':
                        ch = '\v';
                        break;
                    case '0':
                        ch = '\0';
                        break;
                    default:
                        ch = yytext[1];
                }
                convertedString += ch;
            }

<STRING>\"      {
                    plainString += yytext;
                    int line_prev = line_count;
                    string token = "SINGLE LINE STRING";
                    countNewLine(plainString.c_str(),plainString.size());
                    if (line_count==line_prev) {
                        token = "SINGLE LINE STRING";
                    }
                    else {
                        token = "MULTI LINE STRING";
                    }
                    fprintf(tokenout,"<%s, %s>\n",token.c_str(),convertedString.c_str());
                    fprintf(logout,"Line# %d: Token <%s> Lexeme %s found\n",line_prev,token.c_str(),plainString.c_str());
                    BEGIN INITIAL;
                }

<STRING>\n      {
                    error_count++;
                    countNewLine(plainString.c_str(),plainString.size());
                    fprintf(logout,"Error at line# %d: UNFINISHED_STRING %s\n",line_count,plainString.c_str());
                    line_count++;
                    BEGIN INITIAL;
                }

<STRING><<EOF>>     {
                        error_count++;
                        countNewLine(plainString.c_str(),plainString.size());
                        fprintf(logout,"Error at line# %d: UNFINISHED_STRING %s\n",line_count,plainString.c_str());
                        BEGIN INITIAL;
                    }

\/\/    {
            BEGIN COMMENTSINGLE;
            comment = "";
            comment += yytext;
        }

<COMMENTSINGLE>.    {
                        comment += yytext;
                    }

<COMMENTSINGLE>\\\n     {
                            comment += yytext;
                        }

<COMMENTSINGLE>\n   {
                        fprintf(logout,"Line# %d: Token <SINGLE LINE COMMENT> Lexeme %s found\n",line_count,comment.c_str());
                        countNewLine(comment.c_str(),comment.size());
                        line_count++;
                        BEGIN INITIAL;
                    } 

<COMMENTSINGLE><<EOF>>  {
                            fprintf(logout,"Line# %d: Token <SINGLE LINE COMMENT> Lexeme %s found\n",line_count,comment.c_str());
                            countNewLine(comment.c_str(),comment.size());
                            BEGIN INITIAL;
                        }

\/\*    {
            BEGIN COMMENTMULTI;
            comment = "";
            comment += yytext;
        }

<COMMENTMULTI>(.|(\n))  {
                            comment += yytext;
                        }

<COMMENTMULTI>\*\/  {
                        comment += yytext;
                        fprintf(logout,"Line# %d: Token <MULTI LINE COMMENT> Lexeme %s found\n",line_count,comment.c_str());
                        countNewLine(comment.c_str(),comment.size());
                        BEGIN INITIAL;
                    }

<COMMENTMULTI><<EOF>>   {
                            error_count++;
                            countNewLine(comment.c_str(),comment.size());
                            fprintf(logout,"Error at line# %d: UNFINISHED_COMMENT %s\n",line_count,comment.c_str());
                            BEGIN INITIAL;
                        }                              

(({DIGIT}+(\.{DIGIT}*){2,})|((\.{DIGIT}+)(\.{DIGIT}*)+))(E[+-]?{DIGIT}+)?	{
                                                                                error_count++;
                                                                                //fprintf(tokenout,"<ERROR 1, %s>\n",yytext);
                                                                                fprintf(logout,"Error at line# %d: TOO_MANY_DECIMAL_POINTS %s\n",line_count,yytext);
                                                                            }

(({DIGIT}+(\.{DIGIT}+)?)|(\.{DIGIT}+))(E[+-]?(({DIGIT}+(\.{DIGIT}*)+)|((\.{DIGIT}+)(\.{DIGIT}*)*)))	    {
                                                                                                            error_count++;
                                                                                                            //fprintf(tokenout,"<ERROR 2, %s>\n",yytext);
                                                                                                            fprintf(logout,"Error at line# %d: ILLFORMED_NUMBER %s\n",line_count,yytext);
                                                                                                        }

(({DIGIT}+(\.{DIGIT}+)?)|(\.{DIGIT}+))(E[+-]?{DIGIT}+)?({LETTER}|_)({LETTER}|_|{DIGIT})*	{
                                                                                                error_count++;
                                                                                                //fprintf(tokenout,"<ERROR 3, %s>\n",yytext);
                                                                                                fprintf(logout,"Error at line# %d: INVALID_ID_SUFFIX_NUM_PREFIX %s\n",line_count,yytext);
                                                                                            }

'[^\\'\n][^'\n]+'	{
                        error_count++;
                        //fprintf(tokenout,"<ERROR 4, %s>\n",yytext);
                        fprintf(logout,"Error at line# %d: MULTICHAR_CONST_CHAR %s\n",line_count,yytext);
                    }

'\\.[^'\n]*'	    {
                        error_count++;
                        //fprintf(tokenout,"<ERROR 4, %s>\n",yytext);
                        fprintf(logout,"Error at line# %d: MULTICHAR_CONST_CHAR %s\n",line_count,yytext);
                    }

'[^'\n]?   {
                error_count++;
                //fprintf(tokenout,"<ERROR 5, %s>\n",yytext);
                fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n",line_count,yytext);
            }

'\\.	{
            error_count++;
            //fprintf(tokenout,"<ERROR 5, %s>\n",yytext);
            fprintf(logout,"Error at line# %d: UNFINISHED_CONST_CHAR %s\n",line_count,yytext);
        }

''	{
        error_count++;
        //fprintf(tokenout,"<ERROR 5, %s>\n",yytext);
        fprintf(logout,"Error at line# %d: EMPTY_CONST_CHAR %s\n",line_count,yytext);
    }

<<EOF>> {
            st.printAllScopeTable(logout);
            fprintf(logout,"Total lines: %d\n",line_count);
            fprintf(logout,"Total errors: %d\n",error_count);
            return 0;
        }

.	{
        error_count++;
        //fprintf(tokenout,"<ERROR 8, %s>\n",yytext);
        fprintf(logout,"Error at line# %d: UNRECOGNIZED_CHAR %s\n",line_count,yytext);
    }


%%

int main(int argc, char** argv) {
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("1905016_log.txt","w");
	tokenout= fopen("1905016_token.txt","w");

	yyin= fin;
	yylex();

	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}
