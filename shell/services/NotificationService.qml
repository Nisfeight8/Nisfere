pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dndEnabled: false

    // ── Image cache (for notifications sent with raw pixmap data instead
    //    of a file path — e.g. anything using the image-data hint) ──────
    readonly property string imageCacheDir: Quickshell.env("HOME") + "/.cache/nisfere/notif-images"

    Process {
        command: ["mkdir", "-p", root.imageCacheDir]
        running: true
    }

    function deleteCachedImage(notifData) {
        if (!notifData || !notifData.nImage)
            return;
        const prefix = "file://" + root.imageCacheDir + "/";
        if (notifData.nImage.startsWith(prefix)) {
            const path = notifData.nImage.substring("file://".length);
            Quickshell.execDetached(["rm", "-f", path]);
        }
    }

    Component {
        id: imageCacherComp

        QtObject {
            id: cacher

            property string sourceUrl: ""
            property string cacheDir: ""
            property bool grabbed: false

            signal done(string path)

            property PanelWindow win: PanelWindow {
                implicitWidth: 128
                implicitHeight: 128
                color: "transparent"
                mask: Region {}
                visible: true

                Image {
                    id: img
                    width: 128
                    height: 128
                    asynchronous: true
                    cache: false
                    opacity: 0
                    source: cacher.sourceUrl

                    function tryGrab() {
                        if (cacher.grabbed)
                            return;
                        if (status === Image.Error) {
                            cacher.grabbed = true;
                            cacher.done("");
                            return;
                        }
                        if (status !== Image.Ready || width < 1 || height < 1)
                            return;

                        cacher.grabbed = true;
                        const fileName = cacher.cacheDir + "/" + Date.now() + "-" + Math.floor(Math.random() * 100000) + ".png";
                        grabToImage(function (result) {
                            const ok = result && result.saveToFile(fileName);
                            cacher.done(ok ? ("file://" + fileName) : "");
                        });
                    }

                    onStatusChanged: tryGrab()
                    onWidthChanged: tryGrab()
                    onHeightChanged: tryGrab()
                }
            }

            // Safety net: if for whatever reason we never manage to grab
            // (bad handle, window never maps, etc.) don't leave the
            // notification stuck waiting forever.
            property Timer giveUpTimer: Timer {
                interval: 800
                running: true
                onTriggered: {
                    if (!cacher.grabbed) {
                        cacher.grabbed = true;
                        cacher.done("");
                    }
                }
            }
        }
    }

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

            // Wire up close handling immediately so we don't miss a fast
            // close/replace that happens while an image is being cached.
            root.bindClose(notification, appName);

            const rawImage = notification.image;

            function finishNotification(resolvedImage) {
                const existingIndex = root.findIndex(notification, appName);
                const timeToUse = (existingIndex >= 0) ? root.notifications[existingIndex].timeReceived : Qt.formatTime(new Date(), "HH:mm");

                const isCritical = notification.hints && notification.hints.urgency === 2;

                if (existingIndex >= 0) {
                    // Replacing an existing notif — clean up its old cached
                    // image if it had a different one, so updates (e.g. a
                    // media player swapping album art) don't leak files.
                    const old = root.notifications[existingIndex];
                    if (old.nImage !== resolvedImage)
                        root.deleteCachedImage(old);
                }

                const notif = {
                    notifId: notification.id,
                    nAppName: appName,
                    nAppIcon: notification.appIcon,
                    nSummary: notification.summary,
                    nBody: notification.body,
                    nImage: resolvedImage,
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
            }

            if (rawImage && rawImage.startsWith("image://") && !rawImage.startsWith("image://icon/")) {
                // Raw pixmap handle (image-data hint) — bake it to a real
                // file before it can go stale, then proceed.
                const cacher = imageCacherComp.createObject(root, {
                    sourceUrl: rawImage,
                    cacheDir: root.imageCacheDir
                });
                cacher.done.connect(path => {
                    cacher.destroy();
                    finishNotification(path || rawImage);
                });
            } else {
                // Already a real path, or a stable themed-icon reference —
                // nothing to cache.
                finishNotification(rawImage);
            }
        }
    }

    signal showPopup(var notifData)

    function bindClose(notification, appName) {
        notification.closed.connect(() => {
            let index = root.findIndex(notification, appName);
            if (index >= 0) {
                root.deleteCachedImage(root.notifications[index]);
                root.notifications.splice(index, 1);
                root.notificationsChanged();
                root.saveHistory();
            }
        });
    }
    function clearAll() {
        root.notifications.forEach(item => {
            deleteNotif(item);
            root.deleteCachedImage(item);
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
            root.deleteCachedImage(root.notifications[idx]);
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