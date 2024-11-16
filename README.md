# OpenTimelineIO Time Warp Test Suite

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

This method can be applied to any NLE, renderer, or DCC. If those applications
support OTIO, then we can import the test OTIO provided here rather than manually
recreating the the complex set of time warps.

## Test Media

To generate the test media, use the `generate_test_pattern_media.sh` script, which
requires a recent version of [ffmpeg](https://ffmpeg.org/) (v 7.0.1 at the time of this writing).
Then verify that the OCR script can extract the frame counter from the rendered video.

```bash
% ./generate_test_pattern_media.sh
% ./ocr_frame_counter.sh test_pattern_media_1920x1080_24_h264.mov > ocr_results.txt
% diff ocr_results.txt test_pattern.ocr_baseline.txt && echo PASS || echo FAIL
```

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

### TODO:

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

## Running the Test Suite

Note: the `ocr_frame_counter.sh` script requires a recent version of
ffprobe, which is usually installed with [ffmpeg](https://ffmpeg.org/), [compiled with the
OCR feature enabled](https://ffmpeg.org/ffmpeg-filters.html#ocr).

### [Avid Media Composer](https://www.avid.com/media-composer)

- Launch Avid Media Composer.
- Create a project with settings: 1920x1080 24 fps
- Import the test media clip into Media Composer.
- Import the `timewarp_test.avid_media_composer.aaf` into Media Composer.
- Play the sequence to make sure it looks correct.
- Export the sequence to a MOV file.
  - Make sure the MOV is 1920x1080 @ 24fps so the OCR will work.
  - Codec is not important as long as it is supported by ffmpeg (h264 works fine).

```bash
% ./ocr_frame_counter.sh avid_render.mov > ocr_results.txt
% diff ocr_results.txt ocr_baseline.txt && echo PASS || echo FAIL
```

### [Toucan](https://github.com/OpenTimelineIO/toucan)

```bash
% toucan-render time_warp_test_suite.otio - -raw rgba | ffmpeg -y -f rawvideo -pix_fmt rgba -s 1920x1080 -r 24 -i pipe: toucan_render.mov
% ./ocr_frame_counter.sh toucan_render.mov > ocr_results.txt
% diff ocr_results.txt ocr_baseline.txt && echo PASS || echo FAIL
```

## What Happens If They Don't Match?

If the OCR results do not match the baseline, then there is a bug or misinterpretation
somewhere in OTIO, the host application's import/export, or the
rendering process. It may not be immediately clear where the issue is, or whether there
is just one or many issues.

This test suite is meant to draw out these issues and provide a clear way to reproduce
them. If you find a discrepancy, please
[file an issue at the OpenTimelineIO repository](https://github.com/AcademySoftwareFoundation/OpenTimelineIO/issues)
so we can help verify the result and figure out next steps.
