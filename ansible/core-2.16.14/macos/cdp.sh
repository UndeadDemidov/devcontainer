#!/bin/bash

# `cdp` to activate an interactive way to navigate directories
# note: for consistency, treat all arrays as 0-indexed
cdp() {
    local MAX_VOPTS=8 MAX_DIR_WIDTH=60 SEARCH_ICON="⌕"
    local SEARCH_PREFIX=" $(tput bold)${SEARCH_ICON}$(tput sgr0)$(tput el) "

    local is_bash=$([[ -n $BASH ]] && echo true || echo false)
    local is_zsh=$([[ -n $ZSH_NAME ]] && echo true || echo false)

    # helper functions
    translate_input() {
        # args: input
        case $1 in
            $'\n'|'')      echo enter;;
            $'\177'|$'\b') echo backspace;;
            "[A")          echo up;;
            "[B")          echo down;;
            "[C")          echo right;;
            "[D")          echo left;;
            *)             echo "$1";;
        esac
    }
    zsh_key_input() {
        read -sk1 key
        [[ $key = $'\e' ]] && read -sk2 -t 0.1 key
        translate_input "$key"
    }
    bash_key_input() {
        IFS='' read -rsn1 key
        [[ $key = $'\e' ]] && read -rsn2 -t 1 key
        translate_input "$key"
    }

    index_array() {
        # args: index, array
        local i=$1
        shift 1
        echo "${@:$((i+1)):1}" # only way for array indexing to work for both bash and zsh
        # ${@:0:1} will return the function name
    }
    index_of() {
        # args: element, array
        local e=$1
        shift 1

        local i=0
        for s in "$@"; do
            if [[ $s = "$e" ]]; then
                echo $i
                return
            fi
            ((i++))
        done
        echo -1
    }

    cursor_to_first_option() {
        tput rc; tput cud1; tput cud1
    }
    print_option() {
        echo "    $1 $(tput el)"
    }
    print_selected() {
        echo "   $(tput setab 7)$(tput setaf 0) $1 $(tput sgr0)$(tput el)"
    }

    render_options() {
        # precondition: cursor is at the first line of the options
        # args: selected index (of visible options), all visible options (as array)
        local selected=$1
        shift 1
        local options=("$@")

        local i=0
        for s in "${options[@]}"; do
            if [[ $i -eq $selected ]]; then print_selected "$s"; else print_option "$s"; fi
            ((i++))
        done
    }

    render_search_string() {
        # args: search string
        # postcondition: cursor is at the first line of the options
        tput rc; tput cud1; tput cuf 4
        echo "$(tput setaf 3)${search_str}$(tput el)$(tput sgr0)_"
    }

    render_heading() {
        # args: none
        tput rc
        local pwd_str=$(pwd)
        local lim_width=$(($(tput cols) - 20 - 5))  # 20 for "Change directory to ", 5 for buffer
        [[ lim_width -gt MAX_DIR_WIDTH ]] && lim_width=$MAX_DIR_WIDTH
        [[ ${#pwd_str} -gt $lim_width ]] && pwd_str="...${pwd_str:$((${#pwd_str} - lim_width + 3))}"
        echo "$(tput smul)Change directory to $(tput bold)${pwd_str}$(tput sgr0)$(tput el)"
    }

    # initialize variables
    local search_str='' prev_dir='' orig_dir=$PWD
    local num_vopts=$(($(tput lines) - 2 - 1))  # 2 fixed lines, 1 for buffer
    [[ $num_vopts -gt $MAX_VOPTS ]] && num_vopts=$MAX_VOPTS

    local regex_chars='$^.?+*(){}[]/'
    escape_regex() {
        # args: string
        local str=$1 c=''
        for ((i=0; i<${#regex_chars}; i++)); do
            c=${regex_chars:$i:1}
            str=${str//"$c"/\\$c}
        done
        echo "$str"
    }

    # initialize interface
    tput civis
    stty -echo
    tpuc sc && render_heading
    echo -e "$SEARCH_PREFIX"
    for ((i=0; i<num_vopts; i++)); do echo; done
    tput cuu $((num_vopts + 2))
    tput sc

    # expected output:
    # - directory line (fixed line)
    # - search string line (fixed line)
    # - options (opts, each on their own line)
    # - blank lines to fill up the rest of the screen as needed

    # cleanup functions
    cleanup_base() {
        tput rc
        tput ed
        tput cnorm
        stty echo
        trap - INT
    }

    cleanup_exit() {
        cleanup_base
        echo "Working directory changed: $(tput bold)$(pwd)$(tput el)$(tput sgr0)"
    }

    cleanup_interrupt() {
        cleanup_base
        cd $orig_dir
        echo "Restored working directory: $(tput bold)$(pwd)$(tput el)$(tput sgr0)"
        return
    }

    trap 'cleanup_interrupt; return' INT

    # main loop
    # opts: options, fopts: filtered options, vopts: visible options
    while true; do
        # determine the options
        local fopts=() opts=()
        local subdirs=$( (ls -F | grep /$ | sort -f) )
        if [[ -n $subdirs ]]; then
            [[ $is_bash = true ]] && IFS=$'\n' read -r -d '' -a opts <<< "$subdirs"
            [[ $is_zsh = true ]] && opts+=("${(f)subdirs}")
        fi
        opts+=('../')

        # jump to previous dir option (if left arrow key was pressed)
        local sel=0
        local prev_dir_index=$(index_of "$prev_dir" "${opts[@]}")
        [[ $prev_dir_index -ne -1 ]] && sel=$prev_dir_index;
        local inp=''

        local first_vopt=$((sel - num_vopts + 1))
        [[ $first_vopt -lt 0 ]] && first_vopt=0
        local do_rerender_opts=true did_update_search=true

        render_heading

        # loop while still in the same directory
        while true; do
            if [[ $did_update_search = true ]]; then
                render_search_string "$search_str"
                # filter options by search string
                fopts=()
                if [[ -z $search_str ]]; then
                    fopts=("${opts[@]}")
                else
                    for opt in "${opts[@]}"; do
                        local opt_l="" regex=""
                        if [[ $is_bash = true ]]; then
                            opt_l=$(echo "$opt" | tr '[:upper:]' '[:lower:]')
                            regex=$(echo "$search_str" | tr '[:upper:]' '[:lower:]')
                        else
                            opt_l=${opt:l}
                            regex=${search_str:l}
                        fi
                        regex=$(escape_regex "$regex")
                        [[ "$opt_l" =~ $regex ]] && fopts+=("$opt")
                    done
                fi
                [[ "${#fopts[@]}" -eq 0 ]] && fopts+=('../')
                local num_fopts=${#fopts[@]}
            else
                cursor_to_first_option
            fi
            did_update_search=false

            if [[ $do_rerender_opts = true ]]; then
                # determine "scroll" position
                if [[ $sel -lt $first_vopt ]]; then first_vopt=$sel
                elif [[ $sel -ge $((first_vopt + num_vopts)) ]]; then first_vopt=$((sel - num_vopts + 1)); fi

                # print options
                vopts=( "${fopts[@]:$first_vopt:$num_vopts}" )
                render_options $((sel - first_vopt)) "${vopts[@]}"
                tput ed
            fi
            do_rerender_opts=true

            # user key control
            [[ $is_bash = true ]] && inp=$(bash_key_input) || inp=$(zsh_key_input)
            case $inp in
                left)        [[ $PWD != "$HOME" ]] && break;;
                up)          ((sel--)); [[ $sel -lt 0 ]] && sel=$((num_fopts - 1));;
                down)        ((sel++)); [[ $sel -ge $num_fopts ]] && sel=0;;
                right|enter) break;;
                '\')         do_rerender_opts=false;;
                backspace)
                    search_str="${search_str%?}"
                    sel=0
                    did_update_search=true;;
                *)
                    search_str+=$inp
                    sel=0
                    did_update_search=true;;
            esac
        done

        # cd accordingly
        case $inp in
            right) cd "$(index_array "$sel" "${fopts[@]}")"; prev_dir='';;
            left)  prev_dir=$(printf '%s/' "${PWD##*/}"); cd ..;;
            enter) break;;
        esac

        search_str=''
    done

    cleanup_exit
}