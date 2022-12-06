typeset "${1}_dir"="$2"

$1() {
	local name="${funcstack[1]}"
	local dirname="${name}_dir"
	local dir="${(P)dirname}"
	(cd "$dir" && zsh -i "$1")
}

# Completions
_$1() {
	local name="${funcstack[1]:1}"
	local dirname="${name}_dir"
	local dir="${(P)dirname}"
	local -a files=(${(@f)$(find "$dir" -type f -name "*.zsh" -not -name "ic.conf.zsh" -printf "%P\n")})
	_describe "$name" files
}

compdef "_$1" "$1"