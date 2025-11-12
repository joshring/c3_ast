module ast::lexer;

import ast::utils;

// Scan b64"abc=" and b64'abc='
fn bool scan_base64(Lexer* lexer) @inline 
{
    next(lexer);  // Step past 6
    next(lexer);  // Step past 4
    char start_char = peek(lexer);
    next(lexer);  // Step past ' or " or `
    char c;
    uint end_len = 0;
    ulong len = 4;
    while (1) 
	{
        c = peek(lexer);
        if (c == 0) 
		{
            return add_error_token_at_start(
                lexer, "The base64 string seems to be missing a terminating"
            );
        }
        next(lexer);
        if (c == start_char) break;
        if (utils::char_is_base64(c)) 
		{
            if (end_len) 
			{
                return add_error_token_at_current(lexer, "can't be placed after an ending '='");
            }
            len++;
            continue;
        }
        if (c == '=') 
		{
            if (end_len > 1) 
			{
                return add_error_token_at_current(
                    lexer, "There cannot be more than 2 '=' at the end of a base64 string."
                );
            }
            end_len++;
            continue;
        }
        if (!utils::char_is_whitespace(c)) 
		{
            if (c < ' ' || c > 127) 
			{
                return add_error_token_at_current(
                    lexer, "A valid base64 character was expected here."
                );
            }
            return add_error_token_at_current(lexer, "not a valid base64 character.");
        }
    }
    char* current = lexer.lexing_start;
    char* end = lexer.current;
    len = (usz)(end - current - 1);
    new_token(lexer, BYTES, (String)lexer.lexing_start[..len]);
    return true;
}
