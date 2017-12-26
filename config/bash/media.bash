if command -v ffmpeg &>/dev/null; then

  ffjson() {
    # Use ffmpeg's built in file checker to output a JSON containing all
    # the stream information from a media file
    ffprobe -v quiet -print_format json -show_format -show_streams "$1"
  }

  gifify() {
    # about 'Converts a .mov file into an into an animated GIF.'
    #   From https://gist.github.com/SlexAxton/4989674#comment-1199058
    #   Requirements (Mac OS X using Homebrew): brew install ffmpeg gifsicle imagemagick
    # param '1: MOV file name'
    # param '2: max width in pixels (optional)'
    # example '$ gifify foo.mov'
    # example '$ gifify foo.mov 600'

    if [ -z "$1" ]; then
      echo "$(tput setaf 1)No input file given. Example: gifify example.mov [max width (pixels)]$(tput sgr 0)"
      return 1
    fi

    output_file="${1%.*}.gif"

    echo "$(tput setaf 2)Creating $output_file...$(tput sgr 0)"

    if [ ! -z "$2" ]; then
      maxsize="-vf scale=$2:-1"
    else
      maxsize=""
    fi

    ffmpeg -loglevel panic -i $1 $maxsize -r 10 -vcodec png gifify-tmp-%05d.png
    convert +dither -layers Optimize gifify-tmp-*.png GIF:- | gifsicle --no-warnings --colors 256 --delay=10 --loop --optimize=3 --multifile - >$output_file
    rm gifify-tmp-*.png

    echo "$(tput setaf 2)Done.$(tput sgr 0)"
  }
fi

imgSize() {
  # imgSize:  Quickly get image dimensions from the command line
  local width height
  if [[ -f $1 ]]; then
    height=$(sips -g pixelHeight "$1" | tail -n 1 | awk '{print $2}')
    width=$(sips -g pixelWidth "$1" | tail -n 1 | awk '{print $2}')
    echo "${width} x ${height}"
  else
    echo "File not found"
  fi
}

64enc() {
  # Encode a given image file as base64 and output css background property to clipboard
  openssl base64 -in "$1" | awk -v ext="${1#*.}" '{ str1=str1 $0 }END{ print "background:url(data:image/"ext";base64,"str1");" }' | pbcopy
  echo "$1 encoded to clipboard"
}

whereisthis() {
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
