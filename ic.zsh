def_file="${funcfiletrace[1]:a:r}"
def_dir="${def_file:h}"
debug="${debug:-false}"
dry="${dry:-false}"

flag() {
	[[ ${1:l} =~ '^(y|yes|t|true|1)$' ]]
}

debug() {
	flag $debug && echo "$@"
}

debug_dump() {
	if ! flag $debug; then
		return
	fi
	for v in "$@"; do
		echo "${v}: ${(P)v}"
	done
}

debug_source() {
	debug "source $1"
	source "$1"
}

() {

	local conf="ic.conf.zsh"
	local cd="${def_dir:#/}/"

	if [[ -v root ]]; then
		root="${${root:a}:#/}/"
		def="${def_file#${root}}"
		if [[ "${def}" == "$def_file" ]]; then
			echo "invalid root ($root) - it must be parent of def_dir ($def_dir)"
			exit 1
		fi
		while true; do
			[[ -f "$cd$conf" ]] && debug_source "$cd$conf"
			[[ "$cd" == "$root" ]] && break
			cd="${${cd:h}:#/}/"
		done
	else
		root="$cd"
		while [[ -f "$cd$conf" ]]; do
			debug_source "$cd$conf"
			root="$cd"
			[[ "$cd" == "/" ]] && break
			cd="${${cd:h}:#/}/"
		done
		def="${def_file#${root}}"
	fi

}

history_prefix="${history_prefix:-${root}history/}"
vared_history_prefix="${vared_history_prefix:-${history_prefix}vared/}"
def_history_prefix="${def_history_prefix:-${history_prefix}def/$(date +%Y/%m/%d/%H_%M_%S_)}"

debug_dump root def vared_history_prefix def_history_prefix

typeset -a resolved=()

make_def_history_file() {
	typeset -g $1="${def_history_prefix}${def//\//_}_${1}"
	if [[ -v 2 ]]; then
		typeset -g $1="${(P)1}.$2"
	fi
	mkdir -p "${(P)1%/*}"
}

run() {
	typeset -ag cmd=("$@")
	resolved+=(cmd)
	if [[ $vars == 1 ]]; then
		typeset -p "${resolved[@]}"
	fi
	make_def_history_file input zsh
	typeset -p "${resolved[@]}" >"$input"
	if flag $dry; then
		echo "${cmd[@]}"
		echo "...press any key..."
		read -s -k1
	else  
		make_def_history_file output txt
		command "${cmd[@]}" | tee "$output"
	fi
}

#
# $1 - history scope (dir prefixes)
# $2 - variable name
# $3 - initial value
#
ask_vared() {
	[[ -z $1 ]] && echo "ask_vared: history scope can't be empty" && return 1
	[[ -z $2 ]] && echo "ask_vared: variable name can't be empty" && return 1

	local v=$2
	if [[ -v 3 ]]; then
		typeset -g $v=$3
	fi

	local prefix="${vared_history_prefix}"
	case $1 in 
	global) ;;
	group) prefix+="${def%/*}";;
	local) prefix+="${def}";;
	*) prefix+="${1}";;
	esac

	mkdir -p "${prefix%/*}"
	fc -pa "$prefix${v}.zsh_history"
	vared -ehcp "$v: " "$v"

	print -s "${(P)v}"
}

ask_file() {
	make_def_history_file "$1"
	cp "${def_file}.example"* "${(P)1}"
	eval "$EDITOR" "${(P)1}"
}

resolve_variant() {
	if [[ -v $1 ]]; then
		return 0
	fi
	typeset -f $1 >/dev/null && $1 && [[ -v $1 ]]
}

resolve() {
	local v
	local prefix
	local variant
	for v in ${@}; do
		prefix="/$def"
		while [[ $prefix ]]; do
			variant="${${prefix:1}//\//_}_$v"
			if resolve_variant $variant; then
				typeset -g $v=${(P)variant}
				break
			fi
			prefix="${prefix%/*}"
		done
		if ! resolve_variant $v; then
			echo "$v required, but not defined"
			exit 1
		fi
		resolved+=($v)
	done
}
