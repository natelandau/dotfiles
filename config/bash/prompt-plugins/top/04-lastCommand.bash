segmentLastCommand() {
  local timerM=0
  local timerS=0
  local commandExitCode="$lastExit"
  local enabled=true # If false, this segment will be ignored

  local commandEnded=$(date +'%s')
  local lastHistory="$(HISTTIMEFORMAT='%s ' history 1)"
  local commandStarted=$(awk '{print $2}' <<<"$lastHistory")
  local commandTime=$((commandEnded - commandStarted))
  local lastHistoryId=$(awk '{print $1}' <<<"$lastHistory")
  local lastHistoryCommand=$(awk '{print $3}' <<<"$lastHistory")

  # Set colors based on exit code of previous command
  if [ $commandExitCode -eq 0 ]; then
    local fground=$whi
    local bground=$grn
  else
    local fground=$whi
    local bground=$red
  fi

  if [[ "$commandTime" -gt 0 ]]; then
    timer_m=$((commandTime / 60))
    timer_s=$((commandTime % 60))
    local promptSegment=" '${lastHistoryCommand}' ${timer_m}m ${timer_s}s "
  else
    local promptSegment=" last: '${lastHistoryCommand}' "
  fi

  # Output to prompt
  _parseSegments_ "${promptSegment}" "${fground}" "${bground}" "${enabled}"
}
segmentLastCommand
