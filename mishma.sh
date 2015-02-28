
#func=([name]="blah" [is_mishmash_func]=1 [arg1]="blah" ... [argn]="blah")

declare -a _MSHMSH_FUNC_TABLE


_mshmsh_chr_replace()
{
    local string="$1"
    local oldchar="$2"
    local newchar="$3"
    local result=
    for (( i=0; i < ${#string}; i++ )); do
        if [[ "${string:$i:1}" == "$oldchar" ]]; then
            result+="$newchar" 
        else
            result+="${string:$i:1}"
        fi
    done
    printf '%s' "$result"
}

_mshmsh_get()
{
    local __mshmash_var_ref="$1"
    local statement="\${$__mshmash_var_ref}"

    if _mshmsh_isset "$__mshmash_var_ref"; then

        eval "printf '%s\n' \"$statement\"" 

        if (( $? != 0 )); then
            _mshmsh_error \
                "$(printf 'Get variable "%s" failed.' "$__mshmash_var_ref")"
        fi
    else
        _mshmsh_error "$(printf 'Variable "%s" is null.' "$__mshmash_var_ref")"
    fi
}

_mshmsh_getd()
{
    local __mshmash_var_ref="$1"
    local statement="\${$__mshmash_var_ref[*]}"

    if _mshmsh_isset "$__mshmash_var_ref"; then

        eval "printf '%s\n' \"$statement\"" 

        if (( $? != 0 )); then
            _mshmsh_error \
                "$(printf 'Get variable "%s" failed.' "$__mshmash_var_ref")"
        fi
    else
        _mshmsh_error "$(printf 'Variable "%s" is null.' "$__mshmash_var_ref")"
    fi
}

_mshmsh_isset()
{
    local __mshmash_var_ref="$1"
    eval "[[ -n \${$__mshmash_var_ref+x} ]]"
}

_mshmsh_set()
{
    local __mshmash_var_ref="$1"
    local __mshmash_new_val="$2"
    local statement="$__mshmash_var_ref='$__mshmash_new_val'"

    eval "$statement" 

    if (( $? != 0 )); then
        _mshmsh_error \
            "$(printf \
                'Set variable "%s" with statment "%s" failed.'\
                "$__mshmash_var_ref" "$statement")"
    fi
}

_mshmsh_setd()
{
    local __mshmash_var_ref="$1"
    shift
    local __mshmash_new_val="$*"
    local statement="$__mshmash_var_ref=($__mshmash_new_val)"

    if _mshmsh_isset "$__mshmash_var_ref"; then
        eval "$statement" 

        if (( $? != 0 )); then
            _mshmsh_error \
                "$(printf \
                    'Set dictionary "%s" with statment "%s" failed.'\
                    "$__mshmash_var_ref" "$statement")"
        fi
    else
        _mshmsh_error \
            "$(printf \
                '"declare -A %s" must be called before setting the dictionary.' \
                "$__mshmash_var_ref")"
    fi
}

_mshmsh_extract_dict_from_func_args()
{
    # Extract all space-separated [var]="value" pairs and insert into
    # dict.
    local dict_ref="$1"
    local args_ref="$2"


}

_mshmsh_parse_args()
{
    set -x
    local args="$@"
    local expected_args=
    local lhs=
    local rhs=
    local statment=
    
    # Grab all of the expected argument entries.
    while (( $# )); do
        if [[ "${1:0:1}" == "[" ]]; then
            expected_args+="$1 "
            shift
            continue
        else
            # It is expected that actual arguments come after expected-list.
            break
        fi
    done
    set +x

    # Establish expected argument list.
    expected_args=($expected_args)

    # Parse the actual arguments, comparing them against the expected arguments.
    while (( $# )); do
        lhs="${1%%=*}"
        rhs="${1##*=}"
        
        if [[ "${lhs:0:2}" == "--" ]]; then
            lhs="${lhs:2:${#lhs}}"
        else
            _mshmsh_error "$(printf 'Invalid argument "%s" must have "--" prefix.' "$1")"
        fi
        lhs="$(_mshmsh_chr_replace "$lhs" '-' '_')"

        _mshmsh_set "$lhs" "$rhs"

        shift

    done
}

_mshmsh_eval()
{
    local args="$@"
    local result=

    result="$(eval "$args" 2>&1)"
    if (( $? != 0 )); then
        _mshmsh_error \
            "$(printf \
                'Execution of command "%s" failed. Output:\n\n"%s"'\
                "$args" "$result")"
    else
        printf '%s\n' "$result"
    fi
}

_mshmsh_error()
{
    local context="$1"
    printf 'Error: %s\n\nTraceback (most recent call first):\n' "$context"
    # Starting from 1 removes _mshmsh_error() from the stack trace.
    for (( i=1; i < ${#BASH_LINENO[@]}; i++ )); do
        printf '    File "%s, line %i, in %s()\n' \
            ${BASH_SOURCE[$i]} ${BASH_LINENO[$i]} ${FUNCNAME[$i]}
    done
    exit 1
}

_()
{
    case "$1" in
        get)
            shift
            _mshmsh_get "$@"
            ;;
        getd)
            shift
            _mshmsh_getd "$@"
            ;;
        set)
            shift
            _mshmsh_set "$@"
            ;;
        setd)
            shift
            _mshmsh_setd "$@"
            ;;
        isset)
            shift
            _mshmsh_isset "$@"
            ;;
        parse_args)
            shift
            _mshmsh_parse_args "$@"
            ;;
        repl)
            shift
            _mshmsh_chr_replace "$@"
            ;;
        *)
            _mshmsh_eval "$@"
    esac
}
