#!/usr/bin/env bash
. back_bone.sh
set -Eeuo pipefail



trim_string(){
	clear_return_variables
	local trimmed_str="$1"
	local size_before=${#trimmed_str} size_after=0
	#print_error "|"
	#print_info "$trimmed_str"
	#print_error "|\n"
	while [[ "$size_before" -ne "$size_after" ]]; do
		size_before=${#trimmed_str}
		trimmed_str="${trimmed_str#[[:space:]]}"
		trimmed_str="${trimmed_str%[[:space:]]}"
		size_after=${#trimmed_str}
		#print_error "|"
		#print_info "$trimmed_str"
		#print_error "|\n"
	done

	RETURN_0="$trimmed_str"
}

sort_array_descending() {
	clear_return_variables
	local UNSORTED_ARRAY=("$@")

	local length="${#UNSORTED_ARRAY[@]}"
	if [[ "$length" -le 1 ]]; then
		RETURN_0=("${UNSORTED_ARRAY[@]}")
		return
	fi

	local m=$(("$length" / 2))
	
	local left_array=(${UNSORTED_ARRAY[@]:0:$m})
	local right_array=(${UNSORTED_ARRAY[@]:$m:$(($length - $m))})

	sort_array_descending "${left_array[@]}"
	left_array=("${RETURN_0[@]}")
	sort_array_descending "${right_array[@]}"
	right_array=("${RETURN_0[@]}")

	local sorted_array=()
	
	local i=0
	local j=0

	while [[ "$i" -lt "${#left_array[@]}" ]] && [[ "$j" -lt "${#right_array[@]}" ]]; do
		local left="${left_array[$i]}"
		local right="${right_array[$j]}"

		if [[ "$left" > "$right" ]]; then
			sorted_array+=("$left")
			i=$(($i + 1))
		else
			sorted_array+=("$right")
			j=$(($j + 1))
		fi
	done

	while [[ "$i" -lt "${#left_array[@]}" ]]; do
		sorted_array+=("${left_array[$i]}")
		i=$(($i + 1))
	done
	while [[ "$j" -lt "${#right_array[@]}" ]]; do
		sorted_array+=("${right_array[$j]}")
		j=$(($j + 1))
	done

	RETURN_0=("${sorted_array[@]}")
}




read_string_lines_into_array(){
	local INPUT_STRING="$1"
	local PREV_IFS="$IFS"
	clear_return_variables

	local array=()
	while IFS= read -r line; do
		array+=("$line")
	done <<< "$INPUT_STRING"

	IFS="$PREV_IFS"
	RETURN_0=("${array[@]}")
}

read_file_lines_into_array(){
	local FILE_PATH="$1"
	clear_return_variables
	local array

	if [ ! -f $FILE_PATH ]; then
		log_error "File does not exist in path: '$FILE_PATH'"
		exit 1
	fi
	
	file_content=$(cat "$FILE_PATH")
	read_string_lines_into_array "$file_content"

	array=("${RETURN_0[@]}")
	RETURN_0=("${array[@]}")	
}

write_array_to_file(){
	clear_return_variables
	local FILE_PATH="$1"
	local ARRAY=("${@:2}")

	if [ ! -f $FILE_PATH ]; then
		log_debug "File does not exist in path: '$FILE_PATH'. Creating file..."
		touch "$FILE_PATH"
	fi

	log_debug "Writing to file '$FILE_PATH'"
	> "$FILE_PATH"
	for line in "${ARRAY[@]}"; do
		printf "%s\n" "$line" >> "$FILE_PATH"
	done
	log_debug "Finished writing to file '$FILE_PATH'"
}

extract_ua_api_mounted_volumes_from_docker_compose_file_content_array(){
	clear_return_variables
	local CONTENT_ARRAY=("$@")
	local PREV_IFS="$IFS"
	

	local mount_sources=() mount_targets=()
	local parsing_ua_api=false
	local parsing_volumes=false
	local YAML_INDENT="  "

	local i=0

	while [[ "$i" -lt "${#CONTENT_ARRAY[@]}" ]]; do
		local line="${CONTENT_ARRAY[$i]}"
		# Remove comment lines
		line="${line%%#*}"
		trim_string "$line"
		local trimmed_line="$RETURN_0"
		

		# Skip empty string because it breaks the volumes parsing	
		if [[ "$trimmed_line" != "" ]]; then

			if [[ "$parsing_volumes" = false ]]; then
				case "$line" in
					"${YAML_INDENT}api:"*)
						parsing_ua_api=true
						;;
					"${YAML_INDENT}${YAML_INDENT}volumes:"*)
						if [[ "$parsing_ua_api" = true ]]; then
							parsing_volumes=true
						fi
						;;
					"${YAML_INDENT}"[[:graph:]]*)
						if [[ "$parsing_ua_api" = true ]]; then
							parsing_ua_api=false
						fi
						;;
					*)
						;;
				esac
			else
				case "$trimmed_line" in 
					"- "*)
						# Remove the '-' before and single quote/double quote around the volumes
						# Because you can have no quotes around the volumes, we have to manually remove
						# the '-' before the volumes to catch for those cases
						trimmed_line="${trimmed_line#*-}"
						trim_string "$trimmed_line"
						trimmed_line="$RETURN_0"

						trimmed_line="${trimmed_line#*\'}"
						trimmed_line="${trimmed_line#*\"}"
						trimmed_line="${trimmed_line%*\'}"
						trimmed_line="${trimmed_line%*\"}"
						
						local temp_array	
						IFS=':' temp_array=($trimmed_line) 
						
						if [[ "${#temp_array[@]}" -lt 2 ]]; then
							log_error "Docker-compose.yml file error, invalid volume '$trimmed_line'"
							exit 1
						fi

						local mount_source="${temp_array[0]}"
						local mount_target="${temp_array[1]}"
						mount_sources+=("$mount_source")			
						mount_targets+=("$mount_target")			
						;;
					*)
						# Stop parsing volumes, decrement index i by one to not miss a line
						parsing_volumes=false
						i=$(($i - 1))
						;;
				esac


			fi

		fi 
		i=$(($i + 1))
	done

	IFS="$PREV_IFS"
	RETURN_0=("${mount_sources[@]}")
	RETURN_1=("${mount_targets[@]}")
}



