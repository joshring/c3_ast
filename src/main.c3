module c3_ast;
import std::io;

fn int main(String[] args)
{
	io::printn("Hello, World!");
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