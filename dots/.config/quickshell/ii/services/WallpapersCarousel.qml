pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Models
import qs.modules.common
import qs.modules.common.functions
import qs.services

/**
 * Carousel-style wallpaper service, faithful to caelestia-dots' design.
 * Uses the real Caelestia.Models.FileSystemModel (recursive, image-filtered,
 * watches for changes) and renders through illogical-impulse's design system.
 */
Singleton {
    id: root

    readonly property string wallpapersDir: `${FileUtils.trimFileProtocol(Directories.pictures)}/Wallpapers`

    // Live list of FileSystemEntry { path, relativePath, name, baseName, isImage, ... }
    readonly property var entries: model.entries

    property string previewPath: ""
    property bool showPreview: false

    function setWallpaper(path: string): void {
        if (!path || path.length === 0)
            return;
        Wallpapers.apply(path);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;
    }

    function stopPreview(): void {
        showPreview = false;
    }

    // Substring filter over relativePath, matching the original's behaviour
    function query(search: string): var {
        if (!search || search.length === 0)
            return model.entries;
        const needle = search.toLowerCase();
        return model.entries.filter(e => (e.relativePath ?? e.name ?? "").toLowerCase().includes(needle));
    }

    FileSystemModel {
        id: model
        path: root.wallpapersDir
        recursive: true
        watchChanges: true
        filter: FileSystemModel.Images
    }

    IpcHandler {
        target: "wallpaperCarousel"

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.entries.map(e => e.path).join("\n");
        }
    }
}
