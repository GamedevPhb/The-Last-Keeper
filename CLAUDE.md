# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projeto

*The Last Keeper*: survival/gestão em primeira pessoa com terror atmosférico e visual PS1, em Godot 4.7 (GDScript, renderer GL Compatibility, física Jolt). Pré-alpha; meta é uma demo de uma noite (ver `docs/PLANO.md`). O design vive em `docs/GDD.md` (pilares, mecânicas, MVP) e o cronograma semanal em `docs/PLANO.md` — ambos em português; consulte-os antes de propor mecânicas ou level design. Comentários e strings de UI do código misturam inglês e português.

## Comandos

Não há build nem lint. O binário do Godot pode se chamar `godot`, `godot-4` ou vir do snap.

```bash
godot --path .                                                    # rodar o jogo (abre o menu principal; main.tscn é a partida)
godot --path . --editor                                           # abrir o editor
godot --headless --path . --script res://tests/smoke_test.gd     # sobe o farol e acende/apaga a lâmpada pela interação
godot --headless --path . --script res://tests/puzzle_test.gd    # lógica dos puzzles: lâmpada, gerador, disjuntores, cadeado
```

Os testes são `SceneTree` customizados (não usa GdUnit): instancia `main.tscn`, simula input com `Input.action_press` e sai com código de erro em falha/timeout (60 s). Ele depende de caminhos de nó (`Island/Lighthouse/Beacon`) e das constantes da rampa (`TOWER_CENTER`, `RAMP_RADIUS`, `TOP_FLOOR`); mudou a geometria do farol → atualize o teste.

## Arquitetura

- **Cena principal** `main.tscn`: `Island` (instância de `world/island.tscn`), `Player`, `Hud`, ambiente/lua e o `PsxPost/Filter` (ColorRect em CanvasLayer 5 com `psx_post.gdshader`, que faz dithering e profundidade de cor 15-bit). Fog e cores da noite ficam no `Environment` embutido em `main.tscn`.
- **Render PS1**: viewport nativa 320×240 com stretch `viewport` + escala inteira (janela 960×720). Os shaders em `shaders/` incluem `psx_common.gdshaderinc`, cujas intensidades vêm de *shader globals* do projeto (`psx_vertex_snap`, `psx_affine_strength`), editáveis em Project Settings → Shader Globals ou em runtime. Materiais novos devem usar `psx_lit.gdshader` (ou `psx_water`) para manter o visual; `materials/` guarda os `.tres` do greybox.
- **Interação (desacoplada)**: `Interactable` (`interaction/interactable.gd`, `Area3D`) expõe `prompt`, `hold_time` (0 = aperto instantâneo), `enabled` e o sinal `interacted`. O `Player` dispara um `RayCast3D` e gerencia foco e progresso de segurar (sinais `focus_changed` / `hold_progress_changed`), que o `Hud` consome. Objetos do mundo (ex.: `Beacon`) apenas possuem um `Interactable` filho e conectam `interacted` — nunca fazem input próprio.
- **Camadas de física** (nomeadas em `project.godot`): 1 `world`, 2 `player`, 3 `interact`. O raio do jogador mascara world + interact, então paredes bloqueiam interação. `Interactable.LAYER` fixa a camada 3 no `_init`.
- **Input actions**: `move_forward/back/left/right`, `sprint`, `interact` (WASD, Shift, E). Mouse look usa `screen_relative` para ignorar o stretch 320×240.
- **Mundo**: `world/island.tscn` (ilha, farol, casa, galpão, píer) com `spiral_ramp.gd` gerando a rampa em espiral até a sala da lanterna, e `beacon.gd` (lâmpada giratória; placeholder do sistema completo de óleo/corda/lente do GDD).

- **Puzzles** (`puzzles/`, estado em `game_state.gd`, autoload `GameState`): itens carregados, energia (gerador + 3 disjuntores, capacidade 2) e `say()` para mensagens no HUD. `Interactable.create()` monta interativos por código. Lâmpada (`world/beacon.gd`): partida a frio em ordem óleo → corda → lente, ordem errada emperra. `generator.gd` (válvulas na ordem do livro de registros no `radio.gd`), `fuse_box.gd`, `radio.gd` (um navio a cada três mente sobre a carga), `cellar_lock.gd` (código 8-3-5 nas pistas `Clue`), `tide.gd` (pedras do ilhéu sobem e descem) e `oil_drum.gd`. Os pontos das estações são `Marker3D` em `world/island_details.tscn`.
- **UI e progressão**: `ui/hud.gd` mostra objetivo (`GameState.objective()`, derivado de flags), rumo e mensagens; `ui/overlay.gd` (criado em código) cobre pausa (Esc), inventário (Tab) e o livro (J, aberto pelo `Logbook` do rádio via `GameState.book_requested`). O jogador nasce no píer, perto do baú (`puzzles/chest.gd`) com lanterna, óleo e combustível.
- **Relógio e dificuldade**: `GameState` conta de 17:30 a 06:00 (1,2 s reais por minuto de jogo, 15 min); `progress()` aumenta consumo de óleo/combustível e a frequência de navios mentirosos; `world/day_night.gd` leva o céu do crepúsculo à madrugada. `night_ended` abre o resumo no `overlay.gd`.
- **Áudio** (autoloads `Settings` e `Audio`): todo som é procedural (`audio/synth.gd`, sem assets). Música em camadas sobe com `GameState.tension()`. Puzzles pedem sons com `GameState.play(nome, posição)`; `audio/audio_director.gd` os toca e liga os loops 3D (gerador, lâmpada).
- **Controle e opções**: ações em `project.godot` incluem PS4 (analógicos, X pula, Quadrado interage, R1 lanterna, L1 livro, Triângulo inventário, Options pausa). Opções salvas em `user://settings.cfg` (`settings.gd`); o jogador recebe via `apply_settings`. Abertura em `ui/intro.tscn` ("uma produção de" VKS Games → "um oferecimento" Porto Indie, qualquer tecla pula) é a cena inicial e leva ao menu principal em `ui/main_menu.tscn` (ilha à direita, botões à esquerda).
- **Tema da UI**: visual de latão enferrujado/verde-água em `ui/ui_kit.gd` (`build_theme()`), gravado em `ui/theme.tres` e ligado por `gui/theme/custom` (o tema da janela não alcança Controls sob `CanvasLayer`). Mudou o visual → rode `godot --headless --path . --script res://tests/make_theme.gd` para regerar o `.tres`. Fonte: DejaVu Serif Condensed Bold (sem antialiasing).
- **Detalhes da ilha** (`world/island_details.tscn`) foi gerado por script e é editável no editor; vegetação (pinheiros, arbustos, grama em MultiMesh) fica nele.
- **Testes com `--script`**: autoloads não existem na compilação do script de teste, então não use tipos `class_name` que dependam de `GameState` (ex.: `Beacon`) e espere um frame antes de usar nós criados em `_ready`.

## Convenções

- GDScript tipado (`class_name`, `@export`, `@onready`), indentação com tabs (`.editorconfig` só define UTF-8).
- Arquivos `.uid` e a pasta `.godot/` : `.godot/` é ignorada pelo git; `.uid` devem ser commitados junto com seus scripts.
- `scns/` (não versionada) contém cenas experimentais fora do fluxo de `main.tscn`.

## Ferramentas de IA

`.claude/skills/` traz skills de gamedev/Blender/Godot instaladas localmente. Há MCPs de `godot` (rodar/editar cenas) e `blender` (modelagem) disponíveis; o plano de trabalho assume que Claude escreve código, cenas e modelos.

## Agentes do projeto (uso OBRIGATÓRIO)

Subagentes de gamedev em `.claude/agents/` (um por função): `game-designer`, `level-designer`, `narrative-designer`, `game-developer`, `engine-programmer`, `ai-physics-programmer`, `concept-artist`, `artist-3d`, `animator`, `sound-designer`, `producer`, `project-manager`, `creative-director`, `qa-tester`, `localizer`, `community-manager`, `marketing-pr`.

**Regra:** toda tarefa que se encaixe numa função acima vai para o agente dessa função, com a ferramenta `Agent` e `subagent_type` igual ao nome do arquivo. Só faça direto: pergunta rápida, leitura de arquivo, edição de 1–2 linhas, rodar teste/build/commit.

| Tarefa | Agente |
|---|---|
| Mecânicas, balanceamento, GDD | `game-designer` |
| Level design da ilha, puzzles espaciais | `level-designer` |
| História, falas, notas, chamadas de rádio | `narrative-designer` |
| Gameplay, UI em GDScript, sistemas | `game-developer` |
| Shaders, render, performance, exportação | `engine-programmer` |
| Criaturas, IA, física | `ai-physics-programmer` |
| Logo, conceitos, arte 2D | `concept-artist` |
| Modelos 3D | `artist-3d` |
| Sons e música | `sound-designer` |
| Testes e bugs | `qa-tester` |
| Página do itch.io, divulgação | `marketing-pr` |
| Planejamento e prioridades | `producer` / `project-manager` |
| Coerência de tom e visão | `creative-director` |

Ao delegar: brief curto com arquivos e critério de pronto, sem recontar o que o agente consegue ler no repositório; peça só o resumo no retorno. Se o tipo não aparecer na lista de agentes da sessão (os arquivos só carregam ao iniciar), avise o usuário em uma linha antes de usar um agente genérico.

Consulte o grafo do Obsidian (`~/obsidian/CodeGraph/graf/CodeGraph`) só quando precisar de padrões de outro projeto; os projetos de Godot de lá são pequenos (starter kit FPS e exercícios de GDScript).
