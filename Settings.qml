import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    // Available card types
    readonly property var cardTypes: [
        { key: "Text", name: "Text" },
        { key: "Image", name: "Image" },
        { key: "Link", name: "Link" },
        { key: "Code", name: "Code" },
        { key: "Color", name: "Color" },
        { key: "Emoji", name: "Emoji" },
        { key: "File", name: "File" }
    ]

    // Available colors from Color scheme
    readonly property var colorOptions: [
        { key: "mPrimary", name: "Primary" },
        { key: "mOnPrimary", name: "On Primary" },
        { key: "mSecondary", name: "Secondary" },
        { key: "mOnSecondary", name: "On Secondary" },
        { key: "mTertiary", name: "Tertiary" },
        { key: "mOnTertiary", name: "On Tertiary" },
        { key: "mSurface", name: "Surface" },
        { key: "mOnSurface", name: "On Surface" },
        { key: "mSurfaceVariant", name: "Surface Variant" },
        { key: "mOnSurfaceVariant", name: "On Surface Variant" },
        { key: "mOutline", name: "Outline" },
        { key: "mError", name: "Error" },
        { key: "mOnError", name: "On Error" },
        { key: "mHover", name: "Hover" },
        { key: "mOnHover", name: "On Hover" },
        { key: "custom", name: "Custom..." }
    ]

    // Currently selected card type for editing
    property string selectedCardType: "Text"

    // Default colors per card type
    readonly property var defaultCardColors: {
        "Text": { bg: "mOutline", separator: "mSurface", fg: "mOnSurface" },
        "Image": { bg: "mTertiary", separator: "mSurface", fg: "mOnTertiary" },
        "Link": { bg: "mPrimary", separator: "mSurface", fg: "mOnPrimary" },
        "Code": { bg: "mSecondary", separator: "mSurface", fg: "mOnSecondary" },
        "Color": { bg: "mSecondary", separator: "mSurface", fg: "mOnSecondary" },
        "Emoji": { bg: "mHover", separator: "mSurface", fg: "mOnHover" },
        "File": { bg: "mError", separator: "mSurface", fg: "mOnError" }
    }

    // Current card colors (loaded from settings or defaults)
    property var cardColors: JSON.parse(JSON.stringify(defaultCardColors))

    // Custom color values (when "custom" is selected)
    property var customColors: {
        "Text": { bg: "#555555", separator: "#000000", fg: "#e9e4f0" },
        "Image": { bg: "#e0b7c9", separator: "#000000", fg: "#20161f" },
        "Link": { bg: "#c7a1d8", separator: "#000000", fg: "#1a151f" },
        "Code": { bg: "#a984c4", separator: "#000000", fg: "#f3edf7" },
        "Color": { bg: "#a984c4", separator: "#000000", fg: "#f3edf7" },
        "Emoji": { bg: "#e0b7c9", separator: "#000000", fg: "#20161f" },
        "File": { bg: "#e9899d", separator: "#000000", fg: "#1e1418" }
    }

    spacing: Style.marginL

    Component.onCompleted: {
        // Load saved settings
        if (pluginApi?.pluginSettings?.cardColors) {
            try {
                cardColors = JSON.parse(JSON.stringify(pluginApi.pluginSettings.cardColors));
            } catch (e) {
                Logger.e("clipper", "Failed to load cardColors: " + e);
            }
        }
        if (pluginApi?.pluginSettings?.customColors) {
            try {
                customColors = JSON.parse(JSON.stringify(pluginApi.pluginSettings.customColors));
            } catch (e) {
                Logger.e("clipper", "Failed to load customColors: " + e);
            }
        }
    }

    // Helper to get actual color value
    function getColorValue(colorKey, cardType, colorType) {
        if (colorKey === "custom") {
            return customColors[cardType]?.[colorType] || "#888888";
        }
        if (typeof Color !== "undefined" && Color[colorKey]) {
            return Color[colorKey];
        }
        return "#888888";
    }

    // Get current colors for preview
    function getPreviewBg() {
        return getColorValue(cardColors[selectedCardType]?.bg || "mOutline", selectedCardType, "bg");
    }
    function getPreviewSeparator() {
        return getColorValue(cardColors[selectedCardType]?.separator || "mSurface", selectedCardType, "separator");
    }
    function getPreviewFg() {
        return getColorValue(cardColors[selectedCardType]?.fg || "mOnSurface", selectedCardType, "fg");
    }

    // Card type selector
    NComboBox {
        Layout.fillWidth: true
        label: "Card Type"
        description: "Select card type to customize"
        model: root.cardTypes
        currentKey: root.selectedCardType
        onSelected: key => root.selectedCardType = key
    }

    // Live Preview
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 280
        color: getColor("mSurfaceVariant", "#333333")
        radius: Style.radiusM

        function getColor(propName, fallback) {
            if (typeof Color !== "undefined" && Color[propName]) return Color[propName];
            return fallback;
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText {
                text: "Preview"
                font.bold: true
                color: root.getPreviewFg()
            }

            // Preview card - same size as real card (250 x ~220)
            Rectangle {
                Layout.preferredWidth: 250
                Layout.preferredHeight: 220
                Layout.alignment: Qt.AlignHCenter
                color: root.getPreviewBg()
                radius: Style.radiusM
                border.width: 2
                border.color: root.getPreviewBg()

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: root.getPreviewBg()
                        radius: Style.radiusM

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.radius
                            color: parent.color
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            NIcon {
                                icon: root.selectedCardType === "Image" ? "photo" :
                                      root.selectedCardType === "Link" ? "link" :
                                      root.selectedCardType === "Code" ? "code" :
                                      root.selectedCardType === "Color" ? "palette" :
                                      root.selectedCardType === "Emoji" ? "mood-smile" :
                                      root.selectedCardType === "File" ? "file" : "align-left"
                                pointSize: 12
                                color: root.getPreviewFg()
                            }

                            NText {
                                text: root.selectedCardType
                                font.bold: true
                                color: root.getPreviewFg()
                            }

                            Item { Layout.fillWidth: true }

                            NIcon {
                                icon: "trash"
                                pointSize: 12
                                color: root.getPreviewFg()
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        Layout.preferredWidth: parent.width - 10
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 1
                        color: root.getPreviewSeparator()
                    }

                    // Content area
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 8

                        NText {
                            anchors.fill: parent
                            text: "Sample content preview..."
                            wrapMode: Text.Wrap
                            color: root.getPreviewFg()
                        }
                    }
                }
            }
        }
    }

    // Color settings
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NComboBox {
            Layout.fillWidth: true
            label: "Background Color"
            description: "Card background color"
            model: root.colorOptions
            currentKey: root.cardColors[root.selectedCardType]?.bg || "mOutline"
            onSelected: key => {
                if (!root.cardColors[root.selectedCardType]) {
                    root.cardColors[root.selectedCardType] = {};
                }
                root.cardColors[root.selectedCardType].bg = key;
                root.cardColorsChanged();
            }
        }

        // Custom color picker for background (visible only when custom is selected)
        NColorPicker {
            visible: root.cardColors[root.selectedCardType]?.bg === "custom"
            Layout.preferredWidth: Style.sliderWidth
            Layout.preferredHeight: Style.baseWidgetSize
            selectedColor: root.customColors[root.selectedCardType]?.bg || "#888888"
            onColorSelected: color => {
                if (!root.customColors[root.selectedCardType]) {
                    root.customColors[root.selectedCardType] = {};
                }
                root.customColors[root.selectedCardType].bg = color.toString();
                root.customColorsChanged();
            }
        }

        NComboBox {
            Layout.fillWidth: true
            label: "Separator Color"
            description: "Line between header and content"
            model: root.colorOptions
            currentKey: root.cardColors[root.selectedCardType]?.separator || "mSurface"
            onSelected: key => {
                if (!root.cardColors[root.selectedCardType]) {
                    root.cardColors[root.selectedCardType] = {};
                }
                root.cardColors[root.selectedCardType].separator = key;
                root.cardColorsChanged();
            }
        }

        NColorPicker {
            visible: root.cardColors[root.selectedCardType]?.separator === "custom"
            Layout.preferredWidth: Style.sliderWidth
            Layout.preferredHeight: Style.baseWidgetSize
            selectedColor: root.customColors[root.selectedCardType]?.separator || "#000000"
            onColorSelected: color => {
                if (!root.customColors[root.selectedCardType]) {
                    root.customColors[root.selectedCardType] = {};
                }
                root.customColors[root.selectedCardType].separator = color.toString();
                root.customColorsChanged();
            }
        }

        NComboBox {
            Layout.fillWidth: true
            label: "Foreground Color"
            description: "Title, icons and content text color"
            model: root.colorOptions
            currentKey: root.cardColors[root.selectedCardType]?.fg || "mOnSurface"
            onSelected: key => {
                if (!root.cardColors[root.selectedCardType]) {
                    root.cardColors[root.selectedCardType] = {};
                }
                root.cardColors[root.selectedCardType].fg = key;
                root.cardColorsChanged();
            }
        }

        NColorPicker {
            visible: root.cardColors[root.selectedCardType]?.fg === "custom"
            Layout.preferredWidth: Style.sliderWidth
            Layout.preferredHeight: Style.baseWidgetSize
            selectedColor: root.customColors[root.selectedCardType]?.fg || "#e9e4f0"
            onColorSelected: color => {
                if (!root.customColors[root.selectedCardType]) {
                    root.customColors[root.selectedCardType] = {};
                }
                root.customColors[root.selectedCardType].fg = color.toString();
                root.customColorsChanged();
            }
        }
    }

    // Reset button
    NButton {
        Layout.alignment: Qt.AlignRight
        text: "Reset to Defaults"
        icon: "refresh"
        onClicked: {
            root.cardColors = JSON.parse(JSON.stringify(root.defaultCardColors));
            root.customColors = {
                "Text": { bg: "#555555", separator: "#000000", fg: "#e9e4f0" },
                "Image": { bg: "#e0b7c9", separator: "#000000", fg: "#20161f" },
                "Link": { bg: "#c7a1d8", separator: "#000000", fg: "#1a151f" },
                "Code": { bg: "#a984c4", separator: "#000000", fg: "#f3edf7" },
                "Color": { bg: "#a984c4", separator: "#000000", fg: "#f3edf7" },
                "Emoji": { bg: "#e0b7c9", separator: "#000000", fg: "#20161f" },
                "File": { bg: "#e9899d", separator: "#000000", fg: "#1e1418" }
            };
        }
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("clipper", "Cannot save settings: pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.cardColors = JSON.parse(JSON.stringify(root.cardColors));
        pluginApi.pluginSettings.customColors = JSON.parse(JSON.stringify(root.customColors));
        pluginApi.saveSettings();

        Logger.i("clipper", "Settings saved successfully");
    }
}
