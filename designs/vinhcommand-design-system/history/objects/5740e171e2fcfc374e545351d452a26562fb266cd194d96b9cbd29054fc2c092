# VinhCommand Design System

The official design system and visual specification for VinhCommand Studio (Windows Desktop) and VinhCommand Companion (Android Native).

---

## 1. Design Philosophy & Core Principles

VinhCommand is built for high-performance software developers who command their local machine from desktop or mobile with zero friction. The interface prioritizes density, exactness, and low latency over decorative fluff.

* **Terminal-First Precision**: Monospace typography (`font-mono`) is elevated to a primary structural element. Data, paths, commands, and code diffs are rendered with crisp contrast against deep studio surfaces.
* **Zero Emoji Standard**: All visual statuses, actions, and tree nodes utilize unambiguous, high-legibility textual badges such as `[RUN]`, `[OK]`, `[DIR]`, `[FILE]`, `[CMD]`, and `[START]`. This guarantees cross-platform rendering consistency on every operating system, terminal, and DPI scale.
* **Dual-Mode Process Control**: UI controls always clarify whether a process runs headless in the background (`[Chạy nền]`) or in an interactive, native UTF-8 console window (`[Mở CMD]`).
* **Unified Master Task Context**: AI interactions are scoped strictly to one Master Task per project, presenting prompt inputs, reasoning streams, and file modifications in a single coherent flow.

---

## 2. Color Palette & Theming

VinhCommand uses a high-contrast Studio Dark default theme with precise color coding for process lifecycle and code entities:

| Token Name | Studio Dark | Studio Light | Intent & Usage |
| :--- | :--- | :--- | :--- |
| `surface` | `#121417` | `#F8FAFC` | Deep root application background canvas. |
| `surface-raised` | `#1B1E23` | `#FFFFFF` | Panels, toolbars, and primary container cards. |
| `surface-code` | `#1E1E1E` | `#F1F5F9` | VS Code dark code editor and terminal stream viewports. |
| `surface-overlay`| `#252526` | `#E2E8F0` | Dialog sheets, context menus, and navigation drawers. |
| `line` | `#2D3139` | `#CBD5E1` | Standard 1px hairlines and container borders. |
| `ink` | `#E2E4E9` | `#0F172A` | Primary text copy, headings, and active code lines. |
| `ink-muted` | `#9EA4B0` | `#64748B` | Secondary metadata, inactive tabs, and timestamps. |
| `brand-primary` | `#4ADE80` | `#16A34A` | Active runner indicator, success state, connected ping. |
| `brand-blue` | `#38BDF8` | `#0284C7` | Web preview links, network IP status, active outline. |
| `brand-vsblue` | `#007ACC` | `#0066B8` | Primary save actions, active file tab, VS Code accent. |
| `accent-amber` | `#FACC15` | `#D97706` | Script console execution, interactive CMD badge, warning. |
| `accent-danger` | `#EF4444` | `#DC2626` | Process termination, connection failure, destructive actions. |

---

## 3. Typography Hierarchy

The type system blends a robust sans-serif for interface navigation with high-legibility monospace fonts for computational contexts:

### UI Interface (`Inter`, `system-ui`, `-apple-system`, `sans-serif`)
* **Title Large** (`20px` / `28px` / `700`): Workspace names, modal headers, major section titles.
* **Title Medium** (`16px` / `24px` / `600`): Card headers, dialog titles, companion bar labels.
* **Body Regular** (`14px` / `20px` / `400`): General explanations, form inputs, status descriptions.
* **Caption** (`12px` / `16px` / `500`): Port numbers, timestamps, subsidiary metadata.

### Code & Console (`JetBrains Mono`, `Consolas`, `monospace`)
* **Code Editor** (`13px` / `20px` / `400`): Source code canvas, syntax diffs, file path breadcrumbs.
* **Terminal Output** (`12px` / `18px` / `400`): Streaming stdout/stderr console logs, build outputs.
* **Textual Badge** (`11px` / `14px` / `700`): Status pills `[RUN]`, `[OK]`, `[DIR]`, `[FILE]`.

---

## 4. Components & Interactive Patterns

### 4.1. Dual Runner Buttons
When executing project scripts, runners provide two explicit options:
1. **Background Runner Button (`brand-primary` / outline)**: Starts the daemon headlessly, piping stdout/stderr into the log drawer.
2. **Interactive CMD Button (`accent-amber` / outline)**: Dispatches `cmd.exe /k "chcp 65001 && <command>"` to open a visible, interactive console window on Windows.

### 4.2. File Tree Nodes
Directory entries are identified by `[DIR]` in `brand-primary` monospace, while file items are tagged with `[FILE]` and syntax color coding based on extension (`.dart`, `.py`, `.ts`, `.json`, `.kt`).

### 4.3. Bi-directional Save Button
The active file canvas displays a prominent save button:
* Dirty state: `[LƯU LÊN PC *]` with `brand-vsblue` fill and pulse indicator.
* Synchronized state: `[ĐÃ LƯU TRÊN PC]` with `brand-primary` outline.
