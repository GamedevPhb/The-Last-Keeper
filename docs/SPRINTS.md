# Sprints até o lançamento da demo

> **The Last Keeper** · Plano de sprints de 12/11/2026 a 17/01/2027 · Lançamento proposto: **quinta 14/01/2027 (A CONFIRMAR)**
> Contexto, histórico e premissas de capacidade: [`PLANO.md`](PLANO.md). Cada tarefa vira uma issue no GitHub (milestone = sprint).

**Estimativas:** "d" = dias de trabalho de agente, incluindo o teste headless. Cada tarefa precisa de uma revisão humana curta (15–45 min). No máximo 6 revisões por semana.

## Calendário

| Sprint | Datas | Meta | Capacidade |
|---|---|---|---|
| S0 | qui 12/11 – dom 15/11 | Consolidar, decidir pendências e provar o export | parcial |
| S1 | seg 16/11 – dom 22/11 | Navios visíveis e decisão de ponta a ponta (loop do GDD fechado em *greybox*) | cheia |
| S2 | seg 23/11 – dom 29/11 | Noite 1 roteirizada, corda em 0 com consequência e primeiro playtest interno | cheia |
| S3 | seg 30/11 – dom 06/12 | Arte P0: os interativos ficam legíveis e o cinza sai | cheia |
| S4 | seg 07/12 – dom 13/12 | Criatura e navio modelados, telas finais, strings externalizadas → **conteúdo travado** | cheia |
| S5 | seg 14/12 – dom 20/12 | **Beta** nas mãos de 3–5 testadores e tradução EN | cheia |
| S6 | seg 21/12 – dom 27/12 | Natal: só correções do beta e capturas | ~40% |
| S7 | seg 28/12 – dom 03/01 | Ano-Novo: balanceamento final, trailer e texto da página | ~40% |
| S8 | seg 04/01 – dom 10/01 | **Release candidate** e congelamento (qui 07/01) | cheia |
| S9 | seg 11/01 – dom 17/01 | **Lançamento qui 14/01** e janela de hotfix | cheia |

### Marcos

| Marco | Data | Critério |
|---|---|---|
| M1 · Loop fechado (*greybox*) | dom 22/11 | Um navio regular e um anômalo aparecem no mar, o jogador decide e vê a consequência no resumo |
| M2 · Noite jogável de ponta a ponta | dom 29/11 | Uma pessoa joga 17:30 → 06:00 sem ajuda do desenvolvedor e chega a um resumo |
| M3 · **Conteúdo travado** | dom 13/12 | Nenhuma mecânica, item, fala ou asset novo depois desta data. Só correção, balanceamento, tradução e polimento |
| M4 · **Beta para playtest** | qua 16/12 | Build Web + Windows na página privada do itch com senha, enviada a 3–5 testadores |
| M5 · **Release candidate** | seg 04/01 | Build RC1 com zero bugs bloqueantes conhecidos, PT e EN completos |
| M6 · Build congelado | qui 07/01 | RC final marcado no git (`v0.1.0-demo`); depois disso só hotfix de crash |
| M7 · **Lançamento** | qui 14/01 | Página pública no itch.io com builds Web, Windows e Linux |

---

## S0 · qui 12/11 – dom 15/11 · Consolidar, decidir e provar o export

**Meta:** tudo commitado, decisões que travam o resto tomadas e um build Web abrindo no navegador.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 0.1 | Commitar o trabalho da semana 2 em commits por sistema (com `.uid`) | humano + qa-tester | 0,5 d | `git status` limpo; smoke e puzzle passam no commit final |
| 0.2 | Teste headless dos status (GDD §4.10, critério 7), se ainda não existir | qa-tester | 0,5 d | Script em `tests/` força sede/fome/vida e checa taxas e limiares; sai com código 0 |
| 0.3 | Export Web e Windows a partir do build atual (sem página pública) | engine-programmer | 0,5 d | Zip Web com `index.html` na raiz abre no Chrome; `.exe` abre num Windows; o FPS e os shaders estão iguais ao editor |
| 0.4 | Limpar a tabela de controles duplicada no fim da GDD §8 | game-designer | 0,1 d | §8 tem uma tabela só, coerente com `project.godot` |
| 0.5 | Decisões do humano (abaixo) registradas na GDD §14 | humano | 1 h | As 5 respostas escritas |

**Decisões que precisam sair na S0** (cada uma bloqueia uma sprint):
1. Idioma: PT + EN no lançamento? (recomendação: sim, só texto) → bloqueia 4.6 e 5.3.
2. Assets: modelar por agente no Blender, usar bibliotecas livres (Kenney, Quaternius, Poly Haven) ou misto? (recomendação: misto; agentes nos interativos P0, bibliotecas na vegetação e nas rochas) → bloqueia S3.
3. O Blender e o MCP estão instalados e conectados? → bloqueia S3. Se não estiverem até 29/11, a arte da S3 vira texturas sobre o *greybox*.
4. Orca de quatro patas: a imagem de referência chega até 29/11? Se não, a orca sai da demo.
5. Demo gratuita ou "pague o quanto quiser"?

**Riscos:** o commit grande pode esconder uma regressão. Mitigação: rodar os testes a cada commit parcial.

---

## S1 · seg 16/11 – dom 22/11 · Navios e decisão

**Meta:** o loop principal do GDD fechado em *greybox*: ver o navio, ouvir o rádio, comparar com o livro, decidir e ver a consequência.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 1.1 | `Ship` (cena + script): casco *greybox*, luzes de navegação (vermelho/verde/topo), rota em `Path3D` ao redor da ilha, ligado à chamada de rádio que já existe | game-developer | 1,5 d | Ao surgir a chamada, um navio aparece no horizonte no rumo anunciado e segue a rota até atracar, passar ou bater |
| 1.2 | Consequência visível: AUTORIZAR leva ao píer; RECUSAR desvia; farol falhando (apagado, fixo ou alcance < 40%) faz o navio bater nas pedras | game-developer | 1 d | Teste headless força cada caso e confere `ships_lost`/salvos e a posição final do navio |
| 1.3 | Navio anômalo: luzes erradas (ex.: só luz verde, ou luz de topo vermelha) e casco do *Santa Aurora* quando ele mente | game-designer → game-developer | 0,5 d | Um testador distingue o anômalo pelas luzes sem ler o código, em 2 de 2 tentativas |
| 1.4 | Binóculo (botão direito / L2): zoom da câmera com vinheta | game-developer | 0,5 d | Zoom ×4 sem quebrar o stretch 320×240; funciona no PS4; relógio não pausa |
| 1.5 | Sons do navio: buzina distante, motor 3D, casco batendo nas pedras | sound-designer | 0,5 d | Sons procedurais em `synth.gd`, tocados por `GameState.play()`; audíveis do topo do farol |
| 1.6 | Atualizar `puzzle_test.gd`/`smoke_test.gd` com o fluxo do navio | qa-tester | 0,5 d | Ambos passam; um caso novo cobre "autorizar anômalo → consequência" |

**Dependências:** 1.2 e 1.3 dependem de 1.1; 1.6 depende de 1.2.
**Riscos:** navios no mar aberto com neblina forte podem ficar invisíveis no 320×240. Mitigação: as luzes de navegação são *unshaded* e ignoram a neblina.

---

## S2 · seg 23/11 – dom 29/11 · A noite completa

**Meta:** a Noite 1 tem roteiro, a corda em 0 tem consequência e uma pessoa joga do começo ao fim.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 2.1 | Roteiro da Noite 1 em `.tres` (horários das chamadas: 3 roteirizadas, 1 regular e 1 anômala obrigatórias; falhas do gerador; rajadas) lido pelo `GameState` | game-developer | 1 d | Mudar um horário no `.tres` muda o evento no jogo sem tocar no código |
| 2.2 | Texto das 3 chamadas, das linhas do livro e do resumo do amanhecer (PT) | narrative-designer | 1 d | Textos no `.tres`/arquivos de dados, revisados pelo humano, coerentes com `HISTORIA.md` |
| 2.3 | Corda em 0 → presença: **versão mínima** (sons de passos molhados, silhueta *greybox* no fim da escada, dano −35 com 3 s de invulnerabilidade, recua quando a corda volta) | ai-physics-programmer | 1,5 d | Com a corda em 0 por 20 s, algo aparece e causa dano; com a corda > 0 ele some; a morte mostra "Algo na escada"; teste headless cobre |
| 2.4 | Primeiro balanceamento: tempos de óleo, corda, lente, combustível, sede e fome com a Noite 1 | game-designer | 0,5 d | Tabela de valores na GDD; uma noite bem jogada termina com 1–2 navios salvos e sem morrer de sede |
| 2.5 | Playtest interno de 1 noite inteira (humano), com nota de 5 linhas | humano + qa-tester | 0,5 d | Lista de bugs priorizada (bloqueante, grave, menor) em issues ou numa seção deste plano |
| 2.6 | Correções do playtest (só bloqueantes e graves) | game-developer | 1 d | Os bloqueantes da 2.5 fechados, testes passando |

**Dependências:** 2.1 depende de 1.1; 2.2 alimenta 2.1; 2.5 depende de 2.1–2.3.
**Marco:** M2 no domingo.
**Riscos:** o jogador não entende o objetivo sem ajuda. Mitigação: o objetivo do HUD (`GameState.objective()`) é revisado na 2.6 com base no que o testador perguntou.

---

## S3 · seg 30/11 – dom 06/12 · Arte P0

**Meta:** cada interativo tem silhueta, cor e detalhe próprios (`LISTA_ASSETS.md` §6), e a ilha deixa de ser cinza.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 3.1 | *Style guide* de 1 página: paleta, densidade de textura, limites de polígonos (base: `LISTA_ASSETS.md`) | concept-artist + creative-director | 0,5 d | Página aprovada pelo humano, com 4 cores e 1 prancha de referência |
| 3.2 | Props interativos P0: disjuntores, gerador, rádio, tambor, latas, baú, cadeado, livro (env_24, 25, 30, 41, 42, 43, 53) | artist-3d | 2 d | `.glb` em `assets/modelos/` dentro do limite de triângulos, com `psx_lit`; colisões e `Interactable` intactos; puzzle_test passa |
| 3.3 | Lâmpada e mecanismo (env_02, env_04): chama que segue a PRESSÃO, cabeça que gira com a CORDA, manômetro | artist-3d + game-developer | 1 d | Os critérios "Mundo 3D" do GDD §4.1.1 são visíveis no jogo |
| 3.4 | Texturas P0 128 px ladrilháveis no lugar dos `m_*.tres` (pedra, madeira, metal, reboco, terra, areia) | artist-3d | 1 d | Nenhum material cinza liso visível do píer ao topo do farol |
| 3.5 | Vegetação e rochas de biblioteca livre (veg_01–05, env_06) com licença registrada | artist-3d | 0,5 d | Arquivo `assets/LICENCAS.md` com origem de cada asset; FPS não cai abaixo de 60 no Web |
| 3.6 | Revisão de performance e de visual no Web | engine-programmer | 0,5 d | Export Web com a arte nova roda a 60 fps num notebook comum; tamanho do zip < 60 MB |

**Dependências:** 3.2–3.5 dependem de 3.1 e da decisão 2/3 da S0; 3.6 depende de 3.2–3.5.
**Riscos:** a modelagem por MCP não fica boa o bastante ou o Blender não está pronto. Mitigação: fallback para textura sobre o *greybox* com silhueta melhorada por primitivas (decidido no domingo 29/11).

---

## S4 · seg 07/12 – dom 13/12 · Conteúdo travado

**Meta:** a última leva de conteúdo entra; a partir de domingo, só correção.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 4.1 | Lavado (cre_01): modelo 900 tris com 3 animações (idle, andar, ataque), substitui a silhueta da 2.3 | artist-3d + animator | 1,5 d | O Lavado aparece na escada com a corda em 0 e anima sem *T-pose*; teste da 2.3 continua passando |
| 4.2 | Navio regular e *Santa Aurora* (cre_06) em versão de longe, com balanço por shader | artist-3d | 1 d | Os dois cascos são diferentes à distância de 80 m no 320×240 |
| 4.3 | Telas finais: amanhecer com resumo (salvos, perdidos, causa), morte e créditos | game-developer + narrative-designer | 1 d | Os 3 desfechos (sobreviveu, morreu, farol falhou) mostram tela e texto próprios e voltam ao menu |
| 4.4 | Polimento de áudio: ambiente do mar em 3 camadas, vento, rangido do mecanismo como relógio | sound-designer | 1 d | Parar a corda é perceptível só pelo som (teste cego com o humano) |
| 4.5 | Página do livro com fundo de pergaminho e cartão de chamada no rádio portátil | game-developer | 0,5 d | Livro e portátil usam o tema; legíveis em 320×240 |
| 4.6 | Externalizar todas as strings de UI, falas e livro para tradução (`tr()` + CSV ou `.po`) | localizer + game-developer | 1 d | Trocar o locale para uma língua de teste muda 100% dos textos visíveis; nenhuma string literal de UI fora do arquivo de tradução |

**Dependências:** 4.1 depende de 2.3; 4.6 depende de o texto da 2.2 e da 4.3 estar fechado.
**Marco:** M3 (conteúdo travado) no domingo 13/12.
**Riscos:** a 4.6 toca em quase todos os scripts de UI e pode quebrar telas. Mitigação: um commit por tela e os testes rodando a cada commit.

---

## S5 · seg 14/12 – dom 20/12 · Beta e tradução

**Meta:** 3–5 pessoas de fora jogam o beta, e o EN fica pronto.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 5.1 | Logo final e capa provisória para a página privada | concept-artist | 0,5 d | PNG transparente 1440 px aprovado; capa 630×500 |
| 5.2 | Página privada no itch (Restricted, senha) com builds Web + Windows e texto do convite (GUIA §9 e §10A) | marketing-pr + engine-programmer | 0,5 d | O humano abre a página como visitante: o embed roda, o download funciona |
| 5.3 | Tradução EN de UI, falas, livro e página | localizer | 1 d | Jogo completo em EN sem string em PT; textos cabem nos painéis em 320×240 |
| 5.4 | Envio do beta (qua 16/12) e formulário de 4 perguntas (GUIA §10A) | humano + marketing-pr | 1 h | Convite enviado a 3–5 pessoas, com prazo de resposta até 23/12 |
| 5.5 | Passada de QA por checklist (controle PS4, teclado, Web, Windows, save/load, morte, os 3 desfechos) | qa-tester | 1 d | Checklist em `docs/` com cada item marcado ou com bug aberto |
| 5.6 | Correções da 5.5 | game-developer | 1 d | Nenhum bloqueante aberto |

**Dependências:** 5.2 depende de 5.1 e do export da S0; 5.3 depende de 4.6.
**Marco:** M4 na quarta 16/12.
**Riscos:** poucos testadores respondem antes do Natal. Mitigação: convidar 6 para obter 3 respostas; o humano grava a tela de 1 testador presencial.

---

## S6 · seg 21/12 – dom 27/12 · Natal (capacidade ~40%)

**Meta:** triar o feedback do beta e corrigir só o que bloqueia ou confunde.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 6.1 | Consolidar o feedback do beta em lista priorizada (MoSCoW) | producer | 0,5 d | Lista curta com no máximo 10 itens "Must fix" |
| 6.2 | Correções "Must fix" | game-developer | 1,5 d | Itens fechados, testes passando |
| 6.3 | Capturas de tela da interface final por script (GUIA §3) | engine-programmer | 0,5 d | 6–8 PNGs 960×720 gerados por um comando |

**Regra da semana:** nenhuma feature nova. Revisão humana de no máximo 2 h.

---

## S7 · seg 28/12 – dom 03/01 · Ano-Novo (capacidade ~40%)

**Meta:** balanceamento final com os dados do beta, e material de divulgação pronto.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 7.1 | Balanceamento final da Noite 1 com base no beta | game-designer | 0,5 d | Valores finais na GDD; 2 das 3 respostas do beta dizem "difícil mas justo" ou próximo |
| 7.2 | Trailer de 60 s (GUIA §8) com trilha própria | marketing-pr + sound-designer | 1 d | MP4 1920×1080 com logo e data; sem música de terceiros |
| 7.3 | Texto da página em HTML simples, PT e EN, banner, fundo e embed BG (GUIA §4–6) | marketing-pr + localizer | 0,5 d | Todos os itens do checklist do GUIA marcados, exceto publicar |
| 7.4 | Correções restantes do beta (só Must e Should) | game-developer | 1 d | Lista da 6.1 vazia nos Must |

---

## S8 · seg 04/01 – dom 10/01 · Release candidate e congelamento

**Meta:** RC1 na segunda, build final congelado na quinta.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 8.1 | RC1 (seg 04/01): exports Web, Windows e Linux | engine-programmer | 0,5 d | Os 3 builds abrem; o zip Web roda no embed da página privada |
| 8.2 | Regressão completa no RC1 (checklist da 5.5 nas 3 plataformas, PT e EN) | qa-tester | 1 d | Zero bloqueantes; graves documentados com decisão (corrigir ou conviver) |
| 8.3 | Playtest humano final de 1 noite em Web e em Windows | humano | 1 h | Uma noite inteira sem crash em cada plataforma |
| 8.4 | Correções do RC1 e RC final (qui 07/01), tag `v0.1.0-demo` | game-developer + engine-programmer | 1 d | Tag criada; builds finais sobem para a página privada |
| 8.5 | Textos de divulgação prontos (curto e longo, PT e EN; GUIA §10B) e lista de onde postar | marketing-pr | 0,5 d | Textos revisados pelo humano |

**Marcos:** M5 (seg 04/01) e M6 (qui 07/01).
**Regra:** depois de 07/01, só entra correção de crash ou de build que não abre.

---

## S9 · seg 11/01 – dom 17/01 · Lançamento

**Meta:** página pública na quinta 14/01 e resposta rápida a problemas.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 9.1 | Checagem final da página privada (seg 11/01) | humano + marketing-pr | 1 h | Imagens, embed, downloads e texto PT/EN conferidos como visitante |
| 9.2 | Publicar (qui 14/01) e postar a divulgação | humano | 1 h | Página pública; posts feitos |
| 9.3 | Janela de hotfix (qui 14 a dom 17/01): triagem dos comentários e do feedback | qa-tester + game-developer | 1 d | Crash relatado é reproduzido e corrigido em até 48 h, com novo build `v0.1.1` se for preciso |

---

## Checagem semanal (todo domingo, ~30 min de humano)

1. `godot --headless --path . --script res://tests/smoke_test.gd` e `res://tests/puzzle_test.gd` (e os testes novos das sprints) saem com código 0.
2. Export Web e Windows sem erro (a partir da S3, também o Linux).
3. O humano joga **uma noite inteira** (15 min) no build exportado, não no editor.
4. `git status` limpo e tag semanal `wk-AAAA-MM-DD` no commit testado.
5. Atualizar este plano: marcar tarefas prontas, mover o que atrasou e decidir se algo cruza a linha de corte.

Se a checagem falhar no domingo, a primeira tarefa de segunda é consertá-la; nada novo entra antes disso.

---

## Linha de corte (MoSCoW)

Se uma sprint terminar com mais de 1 dia de atraso, corte de baixo para cima, sem discutir.

**Must (a demo não sai sem isso)**
- Uma noite completa 17:30 → 06:00 com lâmpada (console), gerador, disjuntores e rádio fixo
- Um navio regular e um anômalo visíveis, com decisão e consequência no resumo
- Corda em 0 com consequência (versão mínima: som, silhueta e dano)
- Arte P0 dos interativos (ou textura + silhueta própria sobre o *greybox*)
- Telas de amanhecer e de morte; menu, pausa, opções e saves
- Build Web e Windows; página no itch com capturas e texto
- Zero crash conhecido

**Should (entra se o cronograma permitir)**
- Lavado modelado e animado (no lugar da silhueta)
- Tradução EN
- Build Linux
- Binóculo
- Trailer de 60 s
- Texturas P0 em toda a ilha

**Could (só se sobrar tempo)**
- Navios modelados com balanço por shader (ficam em *greybox* com luzes)
- Vegetação de biblioteca, pergaminho no livro, cartão de chamada
- Orca de quatro patas (depende da imagem até 29/11; mesmo com a imagem, é Could)
- CSS customizado na página

**Won't (fora da demo, vão para depois do lançamento)**
- Portinho demônio e as relíquias secretas
- Encalhado, Sineiro, Capitã, A Voz, Gaivotas Mudas, Luzes-de-Vigia, Névoa-Viva
- Noites 2–7, finais narrativos, clima dinâmico, barco de suprimentos, sirene de neblina, modo sinal manual
- Dublagem (o áudio continua procedural)

**Não cortar:** a decisão sobre o navio anômalo. É o coração do jogo.

---

## Riscos e dependências

| # | Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|---|
| R1 | **A revisão e o playtest humano não acompanham a produção dos agentes** (fila de revisão cresce, tarefas "prontas" sem validação) | alta | alto | Máximo de 6 revisões por semana; critério de pronto testável por teste headless sempre que possível; checagem de domingo obrigatória |
| R2 | **A arte P0 atrasa** (Blender/MCP não instalado, modelos ruins, retrabalho) e empurra o conteúdo travado | média | alto | Decisão da S0; fallback textura + silhueta em primitivas decidido em 29/11; biblioteca livre para o que não é interativo |
| R3 | **O beta coincide com o Natal**: pouco retorno de testadores e pouca capacidade para corrigir | alta | médio | Beta na quarta 16/12 (antes do feriado); convidar 6 para obter 3; S6 e S7 só com correção |
| R4 | Externalizar strings (4.6) quebra telas tarde demais | média | médio | Feito antes do conteúdo travado; um commit por tela; regressão na 5.5 |
| R5 | Export Web com problema de performance ou tela preta | baixa | alto | Export provado na S0 e em toda checagem semanal; meta de 60 fps e zip < 60 MB na 3.6 |
| R6 | Escopo cresce com criaturas e o Portinho (pedidos novos na `LISTA_ASSETS.md`) | média | alto | Tudo fora do Must/Should está na linha de corte; criatura nova só depois de 14/01 |

**Dependências externas (do humano):** respostas da S0 (idioma, origem dos assets, Blender, imagem da orca, preço); 3–5 testadores confirmados até 13/12; conta e página no itch.io; data de lançamento confirmada até o fim da S2.

