
module ast::lexer;

import ast::utils;

// --- Lexer doc lexing


<* 
 Parse doc comments
*>
fn bool parse_doc_start(Lexer* lexer) 
{
    bool may_have_contract = true;
    bool has_new_line = false;
    // Let's loop until we find the end or the contract
    while LOOP: (!reached_end(lexer)) 
	{
        char c = peek(lexer);
        switch (c) 
		{
            case '\n':
                may_have_contract = true;
                has_new_line = true;
                next(lexer);
                continue;
            case ' ':
            case '\t':
                next(lexer);
                continue;
            case '*':
                // We might have <* Hello *>
                // if (peek_next(lexer) == '>') goto EXIT;
                if (peek_next(lexer) == '>') break LOOP;
                may_have_contract = false;
                next(lexer);
                continue;
            case '@':
                if (may_have_contract && utils::char_is_lower(peek_next(lexer))) 
				{
                    // Found a contract
                    // goto EXIT;
                    break LOOP;
                }
                nextcase;
            default:
                may_have_contract = false;
                next(lexer);
                continue;
        }
    }
    // EXIT:;
    // Now we either found:
    // 1. "<* foo \n @param"
    // 2. "<* foo *>"
    // 3. "<* foo <eof>"
    //
    // In any case we can consider this having reached "the contracts"
    if (has_new_line) 
	{
        while LOOP: (lexer.current - 1 > lexer.lexing_start) 
		{
            switch (*(lexer.current - 1)) 
			{
                case ' ':
                case '\t':
                    lexer.current--;
                case '\n':
                default:
                    break LOOP;
            }

        }
    }
    lexer.mode = LEX_CONTRACTS;
    uint len = (uint)(lexer.current - lexer.lexing_start);
    return new_token(lexer, DOCS_START, (String)lexer.lexing_start[..len - 1]);
}

