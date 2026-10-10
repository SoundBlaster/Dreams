# Dreams

A local macOS prototype: Matrix digital rain on the built-in display. Vertical chains of glyphs react to what your coding agents do: every agent message floods the screen with rain, tool calls are printed in the rain as real call lines (`bash: brew install fontforge`), and the rain settles back to a calm background. It is driven by Codex / Claude Code hooks and by MCP, and it has an experimental virtual display for UI agents.

> The app window and menus are currently in Russian. Their English meanings are given in parentheses where this document refers to them.

## Build and run

Requires macOS 15+, Swift 6.2+ and Metal. Verified on an Apple M4 Pro with macOS 27.0 (26A428), Swift 6.4 and the built-in Liquid Retina XDR display.

```sh
zsh scripts/build-app.sh release
open dist/Dreams.app
```

A normal launch opens the Dreams window with the buttons «Запустить Matrix» (Start Matrix), «Радужные волны» (Rainbow Waves), «Остановить» (Stop) and «Выйти из Dreams» (Quit Dreams). Reopening the app brings this window back and stops the animation. `Esc` stops the animation while Dreams is the active app.

A `◒` item also appears in the menu bar: Start Matrix Rain, Start Rainbow Waves, Stop Animation, Create/Close Agent Workspace, Quit. The animation runs for five minutes. Launching the app never covers the screen by itself. For a separate test window on a virtual display:

```sh
dist/Dreams.app/Contents/MacOS/Dreams --lab
```

`Ctrl+Option+Command+D` is registered as a global hotkey and a menu shortcut that stops the animation. Registration is verified; a call through a synthetic CUA keyboard was not confirmed. MCP stop and auto-stop are verified separately. A physical key press still needs checking for everyday use.

## Default look

The defaults live in `DreamsPreset` (`Sources/Dreams/DreamsController.swift`) and apply until the user changes a setting: density 0%, fade width 3 glyphs, speed 0.43×, brightness spread 51%, glow 57% (0% on a transparent background), calm background 77%, word colour (0, 255, 100) at 200% brightness, restored film glyphs on. To see the default look on this Mac, erase the saved values: `defaults delete ru.egormerkushev.dreams`.

## MCP

Dreams uses the [official Swift MCP SDK](https://github.com/modelcontextprotocol/swift-sdk), version 0.12.1, for the server, tool dispatch, JSON-RPC and stdio. A small compatibility transport, taken from Screener, only edits `initialize`: it drops non-standard `experimental` capabilities with non-string values, which this SDK version cannot decode. All other messages pass through unchanged.

Codex configuration example (not installed automatically):

```toml
[mcp_servers.dreams]
command = "/Applications/Dreams.app/Contents/MacOS/Dreams"
args = ["--mcp"]
```

Any other stdio MCP client, including Claude, uses the same executable and `--mcp`. Integration with Claude itself is not verified yet.

| Tool | Action |
| --- | --- |
| `dreams_status` | Animation state, stop time, display IDs, bounds, test click count and the current settings |
| `dreams_preview` | PNG of the shader itself, without capturing the screen or other windows |
| `dreams_start` | Show the animation: `style` = `matrix` (default) or `waves`; `duration_seconds` 1–3600, default 300; `brightness` 0.02–0.35, default 0.18 |
| `dreams_stop` | Remove the animation and release the display-sleep assertion |
| `dreams_prepare_ui` | Remove the animation before screenshots or clicks on the built-in display |
| `dreams_resume` | Resume the last style, duration and brightness |
| `dreams_workspace_create` | Create a virtual display and an «Increment» test window |
| `dreams_workspace_close` | Close the test window and disconnect Dreams' own virtual display |
| `dreams_publish_keywords` | Replace this session's keywords: `session_id`, `keywords`, optional `color`, `ttl_seconds` |
| `dreams_clear_keywords` | Remove the keywords of the given `session_id` only |

`brightness` is a multiplier on the shader's linear RGB, not the system backlight. Output is SDR sRGB at a 30 fps target. `frames_rendered` counts submitted command buffers, not measured GPU completions. The visual settings are read-only through MCP (`dreams_status` reports them); they are changed in the window.

**One process controls the fullscreen overlay and the virtual display.** That is either the normal app or a single MCP client started with `--mcp`. Other sessions can run `--mcp --publisher`: they get only status, preview, publish_keywords and clear_keywords. Publishers exchange keywords through a shared local mailbox but cannot control someone else's fullscreen. On EOF the controlling MCP process removes its animation and virtual display; a publisher exiting does not remove its keywords before their TTL expires. The `waves_visible` field is kept for compatibility and covers both styles; `visual_style` shows the current style.

## Agent hooks (Codex and Claude Code)

```sh
/Applications/Dreams.app/Contents/MacOS/Dreams --install-hooks
# See what would change without writing anything:
/Applications/Dreams.app/Contents/MacOS/Dreams --install-hooks --dry-run
# Remove only the Dreams hooks and keep every other setting:
/Applications/Dreams.app/Contents/MacOS/Dreams --uninstall-hooks
```

The installer is built into the app. The binary records its own path, so run it from `/Applications`; run from `dist/`, the hooks will point at `dist/`. It adds user-level hooks to `~/.codex/hooks.json` and `~/.claude/settings.json`, keeping your existing settings, key order and other hooks, and writes a timestamped backup next to each file. Running it again is safe, and a file that is not a JSON object is left untouched. Hooks that previously pointed at a `dist/` path are replaced. Tested with `python3 scripts/test-hooks-install.py`.

Codex asks you to review new hooks in `/hooks` and to trust them in the client. Start a new session after changing the configuration. This is an integration with Claude Code, not with arbitrary Claude chat.

Events: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, SessionEnd. Each hook runs a short-lived `Dreams --hook codex|claude` without opening any window; the main Dreams app has to be running for anything to appear on screen. `UserPromptSubmit` publishes the label `TASK`, and `PreToolUse` publishes a tool call line: the tool name and its main argument, up to 60 characters (`bash: brew install …`, `read: <path>`). Values that look like secrets are replaced with `***`, but redaction is pattern-based and not a guarantee. Lines are stored locally in the mailbox (permissions 0600) and are visible on screen. Prompt text, tool output and transcripts are not stored. This is an action indicator, **not a stream of inference tokens or hidden reasoning**.

A hook always prints nothing and exits 0, including on errors or a busy mailbox, so it never changes an agent's decisions. Explicit MCP and `--publish` calls do report errors. Example configurations are in `integrations/`.

On the maintainer's Mac the hooks were confirmed on 9 October 2026, 22:52 MSK: fresh automatic events from four Codex sessions appeared in the shared mailbox. Automatic delivery from Claude Code has not been confirmed yet; the next check is to see events from a real Claude Code session in the shared keyword feed.

### Rain and agent activity

Matrix answers agent messages with a surge. Any new message in the mailbox (turn start, tool call, its result, turn end, keywords) floods the whole screen with rain at full brightness within 0.4 s, holds the flood for 1.5 s, then decays exponentially (time constant 5 s, about 15 s to rest) to the calm background set by the idle slider. A message during the decay raises the rain again from its current level, so frequent tool calls keep it dense and a pause lets it settle. The parameters are `RainActivity.attack/hold/decay`. Fading of already printed glyphs is irreversible: more activity does not restore old brightness. Columns that became fully hidden are cleared and are printed again from the top when they return. Rainbow Waves works independently of agent events.

`UserPromptSubmit`, `PreToolUse` and `PostToolUse` mark a session as `working`; `Stop` and `SessionStart` mark it `idle`; `SessionEnd` removes it from the feed. MCP/CLI publish accepts `activity: "working" | "idle"` (default `working`). The `working_agents` field of `dreams_status` shows the count; the window shows it or «Ожидание агентов» (Waiting for agents).

This is an estimate from hooks, not a measurement of inference. If a Stop is missed, the session disappears after its TTL (normally 90 seconds without events); after the TTL a long computation without new hooks stops counting as active too. An idle session can stay in the mailbox with its keywords but adds no rain.

Work intensity is estimated from the observed hook events, not from inference tokens. For `dreams_status`, a working session gives a base level of 50%, each extra agent 18%, recent actions up to 32% (the rain on screen follows the message surges described above, not this level). PreToolUse adds 1 unit, PostToolUse 0.35, UserPromptSubmit 0.5; accumulation is capped at 12 and fades exponentially with a 20 s time constant. Stop resets a session's accumulation; publishing keywords does not raise it. The status exposes `activity_level` and `action_pressure` (0–1), and the window shows the activity percentage. Recent actions increase column density and mutation rate up to 3×; the chosen fall speed does not change. At maximum density the grid is already full, so the boost shows mainly as more glyph churning.

Check the smooth transitions:

```sh
swiftc -swift-version 6 Sources/Dreams/RainActivity.swift scripts/test-activity.swift -o /tmp/dreams-activity-checks
/tmp/dreams-activity-checks
```

A separate 16-second render demo with synthetic states 3 → 1 → 0 → 2 agents:

```sh
dist/Dreams.app/Contents/MacOS/Dreams --render-demo artifacts/activity-frames --activity-demo
```

This mode does not publish test events into the shared feed.

### Tool call lines

Hook events start separate one-shot streams: PreToolUse → a call line with its arguments (`bash: brew install fontforge`, `read: Sources/Dreams/MatrixRain.swift`, `grep: func glyph\(`, `mcp: xcode.BuildProject Dreams`), UserPromptSubmit → TASK, PreCompact → CONTEXT if that hook is wired separately (the regular installer does not add it yet). `ToolCallLine` builds the line from `tool_name` and `tool_input`: paths are shown relative to `cwd`, a `cd <cwd> &&` prefix is dropped, and a long line is cut to 60 characters with an ellipsis (a path is cut from the start and keeps its end, a command is cut from the end and keeps its start). Values that look like secrets (`TOKEN=…`, `--password …`, `Authorization: Bearer …`, `user:pass@`, long opaque strings) are replaced with `***`, because everyone who can see the screen sees the rain. The labels are vertical, set in DreamsMatrix, with the word colour and brightness settings. Otherwise a stream behaves like ordinary rain: the same speed, tail and brightness spread, and its letters are churned through random rain glyphs (in the word colour) and return to their own character. PostToolUse does not duplicate a stream. The mailbox keeps at most 24 events per session; the renderer accepts at most 6 new events per update and does not replay events older than 8 seconds. An event stream still finishes printing and fades even at idle 0%.

The «Тест струй · DEMO» (Stream test · DEMO) item is in the debug menu (right-click in the control window, or «◒ → Отладка» (Debug) in the menu bar). It starts Matrix if needed and creates four visual fixtures: `bash: brew install fontforge`, `mcp: xcode.BuildProject Dreams`, TASK, CONTEXT. The demo loops and plays an agent turn: the fixtures' message causes the same surge as a real one, the lines are printed, the rain decays to the background, and 2 s after it has calmed the next «turn» starts (about 19 s per loop; longer at a slow rain speed). The loop runs until the rain is stopped by Esc, the timeout, or another style. The CLI flag `--fixture-events` still sends a single wave. The `dreams:visual-fixtures` session is idle, does not raise the working-agent count and expires after 15 s. No external tools are called. The item can be repeated. For an already running Matrix the same can be triggered from the CLI:

```sh
dist/Dreams.app/Contents/MacOS/Dreams --fixture-events
```

## Matrix rain and keywords

Matrix stores the state of every cell: glyph, print time, brightness and tint. An independent cursor in each column prints top to bottom. Only the new cell is highlighted in a light colour; glyphs already printed stay where they are. Every 0.12–0.62 seconds one old glyph in each column is replaced independently, roughly five times as often as in the first version. Only 20% of replacements produce a short white glint lasting 0.28 seconds; the rest keep their green. A whole column never changes at once. After a few seconds the glyphs fade, then the column starts a new pass. The moving noise mask over a static grid is no longer used.

The opening of the reference clip `1.mov` was analysed: the first 3 seconds in 0.25 s steps (`artifacts/reference-opening-contact.png`) and a close-up of the first 1.2 seconds in 0.1 s steps (`artifacts/reference-column-steps.png`). It shows glyphs being printed progressively from the bottom while the upper glyphs stay still. (These reference frames are not part of the repository.)

The palette is green, as in the reference video. Light heads and single replaced glyphs turn white. A faint diffuse green glow surrounds all visible glyphs and is brighter around white flashes. The near and wide blurs (σ 2.8 and 6.5 atlas pixels) are computed once per glyph and blended into a padded atlas; additive blending adds the neighbours' light. In the shader the halo gets smooth, uneven cloud noise with a slow drift and fades softly near the tile edges, without a fullscreen blur. Inside the strokes a phosphor grain works: a procedural 14×14 grid, faint scanlines and a smoothly changing noise modulation at 8 Hz. That is three integer hashes per visible fragment, no extra textures or draw calls; the alpha of the outline itself is not noised, and the halo is modulated separately by smooth noise. The dense grid has 72 rows. Glyph quads overlap the empty margins of the atlas: visible strokes take about 85% of the cell width and 90–95% of its height, so spacing shrinks while letters stay large. The cursor sometimes leaves gaps of 1–3 empty cells and keeps printing below them. Each glyph's brightness is chosen when it is printed. Keywords appear inside the flow, printed by the same cursor, **one upright letter at a time, top to bottom**. Up to three words are shown, the selection refreshes every 16 seconds, and the new selection shows on the cursor's next pass. Rainbow Waves remains a separate mode without text.

Each session publishes 1–6 words of up to 32 characters; up to 24 sessions are stored at once. TTL is 15–300 seconds, default 90. Publishing again replaces only that session. The session colour is stored in the feed for compatibility; the current classic Matrix uses a single green-and-white palette. Mailbox: `~/Library/Application Support/Dreams/Keywords`, directory permissions 0700 / files 0600, atomic writes and a nonblocking lock. `DREAMS_FEED_DIRECTORY` redirects it for isolated tests.

Example MCP arguments:

```json
{"session_id":"codex-project-a","keywords":["Swift","context","check"],"color":"cyan","ttl_seconds":90}
```

Or without MCP, JSON on stdin:

```sh
printf '%s' '{"session_id":"demo","keywords":["Swift","search"]}' | dist/Dreams.app/Contents/MacOS/Dreams --publish
```

`dreams_preview` returns an offscreen render, not a screenshot of the display. While an animation is running it uses the animation's current time; when stopped it renders a staged frame at the sixth second so that keywords are visible.

Agent words in both rain sets are drawn in DreamsMatrix-Regular, in capitals only. The case conversion happens before a word is split into vertical glyphs; the original keywords in the mailbox are unchanged. Call lines are printed as they are: case and spaces are part of the command.

## Settings

All settings are applied immediately and saved between launches.

- **Rain density** (0–100%, default 0%): length of the tail and the pause between passes. The scale is non-linear: 100% fills the whole grid after the initial pass, with no random holes or pauses; all columns are active whenever agents are working. Tail length is about 26–100% of the grid height; the lifetime is tied to the printing speed. At low density a dark pause remains between passes; at high density new passes follow faster and at 100% they are continuous. A new value applies to the next streams and does not bring back glyphs that already faded. Mutations do not extend a glyph's life. Below 100%, agent activity also raises the number of columns; with no work a faint, sparse rain remains at any density setting.
- **Fade width** (1–16 glyphs, default 3): how many rows dissolve at once from the top edge of a tail. At 1 the next glyph starts to fade after the previous has gone; at 16 the edge is soft. It applies to new streams regardless of density.
- **Rain speed** (0.25×–3×, default 0.43×): changes the pace of printing, mutation and fading together while keeping the tail length in cells; the decay time of agent activity stays the same.
- **Brightness spread** (0–100%, default 51%): at 0 ordinary green glyphs all have the same brightness, at 100% the original random range is used. White flashes and tail fading remain.
- **Glow** (0–300%, default 57%, 0% when transparent): the strength of the diffuse halo; 0% turns it off and keeps the brightness of the glyphs themselves. It is stored separately for the black and the transparent background (`rainGlow` and `transparentRainGlow`, default 0), and the slider shows the value of the selected mode.
- **Calm background** (0–100%, default 77%): the background that the rain decays to after a surge. 0% is a black screen between messages. The background stays muted; a surge always runs at full strength. Without any active agents only sparse columns at 35% of normal exposure remain; with work the rain brightens smoothly over 1.8 s and returns to idle in 4 s. Even at density 100% idle stays sparse.
- **Rain colour**: stored separately for the black background (`rainColor`, default the classic dark green) and the transparent one (`transparentRainColor`, default a light mint so the letters read on bright wallpapers). The swatch shows the colour as it appears on screen; the halo follows the colour. `rain_color_rgb` (linear RGB) is reported in the status.
- **Agent words**: colour and brightness are set separately from the rain. Default colour bright green (0, 255, 100); brightness 0–200%, default 200%; 0% hides the words. The colour applies to the letters and their glow; short light heads are kept.
- **Restored glyphs** («Восстановленные глифы из фильма»): switches on the experimental `DreamsMatrix-Regular`, built from a reconstruction sheet and manual SVG corrections. The choice is saved and changing the set starts a new rain pass. When it is off, the previous `Matrix-Code` is used; in both modes the keywords keep a system font that covers Cyrillic. `scripts/build-app.sh release` rebuilds and checks the font before packaging. The set currently has 28 forms; the new G21–G28 are the digits 8/4 and short signs from the film references. The app reads the whole private-use repertoire from the font file, so new glyphs are picked up by the next build automatically. Instructions for editing glyphs: [PIPELINE.md](research/glyphs/PIPELINE.md).
- **Transparent background** («Прозрачный фон — дождь поверх окон»): a checkbox in the window. It is saved (`transparentBackground`); when toggled during rain the overlay is recreated with the remaining time. The `--transparent` process flag still enables the mode at launch, including for MCP:

  ```sh
  open -n ./dist/Dreams.app --args --transparent
  ```

  The transparent mode shows glyphs and glow over the desktop and clicks pass through the window. Rainbow waves keep an opaque background. `transparent_background` in the status shows the selected mode. Working windows under the transparent Matrix stay visible, including in UI-agent screenshots. In this mode glow is off by default to avoid a haze over working windows.

Part of the glyph replacements run as a short churn: 4–8 different glyphs in a row on one position, 35–65 ms apart at 1× speed, then the chosen glyph settles without a white flash. The other replacements are single. After settling, a cell is not picked again for at least 0.8 seconds of simulation time. The churn keeps the brightness and the original print time, and stops when fading starts, the column is hidden, or the cell is overwritten by a new pass.

The window also shows the animation state next to the agent activity: stopped, or the number of rendered frames and the time left. A normal launch is limited to five minutes. The settings window scrolls so that every control stays reachable.

## UI agents and the built-in display

If an agent captures the whole built-in desktop, it will see the waves. Call `dreams_prepare_ui` before such actions and `dreams_resume` after. The fullscreen window does not intercept clicks: it is not a way to block input. There are no waves during UI work on the built-in display.

Simultaneous work is possible when a UI tool captures a window on the virtual display separately and sends input there correctly. Creating a second display does not reconfigure Codex or Claude. Windows of other apps are not moved automatically. Focus, clipboard and keyboard input still belong to the shared user session.

In one experiment Codex CUA took a screenshot of the Dreams window on the virtual display and changed `Clicks: 0` to `Clicks: 1` with a coordinate click while MCP reported `waves_visible: true` on the built-in display. That confirms this specific path, CUA → test window. Work with a browser, arbitrary desktop capture and Claude is not confirmed yet.

The virtual display is created with the **private macOS API** `CGVirtualDisplay`, following Chromium's example. It is an experimental local feature and compatibility with macOS updates is not guaranteed. Such code is not suitable for the App Store, which requires public APIs. Other windows that were manually placed on this display may move to a physical screen when it is disconnected.

## Display and system indicators

Dreams removes the static image but does not promise to prevent burn-in or image retention. The built-in Liquid Retina XDR display of this Mac is an LCD with a mini-LED backlight. Cycling through all colours is not a proven protection. At 60 Hz at most 3600 distinct values can be shown to one pixel in a minute, and 8-bit-per-channel RGB has 16,777,216 colours; the remaining 8 bits in a typical 32-bit pixel format are alpha.

The app does not capture the screen, use the camera or microphone, or draw a frame or a pulsing dot. A UI tool capturing a window may bring system privacy indicators on top of the image. By the user's description the exact source of one such frame has not been established; Dreams does not hide such indicators.

While the animation is active the app holds a display-sleep assertion and releases it after it stops. This keeps the animation visible at the cost of power. It does not change the system brightness, lock settings or persistent sleep settings.

## Release

`scripts/release.sh` builds a universal (arm64 + x86_64) `Dreams.app`, signs it with Developer ID (`P8T2366K8X`) and the hardened runtime, notarizes and staples it, then makes `dist/release/Dreams-<version>.dmg`, notarizes and staples that too, and prints the sha256 for a Homebrew cask. The version comes from `VERSION` and the `Info.plist` template is `scripts/Info.plist.in`; the font comes from the committed `Sources/Dreams/DreamsMatrix.ttf`, so a release does not need Python. Once: `xcrun notarytool store-credentials dreams-notary`. `scripts/release.sh --skip-notarize` signs and verifies without submitting to Apple (such a DMG is only good for local checks). A signed executable is bound to its bundle: it cannot be copied out of `Dreams.app`.

## Testing

```sh
python3 scripts/smoke.py
# For manual / CUA checks of the working window:
python3 scripts/smoke.py --interactive
```

The printing model (no GUI):

```sh
swiftc -swift-version 6 Sources/Dreams/MatrixSimulation.swift scripts/test-matrix.swift -o /tmp/dreams-matrix-checks
/tmp/dreams-matrix-checks
```

It checks sequential writing, that old glyphs stay still, a single replacement, an identical result at different frame rates, and no changes when the same time is rendered again. Five cycles of flowing rain are checked separately: the tail clears the top of the screen before the head leaves, disappears completely, leaves a dark gap and starts a new pass from a single top cell.

To record 180 real Metal frames (6 seconds at 30 fps) without fullscreen:

```sh
dist/Dreams.app/Contents/MacOS/Dreams --render-demo artifacts/typing-frames
ffmpeg -framerate 30 -i artifacts/typing-frames/%04d.png -c:v libx264 -pix_fmt yuv420p artifacts/matrix-typing.mp4
```

The smoke test starts the real executable over stdio, performs a Codex-shaped initialize, and checks the ten tools, the four publisher tools, a publisher being refused fullscreen control, the shared keyword feed between two processes, hook mapping, TTL, invalid parameters, the PNG preview and frame changes over time, creation and placement of a window on the virtual display, start/prepare/resume, the timer, assertion release and cleanup on EOF. The preview is saved as `artifacts/matrix-preview.png`; two frames of the running animation as `artifacts/matrix-live-0.png` and `artifacts/matrix-live-1.png`. This is a protocol integration test; it does not replace checking server discovery with a real MCP client.

The release build and the smoke test passed on the Mac named above. During an earlier manual run the frame counter grew by about 30 per second. A long thermal/GPU benchmark was not run.

## Sources and licenses

- [Rezmason/matrix: the visual principle of illumination waves](https://github.com/Rezmason/matrix)
- [cassmtnr: Matrix-Code font and glyph repertoire, MIT](https://github.com/cassmtnr/matrix-macos-screensaver)
- [OscarL/MatrixSS: visual reference](https://github.com/OscarL/MatrixSS)
- [Codex hooks](https://learn.chatgpt.com/docs/hooks)
- [Claude Code hooks](https://code.claude.com/docs/en/hooks)
- [Apple: MTKView](https://developer.apple.com/documentation/metalkit/mtkview)
- [Apple: ScreenCaptureKit sample, display/window capture](https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-in-macos)
- [Chromium: virtual display implementation](https://chromium.googlesource.com/chromium/src/+/HEAD/ui/display/mac/test/virtual_display_util_mac.mm)
- [Apple: App Review Guidelines, 2.5.1](https://developer.apple.com/app-store/review/guidelines/#software-requirements)
- [Apple: screen observation privacy reminder](https://support.apple.com/en-lamr/120315)
- [Codex: MCP configuration](https://developers.openai.com/codex/mcp/)

The licenses of the adapted Screener code (MIT), Chromium (BSD), Matrix Digital Rain (MIT, font and repertoire) and the Swift dependencies are kept in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and included in the app bundle. Dreams itself is MIT-licensed, see [LICENSE](LICENSE).
