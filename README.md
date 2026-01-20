# Clipper

Advanced clipboard manager plugin for Noctalia Shell with history, search, filtering, and full keyboard navigation.

![Preview](Assets/preview.png)

## Features

### Clipboard Management
- **Clipboard History** - Stores and displays clipboard history using cliphist backend
- **Content Type Detection** - Automatically detects and categorizes content as Text, Image, Color, Link, Code, Emoji, or File
- **Image Preview** - Displays image thumbnails directly in cards
- **Color Preview** - Shows color swatches for hex/rgb color codes
- **Incognito Mode** - Temporarily disable clipboard tracking

### User Interface
- **Card-based Layout** - Each clipboard entry displayed as a styled card
- **Type-specific Coloring** - Different accent colors for each content type
- **Filter Buttons** - Quick filter by content type (All, Text, Image, Color, Link, Code, Emoji, File)
- **Search** - Full-text search through clipboard history
- **Selection Highlight** - Visual indication of currently selected card

### Keyboard Navigation
| Key | Action |
|-----|--------|
| `←` / `→` | Navigate between cards |
| `↑` | Focus search input |
| `↓` | Focus cards (from search) |
| `Enter` | Copy selected item and close panel |
| `Delete` | Delete selected item |
| `Tab` | Cycle to next filter |
| `Shift+Tab` | Cycle to previous filter |
| `0-7` | Direct filter selection (0=All, 1=Text, 2=Image, etc.) |
| `Escape` | Close panel |

### Customization

![Settings](Assets/settings.png)

- **Per-type Card Colors** - Customize background, separator, and foreground colors for each card type
- **Color Scheme Integration** - Choose from Noctalia color scheme or set custom hex colors
- **Live Preview** - See changes in real-time before applying
- **Reset to Defaults** - One-click restore of default color scheme

### IPC Commands
Control the plugin via command line:
```bash
# Open clipboard panel
qs ipc call plugin:clipper openPanel

# Close clipboard panel
qs ipc call plugin:clipper closePanel

# Toggle clipboard panel
qs ipc call plugin:clipper togglePanel
```

### Bar Widget
- Clipboard icon in the bar
- Click to open panel
- Right-click context menu with "Clear History" option
- Per-screen sizing support

## Installation

1. Clone this repository to your Noctalia plugins directory:
   ```bash
   git clone https://github.com/blackbartblues/noctalia-clipper.git ~/.config/noctalia/plugins/clipper
   ```

2. Enable the plugin in Noctalia settings

3. Ensure `cliphist` is installed on your system:
   ```bash
   # Arch Linux
   pacman -S cliphist

   # Or build from source
   go install go.senan.xyz/cliphist@latest
   ```

## Requirements

- Noctalia Shell >= 4.1.2
- cliphist (clipboard history manager)
- wl-clipboard (for Wayland clipboard access)

## License

MIT

## Authors

- blackbartblues
- rscipher001
