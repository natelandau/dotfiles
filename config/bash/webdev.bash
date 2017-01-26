#!/usr/bin/env bash

# Run locally installed npm packages
# http://stackoverflow.com/questions/9679932/how-to-use-package-installed-locally-in-node-modules
# usage:
#   $ npm-exec grunt
alias npm-exec='PATH=$(npm bin):$PATH'
alias grunt="npm-exec grunt"

# `ghi` is a gem that creates and reads github issues
# https://github.com/stephencelis/ghi
if command -v ghi &> /dev/null; then
  alias issue='ghi'
  alias task='ghi'
fi

# Edit /etc/hosts file
alias editHosts='sudo edit /etc/hosts'

# Grabs headers from web page
httpHeaders () { http -h "$@" ; }

# Start an HTTP server from a directory, optionally specifying the port
function server() {
  local port="${1:-8000}";
  sleep 1 && open "http://localhost:${port}/" &
  # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
  # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
  python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port";
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
function phpserver() {
  local port="${1:-4000}";
  local ip=$(ipconfig getifaddr en1);
  sleep 1 && open "http://${ip}:${port}/" &
  php -S "${ip}:${port}";
}

function smartResize() {
  mogrify -path "$3" -filter Triangle -define filter:support=2 -thumbnail "$2" -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB "$1"
}

# Apache specific commands
if command -v apache &> /dev/null ; then
  alias apacheLogs='less +F /var/log/apache2/error_log'
  alias apacheEdit='sudo edit /etc/httpd/httpd.conf'       # apacheEdit:    Edit httpd.conf
  alias apacheRestart='sudo apachectl graceful'            # apacheRestart: Restart Apache
  alias herr='tail /var/log/httpd/error_log'              #  herr:  Tails HTTP error logs
fi

function httpStatus() {
  # -----------------------------------
  # Shamelessly taken from: https://gist.github.com/rsvp/1171304
  #
  # Usage:  httpStatus URL [timeout] [--code or --status] [see 4.]
  #                                             ^message with code (default)
  #                                     ^code (numeric only)
  #                           ^in secs (default: 3)
  #                   ^URL without "http://" prefix works fine.
  #
  #  4. curl options: e.g. use -L to follow redirects.
  #
  #  Dependencies: curl
  #
  #         Example:  $ httpStatus bit.ly
  #                   301 Redirection: Moved Permanently
  #
  #         Example: $ httpStatus www.google.com 100 -c
  #                  200
  #
  # -----------------------------------
  local curlops
  local arg4
  local arg5
  local arg6
  local arg7
  local flag
  local timeout
  local url

  saveIFS=${IFS}
  IFS=$' \n\t'

  url=${1}
  timeout=${2:-'3'}
  #            ^in seconds
  flag=${3:-'--status'}
  #    curl options, e.g. -L to follow redirects
  arg4=${4:-''}
  arg5=${5:-''}
  arg6=${6:-''}
  arg7=${7:-''}
  curlops="${arg4} ${arg5} ${arg6} ${arg7}"

  #      __________ get the CODE which is numeric:
  code=$(echo "$(curl --write-out %{http_code} --silent --connect-timeout ${timeout} \
                    --no-keepalive ${curlops} --output /dev/null  ${url})")

  #      __________ get the STATUS (from code) which is human interpretable:
  case $code in
       000) status="Not responding within ${timeout} seconds" ;;
       100) status="Informational: Continue" ;;
       101) status="Informational: Switching Protocols" ;;
       200) status="Successful: OK within ${timeout} seconds" ;;
       201) status="Successful: Created" ;;
       202) status="Successful: Accepted" ;;
       203) status="Successful: Non-Authoritative Information" ;;
       204) status="Successful: No Content" ;;
       205) status="Successful: Reset Content" ;;
       206) status="Successful: Partial Content" ;;
       300) status="Redirection: Multiple Choices" ;;
       301) status="Redirection: Moved Permanently" ;;
       302) status="Redirection: Found residing temporarily under different URI" ;;
       303) status="Redirection: See Other" ;;
       304) status="Redirection: Not Modified" ;;
       305) status="Redirection: Use Proxy" ;;
       306) status="Redirection: status not defined" ;;
       307) status="Redirection: Temporary Redirect" ;;
       400) status="Client Error: Bad Request" ;;
       401) status="Client Error: Unauthorized" ;;
       402) status="Client Error: Payment Required" ;;
       403) status="Client Error: Forbidden" ;;
       404) status="Client Error: Not Found" ;;
       405) status="Client Error: Method Not Allowed" ;;
       406) status="Client Error: Not Acceptable" ;;
       407) status="Client Error: Proxy Authentication Required" ;;
       408) status="Client Error: Request Timeout within ${timeout} seconds" ;;
       409) status="Client Error: Conflict" ;;
       410) status="Client Error: Gone" ;;
       411) status="Client Error: Length Required" ;;
       412) status="Client Error: Precondition Failed" ;;
       413) status="Client Error: Request Entity Too Large" ;;
       414) status="Client Error: Request-URI Too Long" ;;
       415) status="Client Error: Unsupported Media Type" ;;
       416) status="Client Error: Requested Range Not Satisfiable" ;;
       417) status="Client Error: Expectation Failed" ;;
       500) status="Server Error: Internal Server Error" ;;
       501) status="Server Error: Not Implemented" ;;
       502) status="Server Error: Bad Gateway" ;;
       503) status="Server Error: Service Unavailable" ;;
       504) status="Server Error: Gateway Timeout within ${timeout} seconds" ;;
       505) status="Server Error: HTTP Version Not Supported" ;;
       *)   echo " !!  httpstatus: status not defined." && safeExit ;;
  esac


  # _______________ MAIN
  case ${flag} in
       --status) echo "${code} ${status}" ;;
       -s)       echo "${code} ${status}" ;;
       --code)   echo "${code}"         ;;
       -c)       echo "${code}"         ;;
       *)        echo " !!  httpstatus: bad flag" && safeExit;;
  esac

  IFS="${saveIFS}"
}

