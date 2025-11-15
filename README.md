# Forked from https://github.com/alexveden/c3tools/
	bringing the code up to date with modern C3

## Goals
- Compiling with modern C3 [X]
- Tests updated []
- Investigate ways to simplify
- Integrate into LSP
- replace `ast.@node_at` with `node::index` 		- DONE
- replace `ast.@node_len` with `node::len` 			- DONE
- replace `ast.@allc_add` with `node::append_alloc` - TODO
- replace `ast.@allc_str` with `string_here.copy(allocator)` - in progress, but likely want to tackle one instance at a time as its lead to some hard to track down problems? debugger required

### language syntax changes since this was written
```c3
	/** and */ were replaced with <* and *>
	
	LBRAPIPE {| and |} were removed
	
	List(<MyType>) became List{MyType}
	
	
	(< LGENPAR
	>) RGENPAR
	
	read more here: https://github.com/c3lang/c3c/blob/master/releasenotes.md
```

## future work
TODO: it will be more efficient to have separate arrays for each part of the Lexer, rather than in OOP style
TODO: we can store lookups by a common index and ID into those arrays for LSP access
	map[id] -> index
	location_array[index]
	definitions_array[index]
	etc
	
	


