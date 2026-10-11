# Dreams architecture

Dreams uses Feature-Sliced Design inside its existing SwiftPM executable. AppKit
and Metal remain the UI and rendering technologies. The FSD source root is
`Sources/Dreams`; the Objective-C virtual display bridge is a separate target.

| Boundary | Responsibility |
| --- | --- |
| `app/entrypoint` | Process entry, CLI dispatch and render-demo startup |
| `app/providers` | App lifecycle, menu bar composition and MCP integration |
| `app/styles` | App status icon |
| `pages/settings/ui` | Settings window composition, controls, UI actions and refresh |
| `features/rain` | Settings, simulation, rendering, overlay lifecycle and stop shortcut registration |
| `features/connect-agents` | Installing/removing hooks and detecting agent plugins |
| `entities/agent-activity` | Session messages, event labels, mailbox and hook payload ingestion |
| `shared/lib` | Localization lookup, errors and shortcut values/storage |
| `shared/assets` | Localized string tables |

The shader and fonts retain their existing root resource paths. They are not
Swift declarations and do not introduce layer dependencies.

## Dependency contract

Dependencies go downward: `app → pages → features → entities → shared`.
Widgets can be introduced between pages and features when a reusable composition
appears. There are currently no widget slices.

Slices in `features` and `entities` must not depend on their siblings. Both the
rain feature and settings page can read the agent activity entity. Hook
installation does not know about the settings page or rain rendering.

`DreamsDelegate` owns the controller and composes the settings page. The page
receives that controller through its initializer; it does not refer back to the
application delegate or MCP server. Its `onHotkeyChange` callback lets app
composition refresh the menu shortcut without an upward symbol dependency.
Window construction and form layout are extensions of the page controller,
separate from its action handling. Controls retain their accessibility IDs,
stored setting keys, ranges, localization and target/action behavior.

This is one Swift module: FSD's symbol graph is a static architecture gate,
not a compiler-enforced module access boundary. Internal page implementation is
shared by its extensions. Adding SwiftPM modules is a separate decision.

## Running the gate

```bash
make lint-architecture
make lint
python3 scripts/test-architecture.py
make test-settings
```

The first command checks out MIT-licensed
[SoundBlaster/FSD](https://github.com/SoundBlaster/FSD) into the ignored
`.fsd-ios-tooling` directory. `.fsd-version` pins the exact tooling commit;
`.fsd-ios.yml` enables all structure and dependency rules in strict mode.
Local checks and GitHub Actions run the same wrapper. For an existing clean
checkout at that exact commit:

```bash
DREAMS_FSD_TOOLING_DIR=~/Development/GitHub/FSD_iOS/FSDDemoApp make lint-architecture
```

The architecture regression checks use temporary source trees to prove that
valid downward dependencies pass and upward/sibling-slice dependencies fail.
`make test-settings` instantiates the AppKit settings page with an isolated
agent mailbox, checks control identities, values and timer cleanup, and does
not change saved settings. It requires a macOS WindowServer session.
