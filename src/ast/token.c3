module ast::lexer;

import std::io;

enum TokenType : uint
{
    INVALID_TOKEN,

    // Single-character tokens.
    AMP,  // &
    AT,  // @
    BANG,  // !
    BIT_NOT,  // ~
    BIT_OR,  // =
    BIT_XOR,  // ^
    COLON,  // :
    COMMA,  // ,
    EOS,  // ;
    EMPTY_LINE,  // a line with only white spaces (useful for code formatting)
    EQ,  // =
    GREATER,  // >
    DIV,  // /
    DOLLAR,  // $
    DOT,  // .
    HASH,  // #
    LESS,  // <
    LBRACE,  // {
    LBRACKET,  // [
    LPAREN,  // (
    MINUS,  // -
    MOD,  // %
    PLUS,  // +
    QUESTION,  // ?
    RBRACE,  // }
    RBRACKET,  // ]
    RPAREN,  // )
    STAR,  // *
    UNDERSCORE,  // _
    SPACE,  // ' '

    // two character tokens.
    AND,  // &&
    ARROW,  // -> // Not used but reserved
    BANGBANG,  // !!
    BIT_AND_ASSIGN,  // &=
    BIT_OR_ASSIGN,  // |=
    BIT_XOR_ASSIGN,  // ^=
    DIV_ASSIGN,  // /=
    DOTDOT,  // ..
    BUILTIN,  // $$
    ELVIS,  // ?:
    EQEQ,  // ==
    GREATER_EQ,  // >=
    IMPLIES,  // =>
    LESS_EQ,  // <=
    LBRAPIPE,  // {|
    LGENPAR,  // (<
    LVEC,  // [<
    MINUS_ASSIGN,  // -=
    MINUSMINUS,  // --
    MOD_ASSIGN,  // %=
    MULT_ASSIGN,  // *=
    NOT_EQUAL,  // !=
    OR,  // ||
    PLUS_ASSIGN,  // +=
    PLUSPLUS,  // ++
    RBRAPIPE,  // |}
    RGENPAR,  // >)
    RVEC,  // >]
    QUESTQUEST,  // ??
    SCOPE,  // ::
    SHL,  // <<
    SHR,  // >>

    // Three or more
    ELLIPSIS,  // ...
    SHL_ASSIGN,  // <<=
    SHR_ASSIGN,  // >>=
    CT_AND,  // &&&
    CT_CONCAT,  // +++
    CT_OR,  // |||
    // Literals.
    IDENT,  // Any normal ident.
    CONST_IDENT,  // Any purely uppercase ident,
    TYPE_IDENT,  // Any ident on the format FooBar or __FooBar

    // We want to parse $foo separately,
    // otherwise we allow things like "$ foo" which would be pretty bad.
    CT_IDENT,  // $foobar
    CT_CONST_IDENT,  // $FOOBAR
    CT_TYPE_IDENT,  // $Foobar

    // We want to parse #foo separately.
    HASH_IDENT,  // #foobar
    HASH_CONST_IDENT,  // #FOOBAR
    HASH_TYPE_IDENT,  // #Foobar

    AT_IDENT,  // @macro
    AT_CONST_IDENT,  // @MACRO
    AT_TYPE_IDENT,  // @Macro

    COMMENT_SINGLE_INLINE,  // //single INLINE comment
    COMMENT_SINGLE,  // //single line comment
    COMMENT_MULTI,  //  /* multiline on new line */
    COMMENT_MULTI_INLINE,  //  some /* multiline on the same line */

    STRING,  // "Teststring"
    RAW_STRING,  // `Teststring`
    INTEGER,  // 123 0x23 0b10010 0o327
    CHAR_LITERAL,  // 'a' 'FO' 'BARS' '\u1232'
    REAL,  // 0x23.2p-2a 43.23e23
    BYTES,  // Base64 or Hex

    DOC_COMMENT,  // Doc Comment start

    // Basic types names
    VOID,
    // FIRST_KEYWORD = TOKEN_VOID,
    BOOL,
    CHAR,
    DOUBLE,
    FLOAT,
    FLOAT16,
    BFLOAT,
    INT128,
    ICHAR,
    INT,
    IPTR,
    ISZ,
    LONG,
    SHORT,
    UINT128,
    UINT,
    ULONG,
    UPTR,
    USHORT,
    USZ,
    FLOAT128,
    ANY,
    ANYFAULT,
    TYPEID,

    // Keywords
    ASSERT,
    ASM,
    STRUCT,
    DEF,
    DISTINCT,
    BITSTRUCT,
    FAULT,
    UNION,
    BREAK,
    CASE,
    CATCH,
    CONTINUE,
    DEFAULT,
    DEFER,
    DO,
    ELSE,
    ENUM,
    EXTERN,
    FALSE,
    FOR,
    FOREACH,
    FOREACH_R,
    FN,
    TLOCAL,
    IF,
    INLINE,
    IMPORT,
    MACRO,
    MODULE,
    NEXTCASE,
    NULL,
    INTERFACE,
    RETURN,
    STATIC,
    SWITCH,
    TRUE,
    TRY,
    VAR,
    WHILE,
    CONST,
    // LAST_NON_CT_KEYWORD = TOKEN_WHILE,

    CT_ALIGNOF,  // $alignof
    CT_ANDFN,  // $and
    CT_APPEND,  // $append
    CT_ASSERT,  // $assert
    CT_ASSIGNABLE,  // $assignable
    CT_CASE,  // $case
    CT_CONCATFN,  // $concat
    CT_DEFAULT,  // $default
    CT_DEFINED,  // $defined
    CT_ECHO,  // $echo
    CT_ELSE,  // $else
    CT_EMBED,  // $embed
    CT_ENDFOR,  // $endfor
    CT_ENDFOREACH,  // $endforeach
    CT_ENDIF,  // $endif
    CT_ENDSWITCH,  // $endswitch
    CT_EVAL,  // $eval
    CT_EVALTYPE,  // $evaltype
    CT_ERROR,  // $error
    CT_EXEC,  // $exec
    CT_EXTNAMEOF,  // $extnameof
    CT_FEATURE,  // $feature
    CT_FOR,  // $for
    CT_FOREACH,  // $foreach
    CT_IF,  // $if
    CT_INCLUDE,  // $include
    CT_IS_CONST,  // $is_const
    CT_NAMEOF,  // $nameof
    CT_OFFSETOF,  // $offsetof
    CT_ORFN,  // $or
    CT_QNAMEOF,  // $qnameof
    CT_SIZEOF,  // $sizeof
    CT_STRINGIFY,  // $stringify
    CT_SWITCH,  // $switch
    CT_TYPEFROM,  // $typefrom
    CT_TYPEOF,  // $typeof
    CT_VACOUNT,  // $vacount
    CT_VATYPE,  // $vatype
    CT_VACONST,  // $vaconst,
    CT_VAREF,  // $varef,
    CT_VAARG,  // $vaarg,
    CT_VAEXPR,  // $vaexpr,
    CT_VASPLAT,  // $vasplat,
    // LAST_KEYWORD = TOKEN_CT_VASPLAT,
    DOCS_START,  // <*
    DOCS_END,  // *>
    DOCS_EOL,

    EOF,  // \n - SHOULD ALWAYS BE THE LAST TOKEN.

    // LAST = TOKEN_EOF,
}


struct Token (Printable)
{
    String value;
    TokenType type;
    uint row;
    uint col;
    uint offset;
}


fn String Token.to_string(&self, Allocator allocator) @dynamic
{
	// DString builder = dstring::temp();
	// builder.appendf("{\n");
	// builder.appendf("    type: %s\n", self.type);
	// builder.appendf("    value: `%s`\n", self.value);
	// builder.appendf("    row: %s\n", self.row);
	// builder.appendf("    col: %s\n", self.col);
	// builder.appendf("    offset: %s\n", self.offset);
	// builder.appendf("}\n");
	// return builder.copy_str(allocator);
	return string::format(
		allocator,
`{
	type: %s
	value: '%s'
	row: %s
	col: %s
	offset: %s
}`,
	self.type,
	self.value,
	self.row,
	self.col,
	self.offset,
	);
}

fn void Token.print(&self, bool new_line = false, int padding = 0)
{
    assert(padding >= 0);

    usz plen = 0;
    switch (self.type) 
	{
        case IDENT:
        case CT_IDENT:
        case CT_CONST_IDENT:
        case CT_TYPE_IDENT:
        case HASH_IDENT:
        case HASH_CONST_IDENT:
        case HASH_TYPE_IDENT:
        case CONST_IDENT:
        case TYPE_IDENT:
        case AT_IDENT:
        case AT_TYPE_IDENT:
        case AT_CONST_IDENT:
            plen = io::printf("%s[%s]", token_type_to_string(self.type), self.value)!!;
            // break;
			
        case STRING:
        case RAW_STRING:
        case INTEGER:
        case REAL:
        case CHAR_LITERAL:
        case BYTES:
            plen = io::printf("%s[%s]", token_type_to_string(self.type), self.value)!!;
            // break;
			
        case DOCS_START:
        case COMMENT_SINGLE:
        case COMMENT_SINGLE_INLINE:
        case COMMENT_MULTI:
        case COMMENT_MULTI_INLINE:
            plen = io::printf("%s`#%d`", token_type_to_string(self.type), self.value.len)!!;
            // break;
			
        case EOS:
        case EOF:
        case EMPTY_LINE:
            plen = io::printf("%s", token_type_to_string(self.type))!!;
            // break;
			
        default:
            plen = io::printf("%s", token_type_to_string(self.type))!!;
    }

    if (padding > 0) 
	{
        assert(plen > 0);
        for (int i = 0; i < padding - plen; i++) 
		{
            io::print(" ");
        }
    }

    if (new_line) 
	{
        io::print("\n");
    } 
	else 
	{
        io::print(" ");
    }

}


fn String token_type_to_string(TokenType type)
{
    switch (type) 
	{
        case INVALID_TOKEN:
            return "INVALID_TOKEN";

            // One character tokens
        case AMP:
            return "&";
        case AT:
            return "@";
        case BIT_NOT:
            return "~";
        case BIT_OR:
            return "|";
        case BIT_XOR:
            return "^";
        case COLON:
            return ":";
        case COMMA:
            return ",";
        case DIV:
            return "/";
        case DOLLAR:
            return "$";
        case DOT:
            return ".";
        case EOS:
            return ";";
        case EMPTY_LINE:
            return "<EMPTY_LINE>";
        case EQ:
            return "=";
        case GREATER:
            return ">";
        case HASH:
            return "#";
        case LBRACE:
            return "{";
        case LBRACKET:
            return "[";
        case LESS:
            return "<";
        case LPAREN:
            return "(";
        case MINUS:
            return "-";
        case MOD:
            return "%";
        case BANG:
            return "!";
        case PLUS:
            return "+";
        case QUESTION:
            return "?";
        case RBRACE:
            return "}";
        case RBRACKET:
            return "]";
        case RPAREN:
            return ")";
        case STAR:
            return "*";
        case UNDERSCORE:
            return "_";
        case SPACE:
            return " ";

            // Two character tokens
        case AND:
            return "&&";
        case ARROW:
            return "->";
        case BIT_AND_ASSIGN:
            return "&=";
        case BIT_OR_ASSIGN:
            return "|=";
        case BIT_XOR_ASSIGN:
            return "^=";
        case BUILTIN:
            return "$$";
        case CT_AND:
            return "&&&";
        case CT_OR:
            return "|||";
        case CT_CONCAT:
            return "+++";
        case DIV_ASSIGN:
            return "/=";
        case DOTDOT:
            return "..";
        case ELVIS:
            return "?:";
        case EQEQ:
            return "==";
        case GREATER_EQ:
            return ">=";
        case IMPLIES:
            return "=>";
        case LESS_EQ:
            return "<=";
        case LBRAPIPE:
            return "{|";
        case LGENPAR:
            return "(<";
        case LVEC:
            return "[<";
        case MINUS_ASSIGN:
            return "-=";
        case MINUSMINUS:
            return "--";
        case MULT_ASSIGN:
            return "*=";
        case MOD_ASSIGN:
            return "%=";
        case NOT_EQUAL:
            return "!=";
        case OR:
            return "||";
        case PLUS_ASSIGN:
            return "+=";
        case PLUSPLUS:
            return "++";
        case QUESTQUEST:
            return "??";
        case RBRAPIPE:
            return "|}";
        case RGENPAR:
            return ">)";
        case RVEC:
            return ">]";
        case SCOPE:
            return "::";
        case SHL:
            return "<<";
        case SHR:
            return ">>";
        case BANGBANG:
            return "!!";

            // Three character tokens
        case ELLIPSIS:
            return "...";
        case SHL_ASSIGN:
            return "<<=";
        case SHR_ASSIGN:
            return ">>=";

            // Identifiers
        case IDENT:
            return "IDENT";
        case CT_IDENT:
            return "CT_IDENT";
        case CT_CONST_IDENT:
            return "CT_CONST_IDENT";
        case CT_TYPE_IDENT:
            return "CT_TYPE_IDENT";
        case HASH_IDENT:
            return "HASH_IDENT";
        case HASH_CONST_IDENT:
            return "HASH_CONST_IDENT";
        case HASH_TYPE_IDENT:
            return "HASH_TYPE_IDENT";
        case CONST_IDENT:
            return "CONST_IDENT";
        case TYPE_IDENT:
            return "TYPE_IDENT";

        case AT_IDENT:
            return "MACRO_IDENT";
        case AT_TYPE_IDENT:
            return "MACRO_TYPE_IDENT";
        case AT_CONST_IDENT:
            return "MACRO_CONST_IDENT";

            // Values
        case STRING:
            return "STRING";
        case RAW_STRING:
            return "RAW_STRING";
        case COMMENT_SINGLE:
            return "COMMENT_SINGLE";
        case COMMENT_SINGLE_INLINE:
            return "COMMENT_SINGLE_INLINE";
        case COMMENT_MULTI:
            return "COMMENT_MULTI";
        case COMMENT_MULTI_INLINE:
            return "COMMENT_MULTI_INLINE";
        case INTEGER:
            return "INTEGER";
        case REAL:
            return "FLOAT";
        case CHAR_LITERAL:
            return "CHAR_LITERAL";
        case BYTES:
            return "BYTES";

            // Comments
        case DOC_COMMENT:
            return "DOC_COMMENT";

            // Keywords
        case ANYFAULT:
            return "anyfault";
        case ASM:
            return "asm";
        case ASSERT:
            return "assert";
        case BITSTRUCT:
            return "bitstruct";
        case BREAK:
            return "break";
        case CASE:
            return "case";
        case CATCH:
            return "catch";
        case CONST:
            return "const";
        case CONTINUE:
            return "continue";
        case DEF:
            return "def";
        case DEFAULT:
            return "default";
        case DEFER:
            return "defer";
        case DISTINCT:
            return "distinct";
        case DO:
            return "do";
        case ELSE:
            return "else";
        case ENUM:
            return "enum";
        case EXTERN:
            return "extern";
        case FALSE:
            return "false";
        case FAULT:
            return "fault";
        case FOR:
            return "for";
        case FOREACH:
            return "foreach";
        case FOREACH_R:
            return "foreach_r";
        case FN:
            return "fn";
        case IF:
            return "if";
        case INLINE:
            return "inline";
        case INTERFACE:
            return "interface";
        case IMPORT:
            return "import";
        case MACRO:
            return "macro";
        case MODULE:
            return "module";
        case NEXTCASE:
            return "nextcase";
        case NULL:
            return "null";
        case RETURN:
            return "return";
        case STATIC:
            return "static";
        case STRUCT:
            return "struct";
        case SWITCH:
            return "switch";
        case TLOCAL:
            return "tlocal";
        case TRUE:
            return "true";
        case TRY:
            return "try";
        case TYPEID:
            return "typeid";
        case UNION:
            return "union";
        case VAR:
            return "var";
        case WHILE:
            return "while";

            // Named types
        case VOID:
            return "void";
        case ANY:
            return "any";
        case BOOL:
            return "bool";
        case FLOAT128:
            return "float128";
        case DOUBLE:
            return "double";
        case FLOAT:
            return "float";
        case BFLOAT:
            return "bfloat";
        case FLOAT16:
            return "float16";
        case LONG:
            return "long";
        case ULONG:
            return "ulong";
        case INT128:
            return "int128";
        case UINT128:
            return "uint128";
        case INT:
            return "int";
        case UINT:
            return "uint";
        case SHORT:
            return "short";
        case USHORT:
            return "ushort";
        case ICHAR:
            return "ichar";
        case CHAR:
            return "char";
        case ISZ:
            return "isz";
        case USZ:
            return "usz";
        case IPTR:
            return "iptr";
        case UPTR:
            return "uptr";
        case DOCS_START:
            return "<*";
        case DOCS_END:
            return "*>";
        case CT_ALIGNOF:
            return "$alignof";
        case CT_ANDFN:
            return "$and";
        case CT_APPEND:
            return "$append";
        case CT_ASSERT:
            return "$assert";
        case CT_ASSIGNABLE:
            return "$assignable";
        case CT_CASE:
            return "$case";
        case CT_CONCATFN:
            return "$concat";
        case CT_DEFAULT:
            return "$default";
        case CT_DEFINED:
            return "$defined";
        case CT_ELSE:
            return "$else";
        case CT_EMBED:
            return "$embed";
        case CT_ENDIF:
            return "$endif";
        case CT_ENDSWITCH:
            return "$endswitch";
        case CT_ENDFOR:
            return "$endfor";
        case CT_ENDFOREACH:
            return "$endforeach";
        case CT_EVAL:
            return "$eval";
        case CT_EVALTYPE:
            return "$evaltype";
        case CT_ERROR:
            return "$error";
        case CT_EXEC:
            return "$exec";
        case CT_EXTNAMEOF:
            return "$extnameof";
        case CT_FEATURE:
            return "$feature";
        case CT_FOR:
            return "$for";
        case CT_FOREACH:
            return "$foreach";
        case CT_IF:
            return "$if";
        case CT_IS_CONST:
            return "$is_const";
        case CT_INCLUDE:
            return "$include";
        case CT_VACOUNT:
            return "$vacount";
        case CT_VATYPE:
            return "$vatype";
        case CT_VACONST:
            return "$vaconst";
        case CT_VAARG:
            return "$vaarg";
        case CT_VAREF:
            return "$varef";
        case CT_VAEXPR:
            return "$vaexpr";
        case CT_VASPLAT:
            return "$vasplat";
        case CT_NAMEOF:
            return "$nameof";
        case CT_OFFSETOF:
            return "$offsetof";
        case CT_ORFN:
            return "$or";
        case CT_QNAMEOF:
            return "$qnameof";
        case CT_SIZEOF:
            return "$sizeof";
        case CT_SWITCH:
            return "$switch";
        case CT_TYPEFROM:
            return "$typefrom";
        case CT_TYPEOF:
            return "$typeof";
        case CT_STRINGIFY:
            return "$stringify";
        case CT_ECHO:
            return "$echo";
        case DOCS_EOL:
            return "<EOL>";
        case EOF:
            return "EOF";
        default:
            unreachable();

    }
}