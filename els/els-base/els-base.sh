# we don't want temp files in the /tmp (that is usually in the root
# partition):
test -d "$HOME/tmp" && export TEMP="$HOME/tmp" || export TEMP=/var/tmp
export TMP="$TEMP"
export TMPDIR="$TEMP"

# vars for BASH and LESS
export IGNOREEOF=0
export HISTCONTROL=ignoreboth
export FIGNORE=.a:.o
export LESS="-MSisch4"
