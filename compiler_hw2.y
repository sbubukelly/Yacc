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
    char *LIT_type = NULL;
    char *expr_type = NULL;
    char *factor_type = NULL;
    char *assign_type = NULL;
    char *sentence_type = NULL;
    char *REM_check = NULL;
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
%token LAND LOR NEWLINE
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
// %type <type> Type TypeName ArrayType

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : StatementList NEWLINE {dump_symbol();}
;

StatementList
    : StatementList Statement       {if(sentence_type) free(sentence_type);
                                        sentence_type = NULL;}
    | StatementList '{' {create_symbol();} StatementList '}' {dump_symbol();
                                                                if(sentence_type) free(sentence_type);
                                                                sentence_type = NULL;}
    | StatementList IF Statement    {if(strcmp(sentence_type, "bool")!=0)
                                        printf("error:%d: non-bool (type %s) used as for condition\n", yylineno + 1, sentence_type);
                                        if(sentence_type) free(sentence_type);
                                        sentence_type = NULL;}
    | StatementList FOR Statement   {if(strcmp(sentence_type, "bool")!=0)
                                        printf("error:%d: non-bool (type %s) used as for condition\n", yylineno + 1, sentence_type);
                                        if(sentence_type) free(sentence_type);
                                        sentence_type = NULL;}
    | StatementList FOR Statement ';' Statement ';' Statement 
    | Statement                     {if(sentence_type) free(sentence_type);
                                        sentence_type = NULL;}
;

Statement
    : Declaration
    | bool_statement
    | print_expr
    | assignment
    | NEWLINE
;

Declaration
    : VAR ID INT '=' expr NEWLINE        {insert_symbol($<s_val>2, "int32", "-");}
    | VAR ID INT                    {insert_symbol($<s_val>2, "int32", "-");} 
    | VAR ID '[' expr ']' INT NEWLINE     {insert_symbol($<s_val>2, "array", "int32");} 
    | VAR ID FLOAT '=' expr NEWLINE         {insert_symbol($<s_val>2, "float32", "-");}
    | VAR ID FLOAT NEWLINE                  {insert_symbol($<s_val>2, "float32", "-");}
    | VAR ID '[' expr ']' FLOAT NEWLINE     {insert_symbol($<s_val>2, "array", "float32");}
    | VAR ID STRING '=' expr NEWLINE        {insert_symbol($<s_val>2, "string", "-");}
    | VAR ID STRING NEWLINE                 {insert_symbol($<s_val>2, "string", "-");}
    | VAR ID BOOL '=' expr NEWLINE          {insert_symbol($<s_val>2, "bool", "-");}
    | VAR ID BOOL NEWLINE                   {insert_symbol($<s_val>2, "bool", "-");}
;

sentence
    : sentence '>' expr {if(sentence_type) free(sentence_type);
                            sentence_type = strdup("bool");
                            printf("GTR\n");}
    | sentence '<' expr {if(sentence_type) free(sentence_type);
                            sentence_type = strdup("bool");
                            printf("LSS\n");}
    | sentence GEQ expr {if(sentence_type) free(sentence_type);
                            sentence_type = strdup("bool");
                            printf("GEQ\n");}
    | sentence LEQ expr {if(sentence_type) free(sentence_type);
                            sentence_type = strdup("bool");
                            printf("LEQ\n");}
    | sentence EQL expr {if(sentence_type) free(sentence_type);
                            sentence_type = strdup("bool");
                            printf("EQL\n");}
    | sentence NEQ expr {if(sentence_type) free(sentence_type);
                            sentence_type = strdup("bool");
                            printf("NEQ\n");}
    | expr              {if(!sentence_type)
                            {
                                sentence_type = strdup(factor_type);
                            }
                            else if(strcmp(sentence_type, "bool") == 0)
                            {
                                if(sentence_type) free(sentence_type);
                                sentence_type = strdup(expr_type);
                            }}
;

expr
    : expr '+' term {if(strcmp(expr_type, factor_type)!=0)
                        {
                            printf("error:%d: invalid operation: ADD (mismatched types %s and %s)\n", yylineno, expr_type, factor_type);
                        }
                        printf("ADD\n");}
    | expr '-' term {if(strcmp(expr_type, factor_type)!=0)
                        {
                            printf("error:%d: invalid operation: SUB (mismatched types %s and %s)\n", yylineno, expr_type, factor_type);
                        }
                        printf("SUB\n");}    
    | term              {if(expr_type) free(expr_type);
                            expr_type = strdup(factor_type);}
;

term
    : term '*' factor   {printf("MUL\n");}
    | term '/' factor   {printf("QUO\n");}
    | term '%' {current_lineno = yylineno+1;}
               factor   {if(strcmp(factor_type, "int32") != 0 || strcmp(REM_check, "int32") != 0)
                            printf("error:%d: invalid operation: (operator REM not defined on %s)\n", current_lineno, "float32");
                            printf("REM\n");}
    | factor INC        {printf("INC\n");}
    | factor DEC        {printf("DEC\n");}
    | factor            {if(REM_check) free(REM_check);
                            REM_check = strdup(factor_type);
                            }
;

factor 
    : LITs
    | IDs
    | BOOLs                     {if(factor_type) free(factor_type);
                                    factor_type = strdup("bool");}
    | '!' factor                {printf("NOT\n");}
    | '+' factor                {printf("POS\n");}
    | '-' factor                {printf("NEG\n");}
    | INT '(' factor ')'        {printf("F to I\n");
                                    if(factor_type) free(factor_type);
                                    factor_type = strdup("int32");}
    | FLOAT '(' factor ')'      {printf("I to F\n");
                                    if(factor_type) free(factor_type);
                                    factor_type = strdup("float32");}
    | factor '[' expr ']'       {char *tmp;
                                    lookup_symbol($<s_val>1, &tmp);
                                    if(factor_type) free(factor_type);
                                    factor_type = strdup(tmp);}
    | '(' StatementList ')'
;

IDs
    : ID                        {char *tmp;
                                    int address = lookup_symbol($<s_val>1, &tmp);
                                    if(address == -1)
                                    {
                                        printf("error:%d: undefined: %s\n", yylineno+1, $<s_val>1);
                                        if(factor_type) free(factor_type);
                                            factor_type = strdup("int32");
                                    }
                                    else{
                                        printf("IDENT (name=%s, address=%d)\n", $<s_val>1, address); 
                                        if(strcmp(tmp, "string")!= 0 && strcmp(tmp, "bool")!= 0)
                                        {    
                                            if(factor_type) free(factor_type);
                                            factor_type = strdup(tmp);
                                        }
                                    }
                                    if(LIT_type)
                                        free(LIT_type);
                                    LIT_type = NULL;}   

;

LITs
    : INT_LIT                   {printf("INT_LIT %d\n", $<i_val>1);
                                    if(LIT_type) free(LIT_type);
                                    LIT_type = strdup("int32");
                                    if(factor_type) free(factor_type);
                                    factor_type = strdup("int32");}
    | FLOAT_LIT                 {printf("FLOAT_LIT %.6f\n", $<f_val>1);
                                    if(LIT_type) free(LIT_type);
                                    LIT_type = strdup("float32");
                                    if(factor_type) free(factor_type);
                                    factor_type = strdup("float32");}
    | '\"' STRING_LIT '\"'      {printf("STRING_LIT %s\n", $<s_val>2);
                                    if(LIT_type) free(LIT_type);
                                    LIT_type = strdup("string");}
;

BOOLs
    : TRUE                      {printf("TRUE\n");}
    | FALSE                     {printf("FALSE\n");}
;

print_expr
    : prints '(' must_bool_statement ')'    {if(ln) printf("PRINTLN ");
                                            else
                                                printf("PRINT ");
                                            printf("bool\n");}
    | prints '(' IDs ')'                {if(ln) printf("PRINTLN ");
                                            else
                                                printf("PRINT ");
                                            char *tmp;
                                                lookup_symbol($<s_val>3, &tmp);
                                                printf("%s\n", tmp);}
    | prints '(' IDs '[' expr ']' ')'   {if(ln) printf("PRINTLN ");
                                            else
                                                printf("PRINT ");
                                            char *tmp;
                                                lookup_symbol($<s_val>3, &tmp);
                                                printf("%s\n", tmp);}
    | prints '(' LITs ')'               {if(ln) printf("PRINTLN ");
                                            else
                                                printf("PRINT ");
                                                printf("%s\n", LIT_type);}                                      
;

prints
    : PRINT     {ln = 0;}
    | PRINTLN   {ln = 1;}
;

bool_statement
    : sentence LAND {current_lineno = yylineno+1;}
               bool_statement  {if(strcmp(sentence_type, "bool") != 0)
                                        printf("error:%d: invalid operation: (operator LAND not defined on %s)\n", current_lineno, sentence_type);
                                        printf("LAND\n");}
    | sentence LOR {current_lineno = yylineno+1;}
               bool_statement   {if(strcmp(sentence_type, "bool") != 0)
                                        printf("error:%d: invalid operation: (operator LOR not defined on %s)\n", current_lineno, sentence_type);
                                        printf("LOR\n");}
    | sentence                                            
;

must_bool_statement
    : sentence LAND bool_statement  {printf("LAND\n");}
    | sentence LOR bool_statement   {printf("LOR\n");}
;

assignment
    : factor {if(assign_type) free(assign_type);
                assign_type = strdup(factor_type);} '=' expr           {if(strcmp(assign_type, expr_type)!=0)
                                                                            {
                                                                                printf("error:%d: invalid operation: ASSIGN (mismatched types %s and %s)\n", yylineno, assign_type, expr_type);
                                                                            }printf("ASSIGN\n");}
    | factor {if(assign_type) free(assign_type);
                assign_type = strdup(factor_type);
                if(LIT_type)
                    cant_assign = 1;} ADD_ASSIGN expr    {if(cant_assign)
                                                            {
                                                                printf("error:%d: cannot assign to %s\n", yylineno, assign_type);
                                                            }
                                                            printf("ADD_ASSIGN\n");}
    | factor {if(assign_type) free(assign_type);
                assign_type = strdup(factor_type);} SUB_ASSIGN expr    {printf("SUB_ASSIGN\n");}
    | factor {if(assign_type) free(assign_type);
                assign_type = strdup(factor_type);} MUL_ASSIGN expr    {printf("MUL_ASSIGN\n");}
    | factor {if(assign_type) free(assign_type);
                assign_type = strdup(factor_type);} QUO_ASSIGN expr    {printf("QUO_ASSIGN\n");}
    | factor {if(assign_type) free(assign_type);
                assign_type = strdup(factor_type);} REM_ASSIGN expr    {printf("REM_ASSIGN\n");}
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

    create_symbol();
    yylineno = 0;
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
