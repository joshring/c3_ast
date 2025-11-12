# Forked from https://github.com/alexveden/c3tools/
	bringing the code up to date with modern C3

## Goals
- Compiling with modern C3 [X]
- Tests updated []
- Investigate ways to simplify
- Integrate into LSP

### language syntax changes since this was written
```c3
	/** and */ were replaced with <* and *>
	
	{| and |} were removed
	
	read more here: https://github.com/c3lang/c3c/blob/master/releasenotes.md
```

## future work
TODO: it will be more efficient to have separate arrays for each part of the Lexer, rather than in OOP style
TODO: we can store lookups by a common index and ID into those arrays for LSP access
	map[id] -> index
	location_array[index]
	definitions_array[index]
	etc
	
	


