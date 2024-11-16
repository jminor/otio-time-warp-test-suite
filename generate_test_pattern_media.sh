#!/bin/bash
set -e

# Generate a movie with SMPTE test pattern, timecode & frame number burn-in,
# and audio tone in a few video and audio codec flavors.

FPS=24
SIZE=1920x1080
DURATION=5
FONTSIZE=75
AUDIORATE=48000
AUDIOFREQ=440

TIMECODESTART="01:00:00:00"

TESTPATTERN="smptehdbars=rate=$FPS:size=$SIZE:duration=$DURATION"
AUDIOTONE="sine=frequency=$AUDIOFREQ:sample_rate=$AUDIORATE:duration=$DURATION"

MESSAGE1="$SIZE @ $FPS fps"
MESSAGE2="$AUDIOFREQ @ $AUDIORATE Hz"

# Q: Does this "OCRB" font make the OCR more reliable?
# A: Not enough to matter. Using OCR_CROP and whitelist (in ocr_frame_counter.sh) is more important.
#TEXTFORMAT="fontfile=./OCRB.ttf:fontsize=$FONTSIZE:fontcolor=white:box=1:boxcolor=black:boxborderw=10"
TEXTFORMAT="font=Sans:fontsize=$FONTSIZE:fontcolor=white:box=1:boxcolor=black:boxborderw=10"

# Let's draw text like this in the middle of the screen:
# 1920x1080 @ 24 fps
# 440 @ 48000 Hz
# 01:00:00:12
#
# And the frame counter in the top right corner:
# 00012
TEXTBURNIN="\
drawtext=text='$MESSAGE1':rate=$FPS:x=(w-tw)/2:y=h/2-lh*2:$TEXTFORMAT, \
drawtext=text='$MESSAGE2':rate=$FPS:x=(w-tw)/2:y=h/2-lh:$TEXTFORMAT, \
drawtext=timecode='01\:00\:00\:00':rate=$FPS:x=(w-tw)/2:y=h/2:$TEXTFORMAT, \
drawtext=text='%{eif\:n\:d\:5}':rate=$FPS:x=10:y=10:$TEXTFORMAT, \
drawtext=text='%{eif\:n+3600*$FPS\:d\:5}':rate=$FPS:x=10:y=10+$FONTSIZE:$TEXTFORMAT"

FILTERGRAPH="[1:a]showwaves=s=$SIZE:mode=line:rate=$FPS[wave]; \
                 [0:v][wave]overlay=shortest=1:y=h/2-130[video_with_wave]; \
                 [video_with_wave]$TEXTBURNIN"

OUTPUTBASE="test_pattern_media_${SIZE}_${FPS}"

OUTPUT="${OUTPUTBASE}_h264.mov"
ffmpeg \
    -f lavfi -i "$TESTPATTERN" \
    -f lavfi -i "$AUDIOTONE" \
    -timecode "$TIMECODESTART" \
    -filter_complex "$FILTERGRAPH" \
    -t "$DURATION" \
    -c:a pcm_s16be \
    -y "$OUTPUT"

# See: https://askubuntu.com/questions/907398/how-to-convert-a-video-with-ffmpeg-into-the-dnxhd-dnxhr-format
OUTPUT="${OUTPUTBASE}_DNxHD-LB.mov"
ffmpeg \
    -f lavfi -i "$TESTPATTERN" \
    -f lavfi -i "$AUDIOTONE" \
    -timecode "$TIMECODESTART" \
    -filter_complex "$FILTERGRAPH" \
    -t "$DURATION" \
    -c:v dnxhd -b:v 36M -c:a pcm_s16le \
    -y "$OUTPUT"

# See: https://ottverse.com/ffmpeg-convert-to-apple-prores-422-4444-hq/
OUTPUT="${OUTPUTBASE}_ProRes422HQ.mov"
ffmpeg \
    -f lavfi -i "$TESTPATTERN" \
    -f lavfi -i "$AUDIOTONE" \
    -timecode "$TIMECODESTART" \
    -filter_complex "$FILTERGRAPH" \
    -t "$DURATION" \
    -c:v prores_ks -profile:v 3 -vendor apl0 -bits_per_mb 8000 -pix_fmt yuv422p10le -c:a pcm_s16le \
    -y "$OUTPUT"

# NOTE: The resulting file's duration might not be the exact duration you asked for
# depending on some variables that I don't quite understand. For example, if you use
# the default audio codec 'aac' when asking for a 5 second file, ffmpeg produces a file
# which is 5.02 seconds long. Using -acodec pcm_s16be instead, results in a 5 second file.
