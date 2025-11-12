module ast::lexer;

import std::math;

// tries to extent current AT_IDENT
// for handling @if(env::SOO || SOME) @export("something")
fn void Lexer.extend_current_attribute(Lexer* lexer)
{
    Token* result = &lexer.token;
    assert(lexer.token.type == AT_IDENT || lexer.token.type == AT_TYPE_IDENT);
    assert(
        math::abs(lexer.current - lexer.token.value.ptr) < 64,
        "this must be called AT_IDENT parsed"
    );
    assert(lexer.token.value);
    assert(lexer.token.value.ptr >= lexer.file_begin);
    assert(lexer.token.value.ptr < lexer.file_begin + lexer.file_len);

    int nesting = 0;
    int extra_len = 0;
    bool had_nesting = false;
    while LOOP: (!reached_end(lexer)) {
        char c = peek(lexer);
        // io::printf("current char: `%c`\n", c);
        switch (c) {
            case '(':
                nesting++;
                had_nesting = true;
            case ')':
                nesting--;
                if (nesting == 0) next(lexer);
                nextcase default;
            case ' ':
                break;
            default:
                if (nesting <= 0) {
                    if (had_nesting) {
                        result.value = (String)(
                            (char*)result.value.ptr
                        )[..result.value.len + extra_len];
                    }
                    break LOOP;
                }
        }
        extra_len++;
        next(lexer);
    }
    // unreachable();
}

//scan_ident Parses identifiers. Note that this is a bit complicated here since
// we split identifiers into 2 types + find keywords.
fn bool scan_ident(
    Lexer* lexer, TokenType normal, TokenType const_token, TokenType type_token, char prefix
) @inline 
{
    TokenType type = INVALID_TOKEN;
    char c;
    while ((c = peek(lexer)) == '_') {
        next(lexer);
    }
    while LOOP: (1) {
        c = peek(lexer);
        switch (c) {
            case 'a'..'z':
                if (type == INVALID_TOKEN) {
                    type = normal;
                } else if (type == const_token) {
                    type = type_token;
                }
                break;
            case 'A'..'Z':
                if (type == INVALID_TOKEN) type = const_token;
                break;
            case '0'..'9':
                if (type == INVALID_TOKEN) return add_error_token(lexer, "A letter must precede any digit");
            case '_':
                break;
            default:
                break LOOP;
        }
        next(lexer);
    }

    uint len = (uint)(lexer.current - lexer.lexing_start);
    if (type == INVALID_TOKEN) {
        if (!prefix && len == 1) return new_token(lexer, UNDERSCORE, "_");
        if (prefix && len == 1) {
            return add_error_token(lexer, "An identifier was expected ... ");
        }
        return add_error_token(lexer, "An identifier may not consist of only '_' characters.");
    }
    switch (type) {
        case RETURN:
            if (lexer.mode == LEX_CONTRACTS) type = IDENT;
            break;
        default:
            break;
    }
    String identifier = (String)lexer.lexing_start[..len - 1];
    TokenType ttype = lexer::token_from_identifier(identifier);
    if (ttype != INVALID_TOKEN) {
        type = ttype;
    }
    return new_token(lexer, type, identifier);
}
