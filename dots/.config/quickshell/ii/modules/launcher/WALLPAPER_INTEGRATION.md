# Wallpaper Selector Integration Guide

## Current Setup Status

✅ **Installed**:
- `WallpapersCarousel.qml` service ready in `~/.config/quickshell/ii/services/`
- `WallpaperList.qml` carousel view in this directory
- `WallpaperItem.qml` card component in `./items/`
- Test directory: `~/Pictures/Wallpapers/` with sample images

## How to Use

### Option 1: Direct IPC Call
Test the wallpaper selector with a direct command:

```bash
# List all available wallpapers
qs ipc -c ii call wallpaperCarousel list

# Set a specific wallpaper
qs ipc -c ii call wallpaperCarousel set "$HOME/Pictures/Wallpapers/random_wallpaper.png"
```

### Option 2: Integrate into Launcher (Advanced)

To add the wallpaper carousel to your launcher UI, you'd need to modify the launcher's content selection logic. This would allow typing `!wallpaper sunset` to browse and select wallpapers.

**Location**: The launcher components would go in `/etc/xdg/quickshell/caelestia/modules/launcher/` (system-wide caelestia install) or be overridden in your config.

## Setup Checklist

- [x] WallpapersCarousel service created
- [x] PathView carousel components created
- [x] Quickshell loads without errors
- [x] Service accessible via IPC
- [ ] Integrated into launcher UI (optional)
- [ ] Color preview on wallpaper selection (optional)
- [ ] Keyboard navigation in carousel (optional)

## Directory Layout

```
~/Pictures/Wallpapers/          ← Populate this with images
├── nature/
│   ├── sunset.jpg
│   ├── forest.png
│   └── ocean.webp
├── abstract/
│   ├── gradient.png
│   └── geometric.jpg
└── minimal/
    └── dark.png
```

Recursive scan means subdirectories are supported - they'll be shown in the filename/path.

## Customization Options

### 1. Change Wallpaper Directory
Edit `~/.config/quickshell/ii/services/WallpapersCarousel.qml` line 19:

```qml
readonly property string wallpapersDir: "/custom/path/to/wallpapers"
```

### 2. Adjust Carousel Item Size
Edit `WallpaperList.qml` line 10:

```qml
readonly property int itemWidth: 300  // pixels
```

### 3. Add More Image Formats
Edit `WallpapersCarousel.qml` line 65:

```qml
nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.svg", "*.gif"]
```

## Testing

### Quick Test - Service Response
```bash
# Check if service loads
qs log -c ii | grep -i "wallpaper"

# Test IPC connectivity
qs ipc -c ii call wallpaperCarousel list | head -5
```

### Full Test - Set Wallpaper
```bash
# Get first wallpaper path
FIRST=$(qs ipc -c ii call wallpaperCarousel list | head -1)

# Apply it
qs ipc -c ii call wallpaperCarousel set "$FIRST"
```

## Performance Notes

- **Scan Time**: Full recursive scan of `~/Pictures/Wallpapers` happens on service load (~100ms for typical setups)
- **Memory**: Caches entire wallpaper list in memory (negligible for <10k images)
- **Preview**: No color extraction in current version (can add via caelestia CLI if needed)

## Troubleshooting

### "WallpapersCarousel unavailable"
- Check quickshell logs: `qs log -c ii | tail -50`
- Verify service file exists: `ls ~/.config/quickshell/ii/services/WallpapersCarousel.qml`
- Reload shell: `qs kill -c ii && qs -c ii -d`

### "No wallpapers found"
- Check directory exists: `ls ~/Pictures/Wallpapers/`
- Add test images: `cp /usr/share/backgrounds/* ~/Pictures/Wallpapers/`
- Verify file permissions: `chmod 755 ~/Pictures/Wallpapers/`

### Wallpaper not changing
- Verify `Wallpapers.apply()` works manually: `~/omarchy/bin/switchwall.sh ~/Pictures/Wallpapers/test.png`
- Check if another service is overriding the wallpaper

## Related Services

- **Wallpapers.qml** - Existing service with thumbnail generation support
- **WallpaperSelector** - System UI component from caelestia package
- **Colours** - Could be enhanced to support dynamic color extraction from selected wallpaper

## Next Steps

1. **Populate `~/Pictures/Wallpapers/`** with your own images
2. **Test IPC calls** to verify everything works
3. **(Optional) Integrate into launcher** if you want the carousel UI in the main launcher
4. **(Optional) Add color extraction** for dynamic theming based on wallpaper
