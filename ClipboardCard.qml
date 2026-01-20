import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Keyboard
import qs.Widgets

Rectangle {
    id: root
    focus: true
    property var clipboardItem: null
    property var pluginApi: null
    property string clipboardId: clipboardItem ? clipboardItem.id : ""
    property string mime: clipboardItem ? clipboardItem.mime : ""
    property string preview: clipboardItem ? clipboardItem.preview : ""

    // Content type detection
    readonly property bool isImage: clipboardItem && clipboardItem.isImage
    readonly property bool isColor: {
        if (isImage || !preview) return false;
        const trimmed = preview.trim();
        return /^#[A-Fa-f0-9]{6}$/.test(trimmed) || /^#[A-Fa-f0-9]{3}$/.test(trimmed) || /^[A-Fa-f0-9]{6}$/.test(trimmed) || /^rgba?\(.*\)$/i.test(trimmed);
    }
    readonly property bool isLink: !isImage && !isColor && preview && /^https?:\/\//.test(preview.trim())
    readonly property bool isCode: !isImage && !isColor && !isLink && preview && (preview.includes("function") || preview.includes("import ") || preview.includes("const ") || preview.includes("let ") || preview.includes("var ") || preview.includes("class ") || preview.includes("def ") || preview.includes("return ") || /^[\{\[\(<]/.test(preview.trim()))
    readonly property bool isEmoji: {
        if (isImage || isColor || isLink || isCode || !preview) return false;
        const trimmed = preview.trim();
        return trimmed.length <= 4 && trimmed.charCodeAt(0) > 255;
    }
    readonly property bool isFile: !isImage && !isColor && !isLink && !isCode && !isEmoji && preview && /^(\/|~|file:\/\/)/.test(preview.trim())
    readonly property bool isText: !isImage && !isColor && !isLink && !isCode && !isEmoji && !isFile

    // Helper to safely access Color singleton
    function getColor(propName, fallback) {
        if (typeof Color !== "undefined" && Color[propName]) return Color[propName];
        return fallback;
    }

    readonly property string colorValue: {
        if (!isColor || !preview) return "";
        const trimmed = preview.trim();
        if (/^#[A-Fa-f0-9]{3,6}$/.test(trimmed)) return trimmed;
        if (/^[A-Fa-f0-9]{6}$/.test(trimmed)) return "#" + trimmed;
        return trimmed;
    }

    readonly property string typeLabel: isImage ? "Image" : isColor ? "Color" : isLink ? "Link" : isCode ? "Code" : isEmoji ? "Emoji" : isFile ? "File" : "Text"
    readonly property string typeIcon: isImage ? "photo" : isColor ? "palette" : isLink ? "link" : isCode ? "code" : isEmoji ? "mood-smile" : isFile ? "file" : "align-left"

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

    // Get color setting for current card type
    function getCardColorSetting(colorType) {
        const settings = pluginApi?.pluginSettings?.cardColors;
        const customColors = pluginApi?.pluginSettings?.customColors;
        const cardType = typeLabel;

        if (settings && settings[cardType] && settings[cardType][colorType]) {
            const colorKey = settings[cardType][colorType];
            if (colorKey === "custom" && customColors && customColors[cardType]) {
                return customColors[cardType][colorType] || "#888888";
            }
            return getColor(colorKey, defaultCardColors[cardType]?.[colorType] || "#888888");
        }

        // Fallback to default
        const defaultKey = defaultCardColors[cardType]?.[colorType];
        return getColor(defaultKey, "#888888");
    }

    // Colors from settings or defaults
    readonly property color accentColor: getCardColorSetting("bg")
    readonly property color accentFgColor: getCardColorSetting("fg")
    readonly property color separatorColor: getCardColorSetting("separator")

    signal clicked
    signal deleteClicked
    property bool selected: false

    width: 250
    height: parent.height
    
    // Body background - Same as accent color
    color: selected ? Qt.darker(accentColor, 1.1) : (mouseArea.containsMouse ? Qt.lighter(accentColor, 1.1) : accentColor)
    
    radius: (typeof Style !== "undefined") ? Style.radiusM : 16
    border.width: 2
    border.color: accentColor // Border same as background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: headerBar
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            color: root.accentColor // Header same as background
            radius: (typeof Style !== "undefined") ? Style.radiusM : 16
            
            // Bottom square fix not needed if body has same color, but kept for structure
            Rectangle { 
                anchors.bottom: parent.bottom; 
                width: parent.width; 
                height: parent.radius; 
                color: parent.color 
            }

            RowLayout {
                id: headerContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 8
                spacing: 8
                NIcon { icon: root.typeIcon; pointSize: 13; color: root.accentFgColor }
                NText { text: root.typeLabel; color: root.accentFgColor; font.bold: true }
                Item { Layout.fillWidth: true }
                NIconButton {
                    icon: "trash"
                    colorFg: root.accentFgColor
                    colorBg: "transparent"
                    colorBgHover: Qt.rgba(0,0,0,0.1)
                    colorBorder: "transparent"
                    colorBorderHover: "transparent"
                    onClicked: root.deleteClicked()
                }
            }
            MouseArea { anchors.fill: parent; z: -1; onClicked: root.clicked() }
        }

        Rectangle {
            width: parent.width - 10
            Layout.alignment: Qt.AlignHCenter
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: root.separatorColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            clip: true
            MouseArea { id: mouseArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }

            Rectangle {
                visible: root.isColor
                anchors.fill: parent
                radius: 8
                color: root.colorValue || "transparent"
                border.width: 1
                border.color: root.accentFgColor // Use FG color for border contrast
            }

            NText {
                visible: !root.isColor && !root.isImage
                anchors.fill: parent
                text: root.preview || ""
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                color: root.accentFgColor // Text matches header text
                font.pointSize: 11
                anchors.topMargin: -50 // Adjusted to position text higher
            }

            NImageRounded {
                visible: root.isImage
                anchors.fill: parent
                radius: 8
                imageFillMode: Image.PreserveAspectFit
                imagePath: root.isImage ? (ClipboardService.getImageData(root.clipboardId) || "") : ""
                Component.onCompleted: { if (root.isImage && root.clipboardId) ClipboardService.decodeToDataUrl(root.clipboardId, root.mime, null); }
            }
        }
    }
}
