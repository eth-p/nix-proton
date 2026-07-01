#shellcheck shell=bash
#shellcheck source-path=../../
# ------------------------------------------------------------------------------
if [[ -n ${__included_nix_bash:-} ]]; then
    return
fi
__included_nix_bash=true
# ------------------------------------------------------------------------------

# Function: nix_normalize_package_name
# Normalizes a string into a nix-friendly package name.
nix_normalize_package_name() {
    sed -E 's/[^0-9a-z-]+/-/' <<<"$1"
}
