# OpenTimelineIO Time Warp Test Suite

## Status

Note: This is a work in progress. The test suite is not yet complete, and there
are some flaws which need to be addressed before it becomes useful. Specifically:
- The provided baseline MOV file has not been thouroughly vetted for accuracy.
- Trim-to-fill time warps are incorrectly tagged as TimeEffect instead of LinearTimeWarp, and thus are missing the essential time_scalar values in the OTIO file.
- Several reverse time warps have incorrect time_scalar values in the OTIO file.

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
Avid Media Composer and then converted to OTIO (see below for specifics).
In future, we may choose to author new versions of the test suite in other applications (see list of applications below).

The AAF and rendered MOV exported from Media Composer are the ground truth to compare
others against.

As OTIO import/export features are added to Media Composer (currently in beta/preview as of Dec 2024)
we can use this suite to verify that the OTIO and AAF match each other.

### Re-creating the Test Timeline
To recreate `time_warp_test_suite.otio` and `time_warp_test_suite.otioz` from the source AAF, use this command:

```bash
% ./make_time_warp_test_timeline.sh
```

Note: As of 2024-12-05, there is a
[known issue](https://github.com/OpenTimelineIO/otio-aaf-adapter/issues/53)
in the OTIO AAF adapter, which causes the start timecode
of these test clips to be incorrect. To work around the bug, use
[this fix](https://github.com/OpenTimelineIO/otio-aaf-adapter/pull/44),
by running this command instead of the one above (here using [uvx](https://docs.astral.sh/uv/guides/tools/#using-tools) for convenience):
```bash
% uv run --with opentimelineio --with git+https://github.com/markreidvfx/otio-aaf-adapter.git@mastermob_refactor_v1  ./make_time_warp_test_timeline.sh
```

## Time Warp Test Suite

The time warp test suite is a single video track with clips spliced
end-to-end, each of which has a different time warp effect applied.
The time warp effects are chosen carefully to exercise the full range
of time warp capabilities supported by OTIO, and several that are not
yet supported.

Note:
- There are 1-frame gaps between each clip for clarity.
- Each clip has a marker with an explanation of the time warp effect on that clip.
- Audio clips do not (yet) have any time warp effects applied.

Bug Alert:
- Several of these effects are incorrect due to bugs in the AAF->OTIO conversion. They are noted with (BUG)

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
  - Slow down to 99% speed
  - Slow down to 90% speed
  - Slow down to 50% speed
  - Slow down to 10% speed
  - Speed up to 101% speed
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
- Linear time warps trim-to-fill ("trim" is different from "fit")
  - Trim-to-fill 99 frames into 100 (BUG: TimeEffect should be LinearTimeWarp)
  - Trim-to-fill 90 frames into 100 (BUG: TimeEffect should be LinearTimeWarp)
  - Trim-to-fill 50 frames into 100 (BUG: TimeEffect should be LinearTimeWarp)
  - Trim-to-fill 33 frames into 100 (BUG: TimeEffect should be LinearTimeWarp)
  - Trim-to-fill 5 frames into 100 (BUG: TimeEffect should be LinearTimeWarp)
  - Trim-to-fill 100 frames into 99 (BUG: TimeEffect should be LinearTimeWarp)
  - Trim-to-fill 100 frames into 50 (BUG: TimeEffect should be LinearTimeWarp)
  - Trim-to-fill 100 frames into 33 (BUG: TimeEffect should be LinearTimeWarp)
  - Trim-to-fill 100 frames into 10 (BUG: TimeEffect should be LinearTimeWarp)
  - Trim-to-fill 100 frames into 9 (BUG: TimeEffect should be LinearTimeWarp)
- Backwards time warps
  - Reverse 100%
  - Reverse 50% (BUG: -0.51 should be -0.50)
  - Reverse 200% (BUG: -1.0 should be -2.0)
  - Reverse 30% (BUG: -0.31 should be -0.30)
  - Reverse 120% (BUG: -1.0 should be -1.2)

### TODO: Add these time warps also...

- Trimmed linear time warps
  - All/many of the above, but with the clip trimmed to a shorter length *after* applying the time warp.
  - Ideally we can pick trims that highlight the important cases where the phase/offset of the time warp affects the output.
  - For example, trimming 2 frames off a 33% speed up should result in a 33% speed up of the remaining frames, not a 33% slow down should cause the 1st frame of media to only appear for 1 frame instead of 3 frames.

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
file `time_warp_test.baseline.ocr_results.txt` contains the expected frame counter
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
% diff ocr_results.txt time_warp_test.baseline.ocr_results.txt && echo PASS || echo FAIL
PASS
```

### [Toucan](https://github.com/OpenTimelineIO/toucan)

Toucan can render the `time_warp_test_suite.otio` to a MOV file for comparison, like this:

```bash
% toucan-render time_warp_test_suite.otio toucan_render.mov
% ./ocr_frame_counter.sh toucan_render.mov > ocr_results.txt
% diff ocr_results.txt time_warp_test.baseline.ocr_results.txt && echo PASS || echo FAIL
```

### Your Application Here

If your application supports OTIO, you can follow these steps:
- Download this repository (the full [repository ZIP file](https://github.com/jminor/otio-time-warp-test-suite/archive/refs/heads/main.zip) is most convenient)
- Import one of these:
  - `time_warp_test_suite.otioz` (media included)
  - `time_warp_test_suite.otio` file, plus separate `test_pattern_media_1920x1080_24_h264.mov` media file.
- Take some screenshots or notes about how this imports, and any errors or warnings that come up.
- See if it appears to play back correctly.
- Render out a video of the sequence.
- Use the provided OCR script to extract frame numbers from the video like this: `./ocr_frame_counter.sh rendered.mov > ocr_results.txt`
- Compare to the provided `time_warp_test.baseline.ocr_results.txt` file.
- Let us know how it went! (See contact info at the top of this README.)

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
