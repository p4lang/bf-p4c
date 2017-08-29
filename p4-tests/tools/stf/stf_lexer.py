# -----------------------------------------------------------------------------
# stf_lexer.py
#
# Tokenize an STF file.
# -----------------------------------------------------------------------------

import ply.lex as lex
from ply.lex import TOKEN

class STFLexer:
    def __init__(self):
        self.filename = ''
        # Keeps track of the last token returned from self.token()
        self.last_token = None
        self.errors_cnt = 0
        self.lexer = None

    def reset_lineno(self):
        """ Resets the internal line number counter of the lexer.
        """
        self.lexer.lineno = 1
        self.lexer.colno = 1

    def get_lineno(self):
        return self.lexer.lineno

    def get_colno(self):
        return self.lexer.colno

    # input() and token() are required when building parser from this lexer
    def input(self, text):
        self.lexer.input(text)

    def token(self):
        self.last_token = self.lexer.token()
        self.lexer.colno += 1
        # print self.last_token
        return self.last_token

    def find_tok_column(self, token):
        """ Find the column of the token in its line.
        """
        last_cr = self.lexer.lexdata.rfind('\n', 0, token.lexpos)
        return token.lexpos - last_cr

    # Build the lexer
    def build(self,**kwargs):
        self.lexer = lex.lex(module=self, **kwargs)

    def _error(self, s, token):
        print s, "in file", self.filename, "at line", self.get_lineno()
        self.errors_cnt += 1

    states = (
        ('packetdata', 'exclusive'),
    )

    keywords = (
        'ADD',
        'ALL',
        'BYTES',
        'CHECK_COUNTER',
        'EXPECT',
        'NO_PACKET',
        'PACKET',
        'PACKETS',
        'REMOVE',
        'SETDEFAULT',
        'WAIT'
    )

    keywords_map = {}
    for keyword in keywords:
        if keyword == 'P4_PARSING_DONE':
            keywords_map[keyword] = keyword
        else:
            keywords_map[keyword.lower()] = keyword

    tokens = (
        'COLON',
        'COMMA',
        'DATA_DEC',
        'DATA_HEX',
        'DATA_TERN',
        'DOT',
        'ID',
        'INT_CONST_BIN',
        'INT_CONST_DEC',
        'TERN_CONST_HEX',
        'INT_CONST_HEX',
        'LPAREN',
        'RPAREN',
        'SLASH',
        'EQUAL',
        'EQEQ',
        'LE',
        'LEQ',
        'GT',
        'GEQ',
        'NEQ'
    ) + keywords

    t_ignore_COMMENT = r'\#.*'
    t_COLON     = r':'
    t_COMMA     = r','
    t_DOT       = r'\.'
    t_LPAREN    = r'\('
    t_RPAREN    = r'\)'
    t_EQUAL     = r'='
    t_EQEQ      = r'=='
    t_NEQ       = r'!='
    t_LE        = r'<'
    t_LEQ       = r'<='
    t_GT        = r'>'
    t_GEQ       = r'>='
    t_SLASH     = r'/'

    # binary constants with ternary (don't care) bits
    binary_constant     = r'(0[bB][*01]+)'

    hex_prefix          = r'0[xX]'
    hex_digits          = r'[0-9a-fA-F]'
    hex_constant_body   = r'(' + hex_digits + r'+)'
    hex_constant        = r'(' + hex_prefix + hex_constant_body + r')'

    hex_tern            = r'([0-9a-fA-F\*]+)'
    hex_tern_constant   = r'(' + hex_prefix + hex_tern + r')'

    dec_constant        = r'([0-9]+)'

    identifier          = r'([a-z$A-Z_][a-z$A-Z_0-9]*)'

#    @TOKEN(NO_PACKET)
#    def t_NO_PACKET(self, t):
#        return t

    @TOKEN(hex_tern_constant)
    def t_TERN_CONST_HEX(self, t):
        return t

    @TOKEN(hex_constant)
    def t_INT_CONST_HEX(self, t):
        return t

    @TOKEN(binary_constant)
    def t_INT_CONST_BIN(self, t):
        return t

    @TOKEN(dec_constant)
    def t_INT_CONST_DEC(self, t):
        return t

    @TOKEN(identifier)
    def t_ID(self, t):
        typ = self.keywords_map.get(t.value.lower(), "ID")
        t.type = typ
        if typ == 'EXPECT' or typ == 'PACKET':
            t.lexer.begin('packetdata')
        return t

    # Discard comments.
    def t_COMMENT(self, t):
        r'\#.*$'
        pass

    # Track line numbers.
    def t_newline(self, t):
        r'\n+'
        t.lexer.lineno += len(t.value)
        t.lexer.colno = 0

    # Ignore spaces and tabs.
    t_ignore = ' \t'

    # Error handling.
    def t_error(self, t):
        self._error("Illegal character '%s'" % t.value[0], t)

    # PACKET DATA ------------------------------------------------------------

    @TOKEN(dec_constant)
    def t_packetdata_DATA_DEC(self, t):
        return t

    @TOKEN(hex_constant_body)
    def t_packetdata_DATA_HEX(self, t):
        return t

    def t_packetdata_DATA_TERN(self, t):
        r'\*'
        return t

    def t_packetdata_newline(self, t):
        r'\n+'
        t.lexer.lineno += len(t.value)
        t.lexer.begin('INITIAL')

    # Ignore spaces and tabs.
    t_packetdata_ignore = ' \t'

    # Error handling.
    def t_packetdata_error(self, t):
        self._error('invalid packet data', t)
