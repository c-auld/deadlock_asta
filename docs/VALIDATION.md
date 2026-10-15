# Survival-horror rework: validation

Tested locally on **2026-10-14**, using **Godot 4.7.2**, the Compatibility/OpenGL renderer, and an Apple M3 Max running macOS.

**Result: 68/68 integration checks passed in headless mode and 68/68 passed in an actual rendered game window.** The rendered run launched the project, executed the same gameplay interactions, and exited successfully. No script errors occurred in either completed test run.

These were automated engine-level playtests using injected keyboard/mouse events and actual physics frames, not a human free-play session. Isolated cases reposition actors or set resource counts to reach boundary conditions. The final avoidance route walks continuously from the normal spawn, with all three enemies active, and collects the actual key; it does not teleport, grant ammunition, or disable enemies.

## Interactions actually exercised

| System | What was tested | Method / outcome |
| --- | --- | --- |
| Start and movement | Enter starts the game; WASD movement, floor/wall collision, mouse yaw/pitch | Dispatched input and advanced real physics. Mouse sensitivity checked through the scaled viewport. |
| Shooting | Left click, ammunition use, hit detection, fire cooldown, empty trigger | Actual camera raycast reduced zombie health and spent a round. Rapid duplicate and empty shots were rejected. |
| Shooting feedback | Muzzle flash, recoil trigger, hit marker | Runtime feedback values were checked; handgun and HUD were also visually inspected in screenshots. |
| Occlusion | Shots and item interaction through walls | Bullets spent ammunition but did not hurt a zombie behind a wall; pickups behind a wall were inaccessible. |
| Reloading | R, empty reserves, partial magazines, insufficient reserve, firing during reload | Timed transfer preserved loaded rounds and never created ammunition. Reload blocked shooting. |
| Zombie damage/death | Four hits kill; collapse, disabled collision, interrupted attack | Health reached zero, corpse rotated to the floor, collision disabled, and an interrupted attack caused no damage. |
| Zombie detection/pursuit | Visible close target, blocked sight, local movement, retreat | Walls blocked detection; visible targets were pursued; retreat ended pursuit. |
| Zombie attack | Wind-up, close hit, recovery period, backing away | A landed attack removed 28 health. The wind-up and recovery prevented immediate repeated damage; moving away avoided the hit. |
| Player health/death | Damage effect, brief immunity, repeated enemy attacks, zero health | Four actual landed attacks caused defeat. Damage feedback activated; stacked immediate damage was rejected. Combat and movement stopped on defeat. |
| Inventory | Tab/I open/close, Escape close, displayed quantities, paused world and reload | Weapon, ammo, healing, and key labels reflected state. Time, enemy motion, and reload progress froze while open. |
| Healing | Collect kit, refuse full-health waste, use inventory button, consume once, clamp at 100 | E collected the item; H at full health preserved it. The focused Use button was activated with Enter after injury and restored health; it then became disabled. |
| Item collection | Ammo, first aid, brass key, repeated collection | Real E interactions added four reserve rounds, one kit, and the key. Pickups disappeared and could not be duplicated. |
| Locked exit | Physical blocking, no-key refusal, key collection, remote-use rejection | Collecting the key alone did not open the door. E at the exit consumed it and recorded its used state. |
| Door and victory | Opening motion, collision release, walking through | Pause froze opening. Once open, the player crossed the exit threshold and won; merely unlocking did not win. |
| Retry and menus | R after defeat, restored pickups/resources/enemies, title return | A fresh run restored health, six rounds, living zombies, pickups, and a locked door. |
| Full avoidance route | Spawn → Records → key → exit, all enemies active | Successfully escaped with all six starting rounds still loaded. Side-room entry/exit and the route around the old console were traversed using physics movement. |

## Visual checks

The rendered handgun/corridor, health/ammunition HUD, and inventory were inspected at 1280 × 720. Screenshots are included in this directory. The original low-resolution world, dim lamps, flashlight, fog, and restrained screen treatment remain in use.

The **humanoid zombie model update** was also checked on 2026-10-14: all **68 checks passed again in both headless and rendered runs**. Front, three-quarter walking, attack, and collapsed poses were rendered and visually inspected in the corridor. The new anatomy and animation live in `scripts/zombie_model.gd`; the original collision capsule, damage, attack timing, and pursuit rules are retained. See [the updated zombie preview](zombie.png).

On **2026-10-15**, the project was renamed to **deadlock_asta**. The renamed project launched in both headless and rendered modes; the title screen was captured and visually checked for text fit at 1280 × 720, and [title.png](title.png) was refreshed. The rendered capture exited successfully without errors. This naming-only change did not repeat the full gameplay suite; the previous 68/68 results above remain the latest full integration run.

## Not verified in this pass

- A human free-play/balance session, long-session comfort, and subjective sound mixing. Sound resources and playback code executed in the rendered run, but no listening-based assessment is claimed.
- Every possible approach, enemy crowding configuration, or doorway interaction. Navigation uses two authored doorway routes, not a general navigation mesh.
- Mouse-click activation of the inventory Use button: its actual GUI activation was tested using focus + Enter. Left mouse firing was tested independently.
- A continuous combat-and-looting route through Supplies. Ammo and first-aid collection and combat were tested as separate runtime interactions; the continuous end-to-end route used Records and avoided combat.
- Fullscreen switching, focus-loss behavior, sensitivity-slider interaction, and the steady-light toggle during this rework. These existing controls were retained; Escape pause/resume was tested.
- Other operating systems, Godot versions, export packages, or performance on lower-end hardware. No standalone build or controller support is included.

## Reproduce

Repository preparation was also checked on 2026-10-14: a fresh temporary copy containing only files selected by Git's ignore rules, without the existing `.godot/` cache, imported successfully and passed **68/68 headless integration checks**. Source assets, `.uid` files, and `.import` settings were included; generated caches and exports were excluded. This repository-only pass did not repeat rendered or human playtesting.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 60 --script tests/smoke_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --fixed-fps 60 --script tests/smoke_test.gd
```

For ordinary play, open `project.godot`, press F5, and start from the title screen. Test code is confined to `tests/smoke_test.gd`; the optional `--capture=... --view=inventory` / `--view=corridor` command-line modes stage screenshots, not normal gameplay.
