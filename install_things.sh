#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

CURRENT_DIR="$(pwd)"


### Setup neovim
print_info "Configuring up neovim...\n"

# Set up base directory + nuke if already exists
print_default "Creating directory...\n"

SOURCE_ROOT_DIR="${CURRENT_DIR}/neovim"
cd "${SOURCE_ROOT_DIR}"

TARGET_ROOT_DIR="${HOME}/.config/nvim"
mkdir -p "${TARGET_ROOT_DIR}"
TARGET_LUA_DIR="${TARGET_ROOT_DIR}/lua"
mkdir -p "${TARGET_LUA_DIR}"
TARGET_CUSTOM_LUA_DIR="${TARGET_LUA_DIR}/gly_custom"
rm -fr "${TARGET_CUSTOM_LUA_DIR}"



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


#cd neovim

#find gly_custom -regex .*\.lua | xargs -I % ln -fs $PWD/neovim/% ~/.config/nvim/lua/%


print_info "Configured neovim successfully!\n"
tree "${TARGET_ROOT_DIR}"

