import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

Item {
    id: content

    required property string osdIconName
    required property string osdTitleText
    required property string osdSubtitleText
    required property real osdValueNum
    required property bool osdMutedFlag
    required property bool showBarFlag
    required property bool showCountdownFlag

    // Computed locally — this component is loaded from two different
    // hosting contexts (OSD.qml's drawer mode via contentComponent,
    // and its popup mode via direct instantiation), so rather than
    // relying on either wrapper to remember to pass uiScale down
    // (same class of bug we've hit before), it resolves its own
    // screen directly, same self-sufficient pattern as StyledToolTip.
    readonly property real uiScale: Theme.scaleFor(QsWindow.window?.screen)

    implicitWidth: 260 * uiScale
    implicitHeight: contentColumn.implicitHeight + (32 * uiScale)

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 1
            leftMargin: Theme.radius
            rightMargin: Theme.radius
        }
        height: 1
        radius: 1
        color: Theme.foreground
        opacity: 0.06
    }

    RowLayout {
        id: contentColumn
        anchors {
            fill: parent
            margins: 16 * content.uiScale
        }
        spacing: 14 * content.uiScale

        // ── Icon badge (or countdown number) ──────────────────────────
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 42 * content.uiScale
            height: 42 * content.uiScale
            radius: width / 2
            color: Theme.backgroundAlt
            border.color: Theme.borderColor
            border.width: Theme.widgetBorderWidth

            LucideIcon {
                anchors.centerIn: parent
                icon: content.osdIconName
                size: 20 * content.uiScale
                color: content.osdMutedFlag ? Theme.foreground : Theme.selected
                opacity: content.osdMutedFlag ? 0.5 : 1.0
                visible: !content.showCountdownFlag
            }

            Text {
                anchors.centerIn: parent
                visible: content.showCountdownFlag
                text: Math.round(content.osdValueNum)
                color: Theme.selected
                font.family: Theme.fontName
                font.pixelSize: 26 * content.uiScale
                font.bold: true
            }
        }

        // ── Title + bar / subtitle ─────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6 * content.uiScale

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * content.uiScale

                Text {
                    Layout.fillWidth: true
                    text: content.osdTitleText
                    elide: Text.ElideRight
                    font.family: Theme.fontName
                    font.pixelSize: 13 * content.uiScale
                    font.bold: true
                    color: Theme.foreground
                }

                Text {
                    visible: content.showBarFlag
                    text: Math.round(content.osdValueNum * 100) + "%"
                    font.family: Theme.fontName
                    font.pixelSize: 12 * content.uiScale
                    opacity: 0.6
                    color: Theme.foreground
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 6 * content.uiScale
                visible: content.showBarFlag

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.foreground
                    opacity: 0.12
                }

                Rectangle {
                    id: barFill
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    radius: height / 2
                    color: content.osdMutedFlag ? Theme.foreground : Theme.selected
                    opacity: content.osdMutedFlag ? 0.35 : 1.0
                    width: Math.max(height, parent.width * (content.osdMutedFlag ? 0.0 : content.osdValueNum))

                    Behavior on width {
                        Anim {
                            type: Anim.FastToggle
                        }
                    }
                    Behavior on color {
                        AnimColor {
                            type: Anim.FastEffects
                        }
                    }
                    Behavior on opacity {
                        Anim {
                            type: Anim.FastEffects
                        }
                    }

                    Rectangle {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: parent.height / 2
                        radius: parent.radius
                        color: Theme.foreground
                        opacity: 0.12
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !content.showBarFlag && content.osdSubtitleText !== ""
                text: content.osdSubtitleText
                elide: Text.ElideRight
                font.family: Theme.fontName
                font.pixelSize: 12 * content.uiScale
                opacity: 0.65
                color: Theme.foreground
            }
        }
    }
}
