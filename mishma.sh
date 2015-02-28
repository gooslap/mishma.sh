
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

_mshmsh_chr_escape()
{
    local string="$1"
    local char="$2"
    local escape_char="\\"
    local result=

    for (( i=0; i < ${#string}; i++ )); do
        if [[ "${string:$i:1}" == "$char" ]]; then
            result+="${escape_char}${char}" 
        else
            result+="${string:$i:1}"
        fi
    done
    printf '%s' "$result"
}

_mshmsh_contains_char()
{
    local string="$1"
    local char="$2"

    for (( i=0; i < ${#string}; i++ )); do
        if [[ "${string:$i:1}" == "$char" ]]; then
            return 0
        fi
    done
    return 1
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

_mshmsh_set()
{
    local __mshmash_var_ref="$1"
    local __mshmash_new_val="$2"
    __mshmash_new_val="$(_mshmsh_chr_escape "$__mshmash_new_val" \")"
    local statement="$__mshmash_var_ref=\"$__mshmash_new_val\""

    eval "$statement" 

    if (( $? != 0 )); then
        _mshmsh_error \
            "$(printf \
                'Set variable "%s" with statment "%s" failed.'\
                "$__mshmash_var_ref" "$statement")"
    fi
}

_mshmsh_isset()
{
    local __mshmash_var_ref="$1"
    eval "[[ -n \${$__mshmash_var_ref+x} ]]"
}

#_mshmsh_extract_expected_args()
#{
#    local expected_args=
#    
#    # Grab all of the expected argument entries.
#    while (( $# )); do
#        if [[ "${1:0:1}" == "[" ]]; then
#            expected_args+="$1 "
#            shift
#            continue
#        else
#            # It is expected that actual arguments come after expected-list.
#            break
#        fi
#    done
#}

_mshmsh_parse_args()
{
    local args="$@"
    local lhs=
    local rhs=

    while (( $# )); do
        lhs="${1%%=*}"
        rhs="${1##*=}"
        
        if [[ "${lhs:0:2}" == "--" ]]; then
            lhs="${lhs:2:${#lhs}}"
        else
            _mshmsh_error "$(printf 'Invalid argument "%s" must have "--" prefix.' "$1")"
        fi

        lhs="$(_mshmsh_chr_replace "$lhs" - _)"

        _mshmsh_set "$lhs" "$rhs"

        shift
    done
}

_mshmsh_call()
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
    for (( i=0; i < ${#BASH_LINENO[@]}; i++ )); do
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
        set)
            shift
            _mshmsh_set "$@"
            ;;
        isset)
            shift
            _mshmsh_isset "$@"
            ;;
        parse_args)
            shift
            _mshmsh_parse_args "$@"
            ;;
        chr_repl)
            shift
            _mshmsh_chr_replace "$@"
            ;;
        chr_escape)
            shift
            _mshmsh_chr_escape "$@"
            ;;
        error)
            shift
            _mshmsh_error "$@"
            ;;
        call)
            shift
            _mshmsh_call "$@"
            ;;
        *)
            _mshmsh_call "$@"
            ;;
    esac
}
