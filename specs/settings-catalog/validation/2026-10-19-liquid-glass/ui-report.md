# Actual native glass panels QA

Fresh supplied runtime in isolated ru.egormerkushev.dreams.glass-panels-qa app, EN, blue profile,100% density. Dark screenshot actual normalSDK27 launch; Light screenshot actual diagnostic Aqua override NSRequiresAquaSystemAppearance=true+re-sign, not exact normal follow-system claim. No system theme or production preferences changed.

PASS visual: large outer panel clearly transmits blurred blue columns and bright glyph heads, with thin bright refractive edge at rounded corners/sides. Preview header/footer show matching translucent glass. Compared with prior regularMaterial screenshots this is visibly more transparent/refraction-rich, not overly opaque under the seeded100%density. Native grouped Form row fills remain legible over glass.

Both themes have readable labels/readouts and blue native slider/toggle/sidebar tint. Muted helpers are lower contrast over moving rain but readable in captures. Known full-width toolbar blur band continues covering top Rain/preview headings; deferred, not fixed. No new clipping below that known region.

Artifacts: /tmp/dreams-glass-panels-qa/dark.png, light.png, dark-ax.txt, light-ax.txt. No overlays or unrelated UI changes. App left Rain in diagnostic Light. macOS15 fallback and accessibility toggles not re-tested in this bounded pass.
