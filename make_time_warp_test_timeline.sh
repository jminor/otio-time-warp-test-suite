#!/bin/bash
set -e

# This script re-creates the time warp test suite OTIO from the Avid Media Composer AAF source timeline.

SOURCE_AAF="avid_media_composer/time_warp_test.avid_media_composer.aaf"
SOURCE_MOV="avid_media_composer/time_warp_test.avid_media_composer.mov"
SOURCE_OCR="avid_media_composer/time_warp_test.avid_media_composer.ocr_results.txt"
CONVERTED_OTIO="avid_media_composer/time_warp_test.avid_media_composer.otio"
RELINKED_OTIO="temp.relinked.otio"
CLEANED_OTIO="temp.cleaned.otio"
FINAL_OTIO="time_warp_test_suite.otio"
FINAL_OTIOZ="time_warp_test_suite.otioz"
BASELINE_MOV="time_warp_test.baseline.mov"
BASELINE_OCR="time_warp_test.baseline.ocr_results.txt"

# Check if source files exist
if [ ! -f "$SOURCE_AAF" ]; then
    echo "ERROR: Source AAF not found: $SOURCE_AAF"
    exit 1
fi
if [ ! -f "$SOURCE_MOV" ]; then
    echo "ERROR: Source MOV not found: $SOURCE_MOV"
    exit 1
fi

# Warn about files that will be overwritten
needs_confirmation=false
for file in "$SOURCE_OCR" "$CONVERTED_OTIO" "$RELINKED_OTIO" "$CLEANED_OTIO" "$FINAL_OTIO" "$FINAL_OTIOZ" "$BASELINE_MOV" "$BASELINE_OCR"; do
    if [ -f "$file" ]; then
        echo "WARNING: Existing file will be overwritten: $file"
        needs_confirmation=true
    fi
done
if [ "$needs_confirmation" = true ]; then
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "OCR source MOV..."
./ocr_frame_counter.sh "$SOURCE_MOV" > "$SOURCE_OCR"

echo "Converting AAF to OTIO..."
otioconvert -i "$SOURCE_AAF" -o "$CONVERTED_OTIO"

echo "Relinking media..."
# From: "target_url": "file:///Users/edit/Desktop/test_pattern_media_1920x1080_24_DNxHD-LB.mov"
# To:   "target_url": "./test_pattern_media_1920x1080_24_h264.mov"
# Use sed to change clip names and media paths from DNxHD to h264
# TODO: add a feature to otiotool to relink media with a regex replacement and/or rename clips.
cat "$CONVERTED_OTIO" | \
    sed -E -e 's;"test_pattern_media_1920x1080_24_DNxHD-LB v1";"test_pattern_media_1920x1080_24_h264";' | \
    sed -E -e "s;file:///Users/edit/Desktop/test_pattern_media_1920x1080_24_DNxHD-LB.mov;./test_pattern_media_1920x1080_24_h264.mov;" | \
    cat > "$RELINKED_OTIO"

echo "Cleaning up..."
# Use otiotool --downgrade to remove unused alternate media references
#   (The next step upgrades again to current schema.)
# TODO: add a feature to otiotool to prune unused media references to avoid this hack.
# Use otiotool to remove extraneous metadata and upgrade to the current schema.
cat "$RELINKED_OTIO" | \
    otiotool -i - --downgrade OTIO_CORE:0.14.0 -o - | \
    otiotool -i - --remove-metadata-key AAF -o "$CLEANED_OTIO"

echo "Copying to final location..."
cp "$CLEANED_OTIO" "$FINAL_OTIO"
cp "$SOURCE_MOV" "$BASELINE_MOV"
cp "$SOURCE_OCR" "$BASELINE_OCR"

echo "Building OTIOZ..."
# Remove the output file if it already exists, since otiotool won't overwrite it.
if [ -f "$FINAL_OTIOZ" ]; then
    rm -f "$FINAL_OTIOZ"
fi
# Use --relink-by-name to $PWD to avoid this bug:
# https://github.com/AcademySoftwareFoundation/OpenTimelineIO/issues/1817
otiotool -i "$FINAL_OTIO" --relink-by-name "$PWD" -o "$FINAL_OTIOZ"

echo "Done:"
ls -l "$FINAL_OTIO" "$FINAL_OTIOZ" "$BASELINE_MOV" "$BASELINE_OCR"
