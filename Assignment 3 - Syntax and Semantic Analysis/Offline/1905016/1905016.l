%option noyywrap yylineno

%x COMMENTSINGLE
%x COMMENTMULTI
%x STRING

%{
#include<cstdio>
#include<iostream>
#include<cstdlib>
#include<string>
#include<vector>
#include "1905016.cpp"
#include "y.tab.h"

using namespace std;

extern SymbolTable* table;
extern FILE* logout;
void yyerror(char *);

int line_count=1,error_count=0;

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
			yylval.node = new Node((string)"IF"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <IF> Lexeme %s found\n",line_count,yytext);
            return IF;
        }

"else"	{
            yylval.node = new Node((string)"ELSE"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <ELSE> Lexeme %s found\n",line_count,yytext);
            return ELSE;
        }

"for"	{
            yylval.node = new Node((string)"FOR"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <FOR> Lexeme %s found\n",line_count,yytext);
            return FOR;
        }

"while"	{
            yylval.node = new Node((string)"WHILE"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <WHILE> Lexeme %s found\n",line_count,yytext);
            return WHILE;
        }

"int"	{
            yylval.node = new Node((string)"INT"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <INT> Lexeme %s found\n",line_count,yytext);
            return INT;
        }

"float"	{
            yylval.node = new Node((string)"FLOAT"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <FLOAT> Lexeme %s found\n",line_count,yytext);
            return FLOAT;
        }

"void"	{
            yylval.node = new Node((string)"VOID"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <VOID> Lexeme %s found\n",line_count,yytext);
            return VOID;
        }

"return"	{
                yylval.node = new Node((string)"RETURN"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
                fprintf(logout,"Line# %d: Token <RETURN> Lexeme %s found\n",line_count,yytext);
                return RETURN;
            }

"println"	{
                yylval.node = new Node((string)"PRINTLN"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
                fprintf(logout,"Line# %d: Token <PRINTLN> Lexeme %s found\n",line_count,yytext);
                return PRINTLN;
            }

    /*
"do"	{
			//fprintf(tokenout,"<DO, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <DO> Lexeme %s found\n",line_count,yytext);
		}

"break"	{
			//fprintf(tokenout,"<BREAK, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <BREAK> Lexeme %s found\n",line_count,yytext);
		}

"char"	{
			//fprintf(tokenout,"<CHAR, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <CHAR> Lexeme %s found\n",line_count,yytext);
		}

"double"	{
                //fprintf(tokenout,"<DOUBLE, %s>\n",yytext);
                fprintf(logout,"Line# %d: Token <DOUBLE> Lexeme %s found\n",line_count,yytext);
            }

"switch"	{
                //fprintf(tokenout,"<SWITCH, %s>\n",yytext);
                fprintf(logout,"Line# %d: Token <SWITCH> Lexeme %s found\n",line_count,yytext);
            }

"case"	{
			//fprintf(tokenout,"<CASE, %s>\n",yytext);
			fprintf(logout,"Line# %d: Token <CASE> Lexeme %s found\n",line_count,yytext);
		}

"default"	{
                //fprintf(tokenout,"<DEFAULT, %s>\n",yytext);
                fprintf(logout,"Line# %d: Token <DEFAULT> Lexeme %s found\n",line_count,yytext);
            }

"continue"	{
                //fprintf(tokenout,"<CONTINUE, %s>\n",yytext);
                fprintf(logout,"Line# %d: Token <CONTINUE> Lexeme %s found\n",line_count,yytext);
            }
    */
		
{DIGIT}+ 	{
                yylval.nodeSymbolInfo = new NodeSymbolInfo(new Node((string)"CONST_INT"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count),new SymbolInfo(yytext, "CONST_INT"));
                fprintf(logout,"Line# %d: Token <CONST_INT> Lexeme %s found\n",line_count,yytext);
				return CONST_INT;
			}

(({DIGIT}+(\.{DIGIT}+)?)|(\.{DIGIT}+))(E[+-]?{DIGIT}+)?	{
                                                            yylval.nodeSymbolInfo = new NodeSymbolInfo(new Node((string)"CONST_FLOAT"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count),new SymbolInfo(yytext, "CONST_FLOAT"));
                                                            fprintf(logout,"Line# %d: Token <CONST_FLOAT> Lexeme %s found\n",line_count,yytext);
                                                            return CONST_FLOAT;
                                                        }

    /*
'[^\\\n']' 	    {
                    //fprintf(tokenout,"<CONST_CHAR, %c>\n",yytext[1]);
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
                        //fprintf(tokenout,"<CONST_CHAR, %c>\n",ch);
                        fprintf(logout,"Line# %d: Token <CONST_CHAR> Lexeme %c found\n",line_count,ch);
                    }
    */

[+-]	{
            yylval.nodeSymbolInfo = new NodeSymbolInfo(new Node((string)"ADDOP"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count),new SymbolInfo(yytext, "ADDOP"));
            fprintf(logout,"Line# %d: Token <ADDOP> Lexeme %s found\n",line_count,yytext);
			return ADDOP;
        }

[*/%]	{
            yylval.nodeSymbolInfo = new NodeSymbolInfo(new Node((string)"MULOP"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count),new SymbolInfo(yytext, "MULOP"));
            fprintf(logout,"Line# %d: Token <MULOP> Lexeme %s found\n",line_count,yytext);
			return MULOP;
        }

"++"	{
            yylval.node = new Node((string)"INCOP"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <INCOP> Lexeme %s found\n",line_count,yytext);
            return INCOP;
        }

"--"	{
            yylval.node = new Node((string)"DECOP"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <DECOP> Lexeme %s found\n",line_count,yytext);
            return DECOP;
        }

("<")|("<=")|(">")|(">=")|("==")|("!=")	{
                                            yylval.nodeSymbolInfo = new NodeSymbolInfo(new Node((string)"RELOP"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count),new SymbolInfo(yytext, "RELOP"));
                                            fprintf(logout,"Line# %d: Token <RELOP> Lexeme %s found\n",line_count,yytext);
                                            return RELOP;
                                        }

"="	    {
            yylval.node = new Node((string)"ASSIGNOP"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
            return ASSIGNOP;
        }

("&&")|("||")	{
                    yylval.nodeSymbolInfo = new NodeSymbolInfo(new Node((string)"LOGICOP"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count),new SymbolInfo(yytext, "LOGICOP"));
                    fprintf(logout,"Line# %d: Token <LOGICOP> Lexeme %s found\n",line_count,yytext);
                    return LOGICOP;
                }

    /*
[&|^]|("<<")|(">>")	{
                        //fprintf(tokenout,"<BITOP, %s>\n",yytext);
                        fprintf(logout,"Line# %d: Token <BITOP> Lexeme %s found\n",line_count,yytext);
                    }
    */

"!"		{
            yylval.node = new Node((string)"NOT"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <NOT> Lexeme %s found\n",line_count,yytext);
            return NOT;
        }

"("		{
            yylval.node = new Node((string)"LPAREN"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <LPAREN> Lexeme %s found\n",line_count,yytext);
            return LPAREN;
        }

")"		{
            yylval.node = new Node((string)"RPAREN"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <RPAREN> Lexeme %s found\n",line_count,yytext);
            return RPAREN;
        }

"{"		{
            yylval.node = new Node((string)"LCURL"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <LCURL> Lexeme %s found\n",line_count,yytext);
            return LCURL;
        }

"}"		{
            yylval.node = new Node((string)"RCURL"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <RCURL> Lexeme %s found\n",line_count,yytext);
            return RCURL;
        }

"["		{
            yylval.node = new Node((string)"LSQUARE"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <LSQUARE> Lexeme %s found\n",line_count,yytext);
            return LSQUARE;
        }

"]"		{
            yylval.node = new Node((string)"RSQUARE"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <RSQUARE> Lexeme %s found\n",line_count,yytext);
            return RSQUARE;
        }

","		{
            yylval.node = new Node((string)"COMMA"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <COMMA> Lexeme %s found\n",line_count,yytext);
            return COMMA;
        }

";"		{
            yylval.node = new Node((string)"SEMICOLON"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count);
            fprintf(logout,"Line# %d: Token <SEMICOLON> Lexeme %s found\n",line_count,yytext);
            return SEMICOLON;
        }

({LETTER}|_)({LETTER}|_|{DIGIT})*	{
                                        yylval.nodeSymbolInfo = new NodeSymbolInfo(new Node((string)"ID"+" : "+yytext+"\t<Line: "+to_string(line_count)+">\n",line_count,line_count),new SymbolInfo(yytext, "ID"));
                                        fprintf(logout,"Line# %d: Token <ID> Lexeme %s found\n",line_count,yytext); 
                                        return ID;
                                    }

    /*
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
                    //fprintf(tokenout,"<%s, %s>\n",token.c_str(),convertedString.c_str());
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
    */

.	{
        error_count++;
        //fprintf(tokenout,"<ERROR 8, %s>\n",yytext);
        fprintf(logout,"Error at line# %d: UNRECOGNIZED_CHAR %s\n",line_count,yytext);
    }

%%