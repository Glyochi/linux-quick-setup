#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

CURRENT_DIR="$(pwd)"


### Setup neovim
print_info "Configuring up neovim...\n"
SOURCE_ROOT_DIR="${CURRENT_DIR}/neovim"
TARGET_ROOT_DIR="${HOME}/.config/nvim"
TARGET_LUA_DIR="${TARGET_ROOT_DIR}/lua"
TARGET_GLY_CUSTOM_DIR="${TARGET_LUA_DIR}/gly_custom"


# Check if init.lua has already exists. If not then symbolic link it.
source_path="${SOURCE_ROOT_DIR}/init.lua"
target_path="${TARGET_ROOT_DIR}/init.lua"	
if [[ -f "${target_path}" ]]; then
	prompt_message="Configurations at '${target_path}' already exists. Do you want to replace it?\n" 
	print_warning "$prompt_message"
	tmp_array=("No" "Yes")

	MENU ${tmp_array[@]}
	response="${RETURN_0}"

	clear_previous_string "$prompt_message"

	if [[ "$response" = "No" ]]; then
		print_warning "Configuring neovim aborted.\n"
		exit
	fi
fi

ln -fs "${source_path}" "${target_path}"

source_path="${SOURCE_ROOT_DIR}/.luarc.json"
target_path="${TARGET_ROOT_DIR}/.luarc.json"	
ln -fs "${source_path}" "${target_path}"



# Set up base directory + nuke if already exists
print_default "Creating directory...\n"
cd "${SOURCE_ROOT_DIR}"
mkdir -p "${TARGET_ROOT_DIR}"
mkdir -p "${TARGET_LUA_DIR}"
rm -fr "${TARGET_GLY_CUSTOM_DIR}"




# Create lua directory structure
find_content=$(find "lua/gly_custom" -type d) 
read_string_lines_into_array "$find_content"

find_array=("${RETURN_0[@]}")

i=0 
while [[ "$i" -lt "${#find_array[@]}" ]]; do
	path="${find_array[$i]}"
	target_path="${TARGET_ROOT_DIR}/${path}"	
	mkdir -p "${target_path}"
	i=$(($i + 1))
done

# Symbolic link lua files
print_default "Symoblically linking files...\n"
find_content=$(find "lua/gly_custom" -type f) 
read_string_lines_into_array "$find_content"

find_array=("${RETURN_0[@]}")

i=0 
while [[ "$i" -lt "${#find_array[@]}" ]]; do
	path="${find_array[$i]}"
	source_path="${SOURCE_ROOT_DIR}/${path}"
	target_path="${TARGET_ROOT_DIR}/${path}"	
	ln -fs "${source_path}" "${target_path}"
	i=$(($i + 1))
done





print_info "Configured neovim successfully!\n"
tree "${TARGET_ROOT_DIR}"

