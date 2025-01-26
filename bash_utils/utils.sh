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


check_sso_and_configure() {
	clear_return_variables
	# Name of the SSO session to check for
	local SSO_SESSION_NAME="install"
	# List all configured AWS CLI profiles
	local configured_profiles=()
	configured_profiles=$(aws configure list-profiles)
	# Check if the SSO session name is in the list of configured profiles
	if echo "${configured_profiles}" | grep -q "^${SSO_SESSION_NAME}$" && aws s3 ls --profile "${SSO_SESSION_NAME}" > /dev/null 2>&1; then
		log_info "SSO session '${SSO_SESSION_NAME}' is already configured and still valid."
	else
		log_warning "SSO session '${SSO_SESSION_NAME}' not found or expired. Configuring now..."
		print_warning "\nYou will need to enter the following values to configure the AWS CLI:\n"
		print_trace "SSO session name: "
		print_info "install\n"

		print_trace "SSO start URL: "
		print_info "https://musco.awsapps.com/start/#\n"

		print_trace "SSO region: "
		print_info "us-east-1\n"

		print_trace "SSO registration scopes: "
		print_info "(leave blank)\n"

		print_warning "\nTHEN OPEN THE LINK AND LOGIN\n"

		print_trace "Select the "
		print_info "aws-emerging-tech-sandbox"

		print_trace " account\n"
		print_trace "CLI trace client region: "
		print_info "us-east-1\n"

		print_trace "CLI trace output format: "
		print_info "(leave blank)\n"

		print_trace "CLI profile name: "
		print_info "install\n\n"

		print_trace "Executing configuration command...\n"
		aws configure sso --no-browser --region us-east-1 --color on
	fi
}



git_check_repo_exists(){
	clear_return_variables
	local PREV_IFS="$IFS"
	local REPO_PATH="$1"
	local current_path
	current_path="$(pwd)"

	local tags_array=()
	local is_git_repo=false
	if [ -d $REPO_PATH ]; then
		cd "$REPO_PATH"
		
		local is_git_repo
		is_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null || echo false)"
	fi

	cd "$current_path"
	IFS="$PREV_IFS"
	RETURN_0="$is_git_repo"
}

git_clone_repo() {
	local REPO_NAME="$1" REPO_URL="$2" WORKING_DIR="$3" REPO_PATH="$4"
	# Remove https to used for checking git repo source later
	local REPO_SRC
	REPO_SRC="${REPO_URL#'https://'}"
	local repo_exists=false PREV_WORKING_DIR=""
	PREV_WORKING_DIR="$(pwd)"
	# Checking if repo already exists
	log_info "Checking if repo $REPO_NAME exists..."

	if [ -d $REPO_PATH ]; then
		cd $REPO_PATH
		local is_git_repo
		is_git_repo=$(git rev-parse --is-inside-work-tree)
		local cur_repo_url=""
		log_debug "'$REPO_PATH' is a repo: $is_git_repo"
		if [[ $is_git_repo == true ]]; then
			cur_repo_src=$(git config --get remote.origin.url)
			log_debug "Repo url: $cur_repo_src"
			if [[ "$cur_repo_src" == *"$REPO_SRC" ]]; then
				repo_exists=true 			
			else
				log_error "Directory '$REPO_PATH' is a git repo but from a wrong origin '$cur_repo_url', should be from origin '$REPO_SRC"
				log_error "Please delete directory '$REPO_PATH'"
				exit 1
			fi		
		else
			log_error "Directory '$REPO_PATH' is not a git repo"
			exit 1
		fi
	fi

	if [[ $repo_exists == false ]]; then
		log_warning "Repo $REPO_NAME does not exist in path: '$REPO_PATH'"
		cd "$WORKING_DIR"
		log_info "Cloning repository $REPO_NAME at url: $REPO_URL\n"
		git clone "$REPO_URL"
		log_info "Cloning completed"
	else
		log_info "Repo $REPO_NAME exists in path: '$REPO_PATH'"
	fi

	cd "$PREV_WORKING_DIR"
}


git_update_repo() {
	local REPO_NAME="$1" REPO_URL="$2" REPO_PATH="$3"
	local repo_exists=false PREV_WORKING_DIR
	PREV_WORKING_DIR="$(pwd)"
	local PREV_IFS="$IFS"
	# Checking if repo already exists
	log_debug "Checking if repo $REPO_NAME exists..."

	git_check_repo_exists "$REPO_PATH"
	local repo_exists="$RETURN_0"
	
	if [[ "$repo_exists" = true ]]; then
		cd "$REPO_PATH"

		log=$(git config credential.helper 'cache --timeout=3600')
		repo_exists=true
		log_debug 'Fetching metadata'
		local tmp
		# This should get all tags + commits
		tmp=$(git fetch --tags --force)
		tmp=$(git fetch)
		# Try to merge the branches (bring them up to date. Dont exit if they fail) 
		tmp=$(git merge || true)
		log_debug 'Fetching new tags and commit successfully'  
	else
		log_debug "Repo $REPO_NAME does not exists in path '$REPO_PATH'"
		exit 1
	fi

	cd "$PREV_WORKING_DIR"
}

git_clean_repo_current_checkout(){
	
	clear_return_variables
	local PREV_IFS="$IFS"
	local REPO_PATH="$1"
	local current_path
	current_path="$(pwd)"

	git_check_repo_exists "$REPO_PATH"
	local clean_succeeded=false
	local repo_exists="$RETURN_0"
	if [[ "$repo_exists" == true ]]; then
		cd "$REPO_PATH"

		if git clean -fd 2>/dev/null; then
			if git reset --hard 2>/dev/null; then
				clean_succeeded=true
			fi
		fi
	else
		log_error "Path '$REPO_PATH' is not a git repo"
		exit 1
	fi

	cd "$current_path"
	RETURN_0="$clean_succeeded"
}

git_repo_check_commit_exists(){
	
	clear_return_variables
	local PREV_IFS="$IFS"
	local REPO_PATH="$1"
	local COMMIT="$2"
	local current_path
	current_path="$(pwd)"

	git_check_repo_exists "$REPO_PATH"
	local repo_exists="$RETURN_0"

	local commit_exists=false
	if [[ "$repo_exists" == true ]]; then
		cd "$REPO_PATH"

		local output
		local error
		# In case the branch was checkoued or given a raw commit
		output="$(git cat-file -t $COMMIT 2>/dev/null || echo "Commit does not exists")"

		# If the output is 'commit', then the commit exists
		if [[ "$output" = "commit" ]]; then
			commit_exists=true
		fi
	
		# In case the branch wasnt checkout yet and still known as 'origin/$COMMIT'
		output="$(git cat-file -t "origin/$COMMIT" 2>/dev/null || echo "Commit does not exists")"

		# If the output is 'commit', then the commit exists
		if [[ "$output" = "commit" ]]; then
			commit_exists=true
		fi
	else
		log_error "Path '$REPO_PATH' is not a git repo"
		exit 1
	fi

	cd "$current_path"
	RETURN_0="$commit_exists"
}

git_repo_checkout(){
	
	clear_return_variables
	local PREV_IFS="$IFS"
	local REPO_PATH="$1"
	local CHECKOUT="$2"
	local current_path
	current_path="$(pwd)"

	git_check_repo_exists "$REPO_PATH"
	local repo_exists="$RETURN_0"
	local checkout_succeeded=false
	if [[ "$repo_exists" == true ]]; then
		cd "$REPO_PATH"

		if git checkout "$CHECKOUT" 2>/dev/null; then
			if git merge || true; then
				checkout_succeeded=true
			fi
		fi
	else
		log_error "Path '$REPO_PATH' is not a git repo"
		exit 1
	fi

	cd "$current_path"
	
	RETURN_0="$checkout_succeeded"
}




git_get_repo_tags_array(){
	clear_return_variables
	local PREV_IFS="$IFS"
	local REPO_PATH="$1"
	local current_path
	current_path="$(pwd)"

	local tags_array=()
	git_check_repo_exists "$REPO_PATH"
	local repo_exists="$RETURN_0"
	if [[ "$repo_exists" = true ]]; then
		cd "$REPO_PATH"
		local tags_string
		tags_string="$(git tag)"
		IFS=$'\n' tags_array=($tags_string) 
	else
		log_error "Path '$REPO_PATH' is not a git repo"
		exit 1
	fi

	cd "$current_path"
	IFS="$PREV_IFS"
	RETURN_0=("${tags_array[@]}")
}

git_get_repo_branch_and_commit(){
	clear_return_variables
	local PREV_IFS="$IFS"
	local REPO_PATH="$1"
	local current_path
	current_path="$(pwd)"

	local branch=""
	local commit=""
	if [ -d $REPO_PATH ]; then
		cd "$REPO_PATH"
		local branch_string
		branch_string="$(git branch --show-current)"
		trim_string "$branch_string"
		branch="$RETURN_0"
		local commit_string
		commit_string="$(git show --oneline -s)"
		commit="${commit_string%% *}"
	else
		log_error "Git repo path '$REPO_PATH' does not exists"
		exit 1
	fi

	cd "$current_path"
	IFS="$PREV_IFS"
	RETURN_0="$branch"
	RETURN_1="$commit"
}

git_repo_get_uncommitted_changes_count(){
	clear_return_variables
	local PREV_IFS="$IFS"
	local REPO_PATH="$1"
	local current_path
	current_path="$(pwd)"

	local uncommitted_changes_count
	if [ -d $REPO_PATH ]; then
		cd "$REPO_PATH"
		uncommitted_changes_count="$(git status --porcelain=v1 2>/dev/null | wc -l)"
	else
		log_error "Git repo path '$REPO_PATH' does not exists"
		exit 1
	fi

	cd "$current_path"
	IFS="$PREV_IFS"
	RETURN_0="$uncommitted_changes_count"
}


git_repo_checkout_branch_or_commit(){
	clear_return_variables
	local PREV_IFS="$IFS"
	local REPO_PATH="$1"
	local COMMIT="$2"
	local current_path
	current_path="$(pwd)"

	local branch=""
	local commit=""
	if [ -d $REPO_PATH ]; then
		cd "$REPO_PATH"
		local temp
		temp=$(git checkout "$COMMIT")
	else
		log_error "Git repo path '$REPO_PATH' does not exists"
		exit 1
	fi

	cd "$current_path"
	IFS="$PREV_IFS"
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

extract_ua_api_image_url_from_docker_compose_file_content_array(){
	clear_return_variables
	local CONTENT_ARRAY=("$@")
	local PREV_IFS="$IFS"


	
	local parsing_ua_api=false
	local YAML_INDENT="  "
	local url=""
	for i in "${!CONTENT_ARRAY[@]}"; do
		local line="${CONTENT_ARRAY[$i]}"
		# Remove comment lines
		line="${line%%#*}"

		case "$line" in
			"${YAML_INDENT}api:"*)
				parsing_ua_api=true
				;;
			"${YAML_INDENT}${YAML_INDENT}image:"*)
				if [[ "$parsing_ua_api" = true ]]; then
					url="${line##*image:}"
					trim_string "$url"
					url="$RETURN_0"
					break
				fi
				;;
			*)
				;;
		esac
	done

	if [[ "$url" = "" ]]; then
		log_debug "Couldn't find api image url. Returning empty string''"
	fi


	IFS="$PREV_IFS"
	RETURN_0="$url"
}

replace_ua_api_mounted_volumes_in_docker_compose_file_content_array(){
	clear_return_variables
	local PREV_IFS="$IFS"
	local i=1
	local DOCKER_COMPOSE_CONTENT_ARRAY_LENGTH="${@:$i:1}"
	i=$(($i + 1))
	local DOCKER_COMPOSE_CONTENT_ARRAY=("${@:$i:$DOCKER_COMPOSE_CONTENT_ARRAY_LENGTH}")
	i=$(($i + $DOCKER_COMPOSE_CONTENT_ARRAY_LENGTH))
	local VOLUMES_ARRAY_LENGTH=("${@:$i:1}")
	i=$(($i + 1))
	local VOLUMES_ARRAY=("${@:$i:$VOLUMES_ARRAY_LENGTH}")

	local result_content_array=()
	
	local parsing_ua_api=false
	local parsing_volumes=false
	local YAML_INDENT="  "
	i=0
	while [[ "$i" -lt "${#DOCKER_COMPOSE_CONTENT_ARRAY[@]}" ]]; do
		local line="${DOCKER_COMPOSE_CONTENT_ARRAY[$i]}"
		# Remove comment from the line
		cleaned_line="${line%%#*}"
		trim_string "$cleaned_line"
		local trimmed_line="$RETURN_0"


		if [[ "$parsing_volumes" = false ]]; then
			case "$cleaned_line" in
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
			
			result_content_array+=("$line")
		else
			case "$trimmed_line" in 
				"- "*)
					# Ignore all volumes from the docker file
					;;
				"")
					# Ignore all empty lines. These are not a good indicators for hwhen parsing volumes is completed
					;;
				*)
					# Stop parsing volumes, decrement index i by one to not miss a line
					parsing_volumes=false
					i=$(($i - 1))

					local volume=""
					for j in ${!VOLUMES_ARRAY[@]}; do
						volume="${VOLUMES_ARRAY[$j]}"
						trim_string "$volume"
						volume="$RETURN_0"
						result_content_array+=("$YAML_INDENT$YAML_INDENT$YAML_INDENT- '$volume'")
					done
					;;
			esac


		fi

		i=$(($i + 1))
	done

	IFS="$PREV_IFS"
	RETURN_0=("${result_content_array[@]}")
}



replace_ua_api_image_url_in_docker_compose_file_content_array(){
	clear_return_variables
	local URL="$1"
	local CONTENT_ARRAY=("${@:2}")
	local PREV_IFS="$IFS"


	
	local result_content_array=()
	local parsing_ua_api=false
	local YAML_INDENT="  "
	for i in "${!CONTENT_ARRAY[@]}"; do
		local line="${CONTENT_ARRAY[$i]}"
		# Remove comment from the line
		line="${line%%#*}"


		case "$line" in
			"${YAML_INDENT}api:"*)
				parsing_ua_api=true
				;;
			"${YAML_INDENT}${YAML_INDENT}image:"*)
				if [[ "$parsing_ua_api" = true ]]; then
					line="${YAML_INDENT}${YAML_INDENT}image: $URL"
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
		result_content_array+=("$line")
	done


	IFS="$PREV_IFS"
	RETURN_0=("${result_content_array[@]}")
}


docker_pull_image(){
	clear_return_variables
	local CONTAINER_REGISTRY="$1"
	local CONTAINER_NAME="$2"
	local TAG="$3"

	check_sso_and_configure

	log_debug "Registry: $CONTAINER_REGISTRY"
	log_debug "Name: $CONTAINER_NAME"
	log_debug "Tag: $TAG"

	# Save screen content to only display docker pull log
	tput smcup

	local log 
	log="$(sudo aws ecr get-login-password --region us-east-2 --profile install | sudo docker login -u AWS --password-stdin https://182863709418.dkr.ecr.us-east-2.amazonaws.com)"
	log_debug "$log"

	
       	sudo docker pull "$CONTAINER_REGISTRY/$CONTAINER_NAME:$TAG"

	# Restore screen content to show what was before docker pull
	sleep 10
	tput rmcup
	log_debug "Pulled image '$CONTAINER_NAME' version '$TAG' successfully"
}

docker_get_downloaded_images(){
	clear_return_variables
	local DOCKER_REGISTRY="$1"
	local CONTAINER_NAME="$2"
	local PREV_IFS="$IFS"	
	local temp_array=()
	IFS=$'\n' temp_array=($(sudo docker images))	

	local repos=()
	local tags=()
	local ids=()
	local hardcoded_repo_index=0
	local hardcoded_tag_index=1
	local hardcoded_id_index=2

	# Start at index 1 to skip the first line (header line)
	local i=1
	while [[ "$i" -lt "${#temp_array[@]}" ]]; do
		local line="${temp_array[$i]}"
		
		# Remove the docker registry prefix
		line="${line#$DOCKER_REGISTRY}"
		# Remove the / prefix
		line="${line#/}"
		trim_string "$line"
		line="$RETURN_0"

		local cols=()
		IFS=$' ' cols=($line)
		
		case "${cols[$hardcoded_repo_index]}" in 
			"$CONTAINER_NAME")
				repos+=("${cols[$hardcoded_repo_index]}")
				tags+=("${cols[$hardcoded_tag_index]}")
				ids+=("${cols[$hardcoded_id_index]}")
				;;
			*)
				;;
		esac

		i="$(("$i" + "1"))"
	done


	IFS="$PREV_IFS"
	RETURN_0=("${repos[@]}")
	RETURN_1=("${tags[@]}")
	RETURN_2=("${ids[@]}")

}


extract_fields_and_values_from_env_file_content_array(){
	clear_return_variables
	local CONTENT_ARRAY=("$@")
	local PREV_IFS="$IFS"

	local fields_array=()
	local values_array=()
	
	for line in "${CONTENT_ARRAY[@]}"; do
		line="${line%%#*}"
		if [[ "$line" = "" ]]; then
			continue
		fi
		local temp_array
		IFS='=' temp_array=($line) 
		local field="${temp_array[0]}"
		local value="${temp_array[1]}"

		value="${value#\"}"
		value="${value%\"}"
		fields_array+=("$field")
		values_array+=("$value")
	done

	IFS="$PREV_IFS"
	RETURN_0=("${fields_array[@]}")
	RETURN_1=("${values_array[@]}")
}

check_valid_work_directory(){
	clear_return_variables
	local WORK_DIR="$1"

	local directory_exists=false
	local docker_compose_exists=false
	if [[ -d "$tmp_working_dir" ]]; then
		directory_exists=true

		linux_join_path "$WORK_DIR" "docker-compose.yml"
		local docker_compose_path="$RETURN_0"

		if [[ -f "$docker_compose_path" ]]; then
			docker_compose_exists=true	
		fi
	fi

	RETURN_0="$directory_exists"
	RETURN_1="$docker_compose_exists"
}

prompt_valid_configuration_directory(){
	clear_return_variables
	local DEFAULT_DIR="$1"

	USER_INPUT "Configuration directory" "$DEFAULT_DIR" 
	local tmp_working_dir="$RETURN_0"
	local directory_exists=false
	local docker_compose_exists=false
	check_valid_work_directory "$tmp_working_dir"
	directory_exists="$RETURN_0"
	docker_compose_exists="$RETURN_1"
	while [[ "$directory_exists" = false ]] || [[ "$docker_compose_exists" = false ]]; do
		local tmp_error_msg=""
		if [[ "$directory_exists" = false ]]; then
			print_error "Path '$tmp_working_dir' does not exists\n" 
		elif [[ "$docker_compose_exists" = false ]]; then
			print_error "Path '$tmp_working_dir' does not have the docker-compose.yml file\n" 
		fi
		tmp_error_msg="${tmp_error_msg}${LAST_PRINT_CONTENT}"

		USER_INPUT "Configuration directory" "$DEFAULT_DIR" 
		tmp_working_dir="$RETURN_0"
		check_valid_work_directory "$tmp_working_dir"
		directory_exists="$RETURN_0"
		docker_compose_exists="$RETURN_1"

		clear_previous_string "$tmp_error_msg"
	done
	
	RETURN_0="$tmp_working_dir"
}

