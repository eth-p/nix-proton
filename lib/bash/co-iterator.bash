#shellcheck shell=bash
#shellcheck source-path=../../
# ------------------------------------------------------------------------------
if [[ -n ${__included_co_iterator_bash:-} ]]; then
    return
fi
__included_co_iterator_bash=true
# ------------------------------------------------------------------------------
source "$PROJECT_DIR/lib/bash/cleanup.bash"

# Function: create_co_iterator
# Creates an iterator that fetches data in the background.
#
# Example:
#
#    my_iter_impl() {
#        iter_yield "Hello!"
#        sleep 1
#        iter_yield "World!"
#    }
#
#    create_co_iterator my_iter my_iter_impl
#
#    while my_iter data; do
#       echo "$data"
#    done
declare -A _create_co_iterator_pids
create_co_iterator() {
    local name="${1?create_co_iterator: Name required}"
    local generator="${2?create_co_iterator: Iter function required}"
    local args=("${@:3}")

    # Create a fifo for communication between the generator and current process.
    local fifo
    fifo=$(mktemp)
    rm "$fifo"
    mkfifo "$fifo"

    # Spawn a background subshell to generate the data.
    local co_pid
    ({
        local write_fd
        exec {write_fd}>"$fifo"

        # shellcheck disable=SC2064
        trap "printf 'CLOSE\n' >&${write_fd}" EXIT

        # shellcheck disable=SC2329
        iter_yield() {
            printf "EMIT %q\n" "$1" >&"${write_fd}"
        }

        "$generator" "${args[@]}"
    }) &
    co_pid=$!

    # Open the fifo to read the generated data.
    # This will wait for the writer to attach.
    local read_fd
    exec {read_fd}<"$fifo"
    rm "$fifo"
    _create_co_iterator_pids["$read_fd"]="$co_pid"

    # Define the reader variable as a function.
    eval "$(printf '%s() { _create_co_iterator_impl %q %q "$@"; }' "$name" "$name" "$read_fd")"
}

_create_co_iterator_impl() {
    local __self="$1"
    local __read_fd="$2"
    local __out_var="$3"
    local __op __data
    read -r __op __data 0<&"${__read_fd}"

    case "$__op" in
    CLOSE)
        eval "$(printf '%s() { return 1; }' "$__self")"
        unset "_create_co_iterator_pids[$__read_fd]"
        return 1
        ;;
    EMIT)
        eval "$__out_var=$__data"
        return 0
        ;;
    esac
}

add_cleanup_hook _create_co_iterator_cleanup
_create_co_iterator_cleanup() {
    local co_fd
    for co_fd in "${!_create_co_iterator_pids[@]}"; do
        kill "${_create_co_iterator_pids[$co_fd]}" 2>/dev/null
    done
}
