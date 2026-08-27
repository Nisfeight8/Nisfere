pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dndEnabled: false
    property FileView historyFile: FileView {
        blockLoading: true
        path: Quickshell.env("HOME") + "/.cache/nisfere/notifications.json"

        adapter: JsonAdapter {
            id: jsonAdapter

            property var savedNotifications: []
        }

        onAdapterUpdated: writeAdapter()
        onLoaded: {
            if (jsonAdapter.savedNotifications) {
                root.notifications = jsonAdapter.savedNotifications.map(n => {
                    n.rawObj = null;
                    return n;
                });
            }
        }
    }
    property var notifications: []
    property NotificationServer server: NotificationServer {
        actionsSupported: true

        onNotification: notification => {
            notification.tracked = true;
            const appName = notification.appName || "System";

            const existingIndex = root.findIndex(notification, appName);
            const timeToUse = (existingIndex >= 0) ? root.notifications[existingIndex].timeReceived : Qt.formatTime(new Date(), "HH:mm");

            const isCritical = notification.hints && notification.hints.urgency === 2;

            const notif = {
                notifId: notification.id,
                nAppName: appName,
                nAppIcon: notification.appIcon,
                nSummary: notification.summary,
                nBody: notification.body,
                nImage: notification.image,
                timeReceived: timeToUse,
                isCritical: isCritical,
                actions: notification.actions,
                rawObj: notification
            };

            if (existingIndex >= 0) {
                root.notifications[existingIndex] = notif;
            } else {
                root.notifications.unshift(notif);
            }

            root.notificationsChanged();
            root.saveHistory();

            if (!root.dndEnabled && !notification.lastGeneration) {
                root.showPopup(notif);
            }

            root.bindClose(notification, appName);
        }
    }

    signal showPopup(var notifData)

    function bindClose(notification, appName) {
        notification.closed.connect(() => {
            let index = root.findIndex(notification, appName);
            if (index >= 0) {
                root.notifications.splice(index, 1);
                root.notificationsChanged();
                root.saveHistory();
            }
        });
    }
    function clearAll() {
        root.notifications.forEach(item => {
            deleteNotif(item)
        });
        root.notifications = [];
        root.saveHistory();
    }
    function close(index) {
        let item = root.notifications[index];
        if (!item)
            return;

        dismissNotification(item)
    }


    function deleteNotif(notifData) {
        if (notifData.rawObj) {
            try {
                notifData.rawObj.dismiss();
            } catch (e) {
                console.log("OS Notification already destroyed, cleaning up local list...");
            }
        }
    }
    function dismissNotification(notifData) {
        deleteNotif(notifData)

        let idx = root.notifications.findIndex(n => n.notifId === notifData.notifId && n.nAppName === notifData.nAppName);
        if (idx >= 0) {
            root.notifications.splice(idx, 1);
            root.notificationsChanged();
            root.saveHistory();
        }
    }
    function findIndex(notification, appName) {
        let idx = root.notifications.findIndex(n => n.notifId === notification.id && n.nAppName === appName);
        if (idx >= 0)
            return idx;
        return root.notifications.findIndex(n => n.nAppName === appName && n.nSummary === notification.summary && n.nBody === notification.body);
    }
    function saveHistory() {
        const serializable = root.notifications.map(function (item) {
            return {
                notifId: item.notifId,
                nAppName: item.nAppName,
                nAppIcon: item.nAppIcon,
                nSummary: item.nSummary,
                nBody: item.nBody,
                nImage: item.nImage,
                timeReceived: item.timeReceived,
                isCritical:   item.isCritical
            };
        });

        jsonAdapter.savedNotifications = serializable;
    }
    function toggleDnd() {
        root.dndEnabled = !root.dndEnabled;
    }
}
