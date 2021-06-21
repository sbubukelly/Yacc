/*	Definition section */
%{
    #include "common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    struct Node {
        char *name;
        char *type;
        int address;
        int lineno;
        char *elementType;
        struct Node *next;
    };

    struct Node *table[30] = { NULL };
    int Scope = 0;
    int AddressNum = 0;
    char *elementType = NULL;
    char typeChange;
    int assignAble = 1,assigned = 1;
    
    /* Symbol table function - you can add new function if needed. */
    static void create_symbol();
    static void insert_symbol(char *name, char *type, char *elementType);
    static struct Node* lookup_symbol(char *name);
    static void dump_symbol();

%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    /* ... */
}

/* Token without return */
%token VAR SEMICOLON
%token INT FLOAT BOOL STRING 
%token INC DEC GEQ LEQ EQL NEQ 
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token AND OR
%token PRINT PRINTLN
%token IF ELSE FOR WHILE
%token TRUE FALSE

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <*s_val> ID

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type TypeName INT FLOAT STRING BOOL
%type <s_val> Expr ExprAdd ExprAnd ExprCompare ExprMul ExprUnary Assignment
%type <s_val> PrintExpr Literal IncDecExpr Operand Primary Array ChangeType
// %type <s_val> While Block If If_block ElseIf_block Else_block For ForClause

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : StatementList     { dump_symbol(); }
;

StatementList
    : StatementList Statement
    | Statement
;

Statement
    : DeclarationStmt SEMICOLON     
    | Expr SEMICOLON     
    | IncDecExpr SEMICOLON     
    | PrintExpr SEMICOLON     
    | Assignment SEMICOLON    
    | Block  
    | While  
    | If  
    | For 
;

Assignment 
    : AssignedExpr '=' Expr  {  if(assigned == 0){
                                    printf("error:%d: cannot assign to %s\n",yylineno,$<s_val>1);
                                    assigned = 1;
                                }
                                if(strcmp($<s_val>1, $<s_val>3) != 0){
                                    if(strcmp($<s_val>1, "none") != 0 && strcmp($<s_val>3, "none") != 0){
                                        printf("error:%d: invalid operation: ASSIGN (mismatched types %s and %s)\n",yylineno,$<s_val>1,$<s_val>3);
                                    }
                                }
                                printf("ASSIGN\n"); $$ = $<s_val>1;}
    | AssignedExpr ADD_ASSIGN Expr  {   if(assigned == 0){
                                            printf("error:%d: cannot assign to %s\n",yylineno,$<s_val>1);
                                            assigned = 1;
                                        }
                                        if(strcmp($<s_val>1, $<s_val>3) != 0){
                                            if(strcmp($<s_val>1, "none") != 0 && strcmp($<s_val>3, "none") != 0){
                                                printf("error:%d: invalid operation: ADD_ASSIGN (mismatched types %s and %s)\n",yylineno,$<s_val>1,$<s_val>3);
                                            }
                                        }
                                        printf("ADD_ASSIGN\n"); $$ = $<s_val>1;
                                    }
    | AssignedExpr SUB_ASSIGN Expr  {   if(assigned == 0){
                                            printf("error:%d: cannot assign to %s\n",yylineno,$<s_val>1);
                                            assigned = 1;
                                        }
                                        if(strcmp($<s_val>1, $<s_val>3) != 0){
                                            if(strcmp($<s_val>1, "none") != 0 && strcmp($<s_val>3, "none") != 0){
                                                printf("error:%d: invalid operation: SUB_ASSIGN (mismatched types %s and %s)\n",yylineno,$<s_val>1,$<s_val>3);
                                            }
                                        }
                                        printf("SUB_ASSIGN\n"); $$ = $<s_val>1;
                                    }
    | AssignedExpr MUL_ASSIGN Expr  {   if(assigned == 0){
                                            printf("error:%d: cannot assign to %s\n",yylineno,$<s_val>1);
                                            assigned = 1;
                                        }
                                        if(strcmp($<s_val>1, $<s_val>3) != 0){
                                            if(strcmp($<s_val>1, "none") != 0 && strcmp($<s_val>3, "none") != 0){
                                                printf("error:%d: invalid operation: MUL_ASSIGN (mismatched types %s and %s)\n",yylineno,$<s_val>1,$<s_val>3);
                                            }
                                        }
                                        printf("MUL_ASSIGN\n"); $$ = $<s_val>1;
                                    }
    | AssignedExpr QUO_ASSIGN Expr  {   if(assigned == 0){
                                            printf("error:%d: cannot assign to %s\n",yylineno,$<s_val>1);
                                            assigned = 1;
                                        }
                                        if(strcmp($<s_val>1, $<s_val>3) != 0){
                                            if(strcmp($<s_val>1, "none") != 0 && strcmp($<s_val>3, "none") != 0){
                                                printf("error:%d: invalid operation: QUO_ASSIGN (mismatched types %s and %s)\n",yylineno,$<s_val>1,$<s_val>3);
                                            }
                                        }
                                        printf("QUO_ASSIGN\n"); $$ = $<s_val>1;
                                    }
    | AssignedExpr REM_ASSIGN Expr  {   if(assigned == 0){
                                            printf("error:%d: cannot assign to %s\n",yylineno,$<s_val>1);
                                            assigned = 1;
                                        }
                                        if(strcmp($<s_val>1, $<s_val>3) != 0){
                                            if(strcmp($<s_val>1, "none") != 0 && strcmp($<s_val>3, "none") != 0){
                                                printf("error:%d: invalid operation: REM_ASSIGN (mismatched types %s and %s)\n",yylineno,$<s_val>1,$<s_val>3);
                                            }
                                        }
                                        printf("REM_ASSIGN\n"); $$ = $<s_val>1;
                                    }
;

AssignedExpr
    : Expr {if(assignAble == 0){assigned = 0;}}

DeclarationStmt
    : Type ID                   {insert_symbol($<s_val>2, $<s_val>1, "-");}
    | Type ID '=' Expr          {insert_symbol($<s_val>2, $<s_val>1, "-");}
    | Type ID '[' Expr ']'      {insert_symbol($<s_val>2,"array", $<s_val>1);assignAble = 1;}
    | Type ID '[' Expr ']' '=' Expr     {insert_symbol($<s_val>2,"array", $<s_val>1);assignAble = 1;}
;


Type
    : TypeName {$$=$1;}
;

TypeName
    : INT {$$="int";}
    | FLOAT {$$="float";}
    | STRING {$$="string";}
    | BOOL {$$="bool";}
;

IncDecExpr
    : Expr INC       { printf("INC\n");assignAble = 0; $$=$1;}
    | Expr DEC       { printf("DEC\n");assignAble = 0; $$=$1;}
;

PrintExpr
    : PRINT '(' Expr ')'    { printf("PRINT %s\n", $<s_val>3); }
;

Expr
    : Expr OR ExprAnd    {  if(strcmp($<s_val>1,"bool") != 0){
                                printf("error:%d: invalid operation: (operator OR not defined on %s)\n",yylineno,$<s_val>1);
                            }
                            else if(strcmp($<s_val>3,"bool") != 0){
                                printf("error:%d: invalid operation: (operator OR not defined on %s)\n",yylineno,$<s_val>3);
                            }
                            printf("OR\n"); assignAble = 0;$$ = "bool";}
    | ExprAnd {$$=$1;}
;

ExprAnd
    : ExprAnd AND ExprCompare   {   if(strcmp($<s_val>1,"bool") != 0){
                                        printf("error:%d: invalid operation: (operator AND not defined on %s)\n",yylineno,$<s_val>1);
                                    }
                                    else if(strcmp($<s_val>3,"bool") != 0){
                                        printf("error:%d: invalid operation: (operator AND not defined on %s)\n",yylineno,$<s_val>3);
                                    }
                                    printf("AND\n");assignAble = 0; $$ = "bool";}
    | ExprCompare {$$=$1;}
;

ExprCompare
    : ExprCompare '<' ExprAdd        { printf("LSS\n");assignAble = 0; $$ = "bool"; }
    | ExprCompare '>' ExprAdd        { printf("GTR\n");assignAble = 0; $$ = "bool";   }
    | ExprCompare GEQ ExprAdd        { printf("GEQ\n");assignAble = 0; $$ = "bool";  }
    | ExprCompare LEQ ExprAdd        { printf("LEQ\n");assignAble = 0; $$ = "bool";  }
    | ExprCompare EQL ExprAdd        { printf("EQL\n");assignAble = 0; $$ = "bool";  }
    | ExprCompare NEQ ExprAdd        { printf("NEQ\n");assignAble = 0; $$ = "bool";  }
    | ExprAdd {$$=$1;}
;

ExprAdd
    : ExprAdd '+' ExprMul     { if(strcmp($<s_val>1, $<s_val>3) != 0){
                                    if(strcmp($<s_val>1, "none") != 0 && strcmp($<s_val>3, "none") != 0){
                                        printf("error:%d: invalid operation: ADD (mismatched types %s and %s)\n",yylineno,$<s_val>1,$<s_val>3);
                                    }
                                }
                                printf("ADD\n");assignAble = 0;$$ =  $<s_val>1;}
    | ExprAdd '-' ExprMul     { if(strcmp($<s_val>1, $<s_val>3) != 0){
                                    if(strcmp($<s_val>1, "none") != 0 && strcmp($<s_val>3, "none") != 0){
                                        printf("error:%d: invalid operation: SUB (mismatched types %s and %s)\n",yylineno,$<s_val>1,$<s_val>3);
                                    }
                                }
                                printf("SUB\n");assignAble = 0;$$ =  $<s_val>1;}   
    | ExprMul {$$=$1;}               
;

ExprMul
    : ExprMul '*' ExprUnary         {printf("MUL\n");assignAble = 0; $$ = $<s_val>1;}
    | ExprMul '/' ExprUnary         {printf("QUO\n");assignAble = 0; $$ = $<s_val>1;}
    | ExprMul '%' ExprUnary         {   if(strcmp($<s_val>1,"int") != 0){
                                            printf("error:%d: invalid operation: (operator REM not defined on %s)\n",yylineno,$<s_val>1);
                                        }
                                        else if(strcmp($<s_val>3,"int") != 0){
                                            printf("error:%d: invalid operation: (operator REM not defined on %s)\n",yylineno,$<s_val>3);
                                        }
                                        printf("REM\n");assignAble = 0; $$ = $<s_val>1;}
    |ExprUnary {$$=$1;}
;

ExprUnary
    : '+' ExprUnary                   { printf("POS\n");assignAble = 0; $$ = $<s_val>2; }
    | '-' ExprUnary                   { printf("NEG\n");assignAble = 0; $$ = $<s_val>2; }
    | '!' ExprUnary                   { printf("NOT\n");assignAble = 0; $$ = $<s_val>2; }
    | Primary {$$=$1;}

Primary
    : Operand { $$=$1;}
    | Array { $$=$1;}
    | ChangeType {$$=$1;}
;

Array
    : Operand '[' Expr ']'      { $$ = elementType; assignAble = 1; }
;

ChangeType
    : '(' Type ')' Expr    {   if(strcmp($<s_val>4, "int") == 0) typeChange = 'I';
                                else{typeChange = 'F';}
                                printf("%c to ",typeChange);
                                if(strcmp($<s_val>2, "int") == 0) typeChange = 'I';
                                else{typeChange = 'F';}
                                printf("%c\n",typeChange);
                                $$ = $2;
                            }
;
Operand 
    : ID    {   struct Node *id = lookup_symbol($<s_val>1);
                if(id != NULL){
                    printf("IDENT (name=%s, address=%d)\n", id->name, id->address);
                    $$ = id->type;
                    if (strcmp($$, "array") == 0)
                        elementType = id->elementType;
                        assignAble = 1;
                }
                else{
                    $$ = "none";
                }
                
            }
    | Literal    { $$ = $<s_val>1; assignAble = 0;}
    | '(' Expr ')'    { $$ = $<s_val>2; }
;

Literal
    : INT_LIT                   { printf("INT_LIT %d\n", $<i_val>1); $$ = "int"; }
    | FLOAT_LIT                 { printf("FLOAT_LIT %.6f\n", $<f_val>1); $$ = "float"; }
    | '\"' STRING_LIT '\"'      { printf("STRING_LIT %s\n", $<s_val>2); $$ = "string"; }
    | TRUE                      { printf("TRUE\n"); $$ = "bool"; }
    | FALSE                     { printf("FALSE\n"); $$ = "bool"; }
;

While
    : WHILE '(' Expr ')'    {   if(strcmp($<s_val>3, "bool") != 0){
                                    printf("error:%d: non-bool (type %s) used as for condition\n",yylineno + 1,$<s_val>3);
                                }
                            } Block      
;

If
    : IF  '(' Expr ')' {    if(strcmp($<s_val>3, "bool") != 0){
                                    printf("error:%d: non-bool (type %s) used as for condition\n",yylineno + 1,$<s_val>3);
                            }
                        } If_block
;

If_block
    : Block     
    | Block ELSE Block
    | Block ELSE If
;


For
    :FOR '(' ForClause ')' Block

;

ForClause
    : Assignment SEMICOLON Expr SEMICOLON IncDecExpr

Block
    : '{'{ create_symbol(); } StatementList '}'        { dump_symbol(); }
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yyparse();

	printf("Total lines: %d\n", yylineno-1);
    fclose(yyin);
    return 0;
}


static void create_symbol() {
    Scope++;
}

static void insert_symbol(char *name, char *type, char *elementType) {
    struct Node *current = table[Scope];
    int exist = false;
    while (current != NULL)
    {
        if (strcmp(current->name, name) == 0){
            exist = true;
            break;
        }
        current = current->next;
    }
    if(exist){
        printf("error:%d: %s redeclared in this block. previous declaration at line %d\n",yylineno,name,current->lineno);
        return;
    }

    struct Node* new_node = (struct Node*) malloc(sizeof(struct Node));
    new_node->name = name;
    new_node->type = type;
    new_node->elementType = elementType;
    new_node->address = AddressNum++;
    new_node->lineno = yylineno;
    new_node->next = NULL;

    if(table[Scope] == NULL)
        table[Scope] = new_node;
    else {
        struct Node *current = table[Scope];
        while (current->next != NULL)
        {
            current = current->next;
        }
        current->next = new_node;
    }
    
    printf("> Insert {%s} into symbol table (scope level: %d)\n", name, Scope);
}

static struct Node* lookup_symbol(char *name) {
    int cur = Scope;
    for(int i = cur;i >= 0;i --){
        struct Node *node = table[i];
        while(node != NULL){
            if (strcmp(node->name, name) == 0)
                return node;
            node = node->next;
        }
    }
    printf("error:%d: undefined: %s\n",yylineno,name);
    return NULL;
}

static void dump_symbol() {

    printf("> Dump symbol table (scope level: %d)\n", Scope);
    printf("%-10s%-10s%-10s%-10s%-10s%s\n", "Index", "Name", "Type", "Address", "Lineno",
    "Element type");
    int index = 0;
    struct Node *node = table[Scope];
    while (node != NULL) {
        printf("%-10d%-10s%-10s%-10d%-10d%s\n",index++, node->name, node->type, node->address, node->lineno, node->elementType);
        struct Node *tmp = node;
        node = node->next;
        free(tmp);
    }
    table[Scope--] = NULL;
    
}
 