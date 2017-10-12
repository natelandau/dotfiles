_raspberryPi_ () {
  local me

  me=$(whoami)

  if [[ "$me" == "pi" ]]; then
    export LC_ALL=C
  fi
}