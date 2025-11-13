module c3_ast;
import std::io;

import ast;
 


fn int main(String[] args)
{
	
	// AstNode ast_node;
	
	// io::printfn("ast_node.alignof: %s AstNode.sizeof: %s", AstNode.alignof, AstNode.sizeof);
	// $echo(AstNode.membersof);
	
	utils::struct_memory_layout(Token);
	
	utils::struct_memory_layout(Lexer);
	
	// utils::struct_memory_layout(AstTypeDefStructural);
	
	// utils::struct_memory_layout(AstCallable);
	
	// utils::struct_memory_layout(AstCallableParam);
	
	// utils::struct_memory_layout(AstImport);
	
	// utils::struct_memory_layout(AstDoc);
	
	// utils::struct_memory_layout(AstDocContract);

	
	// $foreach $index, $type_member : AstNode.membersof:
	// 	io::printfn("index: %s typename: %s size: %s alignment %s",$index, $type_member.nameof, $type_member.sizeof, $type_member.alignof);
	// $endforeach
	
	return 0;
}

// module get_environ;
// import std;

// fn void main(String[] args){
//     ZString* environ_arr = std::os::posix::environ;
//     foreach (idx, ZString &envvar : environ_arr)
//     {}
// }

// module get_environ;
// import std;
// import std::io;

// fn void main(String[] args){
//     String environ_arr = (*std::os::posix::environ).str_view();
// 	String[] split = environ_arr.tsplit("\n"); 
	
	
//     foreach (idx, String envvar : split)
//     {
// 		io::printn(envvar);
// 	}
// }