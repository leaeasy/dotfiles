#!/bin/zsh
# vim:fdm=marker

# 预配置 {{{
# 如果不是交互shell就直接结束 (unix power tool, 2.11)
#if [[  "$-" != *i* ]]; then return 0; fi

# 为兼容旧版本定义 is-at-least 函数
function is-at-least {
    local IFS=".-" min_cnt=0 ver_cnt=0 part min_ver version

    min_ver=(${=1})
    version=(${=2:-$ZSH_VERSION} 0)

    while (( $min_cnt <= ${#min_ver} )); do
      while [[ "$part" != <-> ]]; do
        (( ++ver_cnt > ${#version} )) && return 0
        part=${version[ver_cnt]##*[^0-9]}
      done

      while true; do
        (( ++min_cnt > ${#min_ver} )) && return 0
        [[ ${min_ver[min_cnt]} = <-> ]] && break
      done

      (( part > min_ver[min_cnt] )) && return 0
      (( part < min_ver[min_cnt] )) && return 1
      part=''
    done
}

SHELL=`which zsh`

#}}}

# 定义颜色 {{{
if [[ ("$TERM" = *256color || "$TERM" = screen* || "$TERM" = xterm* ) && -f $HOME/.lscolor256 ]]; then
    #use prefefined colors
    eval $(dircolors -b $HOME/.lscolor256)
    use_256color=1
    export TERMCAP=${TERMCAP/Co\#8/Co\#256}
else
    eval $(dircolors)
fi

#color defined for prompts and etc
autoload colors
[[ $terminfo[colors] -ge 8 ]] && colors
pR="%{$reset_color%}%u%b" pB="%B" pU="%U"
for i in red green blue yellow magenta cyan white black; {eval pfg_$i="%{$fg[$i]%}" pbg_$i="%{$bg[$i]%}"}
#}}}

# 设置参数 {{{
setopt complete_aliases         #do not expand aliases _before_ completion has finished
setopt auto_cd                  # if not a command, try to cd to it.
setopt auto_pushd               # automatically pushd directories on dirstack
setopt auto_continue            #automatically send SIGCON to disowned jobs
setopt extended_glob            # so that patterns like ^() *~() ()# can be used
setopt pushd_ignore_dups        # do not push dups on stack
setopt pushd_silent             # be quiet about pushds and popds
setopt brace_ccl                # expand alphabetic brace expressions
#setopt chase_links             # ~/ln -> /; cd ln; pwd -> /
setopt complete_in_word         # stays where it is and completion is done from both ends
setopt correct                  # spell check for commands only
#setopt equals extended_glob    # use extra globbing operators
setopt no_hist_beep             # don not beep on history expansion errors
setopt hash_list_all            # search all paths before command completion
setopt hist_ignore_all_dups     # when runing a command several times, only store one
setopt hist_reduce_blanks       # reduce whitespace in history
setopt hist_ignore_space        # do not remember commands starting with space
setopt share_history            # share history among sessions
setopt hist_verify              # reload full command when runing from history
setopt hist_expire_dups_first   #remove dups when max size reached
setopt interactive_comments     # comments in history
setopt list_types               # show ls -F style marks in file completion
setopt long_list_jobs           # show pid in bg job list
setopt numeric_glob_sort        # when globbing numbered files, use real counting
setopt inc_append_history       # append to history once executed
setopt prompt_subst             # prompt more dynamic, allow function in prompt
setopt nonomatch 

#remove / and . from WORDCHARS to allow alt-backspace to delete word
WORDCHARS='*?_-[]~=&;!#$%^(){}<>'

# report about cpu-/system-/user-time of command if running longer than 5 seconds
REPORTTIME=5

#report to me when people login/logout
watch=(notme)
#replace the default beep with a message
#ZBEEP="\e[?5h\e[?5l"        # visual beep

#is-at-least 4.3.0 && 

# 自动加载自定义函数
fpath=($HOME/.zfunctions $fpath)
# 需要设置了extended_glob才能glob到所有的函数，为了补全能用，又需要放在compinit前面
autoload -U ${fpath[1]}/*(:t)       
# }}}

# 命令补全参数{{{
#   zsytle ':completion:*:completer:context or command:argument:tag'
zmodload -i zsh/complist        # for menu-list completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" "ma=${${use_256color+1;7;38;5;143}:-1;7;33}"
#ignore list in completion
zstyle ':completion:*' ignore-parents parent pwd directory
#menu selection in completion
zstyle ':completion:*' menu select=2
#zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*' completer _oldlist _expand _force_rehash _complete _match #_user_expand
zstyle ':completion:*:match:*' original only 
#zstyle ':completion:*' user-expand _pinyin
zstyle ':completion:*:approximate:*' max-errors 1 numeric 
## case-insensitive (uppercase from lowercase) completion
zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}'
### case-insensitive (all) completion
#zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:*:*:processes' force-list always
zstyle ':completion:*:processes' command 'ps -au$USER' 
zstyle ':completion:*:*:kill:*:processes' list-colors "=(#b) #([0-9]#)*=36=1;31"
#use cache to speed up pacman completion
zstyle ':completion::complete:*' use-cache on
#zstyle ':completion::complete:*' cache-path .zcache 
#group matches and descriptions
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:descriptions' format $'\e[33m == \e[1;7;36m %d \e[m\e[33m ==\e[m' 
zstyle ':completion:*:messages' format $'\e[33m == \e[1;7;36m %d \e[m\e[0;33m ==\e[m'
zstyle ':completion:*:warnings' format $'\e[33m == \e[1;7;31m No Matches Found \e[m\e[0;33m ==\e[m' 
zstyle ':completion:*:corrections' format $'\e[33m == \e[1;7;37m %d (errors: %e) \e[m\e[0;33m ==\e[m'
# dabbrev for zsh!! M-/ M-,
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes select

#autoload -U compinit
autoload -Uz compinit
compinit

#force rehash when command not found
#  http://zshwiki.org/home/examples/compsys/general
_force_rehash() {
    (( CURRENT == 1 )) && rehash
    return 1    # Because we did not really complete anything
}

# }}}

# 自定义函数 {{{

# 普通自定义函数 {{{
#show 256 color tab
256tab() {
    for k in `seq 0 1`;do 
        for j in `seq $((16+k*18)) 36 $((196+k*18))`;do 
            for i in `seq $j $((j+17))`; do 
                printf "\e[01;$1;38;5;%sm%4s" $i $i;
            done;echo;
        done;
    done
}

#check if a binary exists in path
bin-exist() {[[ -n ${commands[$1]} ]]}

#ssh wrapper that rename current tmux window to the hostname of the remote host
ssh_on_exit(){
	printf "\033kbash\033\\"
	trap - SIGINT SIGTERM
}

ssh() {
	# Do nothing if we are not inside tmux or ssh is called without arguments
	if [[ $# == 0 || -z $TMUX ]]; then
		command ssh $@
		return
	fi
	trap ssh_on_exit SIGINT SIGTERM
	# The hostname is the last parameter (i.e. ${(P)#})
	local remote=${${(P)#}%.*}
	local old_name="`whoami`@$(tmux display-message -p '#T')"
	local renamed=0
	# Save the current name
	if [[ $remote != -* ]]; then
		renamed=1
		tmux rename-window $remote
	fi
	command ssh $@
	if [[ $renamed == 1 ]]; then
		tmux rename-window "$old_name"
	fi
}

# }}}

#{{{ functions to set prompt pwd color
__PROMPT_PWD="$pfg_magenta%~$pR"
#change PWD color
pwd_color_chpwd() { [ $PWD = $OLDPWD ] || __PROMPT_PWD="$pU$pfg_cyan%~$pR" }
#change back before next command
pwd_color_preexec() { __PROMPT_PWD="$pfg_magenta%~$pR" }

#}}}

#{{{functions to display git branch in prompt

get_git_status() {
    unset __CURRENT_GIT_BRANCH
    unset __CURRENT_GIT_BRANCH_STATUS
    unset __CURRENT_GIT_BRANCH_IS_DIRTY

    # do not track git branch info in ~
    [[ "$PWD" = "$HOME" ]]  &&  return
    local dir=$(git rev-parse --git-dir 2>/dev/null)
    [[ "${dir:h}" = "$HOME" ]] && return

    local st="$(git status 2>/dev/null)"
    if [[ -n "$st" ]]; then
        local -a arr
        arr=(${(f)st})

        if [[ $arr[1] =~ 'Not currently on any branch.' ]]; then
            __CURRENT_GIT_BRANCH='no-branch'
        else
            __CURRENT_GIT_BRANCH="${arr[1][(w)4]}";
        fi

        if [[ $arr[2] =~ 'Your branch is' ]]; then
            if [[ $arr[2] =~ 'ahead' ]]; then
                __CURRENT_GIT_BRANCH_STATUS='ahead'
            elif [[ $arr[2] =~ 'diverged' ]]; then
                __CURRENT_GIT_BRANCH_STATUS='diverged'
            else
                __CURRENT_GIT_BRANCH_STATUS='behind'
            fi
        fi

        [[ ! $st =~ "nothing to commit" ]] && __CURRENT_GIT_BRANCH_IS_DIRTY='1'
    fi
}

git_branch_precmd() { [[ "$(fc -l -1)" == *git* ]] && get_git_status }

git_branch_chpwd() { get_git_status }

#this one is to be used in prompt
get_prompt_git() { 
    if [[ -n $__CURRENT_GIT_BRANCH ]]; then
        local s=$__CURRENT_GIT_BRANCH
        case "$__CURRENT_GIT_BRANCH_STATUS" in
            ahead) s+="+" ;;
            diverged) s+="=" ;;
            behind) s+="-" ;;
        esac
        [[ $__CURRENT_GIT_BRANCH_IS_DIRTY = '1' ]] && s+="*"
        echo " $pfg_black$pbg_white$pB $s $pR" 
    fi
}
#}}}

#{{{define magic function arrays
if ! (is-at-least 4.3); then
    #the following solution should work on older version <4.3 of zsh. 
    #The "function" keyword is essential for it to work with the old zsh.
    #NOTE these function fails dynamic screen title, not sure why
    #CentOS stinks.
    function precmd() {
        screen_precmd 
        git_branch_precmd
    }

    function preexec() {
        screen_preexec
        pwd_color_preexec
    }

    function chpwd() {
        pwd_color_chpwd
        git_branch_chpwd
    }
else
    #this works with zsh 4.3.*, will remove the above ones when possible
    typeset -ga preexec_functions precmd_functions chpwd_functions
    precmd_functions+=screen_precmd
    precmd_functions+=git_branch_precmd
    preexec_functions+=screen_preexec
    preexec_functions+=pwd_color_preexec
    chpwd_functions+=pwd_color_chpwd
    chpwd_functions+=git_branch_chpwd
fi

#}}}

# }}}

# 提示符 {{{
if [ "$SSH_TTY" = "" ]; then
    local host="$pB$pfg_magenta%m$pR"
else
    local host="$pB$pfg_red%m$pR"
fi
local result="%(?:$pfg_green✓:$pfg_red✗)"
local user="$pB%(!:$pfg_red:$pfg_green)%n$pR"       #different color for privileged sessions
local symbol="$pB%(!:$pfg_red# :$pfg_yellow)$pR"
local arrow=" $pfg_yellow➭ "
local job="%1(j,$pfg_red:$pfg_blue%j,)$pR"
PROMPT='$result $user$pfg_yellow@$pR$host$(get_prompt_git)$job$symbol$arrow'
PROMPT2="$PROMPT$pfg_cyan%_$pR $pB$pfg_black>$pR$pfg_green>$pB$pfg_green>$pR "
#NOTE  **DO NOT** use double quote , it does not work
typeset -A altchar
set -A altchar ${(s..)terminfo[acsc]}
PR_SET_CHARSET="%{$terminfo[enacs]%}"
PR_SHIFT_IN="%{$terminfo[smacs]%}"
PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
#PR_RSEP=$PR_SET_CHARSET$PR_SHIFT_IN${altchar[\`]:-|}$PR_SHIFT_OUT
local prompt_time="%(?:$pfg_green:$pfg_red)%*$pR"
RPROMPT='$__PROMPT_PWD $prompt_time'

# SPROMPT - the spelling prompt
SPROMPT="${pfg_yellow}zsh$pR: correct '$pfg_red$pB%R$pR' to '$pfg_green$pB%r$pR' ? ([${pfg_cyan}Y$pR]es/[${pfg_cyan}N$pR]o/[${pfg_cyan}E$pR]dit/[${pfg_cyan}A$pR]bort) "

#行编辑高亮模式 {{{
if (is-at-least 4.3); then
    zle_highlight=(region:bg=magenta
                   special:bold,fg=magenta
                   default:bold
                   isearch:underline
                   )
fi
#}}}

# }}}

# 键盘定义及键绑定 {{{
#bindkey "\M-v" "\`xclip -o\`\M-\C-e\""
# 设置键盘 {{{
# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
autoload -U zkbd
bindkey -e      #use emacs style keybindings :(
typeset -A key  #define an array

#if zkbd definition exists, use defined keys instead
if [[ -f ~/.zkbd/${TERM}-${DISPLAY:-$VENDOR-$OSTYPE} ]]; then
    source ~/.zkbd/$TERM-${DISPLAY:-$VENDOR-$OSTYPE}
else
    key[Home]=${terminfo[khome]}
    key[End]=${terminfo[kend]}
    key[Insert]=${terminfo[kich1]}
    key[Delete]=${terminfo[kdch1]}
    key[Up]=${terminfo[kcuu1]}
    key[Down]=${terminfo[kcud1]}
    key[Left]=${terminfo[kcub1]}
    key[Right]=${terminfo[kcuf1]}
    key[PageUp]=${terminfo[kpp]}
    key[PageDown]=${terminfo[knp]}
    for k in ${(k)key} ; do
        # $terminfo[] entries are weird in ncurses application mode...
        [[ ${key[$k]} == $'\eO'* ]] && key[$k]=${key[$k]/O/[}
    done
fi

# setup key accordingly
[[ -n "${key[Home]}"    ]]  && bindkey  "${key[Home]}"    beginning-of-line
[[ -n "${key[End]}"     ]]  && bindkey  "${key[End]}"     end-of-line
[[ -n "${key[Insert]}"  ]]  && bindkey  "${key[Insert]}"  overwrite-mode
[[ -n "${key[Delete]}"  ]]  && bindkey  "${key[Delete]}"  delete-char
[[ -n "${key[Up]}"      ]]  && bindkey  "${key[Up]}"      up-line-or-history
[[ -n "${key[Down]}"    ]]  && bindkey  "${key[Down]}"    down-line-or-history
[[ -n "${key[Left]}"    ]]  && bindkey  "${key[Left]}"    backward-char
[[ -n "${key[Right]}"   ]]  && bindkey  "${key[Right]}"   forward-char

# }}}

# 键绑定  {{{ 
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "" history-beginning-search-backward-end
bindkey "" history-beginning-search-forward-end
bindkey -M viins "" history-beginning-search-backward-end
bindkey -M viins "" history-beginning-search-forward-end
bindkey '[1;5D' backward-word     # C-left
bindkey '[1;5C' forward-word      # C-right

autoload -U edit-command-line
zle -N      edit-command-line
bindkey '\ee' edit-command-line
# }}}

# }}}

# ZLE 自定义widget {{{
#

# {{{ pressing TAB in an empty command makes a cd command with completion list 
# from linuxtoy.org 
dumb-cd(){
    if [[ -n $BUFFER ]] ; then # 如果该行有内容
        zle expand-or-complete # 执行 TAB 原来的功能
    else # 如果没有
        BUFFER="cd " # 填入 cd（空格）
        zle end-of-line # 这时光标在行首，移动到行末
        zle expand-or-complete # 执行 TAB 原来的功能
    fi 
}
zle -N dumb-cd
bindkey "\t" dumb-cd #将上面的功能绑定到 TAB 键
# }}}

# {{{ colorize commands
TOKENS_FOLLOWED_BY_COMMANDS=('|' '||' ';' '&' '&&' 'sudo' 'do' 'time' 'strace')

recolor-cmd() {
    region_highlight=()
    colorize=true
    start_pos=0
    for arg in ${(z)BUFFER}; do
        ((start_pos+=${#BUFFER[$start_pos+1,-1]}-${#${BUFFER[$start_pos+1,-1]## #}}))
        ((end_pos=$start_pos+${#arg}))
        if $colorize; then
            colorize=false
            res=$(LC_ALL=C builtin type $arg 2>/dev/null)
            case $res in
                *'reserved word'*)   style="fg=magenta,bold";;
                *'alias for'*)       style="fg=cyan,bold";;
                *'shell builtin'*)   style="fg=yellow,bold";;
                *'shell function'*)  style='fg=green,bold';;
                *"$arg is"*)         
                    [[ $arg = 'sudo' ]] && style="fg=red,bold" || style="fg=blue,bold";;
                *)                   style='none,bold';;
            esac
            region_highlight+=("$start_pos $end_pos $style")
        fi
        [[ ${${TOKENS_FOLLOWED_BY_COMMANDS[(r)${arg//|/\|}]}:+yes} = 'yes' ]] && colorize=true
        start_pos=$end_pos
    done
}

check-cmd-self-insert() { zle .self-insert && recolor-cmd }
check-cmd-backward-delete-char() { zle .backward-delete-char && recolor-cmd }

zle -N self-insert check-cmd-self-insert
zle -N backward-delete-char check-cmd-backward-delete-char
# }}}

# 拼音补全
function _pinyin() { reply=($($HOME/bin/chsdir 0 $*)) }

# {{{ double ESC to prepend "sudo"
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    [[ $BUFFER != sudo\ * ]] && BUFFER="sudo $BUFFER"
    zle end-of-line                 #光标移动到行末
}
zle -N sudo-command-line
#定义快捷键为： [Esc] [Esc]
bindkey "\e\e" sudo-command-line
# }}}

# {{{ c-z to continue
bindkey -s "" "fg\n"
# }}}

# }}}

# 环境变量及其他参数 {{{
# number of lines kept in history
export HISTSIZE=10000
# number of lines saved in the history after logout
export SAVEHIST=10000
# location of history
export HISTFILE=$HOME/.zsh_history

export PATH=$PATH:$HOME/.bin
export EDITOR=vim
export VISUAL=vim
export SUDO_PROMPT=$'[\e[31;5msudo\e[m] password for \e[33;1m%p\e[m: '

#MOST like colored man pages
export PAGER=less
export LESS_TERMCAP_md=$'\E[1;31m'      #bold1
export LESS_TERMCAP_mb=$'\E[1;31m'
export LESS_TERMCAP_me=$'\E[m'
export LESS_TERMCAP_so=$'\E[01;7;34m'  #search highlight
export LESS_TERMCAP_se=$'\E[m'
export LESS_TERMCAP_us=$'\E[1;2;32m'    #bold2
export LESS_TERMCAP_ue=$'\E[m'
export LESS="-M -i -R --shift 5"
export LESSCHARSET=utf-8
export READNULLCMD=less

# Fcitx input method
export XIM="fcitx"
export XIM_PROGRAM="fcitx"
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
# }}}

# 读入其他配置 {{{ 

# 主机特定的配置，前置的主要原因是有可能需要提前设置PATH等环境变量
#   例如在aix主机，需要把 /usr/linux/bin
#   置于PATH最前以便下面的配置所调用的命令是linux的版本
[[ -f $HOME/.zshrc.$HOST ]] && source $HOME/.zshrc.$HOST
[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local
# }}}

# 命令别名 {{{

# tmux or screen ?
(bin-exist tmux) && alias s=tmux || alias s=screen

#no correct for mkdir mv and cp
for i in  mv cp;       alias $i="nocorrect $i -g"
alias mkdir='nocorrect mkdir'

alias find='noglob find'        # noglob for find
alias grep='grep -I --color=auto'
alias egrep='egrep -I --color=auto'
alias cal='cal -3'
alias freeze='kill -STOP'
alias ls=$'ls -h --color=auto -X --time-style="+\e[33m[\e[32m%Y-%m-%d \e[35m%k:%M\e[33m]\e[m"'
alias vi='vim'
alias ll='ls -l'
alias df='df -Th'
alias du='du -h'
alias info='info --vi-keys'
alias rsync='rsync --progress --partial'
alias history='history 1'       #zsh specific
alias qml='qmlviewer'

#}}}

# 执行fbterm {{{
if [[ ("$TERM" = linux) ]];then
	(bin-exist fcitx-fbterm-helper) && fcitx-fbterm-helper -l
fi
# }}}
typeset -U PATH
