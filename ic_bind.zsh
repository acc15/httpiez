typeset "_${1}_dir"="$2"

$1() {
	local name="_${funcstack[1]}"
	local dirname="${name}_dir"
	local dir="${(P)dirname}"
	zsh -i -c "cd $dir && source $1"
}

# Completions
_$1() {
	local name="${funcstack[1]}"
	local dirname="${name}_dir"
	local dir="${(P)dirname}"
	local -a files=(${(@f)$(find "$dir" -type f -name "*.zsh" -not -name "ic.conf.zsh" -printf "%P\n" | sort)})

	local file
	local description
	
	local i
	for ((i = 1; i <= ${#files}; i++)); do
		
		file="${files[i]}"
		if ! read<"${dir}/${file}"; then
			continue
		fi

		description="$REPLY"
		if [[ "${description[1]}" != "#" ]]; then
			continue
		fi

		description="${(*)${(*)${description:1}##[[:space:]]##}%%[[:space:]]##}"
		files[$i]="${files[i]}:${description}"

	done

	_describe "$name" files
}

compdef "_$1" "$1"