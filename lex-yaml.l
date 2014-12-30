
%x LINESTART LINE1 LINE2 LINE3
%s NORMAL

%{
#include <assert.h>
#include <stack>
static std::stack<int>  indent;
static int              parens=0;
static int indent_depth(const char *);
static struct match_t parse_match(const char *s, int bits_per_digit);

#if YYDEBUG
#undef BEGIN
/* DANGER -- the depends on the internals of how flex sets states, but as
 * DANGER -- its only for debugging, its not too bad */
#define BEGIN(S)  ((yy_start) = 1 + 2*(S), \
                   yydebug ? fprintf(stderr, "Setting lexer state "#S"\n") : 0)
#define DB(...) fprintf(stderr, __VA_ARGS__)
#else
#define DB(...)
#endif
%}

ID [A-Za-z_]([-.]?*[A-Za-z0-9_])*

%option nounput noyywrap

%%

<INITIAL>.*|\n        { yyless(0); BEGIN(LINESTART); indent.push(0); }
<LINESTART>[ \t]*     { int depth = indent_depth(yytext);
                        if (depth < indent.top()) {
                            indent.pop();
                            yyless(0);
                            return UNINDENT; }
                        BEGIN(NORMAL);
                        if (depth > indent.top()) {
                            indent.push(depth);
                            return INDENT; } }

<LINESTART>"#line"    { BEGIN(LINE1); }
<LINESTART>"# "       { BEGIN(LINE1); }
<LINE1>[0-9]+         { line_file_map[lineno].second = atoi(yytext)-1;
                        DB("next line is %s\n", yytext);
                        BEGIN(LINE2); }
<LINE2>\"[^"]*        { line_file_map[lineno].first = yytext+1;
                        DB("file is '%s'\n", yytext+1);
                        BEGIN(LINE3); }
<LINE1,LINE2>[ \t]      ;
<LINE1,LINE2>.        { BEGIN(LINE3); }
<LINE3>.                ;
<LINE1,LINE2,LINE3>\n { lineno++; BEGIN(LINESTART); }
<LINE1,LINE2,LINE3><<EOF>> { BEGIN(LINESTART); }

<LINESTART>"#"        { BEGIN(LINE3); }
<LINESTART>.          { yyless(0);
                        if (indent.top() > 0) {
                            indent.pop();
                            return UNINDENT; }
                        BEGIN(NORMAL); }
<LINESTART><<EOF>>    { if (indent.top() > 0) {
                            indent.pop();
                            return UNINDENT; }
                        BEGIN(NORMAL); }
<LINESTART>[ \t]*\n   { lineno++; }

[[({]             { parens++; return *yytext; }
[])}]             { if (--parens < 0) parens = 0;
                    return *yytext; }
\n                { lineno++;
                    if (parens == 0) {
                        BEGIN(LINESTART);
                        return '\n'; } }
[ \t]+              ;
".."              { return DOTDOT; }
{ID}              { yylval.str = strdup(yytext); return ID; }
[0-9]+            { yylval.i = atoi(yytext); return INT; }
0[xX][0-9a-fA-F]+ { yylval.i = strtol(yytext+2, 0, 16); return INT; }
0[oO][0-7]+       { yylval.i = strtol(yytext+2, 0, 8); return INT; }
0[bB][0-1]+       { yylval.i = strtol(yytext+2, 0, 2); return INT; }
0[xX][0-9a-fA-F*]+ { yylval.match = parse_match(yytext+2, 4); return MATCH; }
0[oO][0-7*]+      { yylval.match = parse_match(yytext+2, 3); return MATCH; }
0[bB][0-1*]+      { yylval.match = parse_match(yytext+2, 1); return MATCH; }

"#".*               ;
.                 { return *yytext; }


%%

int indent_depth(const char *pfx) {
    int rv = 0;
    while (*pfx)
        switch(*pfx++) {
        case ' ': rv++; break;
        case '\t': rv &= ~7; rv += 8; break;
        default:
            return rv;}
    return rv;
}

struct match_t parse_match(const char *s, int bits_per_digit) {
    struct match_t rv = { 0, 0 };
    unsigned digit, digit_mask = (1U << bits_per_digit) - 1;
    while (*s) {
        rv.word0 <<= bits_per_digit;
        rv.word1 <<= bits_per_digit;
        switch (*s) {
        case '0': case '1': case '2': case '3': case '4':
        case '5': case '6': case '7': case '8': case '9':
            digit = *s - '0';
            break;
        case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
            digit = *s - 'a' + 10;
            break;
        case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
            digit = *s - 'A' + 10;
            break;
        case '*':
            rv.word1 |= digit_mask;
            digit = 0;
            break;
        default:
            assert(0); }
        assert((digit & ~digit_mask) == 0);
        rv.word1 |= digit;
        rv.word0 |= digit_mask & ~digit;
        s++; }
    return rv;
}
