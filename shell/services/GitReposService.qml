pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Discovers git repos under $HOME by finding ".git" directories — same
// general Process + StdioCollector pattern as FileSearchService.
// ".git" is a rare, specific directory name (unlike a broad file-search
// substring), so a plain unbounded `find` here is fast enough in
// practice without needing the timeout/head-capping machinery that
// broad file search needed.
Singleton {
    id: root

    property var repos: []  // [{ path, name }]

    property Process _searchProc: Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim() !== "");
                // Each line is a ".git" directory itself — the actual
                // repo root is its parent.
                root.repos = lines.map(gitDir => {
                    const repoPath = gitDir.replace(/\/\.git$/, "");
                    const parts = repoPath.split("/").filter(p => p !== "");
                    return {
                        path: repoPath,
                        name: parts.length > 0 ? parts[parts.length - 1] : repoPath
                    };
                });
            }
        }
    }

    function refresh() {
        if (root._searchProc.running)
            root._searchProc.running = false;
        // Two fixes over a naive "-type d -name .git":
        //   1. No -type restriction — submodules/worktrees have a
        //      ".git" FILE (a text pointer like "gitdir: ../.git/
        //      modules/...", not a directory), which -type d silently
        //      excluded entirely.
        //   2. "-name '.git' -prune -print" (chained, not separate)
        //      both prints the match AND stops find from recursing
        //      INTO it afterward — previously find kept scanning every
        //      repo's internal .git object store for nothing, wasted
        //      work that only grows with repo history size.
        root._searchProc.command = ["sh", "-c", "find ~/ -maxdepth 6 \\( -path '*/.cache' -o -path '*/node_modules' -o -path '*/.local/share/Trash' \\) -prune -o -name '.git' -prune -print 2>/dev/null"];
        root._searchProc.running = true;
    }

    Component.onCompleted: refresh()
}
