#!/bin/zsh
#-----------------------------------------------------------------------#
# File:          .zshrc   ZSH resource file                             #
# Orig Author:   Seynthan "ST.x" Thanapalan <seynthan.tx@gmail.com>     #
#-----------------------------------------------------------------------#

# {{{ Autoload
autoload -U zutil
autoload -U compinit
autoload -U complist
autoload eit-command-line
zle -N edit-command-line
compinit
# }}}

# {{{ History
HISTFILE=~/.zsh_history
HISTSIZE=99999
SAVEHIST=99999
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
# }}}

# {{{ other opts
setopt NO_BG_NICE # don't nice background tasks
setopt nobeep
stty erase 
# }}}

# {{{ Completion
# :completion:<func>:<completer>:<command>:<argument>:<tag>
# Expansion options
zstyle ':completion:*' completer _complete _prefix
zstyle ':completion::prefix-1:*' completer _complete
zstyle ':completion:incremental:*' completer _complete _correct
zstyle ':completion:predict:*' completer _complete
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Expand partial paths
zstyle ':completion:*' expand 'yes'
zstyle ':completion:*' squeeze-slashes 'yes'

# Separate matches into groups
zstyle ':completion:*:matches' group 'yes'

# Describe each match group.
zstyle ':completion:*:descriptions' format "%B---- %d%b"

# Messages/warnings format
zstyle ':completion:*:messages' format '%B%U---- %d%u%b'
zstyle ':completion:*:warnings' format '%B%U---- no match for: %d%u%b'

# Describe options in full
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
# }}}

# {{{ Window Title
case $TERM in
    *xterm*|rxvt|rxvt-unicode|rxvt-256color|(dt|k|E)term)
    precmd () { print -Pn "\e]0;$TERM [%~]\a" }
#    preexec () { print -Pn "\e]0;$TERM - (%L) [%n@%M]%# [%~] ($1)\a" }
    preexec () { print -Pn "\e]0; $1 \a" }
  ;;
    screen)
      precmd () {
      print -Pn "\e]83;title \"$1\"\a"
      print -Pn "\e]0;$TERM - (%L) [%n@%M]%# [%~]\a"
    }
    preexec () {
      print -Pn "\e]83;title \"$1\"\a"
      print -Pn "\e]0;$TERM - (%L) [%n@%M]%# [%~] ($1)\a"
    }
  ;;
esac
# }}}

# {{{ Prompt Config
setprompt () {
    # load some modules
    autoload -U colors zsh/terminfo # Used in the colour alias below
    colors
    setopt prompt_subst

    #   username@Machine ~/dev/dir[master]$   # clean working directory
    #   username@Machine ~/dev/dir[master☠]$  # dirty working directory
    function parse_git_dirty {
    	[[ $(git status 2> /dev/null | tail -n1) != "nothing to commit (working directory clean)" ]] && echo "☠"
    }
    function parse_git_branch {
    	git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/[\1$(parse_git_dirty)]/"
    }

#    PROMPT='%{$fg_bold[grey]%}[%{$fg_bold[white]%}%~%{$reset_color%}%{$fg_bold[grey]%}]%{$reset_color%}%{$fg_bold[blue]%}$(parse_git_branch)%{$reset_color%}
#-%{$fg_bold[red]%}>%{$reset_color%} '
#    RPROMPT='%{$fg[yellow]%}%D{%H:%M}%{$reset_color%}'
    PROMPT='[%{$fg[cyan]%}%T%{$reset_color%}] %{$fg[green]%}%% %{$reset_color%}'
    RPROMPT='[%{$fg[red]%}%~%{$reset_color%}]'
}
setprompt
# }}}

# {{{ Key Bindings
bindkey '\e[A' history-beginning-search-backward
bindkey '\e[B' history-beginning-search-forward
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey "\e[3~" delete-char
bindkey '^i' expand-or-complete-prefix
bindkey "\e[8~" end-of-line
bindkey "\e[7~" beginning-of-line

#bindkey "\e[1~" beginning-of-line
#bindkey "\e[4~" end-of-line
#bindkey "\e[5~" beginning-of-history
#bindkey "\e[6~" end-of-history
#bindkey "\e[3~" delete-char
#bindkey "\e[2~" quoted-insert
#bindkey "\e[5C" forward-word
#bindkey "\e[5D" backward-word
#bindkey "\e\e[C" forward-word
#bindkey "\e\e[D" backward-word
#bindkey "^H" backward-delete-word
# for rxvt
#bindkey "\e[8~" end-of-line
#bindkey "\e[7~" beginning-of-line
# completion in the middle of a line
#bindkey '^i' expand-or-complete-prefix
# }}}

# {{{ Aliases
#alias startx='SHELL=/bin/sh startx'
alias ls='ls -ah --color'
alias ll='ls -ah --color | more; echo "\e[1;32m --[\e[1;34m Dirs:\e[1;36m `ls -al | egrep \"^drw\" | wc -l` \e[1;32m|\e[1;35m Files: \e[1;31m`ls -al | egrep -v \"^drw\" | grep -v total | wc -l` \e[1;32m]--"'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias shutdownhome='sudo shutdown -hP now'
alias reboothome='sudo reboot'
alias screenie='cd ~/bin/ && ./info.pl'
alias xpop='xprop | grep --color=none "WM_WINDOW_ROLE\|WM_CLASS" | xmessage -file - -center'
alias nvtemp='echo "$(nvidia-settings -q gpucoretemp | grep Attribute | sed "s/ //g")"'
#alias pacman='sudo pacman-color'
alias matlab='cd /home/seynthantx/matlabr2008a/bin/ && ./matlab'
alias log_out='killall screen && logout'
alias "cdcode"="cd ~cs1911/public_html/10s1/code/"
alias ".."="cd .."
alias "..."="cd ../.."
alias 'gfriends'='/home/stevec/gfriends'
alias quake="if [ -d /tmp/q3 ]; then /tmp/q3/quake3.x86.rk +set fs_game cpma;
else ~csesoc/games/q3; fi"
alias fortune=/usr/games/fortune
alias f='perl ~/friends.pl'
#alias cd=cl
alias dropbox="~/.dropbox-dist/dropboxd &"
alias rf="clear; motd; friends.pl | column -t"
alias omp="ompload -u"
alias ack="ack-grep"
alias home="ssh -p 7853 j@heresjohnny.dyndns.org"
alias zenity="zenity --title='zenity'"
# }}}

# {{{ Environment variables

PATH="/import/kamen/1/jwon145/bin:$PATH:~csesoc/games/:$DB/bin:/import/kamen/1/jwon145/bin/bin"

LC_ALL=C
LANG=en_AU.utf8

PERL5LIB="/import/kamen/1/jwon145/bin/cpan"
MUDFLAP_OPTIONS=-viol-abort

GREP_OPTIONS='--color=auto'

LESS_TERMCAP_mb=$(printf "\e[1;37m")
LESS_TERMCAP_md=$(printf "\e[1;37m")
LESS_TERMCAP_me=$(printf "\e[0m")
LESS_TERMCAP_se=$(printf "\e[0m")
LESS_TERMCAP_so=$(printf "\e[1;47;30m")
LESS_TERMCAP_ue=$(printf "\e[0m")
LESS_TERMCAP_us=$(printf "\e[0;36m")

DB=~/Dropbox
DWM=/import/kamen/1/jwon145/dwm-5.7.2/
LAB=~/cs1921/lab
USB=/mnt/usb/1
PKG_CONFIG_PATH=/import/kamen/1/jwon145/bin/lib/pkgconfig

umask 077
# }}}

# {{{  URXVT workaround  - stop first line completion bug in tiling WMs
if test "$TERM" = "rxvt-256color"; then
    sleep 0.1 && clear
fi
# }}}

# {{{ Functions

mkcd() {
    mkdir -p "$@"
    cd "$@"
}

cd() {
    builtin cd $@; ls
}

# reload zshrc
function src() {
    autoload -U zrecompile
    [[ -f ~/.zshrc ]] && zrecompile -p ~/.zshrc
    [[ -f ~/.zcompdump ]] && zrecompile -p ~/.zcompdump
    [[ -f ~/.zcompdump ]] && zrecompile -p ~/.zcompdump
    [[ -f ~/.zshrc.zwc.old ]] && rm -f ~/.zshrc.zwc.old
    [[ -f ~/.zcompdump.zwc.old ]] && rm -f ~/.zcompdump.zwc.old
    source ~/.zshrc
}

# Completion for pacman-color
#function pacman; pacman-color $argv;

# The number given after pacstatus determines how many lines of history you would like shown
pacstats() {
	pacman -V | grep Pacman | cut -d " " -f 20-
	echo
	#echo "Last cmd - " `cat ~/.zsh_history | grep "pacman " | tail -n1`
	echo "Last Sy - " `cat /var/log/pacman.log | grep sync | tail -n1 | cut -d "[" -f 2 | cut -d "]" -f -1`
	echo "Last Su - " `cat /var/log/pacman.log | grep "full system" | tail -n1 | cut -d "[" -f 2 | cut -d "]" -f -1`
	echo
	echo "Last "$1" Installed"
	cat /var/log/pacman.log | grep installed | tail -n $1 | cut -d " " -f 4,5
	echo
	echo "Last "$1" Removed"
	cat /var/log/pacman.log | grep removed | tail -n $1 | cut -d " " -f 4,5
}

# Show Console Colours
function show_console_colours()
{
    for NUMB in `seq 200 `
    do
        echo -en "\033[${NUMB}m ${NUMB} \e[0m "
    done
    echo ""
}

extract () {
    local old_dirs current_dirs lower
    lower=${(L)1}
    old_dirs=( *(N/) )
    if [[ $lower == *.tar.gz || $lower == *.tgz ]]; then
        tar xvzf $1
    elif [[ $lower == *.gz ]]; then
        gunzip $1
    elif [[ $lower == *.tar.bz2 || $lower == *.tbz ]]; then
        tar xvjf $1
    elif [[ $lower == *.bz2 ]]; then
        bunzip2 $1
    elif [[ $lower == *.zip ]]; then
        unzip $1
    elif [[ $lower == *.rar ]]; then
        unrar e $1
    elif [[ $lower == *.tar ]]; then
        tar xvf $1
    elif [[ $lower == *.lha ]]; then
        lha e $1
    else
        print "Unknown archive type: $1"
        return 1
    fi
    # Change in to the newly created directory, and
    # list the directory contents, if there is one.
    current_dirs=( *(N/) )
    for i in {1..${#current_dirs}}; do
        if [[ $current_dirs[$i] != $old_dirs[$i] ]]; then
            cd $current_dirs[$i]
            break
        fi
    done
}

roll () {
    FILE=$1
    case $FILE in
        *.tar.bz2) shift && tar cjf $FILE $* ;;
        *.tar.gz) shift && tar czf $FILE $* ;;
        *.tgz) shift && tar czf $FILE $* ;;
        *.zip) shift && zip $FILE $* ;;
        *.rar) shift && rar $FILE $* ;;
    esac
}

# user chownage
function mkmine() { sudo chown -R ${USER} ${1:-.}; }

# sanitize - set file/directory owner and permissions to normal values (644/755)
# Usage: sanitize <file>
sanitize() {
    chmod -R u=rwX,go=rX "$@"
    chown -R ${USER}.users "$@"
}
# }}}

# MOTD  {{{
#~/motd
# cat ~/cowsay-3.03/cows/default.cow
$DB/bin/motd
#$HOME/bin/friends.pl | column -t
#$DB/bin/q3
# }}}
