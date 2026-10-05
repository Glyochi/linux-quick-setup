#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

CURRENT_DIR="$(pwd)"
TMP_DIR="$CURRENT_DIR/tmp"
mkdir -p "${TMP_DIR}"

### Configurable install knobs. Defaults preserve the interactive host flow.
NEOVIM_VERSION="${NEOVIM_VERSION:-v0.11.1}"
NEOVIM_INSTALL_DIR="${NEOVIM_INSTALL_DIR:-/usr/local}"
# ${SUDO-sudo} (not :-) so an explicit empty SUDO disables it for root/containers.
SUDO="${SUDO-sudo}"
# Non-interactive mode: explicit PI_NONINTERACTIVE=1, or stdin is not a TTY.
PI_NONINTERACTIVE="${PI_NONINTERACTIVE:-0}"
if [[ "$PI_NONINTERACTIVE" != "1" && ! -t 0 ]]; then
	PI_NONINTERACTIVE=1
fi

run_privileged(){
	if [[ -n "$SUDO" ]]; then
		"$SUDO" "$@"
	else
		"$@"
	fi
}


### Setup neovim
print_info "Checking if neovim is installed...\n"
TARGET_NEOVIM_VERSION="$NEOVIM_VERSION"
neovim_response="$(nvim --version || echo 'False')" 
if [[ "$neovim_response" != "False" ]]; then
    read_string_lines_into_array "$neovim_response"
    neovim_response_array=("${RETURN_0[@]}")
    neovim_version="${neovim_response_array[0]#'NVIM '}" 

    if [[ "$neovim_version" == "$TARGET_NEOVIM_VERSION" ]]; then
        print_info "Neovim is already installed with version $neovim_version!\n"
    else
        prompt_message="Neovim is already installed with version $neovim_version. The prefered version is $TARGET_NEOVIM_VERSION. Do you wish to continue with your neovim version?\n"
        if [[ "$PI_NONINTERACTIVE" == "1" ]]; then
            print_warning "$prompt_message"
            print_warning "Non-interactive mode: keeping the installed Neovim version.\n"
        else
            print_warning "$prompt_message"
            tmp_array=("No" "Yes")

            MENU ${tmp_array[@]}
            response="${RETURN_0}"

            clear_previous_string "$prompt_message"

            if [[ "$response" = "No" ]]; then
                print_warning "Installing neovim aborted!\n"
                exit
            fi

            print_warning "Continuing with Neovim version $TARGET_NEOVIM_VERSION...\n"
        fi
    fi

else
	cd "$TMP_DIR"

	print_default "Downloading Neovim...\n"
	if [[ ! -f "${TMP_DIR}/nvim-linux-x86_64.tar.gz" ]]; then
        download_url="https://github.com/neovim/neovim/releases/download/$TARGET_NEOVIM_VERSION/nvim-linux-x86_64.tar.gz"
        print_info "Downloading neovim from url '$download_url'\n"
		download_response=$(wget "$download_url" || echo "False")
		if [[ "$download_response" == "False" ]]; then
			print_error "Fail to download 'nvim-linux-x86_64.tar.gz', try again perhaps?\n"
			exit
		fi
	else
		print_default "Using cached Neovim download\n"
	fi

	print_default "Extracting Neovim...\n"
	extract_response=$(tar xzvf nvim-linux-x86_64.tar.gz || echo "False")
	if [[ "$extract_response" == "False" ]]; then
		print_error "Fail to extract 'nvim-linux-x86_64.tar.gz', try again perhaps?\n"
		exit
	fi
	
	print_default "Installing Neovim...\n"
	move_response=$(run_privileged mkdir -p "${NEOVIM_INSTALL_DIR}" && run_privileged rm -fr "${NEOVIM_INSTALL_DIR}/nvim-linux-x86_64" && run_privileged mv -f "nvim-linux-x86_64" "${NEOVIM_INSTALL_DIR}" || echo "False")
	if [[ "$move_response" == "False" ]]; then
		print_error "Fail to move 'nvim-linux-x86_64.tar.gz' to '${NEOVIM_INSTALL_DIR}'\n"
		exit
	fi

	if [[ "$PI_NONINTERACTIVE" == "1" ]]; then
		print_default "Skipping ~/.bashrc update in non-interactive mode.\n"
	else
		add_to_bashrc_response=$(echo -e "\\n\\nexport PATH=\$PATH:${NEOVIM_INSTALL_DIR}/nvim-linux-x86_64/bin\\nalias vim='nvim'" >> ~/.bashrc || echo "False")
		if [[ "$add_to_bashrc_response" == "False" ]]; then
			print_error "Fail to add Neovim bin path to .bashrc, try again with sudo perhaps?\n"
			exit
		fi
	fi

	print_info "Successfully installed Neovim $TARGET_NEOVIM_VERSION\n"
	cd "$CURRENT_DIR" 
fi


print_info "Configuring up neovim...\n"
SOURCE_ROOT_DIR="${CURRENT_DIR}/neovim"
TARGET_ROOT_DIR="${HOME}/.config/nvim"
mkdir -p "${TARGET_ROOT_DIR}"



TARGET_LUA_DIR="${TARGET_ROOT_DIR}/lua"
TARGET_GLY_CUSTOM_DIR="${TARGET_LUA_DIR}/gly_custom"


# Check if init.lua has already exists. If not then symbolic link it.
source_path="${SOURCE_ROOT_DIR}/init.lua"
target_path="${TARGET_ROOT_DIR}/init.lua"	
if [[ -f "${target_path}" ]]; then
	prompt_message="Configurations at '${target_path}' already exists. Do you want to replace it?\n"
	if [[ "$PI_NONINTERACTIVE" == "1" ]]; then
		print_warning "Configurations at '${target_path}' already exist; replacing them (non-interactive).\n"
	else
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
fi

ln -fs "${source_path}" "${target_path}"

source_path="${SOURCE_ROOT_DIR}/.luarc.json"
target_path="${TARGET_ROOT_DIR}/.luarc.json"	
ln -fs "${source_path}" "${target_path}"


# Locking down on the plugins version
source_path="${SOURCE_ROOT_DIR}/lazy-lock.json"
target_path="${TARGET_ROOT_DIR}/lazy-lock.json"	
ln -fs "${source_path}" "${target_path}"

# Set up base directory + nuke if already exists
print_default "Creating directory...\n"
cd "${SOURCE_ROOT_DIR}"
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
find_content="$(find "lua/gly_custom" -type f)"
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

