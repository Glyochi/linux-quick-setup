#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail


# Setup neovim
cd "neovim"

# Create directory structure
TARGET_ROOT_DIR="~/.config/nvim"
find_content=$(find "gly_custom" -type d) 
read_string_lines_into_array "$find_content"

find_array=("${RETURN_0[@]}")

i=0 
while [[ "$i" -lt "${#find_array[@]}" ]]; do
	path="${find_array[$i]}"
	create_path="${TARGET_ROOT_DIR}/${path}"	
	echo "${create_path}"
	#mkdir create_path
done

#ln -fs $PWD/neovim/init.lua ~/.config/nvim/init.lua

#cd neovim

#find gly_custom -regex .*\.lua | xargs -I % ln -fs $PWD/neovim/% ~/.config/nvim/lua/%


