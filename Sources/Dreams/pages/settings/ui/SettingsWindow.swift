import AppKit

extension SettingsPageController {
    @objc func showControls() {
        if nativeSettingsEnabled { showNativeControls() }
        else { showLegacyControls() }
    }

    @objc func showLegacyControls() {
        if controlsWindow == nil {
            let window = DreamsControlsWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 600),
                styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "Dreams"
            window.appearance = NSAppearance(named: .darkAqua)
            window.isReleasedWhenClosed = false
            window.onEscape = { [weak self] in self?.controller.handleEscape() }

            // Header: status and the main actions.
            let activityLabel = NSTextField(wrappingLabelWithString: "")
            activityLabel.textColor = .secondaryLabelColor
            activityLabel.preferredMaxLayoutWidth = 420
            self.activityLabel = activityLabel
            let matrix = NSButton(title: L("button.startMatrix"), target: self, action: #selector(start))
            matrix.setAccessibilityIdentifier("dreams.start-matrix")
            matrix.keyEquivalent = "\r"
            let stopButton = NSButton(title: L("button.stop"), target: self, action: #selector(stop))
            stopButton.setAccessibilityIdentifier("dreams.stop")
            let runTime = NSPopUpButton(frame: .zero, pullsDown: false)
            for seconds in DreamsPreset.runTimeChoices {
                runTime.addItem(withTitle: Self.runTimeTitle(seconds))
                runTime.lastItem?.representedObject = seconds
            }
            runTime.selectItem(at: DreamsPreset.runTimeChoices.firstIndex(of: controller.runTimeSeconds) ?? 2)
            runTime.target = self
            runTime.action = #selector(changeRunTime(_:))
            runTime.toolTip = L("runtime.tip")
            runTime.setAccessibilityLabel(L("runtime.accessibility"))
            runTime.setAccessibilityIdentifier("dreams.run-time")
            controlsByID["dreams.run-time"] = runTime
            let launch = NSStackView(views: [matrix, stopButton, runTime])
            launch.spacing = 8
            let escapeHint = Self.note("")
            runTimeHint = escapeHint

            // The global stop shortcut: click, press a combination.
            let hotkeyName = Self.name(L("hotkey.label"))
            let hotkeyButton = NSButton(title: controller.stopHotkey.display, target: self, action: #selector(recordHotkey(_:)))
            hotkeyButton.toolTip = L("hotkey.tip")
            hotkeyButton.setAccessibilityLabel(L("hotkey.label"))
            hotkeyButton.setAccessibilityIdentifier("dreams.stop-hotkey")
            hotkeyButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 96).isActive = true
            self.hotkeyButton = hotkeyButton
            let hotkeyDefault = NSButton(title: L("hotkey.reset"), target: self, action: #selector(resetHotkey))
            hotkeyDefault.bezelStyle = .inline
            hotkeyDefault.setAccessibilityIdentifier("dreams.stop-hotkey-default")
            let hotkeyNote = Self.note("")
            self.hotkeyNote = hotkeyNote
            let hotkeyRow = NSStackView(views: [hotkeyName, hotkeyButton, hotkeyDefault])
            hotkeyRow.spacing = 8
            refreshRunTimeHint()

            // Rain.
            let rainColor = NSColorWell()
            rainColor.color = controller.rainColor
            rainColor.target = self
            rainColor.action = #selector(changeRainColor(_:))
            rainColor.setAccessibilityLabel(L("rain.color.accessibility"))
            rainColor.setAccessibilityIdentifier("dreams.rain-color")
            rainColor.toolTip = L("rain.color.tip")
            rainColorWell = rainColor
            controlsByID["dreams.rain-color"] = rainColor
            let automaticColumns = NSButton(checkboxWithTitle: L("rain.columns.auto"), target: self,
                                            action: #selector(changeAutomaticColumns(_:)))
            automaticColumns.state = controller.rainColumnCount == 0 ? .on : .off
            automaticColumns.setAccessibilityIdentifier("dreams.rain-columns-auto")
            controlsByID["dreams.rain-columns-auto"] = automaticColumns
            let deceleration = NSButton(checkboxWithTitle: L("rain.deceleration.enabled"), target: self,
                                         action: #selector(changeDecelerationEnabled(_:)))
            deceleration.state = controller.rainDecelerationEnabled ? .on : .off
            deceleration.setAccessibilityIdentifier("dreams.rain-deceleration-enabled")
            deceleration.toolTip = L("rain.deceleration.enabled.tip")
            controlsByID["dreams.rain-deceleration-enabled"] = deceleration
            let rain = settingsGrid([
                [Self.name(L("rain.grid")), automaticColumns, NSView()],
                sliderRow(L("rain.columns"), value: Double(controller.rainColumnCount == 0
                          ? controller.automaticColumnCount : controller.rainColumnCount), min: 24, max: 240,
                          action: #selector(changeColumns(_:)), valueLabel: columnsLabel,
                          identifier: "dreams.rain-columns", tip: L("rain.columns.tip")),
                [Self.name(L("label.color")), rainColor, NSView()],
                sliderRow(L("rain.density"), value: controller.rainDensity, min: 0, max: 1,
                          action: #selector(changeDensity(_:)), valueLabel: densityLabel,
                          identifier: "dreams.rain-density",
                          tip: L("rain.density.tip")),
                sliderRow(L("rain.speed"), value: controller.rainSpeed, min: 0.25, max: 3,
                          action: #selector(changeSpeed(_:)), valueLabel: speedLabel,
                          identifier: "dreams.rain-speed", tip: L("rain.speed.tip")),
                sliderRow(L("rain.search"), value: controller.rainSearchFraction, min: 0, max: 1,
                          action: #selector(changeSearchFraction(_:)), valueLabel: searchFractionLabel,
                          identifier: "dreams.rain-search-fraction", tip: L("rain.search.tip")),
                [NSView(), deceleration, NSView()],
                sliderRow(L("rain.deceleration"), value: controller.rainDeceleration,
                          min: MatrixSimulation.Deceleration.minimumAcceleration, max: 0,
                          action: #selector(changeDeceleration(_:)), valueLabel: decelerationLabel,
                          identifier: "dreams.rain-deceleration", tip: L("rain.deceleration.tip")),
                sliderRow(L("rain.fade"), value: controller.rainFadeRows, min: 1, max: 16,
                          action: #selector(changeFade(_:)), valueLabel: fadeLabel, ticks: 16,
                          identifier: "dreams.rain-fade",
                          tip: L("rain.fade.tip")),
                sliderRow(L("rain.spread"), value: controller.rainBrightnessSpread, min: 0, max: 1,
                          action: #selector(changeBrightnessSpread(_:)), valueLabel: brightnessSpreadLabel,
                          identifier: "dreams.rain-brightness-spread",
                          tip: L("rain.spread.tip")),
                sliderRow(L("rain.pulse"), value: controller.rainPulseStrength, min: 0, max: 1,
                          action: #selector(changePulseStrength(_:)), valueLabel: pulseStrengthLabel,
                          identifier: "dreams.rain-pulse-strength", tip: L("rain.pulse.tip")),
                sliderRow(L("rain.glow"), value: controller.rainGlow, min: 0, max: 3,
                          action: #selector(changeGlow(_:)), valueLabel: glowLabel,
                          identifier: "dreams.rain-glow",
                          tip: L("rain.glow.tip")),
            ])
            glowSlider = controlsByID["dreams.rain-glow"] as? NSSlider

            // Background between agent messages.
            let background = settingsGrid([
                sliderRow(L("rain.idle"), value: controller.rainIdleIntensity, min: 0, max: 1,
                          action: #selector(changeIdle(_:)), valueLabel: idleLabel,
                          identifier: "dreams.rain-idle",
                          tip: L("rain.idle.tip")),
            ])
            let transparent = NSButton(checkboxWithTitle: L("check.transparent"),
                target: self, action: #selector(changeTransparency(_:)))
            transparent.state = controller.transparentBackground ? .on : .off
            transparent.setAccessibilityIdentifier("dreams.transparent-background")
            controlsByID["dreams.transparent-background"] = transparent

            let screenshots = NSButton(checkboxWithTitle: L("check.hideFromScreenshots"),
                target: self, action: #selector(changeHideFromScreenshots(_:)))
            screenshots.state = controller.hideFromScreenshots ? .on : .off
            screenshots.toolTip = L("check.hideFromScreenshots.tip")
            screenshots.setAccessibilityIdentifier("dreams.hide-from-screenshots")
            controlsByID["dreams.hide-from-screenshots"] = screenshots

            // Agent words and call lines.
            let wordColor = NSColorWell()
            wordColor.color = controller.keywordColor
            wordColor.target = self
            wordColor.action = #selector(changeKeywordColor(_:))
            wordColor.setAccessibilityLabel(L("words.color.accessibility"))
            wordColor.setAccessibilityIdentifier("dreams.keyword-color")
            controlsByID["dreams.keyword-color"] = wordColor
            let words = settingsGrid([
                [Self.name(L("label.color")), wordColor, NSView()],
                sliderRow(L("words.brightness"), value: controller.keywordBrightness, min: 0, max: 2,
                          action: #selector(changeKeywordBrightness(_:)), valueLabel: keywordBrightnessLabel,
                          identifier: "dreams.keyword-brightness", tip: L("words.brightness.tip")),
            ])

            // Agent hooks: connect Dreams to Codex and Claude Code.
            let hooksGrid = NSGridView(views: HooksInstaller.targets.map { source, _ in
                let name = Self.name(L("hooks." + source))
                let status = NSTextField(labelWithString: "")
                status.textColor = .secondaryLabelColor
                let button = NSButton(title: L("button.connect"), target: self, action: #selector(toggleHooks(_:)))
                button.identifier = NSUserInterfaceItemIdentifier(source)
                button.setAccessibilityIdentifier("dreams.hooks-" + source)
                hookStatusLabels[source] = status
                hookButtons[source] = button
                return [name, status, button]
            })
            hooksGrid.rowSpacing = 6
            hooksGrid.columnSpacing = 12
            hooksGrid.column(at: 0).width = 120
            hooksGrid.column(at: 1).width = 170
            hooksGrid.column(at: 2).width = 110
            hooksGrid.column(at: 2).xPlacement = .trailing
            for index in 0..<hooksGrid.numberOfRows { hooksGrid.row(at: index).yPlacement = .center }
            let hooksNote = Self.note(L("hooks.note"))

            // Glyphs and the demo.
            let restored = NSButton(checkboxWithTitle: L("check.restored"),
                target: self, action: #selector(changeGlyphSet(_:)))
            restored.state = controller.restoredGlyphs ? .on : .off
            restored.setAccessibilityIdentifier("dreams.restored-glyphs")
            controlsByID["dreams.restored-glyphs"] = restored
            let quitButton = NSButton(title: L("button.quit"), target: self, action: #selector(quit))
            let resetButton = NSButton(title: L("button.reset"), target: self, action: #selector(resetDefaults))
            resetButton.setAccessibilityIdentifier("dreams.reset-defaults")
            resetButton.toolTip = L("button.reset.tip")
            let spacer = NSView()
            spacer.setContentHuggingPriority(.init(1), for: .horizontal)
            let footer = NSStackView(views: [resetButton, spacer, quitButton])
            footer.orientation = .horizontal
            footer.widthAnchor.constraint(equalToConstant: 420).isActive = true

            let menuBarIcon = NSButton(checkboxWithTitle: L("menubar.show"), target: self, action: #selector(changeMenuBarIcon(_:)))
            menuBarIcon.state = controller.showsMenuBarIcon ? .on : .off
            menuBarIcon.toolTip = L("menubar.tip")
            menuBarIcon.setAccessibilityIdentifier("dreams.show-menu-bar-icon")
            controlsByID["dreams.show-menu-bar-icon"] = menuBarIcon
            let menuBarNote = Self.note(L("menubar.tip"))

            let stack = NSStackView(views: [
                activityLabel, launch, escapeHint, hotkeyRow, hotkeyNote,
                menuBarIcon, menuBarNote,
                Self.section(L("section.displays")), DisplaySettingsView(controller: controller),
                Self.section(L("section.rain")), rain,
                Self.section(L("section.between")), background, transparent, screenshots,
                Self.section(L("section.words")), words,
                Self.section(L("section.agents")), hooksGrid, hooksNote,
                Self.section(L("section.glyphs")), restored,
                Self.separator(), footer,
            ])
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 10
            for (view, gap) in [(launch, 6.0), (escapeHint, 8.0), (hotkeyNote, 18.0), (rain, 18.0), (screenshots, 18.0),
                                (words, 18.0), (hooksNote, 18.0), (restored, 14.0)] as [(NSView, CGFloat)] {
                stack.setCustomSpacing(gap, after: view)
            }
            stack.translatesAutoresizingMaskIntoConstraints = false
            refreshValueLabels()
            refreshHooks()
            focusObserver = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window,
                                                   queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshHooks() }
            }
            let content = window.contentView!
            let scroll = NSScrollView()
            scroll.hasVerticalScroller = true
            scroll.autohidesScrollers = true
            scroll.drawsBackground = false
            scroll.translatesAutoresizingMaskIntoConstraints = false
            let document = DreamsSettingsDocumentView()
            document.translatesAutoresizingMaskIntoConstraints = false
            // Debug tools live in the right-click menu, out of the everyday settings.
            document.menu = debugMenu()
            scroll.documentView = document
            content.addSubview(scroll)
            document.addSubview(stack)
            NSLayoutConstraint.activate([
                scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor),
                scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor),
                scroll.topAnchor.constraint(equalTo: content.topAnchor),
                scroll.bottomAnchor.constraint(equalTo: content.bottomAnchor),
                document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
                stack.leadingAnchor.constraint(equalTo: document.leadingAnchor, constant: 20),
                stack.trailingAnchor.constraint(equalTo: document.trailingAnchor, constant: -20),
                stack.topAnchor.constraint(equalTo: document.topAnchor, constant: 16),
                stack.bottomAnchor.constraint(equalTo: document.bottomAnchor, constant: -16)
            ])
            // Size the window to its laid-out content (16 pt margins above and below);
            // scroll only on very small screens. The status text must be in place first:
            // an empty status label would measure one line short.
            refreshActivityLabel()
            content.layoutSubtreeIfNeeded()
            let needed = stack.fittingSize.height + 32
            let available = (NSScreen.main?.visibleFrame.height ?? 900) - 80
            window.setContentSize(NSSize(width: 460, height: min(needed, available)))
            content.layoutSubtreeIfNeeded()
            if stack.frame.height + 32 > window.contentLayoutRect.height, needed < available {
                window.setContentSize(NSSize(width: 460, height: min(stack.frame.height + 32, available)))
            }
            window.center()
            controlsWindow = window
            refreshActivityLabel()
            ensureActivityUpdates()
        }
        controller.stopForReopen()
        NSApplication.shared.activate(ignoringOtherApps: true)
        controlsWindow?.makeKeyAndOrderFront(nil)
    }

}
