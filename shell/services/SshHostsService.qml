pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Read-only parser for ~/.ssh/config's "Host" blocks. Deliberately
// read-only for now (see chat) — rewriting a hand-edited SSH config
// safely (preserving comments, ProxyJump/IdentityFile/Include
// directives, formatting) is a genuinely different, riskier problem
// than just reading it; add/edit/remove is a considered future step,
// not this one.
Singleton {
    id: root

    property var hosts: []  // [{ alias, hostName, user, port }]

    property FileView _configFile: FileView {
        id: configFile
        path: Quickshell.env("HOME") + "/.ssh/config"
        blockLoading: true
        watchChanges: true

        onLoaded: root._parse(text())
        onLoadFailed: root.hosts = []
        onFileChanged: reload()
    }

    function _parse(content) {
        const lines = content.split("\n");
        const parsed = [];
        let current = null;

        for (const rawLine of lines) {
            const line = rawLine.trim();
            if (line === "" || line.startsWith("#"))
                continue;

            // OpenSSH's ssh_config accepts BOTH "Key value" and
            // "Key=value" as valid syntax — this was only matching
            // whitespace, silently dropping (skipping entirely) any
            // line written with "=", which meant User/Port/HostName
            // written that way just vanished with no error, easy to
            // mistake for "not picking up the right user/port" even
            // though the real `ssh <alias>` connection itself reads
            // the actual config file directly and doesn't go through
            // this parse at all — only the displayed subtitle here
            // does.
            const match = line.match(/^(\S+)[\s=]+(.*)$/);
            if (!match)
                continue;
            const key = match[1].toLowerCase();
            const value = match[2].trim();

            if (key === "host") {
                // A "Host" line can list multiple space-separated
                // patterns — skip wildcard-only entries (e.g. "Host *",
                // used for shared defaults, not an actual server) since
                // they're not something you'd ever want to connect to
                // directly.
                const aliases = value.split(/\s+/).filter(a => a.indexOf("*") === -1 && a.indexOf("?") === -1);
                if (aliases.length === 0) {
                    current = null;
                    continue;
                }
                current = {
                    alias: aliases[0],
                    hostName: "",
                    user: "",
                    port: ""
                };
                parsed.push(current);
            } else if (current) {
                if (key === "hostname")
                    current.hostName = value;
                else if (key === "user")
                    current.user = value;
                else if (key === "port")
                    current.port = value;
            }
        }

        root.hosts = parsed;
    }
}
