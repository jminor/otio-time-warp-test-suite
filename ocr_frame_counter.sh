#!/bin/bash
set -e

INPUT_FILE="$1"

OCR_CROP="550:75:0:0"

# Use optical character recognition (OCR) to find the frame number in the top corner of the video
ffprobe -show_entries frame_tags=lavfi.ocr.text \
  -f lavfi -i "movie='${INPUT_FILE}', crop=${OCR_CROP}, negate, ocr=whitelist=0123456789" 2<&1 \
  | fgrep ocr.text \
  | sed -E 's/^[^0-9]+0*([0-9]+).*/\1/g'  # just the frame number (no text, no leading zeros)

# If you want to extract the timecode string instead, you'll need to adjust the placement
# and/or the crop, and include ":" in the ocr whitelist. Note: without the whitelist, the
# results are too noisy to be useful.
# ffprobe -show_entries frame_tags=lavfi.ocr.text \
#   -f lavfi -i "movie='${INPUT_FILE}', ocr=whitelist=0123456789\\\:" 2<&1 \
#   | fgrep ocr.text
