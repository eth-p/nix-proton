#shellcheck shell=bash
#shellcheck disable=SC2016
declare protonDisplayName
declare protonToolName

changeProtonToolName() {
	@vdfConvert@ to-json <"$1" |
		@jq@ --arg name "$2" '.compatibilitytools.compat_tools | to_entries | .[0].key = $name | from_entries' |
		@vdfConvert@ from-json >"$1.new"

	mv "$1.new" "$1"
}

changeProtonDisplayName() {
	@vdfConvert@ to-json <"$1" |
		@jq@ --arg name "$2" '.compatibilitytools.compat_tools |= (. | to_entries | .[0].value.display_name = $name | from_entries)' |
		@vdfConvert@ from-json >"$1.new"

	mv "$1.new" "$1"
}

findProtonCompatibilityToolFile() {
	local files=()
	readarray -t files < <(find -L "${1:-.}" -name compatibilitytool.vdf)
	if [[ "${#files[@]}" -eq 1 ]]; then
		printf "%s\n" "${files[0]}"
		return 0
	fi

	{
		echo "error: changeProtonName hook failed!"
		if [[ "${#files[@]}" -eq 0 ]]; then
			echo "could not find any compatibilitytool.vdf file"
		else
			echo "found multiple compatibilitytool.vdf files:"
			printf "  %s\n" "${files[@]}"
		fi
	} 1>&2
	return 1
}

_runChangeProtonNameHooks() {
	: "${protonDisplayName:=}"
	: "${protonToolName:=}"

	if [[ -z "${protonDisplayName}${protonToolName}" ]]; then
		return 0
	fi

	local toolfile
	toolfile="$(findProtonCompatibilityToolFile)"
	cp "$toolfile" "$toolfile.original"

	if [[ -n "$protonDisplayName" ]]; then
		changeProtonDisplayName "$toolfile" "$protonDisplayName"
	fi

	if [[ -n "$protonToolName" ]]; then
		changeProtonToolName "$toolfile" "$protonToolName"
	fi
}

appendToVar postBuildHooks _runChangeProtonNameHooks
