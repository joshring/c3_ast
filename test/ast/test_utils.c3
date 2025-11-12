module test::ast::utils @test;
import ast::utils;


fn void test_char_is_letter()
{
	String contents = "Example";
	
	foreach(character : contents)
	{
		test::eq(utils::char_is_letter(c: character), true);
	}
}

fn void test_char_is_letter_()
{
	String contents = "Example_here";
	
	foreach(character : contents)
	{
		test::eq(utils::char_is_letter_(c: character), true);
	}
}

fn void test_char_is_lower()
{
	String contents = "example";
	
	foreach(character : contents)
	{
		test::eq(utils::char_is_lower(c: character), true);
	}
}

fn void test_char_is_lower_()
{
	String contents = "example_here";
	
	foreach(character : contents)
	{
		test::eq(utils::char_is_lower_(c: character), true);
	}
}

fn void test_char_is_upper()
{
	String contents = "EXAMPLE";
	foreach(character : contents)
	{
		test::eq(utils::char_is_upper(c: character), true);
	}
}

fn void test_char_is_alphanum_()
{
	String contents = "EXAMPLE_here992";
	foreach(character : contents)
	{
		test::eq(utils::char_is_alphanum_(c: character), true);
	}
}

fn void test_char_is_lower_alphanum_()
{
	String contents = "example_here992";
	foreach(character : contents)
	{
		test::eq(utils::char_is_lower_alphanum_(c: character), true);
	}
}

fn void test_char_is_upper_alphanum_()
{
	String contents = "EXAMPLE_HERE992";
	foreach(character : contents)
	{
		test::eq(utils::char_is_upper_alphanum_(c: character), true);
	}
}

fn void test_char_is_oct()
{
	String contents = "017";
	foreach(character : contents)
	{
		test::eq(utils::char_is_oct(c: character), true);
	}
}


fn void test_char_is_oct_or_()
{
	String contents = "0_17";
	foreach(character : contents)
	{
		test::eq(utils::char_is_oct_or_(c: character), true);
	}
}

fn void test_char_is_binary()
{
	String contents = "0101";
	foreach(character : contents)
	{
		test::eq(utils::char_is_binary(c: character), true);
	}
}

fn void test_char_is_binary_or_()
{
	String contents = "01_01";
	foreach(character : contents)
	{
		test::eq(utils::char_is_binary_or_(c: character), true);
	}
}

fn void test_char_is_digit()
{
	String contents = "910000";
	foreach(character : contents)
	{
		test::eq(utils::char_is_digit(c: character), true);
	}
}

fn void test_char_is_digit_or_()
{
	String contents = "910_000";
	foreach(character : contents)
	{
		test::eq(utils::char_is_digit_or_(c: character), true);
	}
}

fn void test_char_hex_to_nibble()
{
	String contents = "ffffff";
	foreach(character : contents)
	{
		test::eq(utils::char_hex_to_nibble(c: character), 15);
	}
}

fn void test_char_is_hex_or_()
{
	String contents = "ff_ff_ff";
	test::eq(utils::char_is_hex_or_(c: contents[0]), true);
	test::eq(utils::char_is_hex_or_(c: contents[2]), true);
}

fn void test_char_is_valid_escape()
{
	String contents = "t";
	foreach(character : contents)
	{
		test::eq(utils::char_is_valid_escape(c: character), '\t');
	}
}

fn void test_char_is_base64()
{
	String contents = "Zm9vYmFy"; // foobar in b64
	foreach(character : contents)
	{
		test::eq(utils::char_is_base64(c: character), true);
	}
}

fn void test_char_nibble_to_hex()
{
	test::eq(utils::char_nibble_to_hex(c: 15), 'F');
	test::eq(utils::char_nibble_to_hex(c: 9), '9');
	test::eq(utils::char_nibble_to_hex(c: 1), '1');
}

fn void test_is_space()
{
	String contents = " \t";
	foreach(character : contents)
	{
		test::eq(utils::is_space(c: character), true);
	}
}

fn void test_char_is_whitespace()
{
	String contents = " \n\t";
	foreach(character : contents)
	{
		test::eq(utils::char_is_whitespace(c: character), true);
	}
}





