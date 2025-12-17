# Ansible and Git aliases for development environment

# Reload shell configuration
alias z='source ~/.zshrc'
alias b='source ~/.bashrc'

# Ansible aliases
alias a='ansible'
alias ap='ansible-playbook'
alias ag='ansible-galaxy'
alias agi='ansible-galaxy install'
alias agir='ansible-galaxy install -r requirements.yml'
alias agr='ansible-galaxy remove'
alias agl='ansible-galaxy list'
alias ags='ansible-galaxy search'
alias agc='ansible-galaxy collection'
alias agcu='ansible-galaxy collection install'
alias agcl='ansible-galaxy collection list'

# Git-crypt aliases
alias gcl='git-crypt lock'
alias gcu='git-crypt unlock'

# Ansible playbook function for zsh
if [ -n "$ZSH_VERSION" ]; then
    app() { 
        ansible-playbook playbooks/"$@"
    }
fi 