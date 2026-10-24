# macOS ↔ tvOS parity

| Capability | macOS | tvOS after this change |
|---|---|---|
| Grid | Automatic or24–240 columns | Same grid law/range; keep existing TV manual96 default |
| Density | 0–100% | Same simulation; keep TV82% default and dim occupied tail at100% |
| Speed/fade | 0.25–3× /1–16 glyphs | Same ranges and step precision |
| Deceleration | Optional, -120–0 glyph/s², positive terminal-speed floor | Same shared motion implementation |
| Search | Minimum simultaneous fraction of live cells, 0–100% | Same shared occupancy scheduler; head cycle independent |
| Pulse | Independent real-time gain, 0–100% | Same GlyphPulse helper; applied before head highlight |
| Color/spread/glow | sRGB color, 0–100% spread, 0–300% glow | Same units and linear-light conversion; remote RGB channels |
| Glyph sets | Restored PUA font / classic Matrix-Code | Same fonts/repertoires; retain TV mirrored variants |
| Settings | Native/legacy desktop controls; shared persistent state | Native TV list/toggles/adjustment buttons, immediate preview, reset confirmation |
| Playback | Start/stop overlays and preview pause | Rain foreground; Play/Pause opens/closes the menu; preview switch controls pause |
| Clock | Not part of desktop rain | Preserve optional HH:mm mask, three fonts, size and bounded drift |
| Brightness | Renderer exposure controlled by activity | Preserve TV2–35% exposure without agent activity |
| Agent words/activity, hooks, MCP | Desktop integration | Deliberately excluded |
| Transparent desktop, capture hiding, displays, global hotkey, overlay duration | Desktop window/session functions | Deliberately excluded; no desktop windows on Apple TV |

TV-specific defaults and clock treatment are compatibility choices, not an assertion
of pixel-identical output across different display sizes or color pipelines. Existing
TV preference values are preserved, even when a macOS default differs.
