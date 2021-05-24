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
    static void create_symbol();
    static void insert_symbol();
    static int  lookup_symbol();
    static void dump_symbol();

    struct Table_node {
        int index;
        char *name;
        char *type;
        int address;
        int lineno;
        char *element_type;
        struct Table_node *next;
    };

    int current_scope = -1;
    int ln = 0;
    int current_address = 0;
    int current_lineno = 0;
    char cant_assign = 0;
    // char *LIT_type = NULL;
    // char *expr_type = NULL;
    // char *factor_type = NULL;
    // char *assign_type = NULL;
    // char *sentence_type = NULL;
    // char *REM_check = NULL;
    struct Table_node *tables[20] = {};
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
%token INT_LIT FLOAT_LIT STRING_LIT ID
%type <i_val> INT_LIT
%type <f_val> FLOAT_LIT
%type <*s_val> STRING_LIT
%type <*s_val> ID


/* Nonterminal with return, which need to sepcify type */
//%type <s_val> Type TypeName ArrayType
/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : StatementList NEWLINE {dump_symbol();}
;

StatementList
    : StatementList Statement   
    | Statement    

Statement
    : DeclarationStmt 
    // | Block NEWLINE
    // | IfStmt NEWLINE
    // | LoopStmt NEWLINE
    // | PrintStmt NEWLINE
;

DeclarationStmt
    : VAR ID Type   {insert_symbol($<s_val>2, $<s_val>3, "-"); }
    | VAR ID Type '=' Expr  {insert_symbol($<s_val>2, $<s_val>3, "-");}
    | VAR ID ArrayType    {insert_symbol($<s_val>2, "array",  $<s_val>3);} 
    | VAR ID ArrayType '=' Expr   {insert_symbol($<s_val>2, "array",  $<s_val>3);} 
;

Operation
    : Expr
;

Type
    : TypeName 
;
ArrayType
    : '[' Literal ']' Type       { $$ = $<s_val>4;} 
;

TypeName
    : INT
    | FLOAT
    | STRING
    | BOOL
;

Expr  //+ - 
;

term 
;

Literal
    : INT_LIT {
        printf("INT_LIT %d\n", $<i_val>$);
    }
    | FLOAT_LIT {
        printf("FLOAT_LIT %f\n", $<f_val>$);
    }
    | '\"' STRING_LIT '\"'      { printf("STRING_LIT %s\n", $<s_val>2); $$ = "string"; }
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
    current_scope += 1;
    tables[current_scope] = NULL;
}

static void insert_symbol(char* name, char* type, char* element_type) {
    // Dose the ID already declared?
    for(struct Table_node *current = tables[current_scope]; current; current = current->next)
    {
        if(strcmp(current->name, name) == 0)
        {
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, name, current->lineno);
            return;
        }
    }
    struct Table_node *table = malloc(sizeof(struct Table_node));
    table->index = 0;
    table->name = name;
    table->type = type;
    table->address = current_address++;
    table->lineno = yylineno;
    table->element_type = element_type;
    table->next = NULL;
    if(!tables[current_scope])
    {
        tables[current_scope] = table;
    }
    else
    {
        struct Table_node *current = tables[current_scope];
        while(current->next) current = current->next;
        table->index = current->index + 1;
        current->next = table;
    }
    printf("> Insert {%s} into symbol table (scope level: %d)\n", name, current_scope);
}

/* return address of target name
 * return -1 if it doesn't exist   
 */
static int lookup_symbol(char* name, char** type) {
    int scope = current_scope;
    struct Table_node *current = tables[scope];

    while(!current && scope > 0)
        current = tables[--scope];
    while( strcmp(name, current->name) != 0 )
    {
        // change to wider scope if there is no target in current scope.
        if(!current->next)
        {
            // there is no other nodes exsiting;
            if(scope == 0)
            {
                current = NULL;
                break;
            }
            else
                current = tables[--scope];
        }
        else
            current = current->next;
    }
    if(current)
    {
        if(strcmp(current->type, "array") == 0)
            *type = current->element_type;
        else
            *type = current->type;
        return current->address;
    }
    else
        return -1;
}

static void dump_symbol() {
    printf("> Dump symbol table (scope level: %d)\n", current_scope);
    printf("%-10s%-10s%-10s%-10s%-10s%s\n",
           "Index", "Name", "Type", "Address", "Lineno", "Element type");
    for(struct Table_node *current = tables[current_scope]; current; current = current->next)
        printf("%-10d%-10s%-10s%-10d%-10d%s\n",
                current->index, current->name, current->type, current->address, current->lineno, current->element_type);

    current_scope -= 1;
}