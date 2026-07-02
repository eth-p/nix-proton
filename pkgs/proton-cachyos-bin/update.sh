#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Adds new proton-cachyos versions to the manifests in proton-cachyos-bin.
# This should be run through `nix develop` to ensure the correct tools are
# available.
# ------------------------------------------------------------------------------
#shellcheck source-path=../../
set -euo pipefail
HERE=$(cd "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")" && pwd)
PROJECT_DIR=$(cd "${HERE}/../.." && pwd)
source "$PROJECT_DIR/lib/bash/gh-releases.bash"
source "$PROJECT_DIR/lib/bash/yq.bash"
source "$PROJECT_DIR/lib/bash/nix.bash"
# ------------------------------------------------------------------------------

# Function: tag_to_version
# Normalizes the tag name into a version string.
tag_to_version() {
	sed '
		s/^cachyos-//;
		s/-slr$//
	' <<<"$1"
}

set_latest_version() {
	local latest="$1"
	local manifest="$HERE/${2:-manifest.toml}"

	export latest
	yq_toml -i '.proton.latest = strenv(latest)' "$manifest"
}

# ------------------------------------------------------------------------------

REPO="CachyOS/proton-cachyos"

EXPECTED_ASSETS_PER_RELEASE=3

subroutine:add_version() {
	declare -g release_tag
	local manifest="$HERE/${1:-manifest.toml}"

	local version package
	version=$(tag_to_version "$release_tag")
	package=$(nix_normalize_package_name "$version")

	export version package
	yq_toml -i '
		.version[strenv(version)].package = strenv(package)
	' "$manifest"
}

subroutine:add_download_for() {
	declare -g release_tag asset
	local system="$1"
	local manifest="$HERE/${2:-manifest.toml}"

	local version asset_name hash
	version=$(tag_to_version "$release_tag")
	hash=$(github_release_asset_sri_hash "$asset")
	eval "$(yq_to_vars asset_name=.name <<<"$asset")"

	printf "\x1B[32mAdded:\x1B[m   %s \x1B[2m(%s)\x1B[m\n" "$asset_name" "$system"

	export version asset_name hash release_tag
	yq_toml -i '
		.version[strenv(version)].download.x86_64-linux = {
			"release": strenv(release_tag),
			"file": strenv(asset_name),
			"sha256": strenv(hash)
		}
	' "$manifest"
}

# Get the latest version so we know when to stop iterating.
manifest_latest_version=$(yq '.proton.latest' "$HERE/manifest.toml")

# Iterate all releases newer than the latest version in manifest.toml.
iterate_github_releases next_release "$REPO"
declare release release_is_latest release_tag
while next_release release; do
	eval "$(yq_to_vars \
		release_is_latest=.isLatest \
		release_tag=.tagName \
		<<<"$release")"

	release_version="$(tag_to_version "$release_tag")"
	printf "\n"
	printf "\x1B[1;34m==> Release %s\x1B[m\n" "$release_tag" 1>&2
	printf "\x1B[34mVersion: \x1B[m%s\n" "$release_version" 1>&2

	if [[ "$manifest_latest_version" = "$release_tag" ]]; then
		echo "Stopping. This is the current known-latest version." 1>&2
		break
	fi

	version_exists=$(version="$release_version" yq '.version[strenv(version)] != null' "$HERE/manifest.toml")
	if [[ "$version_exists" = true ]]; then
		echo "Skipping, already in manifest."
		continue
	fi

	# Add the version to the manifest files.
	iterate_github_release_assets next_asset "$REPO" "$release_tag"
	declare asset asset_name asset_digest
	num_assets=0
	num_assets_added=0
	while next_asset asset; do
		eval "$(yq_to_vars \
			asset_name=.name \
			asset_digest=.digest <<<"$asset")"

		num_assets=$((num_assets + 1))
		num_assets_added=$((num_assets_added + 1))
		case "$asset_name" in

		# x86_64-linux
		*-slr-x86_64.tar.xz)
			subroutine:add_download_for x86_64-linux manifest.toml
			;;

		# x86_64-linux (x86-64-v3)
		*-slr-x86_64_v3.tar.xz)
			subroutine:add_download_for x86_64-linux manifest-x86-64-v3.toml
			;;

		# x86_64-linux
		*-slr-arm64.tar.xz)
			subroutine:add_download_for aarch64-linux manifest.toml
			;;

		# unsupported/unknown asset
		*)
			printf "\x1B[2mSkipped:\x1B[m %s\n" "$asset_name"
			num_assets_added=$((num_assets_added - 1))
			;;
		esac
	done

	if [[ "$num_assets_added" -lt "$EXPECTED_ASSETS_PER_RELEASE" ]]; then
		printf "\x1B[31mAborting! Added %d assets (of %d) from release %s, but wanted %d.\x1B[m\n" \
			"$num_assets_added" "$num_assets" "$release_tag" "$EXPECTED_ASSETS_PER_RELEASE" 1>&2
		exit 1
	fi

	subroutine:add_version manifest.toml
	subroutine:add_version manifest-x86-64-v3.toml

	# If this release is the latest version, update the manifest.
	if [[ "$release_is_latest" = "true" ]]; then
		set_latest_version "$release_tag" manifest.toml
		set_latest_version "$release_tag" manifest-x86-64-v3.toml
	fi
done
