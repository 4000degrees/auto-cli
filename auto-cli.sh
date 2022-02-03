#!/bin/bash

# Automatically create command line interface from functions in a bash script.
# - Enables tab autocomplete for functions in a bash script
# - Executes function passed as an argument to a bash script
# - Displays a select with function names if run without arguments
# Installation
# 1. Download auto-cli.sh and put it in any location
# 2. ln -s /path/to/auto-cli.sh ~/.local/bin/auto-cli
# 3. echo source auto-cli setup-autocomplete >> ~/.bashrc
# Usage
# Add `auto-cli` at any location in your script.
# Shebang must be present in the script, otherwise calling functions via arguments won't work.
# Private functions can be declared by adding a comment with the word 'private'. E.g.: `function name { # private`.
# github.com/4000degrees/auto-cli

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

    # If its not an .sh file or doesn't contain "auto-cli" command, restore completion.
    if [[ $ext != "sh" ]] || [[ -z $(grep "auto-cli" "$cmd") ]]; then
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

# If running itself, it means its the second run after re-runnig the parent script.
if [[ $(cat /proc/$PPID/comm) == "auto-cli" ]]; then
  exit
fi

if [[ -f /proc/${PPID}/fd/254 ]]; then
  # If there's no shebang, caller is bash, and 255 desciptor points to tty and 254 to script.
  fd=/proc/${PPID}/fd/254
else
  # If there is shebang, caller is parent script and 255 points to it.
  fd=/proc/${PPID}/fd/255
fi

scriptpath="$(readlink $fd)"

# If scriptpath is tty or empty, it means it's run directly.
if [[ "$scriptpath" == "" ]] || [[ $scriptpath == "/dev/pts"* ]]; then
  echo "This script shouldn't be run directly."
  exit
fi

scriptname="$(basename ${scriptpath})"

# If there's no shebang, /proc/$PPID/cmdline contains only /bin/bash. Script arguments aren't available.
readarray -d '' cmdarray < <(cat /proc/$PPID/cmdline)
cmd=${cmdarray[2]}

options=$(getFunctions "$scriptpath")

if [[ -z "$cmd" ]]; then
  select option in $options
  do
      cmd="$option"
      break
  done
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
"${cmdarray[@]:2}"
