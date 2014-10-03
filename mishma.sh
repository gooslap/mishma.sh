# usage: source mishma.sh

# Notes:
#
# - Create better error reporting/exception handling mechanism.
#
# - Create abstraction layer for variables (all variables should
#   be maintained by mishma.sh).
#
# - List and Map types (bash already has arrays and dicts so
#   expand upon this basis).
#
# - Make extensive use of function callback mechanism.
#
# - Add named arguments to functions via preamble.
#
#   e.g. f(){
#           _ a, b, c
#        }
#
#   Introspection in this case can be done using "declare -{f,F}"

__mishmash_error()
{
    local msg="$*"
    echo "error: $msg" 1>&2
    echo "backtrace (most recent first):" 1>&2
    local stacksize=${#FUNCNAME[@]}
    for (( i=1; i < stacksize; i++ )); do
        echo $i: ${BASH_SOURCE[$i]}, \
                 ${FUNCNAME[$i]}, \
                 line ${BASH_LINENO[$i-1]} 1>&2
    done
    exit 1
}

# get var [result]
__mishmash_get()
{
    echo "not implemented"
}

# set var value [result]
__mishmash_set()
{
    echo "not implemented"
}

# new type name [value]
__mishmash_new()
{
    if (( $# < 2 )); then 
        __mishmash_error "invalid call \"_ new $*\", expected \"_ new type name [value] [result]\"";
    fi
    local type="$1"
    local name="$2"
    local value="$3"

    case $type in
        int)
            eval __mishmash_vars__$name=$(( value ))
            eval "__mishmash_vars__${name}_type=int"
            ;;

        string)
            eval __mishmash_vars__$name="$value"
            eval "__mishmash_vars__${name}_type=string"
            ;;

        list)
            shift 2
            eval "__mishmash_vars__$name=($*)"
            eval "__mishmash_vars__${name}_type=list"
            ;;

        dict)
            shift 2
            for keyvalpair in "$@"; do
                # bash associative arrays are wonky so we need to create our own
                # not that they will be any better
                eval __mishmash_vars__${name}_${keyvalpair}
                if (( $? != 0 )); then __mishmash_error "invalid $keyvalpair"; fi
                eval "__mishmash_vars__${name}_type=dict"
                eval "__mishmash_vars__${name}_length=$(( __mishmash_vars__${name}_length += 1 ))"
            done
            ;;

        *)
            __mishmash_error "invalid type \"$type\" specified, expected int|string|list|dict";
            ;;

    esac
}

__mishmash_del()
{
    echo "not implemented"
}

_()
{
    if (( $# < 1 )); then __mishmash_error "no command specified"; fi
    local cmd="$1"
    shift

    # check if command exists then call it
    if [[ $cmd == "get" ]]; then __mishmash_get "$@"; fi
    if [[ $cmd == "set" ]]; then __mishmash_set "$@"; fi
    if [[ $cmd == "new" ]]; then __mishmash_new "$@"; fi

    # These are taken from underscore.js which seems like a
    # reasonable starting point.

    # Objects:
    # new
    # keys
    # values
    # pairs
    # invert
    # functions
    # extend
    # pick
    # omit
    # defaults
    # clone
    # tap
    # has
    # matches
    # property
    # is_equal
    # is_empty
    # is_element
    # is_array
    # is_object
    # is_arguments
    # is_function
    # is_string
    # is_number
    # is_finite
    # is_boolean
    # is_date
    # is_reg_exp
    # is_nan
    # is_undefined

    # Collections:
    # each
    # map
    # reduce
    # filter_right
    # find
    # filter
    # where
    # findWhere
    # reject
    # every
    # some
    # contains
    # invoke
    # pluck
    # max
    # min
    # sort_by
    # group_by
    # index_by
    # count_by
    # shuffle
    # sample
    # to_array

    # Arrays:
    # first
    # initial
    # last
    # rest
    # compact
    # flatten
    # without
    # union
    # intersection
    # difference
    # uniq
    # zip
    # object
    # index_of
    # last_index_of
    # sorted_index
    # range

    # Functions:
    # bind
    # bind_all
    # partial
    # memoize
    # delay
    # defer
    # throttle
    # debounce
    # once
    # after
    # before
    # wrap
    # negate
    # compose

    # Utility:
    # no_conflict
    # identity
    # constant
    # noop
    # times
    # random
    # mixin
    # iteratee
    # unique_id
    # escape
    # unescape
    # result
    # now
    # template

    # Chaining:
    # chain
    # value

}
