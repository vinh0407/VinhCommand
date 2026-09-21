# VinhCommand

Cross-platform IDE for Mobile and Desktop built with React Native/Expo and Tauri v2.

## Architecture

```
vinhcommand/
├── packages/                 # Shared packages (monorepo)
│   ├── shared/              # Types, API types, hooks, utilities
│   ├── ui-core/             # Headless UI components (React)
│   └── api-client/          # REST & WebSocket clients
├── apps/
│   ├── mobile/              # Expo/React Native app
│   └── desktop/             # Tauri v2 + React + Tailwind v4 app
└── pnpm-workspace.yaml      # pnpm workspace config
```

## Tech Stack

### Mobile (Expo/React Native)
- **Framework**: Expo Router v3 (file-based routing)
- **UI**: Custom components with React Native
- **State**: Zustand + React Context
- **Navigation**: Expo Router (tabs + stack)
- **Storage**: AsyncStorage

### Desktop (Tauri v2)
- **Framework**: Tauri v2 (Rust backend)
- **Frontend**: React 18 + TypeScript + Vite
- **Styling**: Tailwind CSS v4
- **Editor**: Monaco Editor
- **Terminal**: xterm.js
- **State**: Zustand + React Context
- **Routing**: React Router v6
- **Rust Plugins**: dialog, fs, shell, process, opener

### Shared
- **Language**: TypeScript
- **Build**: tsc
- **Linting**: oxlint
- **Package Manager**: pnpm 9+

## Getting Started

### Prerequisites
- Node.js 20+
- pnpm 9+
- Rust 1.75+ (for desktop)
- Android Studio / Xcode (for mobile)

### Installation

```bash
# Install all dependencies
pnpm install

# Install mobile dependencies
cd apps/mobile && pnpm install

# Install desktop dependencies
cd apps/desktop && pnpm install
```

### Development

```bash
# Start mobile app (Expo)
pnpm dev:mobile

# Start desktop app (Vite only)
pnpm dev:desktop

# Start desktop app with Tauri
pnpm dev:desktop:tauri
```

### Building

```bash
# Build mobile
pnpm build:mobile

# Build desktop (frontend only)
pnpm build:desktop

# Build desktop (Tauri bundle)
pnpm build:desktop:tauri
```

### Type Checking & Linting

```bash
# Type check all packages
pnpm typecheck

# Lint all packages
pnpm lint
```

## Project Structure Details

### packages/shared
Core types and utilities shared across platforms:
- `types/` - TypeScript interfaces (User, Project, FileNode, Terminal, Editor, AI, Git, etc.)
- `api/` - API response types, WebSocket event maps
- `hooks/` - React hooks (useLocalStorage, useDebounce, useMediaQuery, etc.)
- `utils/` - Utility functions (clsx, formatters, file helpers, etc.)

### packages/ui-core
Headless UI components (logic only, no platform-specific code):
- `Button`, `Input`, `Textarea`, `Card` components
- Hooks: `useKeyboardShortcuts`, `useCommandPalette`, `useToast`, etc.
- Context: `ThemeProvider`, `SettingsProvider`

### packages/api-client
API clients for backend communication:
- `RESTClient` - HTTP client with auth, CRUD methods for projects, files, terminal, git, AI
- `WebSocketClient` - Real-time communication for terminal output, file changes, AI messages

### apps/mobile
Expo Router app with tabs navigation:
```
app/
├── _layout.tsx           # Root layout with providers
├── (tabs)/
│   ├── _layout.tsx       # Tab navigator
│   ├── projects.tsx      # Projects list
│   ├── terminal.tsx      # Terminal emulator
│   ├── ai.tsx            # AI agents chat
│   └── settings.tsx      # Settings screen
src/
├── components/           # Mobile-specific components
├── screens/              # Screen components
├── hooks/                # Mobile hooks
├── context/              # Theme & Settings context
├── navigation/           # Navigation helpers
└── utils/                # Mobile utilities
```

### apps/desktop
Tauri v2 app with sidebar layout:
```
src/
├── main.tsx              # Entry point
├── App.tsx               # Router + layout
├── index.css             # Tailwind v4 imports
├── components/
│   ├── Layout.tsx        # Main layout with sidebar
│   ├── ProjectsView.tsx  # Projects dashboard
│   ├── EditorView.tsx    # Monaco editor + file tree
│   ├── TerminalView.tsx  # xterm.js terminal
│   ├── AIView.tsx        # AI chat interface
│   └── SettingsView.tsx  # Settings panels
├── context/
│   ├── ThemeContext.tsx  # Theme management
│   └── SettingsContext.tsx # Workspace settings
├── hooks/                # Desktop hooks
├── stores/               # Zustand stores
└── tauri/                # Tauri-specific code

src-tauri/
├── src/main.rs           # Rust entry point with commands
├── Cargo.toml            # Rust dependencies
├── tauri.conf.json       # Tauri configuration
└── icons/                # App icons
```

## Tauri Commands (Rust)

The desktop app exposes these commands to the frontend:

| Command | Description |
|---------|-------------|
| `greet(name)` | Test command |
| `get_app_version()` | Get app version |
| `open_external_url(url)` | Open URL in browser |
| `read_file(path)` | Read file content |
| `write_file(path, content)` | Write file |
| `list_dir(path)` | List directory entries |
| `create_dir(path)` | Create directory |
| `remove_file(path)` | Delete file |
| `run_command(cmd, args, cwd)` | Execute shell command |
| `get_env(key)` | Get environment variable |
| `set_env(key, value)` | Set environment variable |

## Environment Variables

Create `.env` files in each app:

```env
# apps/mobile/.env
EXPO_PUBLIC_API_URL=http://10.0.2.2:3000
EXPO_PUBLIC_WS_URL=ws://10.0.2.2:3000

# apps/desktop/.env
VITE_API_URL=http://localhost:3000
VITE_WS_URL=ws://localhost:3000
```

## Platform-Specific Notes

### Mobile (Android)
- Uses `10.0.2.2` to access host machine's localhost
- Configure `android:usesCleartextTraffic="true"` for HTTP in debug

### Mobile (iOS)
- Uses `localhost` directly
- Requires `NSAppTransportSecurity` for HTTP in debug

### Desktop
- Uses `localhost` directly
- Rust backend handles file system, process, shell access
- Titlebar overlay with custom window controls

## Contributing

1. Follow the existing code style
2. Run `pnpm typecheck` and `pnpm lint` before committing
3. Keep shared packages platform-agnostic
4. Platform-specific code goes in respective app directories

## License

MIT