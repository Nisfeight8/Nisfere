pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pam

Singleton {
    id: root
    signal unlocked
    signal failed(string errorMessage)

    property bool _isLocked: false
    property string _pendingPassword: ""

    property Timer restartTimer: Timer {
        id: restartTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (root._isLocked && !pamContext.active)
                pamContext.start();
        }
    }

    // Safety net: if PAM never becomes ready, don't leave the UI spinning forever
    property Timer readyTimeoutTimer: Timer {
        id: readyTimeoutTimer
        interval: 4000
        repeat: false
        onTriggered: {
            if (root._pendingPassword.length > 0) {
                root._pendingPassword = "";
                root.failed("Authentication timed out, try again");
            }
        }
    }

    property PamContext pam: PamContext {
        id: pamContext
        config: "login"

        onResponseRequiredChanged: {
            if (responseRequired && root._pendingPassword.length > 0) {
                readyTimeoutTimer.stop();
                const pwd = root._pendingPassword;
                root._pendingPassword = "";
                pamContext.respond(pwd);
            }
        }

        onPamMessage: {
            console.log("PAM MSG:", message, "| error:", messageIsError);
            if (messageIsError)
                root.failed(message);
        }
        onError: err => {
            console.log("PAM ERROR:", err);
            root._pendingPassword = "";
            readyTimeoutTimer.stop();
            root.failed("Authentication error");
            pamContext.abort();
            if (root._isLocked)
                restartTimer.restart();
        }
        onCompleted: result => {
            root._pendingPassword = "";
            readyTimeoutTimer.stop();
            if (result === PamResult.Success) {
                root.unlocked();
            } else if (result === PamResult.Failed) {
                root.failed("Wrong password");
                pamContext.abort();
                if (root._isLocked)
                    pamContext.start();
            } else if (result === PamResult.MaxTries) {
                root.failed("Too many failed attempts");
                pamContext.abort();
                if (root._isLocked)
                    restartTimer.restart();
            } else if (result === PamResult.Error) {
                root.failed("An authentication error occurred");
                pamContext.abort();
                if (root._isLocked)
                    restartTimer.restart();
            }
        }
    }

    function start() {
        _isLocked = true;
        if (!pamContext.active)
            pamContext.start();
    }

    function stop() {
        _isLocked = false;
        _pendingPassword = "";
        readyTimeoutTimer.stop();
        restartTimer.stop();
        if (pamContext.active)
            pamContext.abort();
    }

    function restart() {
        _isLocked = true;
        _pendingPassword = "";
        readyTimeoutTimer.stop();
        if (pamContext.active)
            pamContext.abort();
        restartTimer.start();
    }

    function authenticate(password) {
        if (password.length === 0)
            return;

        if (pamContext.responseRequired) {
            pamContext.respond(password);
        } else {
            console.log("PAM not ready yet — queuing password");
            _pendingPassword = password;
            readyTimeoutTimer.restart();
            if (!pamContext.active)
                pamContext.start();
        }
    }
}
