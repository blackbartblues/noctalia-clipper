import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.UI
import qs.Services.Noctalia
import qs.Widgets

// Fullscreen transparent overlay that captures mouse position
// and shows a context menu with note cards at cursor location
PanelWindow {
    id: root

    required property ShellScreen screen
    property var pluginApi: null
    property string selectedText: ""
    property var noteCards: []
    readonly property string noteCardsDir: Quickshell.env("HOME") + "/.config/noctalia/plugins/clipper/notecards"

    // Callback when note is selected
    signal noteSelected(string noteId, string noteTitle)
    signal createNewNote()
    signal cancelled()

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "noctalia-notecard-selector-" + (screen?.name || "unknown")
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    // Build menu model will use noteCards passed from Main.qml

    // Build menu model from note cards
    function buildMenuModel() {
        Logger.i("NoteCardSelector", "buildMenuModel called, noteCards.length: " + noteCards.length);
        const model = [];
        
        // First option: Create new note
        model.push({
            "label": pluginApi?.tr("notecards.create-note") || "Create New Note",
            "action": "create-new",
            "icon": "add"
        });
        
        // Add separator if there are notes
        if (noteCards.length > 0) {
            model.push({
                "label": "---",
                "action": "separator",
                "icon": ""
            });
        }
        
        // Add existing notes
        for (let i = 0; i < noteCards.length; i++) {
            const note = noteCards[i];
            model.push({
                "label": note.title || "Untitled",
                "action": "note-" + note.id,
                "icon": "note",
                "noteId": note.id
            });
        }
        
        Logger.i("NoteCardSelector", "buildMenuModel created " + model.length + " items");
        return model;
    }

    // Show the selector - display menu at cursor position
    function show(text, notes) {
        selectedText = text || "";
        noteCards = notes || [];
        Logger.i("NoteCardSelector", "Showing selector with " + noteCards.length + " notecards");
        contextMenu.model = buildMenuModel();
        visible = true;
        contextMenu.model = buildMenuModel();
        visible = true;

        // Wait for compositor to send hover events
        showMenuTimer.start();
    }

    // Timer to wait for hover events from compositor
    Timer {
        id: showMenuTimer
        interval: 150
        repeat: false
        onTriggered: {
            // Position menu at current cursor position (tracked by hoverEnabled)
            anchorPoint.x = mouseCapture.mouseX;
            anchorPoint.y = mouseCapture.mouseY - 30;
            contextMenu.anchorItem = anchorPoint;
            contextMenu.visible = true;
        }
    }

    function close() {
        visible = false;
        contextMenu.visible = false;
    }

    // Context menu for note selection
    NPopupContextMenu {
        id: contextMenu
        visible: false
        screen: root.screen
        minWidth: 200

        onTriggered: (action, item) => {
            Logger.i("NoteCardSelector", "onTriggered called, action: " + action);
            if (action === "create-new") {
                Logger.i("NoteCardSelector", "Emitting createNewNote signal");
                root.createNewNote();
            } else if (action.startsWith("note-")) {
                const noteId = action.replace("note-", "");
                const note = noteCards.find(n => n.id === noteId);
                root.noteSelected(noteId, note ? note.title : "Untitled");
            }
            root.close();
        }
    }

    // Anchor point for menu positioning
    Item {
        id: anchorPoint
        width: 1
        height: 1
        x: 0
        y: 0
    }

    // Fullscreen mouse area - tracks cursor position via hoverEnabled
    MouseArea {
        id: mouseCapture
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            // Click outside menu - close
            root.cancelled();
            root.close();
        }
    }

    // ESC to cancel
    Keys.onEscapePressed: {
        root.cancelled();
        root.close();
    }

    Component.onDestruction: {
        showMenuTimer.stop();
        close();
    }
}
