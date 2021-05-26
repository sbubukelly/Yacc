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

    // typedef struct table_node node;
    struct table_node {
        char *name;
        char *type;
        int address;
        int lineno;
        char *elementType;
        struct table_node *next;
    };
    struct table_node *table[20] = { NULL };

    char *elementType = NULL;
    char typeChange;
    
    /* Symbol table function - you can add new function if needed. */
    static void create_symbol();
    static void insert_symbol(char *name, char *type, char *elementType);
    static struct table_node* lookup_symbol(char *name);
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
%token LAND LOR
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
%type <s_val> Type TypeName INT FLOAT STRING BOOL SEMICOLON
%type <s_val> Expr ExprAdd ExprAnd ExprCompare ExprMul ExprUnary Assignment
%type <s_val> PrintExpr Literal IncDecExpr Operand Primary Array ChangeType

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
    | NEWLINE
;

Assignment 
    :  Expr '=' Expr  {   if (strcmp($<s_val>1, $<s_val>3) != 0)
                                            if (strcmp($<s_val>1, "undefined") != 0 && strcmp($<s_val>3, "undefined") != 0)
                                                printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",
                                                                                        yylineno, $<s_val>2, $<s_val>1, $<s_val>3);
                                        printf("ASSIGN\n");
                                    }
    | Expr ADD_ASSIGN Expr  {   if (strcmp($<s_val>1, $<s_val>3) != 0)
                                            if (strcmp($<s_val>1, "undefined") != 0 && strcmp($<s_val>3, "undefined") != 0)
                                                printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",
                                                                                        yylineno, $<s_val>2, $<s_val>1, $<s_val>3);
                                        printf("ADD_ASSIGN \n");
                                    }
    | Expr SUB_ASSIGN Expr  {   if (strcmp($<s_val>1, $<s_val>3) != 0)
                                            if (strcmp($<s_val>1, "undefined") != 0 && strcmp($<s_val>3, "undefined") != 0)
                                                printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",
                                                                                        yylineno, $<s_val>2, $<s_val>1, $<s_val>3);
                                        printf("SUB_ASSIGN\n");
                                    }
    | Expr MUL_ASSIGN Expr  {   if (strcmp($<s_val>1, $<s_val>3) != 0)
                                            if (strcmp($<s_val>1, "undefined") != 0 && strcmp($<s_val>3, "undefined") != 0)
                                                printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",
                                                                                        yylineno, $<s_val>2, $<s_val>1, $<s_val>3);
                                        printf("MUL_ASSIGN\n");
                                    }
    | Expr QUO_ASSIGN Expr  {   if (strcmp($<s_val>1, $<s_val>3) != 0)
                                            if (strcmp($<s_val>1, "undefined") != 0 && strcmp($<s_val>3, "undefined") != 0)
                                                printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",
                                                                                        yylineno, $<s_val>2, $<s_val>1, $<s_val>3);
                                        printf("QUO_ASSIGN\n");
                                    }
    | Expr REM_ASSIGN Expr  {   if (strcmp($<s_val>1, $<s_val>3) != 0)
                                            if (strcmp($<s_val>1, "undefined") != 0 && strcmp($<s_val>3, "undefined") != 0)
                                                printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",
                                                                                        yylineno, $<s_val>2, $<s_val>1, $<s_val>3);
                                        printf("REM_ASSIGN\n");
                                    }
                        

;

DeclarationStmt
    : Type ID                  {insert_symbol($<s_val>2, $<s_val>1, "-");}
    | Type ID '=' Expr          {insert_symbol($<s_val>2, $<s_val>1, "-");}
    | Type ID '[' Expr ']'      {insert_symbol($<s_val>2,"array", $<s_val>1);}
    | Type ID '[' Expr ']' '=' Expr     {insert_symbol($<s_val>2,"array", $<s_val>1);}
;

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
    : Expr INC       { printf("INC\n"); }
    | Expr DEC       { printf("DEC\n"); }
;

PrintExpr
    : PRINT '(' Expr ')'    { printf("PRINT %s\n", $<s_val>3); }
;

Expr
    : Expr LOR ExprAnd    { printf("LOR\n"); $$ = "bool";}
    | ExprAnd
;

ExprAnd
    : Expr LAND ExprCompare   { printf("LAND\n"); $$ = "bool";}
    | ExprCompare
;

ExprCompare
    : ExprCompare '<' ExprAdd        { printf("LSS"); $$ = "bool";  }
    | ExprCompare '>' ExprAdd        { printf("GTR"); $$ = "bool";  }
    | ExprCompare GEQ ExprAdd        { printf("GEQ"); $$ = "bool";  }
    | ExprCompare LEQ ExprAdd        { printf("LEQ"); $$ = "bool";  }
    | ExprCompare EQL ExprAdd        { printf("EQL"); $$ = "bool";  }
    | ExprCompare NEQ ExprAdd        { printf("NEQ"); $$ = "bool";  }
    | ExprAdd
;

ExprAdd
    : ExprAdd '+' ExprMul     {printf("ADD\n");$$ =  $<s_val>1;}
    | ExprAdd '-' ExprMul     {printf("SUB\n");$$ =  $<s_val>1;}   
    | ExprMul                
;

ExprMul
    : ExprMul '*' ExprUnary         {printf("MUL\n"); $$ = $<s_val>1;}
    | ExprMul '/' ExprUnary         {printf("QUO\n"); $$ = $<s_val>1;}
    | ExprMul '%' ExprUnary         {printf("REM\n"); $$ = $<s_val>1;}
    |ExprUnary 
;

ExprUnary
    : '+' ExprUnary                   { printf("POS"); $$ = $<s_val>2; }
    | '-' ExprUnary                   { printf("NEG"); $$ = $<s_val>2; }
    | '!' ExprUnary                   { printf("NOT"); $$ = $<s_val>2; }
    | Primary

Primary
    : Operand
    | Array
    | ChangeType
;

Array
    : Operand '[' Expr ']'      { $$ = elementType; }
;

ChangeType
    : Type '(' Expr ')'    {   if(strcmp($<s_val>3, "int32") == 0) typeChange = 'I';
                                else{typeChange = 'F';}
                                printf("%c to ",typeChange);
                                if(strcmp($<s_val>1, "int32") == 0) typeChange = 'I';
                                else{typeChange = 'F';}
                                printf("%c\n",typeChange);
                            }
;
Operand 
    : ID    {   struct table_node *id = lookup_symbol($<s_val>1);
                if (id != NULL) {
                    printf("IDENT (name=%s, address=%d)\n", id->name, id->address);
                    $$ = id->type;
                    if (strcmp($$, "array") == 0)
                        elementType = id->elementType;
                } 
                else {
                    printf("error:%d: undefined: %s\n", yylineno+1, $<s_val>1);
                    $$ = "undefined"; }
            }
    |Literal    { $$ = $<s_val>1; }
;

Literal
    : INT_LIT                   { printf("INT_LIT %d\n", $<i_val>1); $$ = "int"; }
    | FLOAT_LIT                 { printf("FLOAT_LIT %.6f\n", $<f_val>1); $$ = "float"; }
    | '\"' STRING_LIT '\"'      { printf("STRING_LIT %s\n", $<s_val>2); $$ = "string"; }
    | TRUE                      { printf("TRUE\n"); $$ = "bool"; }
    | FALSE                     { printf("FALSE\n"); $$ = "bool"; }
;


Block
    : '{' { create_symbol(); } StatementList '}'        { dump_symbol(); }
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
    curScope++;
}

static void insert_symbol(char *name, char *type, char *elementType) {

    struct table_node *cur = table[curScope];
    while (cur != NULL) {
        if(strcmp(cur->name, name) == 0) {
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, name, cur->lineno);
            return;
        }
        cur = cur->next;
    }
    struct table_node *new = malloc(sizeof(struct table_node));
    new->name = name;
    new->type = type;
    new->address = curAddress++;
    new->lineno = yylineno;
    new->elementType = elementType;
    new->next = NULL;
    if(table[curScope] == NULL)
        table[curScope] = new;
    else {
        struct table_node *cur = table[curScope];
        while(cur->next) cur = cur->next;
        cur->next = new;
    }
    
    printf("> Insert {%s} into symbol table (scope level: %d)\n", name, curScope);
}

static struct table_node* lookup_symbol(char *name) {

    int tmp = curScope;
    while (tmp >= 0) {
        struct table_node *cur = table[tmp--];
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
    struct table_node *cur = table[curScope];
    while (cur != NULL) {
        printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                index++, cur->name, cur->type, cur->address, cur->lineno, cur->elementType);
        struct table_node *tmp = cur;
        cur = cur->next;
        free(tmp);
    }
    table[curScope--] = NULL;
}
 