module ast::lexer;

import ast::utils;

// --- Number scanning

<*
 For C3 we use the practice of f<bit-width> u<bit-width> and i<bit-width>
 @param lexer
 @param is_float
 @return
*>
fn bool scan_number_suffix(Lexer* lexer, bool* is_float) 
{
    if (prev(lexer) == '_') 
	{
        backtrack(lexer);
        return add_error_token_at_current(
            lexer, "The number ended with '_', which isn't allowed, please remove it."
        );
    }
    char c = peek(lexer);
    if (!utils::char_is_alphanum_(c)) return true;
    switch (c | 32) 
	{
        case 'l':
            c = next(lexer);
            if (*is_float) 
			{
                return add_error_token_at_current(
                    lexer, "Integer suffix is not valid for a floating point literal."
                );
            }
            break;
        case 'u':
            if (*is_float) 
			{
                return add_error_token_at_current(
                    lexer, "Integer suffix is not valid for a floating point literal."
                );
            }
            c = next(lexer);
            if ((c | 32) == 'l') 
			{
                c = next(lexer);
                break;
            }
            while (utils::char_is_digit(c = peek(lexer))) next(lexer);
            break;
        case 'i':
            if (*is_float) 
			{
                return add_error_token_at_current(
                    lexer, "Integer suffix '%c' is not valid for a floating point literal."
                );
            }
            next(lexer);
            while (utils::char_is_digit(c = peek(lexer))) next(lexer);
            break;
        case 'f':
            next(lexer);
            *is_float = true;
            while (utils::char_is_digit(c = peek(lexer))) next(lexer);
            break;
        default:
            break;
    }
    if (utils::char_is_alphanum_(c)) 
	{
        next(lexer);
        return add_error_token(lexer, "This doesn't seem to be a valid literal.");
    }
    return true;
}

macro bool next_and_check_no_multiple_(Lexer* lexer) 
{
    if (next(lexer) == '_' && prev(lexer) == '_') 
	{
        return add_error_token_at_current(lexer, "Multiple consecutive '_' are not allowed.");
    }
    return true;
}

<*
 Parsing octals. Here we depart from the (error prone) C style octals with initial zero e.g. 0231
 Instead we only support 0o prefix like 0o231. Note that lexing here doesn't actually parse the
 number itself.
*>
fn bool scan_oct(Lexer* lexer) 
{
    if (!utils::char_is_oct(peek(lexer))) 
	{
        return add_error_token_at_current(
            lexer, "An expression starting with '0o' should be followed by octal numbers (0-7)."
        );
    }
    next(lexer);
    while (utils::char_is_oct_or_(peek(lexer))) next_and_check_no_multiple_(lexer);

    if (utils::char_is_digit(peek(lexer))) 
	{
        return add_error_token_at_current(
            lexer, "An expression starting with '0o' should be followed by octal numbers (0-7)."
        );
    }
    bool is_float = false;
    if (!scan_number_suffix(lexer, &is_float)) return false;
    if (is_float) 
	{
        return add_error_token(lexer, "Octal literals cannot have a floating point suffix.");
    }
    uint len = (uint)(lexer.current - lexer.lexing_start);
    return new_token(lexer, INTEGER, (String)lexer.lexing_start[..len - 1]);
}

<*
 Binary style literals e.g. 0b10101011
*>
fn bool scan_binary(Lexer* lexer) 
{
    if (!utils::char_is_binary(peek(lexer))) 
	{
        return add_error_token_at_current(
            lexer, "An expression starting with '0b' should be followed by binary digits (0-1)."
        );
    }
    next(lexer);
    while (utils::char_is_binary_or_(peek(lexer))) next_and_check_no_multiple_(lexer);
    if (utils::char_is_digit(peek((lexer)))) 
	{
        return add_error_token_at_current(
            lexer, "An expression starting with '0b' should be followed by binary digits (0-1)."
        );
    }
    bool is_float = false;
    if (!scan_number_suffix(lexer, &is_float)) return false;
    if (is_float) 
	{
        return add_error_token(lexer, "Binary literals cannot have a floating point suffix.");
    }
    // return new_token(lexer, INTEGER, ((ZString)lexer.lexing_start).str_view());
    uint len = (uint)(lexer.current - lexer.lexing_start);
    return new_token(lexer, INTEGER, (String)lexer.lexing_start[..len - 1]);
}

<*
 Scan the digit after the exponent, e.g +12 or -12 or 12
 @param lexer
 @return `false if lexing failed`
*>
fn bool scan_exponent(Lexer* lexer) @inline 
{
    // Step past e/E or p/P
    next(lexer);
    char c = peek(lexer);
    next(lexer);
    // Step past +/-
    if (c == '+' || c == '-') 
	{
        c = peek(lexer);
        next(lexer);
    }
    // Now we need at least one digit
    if (!utils::char_is_digit(c)) 
	{
        if (c == 0) 
		{
            backtrack(lexer);
            return add_error_token_at_current(
                lexer, "End of file was reached while parsing the exponent."
            );
        }
        if (c == '\n') return add_error_token(lexer, "End of line was reached while parsing the exponent.");
        if (c < 31 || c > 127) add_error_token(lexer, "An unexpected character was found while parsing the exponent.");
        return add_error_token(
            lexer, "Parsing the floating point exponent failed, because some char is not a number."
        );
    }
    // Step through all the digits.
    while (utils::char_is_digit(peek(lexer))) next(lexer);
    return true;
}

<*
 Scan a hex number, including floating point hex numbers of the format 0x31a31ff.21p12. Note that the
 exponent is written in decimal.
*>
fn bool scan_hex(Lexer* lexer) @inline 
{
    if (!utils::char_is_hex(peek(lexer))) 
	{
        return add_error_token_at_current(
            lexer,
            "'0x' starts a hexadecimal number, so the next character should be 0-9, a-f or A-F."
        );
    }
    next(lexer);
    while (utils::char_is_hex_or_(peek(lexer))) next_and_check_no_multiple_(lexer);
    bool is_float = false;
    if (peek(lexer) == '.' && peek_next(lexer) != '.') 
	{
        is_float = true;
        next(lexer);
        char c = peek(lexer);
        if (c == '_') return add_error_token_at_current(lexer, "'_' is not allowed directly after decimal point, try removing it.");
        if (utils::char_is_hex(c)) next(lexer);
        while (utils::char_is_hex_or_(peek(lexer))) next_and_check_no_multiple_(lexer);
    }
    char c = peek(lexer);
    if (c == 'p' || c == 'P') 
	{
        is_float = true;
        if (!scan_exponent(lexer)) return false;
    }
    if (!scan_number_suffix(lexer, &is_float)) return false;
    // return new_token(lexer, is_float ? REAL : INTEGER, ((ZString)lexer.lexing_start).str_view());
    uint len = (uint)(lexer.current - lexer.lexing_start);
    return new_token(lexer, is_float ? REAL : INTEGER, (String)lexer.lexing_start[..len - 1]);

}

<*
 Scans integer and float decimal values.
*>
fn bool scan_dec(Lexer* lexer) @inline 
{
    assert(utils::char_is_digit(peek(lexer)));

    // Walk through the digits, we don't need to worry about
    // initial _ because we only call this if we have a digit initially.
    while (utils::char_is_digit_or_(peek(lexer))) next_and_check_no_multiple_(lexer);

    // Assume no float.
    bool is_float = false;

    // If we have a single dot, we assume that we have a float.
    // Note that this current parsing means we can't have functions on
    // literals, like "123.sizeof", but we're fine with that.
    if (peek(lexer) == '.' && peek_next(lexer) != '.') 
	{
        is_float = true;
        // Step past '.'
        next(lexer);
        // Check our rule to disallow 123._32
        char c = peek(lexer);
        if (c == '_') return add_error_token_at_current(lexer, "'_' is not allowed directly after decimal point, try removing it.");
        // Now walk until we see no more digits.
        // This allows 123. as a floating point number.
        while (utils::char_is_digit_or_(peek(lexer))) next_and_check_no_multiple_(lexer);
    }
    char c = peek(lexer);
    // We might have an exponential. We allow 123e1 and 123.e1 as floating point, so
    // just set it to floating point and check the exponential.
    if (c == 'e' || c == 'E') 
	{
        is_float = true;
        if (!scan_exponent(lexer)) return false;
    }
    if (!scan_number_suffix(lexer, &is_float)) return false;
    // return new_token(lexer, is_float ? REAL : INTEGER, ((ZString)lexer.lexing_start).str_view());
    uint len = (uint)(lexer.current - lexer.lexing_start);
    return new_token(lexer, is_float ? REAL : INTEGER, (String)lexer.lexing_start[..len - 1]);
}

<*
 Scan a digit, switching on initial zero on possible parsing schemes:
 0x... . Hex
 0o... . Octal
 0b... . Binary

 Default is decimal.

 It's actually pretty simple to add encoding schemes here, so for example Base64 could
 be added.
*>
fn bool scan_digit(Lexer* lexer) @inline 
{
    if (peek(lexer) == '0') 
	{
        switch (peek_next(lexer)) 
		{
            case 'x':
            case 'X':
                skip(lexer, 2);
                return scan_hex(lexer);
            case 'o':
            case 'O':
                skip(lexer, 2);
                return scan_oct(lexer);
            case 'b':
            case 'B':
                skip(lexer, 2);
                return scan_binary(lexer);
            default:
                break;
        }
    }
    return scan_dec(lexer);
}

fn bool scan_hex_array(Lexer* lexer) @inline 
{
    char start_char = peek(lexer);
    next(lexer);  // Step past ' or " `
    char c;
    ulong len = 2;
    while (1) 
	{
        c = peek(lexer);
        if (c == 0) 
		{
            return add_error_token_at_current(
                lexer, "The hex string seems to be missing a terminating "
            );
        }

        if (c == start_char) break;

        if (utils::char_is_hex(c)) 
		{
            next(lexer);
            len++;
            continue;
        }
        if (utils::char_is_whitespace(c)) 
		{
            next(lexer);
            continue;
        }
        if (c > ' ' && c < 127) 
		{
            return add_error_token_at_current(
                lexer,
                " isn't a valid hexadecimal digit, all digits should be a-z, A-Z and 0-9.",
            );
        }
        return add_error_token_at_current(
            lexer, "This isn't a valid hexadecimal digit, all digits should be a-z, A-Z and 0-9."
        );
    }
    next(lexer);
    if (len % 2) 
	{
        return add_error_token(
            lexer, "The hexadecimal string is not an even length, did you miss a digit somewhere?"
        );
    }

    char* current = lexer.lexing_start;
    char* end = lexer.current;
    len = (usz)(end - current - 1);

    new_token(lexer, BYTES, (String)lexer.lexing_start[..len]);
    return true;
}