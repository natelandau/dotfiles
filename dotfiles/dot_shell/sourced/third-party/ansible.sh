alias ainv="ansible-inventory all --graph --vars" # Ansible inventory graph
alias ave="ansible-vault encrypt"                 # Encrypt a file with ansible-vault
alias avd="ansible-vault decrypt"                 # Decrypt a file with ansible-vault
alias avv="ansible-vault view"                    # View a file encrypted with ansible-vault
alias avedit="ansible-vault edit"                 # Edit a file encrypted with ansible-vault

aus() {
    # Run the Ansible Update Server (AUS) playbook with options
    # USAGE: aus -l [host] -t [tag],[tag]

    ANSIBLE_DIR="${HOME}/repos/ansible-update-server"

    if [ -d "${ANSIBLE_DIR}" ]; then
        pushd "${ANSIBLE_DIR}" &>/dev/null || return 1
        poetry run ansible-playbook main.yml "${@}"
        popd &>/dev/null || return 1
    else
        echo "Can not find ${ANSIBLE_DIR}"
        return 1
    fi
}
