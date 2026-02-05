import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property var screen: null

    // Function to sync all notecard changes before saving
    function syncAllChanges() {
        for (let i = 0; i < noteCardsRepeater.count; i++) {
            const card = noteCardsRepeater.itemAt(i);
            if (card && card.syncChanges) {
                card.syncChanges();
            }
        }
    }

    // Background MouseArea - ALWAYS closes panel on click
    MouseArea {
        anchors.fill: parent
        z: -1  // Behind everything

        onClicked: {
            // Close panel when clicking on background
            if (root.pluginApi && root.screen) {
                root.pluginApi.closePanel(root.screen);
            }
        }
    }

    // Empty state UI (shown when no notes)
    Item {
        anchors.centerIn: parent
        width: 400
        height: 200
        visible: !(root.pluginApi && root.pluginApi.mainInstance && root.pluginApi.mainInstance.noteCards) ||
                 root.pluginApi.mainInstance.noteCards.length === 0

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            NIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: "notes"
                pointSize: 64
                color: Color.mOnSurfaceVariant
                opacity: 0.5
            }

            NText {
                Layout.alignment: Qt.AlignHCenter
                text: pluginApi?.tr("notecards.empty-state") || "No notes yet"
                font.pointSize: Style.fontSizeL
                font.bold: true
                color: Color.mOnSurfaceVariant
            }

            NText {
                Layout.alignment: Qt.AlignHCenter
                text: pluginApi?.tr("notecards.empty-hint") || "Click the button below to create your first note"
                font.pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
                opacity: 0.7
            }

            NButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 16
                text: pluginApi?.tr("notecards.create-note") || "Create Note"
                icon: "add"

                onClicked: {
                    if (root.pluginApi && root.pluginApi.mainInstance) {
                        root.pluginApi.mainInstance.createNoteCard("");
                    }
                }
            }
        }
    }

    // Repeater for note cards
    Repeater {
        id: noteCardsRepeater
        model: (root.pluginApi && root.pluginApi.mainInstance) ? (root.pluginApi.mainInstance.noteCards || []) : []

        NoteCard {
            pluginApi: root.pluginApi
            note: modelData
            noteIndex: index
            z: 1  // Above background MouseArea

            // React to revision changes
            property int revision: (root.pluginApi && root.pluginApi.mainInstance) ? (root.pluginApi.mainInstance.noteCardsRevision || 0) : 0
        }
    }

    // Note controls (TOP-LEFT corner)
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 16
        width: contentRow.width + 16
        height: 40
        color: Color.mSurfaceVariant
        border.color: Color.mOnSurfaceVariant
        border.width: 1
        radius: Style.radiusM
        visible: (root.pluginApi && root.pluginApi.mainInstance && root.pluginApi.mainInstance.noteCards) ? root.pluginApi.mainInstance.noteCards.length > 0 : false
        z: 2  // Above everything

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8

            // Add note button
            NIconButton {
                width: 28
                height: 28
                icon: "add"
                tooltipText: pluginApi?.tr("notecards.create-note") || "Create Note"
                colorBg: Color.mPrimary
                colorFg: Color.mOnPrimary
                colorBgHover: Qt.lighter(Color.mPrimary, 1.2)
                colorFgHover: Color.mOnPrimary

                onClicked: {
                    if (root.pluginApi && root.pluginApi.mainInstance) {
                        const count = root.pluginApi.mainInstance.noteCards ? root.pluginApi.mainInstance.noteCards.length : 0;
                        const max = root.pluginApi.mainInstance.maxNoteCards || 20;

                        if (count >= max) {
                            ToastService.showWarning("Maximum " + max + " notes reached");
                        } else {
                            root.pluginApi.mainInstance.createNoteCard("");
                        }
                    }
                }
            }

            // Vertical separator
            Rectangle {
                width: 1
                height: 24
                color: Color.mOnSurfaceVariant
                opacity: 0.3
            }

            // Note icon
            NIcon {
                icon: "note"
                pointSize: 16
                color: Color.mOnSurfaceVariant
            }

            // Count text
            NText {
                text: {
                    const count = (root.pluginApi && root.pluginApi.mainInstance && root.pluginApi.mainInstance.noteCards) ? root.pluginApi.mainInstance.noteCards.length : 0;
                    const max = (root.pluginApi && root.pluginApi.mainInstance) ? (root.pluginApi.mainInstance.maxNoteCards || 20) : 20;
                    return count + " / " + max;
                }
                font.pointSize: Style.fontSizeM
                font.bold: true
                color: {
                    const count = (root.pluginApi && root.pluginApi.mainInstance && root.pluginApi.mainInstance.noteCards) ? root.pluginApi.mainInstance.noteCards.length : 0;
                    const max = (root.pluginApi && root.pluginApi.mainInstance) ? (root.pluginApi.mainInstance.maxNoteCards || 20) : 20;
                    return count >= max ? Color.mError : Color.mOnSurfaceVariant;
                }
            }
        }
    }
}
