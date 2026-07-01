#shellcheck shell=bash
#shellcheck source-path=../../
# ------------------------------------------------------------------------------
if [[ -n ${__included_cleanup_bash:-} ]]; then
    return
fi
__included_cleanup_bash=true
# ------------------------------------------------------------------------------

# Function: add_cleanup_hook
# Prepends a cleanup hook that runs when bash exits.
add_cleanup_hook() {
    local current
    current=$(trap -p EXIT)
    if [[ -z $current ]]; then
        current=":"
    fi

    # shellcheck disable=SC2064
    trap "$1; $current" EXIT
}
