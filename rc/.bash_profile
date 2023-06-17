

# PS1
# this one has black background
TC_GRE="\[\033[0;32;40m\]"
TC_RESET="\[\033[0;0m\]" 

# Just right... 
TC_GRE="\[\033[0;36m\]"
TC_RESET="\[\033[0;0m\]" 
export PS1="${TC_GRE}ツ ${TC_RESET}" 

# macvim 
export PATH=/Applications/MacVim.app/Contents/bin:$PATH

# export PATH="$HOME/miniconda/bin:$PATH"
# export PATH="$HOME/bin/rar:$PATH"
# export PATH="$HOME/bin:$PATH"

# use vi in bash
set -o vi

# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-HISTCONTROL
export HISTCONTROL=ignorespace

# let "less" be case insensitive by default ! 
LESS=-Ri
