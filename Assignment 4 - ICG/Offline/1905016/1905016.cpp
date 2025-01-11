#include<string>
#include<vector>
#include<iostream>
using namespace std;

#ifndef _SYMBOL_TABLE_
#define _SYMBOL_TABLE_
class Node {
public:
	string parsetree;
	int startLine;
	int endLine;
    Node () {
		this->parsetree = "";
		this->startLine = 0;
		this->endLine = 0;
	}
	Node (string parsetree, int startLine, int endLine) {
		this->parsetree = parsetree;
		this->startLine = startLine;
		this->endLine = endLine;
	}
};
class LabelOffset {
public:
    int label;
    int offset;
    LabelOffset(int label, int offset) {
        this->label = label;
        this->offset = offset;
    }

};
class Parameter {
public:
    string parameterType;
    string parameterName;
    Parameter(string parameterType, string parameterName) {
        this->parameterType = parameterType;
        this->parameterName = parameterName;
    }
};

class SymbolInfo {
    string name;
    string type;
public:
    SymbolInfo* next;
    string returnType;
    string address;
    int size;
    vector<Parameter*> parameterList;
    SymbolInfo(string name, string type, SymbolInfo* next = nullptr) {
        this->name = name;
        this->type = type;
        this->next = next;
        this->size = -3;
        parameterList.clear();
        returnType = "";
        address = "";
    }
    SymbolInfo(SymbolInfo* info) {
        this->name = info->name;
        this->type = info->type;
        this->next = info->next;
        this->returnType = info->returnType;
        this->size = info->size;
        this->address = info->address;
        for (int i=0;i<info->parameterList.size();i++) {
            this->parameterList.push_back(new Parameter(info->parameterList[i]->parameterType,info->parameterList[i]->parameterName));
        }
    }
    ~SymbolInfo() {
        for (int i=0;i<parameterList.size();i++) {
            delete parameterList[i];
        }
        parameterList.clear();
    }
    string getName() {
        return name;
    }
    string getType() {
        return type;
    }
    void setName(string name) {
        this->name = name;
    }
    void setType(string type) {
        this->type = type;
    }

    void addParameter(string parameterType, string parameterName) {
        parameterList.push_back(new Parameter(parameterType,parameterName));
    }
    Parameter* getParameter(int index) {
        return parameterList[index];
    }

};
class NodeSymbolInfo {
public:
    Node* node;
    SymbolInfo* symbolInfo;
    NodeSymbolInfo(Node* node, SymbolInfo* symbolInfo) {
        this->node = node;
        this->symbolInfo = symbolInfo;
    }
    ~NodeSymbolInfo() {
        delete node;
        delete symbolInfo;
    }
};
class ScopeTable {
    SymbolInfo** buckets;
    int scope_num;
    int num_buckets;
    unsigned long long sdbm_hash(string str) {
        unsigned long long hash = 0;
        unsigned int i = 0;
        unsigned int len = str.length();

        for (i = 0; i < len; i++)
        {
            hash = (str[i]) + (hash << 6) + (hash << 16) - hash;
        }

        return hash;
    }
    unsigned int hash_func(string name) {
        return sdbm_hash(name)%num_buckets;
    }
public:
    ScopeTable* parent_scope;
    ScopeTable (int num_buckets, int scope_num, ScopeTable* parent_scope = nullptr) {
        this->num_buckets = num_buckets;
        this->scope_num = scope_num;
        this->parent_scope = parent_scope;
        buckets = new SymbolInfo*[num_buckets];
        for (int i=0;i<num_buckets;i++) buckets[i]=nullptr;
    }
    ~ScopeTable() {
        for (int i=0;i<num_buckets;i++) {
            SymbolInfo* symbol = buckets[i];
            SymbolInfo* temp;
            while (symbol!=nullptr) {
                temp = symbol;
                symbol = symbol->next;
                delete temp;
            }
        }
        delete [] buckets;
    }
    bool insert(SymbolInfo* info) {
        unsigned int index = hash_func(info->getName());
        int pos = 1;
        if (buckets[index]==nullptr) {
            buckets[index] = info;
            pos = 1;
        }
        else {
            SymbolInfo* curr = buckets[index];
            SymbolInfo* prev = nullptr;
            while (curr!=nullptr) {
                if (curr->getName()==info->getName()) {
                    //cout<<"\t'"<<name<<"' already exists in the current ScopeTable"<<endl;
                    //fprintf(file,"\t%s already exists in the current ScopeTable\n",name.c_str());
                    return false;
                }
                prev = curr;
                curr = curr->next;
                pos++;
            }
            prev->next = info;
        }
        //cout<<"\tInserted in ScopeTable# "<<scope_num<<" at position "<<index+1<<", "<<pos<<endl;
        return true;
    }
    bool insert(string name, string type) {
        unsigned int index = hash_func(name);
        int pos = 1;
        if (buckets[index]==nullptr) {
            buckets[index] = new SymbolInfo(name,type);
            pos = 1;
        }
        else {
            SymbolInfo* curr = buckets[index];
            SymbolInfo* prev = nullptr;
            while (curr!=nullptr) {
                if (curr->getName()==name) {
                    //cout<<"\t'"<<name<<"' already exists in the current ScopeTable"<<endl;
                    //fprintf(file,"\t%s already exists in the current ScopeTable\n",name.c_str());
                    return false;
                }
                prev = curr;
                curr = curr->next;
                pos++;
            }
            prev->next = new SymbolInfo(name,type);
        }
        //cout<<"\tInserted in ScopeTable# "<<scope_num<<" at position "<<index+1<<", "<<pos<<endl;
        return true;
    }
    SymbolInfo* lookUp(string name) {
        unsigned int index = hash_func(name);
        SymbolInfo* temp = buckets[index];
        SymbolInfo* ans = nullptr;
        int pos = 1;
        while (temp!=nullptr) {
            if (temp->getName()==name) {
                ans = temp;
                break;
            }
            temp = temp->next;
            pos++;
        }
        if (ans!=nullptr) {
            //cout<<"\t'"<<name<<"' found in ScopeTable# "<<scope_num<<" at position "<<index+1<<", "<<pos<<endl;
        }
        return ans;
    }
    bool remove(string name) {
        bool ans = false;
        unsigned int index = hash_func(name);
        SymbolInfo* curr = buckets[index];
        SymbolInfo* prev = nullptr;
        int pos = 1;
        while (curr!=nullptr) {
            if (curr->getName()==name) {
                break;
            }
            prev = curr;
            curr = curr->next;
            pos++;
        }
        if (curr==nullptr) {
            ans = false;
            //cout<<"\tNot found in the current ScopeTable"<<endl;
        }
        else if (curr==buckets[index]) {
            ans = true;
            buckets[index] = buckets[index]->next;
            delete curr;
            //cout<<"\tDeleted '"<<name<<"' from ScopeTable# "<<scope_num<<" at position "<<index+1<<", "<<pos<<endl;
        }
        else {
            ans = true;
            prev->next = curr->next;
            delete curr;
            //cout<<"\tDeleted '"<<name<<"' from ScopeTable# "<<scope_num<<" at position "<<index+1<<", "<<pos<<endl;
        }
        return ans;
    }

    void print(FILE* file) {
        //cout<<"\tScopeTable# "<<scope_num<<endl;
        fprintf(file,"\tScopeTable# %d\n",scope_num);
        for (int i=0;i<num_buckets;i++) {
            SymbolInfo* temp = buckets[i];
            if (buckets[i]!=nullptr) {
                //cout<<"\t"<<i+1<<"--> ";
                fprintf(file,"\t%d--> ",i+1);
            }
            while (temp!=nullptr) {
                //cout<<"<"<<temp->getName()<<","<<temp->getType()<<"> ";
                if (temp->size==-1 || temp->size==-2) {
                    fprintf(file,"<%s, %s, %s> ",temp->getName().c_str(),"FUNCTION",temp->returnType.c_str());
                    /*
                    for (int i=0;i<temp->parameterList.size();i++) {
                        fprintf(file,"<%s,%s> ",temp->parameterList[i]->parameterType.c_str(),temp->parameterList[i]->parameterName.c_str());
                    }
                    fprintf(file,")> ");
                    */
                }
                else if (temp->size>=0) {
                    fprintf(file,"<%s, %s, %s> ",temp->getName().c_str(),"ARRAY",temp->returnType.c_str());
                }
                else if (temp->size==-3) {
                    fprintf(file,"<%s, %s> ",temp->getName().c_str(),temp->returnType.c_str());
                }
                //fprintf(file,"<%s,%s> ",temp->getName().c_str(),temp->getType().c_str());
                temp = temp->next;
            }
            if (buckets[i]!=nullptr) {
                fprintf(file,"\n");
                //cout<<endl;
            }
        }
    }
    int getScope_num() {
        return scope_num;
    }
};

class SymbolTable {
    ScopeTable* currentScopeTable;
    int scopeNum;
    int num_buckets;
public:
    SymbolTable(int num_buckets) {
        this->num_buckets = num_buckets;
        scopeNum = 1;
        currentScopeTable = nullptr;
        enterScope();
    }
    ~SymbolTable() {
        ScopeTable* temp;
        while(currentScopeTable!=nullptr) {
            temp = currentScopeTable;
            //cout<<"\tScopeTable# "<<currentScopeTable->getScope_num()<<" removed"<<endl;
            currentScopeTable = currentScopeTable->parent_scope;
            delete temp;
        }
    }
    int getScopeNum() {
        return currentScopeTable->getScope_num();
    }
    void enterScope() {
        currentScopeTable = new ScopeTable(num_buckets,scopeNum,currentScopeTable);
        //cout<<"\tScopeTable# "<<scopeNum<<" created"<<endl;
        scopeNum++;
    }
    void exitScope() {
        ScopeTable* temp = currentScopeTable;
        if (currentScopeTable->parent_scope==nullptr) {
            //cout<<"\tScopeTable# "<<temp->getScope_num()<<" cannot be removed"<<endl;
            return;
        }
        currentScopeTable = currentScopeTable->parent_scope;
        //cout<<"\tScopeTable# "<<temp->getScope_num()<<" removed"<<endl;
        delete temp;
    }
    bool insert(SymbolInfo* info) {
        return currentScopeTable->insert(info);
    }
    bool insert(string name, string type) {
        return currentScopeTable->insert(name,type);
    }
    bool remove(string name) {
        return currentScopeTable->remove(name);
    }
    SymbolInfo* lookUp(string name) {
        SymbolInfo* ans = nullptr;
        ScopeTable* table = currentScopeTable;
        while (table!=nullptr) {
            ans = table->lookUp(name);
            if (ans!=nullptr) break;
            table = table->parent_scope;
        }
        if (ans==nullptr) {
            //cout<<"\t'"<<name<<"' not found in any of the ScopeTables"<<endl;
        }
        return ans;
    }
    void printCurrentScopeTable(FILE* file) {
        currentScopeTable->print(file);
    }
    void printAllScopeTable(FILE* file) {
        ScopeTable* table = currentScopeTable;
        while (table!=nullptr) {
            table->print(file);
            table = table->parent_scope;
        }
    }
};

#endif