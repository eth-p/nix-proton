#shellcheck shell=bash
#shellcheck source-path=../../
# ------------------------------------------------------------------------------
if [[ -n "${__included_gh_releases_bash:-}" ]]; then
    return
fi
__included_gh_releases_bash=true
# ------------------------------------------------------------------------------
source "$PROJECT_DIR/lib/bash/co-iterator.bash"
source "$PROJECT_DIR/lib/bash/yq.bash"

# Function: iterate_github_releases
# Creates an iterator for each release in a GitHub repo.
#
# Example:
#
#    iterate_github_releases next_release some/repo
#    while next_release release; do
#        yq -I4 --prettyPrint <<<"$release"
#    done
iterate_github_releases() {
    create_co_iterator "$1" \
        _iterate_github_releases_gen \
        "$2"
}

_iterate_github_releases_gen() {
    local repo="$1"
    local release=
    while read -r release; do
        iter_yield "$release"
    done < <(
        gh release list \
            --repo "$repo" \
            --exclude-drafts \
            --exclude-pre-releases \
            --limit 100 \
            --json tagName,isLatest |
            yq_jsonl '.[]'
    )
}

# Function: iterate_github_release_assets
# Creates an iterator for each release in a GitHub repo.
#
# Example:
#
#    iterate_github_release_assets next_asset some/repo v1.2.3
#    while next_asset asset; do
#        yq -I4 --prettyPrint <<<"$asset"
#    done
iterate_github_release_assets() {
    create_co_iterator "$1" \
        _iterate_github_release_assets_gen \
        "$2" "$3"
}

_iterate_github_release_assets_gen() {
    local repo="$1"
    local release="$2"
    local asset=
    while read -r asset; do
        iter_yield "$asset"
    done < <(
        gh release view "$release" \
            --repo "$repo" \
            --json assets |
            yq_jsonl '.assets[]'
    )
}

github_release_asset_sri_hash() {
    local asset="$1"
	local asset_digest asset_url asset_name
	eval "$(yq_to_vars \
		asset_url=.url \
        asset_name=.name \
		asset_digest=.digest <<<"$asset")"

	if [[ "$asset_digest" =~ ^sha256: ]]; then
		nix-hash --to-sri "$asset_digest"
		return 0
	fi

    printf "Need to fetch release to find hash: %s\n" "$asset_name" 1>&2
	curl --silent --fail --location --output - "$asset_url" |
        nix-hash --type sha256 --base32 --sri --flat /dev/stdin
}
