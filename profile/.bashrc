# ls aliases
alias ll='ls -laF'
alias la='ls -A'
alias l='ls -CF'

# colored prompt (for non-root user)
PS1='\[$(tput bold)\][\[$(tput setaf 2)\]\u\[$(tput setaf 7)\]@\[$(tput setaf 3)\]\H\[$(tput setaf 7)\]]:[\[$(tput setaf 4)\]\w\[$(tput setaf 7)\]]\$ \[$(tput sgr0)\]'

# colored prompt (for root user)
PS1='\[$(tput bold)\][\[$(tput setaf 1)\]\u\[$(tput setaf 7)\]@\[$(tput setaf 3)\]\H\[$(tput setaf 7)\]]:[\[$(tput setaf 4)\]\w\[$(tput setaf 7)\]]\$ \[$(tput sgr0)\]'

# colored prompt with git branch (if git repo)
PS1='\[$(tput bold)\][\[$(tput setaf 2)\]\u\[$(tput setaf 7)\]@\[$(tput setaf 3)\]\H\[$(tput setaf 7)\]]:[\[$(tput setaf 4)\]\w\[$(tput setaf 7)\]]$(__git_ps1 "[\[$(tput setaf 1)\]%s\[$(tput setaf 7)\]]")\$ \[$(tput sgr0)\]'

