%{
#include<iostream>
#include<fstream>
#include<cstdlib>
#include<climits>
#include<cstring>
#include<sstream>
#include<cmath>
#include "1905016.cpp"


using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int yylineno;
extern int line_count;
extern int error_count;

SymbolTable *table = new SymbolTable(11);
FILE* fp;
//FILE* logout;
//FILE* error;
//FILE* parsetree;
fstream code;
fstream tempfile;

string currentfunc = "";
string rtype="";
string globalVarDec = "";
int offset = 0;
int label_count = 0;
int errorline,errorstartline=INT_MAX,funcdeferrorline,funcdeferrorstartline;
vector<NodeSymbolInfo*> vList;
vector<NodeSymbolInfo*> pList;

void yyerror(char *s)
{
	errorline = yylineno;
	//fprintf(logout,"Error at line no %d : %s\n",yylineno,s);
}

string addSpace(string s) {
	s = " "+s;
	for (int i=0;i<s.size()-1;i++) {
		if (s[i]=='\n') {
			s = s.substr(0,i+1)+" "+s.substr(i+1,string::npos);
		}
	}
	return s;
}

void clearList(vector<NodeSymbolInfo*>& vList) {
	for (int i=0;i<vList.size();i++) {
		delete vList[i];
	}
	vList.clear();
}

void addPrintln() {
	code<<"println PROC\n";
	code<<"\tPUSH BP\n";
	code<<"\tMOV BP, SP\n";
	code<<"\tMOV BX, [BP+4]\n";
	code<<"\tCMP BX, 0\n";
	code<<"\tJGE NONNEG\n";
	code<<"\tMOV AH, 2\n";
	code<<"\tMOV DL, '-'\n";
	code<<"\tINT 21H\n";
	code<<"\tNEG BX\n";
	code<<"NONNEG:\n";
	code<<"\tMOV AX, BX\n";
	code<<"\tMOV CX, 10\n";
	code<<"\tMOV BL, 0\n";
	code<<"\tMOV DX, 0 	\n";
	code<<"OUTP:\n";
	code<<"\tDIV CX\n";
	code<<"\tPUSH DX\n";
	code<<"\tMOV DX, 0\n";
	code<<"\tINC BL\n";
	code<<"\tCMP AX, 0\n";
	code<<"\tJA OUTP\n";
	code<<"\tMOV BH, 0\n";
	code<<"PRINT:\n";
	code<<"\tCMP BH, BL\n";
	code<<"\tJGE ENDPRINT\n";
	code<<"\tPOP DX\n";
	code<<"\tADD DL, '0'\n";
	code<<"\tMOV AH, 2\n";
	code<<"\tINT 21H\n";
	code<<"\tINC BH\n";
	code<<"\tJMP PRINT\n";
	code<<"ENDPRINT:\n";
	code<<"\tMOV DL, 10\n";
	code<<"\tINT 21H\n";
	code<<"\tMOV DL, 13\n";
	code<<"\tINT 21H\n";
	code<<"\tPOP BP\n";
	code<<"\tRET\n";
	code<<"println ENDP\n";
}

vector<string> instructions;
int* labelNewVal;
vector<bool> printInstructions;

void optimizeCode() {
	code.seekg(0,ios::beg);
	string s;
	while (!code.eof()) {
		getline(code,s);
		instructions.push_back(s);
		printInstructions.push_back(true);
	}
	//
	labelNewVal = new int[label_count];
	for (int i=0;i<label_count;i++) {
		labelNewVal[i] = i;
	}
	// optimize
	for (int i=0;i<instructions.size()-1;i++) {
		// redundant label remove
		if ((instructions[i].size()>1 && instructions[i][0]=='L' && instructions[i][instructions[i].size()-1]==':') && (instructions[i+1].size()>1 && instructions[i+1][0]=='L' && instructions[i+1][instructions[i+1].size()-1]==':')) {
			labelNewVal[stoi(instructions[i+1].substr(1,instructions[i+1].size()-2))] = labelNewVal[stoi(instructions[i].substr(1,instructions[i].size()-2))];
			printInstructions[i+1] = false;
		}
		// remove redundant add, sub (not mul and div because they are not straightforward)
		if (instructions[i].size()>2 && (instructions[i].substr(0,5)=="\tADD " || instructions[i].substr(0,5)=="\tSUB ") && instructions[i].substr(instructions[i].size()-3,3) == ", 0") {
			printInstructions[i] = false;
		}
		// remove redundant push pop
		if (instructions[i].size()>6 && instructions[i+1].size()>5 && instructions[i].substr(0,6)=="\tPUSH " && instructions[i+1].substr(0,5)=="\tPOP " && instructions[i].substr(6,instructions[i].size()-6)==instructions[i+1].substr(5,instructions[i+1].size()-5)) {
			printInstructions[i] = false;
			printInstructions[i+1] = false;
		}
		// remove redundant move
		if (instructions[i].size()>5 && instructions[i+1].size()>5 && instructions[i].substr(0,5)=="\tMOV " && instructions[i+1].substr(0,5)=="\tMOV ") {
			stringstream a(instructions[i].substr(5,instructions[i].size()-5));
			stringstream b(instructions[i+1].substr(5,instructions[i+1].size()-5));
			string f1,s1,f2,s2;
			getline(a,f1,',');
			getline(b,f2,',');
			// check for substring range out of bound
			s1 = instructions[i].substr(5+f1.size()+2,instructions[i].size()-5-f1.size()-2);
			s2 = instructions[i+1].substr(5+f2.size()+2,instructions[i+1].size()-5-f2.size()-2);
			if (f1==s2 && s1==f2) {
				printInstructions[i+1] = false;
			}
		}
	}
	// second pass to fix redundant label
	for (int i=0;i<instructions.size();i++) {
		if (instructions[i].size()>1 && instructions[i].substr(0,2)=="\tJ") {
			stringstream a(instructions[i].substr(1,instructions[i].size()-1));
			string f0,s0;
			getline(a,f0,' ');
			// check for substring range out of bound
			s0 = instructions[i].substr(1+f0.size()+1,instructions[i].size()-1-f0.size()-1);
			if (s0.size()>1 && s0[0]=='L') {
				instructions[i] = instructions[i].substr(0,instructions[i].size()-s0.size()+1)+to_string(labelNewVal[stoi(s0.substr(1,s0.size()-1))]);
			}
		}
	}
	// third pass to fix redundant instructions after return
	bool functionEnd = false;
	int instructionNum = 0;
	for (int i=1;i<instructions.size();i++) {
		if (instructions[i].size()>1 && instructions[i][0]=='L' && instructions[i][instructions[i].size()-1]==':') {
			functionEnd = false;
		}
		else if (functionEnd && instructions[i].size()>4 && instructions[i].substr(instructions[i].size()-5,5)==" ENDP") {
			for (int j=instructionNum;j<i;j++) {
				printInstructions[j] = false;
			}
			functionEnd = false;
		}
		else if (!functionEnd) {
			if (instructions[i]=="\tRET" || (instructions[i-1]=="\tMOV AH, 4CH" && instructions[i]=="\tINT 21H")) {
				functionEnd = true;
				instructionNum = i+1;
			}
		}
	}
	// print to file
	for (int i=0;i<instructions.size();i++) {
		if (printInstructions[i]) {
			tempfile<<instructions[i]<<endl;
		}
	}
	delete [] labelNewVal;
	instructions.clear();
	printInstructions.clear();
}


%}


%union {
	Node* node;
	NodeSymbolInfo* nodeSymbolInfo;
	int* label;
	LabelOffset* labelOffset;
}

%token <nodeSymbolInfo> CONST_INT CONST_FLOAT ADDOP MULOP RELOP LOGICOP ID

%token <node> PRINTLN IF ELSE FOR WHILE INT FLOAT VOID RETURN INCOP DECOP ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LSQUARE RSQUARE COMMA SEMICOLON

%type <node> start statement statements var_declaration func_declaration func_definition unit program declaration_list parameter_list compound_statement

%type <nodeSymbolInfo> expression_statement type_specifier variable expression factor term unary_expression simple_expression rel_expression logic_expression argument_list arguments

%type <label> elseaction whileaction foraction forexpaction compound_action logic_action forexpendaction

%type <labelOffset> action whileexpaction

%destructor { 
				//printf("Discarding node symbol. %s\n",$$->parsetree.c_str());
				if (errorstartline>$$->startLine) {
					errorstartline = $$->startLine;
				}
				delete $$;
			} <node>
%destructor { 
				//printf("Discarding nodeSymbolInfo symbol. %s\n",$$->symbolInfo->getName().c_str());
				if (errorstartline>$$->node->startLine) {
					errorstartline = $$->node->startLine;
				}
				delete $$;
			} <nodeSymbolInfo>
%destructor { 
				delete $$;
			} <label>
%destructor { 
				delete $$;
			} <labelOffset>

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		if (error_count==0) {
			code<<".MODEL SMALL\n";
			code<<".STACK 1000H\n";
			code<<".DATA\n";
			code<<globalVarDec<<"\n";
			tempfile.seekg(0,ios::beg);
			string s;
			while (!tempfile.eof()) {
				getline(tempfile,s);
				code<<s<<"\n";
			}
			addPrintln();
			code<<"END MAIN\n";
			tempfile.close();
			tempfile.open("optimized_code.asm",ios::in|ios::out|ios::trunc);
			// optimize code
			optimizeCode();
		}
		else {
			tempfile.close();
			tempfile.open("optimized_code.asm",ios::in|ios::out|ios::trunc);
		}
		//fprintf(logout,"start : program\n");
		//fprintf(logout,"Total Lines: %d\n",line_count);
		//fprintf(logout,"Total Errors: %d\n",error_count);
		$$ = new Node("start : program \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine);
		//fprintf(parsetree,"%s",$$->parsetree.c_str());
		delete $1;
	}
	;

program : program unit 
		{
			//fprintf(logout,"program : program unit \n");
			$$ = new Node("program : program unit \t<Line: "+to_string($1->startLine)+"-"+to_string($2->endLine)+">\n"+addSpace($1->parsetree+$2->parsetree),$1->startLine,$2->endLine);
			delete $1;
			delete $2;
		}
		| unit
		{
			//fprintf(logout,"program : unit\n");
			$$ = new Node("program : unit \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine);
			delete $1;
		}
		;
	
unit : var_declaration
		{
			//fprintf(logout,"unit : var_declaration\n");
			$$ = new Node("unit : var_declaration \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine);
			delete $1;
		}
     	| func_declaration
	 	{
			//fprintf(logout,"unit : func_declaration\n");
			$$ = new Node("unit : func_declaration \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine);
			delete $1;
		}
     	| func_definition
	 	{
			//fprintf(logout,"unit : func_definition\n");
			$$ = new Node("unit : func_definition \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine);
			delete $1;
		}
     	;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			$2->symbolInfo->returnType = $1->symbolInfo->returnType;
			$2->symbolInfo->size = -1;
			bool isVoid = false;
			if (pList.size()>1 || (pList.size()>0 && (pList[0]->symbolInfo->getName()!="" || pList[0]->symbolInfo->returnType!="VOID"))) {
				for (int i=0;i<pList.size();i++) {
					$2->symbolInfo->addParameter(pList[i]->symbolInfo->returnType,pList[i]->symbolInfo->getName());
					if (pList[i]->symbolInfo->returnType=="VOID") {
						//fprintf(error,"Line# %d: Parameter %d of '%s' can not have void type\n",pList[i]->node->startLine,i+1,$2->symbolInfo->getName().c_str());
						error_count++;
						isVoid = true;
						// check error string
					}
				}
			}
			if (!isVoid) {
				SymbolInfo* temp = new SymbolInfo($2->symbolInfo);
				bool ok = table->insert(temp);
				if (!ok) {
					delete temp;
					SymbolInfo* info = table->lookUp($2->symbolInfo->getName());
					if (info->size>=0 || info->size<-2) {
						//fprintf(error,"Line# %d: '%s' redeclared as different kind of symbol\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
						error_count++;
					}
					else {
						bool prevOk = true;
						if (info->returnType!=$2->symbolInfo->returnType) {
							////fprintf(error,"Line# %d: Conflicting types for '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
							//error_count++;
							prevOk = false;
						}
						else if (info->parameterList.size()!=$2->symbolInfo->parameterList.size()) {
							////fprintf(error,"Line# %d: Number of parameter mismatch for '%s' with previous %s\n",$2->node->startLine,$2->symbolInfo->getName().c_str(),(info->size==-1?"declaration":"definition"));
							//error_count++;
							prevOk = false;
						}
						else {
							for (int i=0;i<info->parameterList.size();i++) {
								if (info->parameterList[i]->parameterType!=$2->symbolInfo->parameterList[i]->parameterType) {
									////fprintf(error,"Line# %d: Type mismatch for parameter %d of '%s' with previous %s\n",pList[i]->node->startLine,i+1,$2->symbolInfo->getName().c_str(),(info->size==-1?"declaration":"definition"));
									//error_count++;
									prevOk = false;
									break;
								}
							}
						}
						if (!prevOk) {
							//fprintf(error,"Line# %d: Conflicting types for '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
							error_count++;
						}
					}
				}
			}
			clearList(pList);
			//fprintf(logout,"func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n");
			$$ = new Node("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON \t<Line: "+to_string($1->node->startLine)+"-"+to_string($6->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree+$3->parsetree+$4->parsetree+$5->parsetree+$6->parsetree),$1->node->startLine,$6->endLine);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
			delete $5;
			delete $6;
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			$2->symbolInfo->returnType = $1->symbolInfo->returnType;
			$2->symbolInfo->size = -1;
			SymbolInfo* temp = new SymbolInfo($2->symbolInfo);
			bool ok = table->insert(temp);
			if (!ok) {
				delete temp;
				SymbolInfo* info = table->lookUp($2->symbolInfo->getName());
				if (info->size>=0 || info->size<-2) {
					//fprintf(error,"Line# %d: '%s' redeclared as different kind of symbol\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
					error_count++;
				}
				else {
					bool prevOk = true;
					if (info->returnType!=$2->symbolInfo->returnType) {
						////fprintf(error,"Line# %d: Conflicting types for '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
						//error_count++;
						prevOk = false;
					}
					else if (info->parameterList.size()!=$2->symbolInfo->parameterList.size()) {
						////fprintf(error,"Line# %d: Number of parameter mismatch for '%s' with previous %s\n",$2->node->startLine,$2->symbolInfo->getName().c_str(),(info->size==-1?"declaration":"definition"));
						//error_count++;
						prevOk = false;
					}
					else {
						for (int i=0;i<info->parameterList.size();i++) {
							if (info->parameterList[i]->parameterType!=$2->symbolInfo->parameterList[i]->parameterType) {
								////fprintf(error,"Line# %d: Type mismatch for parameter %d of '%s' with previous %s\n",pList[i]->node->startLine,i+1,$2->symbolInfo->getName().c_str(),(info->size==-1?"declaration":"definition"));
								//error_count++;
								prevOk = false;
								break;
							}
						}
					}
					if (!prevOk) {
						//fprintf(error,"Line# %d: Conflicting types for '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
						error_count++;
					}
				}
			}
			clearList(pList);
			//fprintf(logout,"func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n");
			$$ = new Node("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON \t<Line: "+to_string($1->node->startLine)+"-"+to_string($5->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree+$3->parsetree+$4->parsetree+$5->parsetree),$1->node->startLine,$5->endLine);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
			delete $5;
		}
		| type_specifier ID LPAREN error RPAREN SEMICOLON
		{
			clearList(pList);
			//fprintf(error,"Line# %d: Syntax error at parameter list of function declaration\n",errorline);	
			//fprintf(logout,"func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n");
			$$ = new Node("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON \t<Line: "+to_string($1->node->startLine)+"-"+to_string($6->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree+$3->parsetree+"parameter_list : error\t<Line: "+to_string(errorstartline)+">\n"+$5->parsetree+$6->parsetree),$1->node->startLine,$6->endLine);
			errorstartline = INT_MAX;
			error_count++;
			delete $1;
			delete $2;
			delete $3;
			delete $5;
			delete $6;
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN {
			$2->symbolInfo->returnType = $1->symbolInfo->returnType;
			rtype = $2->symbolInfo->returnType;
			$2->symbolInfo->size = -2;
			if (table->getScopeNum()==1) {
				bool isVoid = false;
				if (pList.size()>1 || (pList.size()>0 && (pList[0]->symbolInfo->getName()!="" || pList[0]->symbolInfo->returnType!="VOID"))) {
					for (int i=0;i<pList.size();i++) {
						$2->symbolInfo->addParameter(pList[i]->symbolInfo->returnType,pList[i]->symbolInfo->getName());
						if (pList[i]->symbolInfo->returnType=="VOID") {
							//fprintf(error,"Line# %d: Parameter %d of '%s' can not have void type\n",pList[i]->node->startLine,i+1,$2->symbolInfo->getName().c_str());
							error_count++;
							isVoid = true;
							// check error string
						}
						// uncomment for nameless parameter check
						/*
						if (pList[i]->symbolInfo->getName()=="") {
							//fprintf(error,"Line# %d: Parameter %d of '%s' can not be nameless\n",pList[i]->node->startLine,i+1,$2->symbolInfo->getName().c_str());
							error_count++;
							isVoid = true;
							// check error string
						}
						*/
					}
				}
				if (!isVoid) {
					SymbolInfo* temp = new SymbolInfo($2->symbolInfo);
					bool ok = table->insert(temp);
					if (!ok) {
						delete temp;
						SymbolInfo* info = table->lookUp($2->symbolInfo->getName());
						if (info->size>=0 || info->size<-2) {
							//fprintf(error,"Line# %d: '%s' redeclared as different kind of symbol\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
							error_count++;
						}
						else {
							bool prevOk = true;
							if (info->returnType!=$2->symbolInfo->returnType) {
								////fprintf(error,"Line# %d: Conflicting types for '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
								//error_count++;
								prevOk = false;
							}
							else if (info->parameterList.size()!=$2->symbolInfo->parameterList.size()) {
								////fprintf(error,"Line# %d: Number of parameter mismatch for '%s' with previous %s\n",$2->node->startLine,$2->symbolInfo->getName().c_str(),(info->size==-1?"declaration":"definition"));
								//error_count++;
								prevOk = false;
							}
							else {
								for (int i=0;i<info->parameterList.size();i++) {
									if (info->parameterList[i]->parameterType!=$2->symbolInfo->parameterList[i]->parameterType) {
										////fprintf(error,"Line# %d: Type mismatch for parameter %d of '%s' with previous %s\n",pList[i]->node->startLine,i+1,$2->symbolInfo->getName().c_str(),(info->size==-1?"declaration":"definition"));
										//error_count++;
										prevOk = false;
										break;
									}
								}
							}
							if (!prevOk) {
								//fprintf(error,"Line# %d: Conflicting types for '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
								error_count++;
							}
							else if (info->size==-2) {
								//fprintf(error,"Line# %d: Redefinition of function '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
								error_count++;
							}
							else {
								tempfile<<info->getName()<<" PROC\n";
								if (info->getName()=="main") {
									tempfile<<"\tMOV AX, @DATA\n";
									tempfile<<"\tMOV DS, AX\n";
								}
								tempfile<<"\tPUSH BP\n";
								tempfile<<"\tMOV BP, SP\n";
								offset = 0;
								currentfunc = info->getName();
							}
						}
					}
					else {
						tempfile<<temp->getName()<<" PROC\n";
						if (temp->getName()=="main") {
							tempfile<<"\tMOV AX, @DATA\n";
							tempfile<<"\tMOV DS, AX\n";
						}
						tempfile<<"\tPUSH BP\n";
						tempfile<<"\tMOV BP, SP\n";
						offset = 0;
						currentfunc = temp->getName();
					}
				}
			}
			else {
				//fprintf(error,"Line# %d: Invalid scoping of function '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
				error_count++;
			}
			// not clearing pList because it is needed in inserting to new scope
		} compound_statement
		{
			tempfile<<"\tPOP BP\n";
			if ($2->symbolInfo->getName()=="main") {
				tempfile<<"\tMOV AH, 4CH\n";
				tempfile<<"\tINT 21H\n";
			}
			else {
				tempfile<<"\tRET\n";
			}
			tempfile<<$2->symbolInfo->getName()+" ENDP\n";
			//fprintf(logout,"func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n");
			$$ = new Node("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement \t<Line: "+to_string($1->node->startLine)+"-"+to_string($7->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree+$3->parsetree+$4->parsetree+$5->parsetree+$7->parsetree),$1->node->startLine,$7->endLine);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
			delete $5;
			// not freeing $6 what is even $6? {}? then what is it passing?
			delete $7;
		}
		| type_specifier ID LPAREN RPAREN {
			clearList(pList);
			$2->symbolInfo->returnType = $1->symbolInfo->returnType;
			rtype = $2->symbolInfo->returnType;
			$2->symbolInfo->size = -2;
			if (table->getScopeNum()==1) {
				SymbolInfo* temp = new SymbolInfo($2->symbolInfo);
				bool ok = table->insert(temp);
				if (!ok) {
					delete temp;
					SymbolInfo* info = table->lookUp($2->symbolInfo->getName());
					if (info->size>=0 || info->size<-2) {
						//fprintf(error,"Line# %d: '%s' redeclared as different kind of symbol\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
						error_count++;
					}
					else {
						bool prevOk = true;
						if (info->returnType!=$2->symbolInfo->returnType) {
							////fprintf(error,"Line# %d: Conflicting types for '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
							//error_count++;
							prevOk = false;
						}
						else if (info->parameterList.size()!=$2->symbolInfo->parameterList.size()) {
							////fprintf(error,"Line# %d: Number of parameter mismatch for '%s' with previous %s\n",$2->node->startLine,$2->symbolInfo->getName().c_str(),(info->size==-1?"declaration":"definition"));
							//error_count++;
							prevOk = false;
						}
						else {
							for (int i=0;i<info->parameterList.size();i++) {
								if (info->parameterList[i]->parameterType!=$2->symbolInfo->parameterList[i]->parameterType) {
									////fprintf(error,"Line# %d: Type mismatch for parameter %d of '%s' with previous %s\n",pList[i]->node->startLine,i+1,$2->symbolInfo->getName().c_str(),(info->size==-1?"declaration":"definition"));
									//error_count++;
									prevOk = false;
									break;
								}
							}
						}
						if (!prevOk) {
							//fprintf(error,"Line# %d: Conflicting types for '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
							error_count++;
						}
						else if (info->size==-2) {
							//fprintf(error,"Line# %d: Redefinition of function '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
							error_count++;
						}
						else {
								tempfile<<info->getName()<<" PROC\n";
								if (info->getName()=="main") {
									tempfile<<"\tMOV AX, @DATA\n";
									tempfile<<"\tMOV DS, AX\n";
								}
								tempfile<<"\tPUSH BP\n";
								tempfile<<"\tMOV BP, SP\n";
								offset = 0;
								currentfunc = info->getName();
						}
					}
				}
				else {
					tempfile<<temp->getName()<<" PROC\n";
					if (temp->getName()=="main") {
						tempfile<<"\tMOV AX, @DATA\n";
						tempfile<<"\tMOV DS, AX\n";
					}
					tempfile<<"\tPUSH BP\n";
					tempfile<<"\tMOV BP, SP\n";
					offset = 0;
					currentfunc = temp->getName();
				}
			}
			else {
				//fprintf(error,"Line# %d: Invalid scoping of function '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
				error_count++;
			}
			
		} compound_statement
		{
			tempfile<<"\tPOP BP\n";
			if ($2->symbolInfo->getName()=="main") {
				tempfile<<"\tMOV AH, 4CH\n";
				tempfile<<"\tINT 21H\n";
			}
			else {
				tempfile<<"\tRET\n";
			}
			tempfile<<$2->symbolInfo->getName()+" ENDP\n";
			//fprintf(logout,"func_definition : type_specifier ID LPAREN RPAREN compound_statement\n");
			$$ = new Node("func_definition : type_specifier ID LPAREN RPAREN compound_statement \t<Line: "+to_string($1->node->startLine)+"-"+to_string($6->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree+$3->parsetree+$4->parsetree+$6->parsetree),$1->node->startLine,$6->endLine);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
			// what is even $5? do we even need to free it?
			delete $6;
		}
		| type_specifier ID LPAREN error RPAREN {
			$2->symbolInfo->returnType = $1->symbolInfo->returnType;
			rtype = $2->symbolInfo->returnType;
			$2->symbolInfo->size = -2;
			funcdeferrorline = errorline;
			funcdeferrorstartline = errorstartline;
			errorstartline = INT_MAX;
			if (table->getScopeNum()==1) {
				//fprintf(error,"Line# %d: Syntax error at parameter list of function definition\n",funcdeferrorline);
				error_count++;
			}
			else {
				//fprintf(error,"Line# %d: Invalid scoping of function '%s'\n",$2->node->startLine,$2->symbolInfo->getName().c_str());
				error_count++;
			}

		} compound_statement
		{
			//fprintf(logout,"func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n");
			$$ = new Node("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement \t<Line: "+to_string($1->node->startLine)+"-"+to_string($7->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree+$3->parsetree+"parameter_list : error\t<Line: "+to_string(funcdeferrorstartline)+">\n"+$5->parsetree+$7->parsetree),$1->node->startLine,$7->endLine);
			delete $1;
			delete $2;
			delete $3;
			delete $5;
			delete $7;
		}
 		;				


parameter_list : parameter_list COMMA type_specifier ID
		{
			$4->symbolInfo->returnType = $3->symbolInfo->returnType;
			pList.push_back($4);
			//fprintf(logout,"parameter_list : parameter_list COMMA type_specifier ID\n");
			$$ = new Node("parameter_list : parameter_list COMMA type_specifier ID \t<Line: "+to_string($1->startLine)+"-"+to_string($4->node->endLine)+">\n"+addSpace($1->parsetree+$2->parsetree+$3->node->parsetree+$4->node->parsetree),$1->startLine,$4->node->endLine);
			delete $1;
			delete $2;
			delete $3;
			// $4 is used no need to free
		}
		| parameter_list COMMA type_specifier
		{
			pList.push_back($3);
			//fprintf(logout,"parameter_list : parameter_list COMMA type_specifier\n");
			$$ = new Node("parameter_list : parameter_list COMMA type_specifier \t<Line: "+to_string($1->startLine)+"-"+to_string($3->node->endLine)+">\n"+addSpace($1->parsetree+$2->parsetree+$3->node->parsetree),$1->startLine,$3->node->endLine);
			delete $1;
			delete $2;
			// $3 is used no need to free
		}
 		| type_specifier ID
		{
			clearList(pList);
			$2->symbolInfo->returnType = $1->symbolInfo->returnType;
			pList.push_back($2);
			//fprintf(logout,"parameter_list : type_specifier ID\n");
			$$ = new Node("parameter_list : type_specifier ID \t<Line: "+to_string($1->node->startLine)+"-"+to_string($2->node->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree),$1->node->startLine,$2->node->endLine);
			delete $1;
		}
		| type_specifier
		{
			clearList(pList);
			pList.push_back($1);
			//fprintf(logout,"parameter_list : type_specifier\n");
			$$ = new Node("parameter_list : type_specifier \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine);
			// $1 is used no need to free
		}
 		;

 		
compound_statement : LCURL compound_action statements RCURL
			{
				if (offset - (*$2)!=0) tempfile<<"\tADD SP, "<<offset - (*$2)<<"\n";
				offset = (*$2);
				//fprintf(logout,"compound_statement : LCURL statements RCURL\n");
				$$ = new Node("compound_statement : LCURL statements RCURL \t<Line: "+to_string($1->startLine)+"-"+to_string($4->endLine)+">\n"+addSpace($1->parsetree+$3->parsetree+$4->parsetree),$1->startLine,$4->endLine);
				delete $1;
				delete $2;
				delete $3;
				delete $4;
				//table->printAllScopeTable(logout);
				table->exitScope();
			}
 		    | LCURL compound_action RCURL
			{
				//tempfile<<"\tADD SP, "<<offset - (*$2)<<"\n";
				//offset = (*$2);
				//fprintf(logout,"compound_statement : LCURL RCURL\n");
				$$ = new Node("compound_statement : LCURL RCURL \t<Line: "+to_string($1->startLine)+"-"+to_string($3->endLine)+">\n"+addSpace($1->parsetree+$3->parsetree),$1->startLine,$3->endLine);
				delete $1;
				delete $2;
				delete $3;
				//table->printAllScopeTable(logout);
				table->exitScope();
			}
 		    ;

compound_action : 
				{
					table->enterScope();
					for (int i=0;i<pList.size();i++) {
						if (pList[i]->symbolInfo->returnType != "VOID" && pList[i]->symbolInfo->getName()!="") {
							SymbolInfo* temp = new SymbolInfo(pList[i]->symbolInfo);
							bool ok = table->insert(temp);
							if (!ok) {
								delete temp;
								//fprintf(error,"Line# %d: Redefinition of parameter '%s'\n",pList[i]->node->startLine,pList[i]->symbolInfo->getName().c_str());
								error_count++;
							}
							else {
								temp->address = "[BP+"+to_string((pList.size()+1-i)*2)+"]";
							}
						}
					}
					clearList(pList);
					$$ = new int(offset);
				}
				;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
			{
				for (int i=0;i<vList.size();i++) {
					bool isVoid = false;
					if ($1->symbolInfo->returnType=="VOID") {
						//fprintf(error,"Line# %d: Variable or field '%s' declared void\n",$1->node->startLine,vList[i]->symbolInfo->getName().c_str());
						error_count++;
						// no need to enter in scope table as per logfile
						isVoid = true;
					}
					vList[i]->symbolInfo->returnType = $1->symbolInfo->returnType;
					bool ok = false;
					if (!isVoid) {
						SymbolInfo* temp = new SymbolInfo(vList[i]->symbolInfo);
						ok = table->insert(temp);
						if (!ok) {
							delete temp;
							SymbolInfo* info = table->lookUp(vList[i]->symbolInfo->getName());
							if ((info->size<0 || vList[i]->symbolInfo->size<0) && info->size!=vList[i]->symbolInfo->size) {
								//fprintf(error,"Line# %d: '%s' redeclared as different kind of symbol\n",vList[i]->node->startLine,vList[i]->symbolInfo->getName().c_str());
								error_count++;
							}
							else if (info->returnType!=vList[i]->symbolInfo->returnType) {
								//fprintf(error,"Line# %d: Conflicting types for '%s'\n",vList[i]->node->startLine,vList[i]->symbolInfo->getName().c_str());
								error_count++;
							}
							else {
								//fprintf(error,"Line# %d: Redefinition of %s '%s'\n",vList[i]->node->startLine,(vList[i]->symbolInfo->size>=0?"array":"variable"),vList[i]->symbolInfo->getName().c_str());
								error_count++;
								// check error string
							}
						}
						else {
							if (table->getScopeNum()==1) {
								if (temp->size==-3) {
									globalVarDec += temp->getName()+" DW 0\n";
									temp->address = temp->getName();
								}
								else {
									globalVarDec += temp->getName()+" DW "+to_string(temp->size)+" DUP(0)\n";
									temp->address = temp->getName()+"[SI]";
								}
							}
							else {
								if (temp->size==-3) {
									tempfile<<"\tSUB SP, 2\n";
									offset += 2;
									temp->address = "[BP-"+to_string(offset)+"]";
								}
								else {
									tempfile<<"\tSUB SP, "<<temp->size*2<<"\n";
									offset += temp->size*2;
									temp->address = "[BP-"+to_string(offset)+"+SI]";
								}
							}
						}
					}
				}
				clearList(vList);
				//fprintf(logout,"var_declaration : type_specifier declaration_list SEMICOLON \n");
				$$ = new Node("var_declaration : type_specifier declaration_list SEMICOLON \t<Line: "+to_string($1->node->startLine)+"-"+to_string($3->endLine)+">\n"+addSpace($1->node->parsetree+$2->parsetree+$3->parsetree),$1->node->startLine,$3->endLine);
				delete $1;
				delete $2;
				delete $3;
			}
			| type_specifier error SEMICOLON
			{
				clearList(vList);
				//fprintf(error,"Line# %d: Syntax error at declaration list of variable declaration\n",errorline);
				//fprintf(logout,"var_declaration : type_specifier declaration_list SEMICOLON \n");
				$$ = new Node("var_declaration : type_specifier declaration_list SEMICOLON \t<Line: "+to_string($1->node->startLine)+"-"+to_string($3->endLine)+">\n"+addSpace($1->node->parsetree+"declaration_list : error\t<Line: "+to_string(errorstartline)+">\n"+$3->parsetree),$1->node->startLine,$3->endLine);
				errorstartline = INT_MAX;
				error_count++;
				delete $1;
				// nothing to free in error?
				delete $3;
			}
 		 ;
 		 
type_specifier	: INT
		{
			SymbolInfo *info = new SymbolInfo("","");
			info->returnType = "INT";
			//fprintf(logout,"type_specifier	: INT\n");
			$$ = new NodeSymbolInfo(new Node("type_specifier : INT \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine),info);
			delete $1;
		}
 		| FLOAT 
		{
			SymbolInfo *info = new SymbolInfo("","");
			info->returnType = "FLOAT";
			//fprintf(logout,"type_specifier	: FLOAT\n");
			$$ = new NodeSymbolInfo(new Node("type_specifier : FLOAT \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine),info);
			delete $1;
		}
 		| VOID
		{
			SymbolInfo *info = new SymbolInfo("","");
			info->returnType = "VOID";
			//fprintf(logout,"type_specifier	: VOID\n");
			$$ = new NodeSymbolInfo(new Node("type_specifier : VOID \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine),info);
			delete $1;
		}
 		;
 		
declaration_list : declaration_list COMMA ID
			{
				// pushed whole nodeSymbolInfo* to get line no for individual variable
				vList.push_back($3);
				//fprintf(logout,"declaration_list : declaration_list COMMA ID\n");
				$$ = new Node("declaration_list : declaration_list COMMA ID \t<Line: "+to_string($1->startLine)+"-"+to_string($3->node->endLine)+">\n"+addSpace($1->parsetree+$2->parsetree+$3->node->parsetree),$1->startLine,$3->node->endLine);
				delete $1;
				delete $2;
				// $3 is kept in vList so no need to free memory
			}
 		  | declaration_list COMMA ID LSQUARE CONST_INT RSQUARE
		  	{
				// pushed whole nodeSymbolInfo* to get line no for individual variable
				int size;
				sscanf($5->symbolInfo->getName().c_str(),"%d",&size);
				$3->symbolInfo->size = size;
				vList.push_back($3);
				//fprintf(logout,"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE\n");
				$$ = new Node("declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE \t<Line: "+to_string($1->startLine)+"-"+to_string($6->endLine)+">\n"+addSpace($1->parsetree+$2->parsetree+$3->node->parsetree+$4->parsetree+$5->node->parsetree+$6->parsetree),$1->startLine,$6->endLine);
				delete $1;
				delete $2;
				// $3 is kept in vList so no need to free memory
				delete $4;
				delete $5;
				delete $6;
			}
 		  | ID
		  	{
				// pushed whole nodeSymbolInfo* to get line no for individual variable
				clearList(vList);
				vList.push_back($1);
				//fprintf(logout,"declaration_list : ID\n");
				$$ = new Node("declaration_list : ID \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine);
				// $1 is kept in vList so no need to free memory
			}
 		  | ID LSQUARE CONST_INT RSQUARE
		  	{
				// pushed whole nodeSymbolInfo* to get line no for individual variable
				clearList(vList);
				int size;
				sscanf($3->symbolInfo->getName().c_str(),"%d",&size);
				$1->symbolInfo->size = size;
				vList.push_back($1);
				//fprintf(logout,"declaration_list : ID LSQUARE CONST_INT RSQUARE\n");
				$$ = new Node("declaration_list : ID LSQUARE CONST_INT RSQUARE \t<Line: "+to_string($1->node->startLine)+"-"+to_string($4->endLine)+">\n"+addSpace($1->node->parsetree+$2->parsetree+$3->node->parsetree+$4->parsetree),$1->node->startLine,$4->endLine);
				// $1 is kept in vList so no need to free memory
				delete $2;
				delete $3;
				delete $4;
			}
 		  ;
 		  
statements : statement
		{
			//fprintf(logout,"statements : statement\n");
			$$ = new Node("statements : statement \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine);
			delete $1;
		}
	   | statements statement
	   	{
			//fprintf(logout,"statements : statements statement\n");
			$$ = new Node("statements : statements statement \t<Line: "+to_string($1->startLine)+"-"+to_string($2->endLine)+">\n"+addSpace($1->parsetree+$2->parsetree),$1->startLine,$2->endLine);
			delete $1;
			delete $2;
		}
	   ;
	   
statement : var_declaration
		{
			//fprintf(logout,"statement : var_declaration\n");
			$$ = new Node("statement : var_declaration \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine);
			delete $1;
		}
	  | func_definition
	 	{
			//fprintf(logout,"statement : func_definition\n");
			$$ = new Node("statement : func_definition \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine);
			delete $1;
		}
	  | expression_statement
	  	{
			//fprintf(logout,"statement : expression_statement\n");
			$$ = new Node("statement : expression_statement \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine);
			delete $1;
		}
	  | compound_statement
	  	{
			//fprintf(logout,"statement : compound_statement\n");
			$$ = new Node("statement : compound_statement \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine);
			delete $1;
		}
	  | FOR LPAREN expression_statement foraction expression_statement forexpaction expression forexpendaction RPAREN statement
	  	{
			if (offset - (*$8)!=0) tempfile<<"\tADD SP, "<<offset - (*$8)<<"\n";
			offset = (*$8);
			tempfile<<"\tJMP L"<<(*$6)+1<<"\n";
			tempfile<<"L"<<(*$6)-1<<":\n";
			table->exitScope();
			if ($5->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$5->node->startLine);
				error_count++;
			}
			//fprintf(logout,"statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n");
			$$ = new Node("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement \t<Line: "+to_string($1->startLine)+"-"+to_string($10->endLine)+">\n"+addSpace($1->parsetree+$2->parsetree+$3->node->parsetree+$5->node->parsetree+$7->node->parsetree+$9->parsetree+$10->parsetree),$1->startLine,$10->endLine);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
			delete $5;
			delete $6;
			delete $7;
			delete $8;
			delete $9;
			delete $10;
	  	}
	  | IF LPAREN expression RPAREN action statement	%prec LOWER_THAN_ELSE
	  	{
			if (offset - ($5->offset)!=0) tempfile<<"\tADD SP, "<<offset - ($5->offset)<<"\n";
			offset = ($5->offset);
			tempfile<<"L"<<$5->label<<":\n";
			table->exitScope();
			if ($3->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$3->node->startLine);
				error_count++;
			}
			//fprintf(logout,"statement : IF LPAREN expression RPAREN statement\n");
			$$ = new Node("statement : IF LPAREN expression RPAREN statement \t<Line: "+to_string($1->startLine)+"-"+to_string($6->endLine)+">\n"+addSpace($1->parsetree+$2->parsetree+$3->node->parsetree+$4->parsetree+$6->parsetree),$1->startLine,$6->endLine);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
			delete $5;
			delete $6;
	  	}
	  | IF LPAREN expression RPAREN action statement ELSE elseaction statement
	  	{
			if (offset - ($5->offset)!=0) tempfile<<"\tADD SP, "<<offset - ($5->offset)<<"\n";
			offset = ($5->offset);
			tempfile<<"L"<<*$8<<":\n";
			table->exitScope();
			if ($3->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$3->node->startLine);
				error_count++;
			}
			//fprintf(logout,"statement : IF LPAREN expression RPAREN statement ELSE statement\n");
			$$ = new Node("statement : IF LPAREN expression RPAREN statement ELSE statement \t<Line: "+to_string($1->startLine)+"-"+to_string($9->endLine)+">\n"+addSpace($1->parsetree+$2->parsetree+$3->node->parsetree+$4->parsetree+$6->parsetree+$7->parsetree+$9->parsetree),$1->startLine,$9->endLine);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
			delete $5;
			delete $6;
			delete $7;
			delete $8;
			delete $9;
	  	}
	  | WHILE whileaction LPAREN expression RPAREN whileexpaction statement
	  	{
			if (offset - ($6->offset)!=0) tempfile<<"\tADD SP, "<<offset - ($6->offset)<<"\n";
			offset = ($6->offset);
			tempfile<<"\tJMP L"<<*$2<<"\n";
			tempfile<<"L"<<$6->label<<":\n";
			table->exitScope();
			if ($4->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$4->node->startLine);
				error_count++;
			}
			//fprintf(logout,"statement : WHILE LPAREN expression RPAREN statement\n");
			$$ = new Node("statement : WHILE LPAREN expression RPAREN statement \t<Line: "+to_string($1->startLine)+"-"+to_string($7->endLine)+">\n"+addSpace($1->parsetree+$3->parsetree+$4->node->parsetree+$5->parsetree+$7->parsetree),$1->startLine,$7->endLine);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
			delete $5;
			delete $6;
			delete $7;
	  	}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
		{
			SymbolInfo* info = table->lookUp($3->symbolInfo->getName());
			if (info==nullptr) {
				//fprintf(error,"Line# %d: Undeclared variable '%s'\n",$3->node->startLine,$3->symbolInfo->getName().c_str());
				error_count++;
			}
			else if (info->size!=-3) {
				//fprintf(error,"Line# %d: '%s' is not a variable\n",$3->node->startLine,$3->symbolInfo->getName().c_str());
				error_count++;
			}
			else {
				tempfile<<"\tPUSH "<<info->address<<"\n";
				tempfile<<"\tCALL println\n";
				tempfile<<"\tADD SP, 2\n";
			}
			//fprintf(logout,"statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n");
			$$ = new Node("statement : PRINTLN LPAREN ID RPAREN SEMICOLON \t<Line: "+to_string($1->startLine)+"-"+to_string($5->endLine)+">\n"+addSpace($1->parsetree+$2->parsetree+$3->node->parsetree+$4->parsetree+$5->parsetree),$1->startLine,$5->endLine);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
			delete $5;
		}
	  | RETURN expression SEMICOLON
	  	{
			if (offset!=0) tempfile<<"\tADD SP, "<<offset<<"\n";
			tempfile<<"\tPOP BP\n";
			if (currentfunc=="main") {
				tempfile<<"\tMOV AH, 4CH\n";
				tempfile<<"\tINT 21H\n";
			}
			else {
				tempfile<<"\tRET\n";
			}
			
			if ($2->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$2->node->startLine);
				error_count++;
			}
			/*
			if (rtype=="INT" && $2->symbolInfo->returnType=="FLOAT") {
				//fprintf(error,"Line# %d: Warning: possible loss of data in assignment of FLOAT to INT\n",$2->node->startLine);
				error_count++;
			}
			*/
			//fprintf(logout,"statement : RETURN expression SEMICOLON\n");
			$$ = new Node("statement : RETURN expression SEMICOLON \t<Line: "+to_string($1->startLine)+"-"+to_string($3->endLine)+">\n"+addSpace($1->parsetree+$2->node->parsetree+$3->parsetree),$1->startLine,$3->endLine);
			delete $1;
			delete $2;
			delete $3;
		}
	  ;

action : 
		{
			tempfile<<"\tCMP AX, 0\n";
			$$ = new LabelOffset(label_count,offset);
			tempfile<<"\tJE L"<<label_count++<<"\n";
			table->enterScope();
	  	}
		;

elseaction :
		{
			if (offset - (($<labelOffset>-2)->offset)!=0) tempfile<<"\tADD SP, "<<offset - (($<labelOffset>-2)->offset)<<"\n";
			offset = (($<labelOffset>-2)->offset);
			$$ = new int(label_count);
			tempfile<<"\tJMP L"<<label_count++<<"\n";
			table->exitScope();
			table->enterScope();
			tempfile<<"L"<<($<labelOffset>-2)->label<<":\n";
		}
		;

whileaction :
		{
			$$ = new int(label_count);
			tempfile<<"L"<<label_count++<<":\n";
		}
		;

whileexpaction :
		{
			tempfile<<"\tCMP AX, 0\n";
			$$ = new LabelOffset(label_count,offset);
			tempfile<<"\tJE L"<<label_count++<<"\n";
			table->enterScope();
		}
		;

foraction :
		{
			$$ = new int(label_count);
			tempfile<<"L"<<label_count++<<":\n";
		}
		;

forexpaction :
		{
			tempfile<<"\tCMP AX, 0\n";
			tempfile<<"\tJE L"<<label_count++<<"\n";
			$$ = new int(label_count);
			tempfile<<"\tJMP L"<<label_count++<<"\n";
			tempfile<<"L"<<label_count++<<":\n";
		}
		;

forexpendaction :
		{
			tempfile<<"\tJMP L"<<*$<label>-3<<"\n";
			tempfile<<"L"<<*$<label>-1<<":\n";
			$$ = new int(offset);
			table->enterScope();
		}
		;
	  
expression_statement : SEMICOLON	
			{
				SymbolInfo* info = new SymbolInfo("","");
				info->returnType = "INT";
				//fprintf(logout,"expression_statement : SEMICOLON\n");
				$$ = new NodeSymbolInfo(new Node("expression_statement : SEMICOLON \t<Line: "+to_string($1->startLine)+"-"+to_string($1->endLine)+">\n"+addSpace($1->parsetree),$1->startLine,$1->endLine),info);
				delete $1;
			}
			| expression SEMICOLON 
			{
				//fprintf(logout,"expression_statement : expression SEMICOLON\n");
				$$ = new NodeSymbolInfo(new Node("expression_statement : expression SEMICOLON \t<Line: "+to_string($1->node->startLine)+"-"+to_string($2->endLine)+">\n"+addSpace($1->node->parsetree+$2->parsetree),$1->node->startLine,$2->endLine),new SymbolInfo($1->symbolInfo));
				delete $1;
				delete $2;
			}
			| error SEMICOLON
			{
				SymbolInfo* info = new SymbolInfo("","");
				info->returnType = "INT";
				//fprintf(error,"Line# %d: Syntax error at expression of expression statement\n",errorline);
				//fprintf(logout,"expression_statement : expression SEMICOLON\n");
				$$ = new NodeSymbolInfo(new Node("expression_statement : expression SEMICOLON \t<Line: "+to_string(errorstartline)+"-"+to_string($2->endLine)+">\n"+addSpace("expression : error\t<Line: "+to_string(errorstartline)+">\n"+$2->parsetree),errorstartline,$2->endLine),info);
				errorstartline = INT_MAX;
				error_count++;
				delete $2;
			}
			;
	  
variable : ID 	
		{
			SymbolInfo* info = table->lookUp($1->symbolInfo->getName());
			if (info==nullptr) {
				//fprintf(error,"Line# %d: Undeclared variable '%s'\n",$1->node->startLine,$1->symbolInfo->getName().c_str());
				error_count++;
				info = new SymbolInfo($1->symbolInfo);
				info->returnType = "INT";
			}
			else if (info->size!=-3) {
				//fprintf(error,"Line# %d: '%s' is not a variable\n",$1->node->startLine,$1->symbolInfo->getName().c_str());
				error_count++;
				info = new SymbolInfo($1->symbolInfo);
				info->returnType = "INT";
			}
			else {
				// copying from symbol table
				info = new SymbolInfo(info);
			}
			//fprintf(logout,"variable : ID\n");
			$$ = new NodeSymbolInfo(new Node("variable : ID \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),info);
			delete $1;
		}
	 | ID LSQUARE expression RSQUARE
	 	{
			SymbolInfo* info = table->lookUp($1->symbolInfo->getName());
			if (info==nullptr) {
				//fprintf(error,"Line# %d: Undeclared array '%s'\n",$1->node->startLine,$1->symbolInfo->getName().c_str());
				error_count++;
				info = new SymbolInfo($1->symbolInfo);
				info->returnType = "INT";
			}
			else if (info->size<0) {
				//fprintf(error,"Line# %d: '%s' is not an array\n",$1->node->startLine,$1->symbolInfo->getName().c_str());
				error_count++;
				info = new SymbolInfo($1->symbolInfo);
				info->returnType = "INT";
			}
			else {
				//tempfile<<"\tPUSH AX\n";
				info = new SymbolInfo(info);
				//info->address[info->address.size()-1] = '+';
				//info->address += "SI]";
				//problem
			}
			// void check + subscript check
			if ($3->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$3->node->startLine);
				error_count++;
			}
			if ($3->symbolInfo->returnType!="INT") {
				//fprintf(error,"Line# %d: Array subscript is not an integer\n",$3->node->startLine);
				error_count++;
			}
			//fprintf(logout,"variable : ID LSQUARE expression RSQUARE\n");
			$$ = new NodeSymbolInfo(new Node("variable : ID LSQUARE expression RSQUARE \t<Line: "+to_string($1->node->startLine)+"-"+to_string($4->endLine)+">\n"+addSpace($1->node->parsetree+$2->parsetree+$3->node->parsetree+$4->parsetree),$1->node->startLine,$4->endLine),info);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
		}
	 ;
	 
expression : logic_expression
		{
			//fprintf(logout,"expression : logic_expression\n");
			$$ = new NodeSymbolInfo(new Node("expression : logic_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
		}
	   | variable ASSIGNOP {
			if ($1->symbolInfo->size>=0) {
				tempfile<<"\tPUSH AX\n";
			}
	   	} logic_expression
	   	{
			if ($1->symbolInfo->size>=0) {
				tempfile<<"\tPOP SI\n";
				tempfile<<"\tSHL SI, 1\n";
			}
			tempfile<<"\tMOV "<<$1->symbolInfo->address<<", AX\n";
			if ($4->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$4->node->startLine);
				error_count++;
			}
			// undeclared variable rtype int and right float ? loss error?
			if ($1->symbolInfo->returnType=="INT" && $4->symbolInfo->returnType=="FLOAT") {
				//fprintf(error,"Line# %d: Warning: possible loss of data in assignment of FLOAT to INT\n",$2->startLine);
				error_count++;
			}
			//fprintf(logout,"expression : variable ASSIGNOP logic_expression\n");
			$$ = new NodeSymbolInfo(new Node("expression : variable ASSIGNOP logic_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($4->node->endLine)+">\n"+addSpace($1->node->parsetree+$2->parsetree+$4->node->parsetree),$1->node->startLine,$4->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
			delete $2;
			delete $4;
		}
	   ;
			
logic_expression : rel_expression
		{
			//fprintf(logout,"logic_expression : rel_expression\n");
			$$ = new NodeSymbolInfo(new Node("logic_expression : rel_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
		}
		 | rel_expression LOGICOP logic_action rel_expression 
		{
			tempfile<<"\tCMP AX, 0\n";
			if ($2->symbolInfo->getName()=="&&") {
				tempfile<<"\tJE L"<<*$3<<"\n";
				tempfile<<"\tMOV AX, 1\n";
				tempfile<<"L"<<*$3<<":\n";
			}
			else if ($2->symbolInfo->getName()=="||") {
				tempfile<<"\tJNE L"<<*$3<<"\n";
				tempfile<<"\tMOV AX, 0\n";
				tempfile<<"\tJMP L"<<label_count++<<"\n";
				tempfile<<"L"<<*$3<<":\n";
				tempfile<<"\tMOV AX, 1\n";
				tempfile<<"L"<<label_count-1<<":\n";
			}
			$1->symbolInfo->setType("");
			if ($1->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$1->node->startLine);
				error_count++;
			}
			if ($4->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$4->node->startLine);
				error_count++;
			}
			// default return type int
			$1->symbolInfo->returnType = "INT";
			//fprintf(logout,"logic_expression : rel_expression LOGICOP rel_expression\n");
			$$ = new NodeSymbolInfo(new Node("logic_expression : rel_expression LOGICOP rel_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($4->node->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree+$4->node->parsetree),$1->node->startLine,$4->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
			delete $2;
			delete $3;
			delete $4;
		}
		 ;

logic_action :
			{
				$$ = new int(label_count);
				tempfile<<"\tCMP AX, 0\n";
				if (($<nodeSymbolInfo>0)->symbolInfo->getName()=="&&") {
					tempfile<<"\tJE L"<<label_count++<<"\n";
				}
				else if (($<nodeSymbolInfo>0)->symbolInfo->getName()=="||") {
					tempfile<<"\tJNE L"<<label_count++<<"\n";
				}
		 	}
			;
			
rel_expression	: simple_expression
		{
			//fprintf(logout,"rel_expression : simple_expression\n");
			$$ = new NodeSymbolInfo(new Node("rel_expression : simple_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
		}
		| simple_expression RELOP {
			tempfile<<"\tPUSH AX\n";
		} simple_expression
		{
			tempfile<<"\tMOV BX, AX\n";
			tempfile<<"\tPOP AX\n";
			tempfile<<"\tCMP AX, BX\n";
			if ($2->symbolInfo->getName()=="<") {
				tempfile<<"\tJL L"<<label_count++<<"\n";
			}
			else if ($2->symbolInfo->getName()=="<=") {
				tempfile<<"\tJLE L"<<label_count++<<"\n";
			}
			else if ($2->symbolInfo->getName()==">") {
				tempfile<<"\tJG L"<<label_count++<<"\n";
			}
			else if ($2->symbolInfo->getName()==">=") {
				tempfile<<"\tJGE L"<<label_count++<<"\n";
			}
			else if ($2->symbolInfo->getName()=="==") {
				tempfile<<"\tJE L"<<label_count++<<"\n";
			}
			else if ($2->symbolInfo->getName()=="!=") {
				tempfile<<"\tJNE L"<<label_count++<<"\n";
			}
			tempfile<<"\tMOV AX, 0\n";
			tempfile<<"\tJMP L"<<label_count++<<"\n";
			tempfile<<"L"<<label_count-2<<":\n";
			tempfile<<"\tMOV AX, 1\n";
			tempfile<<"L"<<label_count-1<<":\n";
			$1->symbolInfo->setType("");
			if ($1->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$1->node->startLine);
				error_count++;
			}
			if ($4->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$4->node->startLine);
				error_count++;
			}
			$1->symbolInfo->returnType = "INT";
			//fprintf(logout,"rel_expression : simple_expression RELOP simple_expression\n");
			$$ = new NodeSymbolInfo(new Node("rel_expression : simple_expression RELOP simple_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($4->node->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree+$4->node->parsetree),$1->node->startLine,$4->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
			delete $2;
			delete $4;
		}
		;
				
simple_expression : term
			{
				//fprintf(logout,"simple_expression : term \n");
				$$ = new NodeSymbolInfo(new Node("simple_expression : term \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
				delete $1;
			}
		  | simple_expression ADDOP {
				tempfile<<"\tPUSH AX\n";
		  	} term
		  	{
				tempfile<<"\tMOV BX, AX\n";
				tempfile<<"\tPOP AX\n";
				if ($2->symbolInfo->getName()=="+") {
					tempfile<<"\tADD AX, BX\n";
				}
				else if ($2->symbolInfo->getName()=="-") {
					tempfile<<"\tSUB AX, BX\n";
				}
				$1->symbolInfo->setType("");
				if ($1->symbolInfo->returnType=="VOID") {
					//fprintf(error,"Line# %d: Void cannot be used in expression \n",$1->node->startLine);
					error_count++;
				}
				if ($4->symbolInfo->returnType=="VOID") {
					//fprintf(error,"Line# %d: Void cannot be used in expression \n",$4->node->startLine);
					error_count++;
				}
				if ($1->symbolInfo->returnType=="FLOAT" || $4->symbolInfo->returnType=="FLOAT") {
					$1->symbolInfo->returnType = "FLOAT";
				}
				else {
					$1->symbolInfo->returnType = "INT";
				}
				//fprintf(logout,"simple_expression : simple_expression ADDOP term\n");
				$$ = new NodeSymbolInfo(new Node("simple_expression : simple_expression ADDOP term \t<Line: "+to_string($1->node->startLine)+"-"+to_string($4->node->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree+$4->node->parsetree),$1->node->startLine,$4->node->endLine),new SymbolInfo($1->symbolInfo));
				delete $1;
				delete $2;
				delete $4;
			}
		  ;
					
term :	unary_expression
		{
			//fprintf(logout,"term : unary_expression\n");
			$$ = new NodeSymbolInfo(new Node("term : unary_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
		}
     |  term MULOP {
			tempfile<<"\tPUSH AX\n";
	 	} unary_expression
	 	{
			tempfile<<"\tMOV BX, AX\n";
			tempfile<<"\tPOP AX\n";
			if ($2->symbolInfo->getName()=="*") {
				tempfile<<"\tIMUL BX\n";
			}
			else if ($2->symbolInfo->getName()=="/") {
				// convert byte to word
				tempfile<<"\tCWD\n";
				tempfile<<"\tIDIV BX\n";
			}
			else if ($2->symbolInfo->getName()=="%") {
				// convert byte to word
				tempfile<<"\tCWD\n";
				tempfile<<"\tIDIV BX\n";
				tempfile<<"\tMOV AX, DX\n";
			}
			$1->symbolInfo->setType("");
			if ($1->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$1->node->startLine);
				error_count++;
			}
			if ($4->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$4->node->startLine);
				error_count++;
			}
			// mod div check
			if ($2->symbolInfo->getName()=="%" || $2->symbolInfo->getName()=="/") {
				if ($2->symbolInfo->getName()=="%") {
					if ($1->symbolInfo->returnType!="INT" || $4->symbolInfo->returnType!="INT") {
						//fprintf(error,"Line# %d: Operands of modulus must be integers \n",$2->node->startLine);
						error_count++;
						// void check + not int check?
					}
				}
				// const float check? double error for modulus
				if ($4->symbolInfo->getType()=="CONST_INT") {
					int div;
					sscanf($4->symbolInfo->getName().c_str(),"%d",&div);
					if (div==0) {
						// check this msg 
						//fprintf(error,"Line# %d: Warning: division by zero i=0f=1Const=0\n",$4->node->startLine);
						error_count++;
					}
				}
				else if ($4->symbolInfo->getType()=="CONST_FLOAT") {
					float div;
					sscanf($4->symbolInfo->getName().c_str(),"%f",&div);
					if (div==0) {
						// check this msg 
						//fprintf(error,"Line# %d: Warning: division by zero i=0f=1Const=0\n",$4->node->startLine);
						error_count++;
					}
				}
			}
			if ($1->symbolInfo->returnType=="FLOAT" || $4->symbolInfo->returnType=="FLOAT") {
				$1->symbolInfo->returnType = "FLOAT";
			}
			else {
				$1->symbolInfo->returnType = "INT";
			}
			// int for modulus
			if ($2->symbolInfo->getName()=="%") {
				$1->symbolInfo->returnType = "INT";
			}
			//fprintf(logout,"term : term MULOP unary_expression\n");
			$$ = new NodeSymbolInfo(new Node("term : term MULOP unary_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($4->node->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree+$4->node->parsetree),$1->node->startLine,$4->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
			delete $2;
			delete $4;
		}
     ;

unary_expression : ADDOP unary_expression
		{
			if ($1->symbolInfo->getName()=="-") {
				tempfile<<"\tNEG AX\n";
			}
			//+-0
			$2->symbolInfo->setType("");
			if ($2->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$2->node->startLine);
				error_count++;
				// default type
				$2->symbolInfo->returnType = "INT";
			}
			//fprintf(logout,"unary_expression : ADDOP unary_expression\n");
			$$ = new NodeSymbolInfo(new Node("unary_expression : ADDOP unary_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($2->node->endLine)+">\n"+addSpace($1->node->parsetree+$2->node->parsetree),$1->node->startLine,$2->node->endLine),new SymbolInfo($2->symbolInfo));
			delete $1;
			delete $2;
		}
		 | NOT unary_expression
		{
			tempfile<<"\tNOT AX\n";
			$2->symbolInfo->setType("");
			if ($2->symbolInfo->returnType=="VOID") {
				//fprintf(error,"Line# %d: Void cannot be used in expression \n",$2->node->startLine);
				error_count++;
				// default type  can we not float?
				$2->symbolInfo->returnType = "INT";
			}
			//fprintf(logout,"unary_expression : NOT unary_expression\n");
			$$ = new NodeSymbolInfo(new Node("unary_expression : NOT unary_expression \t<Line: "+to_string($1->startLine)+"-"+to_string($2->node->endLine)+">\n"+addSpace($1->parsetree+$2->node->parsetree),$1->startLine,$2->node->endLine),new SymbolInfo($2->symbolInfo));
			delete $1;
			delete $2;
		}
		 | factor
		{
			//fprintf(logout,"unary_expression : factor\n");
			$$ = new NodeSymbolInfo(new Node("unary_expression : factor \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
		}
		 ;
	
factor : variable
		{
			if ($1->symbolInfo->size>=0) {
				tempfile<<"\tMOV SI, AX\n";
				tempfile<<"\tSHL SI, 1\n";
			}
			tempfile<<"\tMOV AX, "<<$1->symbolInfo->address<<"\n";
			//fprintf(logout,"factor : variable\n");
			$$ = new NodeSymbolInfo(new Node("factor : variable \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
		}
	| ID LPAREN argument_list RPAREN
		{
			SymbolInfo *info = new SymbolInfo("","");
			SymbolInfo *func = table->lookUp($1->symbolInfo->getName());
			if (func==nullptr) {
				//fprintf(error,"Line# %d: Undeclared function '%s'\n",$1->node->startLine,$1->symbolInfo->getName().c_str());
				error_count++;
				// default return type
				info->returnType = "INT";
			}
			else if (func->size<-2 || func->size>=0) {
				//fprintf(error,"Line# %d: '%s' is not a function\n",$1->node->startLine,$1->symbolInfo->getName().c_str());
				error_count++;
				// return type is that of variable or array?
				info->returnType = "INT";
			}
			else {
				tempfile<<"\tCALL "<<$1->symbolInfo->getName()<<"\n";
				if ($3->symbolInfo->parameterList.size()*2!=0) tempfile<<"\tADD SP, "<<$3->symbolInfo->parameterList.size()*2<<"\n";
				info->returnType = func->returnType;
				if ($3->symbolInfo->parameterList.size()<func->parameterList.size()) {
					//fprintf(error,"Line# %d: Too few arguments to function '%s'\n",$1->node->startLine,$1->symbolInfo->getName().c_str());
					error_count++;
				}
				else if ($3->symbolInfo->parameterList.size()>func->parameterList.size()) {
					//fprintf(error,"Line# %d: Too many arguments to function '%s'\n",$1->node->startLine,$1->symbolInfo->getName().c_str());
					error_count++;
				}
				else {
					for (int i=0;i<func->parameterList.size();i++) {
						if (func->parameterList[i]->parameterType!=$3->symbolInfo->parameterList[i]->parameterType) {
							// line number of that a function?
							//fprintf(error,"Line# %d: Type mismatch for argument %d of '%s'\n",$1->node->startLine,i+1,$1->symbolInfo->getName().c_str());
							error_count++;
						}
					}
				}
			}
			
			//fprintf(logout,"factor : ID LPAREN argument_list RPAREN\n");
			$$ = new NodeSymbolInfo(new Node("factor : ID LPAREN argument_list RPAREN \t<Line: "+to_string($1->node->startLine)+"-"+to_string($4->endLine)+">\n"+addSpace($1->node->parsetree+$2->parsetree+$3->node->parsetree+$4->parsetree),$1->node->startLine,$4->endLine),info);
			delete $1;
			delete $2;
			delete $3;
			delete $4;
		}
	| LPAREN expression RPAREN
		{
			//fprintf(logout,"factor : LPAREN expression RPAREN\n");
			$$ = new NodeSymbolInfo(new Node("factor : LPAREN expression RPAREN \t<Line: "+to_string($1->startLine)+"-"+to_string($3->endLine)+">\n"+addSpace($1->parsetree+$2->node->parsetree+$3->parsetree),$1->startLine,$3->endLine),new SymbolInfo($2->symbolInfo));
			delete $1;
			delete $2;
			delete $3;
		}
	| CONST_INT
		{
			tempfile<<"\tMOV AX, "<<$1->symbolInfo->getName()<<"\n";
			$1->symbolInfo->returnType = "INT";
			//fprintf(logout,"factor : CONST_INT\n");
			$$ = new NodeSymbolInfo(new Node("factor : CONST_INT \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
		}
	| CONST_FLOAT
		{
			$1->symbolInfo->returnType = "FLOAT";
			//fprintf(logout,"factor : CONST_FLOAT\n");
			$$ = new NodeSymbolInfo(new Node("factor : CONST_FLOAT \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
		}
	| variable INCOP 
		{
			if ($1->symbolInfo->size>=0) {
				tempfile<<"\tMOV SI, AX\n";
				tempfile<<"\tSHL SI, 1\n";
			}
			tempfile<<"\tMOV AX, "<<$1->symbolInfo->address<<"\n";
			tempfile<<"\tMOV BX, AX\n";
			tempfile<<"\tINC BX\n";
			tempfile<<"\tMOV "<<$1->symbolInfo->address<<", BX\n";
			// prev
			//tempfile<<"\tMOV AX, "<<$1->symbolInfo->address<<"\n";
			//tempfile<<"\tINC WORD PTR "<<$1->symbolInfo->address<<"\n";
			//fprintf(logout,"factor : variable INCOP\n");
			$$ = new NodeSymbolInfo(new Node("factor : variable INCOP \t<Line: "+to_string($1->node->startLine)+"-"+to_string($2->endLine)+">\n"+addSpace($1->node->parsetree+$2->parsetree),$1->node->startLine,$2->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
			delete $2;
		}
	| variable DECOP
		{
			if ($1->symbolInfo->size>=0) {
				tempfile<<"\tMOV SI, AX\n";
				tempfile<<"\tSHL SI, 1\n";
			}
			tempfile<<"\tMOV AX, "<<$1->symbolInfo->address<<"\n";
			tempfile<<"\tMOV BX, AX\n";
			tempfile<<"\tDEC BX\n";
			tempfile<<"\tMOV "<<$1->symbolInfo->address<<", BX\n";
			// prev
			//tempfile<<"\tMOV AX, "<<$1->symbolInfo->address<<"\n";
			//tempfile<<"\tDEC WORD PTR "<<$1->symbolInfo->address<<"\n";
			//fprintf(logout,"factor : variable DECOP\n");
			$$ = new NodeSymbolInfo(new Node("factor : variable DECOP \t<Line: "+to_string($1->node->startLine)+"-"+to_string($2->endLine)+">\n"+addSpace($1->node->parsetree+$2->parsetree),$1->node->startLine,$2->endLine),new SymbolInfo($1->symbolInfo));
			delete $1;
			delete $2;
		}
	;
	
argument_list : arguments
				{
					//fprintf(logout,"argument_list : arguments\n");
					$$ = new NodeSymbolInfo(new Node("argument_list : arguments \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
					delete $1;
				}
			  |
			  	{
					$$ = new NodeSymbolInfo(new Node("argument_list :\t<Line: "+to_string(yylineno)+">\n",yylineno,yylineno),new SymbolInfo("",""));
				}
			  ;
	
arguments : arguments COMMA logic_expression
			{
				tempfile<<"\tPUSH AX\n";
				$1->symbolInfo->addParameter($3->symbolInfo->returnType,"");
				//fprintf(logout,"arguments : arguments COMMA logic_expression\n");
				$$ = new NodeSymbolInfo(new Node("arguments : arguments COMMA logic_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($3->node->endLine)+">\n"+addSpace($1->node->parsetree+$2->parsetree+$3->node->parsetree),$1->node->startLine,$3->node->endLine),new SymbolInfo($1->symbolInfo));
				delete $1;
				delete $2;
				delete $3;
			}
	      | logic_expression
		  	{
				tempfile<<"\tPUSH AX\n";
				for (int i=0;i<$1->symbolInfo->parameterList.size();i++) {
					delete $1->symbolInfo->parameterList[i];
				}
				$1->symbolInfo->parameterList.clear();
				$1->symbolInfo->addParameter($1->symbolInfo->returnType,"");
				//fprintf(logout,"arguments : logic_expression\n");
				$$ = new NodeSymbolInfo(new Node("arguments : logic_expression \t<Line: "+to_string($1->node->startLine)+"-"+to_string($1->node->endLine)+">\n"+addSpace($1->node->parsetree),$1->node->startLine,$1->node->endLine),new SymbolInfo($1->symbolInfo));
				delete $1;
			}
	      ;
 

%%
int main(int argc,char *argv[])
{
	if(argc!=2) {
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	fp = fopen(argv[1],"r");
	if(fp==NULL) {
		printf("Cannot Open Input File.\n");
		return 0;
	}

	//parsetree = fopen("parsetree.txt","w");
	//logout= fopen("log.txt","w");
	//error= fopen("error.txt","w");
	// new files
	code.open("code.asm",ios::in|ios::out|ios::trunc);
	tempfile.open("optimized_code.asm",ios::in|ios::out|ios::trunc);

	yyin=fp;
	yyparse();

	//fclose(parsetree);
	//fclose(logout);
	//fclose(error);
	code.close();
	tempfile.close();
	fclose(fp);
	delete table;
	return 0;
}

