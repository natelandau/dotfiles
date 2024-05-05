if command -v docker &>/dev/null; then
    alias dstopall='sudo docker stop $(sudo docker ps -aq)'
    alias dprunevol='sudo docker volume prune'
    alias dprunesys='sudo docker system prune -a'
    alias ddelimages='sudo docker rmi $(docker images -q)'
    alias derase='dstopcont ; drmcont ; ddelimages ; dvolprune ; dsysprune'
    alias dprune='ddelimages ; dprunevol ; dprunesys'
    alias dps='sudo docker ps -a'
    alias dpss='sudo docker ps -a --format "table {{.Names}}\t{{.State}}\t{{.Status}}\t{{.Image}}" | (sed -u 1q; sort)'
    alias ddf='sudo docker system df'
    alias dlogs='sudo docker logs -tf --tail="50" '
    alias dexec='sudo docker exec -ti'
    alias dips="sudo docker ps -q | xargs -n 1 docker inspect --format '{{json .}}' | jq -rs 'map(.Name,.NetworkSettings.Networks[].IPAddress) | .[]'"
    dip() {
        sudo docker inspect --format '{{json .}}' "$1" | jq -rs 'map(.NetworkSettings.Networks[].IPAddress) | .[]'
    }
fi
