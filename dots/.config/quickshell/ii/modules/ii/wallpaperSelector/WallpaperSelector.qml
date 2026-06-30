pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../../launcher"

Scope {
    id: root

    Loader {
        active: GlobalStates.wallpaperSelectorOpen

        sourceComponent: PanelWindow {
            id: panel

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:wallpaperSelector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors { top: true; bottom: true; left: true; right: true }

            mask: Region { item: card }

            Component.onCompleted: GlobalFocusGrab.addDismissable(panel)
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panel)
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.wallpaperSelectorOpen = false;
                }
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: GlobalStates.wallpaperSelectorOpen = false

                // Card container, styled like the rest of the shell
                Rectangle {
                    id: card

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut

                    implicitWidth: Math.min(parent.width - Appearance.sizes.hyprlandGapsOut * 2, 1400)
                    implicitHeight: layout.implicitHeight + Appearance.rounding.normal * 2

                    radius: Appearance.rounding.windowRounding
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    StyledRectangularShadow { target: card }

                    ColumnLayout {
                        id: layout
                        anchors.fill: parent
                        anchors.margins: Appearance.rounding.normal
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            spacing: 8

                            MaterialSymbol {
                                text: "wallpaper"
                                iconSize: 26
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: "Wallpapers"
                                font.pixelSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                text: `${WallpapersCarousel.entries.length} found`
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }

                        // The carousel
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: carousel.implicitHeight

                            WallpaperList {
                                id: carousel
                                anchors.centerIn: parent
                                searchText: search.text
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: WallpapersCarousel.entries.length === 0
                                horizontalAlignment: Text.AlignHCenter
                                color: Appearance.colors.colSubtext
                                text: `No wallpapers found\nAdd images to ${WallpapersCarousel.wallpapersDir}`
                            }
                        }

                        MaterialTextField {
                            id: search
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            placeholderText: "Search wallpapers…"

                            Component.onCompleted: forceActiveFocus()

                            Keys.onEscapePressed: GlobalStates.wallpaperSelectorOpen = false
                            Keys.onLeftPressed: carousel.decrementCurrentIndex()
                            Keys.onRightPressed: carousel.incrementCurrentIndex()
                            Keys.onReturnPressed: {
                                const it = carousel.currentItem;
                                if (it?.modelData?.path) {
                                    WallpapersCarousel.setWallpaper(it.modelData.path);
                                    GlobalStates.wallpaperSelectorOpen = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function toggle() {
        GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen;
    }

    IpcHandler {
        target: "wallpaperSelector"

        function toggle(): void { root.toggle() }
        function show(): void { GlobalStates.wallpaperSelectorOpen = true }
        function hide(): void { GlobalStates.wallpaperSelectorOpen = false }
    }
}
