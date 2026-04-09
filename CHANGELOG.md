# Changelog

## 1.0.0 - 2026-04-09

NascentSoul 1.0.0 establishes the current public shape of the plugin: `Zone` is now a real `Control`, runtime state is owned by `ZoneRuntime`, and presets/resources are the primary way to compose layout, interaction, sorting, permissions, and drag visuals.

### Highlights

- `Zone` now owns `ItemsRoot` and `PreviewRoot`, so zone scenes behave like native Godot UI instead of wrapper-based coordinators.
- Drag/drop behavior is more predictable across reorder, transfer, reject, preview, and animation handoff paths.
- Demo scenes were migrated to inspector-driven configuration and cleaned up as working examples instead of code-heavy setup scripts.
- Documentation was rewritten around value and architecture, with `README.md` as the single top-level entry point.
- The plugin package is now self-contained for clean installs: editor icons ship inside the addon, and optional README/example menu items only appear when those resources exist in the current project.

### Validation

- Headless editor plugin load passes on Godot 4.6.1.
- Runtime regression suite passes in the repository project.
- Clean-project install smoke passes by copying only `addons/nascentsoul` into a fresh Godot project and enabling the plugin.
