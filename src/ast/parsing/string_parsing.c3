module ast::lexer;


// --- Character & string scan

fn bool scan_char(Lexer* lexer) @inline 
{
    // Handle the problem with zero size character literal first.
    if (match(lexer, '\'')) 
	{
        return add_error_token(lexer, "The character literal was empty.");
    }

    int width = 1;
    char c;

    while LOOP: (!match(lexer, '\'')) 
	{
        c = peek(lexer);
        next(lexer);
        // End of file may occur:
        switch (c) 
		{
            case '\0':
                return add_error_token_at_start(lexer, "The character literal did not terminate.");
            case '\\':  // escape sequence
                c = peek(lexer);
                if (c == '\'' || c == '\\') 
				{
                    next(lexer);
                    width++;
                }
        }
        width++;
    }
    return new_token(lexer, CHAR_LITERAL, (String)lexer.lexing_start[..width]);
}

fn void consume_to_end_quote(Lexer* lexer) @inline 
{
    char c;
    while ((c = peek(lexer)) != '\0' && c != '"') 
	{
        next(lexer);
    }
}

fn bool scan_string(Lexer* lexer) @inline 
{
    char c = 0;
    char* current = lexer.current;
    while ((c = *(current++)) != '"') 
	{
        if (c == '\n' || c == '\0') 
		{
            current++;
            break;
        }
        if (c == '\\') 
		{
            c = *current;
            if (c != '\n' && c != '\0') current++;
            continue;
        }
    }
    char* end = current - 1;
    usz len = 0;

    // NOTE: inlcuding previous "
    backtrack(lexer);
    begin_new_token(lexer);
    while (lexer.current < end) 
	{
        c = peek(lexer);
        next(lexer);
        if (c == '\0' || (c == '\\' && peek(lexer) == '\0')) 
		{
            if (c == '\0') backtrack(lexer);
            add_error_token_at_start(
                lexer,
                "The end of the file was reached ""while parsing the string. ""Did you forget (or accidentally add) a '\"' somewhere?"
            );
            consume_to_end_quote(lexer);
            return false;
        }
        if (c == '\n' || (c == '\\' && peek(lexer) == '\n')) 
		{

            backtrack(lexer);
            add_error_token_at_start(
                lexer,
                "The end of the line was reached ""while parsing the string. ""Did you forget (or accidentally add) a '\"' somewhere?"
            );
            consume_to_end_quote(lexer);
            return false;
        }
        len++;
    }
    // Skip the `"`
    next(lexer);
    return new_token(lexer, STRING, len > 0 ? (String)lexer.lexing_start[..len] : "");

}

fn bool scan_raw_string(Lexer* lexer) @inline 
{
    char c;
    while (1) 
	{
        c = peek(lexer);
        next(lexer);
        if (c == '`' && peek(lexer) != '`') break;
        if (c == '\0') 
		{
            return add_error_token_at_start(
                lexer,
                "Reached the end of the file looking for ""the end of the raw string that starts ""here. Did you forget a '`' somewhere?"
            );
        }
        if (c == '`') next(lexer);
    }
    char* current = lexer.lexing_start;
    char* end = lexer.current;
    usz len = (usz)(end - current);
    new_token(lexer, RAW_STRING, (String)current[0..len - 1]);
    return true;
}
