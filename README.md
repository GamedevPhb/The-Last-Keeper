# The Last Keeper

**English** · [Português (BR)](README.pt-BR.md)

> A first-person survival-management game with atmospheric horror and a PS1 look, made with Godot 4.

You are the only keeper of Lighthouse 7, on a rocky island at the end of the shipping lane. Every night you must keep the light burning, the generator running and the radio tuned. The ships out there depend on you — but not every ship calling on the radio should be there.

**Status:** pre-alpha. The technical foundation is done; the first playable demo is planned for January 2027.

---

## Features (so far)

- **PS1 rendering:** native 320×240, vertex jitter, affine texture warping, 15-bit color with ordered dithering, heavy fog
- **First-person controller:** walking, sprinting, mouse look
- **Interaction system:** press or hold actions, with an on-screen prompt and progress bar
- **Greybox island:** lighthouse with a spiral ramp up to the lantern room, keeper's house, generator shed, pier
- **Rotating lighthouse beam** that you can switch on and off

## Requirements

- [Godot 4.7+](https://godotengine.org/download) (standard or .NET build)
- A GPU with OpenGL 3.3 support (the project uses the Compatibility renderer)

## Running

1. Clone the repository.
2. Open Godot, click **Import** and select `project.godot`.
3. Press **F5**.

Or from the terminal:

```bash
godot --path .
```

## Controls

| Action | Key |
|---|---|
| Move | W A S D |
| Look | Mouse |
| Sprint | Shift |
| Interact (press or hold) | E |
| Release the mouse | Esc (click to capture it again) |

## Tests

A headless smoke test climbs the lighthouse and switches the lamp through the interaction system:

```bash
godot --headless --path . --script res://tests/smoke_test.gd
```

## Tweaking the PS1 effect

Under **Project → Project Settings → Shader Globals**:

| Global | Effect |
|---|---|
| `psx_vertex_snap` | Vertex jitter grid size in pixels (`0` turns it off) |
| `psx_affine_strength` | Texture warping, from `0` (correct) to `1` (full PS1) |

Color depth and dithering are set on the `PsxPost/Filter` node in `main.tscn`.

## Project structure

```
docs/          GDD and development plan (in Portuguese)
interaction/   Interactable component
materials/     Greybox materials
player/        First-person player
shaders/       PS1 shaders (lit, water, post-processing)
tests/         Headless smoke test
ui/            HUD
world/         Island, lighthouse, spiral ramp, beacon
main.tscn      Main scene
```

## Documentation

- [Game Design Document](docs/GDD.md)
- [Development plan](docs/PLANO.md)
- [Sprints to launch](docs/SPRINTS.md)

## License

Source code: [MIT](LICENSE). Art, narrative and other creative assets: [CC BY-NC 4.0](LICENSE-ASSETS.md). Names and logos are not covered by either license.
