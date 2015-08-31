%{
#define YYDEBUG 1
#include "asm-types.h"
#include <string.h>
#include "sections.h"
#include <map>
#include <string>
static int yylex();
static void yyerror(const char *, ...);
static int lineno;
static std::map<int, std::pair<std::string, int>> line_file_map;

static value_t value(int v, int lineno_adj) {
    value_t rv{tINT, lineno - lineno_adj};
    rv.i = v;
    return rv; }
static value_t value(VECTOR(uintptr_t) &v, int lineno_adj) {
    value_t rv{tBIGINT, lineno - lineno_adj};
    rv.bigi = v;
    return rv; }
static value_t value(int lo, int hi, int lineno_adj) {
    value_t rv{tRANGE, lineno - lineno_adj};
    rv.lo = lo;
    rv.hi = hi;
    return rv; }
static value_t value(char *v, int lineno_adj) {
    value_t rv{tSTR, lineno - lineno_adj};
    rv.s = v;
    return rv; }
static value_t value(match_t v, int lineno_adj) {
    value_t rv{tMATCH, lineno - lineno_adj};
    rv.m = v;
    return rv; }
static value_t value(VECTOR(value_t) &v, int lineno_adj) {
    value_t rv{tVEC, lineno - lineno_adj};
    if (v.size > 0) rv.lineno = v.data[0].lineno;
    rv.vec = v;
    return rv; }
static value_t value(VECTOR(pair_t) &v, int lineno_adj) {
    value_t rv{tMAP, lineno - lineno_adj};
    if (v.size > 0) rv.lineno = v.data[0].key.lineno;
    rv.map = v;
    return rv; }
static value_t empty_vector(int lineno_adj) {
    value_t rv{tVEC, lineno - lineno_adj};
    memset(&rv.vec, 0, sizeof(rv.vec));
    return rv; }
static value_t empty_map(int lineno_adj) {
    value_t rv{tMAP, lineno - lineno_adj};
    memset(&rv.vec, 0, sizeof(rv.vec));
    return rv; }
static value_t singleton_map(const value_t &k, const value_t &v) {
    value_t rv{tMAP, k.lineno};
    VECTOR_init1(rv.map, pair_t(k, v));
    return rv; }
static value_t command(char *cmd, const VECTOR(value_t) &args, int lineno_adj) {
    value_t rv{tCMD, lineno - lineno_adj};
    if (args.size && args.data[0].lineno < rv.lineno)
        rv.lineno = args.data[0].lineno;
    rv.vec = args;
    VECTOR_insert(rv.vec, 0, 1);
    rv[0] = value(cmd, 0);
    rv[0].lineno = rv.lineno;
    return rv; }
static value_t command(char *cmd, value_t &arg, int lineno_adj) {
    value_t rv{tCMD, lineno - lineno_adj};
    if (arg.lineno < rv.lineno)
        rv.lineno = arg.lineno;
    VECTOR_init2(rv.vec, value(cmd, 0), arg);
    rv[0].lineno = rv.lineno;
    return rv; }
static value_t command(char *cmd, value_t &a1, value_t &a2, int lineno_adj) {
    if (a1.type == tCMD && a1 == cmd && a1.vec.size > 2) {
        free(cmd);
        VECTOR_add(a1.vec, a2);
        return a1; }
    value_t rv{tCMD, lineno - lineno_adj};
    if (a1.lineno < rv.lineno)
        rv.lineno = a1.lineno;
    VECTOR_init3(rv.vec, value(cmd, 0), a1, a2);
    rv[0].lineno = rv.lineno;
    return rv; }
static value_t list_map_expand(VECTOR(value_t) &v);

#define VAL(...)  value(__VA_ARGS__, yychar == '\n' ? 1 : 0)
#define CMD(...)  command(__VA_ARGS__, yychar == '\n' ? 1 : 0)

%}

%define parse.error verbose
%define lr.default-reduction accepting

%left '|' '^'
%left '&'
%nonassoc UNARY

%union {
    int                 i;
    VECTOR(uintptr_t)   bigi;
    char                *str;
    match_t             match;
    value_t             value;
    VECTOR(value_t)     vec;
    pair_t              pair;
    VECTOR(pair_t)      map;
}

%token          INDENT UNINDENT DOTDOT
%token<i>       INT
%token<bigi>    BIGINT
%token<str>     ID
%token<match>   MATCH

%type<value>    param list_element key value elements indent_elements flow_value
%type<vec>      opt_params params comma_params linewrapped_params list_elements value_list dotvals
%type<pair>     map_element pair
%type<map>      map_elements pair_list

%destructor   { free($$); } <str>
%destructor   { VECTOR_fini($$); } <bigi>
%destructor   { free_value(&$$); } <value>
%destructor   { VECTOR_foreach($$, free_value); VECTOR_fini($$); } <vec>
%destructor   { free_pair(&$$); } <pair>
%destructor   { VECTOR_foreach($$, free_pair); VECTOR_fini($$); } <map>

%%

start: INDENT sections UNINDENT | sections | /* epsilon */;

sections: sections section | section ;

section : ID opt_params ':'
            { $<i>$ = Section::start_section(lineno, $1, $2); }
          '\n' indent_elements
            { if (!$<i>4) Section::asm_section($1, $2, $6);
              VECTOR_foreach($2, free_value);
              VECTOR_fini($2);
              free_value(&$6);
              free($1); }
        | ID opt_params ':'
            { $<i>$ = Section::start_section(lineno, $1, $2); }
          value '\n'
            { if (!$<i>4) Section::asm_section($1, $2, $5);
              VECTOR_foreach($2, free_value);
              VECTOR_fini($2);
              free_value(&$5);
              free($1); }
;

opt_params: /* empty */ { memset(&$$, 0, sizeof($$)); }
        | params
        ;
params  : param { VECTOR_init1($$, $1); }
        | params param  { $$ = $1; VECTOR_add($$, $2); }
        ;
comma_params
        : param ',' param { VECTOR_init2($$, $1, $3); }
        | comma_params ',' param { $$ = $1; VECTOR_add($$, $3); }
        ;
linewrapped_params
        /* nasty rule duplication caused by mixing left- and right- recursive
         * rules.  Factoring here results in shift/reduce conflicts */
        : param { VECTOR_init1($$, $1); }
        | comma_params { $$ = $1; }
        | param ',' '\n' linewrapped_params
              { $$ = $4; VECTOR_insert($$, 0); $$.data[0] = $1; }
        | comma_params ',' '\n' linewrapped_params
              { $$ = $1; VECTOR_addcopy($$, $4.data, $4.size); VECTOR_fini($4); }
        | INDENT param '\n' UNINDENT { VECTOR_init1($$, $2); }
        | INDENT comma_params '\n' UNINDENT { $$ = $2; }
        | INDENT param ',' '\n' linewrapped_params '\n' UNINDENT
              { $$ = $5; VECTOR_insert($$, 0); $$.data[0] = $2; }
        | INDENT comma_params ',' '\n' linewrapped_params '\n' UNINDENT
              { $$ = $2; VECTOR_addcopy($$, $5.data, $5.size); VECTOR_fini($5); }
        ;
param   : INT { $$ = VAL($1); }
        | ID { $$ = VAL($1); }
        | '-' INT { $$ = VAL(-$2); }
        | INT DOTDOT INT { $$ = VAL($1, $3); }
        | ID '(' param ')' { $$ = CMD($1, $3); }
        | ID '(' comma_params ')' { $$ = CMD($1, $3); }
        ;

indent_elements
        : INDENT elements UNINDENT { $$ = $2; }
        | INDENT error { $<i>$ = lineno; } error_resync UNINDENT { $$ = empty_map(lineno-$<i>3); }
        ;
elements: list_elements { $$ = list_map_expand($1); }
        | list_elements error error_resync { $$ = list_map_expand($1); }
        | map_elements { $$ = VAL($1); }
        | map_elements error error_resync { $$ = VAL($1); }
        ;
map_elements: map_elements map_element { $$ = $1; VECTOR_add($$, $2); }
        | map_element { VECTOR_init1($$, $1); }
        ;
list_elements: list_elements list_element { $$ = $1; VECTOR_add($$, $2); }
        | list_element { VECTOR_init1($$, $1); }
        ;

map_element
        : key ':' value '\n' { $$ = pair_t($1, $3); }
        | flow_value ':' value '\n' { $$ = pair_t($1, $3); }
        | key ':' '\n' indent_elements { $$ = pair_t($1, $4); }
        | flow_value ':' '\n' indent_elements { $$ = pair_t($1, $4); }
        | key ':' '\n' list_elements { $$ = pair_t($1, list_map_expand($4)); }
        | flow_value ':' '\n' list_elements { $$ = pair_t($1, list_map_expand($4)); }
        | '?' value  ':' value '\n' { $$ = pair_t($2, $4); }
        | '?' value '\n' ':' value '\n' { $$ = pair_t($2, $5); }
        ;

list_element
        : '-' key ':' value '\n' { $$ = singleton_map($2, $4); }
        | '-' value '\n' { $$ = $2; }
        | '-' ID comma_params '\n' { $$ = command($2, $3, yychar == '\n' ? 2 : 1); }
        | '-' ID comma_params ',' '\n' linewrapped_params
              { VECTOR_addcopy($3, $6.data, $6.size);
                $$ = command($2, $3, yychar == '\n' ? 2 : 1);
                VECTOR_fini($6); }
        | '-' ID param ',' '\n' linewrapped_params
              { VECTOR_insert($6, 0); $6.data[0] = $3;
                $$ = command($2, $6, yychar == '\n' ? 2 : 1); }
        | '-' key ':' '\n' indent_elements { $$ = singleton_map($2, $5); }
        ;

key : ID { $$ = VAL($1); }
    | ID params { $$ = CMD($1, $2); }
    | INT { $$ = VAL($1); }
    | BIGINT { $$ = VAL($1); }
    | MATCH { $$ = VAL($1); }
    | INT DOTDOT INT { $$ = VAL($1, $3); }
    | ID '(' value_list ')' { $$ = CMD($1, $3); }
    ;

value: key
    | flow_value
    | '-' value %prec UNARY { if (($$=$2).type == tINT) $$.i = -$$.i; else $$ = CMD(strdup("-"), $2); }
    | dotvals INT { VECTOR_add($1, VAL($2)); $$ = VAL($1); }
    | value '^' value { $$ = CMD(strdup("^"), $1, $3); }
    | value '|' value { $$ = CMD(strdup("|"), $1, $3); }
    | value '&' value { $$ = CMD(strdup("&"), $1, $3); }
    | '(' value ')' { $$ = $2; }
    ;

flow_value
    : '[' value_list ']' { $$ = VAL($2); }
    | '[' value_list error error_resync ']' { $$ = VAL($2); }
    | '{' pair_list '}' { $$ = VAL($2); }
    | '{' pair_list error error_resync '}' { $$ = VAL($2); }
    | '[' ']' { $$ = empty_vector(yychar == '\n' ? 1 : 0); }
    | '[' error error_resync ']' { $$ = empty_vector(yychar == '\n' ? 1 : 0); }
    | '{' '}' { $$ = empty_map(yychar == '\n' ? 1 : 0); }
    | '{' error error_resync '}' { $$ = empty_map(yychar == '\n' ? 1 : 0); }
    ;

value_list
    : value_list ',' value { $$ = $1; VECTOR_add($$, $3); }
    | value { VECTOR_init1($$, $1); }
    ;
pair_list
    : pair_list ',' pair { $$ = $1; VECTOR_add($$, $3); }
    | pair { VECTOR_init1($$, $1); }
    ;
pair: value ':' value { $$ = pair_t($1, $3); }
    ;

dotvals : dotvals INT '.' { $$ = $1; VECTOR_add($$, VAL($2)); }
        | INT '.' { VECTOR_init1($$, VAL($1)); }

error_resync: /* epsilon */ | error_resync indent_elements { free_value(&$2); }
    | error_resync INT | error_resync ID { free($2); } | error_resync MATCH
    | error_resync BIGINT { VECTOR_fini($2); } | error_resync ':' | error_resync '-'
    | error_resync ',' | error_resync '(' | error_resync ')' | error_resync DOTDOT
    | error_resync '\n' | error_resync flow_value { free_value(&$2); }
    ;

%%

#include "lex-yaml.c"

int error_count = 0;

void warning(int lineno, const char *fmt, va_list args) {
    auto it = line_file_map.upper_bound(lineno);
    it--;
    fprintf(stderr, "%s:%d: ", it->second.first.c_str(),
            lineno - it->first + it->second.second);
    vfprintf(stderr, fmt, args);
    fprintf(stderr, "\n");
    fflush(stderr); }

void error(int lineno, const char *fmt, va_list args) {
    warning(lineno, fmt, args);
    error_count++; }

static void yyerror(const char *fmt, ...) {
    va_list     args;
    va_start(args, fmt);
    error(lineno, fmt, args);
    va_end(args);
}

void asm_parse_file(const char *name, FILE *in) {
#ifdef YYDEBUG
    if (const char *p = getenv("YYDEBUG"))
        yydebug = atoi(p);
#endif /* YYDEBUG */
    yyrestart(in);
    line_file_map[lineno++] = std::make_pair(name, 0);
    if (yyparse())
        error_count++;
}

/* check a list and see if it is a list of singleton maps -- if so, concatenate the
 * maps into a single map and return that, otherwise return the list */
static value_t list_map_expand(VECTOR(value_t) &v) {
    bool list_of_maps = v.size > 0;
    for (int i = 0; i < v.size; i++) {
        if (v.data[i].type != tMAP || v.data[i].map.size != 1) {
            list_of_maps = false;
            break; } }
    value_t rv{tVEC, lineno};
    if (list_of_maps) {
        rv.type = tMAP;
        rv.map = v.data[0].map;
        for (int i = 1; i < v.size; i++) {
            VECTOR_addcopy(rv.map, v.data[i].map.data, v.data[i].map.size);
            VECTOR_fini(v.data[i].map); }
        VECTOR_fini(v);
    } else
        rv.vec = v;
    return rv; }

std::map<std::string, Section *> *Section::sections = 0;
