import QtQuick
import QtQuick.Controls
import Quickshell.Wayland
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Keyboard
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    // Plugin API (injected by PluginPanelSlot)
    property var pluginApi: null

    // SmartPanel properties (required for panel behavior)
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: false

    // Panel dimensions
    property int contentPreferredHeight: 300
    property int contentPreferredWidth: screen.width  // 0 means use default widthRatio

    // Panel positioning (exposed to PluginPanelSlot which wraps this in SmartPanel)
    property bool panelAnchorBottom: true
    property bool panelAnchorLeft: true
    property bool panelAnchorRight: true
    property bool panelAnchorHorizontalCenter: true
    property bool panelAnchorVerticalCenter: false

    // Keyboard navigation
    property int selectedIndex: 0

    // Filtering
    property string filterType: ""
    property string searchText: ""

    // Reset selection when filter changes
    onFilterTypeChanged: selectedIndex = 0
    onSearchTextChanged: selectedIndex = 0

    // Filtered items
    readonly property var filteredItems: {
        let items = ClipboardService.items || [];
        if (!filterType && !searchText)
            return items;

        return items.filter(item => {
            if (filterType) {
                const itemType = getItemType(item);
                if (itemType !== filterType)
                    return false;
            }
            if (searchText) {
                const preview = item.preview || "";
                if (!preview.toLowerCase().includes(searchText.toLowerCase()))
                    return false;
            }
            return true;
        });
    }

    function getItemType(item) {
        if (!item)
            return "Text";
        if (item.isImage)
            return "Image";
        const preview = item.preview || "";
        const trimmed = preview.trim();

        if (/^#[A-Fa-f0-9]{6}$/.test(trimmed) || /^#[A-Fa-f0-9]{3}$/.test(trimmed))
            return "Color";
        if (/^[A-Fa-f0-9]{6}$/.test(trimmed))
            return "Color";
        if (/^rgba?\s*\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*(,\s*[\d.]+\s*)?\)$/i.test(trimmed))
            return "Color";
        if (/^https?:\/\//.test(trimmed))
            return "Link";
        if (preview.includes("function") || preview.includes("import ") || preview.includes("const ") || preview.includes("let ") || preview.includes("var ") || preview.includes("class ") || preview.includes("def ") || preview.includes("return ") || /^[\{\[\(<]/.test(trimmed))
            return "Code";
        if (trimmed.length <= 4 && trimmed.length > 0 && trimmed.charCodeAt(0) > 255)
            return "Emoji";
        if (/^(\/|~|file:\/\/)/.test(trimmed))
            return "File";

        return "Text";
    }

    Keys.onLeftPressed: {
        Logger.i("clipper", "onLeftPressed");
        if (listView.count > 0) {
            selectedIndex = Math.max(0, selectedIndex - 1);
            listView.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
    }

    Keys.onRightPressed: {
        Logger.i("clipper", "onRightPressed");
        if (listView.count > 0) {
            selectedIndex = Math.min(listView.count - 1, selectedIndex + 1);
            listView.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
    }

    Keys.onReturnPressed: {
        Logger.i("clipper", "onReturnPressed");
        if (listView.count > 0 && selectedIndex >= 0 && selectedIndex < listView.count) {
            const item = root.filteredItems[selectedIndex];
            if (item) {
                ClipboardService.copyToClipboard(item.id);
                if (pluginApi) {
                    pluginApi.closePanel(screen);
                }
            }
        }
    }

    Keys.onEscapePressed: {
        Logger.i("clipper", "onEscapePressed");
        if (pluginApi) {
            pluginApi.closePanel(screen);
        }
    }

    Keys.onDeletePressed: {
        Logger.i("clipper", "onDeletePressed");
        if (listView.count > 0 && selectedIndex >= 0 && selectedIndex < listView.count) {
            const item = root.filteredItems[selectedIndex];
            if (item) {
                ClipboardService.deleteById(item.id);
                if (selectedIndex >= listView.count - 1) {
                    selectedIndex = Math.max(0, listView.count - 2);
                }
            }
        }
    }

    Keys.onDigit1Pressed: {
        Logger.i("clipper", "onDigit1Pressed");
        filterType = "Text";
    }

    Keys.onDigit2Pressed: {
        Logger.i("clipper", "onDigit2Pressed");
        filterType = "Image";
    }

    Keys.onDigit3Pressed: {
        Logger.i("clipper", "onDigit3Pressed");
        filterType = "Color";
    }

    Keys.onDigit4Pressed: {
        Logger.i("clipper", "onDigit4Pressed");
        filterType = "Link";
    }

    Keys.onDigit5Pressed: {
        Logger.i("clipper", "onDigit5Pressed");
        filterType = "Code";
    }

    Keys.onDigit6Pressed: {
        Logger.i("clipper", "onDigit6Pressed");
        filterType = "Emoji";
    }

    Keys.onDigit7Pressed: {
        Logger.i("clipper", "onDigit7Pressed");
        filterType = "File";
    }

    Keys.onDigit0Pressed: {
        Logger.i("clipper", "onDigit0Pressed");
        filterType = "";
    }

    // Main content
    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: (typeof Color !== "undefined") ? Color.mSurface : "#222222"
        radius: Style.radiusM

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.radius
            color: parent.color
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NText {
                    text: "Clipboard History"
                    font.bold: true
                    font.pointSize: Style.fontSizeL
                    Layout.alignment: Qt.AlignVCenter
                    Layout.topMargin: -2 * Style.uiScaleRatio
                }

                Item {
                    Layout.fillWidth: true
                }

                NIconButton {
                    icon: "settings"
                    tooltipText: "Settings"
                    Layout.alignment: Qt.AlignVCenter
                    colorBg: (typeof Color !== "undefined") ? Color.mSurfaceVariant : "#444444"
                    colorBgHover: (typeof Color !== "undefined") ? Color.mHover : "#666666"
                    colorFg: (typeof Color !== "undefined") ? Color.mOnSurface : "#FFFFFF"
                    colorFgHover: (typeof Color !== "undefined") ? Color.mOnSurface : "#FFFFFF"
                    onClicked: {
                        if (root.pluginApi) {
                            BarService.openPluginSettings(screen, root.pluginApi.manifest);
                        }
                    }
                }

                NTextInput {
                    id: searchInput
                    Layout.preferredWidth: 250
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "Search..."
                    text: root.searchText
                    onTextChanged: root.searchText = text

                    Keys.onEscapePressed: {
                        if (text !== "") {
                            text = "";
                        } else {
                            root.onEscapePressed();
                        }
                    }
                    Keys.onLeftPressed: event => {
                        if (searchInput.cursorPosition === 0) {
                            root.onLeftPressed();
                            event.accepted = true;
                        }
                    }
                    Keys.onRightPressed: event => {
                        if (searchInput.cursorPosition === text.length) {
                            root.onRightPressed();
                            event.accepted = true;
                        }
                    }
                    Keys.onReturnPressed: root.onReturnPressed()
                    Keys.onEnterPressed: root.onReturnPressed()
                    Keys.onTabPressed: event => {
                        root.filterType = "Text";
                        event.accepted = true;
                    }
                    Keys.onUpPressed: event => {
                        // Up = focus search (already focused, do nothing)
                        event.accepted = true;
                    }
                    Keys.onDownPressed: event => {
                        // Down = focus cards
                        listView.forceActiveFocus();
                        event.accepted = true;
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Home && event.modifiers & Qt.ControlModifier) {
                            root.onHomePressed();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_End && event.modifiers & Qt.ControlModifier) {
                            root.onEndPressed();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Delete) {
                            // Delete current card
                            if (listView.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < listView.count) {
                                const item = root.filteredItems[root.selectedIndex];
                                if (item) {
                                    ClipboardService.deleteById(item.id);
                                    if (root.selectedIndex >= listView.count - 1) {
                                        root.selectedIndex = Math.max(0, listView.count - 2);
                                    }
                                }
                            }
                            event.accepted = true;
                        } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                            // Number keys for filter types
                            const filterMap = {
                                [Qt.Key_0]: "",
                                [Qt.Key_1]: "Text",
                                [Qt.Key_2]: "Image",
                                [Qt.Key_3]: "Color",
                                [Qt.Key_4]: "Link",
                                [Qt.Key_5]: "Code",
                                [Qt.Key_6]: "Emoji",
                                [Qt.Key_7]: "File"
                            };
                            if (filterMap.hasOwnProperty(event.key)) {
                                root.filterType = filterMap[event.key];
                                event.accepted = true;
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Style.marginXS
                    Layout.alignment: Qt.AlignVCenter

                    NIconButton {
                        focus: true
                        icon: "apps"
                        tooltipText: "All"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "" ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "" ? Color.mPrimary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = ""

                        Keys.onTabPressed: {
                            root.filterType = "";
                            event.accepted = true;
                        }
                    }

                    NIconButton {
                        focus: true
                        icon: "align-left"
                        tooltipText: "Text"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Text" ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Text" ? Color.mPrimary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Text" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Text" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Text"

                        Keys.onTabPressed: {
                            root.filterType = "Image";
                            event.accepted = true;
                        }
                    }

                    NIconButton {
                        focus: true
                        icon: "photo"
                        tooltipText: "Images"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Image" ? Color.mTertiary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Image" ? Color.mTertiary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Image" ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Image" ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Image"
                    }

                    NIconButton {
                        focus: true
                        icon: "palette"
                        tooltipText: "Colors"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Color" ? Color.mSecondary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Color" ? Color.mSecondary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Color" ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Color" ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Color"
                    }

                    NIconButton {
                        focus: true
                        icon: "link"
                        tooltipText: "Links"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Link" ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Link" ? Color.mPrimary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Link" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Link" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Link"
                    }

                    NIconButton {
                        focus: true
                        icon: "code"
                        tooltipText: "Code"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Code" ? Color.mSecondary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Code" ? Color.mSecondary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Code" ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Code" ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Code"
                    }

                    NIconButton {
                        focus: true
                        icon: "mood-smile"
                        tooltipText: "Emoji"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Emoji" ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Emoji" ? Color.mPrimary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Emoji" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Emoji" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Emoji"
                    }

                    NIconButton {
                        focus: true
                        icon: "file"
                        tooltipText: "Files"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "File" ? Color.mTertiary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "File" ? Color.mTertiary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "File" ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "File" ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "File"
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    color: (typeof Color !== "undefined") ? Color.mOutline : "#888888"
                    opacity: 0.5
                }

                NButton {
                    focus: true
                    text: "Clear All"
                    icon: "trash"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.topMargin: -2 * Style.uiScaleRatio
                    onClicked: ClipboardService.wipeAll()
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: ListView.Horizontal
                spacing: Style.marginM
                clip: true
                currentIndex: root.selectedIndex
                focus: false

                model: root.filteredItems

                Keys.onUpPressed: {
                    searchInput.forceActiveFocus();
                }
                Keys.onLeftPressed: {
                    if (count > 0) {
                        root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                        positionViewAtIndex(root.selectedIndex, ListView.Contain);
                    }
                }
                Keys.onRightPressed: {
                    if (count > 0) {
                        root.selectedIndex = Math.min(count - 1, root.selectedIndex + 1);
                        positionViewAtIndex(root.selectedIndex, ListView.Contain);
                    }
                }
                Keys.onReturnPressed: {
                    if (count > 0 && root.selectedIndex >= 0 && root.selectedIndex < count) {
                        const item = root.filteredItems[root.selectedIndex];
                        if (item) {
                            ClipboardService.copyToClipboard(item.id);
                            if (root.pluginApi) {
                                root.pluginApi.closePanel(screen);
                            }
                        }
                    }
                }
                Keys.onDeletePressed: {
                    if (count > 0 && root.selectedIndex >= 0 && root.selectedIndex < count) {
                        const item = root.filteredItems[root.selectedIndex];
                        if (item) {
                            ClipboardService.deleteById(item.id);
                            if (root.selectedIndex >= count - 1) {
                                root.selectedIndex = Math.max(0, count - 2);
                            }
                        }
                    }
                }
                Keys.onEscapePressed: {
                    if (root.pluginApi) {
                        root.pluginApi.closePanel(screen);
                    }
                }
                Keys.onTabPressed: {
                    // Cycle through filters: All -> Text -> Image -> Color -> Link -> Code -> Emoji -> File -> All
                    const filters = ["", "Text", "Image", "Color", "Link", "Code", "Emoji", "File"];
                    const currentIdx = filters.indexOf(root.filterType);
                    const nextIdx = (currentIdx + 1) % filters.length;
                    root.filterType = filters[nextIdx];
                }
                Keys.onBacktabPressed: {
                    // Shift+Tab = cycle backwards
                    const filters = ["", "Text", "Image", "Color", "Link", "Code", "Emoji", "File"];
                    const currentIdx = filters.indexOf(root.filterType);
                    const prevIdx = (currentIdx - 1 + filters.length) % filters.length;
                    root.filterType = filters[prevIdx];
                }
                Keys.onPressed: event => {
                    if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                        const filterMap = {
                            [Qt.Key_0]: "",
                            [Qt.Key_1]: "Text",
                            [Qt.Key_2]: "Image",
                            [Qt.Key_3]: "Color",
                            [Qt.Key_4]: "Link",
                            [Qt.Key_5]: "Code",
                            [Qt.Key_6]: "Emoji",
                            [Qt.Key_7]: "File"
                        };
                        if (filterMap.hasOwnProperty(event.key)) {
                            root.filterType = filterMap[event.key];
                            event.accepted = true;
                        }
                    }
                }

                populate: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Style.animationNormal
                    }
                    NumberAnimation {
                        property: "x"
                        from: listView.width
                        duration: Style.animationNormal
                        easing.type: Easing.OutCubic
                    }
                }

                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Style.animationNormal
                    }
                    NumberAnimation {
                        property: "x"
                        from: listView.width
                        duration: Style.animationNormal
                        easing.type: Easing.OutCubic
                    }
                }

                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Style.animationNormal
                    }
                    NumberAnimation {
                        property: "x"
                        to: -250
                        duration: Style.animationNormal
                        easing.type: Easing.InCubic
                    }
                }

                displaced: Transition {
                    NumberAnimation {
                        properties: "x"
                        duration: Style.animationNormal
                        easing.type: Easing.InOutCubic
                    }
                }

                move: Transition {
                    NumberAnimation {
                        properties: "x"
                        duration: Style.animationNormal
                        easing.type: Easing.InOutCubic
                    }
                }

                delegate: ClipboardCard {
                    clipboardItem: modelData
                    pluginApi: root.pluginApi
                    height: listView.height
                    selected: index === root.selectedIndex

                    onClicked: {
                        root.selectedIndex = index;
                        ClipboardService.copyToClipboard(clipboardId);
                        if (root.pluginApi) {
                            root.pluginApi.closePanel(screen);
                        }
                    }

                    onDeleteClicked: {
                        ClipboardService.deleteById(clipboardId);
                    }
                }

                NText {
                    anchors.centerIn: parent
                    visible: listView.count === 0
                    text: root.filterType || root.searchText ? "No matching items" : "Clipboard is empty"
                    color: (typeof Color !== "undefined") ? Color.mOnSurfaceVariant : "#AAAAAA"
                }
            }
        }
    }

    Component.onCompleted: {
        selectedIndex = 0;
        filterType = "";
        searchText = "";
        ClipboardService.list();
        listView.forceActiveFocus();
        Logger.i("clipper", "open");
        WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand;
    }
}
