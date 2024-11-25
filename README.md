# OpenTimelineIO Time Warp Test Suite

## Status

Note: This is a work in progress. The test suite is not yet complete, and there
are some flaws which need to be addressed before it becomes useful. Specifically:
- The provided `time_warp_test_suite.otio` file has source_ranges which do not align with the embedded timecode in the sample media.
- The provided baseline MOV file has not been thouroughly vetted for accuracy.

If you would like to help with this project, feel free to use any of these:
- Open a [discussion topic](https://github.com/jminor/otio-time-warp-test-suite/discussions)
- File an [issue](https://github.com/jminor/otio-time-warp-test-suite/issues)
- Join the #OpenTimelineIO Slack channel on https://slack.aswf.io/

## Introduction

This repository contains a test suite for [OpenTimelineIO](https://opentimeline.io/)
time warp effects. The aim is ensure that the interpretation of time warps is
consistent across OTIO implementations in different NLEs, renderers, 3rd party tools,
and DCCs.

## Methodology

We use scripts in this repository to generate test media, import that media
into various NLEs, apply time warps, and export the results. We then use Optical
Character Recognition (OCR) to extract the timecode and frame counter from the
rendered video, and compare the results to the desired reference baseline.

If all the time warps effects were applied correctly, then the OCR results should
match the reference baseline exactly. If not, then we can compare frame by frame
to determine where the mismatch occurred.

This method can be applied to any NLE, renderer, or DCC. If those applications
support OTIO, then we can import the test OTIO provided here rather than manually
recreating the the complex set of time warps.

## Requirements

To generate the test media, use the `generate_test_pattern_media.sh` script, which
requires a recent version of [ffmpeg](https://ffmpeg.org/) (v 7.0.1 at the time of this writing).

The `ocr_frame_counter.sh` script requires a recent version of
ffprobe (which is usually installed with ffmpeg) [compiled with the
OCR feature enabled](https://ffmpeg.org/ffmpeg-filters.html#ocr).

On macOS you can get both ffmpeg and ffprobe via `brew install ffmpeg`.

## Test Media

One file is provided:
- `test_pattern_media_1920x1080_24_h264.mov`

The test media is a short video clip with the following characteristics:
- 1920x1080 resolution
- 24 frames per second
- 5 seconds duration
- Starting timecode of 01:00:00:00
- Timecode is burned into the video (middle)
- Frame counter is burned into the video (top right) in two forms:
  - Counter starting at frame 0 <-- this is the text used for OCR comparison
  - Counter starting at frame 86400 (1 hour at 24fps) matching the timecode
- Not Used, but included for future use:
  - SMPTE color bars
  - 440 Hz sine wave audio
  - Overlaid audio waveform

To generate the test media in a variety of codecs, use the `generate_test_pattern_media.sh` script.
Then verify that the OCR script can extract the frame counter from the rendered video.

```bash
% ./generate_test_pattern_media.sh
% ./ocr_frame_counter.sh test_pattern_media_1920x1080_24_h264.mov > ocr_results.txt
% diff ocr_results.txt test_pattern.ocr_baseline.txt && echo PASS || echo FAIL
PASS
```

![test_pattern_media_1920x1080_24_h264.mov](test_pattern_media_1920x1080_24_h264.mov)

## Test Timeline

Two files are provided:
- `time_warp_test_suite.otio` is the test timeline in OTIO format
- `time_warp_test_suite.otioz` is the same timeline with embedded media (the test media clip above)

The test timeline file `time_warp_test_suite.otio` was originally authored in
Avid Media Composer, so it contains AAF-specific metadata in addition to standard OTIO
time warp effects. The AAF-specific metadata is not used in this test suite.

TODO: Should we strip that metadata out? For now, it is helpful for debugging the AAF->OTIO
conversion process, but people may find it confusing...

the AAF and rendered MOV exported from Media Composer are the ground truth to compare
others against.

As OTIO import/export features are added to Media Composer (currently in beta/preview)
we can use this suite to verify that the OTIO and AAF match each other.

## Time Warp Test Suite

The time warp test suite is a single video track with clips spliced end-to-end, each
of which has a different time warp effect applied. The time warp effects are chosen
carefully to exercise the full range of time warp capabilities supported by OTIO,
and several that are not yet supported.

Here is a complete list of the time warp effects in order:
- Full clip (no effects)
- Segments:
  - Segment at start (no effects)
  - Segment in middle (no effects)
  - Segment at end (no effects)
- Freeze frames:
  - Freeze frame at start
  - Freeze frame in middle
  - Freeze frame at end
- Linear time warps by percentage
  - Identity 100% speed
  - Slow down to 99% speed (is 1 frame repeated?)
  - Slow down to 90% speed
  - Slow down to 50% speed
  - Slow down to 10% speed
  - Speed up to 101% speed (is 1 frame skipped?)
  - Speed up to 110% speed
  - Speed up to 2x (200%) speed
  - Speed up to 10x (1000%) speed
- Linear time warps fit-to-fill
  - Fit-to-fill 99 frames into 100
  - Fit-to-fill 90 frames into 100
  - Fit-to-fill 50 frames into 100
  - Fit-to-fill 33 frames into 100
  - Fit-to-fill 5 frames into 100
  - Fit-to-fill 100 frames into 99
  - Fit-to-fill 100 frames into 50
  - Fit-to-fill 100 frames into 33
  - Fit-to-fill 100 frames into 10
  - Fit-to-fill 100 frames into 9
- Backwards time warps
  - Reverse 100% (frames 99 to 0)
  - Reverse 50% (frames 99 to 50, each 2x?)
  - Reverse 200% (frames 99 to 0, on 2s)
  - Reverse 30%
  - Reverse 120%

### TODO: Add these time warps also...

- Keyframed non-linear time warps
  - Linear keyframes
  - Bezier keyframes
  - Mix of speed up and slow down
  - Mix of forward and backward
  - Start and end are not the lowest and highest frame used

Should we include these also?
- Out-of-bounds segments:
  - Segment fully before
  - Segment overlapping start
  - Segment fully after
  - Segment overlapping end
  - Segment beyond start and end

## Baseline Video

The verified correct rendered MOV `time_warp_test.baseline.mov` matches
the test suite timeline `time_warp_test_suite.otio` exactly. The OCR result
file `time_warp_test.ocr_baseline.txt` contains the expected frame counter
generated from that video. See below for details on how to regenerate the OCR
results.

## Running the Test Suite

The steps to run the test suite vary depending on the NLE or renderer used.

### [Avid Media Composer](https://www.avid.com/media-composer)

Since the test suite composition was originally authored in Avid Media Composer,
you can import the original AAF, and render the sequence to a MOV file.

- Launch Avid Media Composer.
- Create a project with settings: 1920x1080 24 fps
- Import the test media clip into Media Composer.
- Import the `time_warp_test.avid_media_composer.aaf` into Media Composer.
- Play the sequence to make sure it looks correct.
- Export the sequence to a MOV file.
  - Make sure the MOV is 1920x1080 @ 24fps so the OCR will work.
  - Codec is not important as long as it is supported by ffmpeg (h264 works fine).

Now use OCR to read the frame counter and compare it to the baseline:

```bash
% ./ocr_frame_counter.sh avid_render.mov > ocr_results.txt
% diff ocr_results.txt ocr_baseline.txt && echo PASS || echo FAIL
PASS
```

To recreate the `time_warp_test_suite.otio` from the AAF, use this command:

```bash
% otioconvert -i avid_media_composer/time_warp_test.avid_media_composer.aaf -o converted.otio
% otiotool -i converted.otio --relink-by-name ./ -o new_time_warp_test_suite.otio
```

### [Toucan](https://github.com/OpenTimelineIO/toucan)

Toucan can render the `time_warp_test_suite.otio` to a MOV file for comparison, like this:

```bash
% toucan-render time_warp_test_suite.otio - -raw rgba | ffmpeg -y -f rawvideo -pix_fmt rgba -s 1920x1080 -r 24 -i pipe: toucan_render.mov
% ./ocr_frame_counter.sh toucan_render.mov > ocr_results.txt
% diff ocr_results.txt ocr_baseline.txt && echo PASS || echo FAIL
```

### More Host Applications...

TODO:
- [DaVinci Resolve](https://www.blackmagicdesign.com/products/davinciresolve/)
- [Adobe Premiere Pro](https://www.adobe.com/products/premiere.html)
- [Final Cut Pro X](https://www.apple.com/final-cut-pro/)
- [Nuke Studio](https://www.foundry.com/products/nuke-studio)
- [cineSync Play](https://www.backlight.co/product/cinesync/download)
- [OpenRV](https://github.com/AcademySoftwareFoundation/OpenRV)
- [tlRender](https://github.com/darbyjohnston/tlRender)
- etc.

## What Happens If They Don't Match?

If the OCR results do not match the baseline, then there is a bug or misinterpretation
somewhere in OTIO, the host application's import/export, or the
rendering process. It may not be immediately clear where the issue is, or whether there
is just one or many issues.

This test suite is meant to draw out these issues and provide a clear way to reproduce
them. If you find a discrepancy, please
[file an issue at the OpenTimelineIO repository](https://github.com/AcademySoftwareFoundation/OpenTimelineIO/issues)
so we can help verify the result and figure out next steps.
