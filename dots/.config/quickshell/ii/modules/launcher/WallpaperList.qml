pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import qs.modules.common
import qs.services

// Carousel, faithful to caelestia-dots' WallpaperList: a PathView whose path is a
// flat line with a z "hump" in the middle so the centre card sits above its
// neighbours. Centre item is held in place via StrictlyEnforceRange.
PathView {
    id: root

    property string searchText: ""

    readonly property int itemWidth: 280 * 0.8 + Appearance.rounding.normal * 2

    readonly property int numItems: {
        const screen = (QsWindow.window as QsWindow)?.screen;
        if (!screen)
            return 0;

        const maxWidth = screen.width - Appearance.rounding.screenRounding * 4 - itemWidth * 2;
        if (maxWidth <= 0)
            return 1;

        const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
        const visible = Math.min(maxItemsOnScreen, count);

        if (visible === 2)
            return 1;
        if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return Math.max(visible, 1);
    }

    model: WallpapersCarousel.query(searchText)
    onSearchTextChanged: currentIndex = 0

    implicitWidth: Math.min(numItems, count) * itemWidth
    implicitHeight: 280 / 16 * 9 + Appearance.font.pixelSize.smaller + Appearance.rounding.normal * 3 + 8

    pathItemCount: numItems
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    onCurrentItemChanged: {
        const it = currentItem as WallpaperItem;
        if (it?.modelData?.path)
            WallpapersCarousel.preview(it.modelData.path);
    }
    Component.onDestruction: WallpapersCarousel.stopPreview()

    delegate: WallpaperItem {}

    path: Path {
        startY: root.height / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
    }
}
