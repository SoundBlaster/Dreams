# System screen saver experiment

An isolated macOS `.saver` lifecycle probe using the public ScreenSaver framework.
It draws a simple synthetic rain with AppKit. It does **not** use the production
Metal renderer, saved preferences, agent feed, or the installed Dreams font.
It is not a release product and is not installed or selected automatically.

Build on macOS with Xcode's command-line tools:

```sh
bash experiments/system-screensaver/build.sh /absolute/output/directory
```

The ad-hoc-signed result is intended for local development. Distribution requires
separate signing, notarization and installation verification. To test, explicitly
install the module via Finder or in the user's Library/Screen Savers directory,
select it in System Settings, and observe preview, idle activation, manual screen
lock, password prompt, unlock and multiple displays. Test on a disposable user
session first; do not equate compilation with lock-screen support. macOS controls
the authentication UI and when the display sleeps.

Next: extract a shared rendering boundary and test resource loading and feed access
in the system host before claiming parity with the application.

## Local baseline — 2026-11-04

Source SHA-256: Swift `83cfc55d3dee24c1e39415f41f98dfa9ecd8913a8b1cdb0cbace6c0f800264ad`,
plist `4c1be31669e75078902c27796336ff97055b24ff699687e30aa2020373a16533`,
build script `67f20c55f13cc41cc3f16f7c84d64ab750eff06946b7043f032f948f5712fc25`.
Apple Swift 6.4, arm64 macOS: build script, plist lint, strict codesign
verification and independent Bundle principal-class load exited 0. No system
host, screen lock, screen output or multi-display test was run.
`make specs-check` with Hypercode executable SHA-256
`6503784100372b8fe93d0a794caf80bfbfc47da880874b2b9177267d34a26b9f`
and SpecPM 0.2.0 exited 0 with unresolved external-capability warnings.
The system-host boundary remains unexplored and unaccepted.
