import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    property real uiScale: 1.0
    required property string repoPath

    // Bottom-up from actual content, NOT a fixed height — a git
    // manager showing "working tree clean" (nothing else, tiny) and
    // one showing 50 changed files are legitimately very different
    // sizes, unlike Docker/Settings/SysMon (persistent, roughly-
    // constant-sized content). A hard floor still applies so it
    // doesn't feel cramped when empty; the file-list area itself is
    // separately capped (see _maxFileListHeight below) so a huge
    // change set scrolls internally instead of growing the whole
    // panel unboundedly.
    readonly property real _minHeight: 380
    readonly property real _maxFileListHeight: 340

    implicitWidth: 720 * uiScale
    implicitHeight: Math.max(_minHeight * uiScale, mainColumn.implicitHeight + 32 * uiScale)

    anchors.fill: parent
    focus: true
    readonly property string repoName: {
        const parts = repoPath.split("/").filter(p => p !== "");
        return parts.length > 0 ? parts[parts.length - 1] : repoPath;
    }
    readonly property var status: GitService.statusFor(repoPath)
    readonly property var currentError: GitService.errorFor(repoPath)

    Component.onCompleted: GitService.requestStatus(repoPath)
    Keys.onEscapePressed: ShellState.closeDashboard()

    // Local commit-message draft — cleared after a successful commit
    // (see the Connections below).
    property string commitMessage: ""

    Connections {
        target: GitService
        function onStatusUpdated(repo) {
            if (repo === root.repoPath && commitMessageField.text !== "")
                commitMessageField.text = "";
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 16 * root.uiScale
        spacing: 12 * root.uiScale

        // ── Header: repo name, branch, ahead/behind, refresh ──────
        // (X moved OUT of this row entirely — see below. A RowLayout
        // item only ever sits where the row's own content ends, which
        // isn't necessarily root's true corner; same lesson as
        // SystemMonitorTool's X earlier.)
        RowLayout {
            Layout.fillWidth: true
            // Reserve space so this row's own content doesn't slide
            // underneath the absolutely-positioned X.
            Layout.rightMargin: 34 * root.uiScale
            spacing: 12 * root.uiScale

            Rectangle {
                width: 40 * root.uiScale
                height: 40 * root.uiScale
                radius: 10 * root.uiScale
                color: Theme.backgroundAlt
                border.width: 1
                border.color: Theme.borderColor
                LucideIcon {
                    anchors.centerIn: parent
                    icon: "git-branch"
                    size: 18 * root.uiScale
                    color: Theme.selected
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2 * root.uiScale
                Text {
                    text: root.repoName
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 15 * root.uiScale
                    font.bold: true
                    elide: Text.ElideMiddle
                }
                Text {
                    text: {
                        if (!root.status)
                            return root.repoPath;
                        let s = root.status.branch || "(detached)";
                        if (root.status.ahead > 0)
                            s += "  ↑" + root.status.ahead;
                        if (root.status.behind > 0)
                            s += "  ↓" + root.status.behind;
                        return s;
                    }
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 11 * root.uiScale
                    opacity: 0.6
                }
            }

            IconButton {
                icon: "refresh-cw"
                size: 30 * root.uiScale
                iconSize: 14 * root.uiScale
                // Disabled while ANYTHING is pending for this repo
                // (not just "status" specifically) — refreshing while
                // a push/pull/commit is already in flight for the same
                // repo would just race it. isPending/isRepoBusy are
                // per-repo now (see GitService) — a request for a
                // DIFFERENT repo no longer affects this button at all.
                enabled: !GitService.isRepoBusy(root.repoPath)
                idleOpacity: GitService.isRepoBusy(root.repoPath) ? 0.35 : 0.7
                tooltipText: GitService.isPending(root.repoPath, "status") ? "Refreshing..." : "Refresh"
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.selected
                onTapped: GitService.requestStatus(root.repoPath)
            }
        }

        // ── Error banner ───────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            visible: root.currentError !== null
            implicitHeight: errorText.implicitHeight + 16 * root.uiScale
            radius: Theme.radius
            color: Qt.rgba(Theme.color1.r, Theme.color1.g, Theme.color1.b, 0.12)
            border.width: 1
            border.color: Theme.color1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8 * root.uiScale
                spacing: 8 * root.uiScale

                LucideIcon {
                    icon: "triangle-alert"
                    size: 16 * root.uiScale
                    color: Theme.color1
                }
                Text {
                    id: errorText
                    Layout.fillWidth: true
                    text: root.currentError ? ("(" + root.currentError.action + ") " + root.currentError.message) : ""
                    color: Theme.foreground
                    font.family: Theme.fontName
                    font.pixelSize: 12 * root.uiScale
                    wrapMode: Text.WordWrap
                }
            }
        }

        // ── File lists ──────────────────────────────────────────────
        // Layout.preferredHeight (capped, content-driven) instead of
        // Layout.fillHeight — was stretching to fill whatever the
        // fixed 640px root left over, wasting huge empty space on a
        // clean repo. Now sizes to its own content up to
        // _maxFileListHeight, scrolling internally beyond that.
        CustomScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(root._maxFileListHeight * root.uiScale, filesColumn.implicitHeight)
            uiScale: root.uiScale
            clip: true

            ColumnLayout {
                id: filesColumn
                // Narrower than the full scroll-view width — reserves
                // room for CustomScrollBar (which otherwise sits right
                // on top of each row's stage/unstage button) without
                // touching CustomScrollView/CustomScrollBar themselves.
                width: parent.width - 16 * root.uiScale
                spacing: 14 * root.uiScale

                GitFileSection {
                    uiScale: root.uiScale
                    title: "Staged"
                    files: root.status ? root.status.staged : []
                    actionIcon: "minus"
                    actionTooltip: "Unstage"
                    onFileAction: file => GitService.unstage(root.repoPath, [file])
                    onSectionAction: () => GitService.unstage(root.repoPath, [])
                    sectionActionTooltip: "Unstage all"
                }
                GitFileSection {
                    uiScale: root.uiScale
                    title: "Changes"
                    files: root.status ? root.status.unstaged : []
                    actionIcon: "plus"
                    actionTooltip: "Stage"
                    onFileAction: file => GitService.stage(root.repoPath, [file])
                    onSectionAction: () => GitService.stage(root.repoPath, root.status ? root.status.unstaged : [])
                    sectionActionTooltip: "Stage all"
                }
                GitFileSection {
                    uiScale: root.uiScale
                    title: "Untracked"
                    files: root.status ? root.status.untracked : []
                    actionIcon: "plus"
                    actionTooltip: "Stage"
                    onFileAction: file => GitService.stage(root.repoPath, [file])
                    onSectionAction: () => GitService.stage(root.repoPath, root.status ? root.status.untracked : [])
                    sectionActionTooltip: "Stage all"
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 20 * root.uiScale
                    visible: root.status && root.status.staged.length === 0 && root.status.unstaged.length === 0 && root.status.untracked.length === 0
                    text: "Working tree clean"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.foreground
                    opacity: 0.4
                    font.family: Theme.fontName
                    font.pixelSize: 13 * root.uiScale
                }
            }
        }

        // ── Commit + push/pull ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * root.uiScale

            SearchBar {
                id: commitMessageField
                Layout.fillWidth: true
                uiScale: root.uiScale
                placeholderText: "Commit message..."
                text: root.commitMessage
                onTextChanged: root.commitMessage = text
            }

            IconButton {
                icon: "check"
                size: 36 * root.uiScale
                iconSize: 16 * root.uiScale
                tooltipText: "Commit staged changes"
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.selected
                enabled: root.commitMessage.trim() !== "" && root.status && root.status.staged.length > 0 && !GitService.isRepoBusy(root.repoPath)
                spinning: GitService.isPending(root.repoPath, "commit")
                onTapped: GitService.commit(root.repoPath, root.commitMessage.trim())
            }

            IconButton {
                icon: "arrow-down"
                size: 36 * root.uiScale
                iconSize: 16 * root.uiScale
                tooltipText: "Pull"
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.selected
                enabled: !GitService.isRepoBusy(root.repoPath)
                spinning: GitService.isPending(root.repoPath, "pull")
                onTapped: GitService.pull(root.repoPath)
            }

            IconButton {
                icon: "arrow-up"
                size: 36 * root.uiScale
                iconSize: 16 * root.uiScale
                tooltipText: "Push"
                normalColor: Theme.backgroundAlt
                hoverColor: Theme.selected
                enabled: !GitService.isRepoBusy(root.repoPath)
                spinning: GitService.isPending(root.repoPath, "push")
                onTapped: GitService.push(root.repoPath)
            }
        }
    }

    // Same "X" convention as Docker/SysMon/Settings —
    // ShellState.closeResumableComponent() closes the dashboard AND
    // forgets this as the backgrounded/resumable tool. Anchored
    // directly to root's own corner (NOT a RowLayout child) — see
    // SystemMonitorTool's own header comment for why that's more
    // reliable than relying on row content to end exactly at the true
    // edge.
    IconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        icon: "x"
        size: 30 * root.uiScale
        iconSize: 14 * root.uiScale
        normalColor: Theme.backgroundAlt
        hoverColor: Theme.color1
        tooltipText: "Close"
        onTapped: ShellState.closeResumableComponent()
    }
}
