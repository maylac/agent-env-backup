# HyperFrames Production Checklist

## Composition

- Root has `data-composition-id`, width, height, and duration.
- Timeline-visible elements have stable, human-readable `id` values.
- Scenes have predictable timing and do not overlap unintentionally.
- Text fits within the frame at 1920x1080 and intended mobile crops.
- Assets use relative paths and are documented.

## Commands

Preferred package scripts:

```bash
npm run lint
npm run render
```

Useful verification:

```bash
ffprobe -v error -show_entries format=duration,size -of default=noprint_wrappers=1 renders/output.mp4
ffmpeg -y -ss 00:00:02 -i renders/output.mp4 -frames:v 1 /tmp/frame-02.png
```

## Visual QA

Check at least:

- Early hook frame.
- Middle explanatory frame.
- Final CTA frame.

Look for:

- Blank frames.
- Cropped text.
- Overlapping elements.
- Illegible small text.
- Missing assets.
- Off-brand or overly generic visuals.

## HeyGen Layering

Use HeyGen outputs as:

- Avatar clip layer.
- Voiceover audio layer.
- Localized replacement track.
- Optional talking-head scene.

Keep the rest of the motion system editable in HyperFrames.
