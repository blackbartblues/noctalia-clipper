import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
    property var pluginApi: null

    IpcHandler {
        target: "plugin:clipper"

        function openPanel() {
            if (pluginApi) {
                // Get the first available screen
                const screens = Quickshell.screens;
                if (screens && screens.length > 0) {
                    pluginApi.openPanel(screens[0]);
                }
            }
        }

        function closePanel() {
            if (pluginApi) {
                const screens = Quickshell.screens;
                if (screens && screens.length > 0) {
                    pluginApi.closePanel(screens[0]);
                }
            }
        }

        function togglePanel() {
            if (pluginApi) {
                const screens = Quickshell.screens;
                if (screens && screens.length > 0) {
                    pluginApi.togglePanel(screens[0]);
                }
            }
        }

        function setMessage(message: string) {
            if (pluginApi && message) {
                pluginApi.pluginSettings.message = message;
                pluginApi.saveSettings();
                ToastService.showNotice("Message updated to: " + message);
            }
        }
    }
}
