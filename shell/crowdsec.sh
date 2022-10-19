if [[ $(command -v crowdsec &>/dev/null) || -e /usr/bin/crowdsec ]]; then

    csec() {
        case ${1} in
            update)
                sudo cscli hub update
                sudo cscli hub upgrade
                ;;
            dash | decisions)
                sudo cscli decisions list
                ;;
            alerts)
                sudo cscli alerts list
                ;;
            delete)
                if [ -n "${2}" ]; then
                    sudo cscli decisions delete "${2}"
                else
                    echo "Please provide a decision ID or IP Address"
                fi
                ;;
            logs)
                sudo tail -f /var/log/crowdsec.log
                ;;
            journal)
                sudo journalctl -u crowdsec -f
                ;;
            status)
                sudo systemctl status crowdsec
                ;;
            list)
                sudo cscli hub list
                ;;
            *)
                printf "Usage: csec [command]\n\n"
                printf "Run crowdsec -h for more information\n\n"
                printf "Available commands:\n"
                printf "  alerts\t\tShow crowdsec alerts (All alerts)\n"
                printf "  dash\t\t\tShow crowdsec decisions (Current bans)\n"
                printf "  delete [ID]\t\tDelete a decision by ID or IP Address\n"
                printf "  journal\t\tTail crowdsec journal\n"
                printf "  list\t\t\tList installed collections, parsers, scenarios, etc\n"
                printf "  logs\t\t\tTail crowdsec logs\n"
                printf "  status\t\tShow crowdsec service status\n"
                printf "  update\t\tUpdate crowdsec hub\n"
                ;;
        esac

    }

fi
