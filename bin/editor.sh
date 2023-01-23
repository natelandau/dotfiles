#!/usr/bin/env bash

# Script to select the correct $EDITOR based on the file being edited
# and the system being used.
#
# Usage:  Place the following in .bash_profile
#         export EDITOR="[LOCATION OF THIS SCRIPT]/editor.sh"

case "$1" in
    *.md | *.markdown | *.mmd | *.mkd)
        if open -Ra "Mark Text" &>/dev/null; then
            open -a "Mark Text" "${1}"
        elif command -v code &>/dev/null; then
            code -wr "${1}"
        else
            editorCommand="$(command -v code micro nano pico | head -n 1)"
            "${editorCommand}" "${1}"
        fi
        ;;
    *.doc | *.docx)
        if open -Ra "Microsoft Word" &>/dev/null; then
            open -a "Microsoft Word" "${1}"
        fi
        ;;
    *.rtf)
        if open -Ra "TextEdit" &>/dev/null; then
            open -a "TextEdit" "${1}"
        elif open -Ra "Microsoft Word" &>/dev/null; then
            open -a "Microsoft Word" "${1}"
        else
            echo "Error: No appropriate editor found for ${1}"
            exit 1
        fi
        ;;
    *.xls | *.xlsx | *.xlsm)
        if open -Ra "Microsoft Excel" &>/dev/null; then
            open -a "Microsoft Excel" "${1}"
        fi
        ;;
    *.ppt | *.pptx)
        if open -Ra "Microsoft Powerpoint" &>/dev/null; then
            open -a "Microsoft Powerpoint" "${1}"
        fi
        ;;
    *.pdf | *.gif | *.jpg | *.jpeg | *.png)
        if open -Ra "Preview" &>/dev/null; then
            open -a "Preview" "${1}"
        else
            echo "Error: No appropriate editor found for ${1}"
            exit 1
        fi
        ;;
    *.graffle | *.gdiagramstyle | *.gstencil | *.gtemplate)
        if open -Ra "Omnigraffle" &>/dev/null; then
            open -a "Omnigraffle" "${1}"
        else
            echo "Error: No appropriate editor found for ${1}"
            exit 1
        fi
        ;;
    *.zip | *.tar | *.gzip | *.bin)
        echo "Error: '${1}' is a compressed file"
        ;;
    *.mp3 | *.mp4 | *.m4v | *.flac | *.avi | *.alac)
        echo "Error: '${1}' is a media file"
        ;;
    *)
        if command -v code &>/dev/null; then
            code -wr "${1}"
        else
            editorCommand="$(command -v micro nano pico | head -n 1)"
            "${editorCommand}" "${1}"
        fi
        ;;
esac
