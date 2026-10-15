# deadlock_asta

The Astra version of a game-building experiment comparing Astra and Opus using the same prompts. Repository: [c-auld/deadlock_asta](https://github.com/c-auld/deadlock_asta).

A small PS1-inspired **first-person survival-horror prototype** in Godot. Explore the service corridor and two side rooms, conserve handgun ammunition, manage wounds, find the brass key, and unlock the exit. The original movement, low-resolution renderer, corridor, and atmospheric audio are reused.

The former timed chase and programming puzzle have been replaced with local encounters and key-based exploration. No crafting, upgrades, additional levels, plugins, services, or paid assets.

![Survival gameplay](docs/survival-gameplay.png)

The zombies have faceted human proportions, hollow eye sockets, a slack jaw, ragged uniforms, articulated fingers, and an uneven gait. [Zombie close-up](docs/zombie.png).

## Play

Open `project.godot` in **Godot 4.7** and press **F5**. This version was tested with Godot **4.7.2**, Compatibility renderer, on macOS. No installation or asset downloads are required.

| Control | Action |
| --- | --- |
| WASD / ZQSD | Move |
| Mouse / arrow keys | Look |
| Shift | Run |
| Left mouse / Space | Fire one pistol round |
| R | Reload; retry on the ending screen |
| E | Collect the item you are facing / use the key at the exit |
| Tab / I | Open or close inventory |
| H / inventory Use button | Use first aid |
| Escape | Pause / resume; close inventory |
| M | Mute / unmute |
| F11 | Fullscreen |

Inventory pauses simulation, including attacks and reloading. It shows the equipped handgun, magazine, spare rounds, first-aid kit, and key status. Healing at full health does not consume the kit. The pause menu retains mouse sensitivity and steady-light controls. Losing window focus pauses gameplay.

![Inventory](docs/inventory.png)

## Small survival loop

- Start with **100 health** and a **six-round pistol**, with no spare ammunition.
- Search **Supplies**, the first open room on the left, for **four spare rounds** and **one first-aid kit**. The kit restores up to **50 health**.
- Search **Records**, the open room on the right farther down the corridor, for the **brass exit key**.
- Face the locked exit at the far end and press **E** to use the key, then **walk through the opening** to win. The old terminal remains a powerless environmental prop.
- Three slow zombies detect nearby visible players or nearby gunfire. They pursue locally, telegraph close attacks, and return home when you get far enough away or break sight. Retreating and going around them are viable.
- Each zombie takes **four pistol hits**. The level contains **ten rounds total**, so there is insufficient ammunition to kill all three. A missed shot costs a round too.
- Attacks deal **28 damage**, with a wind-up, recovery, and brief player damage immunity. Reaching zero health ends the run. Dead zombies collapse and cannot attack or block the route.

The pistol is semiautomatic, has a firing cooldown, and uses a **1.65-second reload**. Reloading retains rounds already in the magazine and transfers only what is available in reserve. Bullets and interactions are blocked by walls. Gunfire has recoil, muzzle light, a synthesized report, and hit feedback; wounds produce a red screen effect and low-health heartbeat.

## Verification

See **[docs/VALIDATION.md](docs/VALIDATION.md)** for the tested interactions, methods, and remaining limitations.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --fixed-fps 60 --script tests/smoke_test.gd
# Run the same integration checks in a rendered game window:
godot --path . --fixed-fps 60 --script tests/smoke_test.gd
```

On macOS, use `/Applications/Godot.app/Contents/MacOS/Godot` if `godot` is not on your PATH. The tests use actual game physics and input dispatch. Isolated boundary checks reposition actors or set resource counts; the final avoidance route uses continuous movement, real pickups, and all enemies active.

## Source

- `scripts/game.gd`: input, hitscan combat, interactions, menus, progression, and endings.
- `scripts/survival_state.gd`: health, ammunition, reload timing, and consumable state.
- `scripts/player.gd`: preserved movement and camera, procedural handgun and firing/reload feedback.
- `scripts/zombie.gd`: detection, local pursuit, attack timing, damage, and death.
- `scripts/zombie_model.gd`: faceted humanoid anatomy, gaunt face, ragged clothing, articulated hands, and an uneven gait. Visual changes retain the existing enemy collision and combat rules.
- `scripts/corridor.gd`: reused corridor, side rooms, simple doorway routing, and exit machinery.
- `scripts/pickup.gd`: collectible ammunition, first aid, and key.
- `scripts/interface.gd`: HUD, four-slot inventory, and menus.
- `shaders/retro.gdshader`: original 480 × 270 presentation, quantization, grain, and damage feedback.

All art uses simple Godot geometry and procedural textures. Original synthesized audio is included; regenerate it with `python3 assets/audio/generate_audio.py`. There is no save system, weapon selection, advanced enemy navigation, or export package.

## Repository

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, checks, and file conventions. Godot caches, compiled builds, local editor settings, and credentials are ignored. Source assets and Godot `.uid` / `.import` sidecars are included so the project can be imported from a fresh clone.
