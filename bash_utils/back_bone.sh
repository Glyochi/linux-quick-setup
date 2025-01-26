#!/usr/bin/env bash

RETURN_0=""
RETURN_1=""
RETURN_2=""
RETURN_3=""
RETURN_4=""
RETURN_5=""
RETURN_6=""
RETURN_7=""
RETURN_8=""
RETURN_9=""


clear_return_variables() {
	RETURN_0=""
	RETURN_1=""
	RETURN_2=""
	RETURN_3=""
	RETURN_4=""
	RETURN_5=""
	RETURN_6=""
	RETURN_9=""
}


COLOR_TEXT_BLACK=$(tput setaf 0)
if [[ $? -ne 0 ]]; then
	echo "Black text not supported"
fi
COLOR_TEXT_RED=$(tput setaf 1)
if [[ $? -ne 0 ]]; then
	echo "Red text not supported"
fi
COLOR_TEXT_GREEN=$(tput setaf 2)
if [[ $? -ne 0 ]]; then
	echo "Green text not supported"
fi
COLOR_TEXT_YELLOW=$(tput setaf 3)
if [[ $? -ne 0 ]]; then
	echo "Yellow text not supported"
fi
COLOR_TEXT_BLUE=$(tput setaf 4)
if [[ $? -ne 0 ]]; then
	echo "Blue text not supported"
fi
COLOR_TEXT_MAGNETA=$(tput setaf 5)
if [[ $? -ne 0 ]]; then
	echo "Magneta text not supported"
fi
COLOR_TEXT_CYAN=$(tput setaf 6)
if [[ $? -ne 0 ]]; then
	echo "Cyan text not supported"
fi
COLOR_TEXT_WHITE=$(tput setaf 7)
if [[ $? -ne 0 ]]; then
	echo "White text not supported"
fi
COLOR_TEXT_NONE=$(tput setaf 8)
if [[ $? -ne 0 ]]; then
	echo "None color text not supported"
fi
COLOR_TEXT_RESET=$(tput setaf 9)
if [[ $? -ne 0 ]]; then
	echo "Reset color text not supported"
fi


COLOR_BACKGROUND_BLACK=$(tput setab 0)
if [[ $? -ne 0 ]]; then
	echo "Black background text not supported"
fi
COLOR_BACKGROUND_RED=$(tput setab 1)
if [[ $? -ne 0 ]]; then
	echo "Red background text not supported"
fi
COLOR_BACKGROUND_GREEN=$(tput setab 2)
if [[ $? -ne 0 ]]; then
	echo "Green background text not supported"
fi
COLOR_BACKGROUND_YELLOW=$(tput setab 3)
if [[ $? -ne 0 ]]; then
	echo "Yellow background text not supported"
fi
COLOR_BACKGROUND_BLUE=$(tput setab 4)
if [[ $? -ne 0 ]]; then
	echo "Blue background text not supported"
fi
COLOR_BACKGROUND_MAGNETA=$(tput setab 5)
if [[ $? -ne 0 ]]; then
	echo "Magenta background text not supported"
fi
COLOR_BACKGROUND_CYAN=$(tput setab 6)
if [[ $? -ne 0 ]]; then
	echo "Cyan background text not supported"
fi
COLOR_BACKGROUND_WHITE=$(tput setab 7)
if [[ $? -ne 0 ]]; then
	echo "White background text not supported"
fi
COLOR_BACKGROUND_NONE=$(tput setab 8)
if [[ $? -ne 0 ]]; then
	echo "None background text not supported"
fi
COLOR_BACKGROUND_RESET=$(tput setab 9)
if [[ $? -ne 0 ]]; then
	echo "Reset background text not supported"
fi


COLOR_EFFECT_BOLD=$(tput bold)
if [[ $? -ne 0 ]]; then
	echo "Bold text not supported"
fi
COLOR_EFFECT_START_UNDERLINED=$(tput smul)
if [[ $? -ne 0 ]]; then
	echo "Start underlined text not supported"
fi
COLOR_EFFECT_END_UNDERLINED=$(tput rmul)
if [[ $? -ne 0 ]]; then
	echo "End underelined text not supported"
fi
COLOR_EFFECT_REVERSED=$(tput rev)
if [[ $? -ne 0 ]]; then
	echo "Reversed text not supported"
fi
COLOR_EFFECT_BLINK=$(tput blink)
if [[ $? -ne 0 ]]; then
	echo "Blink text not supported"
fi
COLOR_EFFECT_INVISIBLE=$(tput invis)
if [[ $? -ne 0 ]]; then
	echo "Invisible text not supported"
fi
COLOR_EFFECT_START_STANDOUT=$(tput smso)
if [[ $? -ne 0 ]]; then
	echo "Start standout text not supported"
fi
COLOR_EFFECT_END_STANDOUT=$(tput rmso)
if [[ $? -ne 0 ]]; then
	echo "End standout text not supported"
fi


SPECIAL_CHARACTERS_ARRAY=()

COLOR_ENDING=$(tput sgr0)
#echo "?"
#echo "${COLOR_TEXT_BLACK@Q}"
#echo "${COLOR_TEXT_RED@Q}"
#echo "${COLOR_TEXT_GREEN@Q}"
#echo "${COLOR_TEXT_YELLOW@Q}"
#echo "${COLOR_TEXT_BLUE@Q}"
#echo "${COLOR_TEXT_MAGNETA@Q}"
#echo "${COLOR_TEXT_CYAN@Q}"
#echo "${COLOR_TEXT_WHITE@Q}"
#echo "${COLOR_TEXT_NONE@Q}"
#echo "${COLOR_TEXT_RESET@Q}"
#
#
#echo "${COLOR_BACKGROUND_BLACK@Q}"
#echo "${COLOR_BACKGROUND_RED@Q}"
#echo "${COLOR_BACKGROUND_GREEN@Q}"
#echo "${COLOR_BACKGROUND_YELLOW@Q}"
#echo "${COLOR_BACKGROUND_BLUE@Q}"
#echo "${COLOR_BACKGROUND_MAGNETA@Q}"
#echo "${COLOR_BACKGROUND_CYAN@Q}"
#echo "${COLOR_BACKGROUND_WHITE@Q}"
#echo "${COLOR_BACKGROUND_NONE@Q}"
#echo "${COLOR_BACKGROUND_RESET@Q}"
#
#echo "${COLOR_EFFECT_BOLD@Q}"
#echo "${COLOR_EFFECT_START_UNDERLINED@Q}"
#echo "${COLOR_EFFECT_END_UNDERLINED@Q}"
#echo "${COLOR_EFFECT_REVERSED@Q}"
#echo "${COLOR_EFFECT_BLINK@Q}"
#echo "${COLOR_EFFECT_INVISIBLE@Q}"
#echo "${COLOR_EFFECT_START_STANDOUT@Q}"
#echo "${COLOR_EFFECT_END_STANDOUT@Q}"
#
#echo "${COLOR_ENDING@Q}"
#echo "?"




SPECIAL_CHARACTERS_ARRAY+=("${COLOR_TEXT_BLACK}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_TEXT_RED}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_TEXT_GREEN}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_TEXT_YELLOW}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_TEXT_BLUE}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_TEXT_MAGNETA}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_TEXT_CYAN}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_TEXT_WHITE}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_TEXT_NONE}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_TEXT_RESET}")

SPECIAL_CHARACTERS_ARRAY+=("${COLOR_BACKGROUND_BLACK}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_BACKGROUND_RED}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_BACKGROUND_GREEN}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_BACKGROUND_YELLOW}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_BACKGROUND_BLUE}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_BACKGROUND_MAGNETA}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_BACKGROUND_CYAN}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_BACKGROUND_WHITE}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_BACKGROUND_NONE}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_BACKGROUND_RESET}")

SPECIAL_CHARACTERS_ARRAY+=("${COLOR_EFFECT_BOLD}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_EFFECT_START_UNDERLINED}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_EFFECT_END_UNDERLINED}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_EFFECT_REVERSED}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_EFFECT_BLINK}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_EFFECT_INVISIBLE}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_EFFECT_START_STANDOUT}")
SPECIAL_CHARACTERS_ARRAY+=("${COLOR_EFFECT_END_STANDOUT}")

SPECIAL_CHARACTERS_ARRAY+=("${COLOR_ENDING}")

#extract_current_cursor_position () {
#	clear_return_variables	
#	local PREV_IFS="$IFS"
#	local pos_x pos_y
#
#	local cur_pos
#	read -sdR -p $'\E[6n' cur_pos
#	# Strip decoration character <ESC>[
#	#echo "${cur_pos@Q}"
#	cur_pos=${cur_pos#*[}
#	#echo "${cur_pos@Q}"
#	local tmp_array=()
#	IFS=';' tmp_array=($cur_pos)
#
#	pos_x=${tmp_array[0]}
#	pos_y=${tmp_array[1]}
#
#	#echo "|$pos_x $pos_y|"
#	#sleep 2
#	IFS="$PREV_IFS"
#	RETURN_0="$pos_x"
#	RETURN_1="$pos_y"
#}

extract_current_cursor_position () {
	clear_return_variables	
	local PREV_IFS="$IFS"
	local pos_x pos_y

	local success=false
	local number_exp='^[0-9]+$'
	
	while [[ "$success" = false ]]; do
		exec < /dev/tty
		oldstty=$(stty -g)
		stty raw -echo min 0
		echo -en "\033[6n" > /dev/tty
		IFS=';' read -r -d R -a pos
		stty $oldstty
		
		#echo "${pos[0]:2}"
		#echo "[[ "${pos[0]:2}" =~ $number_exp ]]"
		#sleep 2
		if ! [[ "${pos[0]:2}" =~ $number_exp ]] || ! [[ "${pos[1]}" =~ $number_exp ]]; then
			continue
		fi
		eval "pos_x=$((${pos[0]:2} - 2))"
		eval "pos_y=$((${pos[1]} - 1))"
		success=true
	done

	IFS="$PREV_IFS"
	RETURN_0="$pos_x"
	RETURN_1="$pos_y"
}

# If lines count is 0, then clear the current line. If lines count = 1, then clear the current and 1 previous line. So on and so forth
clear_previous_lines(){
	clear_return_variables
	local LINES_COUNT="$1"
	extract_current_cursor_position
	local cur_x="$RETURN_0"
	local cur_y="$RETURN_1"
	local prev_x="$RETURN_0"
	local prev_y="$RETURN_1"
	
	# Move to the start of the line	
	tput cup "$cur_x" "0"

	# Get the new cursor position because even tho all we do is go to the start of the line
	# The row number changes still wtf
	extract_current_cursor_position
	cur_x="$RETURN_0"
	cur_y="$RETURN_1"

	local i=0	
	while [[ "i" -lt "$(("${prev_x}" - "${cur_x}"))" ]]; do
		tput cud1		
		i="$(("$i" + "1"))"
	done

	
	local i=0
	while [[ "$i" -lt "$LINES_COUNT" ]]; do
		# Move up one line then clear that line
		tput cuu1
		i="$(("$i" + "1"))"
	done

	tput ed
}

clear_previous_string(){
	clear_return_variables
	local PREV_STR="$1"
	local PREV_IFS="$IFS"

		
	# Count cols of the stripped display string (No color/special characters counted)
	strip_string_format "$PREV_STR"
	local stripped_prev_str="$RETURN_0"

	# Added a signal character at the start and end to capture empty string on both ends before or after new line
	local signal_char="?"
	stripped_prev_str="${signal_char}${stripped_prev_str}${signal_char}"
	local total_display_rows=0
	local terminal_cols=0
	terminal_cols="$(tput cols)"

	local stripped_lines_array=()
	# print it out then capture output because that seems to be the only way for new line to be registered
	IFS=$'\n' stripped_lines_array=($(print "${stripped_prev_str}"))

	for i in "${!stripped_lines_array[@]}"; do	
		local line="${stripped_lines_array[$i]}"
		
		# Remove signal character if the first or last line
		if [[ "$i" == 0 ]]; then
			line="${line:1}"
		fi
		
		if [[ $(("$i" + "1")) == "${#stripped_lines_array[@]}" ]]; then
			line="${line:0:-1}"
		fi

		# If the line is empty we still want to count it
		if [[ "$line" = "" ]]; then
			total_display_rows=$(("$total_display_rows" + 1))
			continue
		fi
		# Caculate the number of rows taken to display that print, round up by adding (denomurator - 1) to the numerator
		total_display_rows=$(((("${#line}" + "$terminal_cols" - 1) / "$terminal_cols") + "$total_display_rows"))
	done


	# If total display rows is 1, that means we only want to clear the current row => clear_previous_lines 0
	# If total display rows > 1, say x, that means we only want to clear the current row and x - 1 previous rows  => clear_previous_lines x - 1
	#echo "$(("$total_display_rows" - "1"))"
	clear_previous_lines "$(("$total_display_rows" - "1"))"
	IFS="$PREV_IFS"
}


LAST_PRINT_CONTENT=""
LAST_LOG_CONTENT=""

LOG_LEFT_PAD_LENGTH=21


print() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$*"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}

print_default() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_TEXT_NONE$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_default_blink() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_BLINK$COLOR_TEXT_NONE$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_default_bold() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_TEXT_NONE$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_default_underlined() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_START_UNDERLINED$COLOR_TEXT_NONE$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}



print_info() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_TEXT_GREEN$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_info_blink() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_BLINK$COLOR_TEXT_GREEN$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_info_bold() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_TEXT_GREEN$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_info_underlined() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_START_UNDERLINED$COLOR_TEXT_GREEN$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}




print_warning() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_TEXT_YELLOW$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_warning_blink() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_BLINK$COLOR_TEXT_YELLOW$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_warning_bold() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_TEXT_YELLOW$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_warning_underlined() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_START_UNDERLINED$COLOR_TEXT_YELLOW$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}



print_error() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_TEXT_RED$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_error_blink() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_BLINK$COLOR_TEXT_RED$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_error_bold() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_TEXT_RED$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_error_underlined() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_START_UNDERLINED$COLOR_TEXT_RED$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}



print_debug() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_TEXT_MAGNETA$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_debug_blink() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_BLINK$COLOR_TEXT_MAGNETA$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_debug_bold() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_TEXT_MAGNETA$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_debug_underlined() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_START_UNDERLINED$COLOR_TEXT_MAGNETA$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}




print_trace() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_TEXT_CYAN$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_trace_blink() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_BLINK$COLOR_TEXT_CYAN$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_trace_bold() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_TEXT_CYAN$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}
print_trace_underlined() {
	local PREV_IFS="$IFS"
	IFS=" "
	LAST_PRINT_CONTENT="$COLOR_EFFECT_BOLD$COLOR_EFFECT_START_UNDERLINED$COLOR_TEXT_CYAN$*$COLOR_ENDING"
	printf "%b%s" "$LAST_PRINT_CONTENT"
	IFS="$PREV_IFS"
}


#print_default "Default\n"
#print_default_blink "Default\n"
#print_default_bold "Default\n"
#print_default_underlined "Default\n"
#print_info "Info\n"
#print_info_blink "Info\n"
#print_info_bold "Info\n"
#print_info_underlined "Info\n"
#print_error "Error\n"
#print_error_blink "Error\n"
#print_error_bold "Error\n"
#print_error_underlined "Error\n"
#print_debug "Debug\n"
#print_debug_blink "Debug\n"
#print_debug_bold "Debug\n"
#print_debug_underlined "Debug\n"

linux_join_path(){
	clear_return_variables
	local INPUTS=("$@")
	
	local result="${INPUTS[0]}"
	result="${result%/}"
	local i=1
	while [[ "$i" -lt "${#INPUTS[@]}" ]]; do
		input="${INPUTS[$i]}"
		input="${input#/}"	
		input="${input%/}"	

		if [[ "$input" != "" ]]; then
			result="${result}/${input}"
		fi
		i=$(("$i" + "1"))
	done

	result="${result%/}"
	RETURN_0="${result}"
}

create_string() {
	clear_return_variables
	local pad_str="$1"
	local length=$2

	local missing_part_length
	local missing_part
	missing_part_length=0
	missing_part=""
	
	local result
	result="$pad_str"

	if [[ $length -le 0 ]]; then
		RETURN_0=""
		return
	fi	

	if [[ $length -eq 1 ]]; then
		RETURN_0="$result"
		return
	fi	

	
	while [[ $((${#result} * 2)) -le $length ]]; do
		result="$result$result"
	done

	if [[ ${#result} -lt $length ]]; then
		missing_part_length=$(($length - ${#result}))
		create_string "$pad_str" $missing_part_length
		missing_part="$RETURN_0"
	fi

	result="$result$missing_part"
	RETURN_0="$result"
	return
}


log_default(){
	local text
	local current_date_time
	current_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	local left_pad_length
	left_pad_length=$(($LOG_LEFT_PAD_LENGTH - ${#current_date_time} - 2))
	local left_pad
	
	create_string " " $left_pad_length
	left_pad="$RETURN_0"

	LAST_LOG_CONTENT=""
	print_default "[$left_pad$current_date_time]"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_default " "
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_default_bold "$1\n"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
}

log_trace(){
	local text
	local current_date_time
	current_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	local left_pad_length
	left_pad_length=$(($LOG_LEFT_PAD_LENGTH - ${#current_date_time} - 2))
	local left_pad
	
	create_string " " $left_pad_length
	left_pad="$RETURN_0"

	LAST_LOG_CONTENT=""
	print_default "[$left_pad$current_date_time]"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_trace " "
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_trace_bold "$1\n"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
}



log_info(){
	local text
	local current_date_time
	current_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	local left_pad_length
	left_pad_length=$(($LOG_LEFT_PAD_LENGTH - ${#current_date_time} - 2))
	local left_pad
	
	create_string " " $left_pad_length
	left_pad="$RETURN_0"

	LAST_LOG_CONTENT=""
	print_default "[$left_pad$current_date_time]"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_info " "
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_info_bold "$1\n"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
}


log_info_blink(){
	local text
	local current_date_time
	current_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	local left_pad_length
	left_pad_length=$(($LOG_LEFT_PAD_LENGTH - ${#current_date_time} - 2))
	local left_pad
	
	create_string " " $left_pad_length
	left_pad="$RETURN_0"

	LAST_LOG_CONTENT=""
	print_default "[$left_pad$current_date_time]"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_info " "
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_info_blink "$1\n"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
}



log_debug(){
	local text
	local current_date_time
	current_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	local left_pad_length
	left_pad_length=$(($LOG_LEFT_PAD_LENGTH - ${#current_date_time} - 2))
	local left_pad
	
	create_string " " $left_pad_length
	left_pad="$RETURN_0"

	LAST_LOG_CONTENT=""
	print_default "[$left_pad$current_date_time]"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_info " "
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_debug_bold "$1\n"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
}


log_warning(){
	local text
	local current_date_time
	current_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	local left_pad_length
	left_pad_length=$(($LOG_LEFT_PAD_LENGTH - ${#current_date_time} - 2))
	local left_pad
	
	create_string " " $left_pad_length
	left_pad="$RETURN_0"

	LAST_LOG_CONTENT=""
	print_default "[$left_pad$current_date_time]"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_info " "
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_warning_bold "$1\n"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
}

log_warning_underlined(){
	local text
	local current_date_time
	current_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	local left_pad_length
	left_pad_length=$(($LOG_LEFT_PAD_LENGTH - ${#current_date_time} - 2))
	local left_pad
	
	create_string " " $left_pad_length
	left_pad="$RETURN_0"

	LAST_LOG_CONTENT=""
	print_default "[$left_pad$current_date_time]"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_info " "
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_warning_underlined "$1\n"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
}

log_error(){
	local text
	local current_date_time
	current_date_time=$(date +"%Y-%m-%d %H:%M:%S")
	local left_pad_length
	left_pad_length=$(($LOG_LEFT_PAD_LENGTH - ${#current_date_time} - 2))
	local left_pad
	
	create_string " " $left_pad_length
	left_pad="$RETURN_0"

	LAST_LOG_CONTENT=""
	print_default "[$left_pad$current_date_time]"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_info " "
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
	print_error "$1\n"
	LAST_LOG_CONTENT="$LAST_LOG_CONTENT$LAST_PRINT_CONTENT"
}



MENU() {
	clear_return_variables
	#tput smcup
	#tput sc
	

	local INDENT="    "
	local NON_INDICATOR=" "	
	local INDICATOR="> "
	local SELECTED=0
	local OPTIONS=("$@")
	local LENGTH=$#
	

	local menu_content=""
	MENU_PRINT() {
		clear_previous_string "$menu_content"	
		menu_content=""
		
		for (( i=0;i<(($LENGTH)); i++))
		do
			if [[ $SELECTED -eq $i ]]
			then
				print_default "$INDENT "
				menu_content="${menu_content}${LAST_PRINT_CONTENT}"
				print_debug_bold "$INDICATOR"
				menu_content="${menu_content}${LAST_PRINT_CONTENT}"
				print_info_bold "${OPTIONS[$i]}\n"
				menu_content="${menu_content}${LAST_PRINT_CONTENT}"
			else
				print_default "$INDENT"
				menu_content="${menu_content}${LAST_PRINT_CONTENT}"
				print_debug_bold "$NON_INDICATOR "
				menu_content="${menu_content}${LAST_PRINT_CONTENT}"
				print_warning "${OPTIONS[$i]}\n"
				menu_content="${menu_content}${LAST_PRINT_CONTENT}"
			fi
		done
	}

	MENU_PRINT
	
	# -r for interpreting backslash not as an escape character
	# -s for hiding user input and not show it on the screen
	# -n1 for only taking one key input
	while read -rsn1 input
	do
		#print_error $input
		case $input in
		"A")
			if [[ $SELECTED -lt 1 ]]
			then
			  SELECTED=$(($LENGTH-1))
			else
			  SELECTED=$(($SELECTED-1))
			fi
			MENU_PRINT
			;;
		"B")
			if [[ $SELECTED -gt $(($LENGTH-2)) ]]
			then
			  SELECTED=0
			else
			  SELECTED=$(($SELECTED+1))
			fi
			MENU_PRINT
			;;
		"") 
			clear_previous_string "$menu_content"	
			break
			;;	
		esac
	done
	
	#clear
	#tput rmcup
	RETURN_0="${OPTIONS[$SELECTED]}"
	RETURN_1="$SELECTED"
	#RETURN_0="$(($SELECTED))"
}

strip_string_format() {
	clear_return_variables
	local str="${1@Q}"

	for char in "${SPECIAL_CHARACTERS_ARRAY[@]}"; do
		if [[ "$char" = "" ]]; then
			continue
		fi
		local pattern="${char@Q}"
		pattern="${pattern:2:-1}"

		str="${str//"${pattern}"/}"
	done

	eval "str=$str"
	
	RETURN_0="${str}"
}

USER_INPUT(){
	clear_return_variables
	local PROMPT_STR="$1" DEFAULT_VALUE="$2" HIDDEN="${3:-false}"
	local input
	

	local total_display_cols=0
	local display_str=""
	if [[ "$DEFAULT_VALUE" != "" ]]; then
		display_str="$PROMPT_STR ($COLOR_TEXT_CYAN$DEFAULT_VALUE$COLOR_ENDING): "
	else
		display_str="$PROMPT_STR: "
	fi


	# Display and wait for user input
	print "$display_str"
	if [[ "$HIDDEN" = "false" ]]; then
		# Added a new line here because unlike -s, on enter it creates an extra line
		read -p "" input
		display_str="${display_str}${input}\n"
	else
		read -s -p "" input
		display_str="${display_str}${input}"
	fi
	
	clear_previous_string "$display_str"

	input="${input:-$DEFAULT_VALUE}"

	#print "$display_str"

	RETURN_0="$input"
	RETURN_1="$display_str"
}


#log_info 'reeeeeeeeeeeeee'
#print $LAST_PRINT_CONTENT
#print $LAST_LOG_CONTENT
#echo
#OPTIONS=('test' 'test1---------------------------------------------------------------------------------------------------------------------------------------------------------------' 'test2')
#MENU ${OPTIONS[@]}
#RESULT=$?

#echo $RESULT

