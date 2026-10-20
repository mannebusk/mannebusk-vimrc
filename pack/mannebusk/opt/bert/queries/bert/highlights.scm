; Syntax highlighting for Bert (Lumen surface).
;
; Capture names follow the nvim-treesitter standard groups. Where several
; patterns match a node, the last one wins (nvim-treesitter semantics), so more
; specific patterns are placed below the general ones.

; ---- Comments ----

(comment) @comment @spell

; ---- Literals ----

(int_literal) @number
(boolean) @boolean

(string_literal) @string
(escape_sequence) @string.escape

; ---- Keywords ----

["if" "then" "else" "match"] @keyword.conditional
(export) @keyword
["test" "type" "external"] @keyword

; A test's name string is a label rather than ordinary string data.
(test_declaration name: (string_literal) @string.special)

; ---- Operators & punctuation ----

(binary_expression operator: _ @operator)

[
  "="
  "->"
  "?"
  "\\"
  "|"
  ".."
] @operator

":" @punctuation.special

["(" ")" "[" "]" "{" "}"] @punctuation.bracket
["," "." ";"] @punctuation.delimiter

; ---- Variables & binders ----

(identifier) @variable
(wildcard) @variable.builtin

(parameter_list (identifier) @variable.parameter)

; Pattern binders introduce a new name the same way a parameter does, so they
; are highlighted as parameters rather than as ordinary references. The `tag`
; and `type` fields are constructors and nominal names, so only the nested
; patterns can match `(identifier)` here.

(match_arm pattern: (identifier) @variable.parameter)
(tag_pattern (identifier) @variable.parameter)
(nominal_pattern (identifier) @variable.parameter)
(list_pattern (identifier) @variable.parameter)
(rest_pattern (identifier) @variable.parameter)

; ---- Nominal types ----
;
; `@` marks a nominal type's name everywhere it is written — the declaration,
; every type position, construction, and the mirror pattern — so one capture
; highlights it identically wherever it appears.

(nominal_name) @type
(nominal_name "@" @punctuation.special)

; ---- Tag constructors ----

(constructor) @constructor
(tag_pattern tag: (constructor) @constructor)

; ---- Module-qualified builtins (e.g. `Int.add`, `CLI.print`) ----

(scoped_identifier
  module: (module) @module
  name: (identifier) @function)

; ---- Function definitions & calls ----

; A definition's name is not a reference to one. Bert has no mutation, so a
; binding of a non-function value reads as a constant; a binding of a function
; literal is a function. A signature is highlighted like the binding it
; annotates so the two lines of a declaration match.

(binding name: (identifier) @constant)
(signature name: (identifier) @constant)
(signature
  name: (identifier) @function
  type: (function_type))

(external_declaration name: (identifier) @constant)
(external_declaration
  name: (identifier) @function
  type: (function_type))

(binding
  name: (identifier) @function
  value: [(function_literal) (lambda)])

; Export items name the file's own definitions.
(export_clause (identifier) @constant)

(call function: (identifier) @function.call)
(call function: (scoped_identifier name: (identifier) @function.call))

; ---- Types ----

(type_variable) @variable.parameter
(type_constructor) @type
(row_variant tag: (type_constructor) @constructor)

; An imported type is reached through its module path (`Geometry.Math.Vec`).
(qualified_type
  module: (module) @module)

((type_constructor) @type.builtin
  (#any-of? @type.builtin "Int" "Bool" "String" "Unit" "Never"))
