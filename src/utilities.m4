m4_include([list.m4])


dnl
dnl Define a macro that is part of the public API
dnl Ensure the replication and also add the macro name to a list of allowed macros
m4_define([argbash_api], [_argbash_persistent([$1], [$2])])
m4_define([_argbash_persistent], [m4_set_add([_KNOWN_MACROS],[$1])m4_define([$1], [$2])])


dnl
dnl $1: this comm block ID
dnl $2: where it is defined
dnl $3: indentation
dnl $4, ....: comment lines
dnl
dnl If the comment ID has been defined earlier, don't display the comment, but point to the definition.
dnl Otherwise, act like _COMM_BLOCK
m4_define([_POSSIBLY_REPEATED_COMMENT_BLOCK], [m4_ifndef([_COMMENT_$1_LOCATION], [m4_do(
	[m4_define([_COMMENT_$1_LOCATION], [[$2]])],
	[_COMM_BLOCK($3, m4_shiftn(3, $@))],
)], [m4_do(
	[_COMM_BLOCK([$3], m4_quote([# ]m4_indir([_COMMENT_$1_LOCATION])))],
)])])

m4_define([_COMM_BLOCK], [m4_ifdef([COMMENT_OUTPUT], [_JOIN_INDENTED([$1], m4_shift(m4_dquote_elt($@)))])])
m4_define([_COMMENT_CHAIN], [m4_ifdef([COMMENT_OUTPUT], [$@])])
m4_define([_COMMENT], [m4_ifdef([COMMENT_OUTPUT], [$1])])


dnl
dnl $1: The text to substitute
dnl Regexp: Find beginning of backslashes, match for pairs, and if \\n is left, then substitute it for literal newline.
m4_define([_SUBSTITUTE_LF_FOR_NEWLINE_AND_INDENT], [m4_bpatsubst([[$1]], [\([^\\]\)\(\\\\\)*\\n],  [\1\2
		])])


dnl
dnl Checks that the n-th argument is an integer.
dnl Should be called upon the macro definition outside of quotes, e.g. m4_define([FOO], _CHECK_INTEGER_TYPE(1)[m4_eval(2 + $1)])
dnl $1: The argument number
dnl $2: The error message (optional)
m4_define([_CHECK_INTEGER_TYPE],
	__CHECK_INTEGER_TYPE([[$][0]], m4_quote($[]$1), [$1], m4_quote($[]2)))


dnl
dnl The helper macro for _CHECK_INTEGER_TYPE
dnl $1: The caller name
dnl $2: The arg position
dnl $3: The arg value
dnl $4: The error message (optional)
m4_define([__CHECK_INTEGER_TYPE], [[m4_do(
	[m4_bmatch([$2], [^[0-9]+$], ,
		[m4_fatal([The ]m4_case([$3], 1, 1st, 2, 2nd, 3, 3rd, $3th)[ argument of '$1' has to be a number]m4_ifnblank([$4], [[ ($4)]])[, got '$2'])])],
)]])



m4_define([_CHECK_PASSED_ARGS_COUNT_TOO_FEW],
	[m4_fatal([You have passed $2 arguments to macro $1, while it requires at least $3.]m4_ifnblank([$4], [ Call it like: $4]))])

m4_define([_CHECK_PASSED_ARGS_COUNT_TOO_MANY],
	[m4_fatal([You have passed $2 arguments to macro $1, while it accepts at most $3.]m4_ifnblank([$4], [ Call it like: $4]))])

dnl
dnl $1: Name of the macro
dnl $2: The actual argc
dnl $3: argc lower bound
dnl $4: argc upper bound
dnl $5: The calling signature
m4_define([__CHECK_PASSED_ARGS_COUNT], [[m4_do(
	[m4_pushdef([_maybe_signature_$1], [m4_ifnblank([$5], [[$1($5)]])])],
	[m4_if(
		m4_eval($2 < $3), 1, [_CHECK_PASSED_ARGS_COUNT_TOO_FEW([$1], [$2], [$3], m4_quote(m4_indir([_maybe_signature_$1])))],
		m4_eval($2 > $4), 1, [_CHECK_PASSED_ARGS_COUNT_TOO_MANY([$1], [$2], [$4], m4_quote(m4_indir([_maybe_signature_$1])))],
	)],
	[m4_popdef([_maybe_signature_$1])],
)]])


dnl Check thath the correct number of arguments has been passed, and display the calling signature if it is not the case
dnl $1: The minimal amount of args > 0 (due to m4's $# behaior)
dnl $2: The highest possible arguments count (optional, defaults to no upper bound behavior)
dnl $3: The arguments part of the calling signature (optional)
m4_define([_CHECK_PASSED_ARGS_COUNT], m4_if([$1], 0, [m4_fatal([The minimal amount of args must be non-negative.])])[__CHECK_PASSED_ARGS_COUNT([$]0, $[#], [$1], m4_default([$2], [$[#]]), [$3])])


dnl
dnl
dnl Blank args to this macro are totally ignored, use @&t@ to get over that --- @&t@ is a quadrigraph that expands to nothing in the later phase
dnl $1: How many indents
dnl $2, $3, ...: What to put there
m4_define([_JOIN_INDENTED], _CHECK_INTEGER_TYPE(1, [depth of indentation])[m4_do(
	[m4_pushdef([_current_indentation_level], [$1])],
	[m4_foreach([line], [m4_shift($@)], [m4_ifnblank(m4_quote(line), _INDENT_([$1])[]m4_dquote(line)
)])],
	[m4_popdef([_current_indentation_level])],
)])


dnl
dnl $1, $2, ...: What to put there
dnl
dnl Takes arguments, returns them, but there is an extra _INDENT_() in the beginning of them
m4_define([_INDENT_MORE], [m4_do(
	[m4_list_ifempty([_TLIST], , [m4_fatal([Internal error: List '_TLIST' should be empty, contains ]m4_list_contents([_TLIST])[ instead])])],
	[m4_foreach([line], [$@], [m4_list_append([_TLIST], m4_expand([_INDENT_()line]))])],
	[m4_list_contents([_TLIST])],
	[m4_list_destroy([_TLIST])],
)])


dnl Take precaution that if the indentation depth is 0, nothing happens
m4_define([_SET_INDENT], [m4_define([_INDENT_],
	[m4_for(_, 1, m4_default($][1, 1), 1,
		[[$1]])])])

m4_define([_SET_INDENT], [__SET_INDENT([$1], $[]1)])


dnl
dnl defines _INDENT_
dnl $1: How many times to indent (default 1)
dnl $2, ...: Ignored, but you can use those to make the code look somewhat better.
m4_define([__SET_INDENT], [m4_define([_INDENT_], [m4_if([$2], 0, ,
	[m4_for(_, 1, m4_default([$2], 1), 1,
		[[$1]])])])])


dnl
dnl Sets the indentation character(s) in the parsing code
dnl $1: The indentation character(s)
argbash_api([ARGBASH_SET_INDENT],
	[m4_bmatch(m4_expand([_W_FLAGS]), [I], ,[[$0($@)]_SET_INDENT([$1])])])


m4_define([_ASSIGN_VALUE_TO_VAR], [[$3=]_MAYBE_VALIDATE_VALUE([$1], [$2])_IF_ARG_IS_TYPED([$1], [ || exit 1])])
m4_define([_APPEND_VALUE_TO_ARRAY], [[$3+=](_MAYBE_VALIDATE_VALUE([$1], [$2]))_IF_ARG_IS_TYPED([$1], [ || exit 1])])
dnl m4_define([_ASSIGN_VALUE_TO_VAR], [[$2="$1"]])
dnl m4_define([_APPEND_VALUE_TO_ARRAY], [[$2+=("$1")]])
