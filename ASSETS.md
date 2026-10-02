# Graybox Protocol — Asset Licenses

Everything third-party in this project is **CC0 1.0 (public domain)**: free for commercial
use, no attribution required. It is credited anyway — in-game (main menu → CREDITS) and here.
Level geometry is still built in code from primitives; the assets dress it.

| What | Source | License | Where | Used for |
|---|---|---|---|---|
| Car Kit, City Kit (Commercial / Industrial / Suburban), Retro Urban Kit, Survival Kit, Furniture Kit | [Kenney](https://kenney.nl) | CC0 | `assets/models/<kit>/` | cars, bins, skips, lamp posts, trees, furniture, skyline (`scripts/world/props.gd`, `sec_props_*`, `sec_skyline`) |
| Blaster Kit (`blaster-a`, `silencer-small`) | [Kenney](https://kenney.nl/assets/blaster-kit) | CC0 | baked into `assets/viewmodel/viewmodel_pistol.glb` | the Regular's pistol |
| WRAD ARMS | [wriks](https://wriks.itch.io/wrad-arms) | CC0 | baked into `assets/viewmodel/viewmodel_pistol.glb` | first-person hand |
| Interface Sounds, Impact Sounds, Sci-Fi Sounds | [Kenney](https://kenney.nl) | CC0 | `assets/audio/{ui,impact,scifi}/` | menu clicks, footsteps, hits, PA chime, engine idles |
| Kenney Fonts (Future, Future Narrow, Mini Square Mono) | [Kenney](https://kenney.nl/assets/kenney-fonts) | CC0 | `assets/fonts/` | menu headings and buttons |
| asphalt_02, brick_wall_02, concrete_wall_008, concrete_floor_worn_001, concrete_pavement, metal_plate_02, corrugated_iron_02, plywood (1k diffuse + GL normal) | [Poly Haven](https://polyhaven.com) | CC0 | `assets/textures/` | surface materials (`scripts/world/surfaces.gd`) |

License texts: `assets/LICENSE-kenney.txt`, `assets/viewmodel/LICENSE-*.txt`.

## The viewmodel

`assets/viewmodel/viewmodel_pistol.glb` is one static mesh: the WRAD right arm posed round
Kenney's `blaster-a` in Blender (fingers curled by script, grip fitted to the fist), the pose
baked, the left arm removed, exported with the eye at the origin looking down −Z. To re-pose
it, rebuild from the WRAD `.blend` — the gun's materials are overridden in
`scripts/player/viewmodel.gd` anyway.

## Sound drop-ins (e.g. a bought Gamemaster Audio pack)

`AudioSynth.play(node, "name")` looks for `res://assets/audio/sfx/<name>.ogg` (or `.wav`)
**first**, then the Kenney samples, then the original synthesized tone. To use a paid
library, copy its files into `assets/audio/sfx/` under these names — no code change:

`pistol` · `guard_shot` · `aim` · `hit` · `hurt` · `step` · `mantle` · `unlock` · `click` ·
`hover` · `back` · `confirm` · `pa_chime` · `alarm` · `win` · `lose` · `brass`

Gamemaster Audio is **not** free (packs from $19; the full Pro Sound Collection is $47,
royalty-free, no attribution) and its licence forbids redistributing the files — don't commit
a bought pack to a public repo. The "free download" mirrors for it are piracy.

## Synthesized / original

The original procedural SFX (`scripts/fx/audio_synth.gd`) remain the fallback for every name.
All code, level design and writing are original.

## Engine

Godot 4.7 (MIT).
