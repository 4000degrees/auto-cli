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

    # If its not an .sh file or doesn't contain "auto-options" command, restore completion.
    if [[ $ext != "sh" ]] || [[ -z $(grep "auto-options" "$cmd") ]]; then
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

scriptpath="$(readlink /proc/${PPID}/fd/255)"

if [[ "$scriptpath" == "" ]] || [[ $scriptpath == "/dev/pts"* ]]; then
  echo "This script shouldn't be run directly."
  exit # If scriptpath is tty or empty, it means it's run directly.
fi

if [[ $(cat /proc/$PPID/comm) == "auto-options" ]]; then
  exit # If running itself, it means its the second run after including parent script.
fi

scriptname="$(basename ${scriptpath})"

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

BASH_ARGV0="$scriptpath" # Change $0 to caller script to avoid confusion.
source "$scriptpath"

echo "Running ${cmd}..."
$cmd
