.DEFAULT_GOAL := help

VERSION := $(shell cat VERSION)
APP := dist/Dreams.app
DMG := dist/release/Dreams-$(VERSION).dmg
PYTHON := .venv/bin/python
NOTARY_PROFILE ?= dreams-notary

.PHONY: help app run test test-unit glyphs glyphs-verify glyphs-selftest \
	release release-local checksum github-release notary-profile \
	install-hooks uninstall-hooks uninstall uninstall-purge clean

help:
	@printf '%s\n' \
		'Dreams $(VERSION)' \
		'' \
		'Develop:' \
		'  make app              Build dist/Dreams.app (rebuilds the glyph font, ad-hoc signed)' \
		'  make run              Quit a running Dreams, rebuild and open the app' \
		'  make test-unit        Tests that need no app bundle (activity model, typing model)' \
		'  make test             Everything: unit tests, localization, hooks installer, MCP smoke' \
		'  make glyphs           Rebuild the font from research/glyphs (strict checks)' \
		'  make glyphs-verify    Check that a rebuild is byte-identical' \
		'  make glyphs-selftest  Check that every glyph check catches its own defect' \
		'' \
		'Release (version from VERSION):' \
		'  make notary-profile KEY=<AuthKey.p8> KEY_ID=<id> ISSUER=<uuid>   One-time notarytool setup' \
		'  make release          Universal build, Developer ID signature, notarized and stapled DMG' \
		'  make release-local    The same without notarization (local checks only)' \
		'  make checksum         sha256 of the DMG, for the Homebrew cask' \
		'  make github-release   Tag v$(VERSION) and publish the DMG on GitHub (asks first)' \
		'' \
		'Agents:' \
		'  make install-hooks    Add the Dreams hooks to Codex and Claude Code (uses /Applications)' \
		'  make uninstall-hooks  Remove them' \
		'  make uninstall        Quit Dreams, remove its hooks and the app' \
		'  make uninstall-purge  The same, plus settings, mailbox, caches and hook backups' \
		'' \
		'  make clean            Remove .build and dist'

app:
	zsh scripts/build-app.sh release

run: app
	-pkill -x Dreams
	@sleep 1
	open $(APP)

test-unit:
	swiftc -swift-version 6 Sources/Dreams/RainActivity.swift scripts/test-activity.swift -o .build/activity-checks
	.build/activity-checks
	swiftc -swift-version 6 Sources/Dreams/MatrixSimulation.swift scripts/test-matrix.swift -o .build/matrix-checks
	.build/matrix-checks

test: app test-unit
	python3 scripts/test-localization.py
	python3 scripts/test-hooks-install.py $(APP)/Contents/MacOS/Dreams
	python3 scripts/test-uninstall.py
	python3 scripts/smoke.py
	python3 scripts/test-hook-pressure.py
	$(PYTHON) scripts/test-transparent.py

glyphs:
	$(PYTHON) scripts/glyphs/pipeline.py build

glyphs-verify: glyphs
	$(PYTHON) scripts/glyphs/pipeline.py verify

glyphs-selftest:
	$(PYTHON) scripts/glyphs/selftest.py

notary-profile:
	@test -n "$(KEY)" -a -n "$(KEY_ID)" -a -n "$(ISSUER)" || { \
		echo 'Usage: make notary-profile KEY=~/path/AuthKey_XXXX.p8 KEY_ID=XXXX ISSUER=<issuer uuid>'; exit 1; }
	xcrun notarytool store-credentials $(NOTARY_PROFILE) --key "$(KEY)" --key-id "$(KEY_ID)" --issuer "$(ISSUER)"

release:
	DREAMS_NOTARY_PROFILE=$(NOTARY_PROFILE) scripts/release.sh

release-local:
	scripts/release.sh --skip-notarize

checksum:
	@test -f $(DMG) || { echo '$(DMG) not found: run make release first'; exit 1; }
	@shasum -a 256 $(DMG)

# Publishing is outward-facing: the DMG must be notarized and the tree clean and pushed.
github-release:
	@test -f $(DMG) || { echo '$(DMG) not found: run make release first'; exit 1; }
	@xcrun stapler validate $(DMG) > /dev/null || { echo '$(DMG) is not notarized and stapled'; exit 1; }
	@test -z "$$(git status --porcelain)" || { echo 'Working tree is not clean: commit first'; exit 1; }
	@git fetch -q origin && test "$$(git rev-parse HEAD)" = "$$(git rev-parse origin/main)" || { echo 'HEAD is not pushed to origin/main'; exit 1; }
	@printf 'Publish v$(VERSION) with %s to GitHub? [y/N] ' '$(DMG)'; read answer; test "$$answer" = y
	gh release create v$(VERSION) $(DMG) --title "Dreams $(VERSION)" --generate-notes
	@shasum -a 256 $(DMG)

install-hooks:
	@test -x /Applications/Dreams.app/Contents/MacOS/Dreams || { echo 'Install Dreams into /Applications first'; exit 1; }
	/Applications/Dreams.app/Contents/MacOS/Dreams --install-hooks

uninstall-hooks:
	@test -x /Applications/Dreams.app/Contents/MacOS/Dreams || { echo 'Dreams is not in /Applications'; exit 1; }
	/Applications/Dreams.app/Contents/MacOS/Dreams --uninstall-hooks

uninstall:
	scripts/uninstall.sh

uninstall-purge:
	scripts/uninstall.sh --purge

clean:
	rm -rf .build dist
