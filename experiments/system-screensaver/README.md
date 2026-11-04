# System screen saver experiment

An isolated macOS `.saver` lifecycle probe using the public ScreenSaver framework.
It compiles the production Metal renderer and its font and shader resources into
the module. It currently uses renderer defaults, not saved Dreams settings.
The renderer attempts to observe the agent feed; access and behavior within the
system host are not yet verified.
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

Next: test rendering and feed access in the system host, then extract a shared
rendering boundary before claiming parity with the application.

## Local baseline — 2026-11-04

This baseline describes the earlier AppKit-only probe, not the Metal revision.

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

## Metal host baseline — 2026-11-05

Build on Apple Silicon with Swift 6.4 in Swift 5 language mode succeeded, with
main-actor isolation warnings in the shared renderer. A separate local process
loaded the bundle, initialized its screen saver view and Metal renderer, and
observed the MTKView unpause on start and pause on stop. This does not establish
that a drawable was presented, nor does it test the macOS screen saver host.
Swift source SHA-256: `3d19b8599255746bd879242b5fe64c8167beef1160ade19f6baf2f48f0f6d76d`;
build script: `a5d5ebec454738f8f157b4edede2a4ae818aad6fdc6f78534885685b625e13be`;
RainRenderer: `20246272d0693172cc0e85d478d62ec1988daf7bdc018acdeb2284cc612a8bab`;
MatrixRain: `c4805c20fbccdea088293b50bb133815059fd299cfd25d529f9951e6dc8a8e0c`.
