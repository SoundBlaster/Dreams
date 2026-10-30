# Packaged backend follow-up

Dreams now consumes the local optional ScreenerScreenCaptureKit product under the
existing pilot flag. Its custom GPU readback uses the public raw BGRA8 converter.
Normal builds retain the released dependency and omit pilot instrumentation.

```sh
rtk proxy make capture-metal-pilot SCREENER_PATH=/path/to/Screener
```

Canonical local report and native comparison evidence:
`/Users/egor/Development/GitHub/Screener/docs/validation/packaged-backend-2026-10-12/README.md`.
Fresh run: `artifacts/metal-pilot/20261012T181959Z` (14 exact native RGB matches).
The historical `metal-pilot-2026-10-12` report is preserved unchanged.
