#!/bin/bash

# Automatically detect functions in a script.
# - Enables autocomplete for functions in a script
# - Executes function passed in an argument
# - Displays a select with function names if run w/o arguments
# Works only if shebang is present in parent script. Otherwise there's no way to find caller, it is always /bin/bash.
# ln -s /path/to/auto-options.sh ~/.local/bin/auto-options
# echo source auto-options setup-autocomplete >> ~/.bashrc
# Then add "auto-options" at the bottom of a script.
# Private functions can be declared by adding a comment with the word 'private': function name { # private
# 03-21-2021

function getFunctions {
  file="$1"
  functions=$(gawk 'match($0, /(function )?([a-zA-Z0-9\-_]+)( +)?(\(\))?( +)?(\{)( +?# +?private)?/, matches) {if (!matches[7]) print matches[2]}' "$file")
  echo "$functions"
}

if [[ $1 == "setup-autocomplete" ]]; then
  _script()
  {
    _init_completion || return

    local cmd="$1"
    local ext="${cmd##*.}"

    if [[ $ext != "sh" ]] || [[ -z $(grep "auto-options" "$cmd") ]]; then # get default completion if its not an .sh file or doesn't contain this script's name
      __load_completion "$cmd" && return 124
      complete -F _minimal -- "$cmd" && return 124
    fi

    local COMMANDS=$(getFunctions "$cmd") # all functions

    local command i

    for (( i=0; i < ${#words[@]}-1; i++ )); do
        if [[ ${COMMANDS[@]} =~ ${words[i]} ]]; then
            command=${words[i]}
            break
        fi
    done

    if [ "$command" = "" ]; then
        COMPREPLY=( $( compgen -W '${COMMANDS[@]}' -- "$cur" ) )
    fi

    return 0
  } &&
  complete -o nospace -o dirnames -o filenames -o bashdefault -o default -D -F _script
  return
fi

IFS=" " read -a ps_output <<< "$(ps --no-headers $PPID)" # Get parent script
# if [[ ${ps_output[5]} == "" ]] || [[ $(basename ${ps_output[5]}) == $(basename $0) ]]; then
# # If 5th element is empty it means that parent is bash. If 5th el is this script, it means options has been selected and it runs itself 2nd time.
#   exit
# fi

scriptname="$(basename ${ps_output[5]})"
scriptpath="$(realpath ${ps_output[5]})"
scriptargs="${ps_output[@]:6}"
# echo ${ps_output[@]}
# echo $PWD
# echo $scriptpath
echo $(readlink /proc/${PPID}/fd/255)
exit

options=$(getFunctions "$scriptpath")

if [[ -z "$scriptargs" ]]; then
  select option in $options
  do
      cmd="$option"
      break
  done
else
  cmd="$scriptargs"
fi

if [[ -z "$cmd" ]]; then
  exit
fi

if [[ ! "$options" =~ ($'\n'|^)"$cmd"($'\n'|$) ]]; then
  echo There is no function named \"$cmd\" in ${scriptname}.
  exit
fi

BASH_ARGV0="$scriptpath"
source "$scriptpath"

echo "Running ${cmd}..."
$cmd
