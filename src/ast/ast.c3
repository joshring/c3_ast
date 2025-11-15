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
)
{
    Ast ast;
    assert(file_path, "empty path");
    assert(file_path.ends_with(".c3"), "wrong extension");
    ast.path = file_path.tcopy();

    lexer::init(&ast.lexer, contents);
    NodeParser node_fn = null;
    AstNode* node = null;
    AstDoc* docstring = null;
    AstModule* current_module = (AstModule*)node::append_alloc(
        AstModule, &ast.modules, &ast.lexer.token
    );
    current_module.file_path = ast.path;

    ast.state_stack.tinit();
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
                    node = node::append_alloc(AstModule, &ast.modules, &ast.lexer.token);
                    current_module = (AstModule*)node;
                    current_module.src_line = ast.lexer.token.row;
                    current_module.docs = docstring;
                    current_module.file_path = ast.path;
                case MACRO:
                case FN:
                    node_fn = &Ast.parse_function;
                    node = node::append_alloc(AstCallable, &current_module.decls, &ast.lexer.token);
                    ((AstCallable*)node).docs = docstring;
                case IMPORT:
                    node_fn = &Ast.parse_import;
                    node = node::append_alloc(AstImport, &current_module.imports, &ast.lexer.token);
                case DOCS_START:
                    // Global doc strings
                    docstring = null;  // reset all previous docs
                    node_fn = &Ast.parse_docstring;
                    node = node::append_alloc(AstDoc, &docstring, &ast.lexer.token);
                case ENUM:
                case FAULT:
                    node_fn = &Ast.parse_enumerable;
                    node = node::append_alloc(
                        AstTypeDefEnumerable, &current_module.decls, &ast.lexer.token
                    );
                    ((AstTypeDefEnumerable*)node).docs = docstring;
                case INTERFACE:
                    node_fn = &Ast.parse_interface;
                    node = node::append_alloc(
                        AstTypeDefInterface, &current_module.decls, &ast.lexer.token
                    );
                    ((AstTypeDefInterface*)node).docs = docstring;
                case STRUCT:
                case UNION:
                case BITSTRUCT:
                    node_fn = &Ast.parse_structural;
                    node = node::append_alloc(
                        AstTypeDefStructural, &current_module.decls, &ast.lexer.token
                    );
                    ((AstTypeDefStructural*)node).docs = docstring;
                case DEF:
                case DISTINCT:
                    node_fn = &Ast.parse_typedef;
                    node = node::append_alloc(AstTypeDef, &current_module.decls, &ast.lexer.token);
                    ((AstTypeDef*)node).docs = docstring;
                case CONST:
                    node_fn = &Ast.parse_constants;
                    node = node::append_alloc(AstTypeDef, &current_module.decls, &ast.lexer.token);
                    ((AstTypeDef*)node).docs = docstring;
                case TYPE_IDENT:
                case TLOCAL:
                    node_fn = &Ast.parse_global_var;
                    node = node::append_alloc(AstTypeDef, &current_module.decls, &ast.lexer.token);
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
                    node.value = node::to_string(current_module.name, mname, "::").tcopy();
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

//=============================================
//                 NODE MANAGEMENT
//=============================================

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

<*
 Append ast node to last node
 @require node_tree != null
*>
macro AstNode* append(AstNode** node_tree, AstNode* new) 
{
    assert(node_tree != null);

    if (*node_tree == null) 
	{
        *node_tree = new;
    } 
	else 
	{
        AstNode* node = last(*node_tree);
        node.next = new;
    }
    return new;
}

<*
 Apply a function to a node tree
 Q: is there a simpler way to achieve this?
*>
macro @node_foreach(#node_tree; @body(item))
{
    var node = #node_tree;
    while (node != null) 
	{
        @body(node);
        node = ($typeof(#node_tree))node.next;
    }
}

<*
 Append allocated ast node to last node
 @require node_tree != null
*>
macro append_alloc(
	$Type, 
	AstNode** node_tree, 
	lexer::Token* token,
) 
{
    $Type* result = mem::tnew($Type);
    *result = {
        .type = token.type,
        .istart = token.offset,
        .iend = token.offset + token.value.len,
        .value = token.value.tcopy(),
    };
    return append(node_tree, result);
}



<*
 output string of ast node tree
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


<*
 iterate to the end of the node tree (linked list) recording its length
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

<*
 return the node of a given type at a given index
 traverses node tree (linked list) until next==null
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
