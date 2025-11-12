module ast::utils;
// Copyright (c) 2019 Christoffer Lerno. All rights reserved.
// Copyright (c) 2025 Alex Veden <i@alexveden.com>. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the LICENSE_STDLIB file.


fn bool char_is_letter(char c)
{
    switch (c) 
	{
        case 'a'..'z':
        case 'A'..'Z':
            return true;
        default:
            return false;
    }
}

fn bool char_is_letter_(char c)
{
    switch (c) 
	{
        case 'a'..'z':
        case 'A'..'Z':
        case '_':
            return true;
        default:
            return false;
    }
}

fn bool char_is_lower(char c)
{
	switch(c)
	{
		case 'a'..'z':
			return true;
		default:
			return false;
	}
}

fn bool char_is_lower_(char c)
{
    switch(c)
	{
		case 'a'..'z':
		case '_':
			return true;
		default:
			return false;
	}
}

fn bool char_is_upper(char c)
{
    switch(c)
	{
		case 'A'..'Z':
			return true;
		default:
			return false;
	}
}


fn bool char_is_alphanum_(char c)
{
    switch (c) 
	{
		case 'a'..'z':
		case 'A'..'Z':
        case '0'..'9':
        case '_':
            return true;
        default:
            return false;
    }
}

fn bool char_is_lower_alphanum_(char c)
{
    switch (c) 
	{
        case 'a'..'z':
        case '0'..'9':
        case '_':
            return true;
        default:
            return false;
    }
}

fn bool char_is_upper_alphanum_(char c)
{
    switch (c) 
	{
        case 'A'..'Z':
        case '0'..'9':
        case '_':
            return true;
        default:
            return false;
    }
}



fn bool char_is_oct(char c)
{
	switch (c) 
	{
        case '0'..'7':
            return true;
        default:
            return false;
    }
}

fn bool char_is_oct_or_(char c)
{
    switch (c) 
	{
        case '0'..'7':
		case '_':
            return true;
        default:
            return false;
    }
}

fn bool char_is_binary(char c)
{
    switch (c) 
	{
        case '0'..'1':
            return true;
        default:
            return false;
    }
}

fn bool char_is_binary_or_(char c)
{
	switch (c) 
	{
        case '0'..'1':
		case '_':
            return true;
        default:
            return false;
    }
}

fn bool char_is_digit(char c)
{
    switch (c) 
	{
        case '0'..'9':
            return true;
        default:
            return false;
    }
}

fn bool char_is_digit_or_(char c)
{
	switch (c) 
	{
        case '0'..'9':
		case '_':
            return true;
        default:
            return false;
    }
}

const char[256] HEX_CONV = {
    ['0'] = 0,
    ['1'] = 1,
    ['2'] = 2,
    ['3'] = 3,
    ['4'] = 4,
    ['5'] = 5,
    ['6'] = 6,
    ['7'] = 7,
    ['8'] = 8,
    ['9'] = 9,
    ['A'] = 10,
    ['B'] = 11,
    ['C'] = 12,
    ['D'] = 13,
    ['E'] = 14,
    ['F'] = 15,
    ['a'] = 10,
    ['b'] = 11,
    ['c'] = 12,
    ['d'] = 13,
    ['e'] = 14,
    ['f'] = 15,
};

fn int char_hex_to_nibble(char c)
{
    return HEX_CONV[c];
}

fn bool char_is_hex(char c)
{
    switch (c) 
	{
		case '0'..'9':
		case 'a'..'f':
		case 'A'..'F':
            return true;
        default:
            return false;
    }
}

fn bool char_is_hex_or_(char c)
{
    switch (c) 
	{
		case '0'..'9':
		case 'a'..'f':
		case 'A'..'F':
        case '_':
            return true;
        default:
            return false;
    }
}

<*
 I don't recognise these escape sequences...
 TODO: use faults rather than -1
*>
fn ichar char_is_valid_escape(char c)
{
    switch (c) 
	{
        case 'a':
            return '\a';
        case 'b':
            return '\b';
        case 'e':
            return 0x1B;
        case 'f':
            return '\f';
        case 'n':
            return '\n';
        case 'r':
            return '\r';
        case 't':
            return '\t';
        case 'v':
            return '\v';
        case 'x':
            return 'x';
        case 'u':
            return 'u';
        case 'U':
            return 'U';
        case '\'':
            return '\'';
        case '"':
            return '"';
        case '\\':
            return '\\';
        case '0':
            return '\0';
        default:
            return -1;
    }
}

fn bool char_is_base64(char c)
{
	switch (c) 
	{
        case 'A'..'Z':
		case 'a'..'z':
		case '0'..'9':
		case '+':
		case '/':
            return true;
        default:
            return false;
    }
}


fn char char_nibble_to_hex(int c)
{
    String conv = "0123456789ABCDEF";
    return conv[c];
}

fn bool is_space(char c)
{
    return c == ' ' || c == '\t';
}

fn bool char_is_whitespace(char c)
{
    switch (c) 
	{
        case ' ':
        case '\t':
        case '\n':
            return true;
        case '\r': // TODO: why is this unreachable?
            unreachable();
        default:
            return false;
    }
}
