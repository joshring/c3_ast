module ast;

import ast::lexer;
import ast::node;

import std::io;
import std::hash::fnv32a;
import std::sort;
import std::collections::list;
import std::collections::map;

fn Ast parse(
    String contents, 
	String file_path, 
	bool print_lex = false, 
	DynamicArenaAllocator* allocator = null
)
{
    Ast ast;
    if (allocator == null) 
	{
        // typically this will be actual only for tests
        ast.allocator = mem::alloc(DynamicArenaAllocator);
        ast.allocator.init(allocator: tmem, page_size: 1024);
    } 
	else 
	{
        ast.allocator = allocator;
    }
    assert(file_path, "empty path");
    assert(file_path.ends_with(".c3"), "wrong extension");
    ast.path = ast.@allc_str(file_path);

    lexer::init(&ast.lexer, contents);
    NodeParser node_fn = null;
    AstNode* node = null;
    AstDoc* docstring = null;
    AstModule* current_module = (AstModule*)ast.@allc_add(
        AstModule, &ast.modules, &ast.lexer.token
    );
    current_module.file_path = ast.path;

    ast.state_stack.init(allocator: allocator);
    defer ast.state_stack.free();

    while LOOP: (ast.lexer.next_token()) 
	{
        if (print_lex) ast.lexer.token.print();

        if (!node_fn) 
		{
            switch (ast.lexer.token.type) 
			{
                case MODULE:
                    node_fn = &Ast.parse_module;
                    if (ast.modules.next == null) 
					{
                        // first `module` keyword, check if there is no decls/imports in default
                        // and remove it from modules list if it's completely empty
                        if (!ast.modules.decls && !ast.modules.imports) 
						{
                            ast.modules = null;
                        }
                    }
                    node = ast.@allc_add(AstModule, &ast.modules, &ast.lexer.token);
                    current_module = (AstModule*)node;
                    current_module.src_line = ast.lexer.token.row;
                    current_module.docs = docstring;
                    current_module.file_path = ast.path;
                case MACRO:
                case FN:
                    node_fn = &Ast.parse_function;
                    node = ast.@allc_add(AstCallable, &current_module.decls, &ast.lexer.token);
                    ((AstCallable*)node).docs = docstring;
                case IMPORT:
                    node_fn = &Ast.parse_import;
                    node = ast.@allc_add(AstImport, &current_module.imports, &ast.lexer.token);
                case DOCS_START:
                    // Global doc strings
                    docstring = null;  // reset all previous docs
                    node_fn = &Ast.parse_docstring;
                    node = ast.@allc_add(AstDoc, &docstring, &ast.lexer.token);
                case ENUM:
                case FAULT:
                    node_fn = &Ast.parse_enumerable;
                    node = ast.@allc_add(
                        AstTypeDefEnumerable, &current_module.decls, &ast.lexer.token
                    );
                    ((AstTypeDefEnumerable*)node).docs = docstring;
                case INTERFACE:
                    node_fn = &Ast.parse_interface;
                    node = ast.@allc_add(
                        AstTypeDefInterface, &current_module.decls, &ast.lexer.token
                    );
                    ((AstTypeDefInterface*)node).docs = docstring;
                case STRUCT:
                case UNION:
                case BITSTRUCT:
                    node_fn = &Ast.parse_structural;
                    node = ast.@allc_add(
                        AstTypeDefStructural, &current_module.decls, &ast.lexer.token
                    );
                    ((AstTypeDefStructural*)node).docs = docstring;
                case DEF:
                case DISTINCT:
                    node_fn = &Ast.parse_typedef;
                    node = ast.@allc_add(AstTypeDef, &current_module.decls, &ast.lexer.token);
                    ((AstTypeDef*)node).docs = docstring;
                case CONST:
                    node_fn = &Ast.parse_constants;
                    node = ast.@allc_add(AstTypeDef, &current_module.decls, &ast.lexer.token);
                    ((AstTypeDef*)node).docs = docstring;
                case TYPE_IDENT:
                case TLOCAL:
                    node_fn = &Ast.parse_global_var;
                    node = ast.@allc_add(AstTypeDef, &current_module.decls, &ast.lexer.token);
                    ((AstTypeDef*)node).docs = docstring;
                default:
                    continue LOOP;
            }

            assert(ast.state_stack.len() == 0);
            ast.state_stack.push((NodeParserState){});
        }

        if (node_fn(&ast, node, &ast.lexer.token, &ast.state_stack[0])) 
		{
            // Node was finished, scan next;
            switch (node.type) 
			{
                case MODULE:
                    assert(node == current_module);
                    DString mname = dstring::temp();
                    node.value = ast.@allc_str(node::to_string(current_module.name, mname, "::"));
                    current_module.hash.init();
                    current_module.hash.update(node.value);
                    nextcase default;
                case DOCS_START:
                    break;
                default:
                    docstring = null;
            }
            node_fn = null;
            node = null;
            assert(ast.state_stack.len() == 0, "not cleared?");
        }
    }

    if (ast.modules) 
	{
        AstModule* last_mod = node::last(ast.modules);
        last_mod.iend = ast.lexer.token.offset - 1;
    }
    ast.state_stack.clear();

    return ast;
}


struct Ast
{
    Lexer lexer;
    List{NodeParserState} state_stack;
    String path;
    AstModule* modules;
    allocator::DynamicArenaAllocator* allocator;
}

alias NodeParser = fn bool (Ast* ast, AstNode* node, Token* t, NodeParserState* state);

struct NodeParserState
{
    TokenType[32] scope_stack;
    AstNode* sub_node;
    TokenType current_state;
    TokenType last_token;
    TokenType current_token;
    TokenType initial_token;
    uint scope_depth;
}

struct AstNode
{
    String value;
    AstNode* next;
    TokenType type;
    uint istart;
    uint iend;
}

struct AstModule
{
    inline AstNode node;
    String file_path;
    AstNode* name;
    AstNode* attributes;
    AstImport* imports;
    AstTypeDef* decls;
    AstDoc* docs;
    Fnv32a hash;
    uint src_line;
}

struct AstTypeDef
{
    inline AstNode node;
    AstModule* mod;  // module which owns the type def
    AstNode* attributes;
    AstDoc* docs;
    AstNode* ftype;  // field or function return type
}

struct AstTypeDefEnumerable
{
    inline AstTypeDef node;
    AstNode* values;
}

struct AstTypeDefInterface
{
    inline AstTypeDef node;
    AstCallable* functions;
}

struct AstTypeDefStructural
{
    inline AstTypeDef node;
    AstTypeDef* inlines;
    AstTypeDef* members;
}

struct AstCallable
{
    inline AstTypeDef node;
    AstNode* name;
    AstCallableParam* params;
    uint iscope_start;
}

struct AstCallableParam
{
    inline AstNode node;
    AstNode* param_type;
    AstNode* attributes;
}

struct AstImport
{
    inline AstNode node;
    AstNode* name;
    AstNode* attributes;
}

struct AstDoc
{
    inline AstNode node;
    AstDocContract* contracts;
}

struct AstDocContract
{
    inline AstNode node;
    AstNode* items;
}

//
//                 NODE MANAGEMENT
//

// TODO: create module to clarify naming
module ast::node;
import ast::lexer;

macro last(node_tree) 
{
	var $InputType = $typeof(node_tree);
	
    assert(node_tree != null);
    $InputType node = node_tree;
	
    while (node.next != null) 
	{
        node = ($InputType)node.next;
    }
    return node;
}

macro @node_last(self) 
{
    assert(self != null);
    $typeof(self) node = self;
    while (node.next) 
	{
        node = ($typeof(self))node.next;
    }
    return node;
}

<*
 Append ast node to last node
 
*>
// macro AstNode* append(AstNode** self, AstNode* new) 
// {
//     assert(self != null);

//     if (*self == null) 
// 	{
//         *self = new;
//     } 
// 	else 
// 	{
//         AstNode* node = @node_last(*self);
//         node.next = new;
//     }
//     return new;
// }

macro AstNode* @node_add(AstNode** self, AstNode* new) 
{
    assert(self != null);

    if (*self == null) 
	{
        *self = new;
    } 
	else 
	{
        AstNode* node = last(*self);
        node.next = new;
    }
    return new;
}

macro @node_foreach(#self; @body(item))
{
    var node = #self;
    while (node) 
	{
        @body(node);
        node = ($typeof(#self))node.next;
    }
}

macro Ast.@allc_add(&self, $Type, AstNode** collection, lexer::Token* token) 
{
    $Type* result = self.allocator.acquire($Type.sizeof, NO_ZERO, $Type.alignof)!!;
    *result = {
        .type = token.type,
        .istart = token.offset,
        .iend = token.offset + token.value.len,
        .value = self.@allc_str(token.value),
    };
    return @node_add(collection, result);
}



<*
 output string of ast node tree
 my version of Ast.@node_join
 TODO: change out_str to be a return value?
*>
macro to_string(node_tree, DString out_str, String sep = ",")
{
	var $InputType = $typeof(node_tree);
	
    out_str.clear();
    $InputType search_node = node_tree;
	
    while (search_node != null) 
	{
        out_str.append(search_node.value);
        search_node = ($InputType)search_node.next;
        if (search_node) 
		{
            out_str.append(sep);
        }
    }
    return out_str.str_view();
}

// <*
//  DEPRECATED: use ast::to_string
//  output string of ast node tree
// *>
// macro Ast.@node_join(self, node, DString out_str, String sep = ",")
// {
//     out_str.clear();
//     $typeof(node) _node = node;
//     while (_node) 
// 	{
//         out_str.append(_node.value);
//         _node = ($typeof(node))_node.next;
//         if (_node) 
// 		{
//             out_str.append(sep);
//         }
//     }
//     return out_str.str_view();
// }

// <*
//  DEPRECATED: use ast::len
//  iterate to the end of the linked list recording its length
// *>
// macro uint Ast.@node_len(self, node)
// {
//     uint len = 0;
//     $typeof(node) _node = node;
//     while (_node) 
// 	{
//         len++;
//         _node = ($typeof(node))_node.next;
//     }
//     return len;
// }

<*
 iterate to the end of the node tree (linked list) recording its length
 my version of Ast.@node_len
*>
macro uint len(node_tree)
{
	var $InputType = $typeof(node_tree);
	
    uint len = 0;
    $InputType search_node = node_tree;
	
    while (search_node != null) 
	{
        len++;
        search_node = ($InputType)search_node.next;
    }
    return len;
}

// <*
//  DEPREACTED: use ast::index
 
//  return the node of a given type at a given index
//  traverses linked list until next==null I think?
 
//  Q: isn't this function a bit strange? why not return the node at a given index instead? 
//  	it feels strange/unnecesisary giving the type as a paramter
// *>
// macro Ast.@node_at(self, node, uint index)
// {
//     uint len = 0;
//     $typeof(node) _node = node;
//     while (_node) 
// 	{
//         if (len == index) return _node;
//         len++;
//         _node = ($typeof(node))_node.next;
//     }
//     return _node;
// }

<*
 return the node of a given type at a given index
 traverses node tree (linked list) until next==null

 my version of Ast.@node_at
*>
macro index(node_tree, uint index)
{
	var $InputType = $typeof(node_tree);
	
    uint len = 0;
    $InputType search_node = node_tree;
	
    while (search_node != null) 
	{
        if (len == index) return search_node;
        search_node = ($InputType)search_node.next;
        len++;
    }
    return null;
}


macro String Ast.@allc_str(&self, String s) 
{
    String result = s.copy(self.allocator);
    return result;
}
