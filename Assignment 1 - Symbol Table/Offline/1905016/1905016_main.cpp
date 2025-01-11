#include<iostream>
#include<string>
#include<fstream>
using namespace std;

class SymbolInfo {
    string name;
    string type;
public:
    SymbolInfo* next;
    SymbolInfo(string name, string type, SymbolInfo* next = nullptr) {
        this->name = name;
        this->type = type;
        this->next = next;
    }
    ~SymbolInfo() {
        //no dynamically allocated memory to release
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
                    cout<<"\t'"<<name<<"' already exists in the current ScopeTable"<<endl;
                    return false;
                }
                prev = curr;
                curr = curr->next;
                pos++;
            }
            prev->next = new SymbolInfo(name,type);
        }
        cout<<"\tInserted in ScopeTable# "<<scope_num<<" at position "<<index+1<<", "<<pos<<endl;
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
            cout<<"\t'"<<name<<"' found in ScopeTable# "<<scope_num<<" at position "<<index+1<<", "<<pos<<endl;
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
            cout<<"\tNot found in the current ScopeTable"<<endl;
        }
        else if (curr==buckets[index]) {
            ans = true;
            buckets[index] = buckets[index]->next;
            delete curr;
            cout<<"\tDeleted '"<<name<<"' from ScopeTable# "<<scope_num<<" at position "<<index+1<<", "<<pos<<endl;
        }
        else {
            ans = true;
            prev->next = curr->next;
            delete curr;
            cout<<"\tDeleted '"<<name<<"' from ScopeTable# "<<scope_num<<" at position "<<index+1<<", "<<pos<<endl;
        }
        return ans;
    }

    void print() {
        cout<<"\tScopeTable# "<<scope_num<<endl;
        for (int i=0;i<num_buckets;i++) {
            cout<<"\t"<<i+1<<"--> ";
            SymbolInfo* temp = buckets[i];
            while (temp!=nullptr) {
                cout<<"<"<<temp->getName()<<","<<temp->getType()<<"> ";
                temp = temp->next;
            }
            cout<<endl;
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
            cout<<"\tScopeTable# "<<currentScopeTable->getScope_num()<<" removed"<<endl;
            currentScopeTable = currentScopeTable->parent_scope;
            delete temp;
        }
    }
    void enterScope() {
        currentScopeTable = new ScopeTable(num_buckets,scopeNum,currentScopeTable);
        cout<<"\tScopeTable# "<<scopeNum<<" created"<<endl;
        scopeNum++;
    }
    void exitScope() {
        ScopeTable* temp = currentScopeTable;
        if (currentScopeTable->parent_scope==nullptr) {
            cout<<"\tScopeTable# "<<temp->getScope_num()<<" cannot be removed"<<endl;
            return;
        }
        currentScopeTable = currentScopeTable->parent_scope;
        cout<<"\tScopeTable# "<<temp->getScope_num()<<" removed"<<endl;
        delete temp;
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
            cout<<"\t'"<<name<<"' not found in any of the ScopeTables"<<endl;
        }
        return ans;
    }
    void printCurrentScopeTable() {
        currentScopeTable->print();
    }
    void printAllScopeTable() {
        ScopeTable* table = currentScopeTable;
        while (table!=nullptr) {
            table->print();
            table = table->parent_scope;
        }
    }
};

int main ()
{
    ifstream in("input.txt");
    ofstream out("output.txt");
    cout.rdbuf(out.rdbuf());
    cin.rdbuf(in.rdbuf());
    int n;
    cin>>n;
    SymbolTable* st = new SymbolTable(n);
    string command;
    string s;
    getline(cin,s);
    int i = 1;
    while (true) {
        getline(cin,s);
        cout<<"Cmd "<<i<<": "<<s<<endl;
        int pos = 0;
        //while (s.find(" ",pos)==pos) pos++;
        command = s.substr(pos,s.find(" ",pos)-pos);
        if (command=="I") {
            string name,type;
            if (s.find(" ",pos)!=string::npos) {
                pos = s.find(" ",pos)+1;
                while (s.find(" ",pos)==pos) pos++;
                if (pos<s.size()) {
                    name = s.substr(pos,s.find(" ",pos)-pos);
                    if (s.find(" ",pos)!=string::npos) {
                        pos = s.find(" ",pos)+1;
                        while (s.find(" ",pos)==pos) pos++;
                        if (pos<s.size()) {
                            type = s.substr(pos,s.find(" ",pos)-pos);
                            if (s.find(" ",pos)!=string::npos) {
                                pos = s.find(" ",pos)+1;
                                while (s.find(" ",pos)==pos) pos++;
                                if (pos<s.size()) {
                                    cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                                }
                                else {
                                    st->insert(name,type);
                                }
                            }
                            else {
                                st->insert(name,type);
                            }
                        }
                        else {
                            cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                        }

                    }
                    else {
                        cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                    }
                }
                else {
                    cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                }
            }
            else {
                cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
            }
        }
        else if (command=="L") {
            string name;
            if (s.find(" ",pos)!=string::npos) {
                pos = s.find(" ",pos)+1;
                while (s.find(" ",pos)==pos) pos++;
                if (pos<s.size()) {
                    name = s.substr(pos,s.find(" ",pos)-pos);
                    if (s.find(" ",pos)!=string::npos) {
                        pos = s.find(" ",pos)+1;
                        while (s.find(" ",pos)==pos) pos++;
                        if (pos<s.size()) {
                            cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                        }
                        else {
                            st->lookUp(name);
                        }
                    }
                    else {
                        st->lookUp(name);
                    }
                }
                else {
                    cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                }

            }
            else {
                cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
            }
        }
        else if (command=="D") {
            string name;
            if (s.find(" ",pos)!=string::npos) {
                pos = s.find(" ",pos)+1;
                while (s.find(" ",pos)==pos) pos++;
                if (pos<s.size()) {
                    name = s.substr(pos,s.find(" ",pos)-pos);
                    if (s.find(" ",pos)!=string::npos) {
                        pos = s.find(" ",pos)+1;
                        while (s.find(" ",pos)==pos) pos++;
                        if (pos<s.size()) {
                            cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                        }
                        else {
                            st->remove(name);
                        }
                    }
                    else {
                        st->remove(name);
                    }
                }
                else {
                    cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                }

            }
            else {
                cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
            }
        }
        else if (command=="P") {
            string subcommand;
            if (s.find(" ",pos)!=string::npos) {
                pos = s.find(" ",pos)+1;
                while (s.find(" ",pos)==pos) pos++;
                if (pos<s.size()) {
                    subcommand = s.substr(pos,s.find(" ",pos)-pos);
                    if (s.find(" ",pos)!=string::npos) {
                        pos = s.find(" ",pos)+1;
                        while (s.find(" ",pos)==pos) pos++;
                        if (pos<s.size()) {
                            cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                        }
                        else {
                            if (subcommand=="A") {
                                st->printAllScopeTable();
                            }
                            else if (subcommand=="C") {
                                st->printCurrentScopeTable();
                            }
                        }
                    }
                    else {
                        if (subcommand=="A") {
                            st->printAllScopeTable();
                        }
                        else if (subcommand=="C") {
                            st->printCurrentScopeTable();
                        }
                    }
                }
                else {
                    cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                }

            }
            else {
                cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
            }
        }
        else if (command=="S") {
            if (s.find(" ",pos)!=string::npos) {
                pos = s.find(" ",pos)+1;
                while (s.find(" ",pos)==pos) pos++;
                if (pos<s.size()) {
                    cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                }
                else {
                    st->enterScope();
                }
            }
            else {
                st->enterScope();
            }
        }
        else if (command=="E") {
            if (s.find(" ",pos)!=string::npos) {
                pos = s.find(" ",pos)+1;
                while (s.find(" ",pos)==pos) pos++;
                if (pos<s.size()) {
                    cout<<"\tNumber of parameters mismatch for the command "<<command<<endl;
                }
                else {
                    st->exitScope();
                }
            }
            else {
                st->exitScope();
            }
        }
        else if (command=="Q") {
            delete st;
            break;
        }
        i++;
    }
    in.close();
    out.close();
    return 0;
}
