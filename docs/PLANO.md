# Plano de Desenvolvimento: Demo Jogável

> **The Last Keeper** · Início 2026-11-10 · Plano revisto em 2026-11-12 (quinta)
> **Lançamento da demo no itch.io: quinta 07/01/2027** · Build final congelado: segunda 04/01/2027 · RC1: segunda 28/12/2026
> Plataformas: Web, Windows, Linux e **Android (APK, HUD de toque, meta de 30 fps num celular intermediário)**. O Android passa por um portão de performance em 06/12 (ver `SPRINTS.md`).
> Ritmo: o código, as cenas e os modelos são feitos por agentes de IA. **O gargalo é a revisão e o playtest humano.** Hipótese de capacidade humana: 6–8 h/semana (revisar, jogar, decidir); 2–3 h nas semanas de Natal e Ano-Novo. Se a capacidade real for de 3–5 h/semana, aplique a linha de corte já na sprint 3. Não há semana de folga entre o congelamento e o lançamento: qualquer atraso sai da linha de corte, não da data.

**A demo é o MVP do GDD (§12):** uma noite completa, do anoitecer ao amanhecer, com lâmpada, gerador, rádio e dois navios (um regular, um anômalo), no visual PS1, publicada no itch.io. Tudo o que não serve a essa noite está abaixo da linha de corte.

**Como ler as estimativas:** "d" = dias de trabalho de agente (incluindo o teste headless). Cada tarefa precisa de uma revisão humana curta (15–45 min) antes de ser marcada como pronta. Não abra mais de 6 tarefas de revisão por semana.

---

## Histórico (o que já está pronto)

### Semana 1: base técnica ✅ (2026-11-10)
- Projeto 320×240, shaders PS1 (jitter, afim, mar, dithering 15-bit), jogador em primeira pessoa, interação (apertar/segurar), ilha *greybox* com rampa em espiral, `tests/smoke_test.gd`.

### Semana 2: sistemas e UI ✅ (2026-11-10 a 2026-11-12, além do plano original)
- Puzzles: gerador com válvulas, disjuntores (capacidade 2), rádio fixo com navios que mentem sobre a carga, cadeado 8-3-5 com pistas, maré, tambor de óleo, baú.
- Relógio 17:30 → 06:00 (~15 min reais), `progress()`/`tension()`, céu dia-noite, resumo da noite.
- Console da lâmpada (queimador de vapor, GDD §4.1.1) e console dos disjuntores.
- Rádio portátil (GDD §4.8), inventário de 32 slots estilo Minecraft (§4.9), vida/sede/fome (§4.10).
- HUD limpo, tema de latão, abertura VKS Games + Porto Indie, menu principal, pausa, opções (`user://settings.cfg`), controle PS4.
- Saves em 3 slots com autosave, cutscene de abertura ("A travessia", `docs/CUTSCENE_ABERTURA.md`).
- Trilha adaptativa em 4 estágios com textura lo-fi PS1 e visual PS1 reforçado; todo o áudio é procedural.
- `smoke_test.gd` e `puzzle_test.gd` passando no headless.

**O que falta para o MVP:** navios visíveis com decisão e consequência, a consequência da corda em 0 (criaturas), uma noite roteirizada e balanceada, arte P0 no lugar das caixas, localização PT/EN, exportação e página, playtests e polimento.

**Pendência imediata:** o trabalho da semana 2 está todo fora do git (ver `git status`). Commitar antes de começar a sprint 1.

---

## Sprints

O cronograma detalhado (calendário, marcos, tarefas por sprint, checagem semanal, linha de corte e riscos) está em [`SPRINTS.md`](SPRINTS.md). Cada tarefa tem uma issue no GitHub, com a sprint como milestone.

## Como rodar os testes

```bash
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --script res://tests/puzzle_test.gd
```
