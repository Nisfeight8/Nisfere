pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var tasks: []   // [{id, text, done}]

    property FileView _store: FileView {
        path: Quickshell.env("HOME") + "/.cache/nisfere/tasks.json"
        blockLoading: true

        adapter: JsonAdapter {
            id: jsonAdapter
            property var savedTasks: []
        }

        onAdapterUpdated: writeAdapter()
        onLoaded: {
            if (jsonAdapter.savedTasks)
                root.tasks = jsonAdapter.savedTasks;
        }
        onLoadFailed: root.tasks = []
    }

    function _save() {
        jsonAdapter.savedTasks = root.tasks;
    }

    function addTask(text) {
        const trimmed = text.trim();
        if (!trimmed) return;
        root.tasks = [...root.tasks, {
            id:   Date.now().toString(),
            text: trimmed,
            done: false
        }];
        _save();
    }

    function toggleTask(id) {
        root.tasks = root.tasks.map(t =>
            t.id === id ? Object.assign({}, t, { done: !t.done }) : t
        );
        _save();
    }

    function removeTask(id) {
        root.tasks = root.tasks.filter(t => t.id !== id);
        _save();
    }

    function clearCompleted() {
        root.tasks = root.tasks.filter(t => !t.done);
        _save();
    }

    readonly property int remainingCount: tasks.filter(t => !t.done).length
    readonly property int completedCount: tasks.filter(t => t.done).length
}
