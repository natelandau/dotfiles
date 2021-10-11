if command -v ffprobe &>/dev/null; then
    alias ffjson="ffprobe -v quiet -print_format json -show_format -show_streams" # ffprobe streams in json format
fi

if command -v sips &>/dev/null; then
    imgSize() {
        # DESC:		Quickly get image dimensions from the command line
        # ARGS:		$1 (required): Image file
        # OUTS:		None
        # REQS:		macOS
        # USAGE:
        # NOTE:

        if [ -z "${1}" ]; then
            echo "No input file given"
            return 1
        fi

        local width height
        if [[ -f $1 ]]; then
            height=$(sips -g pixelHeight "$1" | tail -n 1 | awk '{print $2}')
            width=$(sips -g pixelWidth "$1" | tail -n 1 | awk '{print $2}')
            echo "${width} x ${height}"
        else
            echo "File not found"
        fi
    }
fi

if [[ ${OSTYPE} == "darwin"* ]]; then
    64enc() {
        # DESC:   Encode a given image file as base64 and output css background property to clipboard
        # ARGS:		$1 (required): Image file
        # OUTS:		None
        # REQS:   macOS
        # NOTE:
        # USAGE:
        if [ -z "${1}" ]; then
            echo "No input file given"
            return 1
        fi

        openssl base64 -in "$1" | awk -v ext="${1#*.}" '{ str1=str1 $0 }END{ print "background:url(data:image/"ext";base64,"str1");" }' | pbcopy
        echo "$1 encoded to clipboard"
    }

    whereisthis() {
        # DESC:		Run on photos with embedded geo-data to get the coordinates and open it in a Google map
        # ARGS:		$1 (required): Image file
        # OUTS:		None
        # REQS:		macOS
        # NOTE:
        # USAGE:

        if [ -z "${1}" ]; then
            echo "No input file given"
            return 1
        fi

        local lat=$(mdls -raw -name kMDItemLatitude "${1}")
        if [ "${lat}" != "(null)" ]; then
            local long=$(mdls -raw -name kMDItemLongitude "${1}")
            echo -n "${lat}","${long}" | pbcopy
            echo "${lat}","${long}" copied
            open https://www.google.com/maps?q="${lat}","${long}"
        else
            echo "No Geo-Data Available"
            return 1
        fi
    }
fi
