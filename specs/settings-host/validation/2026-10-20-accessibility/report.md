# VoiceOver / tooltip bounded CUA capability audit

Skills applied: device-interaction and ios-accessibility. Fresh isolated normal release app `/Volumes/TB5/Developer/Builds/GitHub/Dreams-36273a9c832f69b9/voiceover-app/Dreams VoiceOver QA.app`, bundle `ru.egormerkushev.dreams.voiceover-qa`, PID86330 at launch. Parent verified preserved runtime source matches current main; no build/source/harness changes by QA. No production settings, hooks, reset or overlays.

## Initial and restored state
- Initial VoiceOver OFF verified by actual System Settings VoiceOver switch (AX_VOICEOVER_ENABLED). Initial process search had no VoiceOver process; later broad pgrep matches own app name and is not proof of VoiceOver running.
- CmdF5 did not visibly enable VO; system UI switch was used instead, observed OFF→ON.
- Returned to isolated Rain, sent one ControlOptionRight navigation and ControlOptionCommandF10 caption attempt. No caption text or speech output was available through CUA. No assertable VO focus progression, control announcement or adjustment evidence obtained. Screenshot/AX is not claimed as VoiceOver behavior proof.
- Restored system VoiceOver switch OFF, verified by screenshot and AX file `voiceover-restored-off.*`. No user theme/transparency/motion settings changed.

## Tool boundaries
- Documented CUA API has getAXState/getScreenshot, click/drag/scroll/setValue and key synthesis; no rawattribute API, pointermove/hover, audio capture or VoiceOver speech viewer access.
- CUA human-readable control prefix currently displays help-like prose for Rain sliders while descriptions, IDs and settablefloat values remain. This representation alone does not prove loss of underlying AXSlider role. Raw AXRole/AXHelp investigation belongs to parent separate read-only probe.
- Actual tooltip popup, VO announcements and one-step Speed/Fade/Glow operation remain unverified; no slider edits attempted without reliable VO focus.

## Artifacts
- navigation-attempt.png and navigation-attempt-ax.txt show Rain after one VO/caption attempt; not speech proof.
- voiceover-restored-off.png and voiceover-restored-off-ax.txt confirm cleanup.

Timing limitation: model/tool round-trips often consumed40–60sec despite subsecond tool runtimes; parent AppKitprobe also reserved UI for several minutes. No repeated undocumented retries. UI released to parent for raw probe/hover.

## Final bounded Utility attempt
- VoiceOver Utility opened successfully through System Settings. Visuals→Panels and Menus: Show caption panel was alreadyON (caption-initial-ax.txt); no caption preference changed.
- Enabled system VO switch once. Attempt to bind actual VoiceOver app failed: NSCocoaError256 / NSOSStatus -600 procNotFound, no eligible process at /System/Library/CoreServices/VoiceOver.app/. This is a host/tool blocker, not an application accessibility failure.
- Immediately restored VO system switchOFF; final-attempt-restored-off-ax.txt confirms. Caption setting retained observedON. No further UI retries or productsetting adjustments.
- Actual speech/caption task remains unverified. RawAX and one-step adjustment observations obtained separately by parent must be reported at their own evidence level.
