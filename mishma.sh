#The MIT License (MIT)
#
#Copyright (c) 2014 Mason McParlane
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.


# Stores the stack trace of the last command that failed.
readonly _MSHMSH_ERROR_CONTEXT_FILE=/tmp/mishma.sh_error_$$

_mshmsh_error_handler()
{
    if [[ -f $_MSHMSH_ERROR_CONTEXT_FILE ]]; then
        cat $_MSHMSH_ERROR_CONTEXT_FILE 1>&2
        rm -f $_MSHMSH_ERROR_CONTEXT_FILE
    else
        printf 'Failed to load error context file "%s".\n' "$_MSHMSH_ERROR_CONTEXT_FILE"
    fi
    exit 1
}

# This ensures that all subshells will propagate errors to the
# parent shell whenever _mshmsh_error is invoked.
trap '_mshmsh_error_handler' SIGABRT

_mshmsh_error()
{
    local context="$1"
    local stackend=$((${#BASH_LINENO[@]}))
    printf '\nError: %s\n\nTraceback (most recent call first):\n' "$context" \
        >> $_MSHMSH_ERROR_CONTEXT_FILE
    for (( i=1; i < stackend; i++ )); do
        # Line i + 1 properly aligns source and line of function caller.
        printf '    File "%s, line %i, in %s()\n' \
            ${BASH_SOURCE[$i]} ${BASH_LINENO[$i-1]} ${FUNCNAME[$i]} \
            >> $_MSHMSH_ERROR_CONTEXT_FILE
    done
    # Allows sub-shells to propagate errors to the parent shell.
    kill -6 $$
}

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

        if (( $? )); then
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

    if (( $? )); then
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

_mshmsh_parse_args()
{
    local args="$@"
    local lhs=
    local rhs=

    if (( $# )); then
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
        return 0
    else
        # Let the caller know there were no arguments.
        return 1
    fi
}

_mshmsh_call()
{
    local args="$@"

    eval "$args"
    if (( $? )); then
        _mshmsh_error \
            "$(printf \
                'Execution of command "%s" failed.\n'\
                "$args")"
    fi
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





