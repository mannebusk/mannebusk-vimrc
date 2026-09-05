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
["test" "type"] @keyword

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

(binding
  name: (identifier) @function
  value: [(function_literal) (lambda)])

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
