if command -v docker &>/dev/null; then

    # Stop all running containers
    alias dstopall='sudo docker stop $(sudo docker ps -aq)'

    # Prune volumes
    alias dprunevol='sudo docker volume prune'

    # Prune system
    alias dprunesys='sudo docker system prune -a'

    # Remove all containers
    alias ddelimages='sudo docker rmi $(docker images -q)'

    # List all containers
    alias dps='docker ps -a'

    # Show docker disk usage
    alias ddf='docker system df'

    # Usage: dlogs <container_name>
    alias dlogs='docker logs -tf --tail="50" '

    # Usage: dexec <container_name> <command>
    alias dexec='sudo docker exec -it '

    # List all images sorted by name
    alias dpss='sudo docker ps -a --format "table {{.Names}}\t{{.State}}\t{{.Status}}\t{{.Image}}" | (sed -u 1q; sort)'

    # Prune all images, volumes, and system
    alias dprune='ddelimages ; dprunevol ; dprunesys'

    # Display IP addresses of all containers
    alias dips="sudo docker ps -q | xargs -n 1 docker inspect --format '{{json .}}' | jq -rs 'map(.Name,.NetworkSettings.Networks[].IPAddress) | .[]'"

    dip() {
        # Display IP address of a container. Usage: dip <container_name>
        sudo docker inspect --format '{{json .}}' "$1" | jq -rs 'map(.NetworkSettings.Networks[].IPAddress) | .[]'
    }
fi
