pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Carousel card. Mirrors caelestia-dots' WallpaperItem: scale/opacity driven by
// PathView position, elevation on the current item, label below the thumbnail.
Item {
    id: root

    required property var modelData

    readonly property real thumbWidth: 280
    readonly property real thumbHeight: thumbWidth / 16 * 9

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: thumbWidth + Appearance.rounding.normal * 2
    implicitHeight: thumbHeight + label.height + 8 + Appearance.rounding.normal * 2

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.modelData?.path)
                WallpapersCarousel.setWallpaper(root.modelData.path);
        }
    }

    // Elevation shadow for the focused/current item
    StyledRectangularShadow {
        target: image
        opacity: root.PathView.isCurrentItem ? 1 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    Rectangle {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Appearance.rounding.normal
        implicitWidth: root.thumbWidth
        implicitHeight: root.thumbHeight
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer2
        clip: true

        border.width: root.PathView.isCurrentItem ? 2 : 0
        border.color: Appearance.colors.colPrimary
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "image"
            iconSize: 56
            color: Appearance.colors.colOutline
        }

        Image {
            anchors.fill: parent
            source: root.modelData?.path ? `file://${root.modelData.path}` : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: !root.PathView.view.moving
            // Downscale at decode time so huge wallpapers stay cheap
            sourceSize.width: root.thumbWidth
            sourceSize.height: root.thumbHeight
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Appearance.rounding.normal * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.modelData?.relativePath ?? root.modelData?.name ?? ""
        color: Appearance.colors.colOnLayer0
        font.pixelSize: Appearance.font.pixelSize.smaller
    }

    Behavior on scale {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}
