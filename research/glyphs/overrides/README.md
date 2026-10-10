# Manual contour edits

`Gxx.svg` in this folder replaces the tracing of glyph Gxx. To take a contour into editing:

```sh
.venv/bin/python scripts/glyphs/pipeline.py adopt G06
```

Keep the `viewBox`, draw inside `id="glyph"`, and run `build` after editing. Details in [../PIPELINE.md](../PIPELINE.md#editing-a-contour-by-hand).
