#
# els-setup.sh
#
# Shell script under /etc/profile.d which sets various per session
# environment items to Easy Linux Server standards.
#
# Author: Holger Schurig <holgerschurig@gmx.de>
#
# Modified: by Jonathan Marsden <jonathan@xc.org>
#

# internationalisation
export LC_TYPE=ISO-8859-1
unset LC_ALL

# several handy paths
export TEMP=/var/tmp
export TMP=/var/tmp
export TMPDIR=/var/tmp

# for updatedb
export PRUNEPATHS="/tmp /var/tmp /usr/tmp /mnt"

# more for BASH
export INPUTRC=/etc/inputrc
export IGNOREEOF=0
export HISTCONTROL=ignoreboth
export FIGNORE=.a:.o

# more for LESS
export PAGER=less
export LESS="-MSisch4"
export LESSCHARSET=latin1

# nicer prompt
export PROMPT_COMMAND='PS1=`if test "$UID" = 0 ; then \
	echo "\h:\w# " ; \
    else \
	echo "\h:\w$ " ; \
    fi `'

# nicer ls
export LS_COLORS="no=00:fi=00:di=01;34:ex=01;31"

# make it more like dos
alias copy="cp -i"
alias del="rm -i"
alias dir="ls"
alias md="mkdir"
alias move="mv -i"
alias rd="rmdir"
alias ren="mv -i"
# several handy shortcuts
alias l="ls -lF --color=tty"
alias ll="ls -lAF --color=tty"
alias ls="ls -AF --color=tty"
alias psg="ps auxww | grep"
alias gdb="gdb --quiet"
# directory changing for the lazy ones
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -="cd -"
# get rid of core dumps
ulimit -c 0
test -z "$BASH_VERSINFO" && alias -="cd -"


# a startup-wrapper for "mc" that allows us to change directories inside
# mc and inherit the new directory into the actual shell
function mc () {
    MC=`/usr/bin/mc -P "$@"`
    test -n "$MC" && cd "$MC"
    unset MC
}

#
# Enhanced cd, like "acd" or "ncd" in DOS. It reads a list of
# "hot" directories either from /etc/diralias or from ~/.diralias.
# This function replaces the builtin "cd" command.
#
# The contents of the configuration files should have the following form:
#
#       local SHORT-NAME=FULL-DIRECTORY-PATH
#
# Here's an example:
#
#       local specs=/usr/src/redhat/SPECS
#       local rpms=/usr/src/redhat/RPMS/i386
#
# Now a simple "cd specs" will put you into the /usr/src/redhat/SPECS
# directory.
#
# This code is based on an idea of Wolf Paul (he also did the first
# implementation, but I've deleted his source by accident, so I had
# to rewrite it ...).
#
function cd ()
{
    # shortcut if the directory exists because then the lengthy load of
    # hot directories isn't necessary anyway
    [ -z "$1" ] && builtin cd >/dev/null 2>/dev/null && return
    builtin cd "$1" >/dev/null 2>/dev/null && return
    local file

    # read in the directories in as variables:
    for file in /etc/diralias.d/* ; do
 	. $file
    done
    test -s ~/.diralias && . ~/.diralias

    # nice CSH feature that is also present in bash: if now "cd spec" won't
    # work, CD will do the equivalent of "cd $spec". We switch this feature
    # on, try to change the directory and switch that feature back off.
    cdable_vars=true
    builtin cd "$1" >/dev/null
    unset cdable_vars
}
