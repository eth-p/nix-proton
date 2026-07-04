#!/usr/bin/env bash
set -euo pipefail

PROGRAM=nix-proton-link
HERE=$(cd "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")" && pwd)
manpage_file="$HERE"/nix-proton-link.1

show_help() {
    if command -v man &>/dev/null; then
        man "$manpage_file"
        return 0
    fi

    show_usage
}

show_usage() {
    printf "usage: nix-proton-link [-c] [-t target_dir] source ...\n"
}

failf() {
    declare -g PROGRAM
    printf "%s: $1\n" "$PROGRAM" "${@:2}" 1>&2
    exit 1
}

# ------------------------------------------------------------------------------
# Parse options.
# ------------------------------------------------------------------------------

opt_source_dirs=()
opt_target_dir=
opt_cleanup_dead_links=false

argv=("$@")
argv_i=0

arg_requires_value() {
    declare -g argv argv_i opt opt_value
    if [[ "${#argv[@]}" -le $argv_i ]]; then
        failf "option '%s' requires a value" "$opt"
    fi

    opt_value="${argv[$((argv_i++))]}"
    if [[ "$opt_value" =~ ^- ]]; then
        failf "option '%s' requires a value" "$opt"
    fi
}

while [[ "${#argv[@]}" -gt $argv_i ]]; do
    opt="${argv[$((argv_i++))]}"
    case "$opt" in
    -h | --help)
        show_help 1>&2
        exit 0
        ;;
    -t)
        arg_requires_value
        opt_target_dir="$opt_value"
        ;;
    -c)
        opt_cleanup_dead_links=true
        ;;
    -*)
        printf "%s: unknown option '%s'\n" "$PROGRAM" "$opt" 1>&2
        show_usage 1>&2
        exit 1
        ;;
    *)
        opt_source_dirs+=("$opt")
        ;;
    esac
done

if [[ "${#opt_source_dirs[@]}" -eq 0 ]]; then
    opt_source_dirs=("${HOME}/.nix-profile/share/steam/compatibilitytools.d")
fi

# If the target directory isn't set explicitly, infer it by searching for
# the Steam root directory.
if [[ -z "$opt_target_dir" ]]; then
    possible_steam_dirs=(
        "$HOME/.steam/root"
        "$HOME/.steam/steam"
        "$HOME/.local/share/Steam"
    )

    if [[ -n "${XDG_DATA_HOME:-}" ]]; then
        possible_steam_dirs+=(
            "${XDG_DATA_HOME}/Steam"
            "${XDG_DATA_HOME}/steam"
        )
    fi

    for steam_dir in "${possible_steam_dirs[@]}"; do
        if [[ -d "${steam_dir}/compatibilitytools.d" ]]; then
            opt_target_dir="${steam_dir}"
            break
        fi
        if [[ -d "${steam_dir}/config/libraryfolders.vdf}" ]]; then
            opt_target_dir="${steam_dir}"
            mkdir "${steam_dir}/compatibilitytools.d"
            break
        fi
    done
fi

# ------------------------------------------------------------------------------
# Validate target directory.
# ------------------------------------------------------------------------------

if [[ -z "$opt_target_dir" ]]; then
    failf "could not find Steam directory"
fi
if ! [[ -e "$opt_target_dir" ]]; then
    failf "'%s' does not exist" "$opt_target_dir"
fi
if ! [[ -d "$opt_target_dir" ]]; then
    failf "'%s' is not directory" "$opt_target_dir"
fi
if ! [[ -r "$opt_target_dir" ]]; then
    failf "'%s' is not readable by the current user" "$opt_target_dir"
fi
if ! [[ -w "$opt_target_dir" ]]; then
    failf "'%s' is not writable by the current user" "$opt_target_dir"
fi

# ------------------------------------------------------------------------------
# Validate source directories and scan for Protons.
# ------------------------------------------------------------------------------

proton_dirs=()

for dir in "${opt_source_dirs[@]}"; do
    if ! [[ -e "$dir" ]]; then
        failf "'%s' does not exist" "$dir"
    fi
    if ! [[ -d "$dir" ]]; then
        failf "'%s' is not directory" "$dir"
    fi
    if ! [[ -r "$dir" ]]; then
        failf "'%s' is not readable by the current user" "$dir"
    fi

    # Is the directory itself a Proton tool?
    if [[ -f "${dir}/compatibilitytool.vdf" ]]; then
        proton_dirs+=("$(realpath -s -- "$dir")")
        continue
    fi

    for subdir in "$dir"/*; do
        if [[ -f "${subdir}/compatibilitytool.vdf" ]]; then
            proton_dirs+=("$(realpath -s -- "$subdir")")
        fi
    done
done

# ------------------------------------------------------------------------------
# Clean dead symlinks.
# ------------------------------------------------------------------------------

if [[ "$opt_cleanup_dead_links" = true ]]; then
    printf "Removing dead links in '%s'...\n" "$opt_target_dir"
    for target in "${opt_target_dir}"/*; do
        if [[ -L "$target" ]] && ! [[ -e "$target" ]]; then
            printf "Unlinking '%s'...\n" "$(basename -- "$target")"
            rm "$target"
        fi
    done
fi

# ------------------------------------------------------------------------------
# Create symlinks.
# ------------------------------------------------------------------------------

if [[ "${#proton_dirs[@]}" -eq 0 ]]; then
    printf "Did not find any Proton installations to link." 1>&2
    exit 0
fi

printf "Creating links at '%s'...\n" "$opt_target_dir"
for proton_dir in "${proton_dirs[@]}"; do
    target="${opt_target_dir}/$(basename -- "$proton_dir")"

    # Check if the target already exists.
    if [[ -e "$target" ]]; then
        if ! [[ -L "$target" ]]; then
            failf "symlink already exists at '%s'" "$target"
        fi

        target_link=$(readlink -- "$target")
        if [[ "$target_link" != "$proton_dir" ]]; then
            failf "symlink already exists at '%s'" "$target"
        fi

        printf "Already linked '%s'\n" "$(basename -- "$proton_dir")"
        continue
    fi

    # Create a symlink to the target.
    printf "Linking '%s'...\n" "$(basename -- "$proton_dir")"
    ln -t "$opt_target_dir" -s "$proton_dir"
done
