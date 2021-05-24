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
    
    int curScope = 0;
    int curAddress = 0;
    typedef struct table_node node;
    struct table_node {
        char *name;
        char *type;
        int address;
        int lineno;
        char *elementType;
        node *next;
    };
    node *table[10] = { NULL };

    char *elementType = NULL;
    int isLIT = 0, canAssign = 1,isArray = 0;
    
    /* Symbol table function - you can add new function if needed. */
    static void create_symbol();
    static void insert_symbol(char *name, char *type, char *elementType);
    static node* lookup_symbol(char *name);
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
%token VAR
%token INT FLOAT BOOL STRING 
%token INC DEC GEQ LEQ EQL NEQ 
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token LAND LOR
%token NEWLINE
%token PRINT PRINTLN
%token IF ELSE FOR
%token TRUE FALSE

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT
%token <*s_val> ID

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type TypeName INT FLOAT STRING BOOL 
%type <s_val> Expr Expr2 Literal IncDecExpr Operand

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
    : DeclarationStmt NEWLINE           { isArray = 0; }
    | Expr NEWLINE 
    | IncDecExpr
    | NEWLINE
    ;

DeclarationStmt
    : VAR ID Type                   {insert_symbol($<s_val>1, $<s_val>3, "-");}


Type
    : TypeName
;

TypeName
    : INT
    | FLOAT
    | STRING
    | BOOL
;

IncDecExpr
    : Expr INC        { printf("INC\n"); }
    | Expr DEC        { printf("DEC\n"); }
;

Expr
    :Expr '+' Expr2      {if (strcmp($<s_val>1, $<s_val>3) == 0) $$ = $<s_val>1;
                        else if (strcmp($<s_val>1, "undefined") != 0 && strcmp($<s_val>3, "undefined") != 0)
                        printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno, $<s_val>2, $<s_val>1, $<s_val>3);
                        printf("ADD");
                        isLIT = 1;
                        }
    |Expr '-' Expr2      {if (strcmp($<s_val>1, $<s_val>3) == 0) $$ = $<s_val>1;
                        else if (strcmp($<s_val>1, "undefined") != 0 && strcmp($<s_val>3, "undefined") != 0)
                        printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno, $<s_val>2, $<s_val>1, $<s_val>3);
                        printf("SUB");
                        isLIT = 1;
                        }   
    |Expr2                 
;

Expr2
    : Expr2 '*' Operand       {
                                printf("MUL");
                                if (strcmp($<s_val>1, $<s_val>3) == 0)
                                    $$ = $<s_val>1;
                                isLIT = 1;
                            }
    | Expr2 '/' Operand       {
                                printf("QUO");
                                if (strcmp($<s_val>1, $<s_val>3) == 0)
                                    $$ = $<s_val>1;
                                isLIT = 1;
                            }
    | Expr2 '%' Operand      {   char *wrongType = NULL;
                                if (strcmp($<s_val>1, "int32") != 0)
                                    wrongType = $<s_val>1;
                                else if (strcmp($<s_val>3, "int32") != 0)
                                    wrongType = $<s_val>3;
                                if (wrongType != NULL)
                                    printf("error:%d: invalid operation: (operator REM not defined on %s)\n",
                                            yylineno, wrongType);
                                printf("REM");
                                if (strcmp($<s_val>1, $<s_val>3) == 0)
                                    $$ = $<s_val>1;
                                isLIT = 1;
                            }
    |Operand 
;

Operand 
    : ID    {  node *symbol = lookup_symbol($<s_val>1);
                if (symbol != NULL) {
                    printf("IDENT (name=%s, address=%d)\n", $<s_val>1, symbol->address);
                    $$ = symbol->type;
                    if (strcmp($$, "array") == 0)
                        elementType = symbol->elementType;
                        isLIT = 0;} 
                    else {
                        printf("error:%d: undefined: %s\n", yylineno+1, $<s_val>1);
                        $$ = "undefined"; }
            }
    |Literal    { $$ = $<s_val>1; isLIT = 1; }
;

Literal
    : INT_LIT                   { printf("INT_LIT %d\n", $<i_val>1); $$ = "int"; }
    | FLOAT_LIT                 { printf("FLOAT_LIT %.6f\n", $<f_val>1); $$ = "float"; }
    | TRUE                      { printf("TRUE\n"); $$ = "bool"; }
    | FALSE                     { printf("FALSE\n"); $$ = "bool"; }
    | '\"' STRING_LIT '\"'      { printf("STRING_LIT %s\n", $<s_val>2); $$ = "string"; }
;


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

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}
static void create_symbol() {
    curScope++;
}

static void insert_symbol(char *name, char *type, char *elementType) {

    node *cur = table[curScope];
    while (cur != NULL) {
        if(strcmp(cur->name, name) == 0) {
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, name, cur->lineno);
            return;
        }
        cur = cur->next;
    }
    node *new_node = malloc(sizeof(node));
    new_node->name = name;
    new_node->type = type;
    new_node->address = curAddress++;
    new_node->lineno = yylineno;
    new_node->elementType = elementType;
    new_node->next = NULL;
    if(!table[curScope])
        table[curScope] = new_node;
    else {
        node *cur = table[curScope];
        while(cur->next) cur = cur->next;
        cur->next = new_node;
    }
    
    printf("> Insert {%s} into symbol table (scope level: %d)\n", name, curScope);
}

static node* lookup_symbol(char *name) {

    int scope = curScope;
    while (scope >= 0) {
        node *cur = table[scope--];
        while (cur != NULL) {
            if (strcmp(cur->name, name) == 0)
                return cur;
            cur = cur->next;
        }
    }

    return NULL;
}

static void dump_symbol() {

    printf("> Dump symbol table (scope level: %d)\n", curScope);
    printf("%-10s%-10s%-10s%-10s%-10s%s\n",
           "Index", "Name", "Type", "Address", "Lineno", "Element type");
    int index = 0;
    node *cur = table[curScope];
    while (cur != NULL) {
        printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                index++, cur->name, cur->type, cur->address, cur->lineno, cur->elementType);
        node *tmp = cur;
        cur = cur->next;
        free(tmp);
    }
    table[curScope--] = NULL;
}