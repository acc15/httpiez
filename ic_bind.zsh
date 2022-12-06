typeset "$1"="$2"

$1() {
	(cd "${(P)${funcstack[1]}}" && zsh -i "$1")
}

# Completions
_$1() {
	local -a reqs=(${(@f)$(find "${(P)${funcstack[1]:1}}" -type f -name "*.zsh" -not -name "ic.conf.zsh" -printf "%P\n")})
	_describe epguq reqs
}

compdef "_$1" "$1"