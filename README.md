# Bash Auto CLI

## Automatically create command line interface from functions in a bash script.

### Features

- Enables tab autocomplete for functions in a bash script

- Executes function passed as an argument to a bash script

- Displays a select with function names if run without arguments

### Example

Imagine you have a set of bash scripts for a project you are developing.

Let's put them in one file 'commands.sh' and add `auto-cli` to the script.

```bash
#!/bin/bash
auto-cli

function dev {
  tmux \
  new-session 'trap bash EXIT; cd mock-api; npm run mock-api' \; \
  split-window -h 'trap bash EXIT; cd app && npm run serve' \; \
  set status off \;
}

function deploy {
    rsync -ah --info=progress2 --delete \
    app/dist user@server:/srv/app    
}
```

Now you can functions from the script by running `commands.sh dev` or `commands.sh deploy` or any other.

Also if you type `./commands.sh` and press TAB, you will get autocompletion for all functions in the script. Or if you run your script without any arguments, auto-cli will display a select with your functions.

## Installation

1. Download auto-cli.sh and put it in any location

2. ln -s /path/to/auto-cli.sh ~/.local/bin/auto-cli

3. echo source auto-cli setup-autocomplete >> ~/.bashrc

## Usage

Add `auto-cli` at any location in your script.
Shebang must be present in the script, otherwise calling functions via arguments won't work.
Private functions can be declared by adding a comment with the word 'private'. E.g.: `function name { # private`.

Also supports function arguments: `./commands.sh function argument argument2`.

'argument' and 'argument2' will be available in the function as \$1 and \$2.
