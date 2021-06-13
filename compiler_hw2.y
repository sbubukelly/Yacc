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
%token NEWLINE
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
    : DeclarationStmt SEMICOLON  NEWLINE           
    | Expr SEMICOLON  NEWLINE 
    | IncDecExpr SEMICOLON  NEWLINE
    | PrintExpr SEMICOLON NEWLINE 
    | Assignment SEMICOLON NEWLINE 
    | Block NEWLINE 
    | While NEWLINE
    | If NEWLINE
    | For 
    | NEWLINE
;

Assignment 
    :  Expr '=' Expr  {printf("ASSIGN\n"); $$ = $<s_val>1;}
    | Expr ADD_ASSIGN Expr  {printf("ADD_ASSIGN\n"); $$ = $<s_val>1;}
    | Expr SUB_ASSIGN Expr  {printf("SUB_ASSIGN\n"); $$ = $<s_val>1;}
    | Expr MUL_ASSIGN Expr  {printf("MUL_ASSIGN\n"); $$ = $<s_val>1;}
    | Expr QUO_ASSIGN Expr  {printf("QUO_ASSIGN\n"); $$ = $<s_val>1;}
    | Expr REM_ASSIGN Expr  {printf("REM_ASSIGN\n"); $$ = $<s_val>1;}
                        

;

DeclarationStmt
    : Type ID                  {insert_symbol($<s_val>2, $<s_val>1, "-");}
    | Type ID '=' Expr          {insert_symbol($<s_val>2, $<s_val>1, "-");}
    | Type ID '[' Expr ']'      {insert_symbol($<s_val>2,"array", $<s_val>1);}
    | Type ID '[' Expr ']' '=' Expr     {insert_symbol($<s_val>2,"array", $<s_val>1);}
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
    : Expr INC       { printf("INC\n"); $$=$1; }
    | Expr DEC       { printf("DEC\n"); $$=$1;}
;

PrintExpr
    : PRINT '(' Expr ')'    { printf("PRINT %s\n", $<s_val>3); }
;

Expr
    : Expr OR ExprAnd    { printf("OR\n"); $$ = "bool";}
    | ExprAnd {$$=$1;}
;

ExprAnd
    : ExprAnd AND ExprCompare   { printf("AND\n"); $$ = "bool";}
    | ExprCompare {$$=$1;}
;

ExprCompare
    : ExprCompare '<' ExprAdd        { printf("LSS\n"); $$ = "bool";  }
    | ExprCompare '>' ExprAdd        { printf("GTR\n"); $$ = "bool";  }
    | ExprCompare GEQ ExprAdd        { printf("GEQ\n"); $$ = "bool";  }
    | ExprCompare LEQ ExprAdd        { printf("LEQ\n"); $$ = "bool";  }
    | ExprCompare EQL ExprAdd        { printf("EQL\n"); $$ = "bool";  }
    | ExprCompare NEQ ExprAdd        { printf("NEQ\n"); $$ = "bool";  }
    | ExprAdd {$$=$1;}
;

ExprAdd
    : ExprAdd '+' ExprMul     {printf("ADD\n");$$ =  $<s_val>1;}
    | ExprAdd '-' ExprMul     {printf("SUB\n");$$ =  $<s_val>1;}   
    | ExprMul {$$=$1;}               
;

ExprMul
    : ExprMul '*' ExprUnary         {printf("MUL\n"); $$ = $<s_val>1;}
    | ExprMul '/' ExprUnary         {printf("QUO\n"); $$ = $<s_val>1;}
    | ExprMul '%' ExprUnary         {printf("REM\n"); $$ = $<s_val>1;}
    |ExprUnary {$$=$1;}
;

ExprUnary
    : '+' ExprUnary                   { printf("POS\n"); $$ = $<s_val>2; }
    | '-' ExprUnary                   { printf("NEG\n"); $$ = $<s_val>2; }
    | '!' ExprUnary                   { printf("NOT\n"); $$ = $<s_val>2; }
    | Primary {$$=$1;}

Primary
    : Operand { $$=$1;}
    | Array { $$=$1;}
    | ChangeType {$$=$2;}
;

Array
    : Operand '[' Expr ']'      { $$ = elementType; }
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
                }
                else{
                    $$ = "none";
                }
                
            }
    |Literal    { $$ = $<s_val>1; }
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
    : WHILE '(' Expr ')' Block
;

If
    : If_block
    | Else_block
    | ElseIf_block
;

If_block
    : IF  '(' Expr ')' Block
    | IF  '(' Expr ')' Else_block
    | IF  '(' Expr ')' Block ElseIf_block
;

ElseIf_block
    : ELSE If_block
    | ELSE IF '(' Expr ')' NEWLINE Block Else_block
;

Else_block
    : ELSE Block
;

For
    :FOR '(' ForClause ')' Block

;

ForClause
    : Assignment SEMICOLON Expr SEMICOLON IncDecExpr

Block
    : '{' NEWLINE { create_symbol(); } StatementList '}'        { dump_symbol(); }
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
        printf("error:%d: %s redeclared in this block. previous declaration at line %d",yylineno,name,current->lineno);
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
    for(int i = cur;i >= 0;i ++){
        struct Node *node = table[i];
        while(node != NULL){
            if (strcmp(node->name, name) == 0)
                return node;
            node = node->next;
        }
    }
    printf("error:%d: undefined: %s",yylineno,name);
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
 