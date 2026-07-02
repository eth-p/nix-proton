#shellcheck shell=bash
#shellcheck source-path=../../
# ------------------------------------------------------------------------------
if [[ -n "${__included_yq_bash:-}" ]]; then
    return
fi
__included_yq_bash=true
# ------------------------------------------------------------------------------

yq_toml() {
    yq --input-format toml --output-format toml "$@"
}

yq_json() {
    yq --input-format json --output-format json "$@"
}

yq_jsonl() {
    yq --input-format json --output-format json --indent 0 "$@"
}

yq_to_vars() {
    local script
    script=$(
        printf "%s\n" "$@" |
            sed -E 's/^([^=]+)=/"\1": (/; s/$/)/' |
            paste -sd "," -
    )

    yq --output-format shell "{$script}"
}
