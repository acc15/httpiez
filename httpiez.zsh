request_file="${funcfiletrace[1]:a:r}"
request_dir="${request_file:h}"

() {

	local conf="httpiez.conf.zsh"
	local cd="${request_dir:#/}/"

	if [[ -v root ]]; then
		root="${${root:a}:#/}/"
		request="${request_file#${root}}"
		
		if [[ "${request}" == "$request_file" ]]; then
			echo "invalid root ($root) - it must be parent of request_dir ($request_dir)"
			exit 1
		fi

		while true; do
			
			if [[ -f "$cd$conf" ]]; then
				echo "sourcing $cd$conf"
				source "$cd$conf"
			fi
			
			if [[ "$cd" == "$root" ]]; then
				break
			fi

			cd="${${cd:h}:#/}/"

		done
	else
		
		root="$cd"
		while [[ -f "$cd$conf" ]]; do

			echo "sourcing $cd$conf"
			source "$cd$conf"
			root="$cd"

			if [[ "$cd" == "/" ]]; then
				break
			fi

			cd="${${cd:h}:#/}/"

		done
		request="${request_file#${root}}"

	fi

}

history_dir="${history_dir:-${root}/history}"
vared_history_dir="${vared_history_dir:-${history_dir}/vared}"
request_history_dir="${request_history_dir:-${history_dir}/request/$(date +%Y/%m/%d)}"

typeset -a resolved=()

make_request_history_file() {
	local n="${request//\//_}_${1}_XXXXXX"
	if [[ -v 2 ]]; then
		n="${n}.$2"
	fi
	mkdir -p "$request_history_dir"
	mktemp -p "$request_history_dir" "$n"
}

http() {
	typeset -a cmd=(http -v --pretty none $@)
	resolved+=(cmd)
	if [[ $vars == 1 ]]; then
		typeset -p "${resolved[@]}"
	fi
	typeset -p "${resolved[@]}" >"$(make_request_history_file "req" "zsh")"
	if [[ $dry == 1 ]]; then
		echo "${cmd[@]}"
		echo "...press any key..."
		read -s -k1
		return
	fi 
	command "${cmd[@]}"
}

#
# $1 - history scope (dir prefixes)
# $2 - variable name
# $3 - initial value
#
ask_vared() {
	local v=$2
	if [[ -v 2 ]]; then
		typeset -g $v=$3
	fi

	local dir="${vared_history_dir}"
	case $1 in 
	global)
		;;

	group)
		dir+="/${request%/*}"
		;;

	request)
		dir+="/${request}"
		;;

	*)
		dir+="/${1}"
		;;
	esac

	mkdir -p "$dir"
	fc -pa "$dir/${v}.zsh_history"

	vared -ehcp "$v: " "$v"
	if [[ $? != 0 || -z "${(P)v}" ]]; then
		echo "$v required, but not defined"
		exit 1
	fi

	print -s "${(P)v}"
}

ask_file() {
	local v=$1
	typeset -g $v="$(make_request_history_file "$v")"
	cp "${request_file}.example"* "${(P)v}"
	eval "$EDITOR" "${(P)v}"
}

resolve_variant() {
	if [[ -v $1 ]]; then
		return 0
	fi
	typeset -f $1 >/dev/null && $1
}

resolve() {
	local v
	local prefix
	local variant
	for v in ${@}; do
		prefix="/$request"
		while [[ ! -z $prefix ]]; do
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
