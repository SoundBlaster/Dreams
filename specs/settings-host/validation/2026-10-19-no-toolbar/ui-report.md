# Actual no-toolbar QA

Fresh final V3 supplied release binary and Dreams_Dreams.bundle copied to isolated ru.egormerkushev.dreams.no-toolbar-qa. Pre-sign binary SHA comparison matched root product exactly. EN Dark green rain60%, no Aqua override or global changes.

PASS V3: auto native sidebar toolbar item removed; no toolbar AX node or duplicate big glass button. Single custom Toggle sidebar button localized correctly. Rain heading/description and Live Preview fully visible; old full-width blur band gone. Labels/readouts readable. Native close/minimize/fullscreen buttons remain in AX; top-left screenshot is covered by standard purple CUA privacy indicator, so traffic lights not visually proven.

PASS: custom button hides sidebar; Ctrl+Cmd+S restores sidebar with Rain selection. Saved v3-recovered-ax.txt. No preferences or overlays changed. V1/V2 duplicate item finding resolved by V3 sidebar-owner removal. Initial raw localization key resolved by fresh resource copy.

LIMITS: exact560x450, minimum resize recovery and header window drag unverified; stopped further experiments as parent requested. Native traffic button actions not activated.

Artifacts: /tmp/dreams-no-toolbar-qa/v3-wide.png, v3-wide-ax.txt, v3-recovered-ax.txt. Historical initial wide.png/sidebar-hidden.png and V2 evidence remain separate. App left open Rain/sidebar visible, exec22824.
