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


    /* Symbol table function - you can add new function if needed. */
    static void create_symbol(/* ... */);
    static void insert_symbol(/* ... */);
    static void lookup_symbol(/* ... */);
    static void dump_symbol(/* ... */);
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
%token INT_LIT FLOAT_LIT STRING_LIT IDENT
%type <i_val> INT_LIT
%type <f_val> FLOAT_LIT
%type <*s_val> STRING_LIT
%type <*s_val> IDENT


/* Nonterminal with return, which need to sepcify type */

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : StatementList
;

Type
    : TypeName { $$ = $1; }
;

TypeName
    : INT
    | FLOAT
    | STRING
    | BOOL
;

Literal
    : INT_LIT {
        printf("INT_LIT %d\n", $<i_val>$);
    }
    | FLOAT_LIT {
        printf("FLOAT_LIT %f\n", $<f_val>$);
    }
;

Statement
    : DeclarationStmt
    | Block
    | IfStmt
    | LoopStmt
    | PrintStmt
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