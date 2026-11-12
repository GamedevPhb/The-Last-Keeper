# Prompt de continuação: expansão da ilha, atividades secundárias e tutorial

Cole o bloco abaixo numa sessão nova, aberta na pasta do projeto (`The Last Keeper`). Antes, commite o que está pendente (veja "Estado" abaixo).

---

Você é o desenvolvedor do *The Last Keeper* (Godot 4.7, GDScript, visual PS1; leia `CLAUDE.md`, `docs/GDD.md`, `docs/HISTORIA.md`, `docs/PLANO.md`). Seja econômico em tokens: leia só o necessário, delegue aos agentes do projeto (`game-developer`, `level-designer`, `game-designer`, `narrative-designer`, `artist-3d`) com briefs curtos e peça retorno curto. Rode `godot-4 --headless --path . --script res://tests/<t>.gd` para TODOS os `tests/*_test.gd` e confira `SCRIPT ERROR` no log (os testes imprimem PASSED mesmo com erro).

## Estado atual (já implementado)
- Noite 1 com tutorial por dicas de objetivo; `GameState.night`, `night_factor()` (0,55 na noite 1, 1,0 na 2, +0,15 por noite até 1,6) e `tutorial()`.
- Fim da noite: resumo com "Continuar" (cena `dawn` do barqueiro, `advance_night()`) e "Menu principal".
- Cenas de história (`ui/story_scene.gd`, `GameState.SCENE_TRIGGERS`, flags `scenes_seen` salvas): `house` (entrar na casa), `lamp`, `bell`, `lavado`, `captain`, `aurora`, `dawn`. A cena da casa foi bem recebida pelo usuário.
- Combate básico (machado, pistola, espingarda; Lavados com 60 hp; invasão em 3 ondas às 02:30), navios do rádio, bateria da lanterna e limpador de lente, cofre com interface, livro com folha padronizada, opções de proporção/resolução.
- NPCs/monstros com modelos psx em `assets/personagens_psx/`, cargueiro em `assets/navios/`, armas em `assets/armas/`.
- Pendente de commit: tudo acima (sem commits desde `26244ad`).

## Objetivo desta sessão (planeje com `EnterPlanMode` e valide comigo antes de codar)
1. **Expandir a ilha**: mais área explorável (por ex. floresta/mata com madeira, costa norte, uma gruta, ruínas/cabana do vigia 6, segundo ilhéu) com identidade visual PS1 e iluminação coerente com a atmosfera; manter o desempenho (câmera corta em 75 m, fog de 45 m). Use `world/island_details.tscn` (Marker3D de estações) e o padrão de nós por script já existente.
2. **Atividades secundárias e estruturas**, desbloqueadas por noite (`GameState.night`):
   - **Noite 1 (simples)**: só o essencial + as **fábricas já liberadas**: fábrica de óleo (jogar madeira/gordura/algas → óleo de lâmpada) e fábrica de combustível (madeira/carvão/restos → combustível), com tempo de produção, capacidade e interação por `Interactable` + console no padrão `ui/puzzle_console.gd`.
   - **Noites 2+** liberam gradualmente: coleta de recursos naturais (lenha, algas, gordura de animal/pesca), pesca ou armadilha de comida/água (`world/supplies.gd`), oficina (munição, pilhas, limpador de lente), horta/cisterna, torre de vigia/binóculo, reforço de cerca/portas contra a invasão. Cada estrutura tem custo de recurso, uso diário e ligação com sobrevivência (sede, fome, óleo, combustível, bateria).
   - Estado salvo em `save_game.gd` (grupo `saveable`) e liberação por `unlocks` por noite em uma tabela única no `GameState`.
3. **Tutorial por cenas** (padrão `story_scene` + `SCENE_TRIGGERS`, tocadas uma vez, puláveis segurando E, salvas): nova cena ao **chegar perto do farol** explicando como o puzzle da lâmpada funciona (óleo → aquecer/bombear até o verde → só então a válvula → corda), e outra ao **chegar perto do gerador** (válvulas na ordem do livro de registros, disjuntores, máximo 2 circuitos). Depois, tutorial curto de cada nova estrutura na primeira vez que ela é liberada (fábricas na noite 1). Noites 2+ não repetem o tutorial.
4. **Balanceamento**: a economia (óleo, combustível, bateria, comida) deve fechar com as fábricas na noite 1 sem sobrar demais, e crescer nas noites seguintes com `night_factor()`.

## Regras
- Nada além do pedido; edite arquivos existentes antes de criar novos; não commite segredos; atualize `docs/GDD.md`, `docs/PLANO.md` e `LICENSE-ASSETS.md` quando mudar escopo/assets.
- Combate/arma já existem: novos inimigos entram no grupo `enemies` e usam `LavadoBody`.
- Assets externos novos: peça ao usuário (ele busca). Enquanto isso, use placeholders low-poly PS1 gerados por código ou modelos já no projeto.
- Antes de encerrar: rodar todos os testes, listar o que não foi visto em tela e propor o commit.
