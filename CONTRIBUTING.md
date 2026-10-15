# Working on DEADLOCK

## Setup

Clone the repository and open `project.godot` in Godot 4.7, using the Compatibility renderer. The project was tested with Godot 4.7.2 on macOS. Press **F5** to play. All required assets are included; there are no plugins or package dependencies to install.

Use tabs for GDScript and four spaces for Python. `.editorconfig` records these conventions, and `.gitattributes` keeps text files on LF line endings.

## Check changes

From the repository root:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --fixed-fps 60 --script tests/smoke_test.gd
```

The import step is required before testing a fresh checkout. On macOS, replace `godot` with `/Applications/Godot.app/Contents/MacOS/Godot` if needed.

For gameplay or visual changes, also run the checks in a rendered window and play the affected interactions:

```sh
godot --path . --fixed-fps 60 --script tests/smoke_test.gd
```

Record what was actually tested and any remaining gaps in [docs/VALIDATION.md](docs/VALIDATION.md). Keep the prototype small: one level, limited ammunition, simple enemies, and key-based escape.

## Files to commit

- Include scenes, scripts, shaders, source assets, Godot `.uid` files, and asset `.import` sidecars. Godot regenerates the cache inside `.godot/` after cloning.
- Keep the synthesized WAV files: they are runtime assets, so a fresh checkout can play immediately after import. Python 3 is only needed to regenerate them with `python3 assets/audio/generate_audio.py`.
- Put standalone exports in `build/` or `exports/` and temporary screenshots in `test-artifacts/`. These folders, caches, compiled binaries, local environments, and editor preferences are ignored.
- Keep credentials and signing keys local. If export presets are added, review them before committing; export credentials belong in Godot's ignored local configuration.
- Check `git status --short` and `git diff --cached` before committing to confirm the intended files are included.

Use original assets or assets with documented redistribution permission. Do not introduce paid assets or external services into the game.
