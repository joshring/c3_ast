module ast::lexer;


// --- Comment parsing


<*
 Skip regular whitespace
*>
fn bool skip_whitespace(Lexer* lexer)
{
    bool has_empty_line = false;
    while LOOP: (!reached_end(lexer)) 
	{
        char c = peek(lexer);
        switch (c) 
		{
            case '/':
                has_empty_line = false;
                if (lexer.mode == LEX_CONTRACTS) return false;
                // The '//' case
                if (peek_next(lexer) == '/') 
				{
                    skip(lexer, 2);
                    if (parse_line_comment(lexer)) 
					{
                        return true;
                    }
                    continue;
                }
                // '/*'
                if (peek_next(lexer) == '*') 
				{
                    skip(lexer, 2);
                    if (parse_multiline_comment(lexer)) 
					{
                        return true;
                    }
                    continue;
                }
                return false;
            case '\n':
                // Contract lexing sees '\n' as a token
                if (lexer.mode == LEX_CONTRACTS) return false;
                if (has_empty_line) 
				{
                    begin_new_token(lexer);
                    return new_token(lexer, TokenType.EMPTY_LINE, "\n");
                }
                has_empty_line = true;

                nextcase;
            case ' ':
            case '\t':
            case '\f':
                if (lexer.is_whitespace_mode) 
				{
                    begin_new_token(lexer);
                    next(lexer);
                    uint len = (uint)(lexer.current - lexer.lexing_start);
                    return new_token(lexer, SPACE, (String)lexer.lexing_start[..len - 1]);
                }
                nextcase;
            case '\r':  // This is forbidden by c3 grammar, and should be skipped silently
                next(lexer);
                break;
            default:
                has_empty_line = false;
                return false;
        }
    }
    return false;
}

<*
 Parsing of the "//" line comment - skipping past the end
*>
fn bool parse_line_comment(Lexer* lexer) @inline
{
    backtrack(lexer);
    backtrack(lexer);
    bool has_new_line = (lexer.current == lexer.file_begin);
    begin_new_token(lexer);

    while (!reached_end(lexer) && peek(lexer) != '\n') 
	{
        next(lexer);
    }

    char* cur = lexer.lexing_start - 1;
    while LOOP: (cur >= lexer.file_begin) 
	{
        switch (*cur) 
		{
            case ' ':
            case '\t':
                break;
            case '\n':
                has_new_line = true;
                break LOOP;
            default:
                break LOOP;
        }
        cur--;
    }
    uint len = (uint)(lexer.current - lexer.lexing_start);
    if (lexer.lexing_start[len - 1] == '\n') len--;

    return new_token(
        lexer,
        has_new_line ? COMMENT_SINGLE : COMMENT_SINGLE_INLINE,
        (String)lexer.lexing_start[..len - 1]
    );
}

<*
 Parse the common / *  * / style multiline comments, allowing nesting
*>
fn bool parse_multiline_comment(Lexer* lexer) @inline
{
    backtrack(lexer);
    backtrack(lexer);
    bool has_new_line = (lexer.current == lexer.file_begin);
    begin_new_token(lexer);

    int nesting = 0;
    while LOOP: (!reached_end(lexer)) 
	{
        switch (peek(lexer)) 
		{
            case '*':
                if (peek_next(lexer) == '/') 
				{
                    skip(lexer, 2);
                    nesting--;
                    if (nesting == 0) break LOOP;
                    continue;
                }
            case '/':
                if (peek_next(lexer) == '*') 
				{
                    skip(lexer, 2);
                    nesting++;
                    continue;
                }
            case '\0':
                // Reached eof - end.
                return false;
            default:
                break;
        }
        next(lexer);
    }

    char* cur = lexer.lexing_start - 1;
    while LOOP: (cur >= lexer.file_begin) 
	{
        switch (*cur) 
		{
            case ' ':
            case '\t':
                break;
            case '\n':
                has_new_line = true;
            default:
                break LOOP;
        }
        cur--;
    }
    uint len = (uint)(lexer.current - lexer.lexing_start);
    if (lexer.lexing_start[len - 1] == '\n') len--;

    return new_token(
        lexer,
        has_new_line ? COMMENT_MULTI : COMMENT_MULTI_INLINE,
        (String)lexer.lexing_start[..len - 1]
    );
}