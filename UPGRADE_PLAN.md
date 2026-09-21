# VinhCommand upgrade

Primary implementation: Flutter Windows desktop + Kotlin Android companion.
The TypeScript alternative is retained without migrating user data.

## Verification-driven increments
- [x] Repair desktop repository contracts and persistent storage; replace obsolete counter test.
- [x] Repair terminal lifecycle and project/agent discovery UI.
- [x] Add authenticated LAN pairing and project API compatible with Android.
- [x] Connect Android configurable endpoint and session authentication.
- [x] Add accessible navigation, text scaling, keyboard actions and settings.
- [x] Run regression, integration, accessibility tests and Windows/Android builds where tools allow.

Baseline: Flutter analyzer reports 490 diagnostics, including 203 errors. Most
errors come from two obsolete repository implementations, not the domain model.
Source backup: backups/desktop-before-upgrade.zip.

