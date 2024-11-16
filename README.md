# OpenTimelineIO Time Warp Test Suite

## Introduction

This repository contains a test suite for OpenTimelineIO time warp effects.
The aim is ensure that the interpretation of time warps is consistent across
OTIO implementations in different NLEs, renderers, 3rd party tools, and DCCs.

## Methodology

We use scripts in this repository to generate test media, import that media
into various NLEs, apply time warps, and export the results. We then use OCR
to extract the timecode and frame counter from the rendered video, and compare
the results to the desired reference baseline.

This method can be applied to any NLE, renderer, or DCC. If those applications
support OTIO, then we can import the test OTIO provided here rather than manually
recreating the the complex set of time warps.

## Test Media

To generate the test media, use the `generate_test_pattern_media.sh` script, which
requires a recent version of ffmpeg (v 7.0.1 at the time of this writing). Then verify
that the OCR script can extract the frame counter from the rendered video.

```bash
% ./generate_test_pattern_media.sh
% ./ocr_frame_counter.sh test_pattern_media_1920x1080_24_h264.mov > ocr_results.txt
% diff ocr_results.txt ocr_baseline.txt && echo PASS || echo FAIL
```
