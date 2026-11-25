# Graybox Protocol — Asset Licenses

Everything third-party in this project is **CC0 1.0 (public domain)**: free for commercial
use, no attribution required. It is credited anyway — in-game (main menu → CREDITS) and here.
Level geometry is still built in code from primitives; the assets dress it.

| What | Source | License | Where | Used for |
|---|---|---|---|---|
| Car Kit, City Kit (Commercial / Industrial / Suburban), Retro Urban Kit, Survival Kit, Furniture Kit | [Kenney](https://kenney.nl) | CC0 | `assets/models/<kit>/` | cars, bins, skips, lamp posts, trees, furniture, skyline (`scripts/world/props.gd`, `sec_props_*`, `sec_skyline`) |
| Blaster Kit, WRAD ARMS | Kenney / wriks | CC0 | only in `art/viewmodel.blend`'s hidden OLD reference collection (r8) | the pre-r8 viewmodel, kept to compare against |
| Universal Base Characters [Standard], Universal Animation Library [Standard] | [Quaternius](https://quaternius.com) | CC0 | baked into `assets/models/people/person_{male,female}.glb` by `tools/blender/people.py` | every guard, civilian and the target (`scripts/world/humanoid.gd`) |
| Interface Sounds, Impact Sounds, Sci-Fi Sounds | [Kenney](https://kenney.nl) | CC0 | `assets/audio/{ui,impact,scifi}/` | menu clicks, footsteps, hits, PA chime, engine idles |
| Kenney Fonts (Future, Future Narrow, Mini Square Mono) | [Kenney](https://kenney.nl/assets/kenney-fonts) | CC0 | `assets/fonts/` | menu headings and buttons |
| asphalt_02, brick_wall_02, concrete_wall_008, concrete_floor_worn_001, concrete_pavement, metal_plate_02, corrugated_iron_02, plywood (1k diffuse + GL normal) | [Poly Haven](https://polyhaven.com) | CC0 | `assets/textures/` | surface materials (`scripts/world/surfaces.gd`) |

License texts: `assets/LICENSE-kenney.txt`, `assets/viewmodel/LICENSE-*.txt`.

## The viewmodel

Our own (r8): `art/viewmodel.blend` — a low-poly pistol (slide, frame, grip, guard,
sights, suppressor) and a gloved right arm, every part a separate bevelled box you can
edit. The eye is the origin looking down +Y. Run its `export_viewmodel.py` text block
(Text Editor, Alt+P) to write `assets/viewmodel/viewmodel_pistol.glb`. The game reads
the empties `gun`, `grip`, `muzzle`, `sight_rear`, `sight_front` from the GLB, so keep
them (and move them if you reshape the gun). Materials are used as authored. `art/` has
a `.gdignore` so Godot never tries to import the `.blend`.

## Our generated sounds (r8)

`assets/audio/gen/<name>_<n>.wav` are ours, synthesized by `tools/gen/make_sfx.py`
(numpy; gunshots, reloads, explosion, kick, grapple, night vision, eating, gibs...).
Re-run it to change them. A drop-in in `assets/audio/sfx/` still wins over these.

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
