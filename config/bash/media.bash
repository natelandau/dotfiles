
function ffjson() {
  # Use ffmpeg's built in file checker to output a JSON containing all
  # the stream information from a media file
  ffprobe -v quiet -print_format json -show_format -show_streams "$1"
}

function makegif() {
  # Converts a QuickTime movie into an animated gif
  if [ "$(type -P "gifsicle")" ] && [ "$(type -P "ffmpeg")" ]; then
    if [ -z "$2" ]; then
      ffmpeg -i "$1" -vf scale=720:-1 -pix_fmt rgb24 -r 10 -f gif - | gifsicle --optimize=3 --delay=1 > "$1".gif
    else
      ffmpeg -i "$1" -vf scale="$2":-1 -pix_fmt rgb24 -r 10 -f gif - | gifsicle --optimize=3 --delay=1 > "$1".gif
    fi
  else
    echo "We must have 'gifsicle' and 'ffmpeg' installed to run.  Maybe you should install via Homebrew."
  fi
}

function imgSize() {
  # imgSize:  Quickly get image dimensions from the command line
  local width height
  if [[ -f $1 ]]; then
    height=$(sips -g pixelHeight "$1"|tail -n 1|awk '{print $2}')
    width=$(sips -g pixelWidth "$1"|tail -n 1|awk '{print $2}')
    echo "${width} x ${height}"
  else
    echo "File not found"
  fi
}

function 64enc() {
  # Encode a given image file as base64 and output css background property to clipboard
  openssl base64 -in "$1" | awk -v ext="${1#*.}" '{ str1=str1 $0 }END{ print "background:url(data:image/"ext";base64,"str1");" }'|pbcopy
  echo "$1 encoded to clipboard"
}

function whereisthis() {
  # Run on photos with embedded geo-data to get the coordinates
  # and open it in a Google map
  lat=$(mdls -raw -name kMDItemLatitude "$1")
  if [ "$lat" != "(null)" ]; then
    long=$(mdls -raw -name kMDItemLongitude "$1")
    echo -n "$lat","$long" | pbcopy
    echo "$lat","$long" copied
    open https://www.google.com/maps?q="$lat","$long"
  else
    echo "No Geo-Data Available"
  fi
}