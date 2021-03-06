export EDITOR=vim

if [[ $HOST == "MBIT138.local" || ! -z `echo $HOST|grep "\.pplsi\.com"` ]]; then
  COMPUTER="LegalShield"
else
  COMPUTER="$HOST"
fi

# Case-insensitive tab-completion
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Fix colors for OTHER_WRITABLE
export LS_COLORS="ow=37;42"

# Keep history between sessions
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=5000
setopt appendhistory
setopt sharehistory
setopt incappendhistory


### Aliases
if [[ $COMPUTER == "LegalShield" ]]; then
  alias ls='ls -aG'
else
  alias ls='ls -a --color=auto'
fi
alias cp='cp -i'
alias mv='mv -i'

# Background-setting aliases so I can quickly switch to black for streaming
if [[ $COMPUTER == "Archiater" ]]; then
  alias hsetroot_stream='hsetroot -solid black'
  alias hsetroot_normal='hsetroot -full backgrounds/1352085388.jayaxer_all_business_by_jayaxer.jpg'
fi

# Alias for shutting down Assassin's creed, because it refuses to do so gracefully
function ShutDownProtonGame() {
  kill -9 `ps aux|grep "steamapp"|grep -v "grep"|grep -o "ibb\s*[0-9]*"|grep -o "[0-9]*"`
  kill -9 `ps aux|grep "C:"|grep -v "grep"|grep -o "ibb\s*[0-9]*"|grep -o "[0-9]*"`
  kill -9 `ps aux|grep "wine"|grep -v "grep"|grep -o "ibb\s*[0-9]*"|grep -o "[0-9]*"`
  kill -9 `ps aux|grep "explorer"|grep -v "grep"|grep -o "ibb\s*[0-9]*"|grep -o "[0-9]*"`
  kill -9 `ps aux|grep "Empyrion"|grep -v "grep"|grep -o "ibb\s*[0-9]*"|grep -o "[0-9]*"`
}
alias proton_shutdown=ShutDownProtonGame


### Prompt setup
PROMPT="%F{red}%? %F{magenta}%~ %F{green}%#%f "
# Git info
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
RPROMPT=\$vcs_info_msg_0_
zstyle ':vcs_info:git:*' formats '%F{yellow}%b %F{green}%c%F{red}%u%F{cyan}%m%f'
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:*' unstagedstr 'x'

# Allow checking for untracked files
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked
+vi-git-untracked() {
  if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
     git status --porcelain | grep -m 1 '^??' &>/dev/null
  then
    hook_com[misc]='?'
  fi
}


### Key setup
# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[ShiftTab]="${terminfo[kcbt]}"

# setup key accordingly
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"      beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"       end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"    overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}" backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"    delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"        up-line-or-history
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"      down-line-or-history
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"      backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"     forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"    history-beginning-search-backward
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"  history-beginning-search-forward
[[ -n "${key[ShiftTab]}"  ]] && bindkey -- "${key[ShiftTab]}"  reverse-menu-complete

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start {
		echoti smkx
	}
	function zle_application_mode_stop {
		echoti rmkx
	}
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi


### Docker aliases
# Justin's docker shortcuts, wrapped to prevent overdefinition
if [[ -z $DOCKER_SHORTCUTS_DEFINED ]]; then
  DOCKER_SHORTCUTS_DEFINED="yes"

  alias dc='docker-compose'

  dcgetcid() {
    echo $(docker-compose ps -q "$1")
  }

  if [[ $COMPUTER == "LegalShield" ]]; then
    dce(){
      CMD="${@:2}"
      docker-compose exec $1 bash -c "stty cols $COLUMNS rows $LINES && bash -c \"$CMD\"";
    }

    # Opens a bash console on a container: `dcb adonis`
    dcb() {
      dce "$1" /bin/bash
    }
  else
    dce() {
      CMD="${@:2}"
      docker-compose exec $1 sh -c "stty cols $COLUMNS rows $LINES && sh -c \"$CMD\"";
    }

    # Opens a sh console on a container: `dcb backend`
    dcb() {
      dce "$1" /bin/sh
    }
  fi

  # Watch the logs for all the running containers: `dcl`
  # Watch the logs for a single container: `dcl adonis`
  # optional tail if you want more than 25 lines: `dcl adonis 100`
  dcl() {
    TAIL=${2:-25}
    docker-compose logs -f --tail="$TAIL" $1
  }

  # Attach your terminal to a container.
  # If you have binding.pry in your code and browse the site
  # then run `dca adonis` in a terminal to be able to type into Pry
  dca() {
    docker attach $(dcgetcid "$1")
  }
fi


### LegalShield-specific
if [[ $COMPUTER == "LegalShield" ]]; then
  alias be='bundle exec'
  alias rails='bundle exec rails'
  alias rspec='bundle exec rspec'
  alias rubocop='bundle exec rubocop'
  alias rake='bundle exec rake'

  # Pathing for various languages/tools
  export PATH="$HOME/.bin:$PATH"
  export PATH="$PATH:/usr/local/opt/postgresql@10/bin"
  eval "$(rbenv init - --no-rehash)"
  export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
  eval "$(nodenv init -)"

  export GIT_USERNAME="ibbathon"
  export GIT_PERSONAL_ACCESS_TOKEN=`cat ${HOME}/.ssh/github-pat`
  
  
  ## My shortcuts for working within PPLSI
  
  # Shortcuts for accessing databases
  psql_dev() {
    dce postgres psql -U admin adonis_development
  }
  psql_test() {
    dce postgres psql -U admin adonis_test
  }
  
  # Fix delete key on Windows keyboard for iTerm2
  bindkey    "^[[3~"          delete-char
  bindkey    "^[3;5~"         delete-char
fi
