module ast::lexer;

import ast::utils;
import std::io;
import std::math;
import std::collections::list;

// Copyright (c) 2019 Christoffer Lerno. All rights reserved.
// Copyright (c) 2025 Alex Veden <i@alexveden.com>. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the LICENSE_STDLIB file.


enum LexMode
{
    LEX_NORMAL,
    LEX_CONTRACTS,
}

const int MAX_SOURCE_LOCATION_LEN = 255;


struct Lexer
{
    Token token;
    char* file_begin;
    char* lexing_start;
    char* current;
    char* line_start;
    char* start_row_start;
    uint file_len;
    uint current_row;
    uint start_row;
    LexMode mode;
    bool is_whitespace_mode;
}


<*
 Initializes new lexer instance

 @param contents : `c3 source contents`
*>
fn void init(Lexer* lexer, String contents)
{
	*lexer = {
		// Set the current file.
		// .file_begin = lexer.file.contents;
		
		.file_begin = contents,
		.file_len = contents.len,
		
		// Set current to beginning.
		.current = contents,
		
		// Line start is current.
		.line_start = contents,
		
		// Row number starts at 1
		.current_row = 1,
		
		// File id is the current file.
		// .tok_span.file_id = .file.file_id,
		
		// Mode is NORMAL
		.mode = LEX_NORMAL
	};
	
    // *lexer = Lexer{};
    // // Set the current file.
    // // lexer.file_begin = lexer.file.contents;
    // lexer.file_begin = contents;
    // lexer.file_len = contents.len;
    // // Set current to beginning.
    // lexer.current = lexer.file_begin;
    // // Line start is current.
    // lexer.line_start = lexer.current;
    // // Row number starts at 1
    // lexer.current_row = 1;
    // // File id is the current file.
    // // lexer.tok_span.file_id = lexer.file.file_id;
    // // Mode is NORMAL
    // lexer.mode = LEX_NORMAL;
	
    // Set up lexing for a new token.
    begin_new_token(lexer);
}

fn void Lexer.set_whitespace_mode(&self, bool is_enabled)
{
    self.is_whitespace_mode = is_enabled;
}

<*
 Parses next token in a code

 @return `true if token found, false - EOF reached or error`
*>
fn bool Lexer.next_token(&self)
{
    if (self.token.type == EOF) 
	{
        return false;
    }
    // Scan for a token.
    if (lexer_scan_token_inner(self)) return true;
    // Failed, so check if we're at end:
    if (reached_end(self)) return true;
    // Scan through the rest of the text for other invalid tokens:
    bool token_is_ok = false;
	
    do {
        if (!token_is_ok) 
		{
            // Scan to the end of the line if we have an error.
            while (!reached_end(self) && peek(self) != '\n') next(self);
        }
        token_is_ok = lexer_scan_token_inner(self);
    } 
	while(!reached_end(self));
	
    // Done.
    return false;
}

//===========================================
// 	Lexing general methods.
//===========================================

<*
 Peek at the current character in the buffer.
*>
macro char peek(lexer) 
{
    return (*(lexer).current);
}

<*
 Look at the prev character in the buffer.
*>
macro char prev(lexer) 
{
    return ((lexer).current[-1]);
}

<* 
 Peek one character ahead.
*>
macro char peek_next(lexer) 
{
    return ((lexer).current[1]);
}

<*
 Is the current character '\0' if so we assume we reached the end.
*>
macro bool reached_end(lexer)
{
    return (lexer.current >= (lexer.file_begin + lexer.file_len) || lexer.current[0] == '\0');
}

<* 
 Step one character forward and return that character
*>
fn char next(Lexer* lexer) @inline
{
    if (@unlikely(*lexer.current == '\n')) 
	{
        lexer.line_start = lexer.current + 1;
        lexer.current_row++;
    }
    lexer.current++;
    if (@unlikely(lexer.current >= (lexer.file_begin + lexer.file_len))) 
	{
        return '\0';
    }
    return (lexer.current)[0];
}

<* 
 Backtrack the buffer read one step.
*>
fn void backtrack(Lexer* lexer) @inline 
{
    lexer.current--;
    if (lexer.current[0] == '\n') 
	{
        lexer.current_row--;
    }
}

<* 
 Skip the x next characters.
*>
fn void skip(Lexer* lexer, int steps) @inline 
{
    assert(steps > 0);
    for (int i = 0; i < steps; i++) 
	{
        next(lexer);
    }
}

<* 
 Match a single character – if successful, more one step forward.
*>
fn bool match(Lexer* lexer, char expected) @inline 
{
    if (lexer.current[0] != expected) return false;
    next(lexer);
    return true;
}



//===========================================

fn bool lexer_scan_token_inner(Lexer* lexer) 
{
    if (skip_whitespace(lexer)) 
	{
        // Now skip the whitespace (but check for comments).
        return true;
    }

    // Point start to the first non-whitespace character.
    begin_new_token(lexer);

    if (reached_end(lexer)) 
	{
        new_token(lexer, EOF, "\n");
        return false;
    }

    ichar c = peek(lexer);
    next(lexer);
    switch (c) 
	{
        case '\n':
            assert(lexer.mode == LEX_CONTRACTS);
            return new_token(lexer, DOCS_EOL, "\n");
        case '@':
            if (utils::char_is_letter_(peek(lexer))) 
			{
                return scan_ident(lexer, AT_IDENT, AT_CONST_IDENT, AT_TYPE_IDENT, '@');
            }
            return new_token(lexer, AT, "@");
        case '\'':
            return scan_char(lexer);
        case '`':
            return scan_raw_string(lexer);
        case '"':
            return scan_string(lexer);
        case '#':
            return scan_ident(lexer, HASH_IDENT, HASH_CONST_IDENT, HASH_TYPE_IDENT, '#');
        case '$':
            if (match(lexer, '$')) 
			{
                if (utils::char_is_letter(peek(lexer))) 
				{
                    return scan_ident(lexer, BUILTIN, BUILTIN, BUILTIN, '#');
                }
                return add_error_token_at_current(lexer, "Expected a letter after $$.");
            } 
			else 
			{
                return scan_ident(lexer, CT_IDENT, CT_CONST_IDENT, CT_TYPE_IDENT, '$');
            }
        case ',':
            return new_token(lexer, COMMA, ",");
        case ';':
            return new_token(lexer, EOS, ";");
        case '{':
            return match(lexer, '|') ? new_token(lexer, LBRAPIPE, "{|") : new_token(lexer, LBRACE, "{");
        case '}':
            return new_token(lexer, RBRACE, "}");
        case '(':
            return new_token(lexer, LPAREN, "(");
            // return match(lexer, '<') ? new_token(lexer, LGENPAR, "(<") : new_token(lexer, LPAREN, "(");
        case ')':
            return new_token(lexer, RPAREN, ")");
        case '[':
            if (match(lexer, '<')) return new_token(lexer, LVEC, "[<");
            return new_token(lexer, LBRACKET, "[");
        case ']':
            return new_token(lexer, RBRACKET, "]");
        case '.':
            if (match(lexer, '.')) 
			{
                if (match(lexer, '.')) return new_token(lexer, ELLIPSIS, "...");
                return new_token(lexer, DOTDOT, "..");
            }
            return new_token(lexer, DOT, ".");
        case '~':
            return new_token(lexer, BIT_NOT, "~");
        case ':':
            return match(lexer, ':') ? new_token(lexer, SCOPE, "::") : new_token(lexer, COLON, ":");
        case '!':
            if (match(lexer, '!')) return new_token(lexer, BANGBANG, "!!");
            return match(lexer, '=') ? new_token(lexer, NOT_EQUAL, "!=") : new_token(lexer, BANG, "!");
        case '/':
            return match(lexer, '=') ? new_token(lexer, DIV_ASSIGN, "/=") : new_token(lexer, DIV, "/");
        case '*':
            if (lexer.mode == LEX_CONTRACTS && match(lexer, '>')) 
			{
                lexer.mode = LEX_NORMAL;
                return new_token(lexer, DOCS_END, "*>");
            }
            return match(lexer, '=') ? new_token(lexer, MULT_ASSIGN, "*=") : new_token(lexer, STAR, "*");
				
        case '=':
            if (match(lexer, '>')) return new_token(lexer, IMPLIES, "=>");
            return match(lexer, '=') ? new_token(lexer, EQEQ, "==") : new_token(lexer, EQ, "=");
			
        case '^':
            return match(lexer, '=') ? new_token(lexer, BIT_XOR_ASSIGN, "^=") : new_token(lexer, BIT_XOR, "^");
        case '?':
            if (match(lexer, '?')) return new_token(lexer, QUESTQUEST, "??");
            return match(lexer, ':') ? new_token(lexer, ELVIS, "?:") : new_token(lexer, QUESTION, "?");
        case '<':
            if (match(lexer, '<')) 
			{
                if (match(lexer, '=')) return new_token(lexer, SHL_ASSIGN, "<<=");
                return new_token(lexer, SHL, "<<");
            }
            if (lexer.mode == LEX_NORMAL && match(lexer, '*')) 
			{
                return parse_doc_start(lexer);
            }
            return match(lexer, '=') ? new_token(lexer, LESS_EQ, "<=") : new_token(lexer, LESS, "<");
        case '>':
            if (match(lexer, '>')) 
			{
                if (match(lexer, '=')) return new_token(lexer, SHR_ASSIGN, ">>=");
                return new_token(lexer, SHR, ">>");
            }
            // if (match(lexer, ')')) return new_token(lexer, RGENPAR, ">)");
            if (match(lexer, ']')) return new_token(lexer, RVEC, ">]");
            
			return match(lexer, '=') ? new_token(lexer, GREATER_EQ, ">=") : new_token(lexer, GREATER, ">");
			
        case '%':
            return match(lexer, '=') ? new_token(lexer, MOD_ASSIGN, "%=") : new_token(lexer, MOD, "%");
			
        case '&':
            if (match(lexer, '&')) 
			{
                return match(lexer, '&') ? new_token(lexer, CT_AND, "&&&") : new_token(lexer, AND, "&&");
            }
            return match(lexer, '=') ? new_token(lexer, BIT_AND_ASSIGN, "&=") : new_token(lexer, AMP, "&");
        case '|':
            if (match(lexer, '}')) return new_token(lexer, RBRAPIPE, "|}");
            if (match(lexer, '|')) 
			{
                return match(lexer, '|') ? new_token(lexer, CT_OR, "|||") : new_token(lexer, OR, "||");
            }
            return match(lexer, '=') ? new_token(lexer, BIT_OR_ASSIGN, "|=") : new_token(lexer, BIT_OR, "|");
        case '+':
            if (match(lexer, '+')) 
			{
                if (match(lexer, '+')) return new_token(lexer, CT_CONCAT, "+++");
                return new_token(lexer, PLUSPLUS, "++");
            }
            if (match(lexer, '=')) return new_token(lexer, PLUS_ASSIGN, "+=");
            return new_token(lexer, PLUS, "+");
        case '-':
            if (match(lexer, '>')) return new_token(lexer, ARROW, ".");
            if (match(lexer, '-')) return new_token(lexer, MINUSMINUS, "--");
            if (match(lexer, '=')) return new_token(lexer, MINUS_ASSIGN, "-=");
            return new_token(lexer, MINUS, "-");
        case 'x':
            if ((peek(lexer) == '"' || peek(lexer) == '\'' || peek(lexer) == '`')) 
			{
                return scan_hex_array(lexer);
            }
            // goto IDENT;
            nextcase '_';
        case 'b':
            if (
                peek(lexer) == '6' &&
                peek_next(lexer) == '4' &&
                (lexer.current[2] == '\'' || lexer.current[2] == '"' || lexer.current[2] == '`')
            ) 
			{
                return scan_base64(lexer);
            }
            // goto IDENT;
            nextcase '_';
        case '_':
            // IDENT:
            backtrack(lexer);
            return scan_ident(lexer, IDENT, CONST_IDENT, TYPE_IDENT, 0);
        default:
            if (c >= '0' && c <= '9') 
			{
                backtrack(lexer);
                return scan_digit(lexer);
            }
            if (c >= 'a' && c <= 'z') nextcase '_';  // goto IDENT;
            if (c >= 'A' && c <= 'Z') nextcase '_';  // goto IDENT;
            if (c < 0) 
			{
                return add_error_token(
                    lexer,
                    "The 0x ?? character may not be placed outside of a string or comment, did you forget a \" somewhere?"
                );
            }
            return add_error_token(
                lexer,
                "char may not be placed outside of a string or comment, did you perhaps forget a \" somewhere?"
            );

    }
}


<*
 Parses lexer contents and returns new list of all available tokens

 @param allocator : "optional allocator for resulting list"
 @return "list of all tokens in lexer string"
*>
fn List{Token} Lexer.new_parse_tokens(&self, Allocator allocator = mem)
{
    assert(self.file_begin, "not initialied");
    assert(self.file_begin == self.current, "already processed");

    List{Token} result;
    result.init(allocator: allocator);

    while (self.next_token()) 
	{
        result.push(self.token);
    }
    return result;
}


//=================================
// --- Token creation
//=================================

fn void begin_new_token(Lexer* lexer) @inline 
{
    lexer.lexing_start = lexer.current;
    lexer.start_row = lexer.current_row;
    lexer.start_row_start = lexer.line_start;
}

<* 
 Add a new regular token.
*>
fn bool new_token(Lexer* lexer, TokenType type, String string) @inline 
{
    set_generic_token(lexer, type, string);
    return true;
}

<*
 Allocate data for a token, including source location.
 This call is doing the basic allocation, with other functions
 filling out additional information.
*>
fn void set_generic_token(Lexer* lexer, TokenType type, String value) @inline 
{
    assert(lexer.lexing_start >= lexer.file_begin);

    lexer.token.type = type;
    // Set the location.
    lexer.token.value = value;
    lexer.token.offset = (uint)(lexer.lexing_start - lexer.file_begin);
    uint line = lexer.start_row;
    uint col;
    uint length;
    if (line == lexer.current_row) 
	{
        // Col is simple difference.
        assert(lexer.lexing_start >= lexer.line_start);
        col = (uint)(lexer.lexing_start - lexer.line_start) + 1;

        // Length is diff between current and start.
        assert(lexer.current >= lexer.lexing_start);
        length = (uint)(lexer.current - lexer.lexing_start);
    } 
	else 
	{
        // For multiline, we grab the diff from the starting line.
        assert(lexer.lexing_start >= lexer.start_row_start);
        col = (uint)(lexer.lexing_start - lexer.start_row_start) + 1;
        // But always set a single token length.
        length = 1;
    }
    lexer.token.col = col;
    lexer.token.row = line;
}

<*
 Error? We simply generate an invalid token and print out the error.
*>
macro bool add_error_token(Lexer* lexer, String message) 
{

    set_generic_token(lexer, INVALID_TOKEN, message);
    return false;
}

<*
 Error at the start of the lexing, with a single length.
*>
macro bool add_error_token_at_start(Lexer* lexer, String message) 
{
    set_generic_token(lexer, INVALID_TOKEN, message);
    return false;
}

<*
 Create an error token at a particular place in the file.
 used for pointing out errors in strings etc.
*>
macro bool add_error_token_at(Lexer* lexer, char* loc, isz len, String message) 
{
    set_generic_token(lexer, INVALID_TOKEN, message);
    return false;
}

<*
 Print an error at the current location.
*>
macro bool add_error_token_at_current(Lexer* lexer, String message) 
{
    set_generic_token(lexer, INVALID_TOKEN, message);
    return false;
}


fn TokenType token_from_identifier(String indentifier)
{
    switch (indentifier) 
	{
        case "asm":
            return ASM;
        case "bitstruct":
            return BITSTRUCT;
        case "break":
            return BREAK;
        case "case":
            return CASE;
        case "catch":
            return CATCH;
        case "const":
            return CONST;
        case "continue":
            return CONTINUE;
        case "def":
            return DEF;
        case "default":
            return DEFAULT;
        case "defer":
            return DEFER;
        case "distinct":
            return DISTINCT;
        case "do":
            return DO;
        case "else":
            return ELSE;
        case "enum":
            return ENUM;
        case "extern":
            return EXTERN;
        case "false":
            return FALSE;
        case "fault":
            return FAULT;
        case "for":
            return FOR;
        case "foreach":
            return FOREACH;
        case "foreach_r":
            return FOREACH_R;
        case "fn":
            return FN;
        case "if":
            return IF;
        case "inline":
            return INLINE;
        case "interface":
            return INTERFACE;
        case "import":
            return IMPORT;
        case "macro":
            return MACRO;
        case "module":
            return MODULE;
        case "nextcase":
            return NEXTCASE;
        case "null":
            return NULL;
        case "return":
            return RETURN;
        case "static":
            return STATIC;
        case "struct":
            return STRUCT;
        case "switch":
            return SWITCH;
        case "true":
            return TRUE;
        case "try":
            return TRY;
        case "typeid":
            return TYPEID;
        case "union":
            return UNION;
        case "while":
            return WHILE;
        case "assert":
            return IDENT;
        case "tlocal":
            return TLOCAL;
            // Types
        case "anyfault":
        case "var":
        case "void":
        case "any":
        case "bool":
        case "float128":
        case "double":
        case "float":
        case "bfloat":
        case "float16":
        case "long":
        case "ulong":
        case "int128":
        case "uint128":
        case "int":
        case "uint":
        case "short":
        case "ushort":
        case "ichar":
        case "char":
        case "isz":
        case "usz":
        case "iptr":
        case "uptr":
            return TYPE_IDENT;
        case "$alignof":
        case "$and":
        case "$append":
        case "$assert":
        case "$assignable":
        case "$concat":
        case "$eval":
        case "$defined":
        case "$embed":
        case "$evaltype":
        case "$error":
        case "$exec":
        case "$extnameof":
        case "$feature":
        case "$is_const":
        case "$include":
        case "$vacount":
        case "$vatype":
        case "$vaconst":
        case "$vaarg":
        case "$varef":
        case "$vaexpr":
        case "$vasplat":
        case "$nameof":
        case "$offsetof":
        case "$or":
        case "$qnameof":
        case "$sizeof":
        case "$typefrom":
        case "$stringify":
        case "$echo":
            return CT_IDENT;
        case "$typeof":
            return CT_TYPEOF;

            // ------
        case "$if":
            return CT_IF;
        case "$else":
            return CT_ELSE;
        case "$endif":
            return CT_ENDIF;
        case "$for":
            return CT_FOR;
        case "$endfor":
            return CT_ENDFOR;
        case "$foreach":
            return CT_FOREACH;
        case "$endforeach":
            return CT_ENDFOREACH;
        case "$switch":
            return CT_SWITCH;
        case "$case":
            return CT_CASE;
        case "$default":
            return CT_DEFAULT;
        case "$endswitch":
            return CT_ENDSWITCH;
        default:
            return INVALID_TOKEN;
    }
}


//=========================================
// Unused struct definitions
//=========================================

// union SourceSpan
// {
//     struct
//     {
//         char length;
//         uint col;
//         uint row;
//     }
//     ulong a;
// }

// struct TokenData 
// {
//     char* lex_start;
//     usz lex_len;
//     union
//     {
//         struct
//         {
//             String string;
//         }
//         struct
//         {
//             float value;
//         }
//         bitstruct : ulong
//         {
//             bool is_base64 : 0..0;
//             ulong bytes_len : 1..63;
//         }
//         struct
//         {
//             int128 char_value;
//             char width;
//         }
//     }
// }