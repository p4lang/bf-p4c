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

static value_t value(int v, bool lineno_adj = false) {
    value_t rv{tINT, lineno - (lineno_adj ? 1 : 0)};
    rv.i = v;
    return rv; }
static value_t value(int lo, int hi, bool lineno_adj = false) {
    value_t rv{tRANGE, lineno - (lineno_adj ? 1 : 0)};
    rv.lo = lo;
    rv.hi = hi;
    return rv; }
static value_t value(char *v, bool lineno_adj = false) {
    value_t rv{tSTR, lineno - (lineno_adj ? 1 : 0)};
    rv.s = v;
    return rv; }
static value_t value(match_t v, bool lineno_adj = false) {
    value_t rv{tMATCH, lineno - (lineno_adj ? 1 : 0)};
    rv.m = v;
    return rv; }
static value_t value(VECTOR(value_t) &v, bool lineno_adj = false) {
    value_t rv{tVEC, lineno - (lineno_adj ? 1 : 0)};
    if (v.size > 0) rv.lineno = v.data[0].lineno;
    rv.vec = v;
    return rv; }
static value_t value(VECTOR(pair_t) &v, bool lineno_adj = false) {
    value_t rv{tMAP, lineno - (lineno_adj ? 1 : 0)};
    if (v.size > 0) rv.lineno = v.data[0].key.lineno;
    rv.map = v;
    return rv; }
static value_t singleton_map(const value_t &k, const value_t &v) {
    value_t rv{tMAP, k.lineno};
    VECTOR_init1(rv.map, (pair_t{k, v}));
    return rv; }
static value_t command(char *cmd, const VECTOR(value_t) &args, bool lineno_adj = false) {
    value_t rv{tCMD, lineno - (lineno_adj ? 1 : 0)};
    if (args.size && args.data[0].lineno < rv.lineno)
        rv.lineno = args.data[0].lineno;
    rv.vec = args;
    VECTOR_insert(rv.vec, 0, 1);
    rv[0] = value(cmd);
    rv[0].lineno = rv.lineno;
    return rv; }
static value_t command(char *cmd, const value_t &arg, bool lineno_adj = false) {
    value_t rv{tCMD, lineno - (lineno_adj ? 1 : 0)};
    if (arg.lineno < rv.lineno)
        rv.lineno = arg.lineno;
    VECTOR_init2(rv.vec, value(cmd), arg);
    rv[0].lineno = rv.lineno;
    return rv; }
static value_t list_map_expand(VECTOR(value_t) &v);

%}

%union {
    int                 i;
    char                *str;
    match_t             match;
    value_t             value;
    VECTOR(value_t)     vec;
    pair_t              pair;
    VECTOR(pair_t)      map;
}

%token          INDENT UNINDENT DOTDOT
%token<i>       INT
%token<str>     ID
%token<match>   MATCH

%type<value>    param list_element key value elements
%type<vec>      opt_params params comma_params list_elements value_list
%type<pair>     map_element pair
%type<map>      map_elements pair_list

%destructor   { free($$); } <str>
%destructor   { free_value(&$$); } <value>
%destructor   { VECTOR_foreach($$, free_value); VECTOR_fini($$); } <vec>
%destructor   { free_pair(&$$); } <pair>
%destructor   { VECTOR_foreach($$, free_pair); VECTOR_fini($$); } <map>

%%

start: INDENT sections UNINDENT | sections | /* epsilon */;

sections: sections section | section ;

section: ID opt_params ':'
            { $<i>$ = Section::start_section(lineno, $1, $2); }
         '\n' INDENT elements UNINDENT
            { if (!$<i>4) Section::asm_section($1, $2, $7);
              VECTOR_foreach($2, free_value);
              VECTOR_fini($2);
              free_value(&$7);
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
param   : INT { $$ = value($1, yychar == '\n'); }
        | ID { $$ = value($1, yychar == '\n'); }
        | '-' INT { $$ = value(-$2, yychar == '\n'); }
        | INT DOTDOT INT { $$ = value($1, $3, yychar == '\n'); }
        ;

elements: list_elements { $$ = list_map_expand($1); }
        | map_elements { $$ = value($1); }
        ;
map_elements: map_elements map_element { $$ = $1; VECTOR_add($$, $2); }
        | map_element { VECTOR_init1($$, $1); }
        ;
list_elements: list_elements list_element { $$ = $1; VECTOR_add($$, $2); }
        | list_element { VECTOR_init1($$, $1); }
        ;

map_element
        : key ':' value '\n' { $$ = pair_t{ $1, $3 }; }
        | key ':' '\n' INDENT elements UNINDENT { $$ = pair_t{ $1, $5 }; }
        | key ':' '\n' list_elements { $$ = pair_t{ $1, value($4) }; }
        ;

list_element
        : '-' key ':' value '\n' { $$ = singleton_map($2, $4); }
        | '-' value '\n' { $$ = $2; }
        | '-' ID comma_params '\n' { $$ = command($2, $3); }
        | '-' key ':' '\n' INDENT elements UNINDENT { $$ = singleton_map($2, $6); }
        ;

key : ID { $$ = value($1, yychar == '\n'); }
    | ID params { $$ = command($1, $2, yychar == '\n'); }
    | INT { $$ = value($1, yychar == '\n'); }
    | MATCH { $$ = value($1, yychar == '\n'); }
    | INT DOTDOT INT { $$ = value($1, $3, yychar == '\n'); }
    | ID '(' param ')' { $$ = command($1, $3, yychar == '\n'); }
    ;

value: key
    | '[' value_list ']' { $$ = value($2); }
    | '{' pair_list '}' { $$ = value($2); }
    ;

value_list
    : value_list ',' value { $$ = $1; VECTOR_add($$, $3); }
    | value { VECTOR_init1($$, $1); }
    ;
pair_list
    : pair_list ',' pair { $$ = $1; VECTOR_add($$, $3); }
    | pair { VECTOR_init1($$, $1); }
    ;
pair: key ':' value { $$ = pair_t{ $1, $3 }; }
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
    fprintf(stderr, "\n"); }

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

/* check a list and see if it is a list of maps -- if so, concatenate the
 * maps into a single map and return that, otherwise return the list */
static value_t list_map_expand(VECTOR(value_t) &v) {
    bool list_of_maps = v.size > 0;
    for (int i = 0; i < v.size; i++) {
        if (v.data[i].type != tMAP) {
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
