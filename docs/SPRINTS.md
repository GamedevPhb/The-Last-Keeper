# Sprints até o lançamento da demo

> **The Last Keeper** · Plano de sprints de 12/11/2026 a 10/01/2027 · Lançamento: **quinta 07/01/2027**
> Contexto, histórico e premissas de capacidade: [`PLANO.md`](PLANO.md). Cada tarefa vira uma issue no GitHub (milestone = sprint). Revisão de 12/11: o lançamento foi antecipado em uma semana e o Android entrou no escopo (ver "Mudanças vs. versão anterior" no fim).

**Estimativas:** "d" = dias de trabalho de agente, incluindo o teste headless. Cada tarefa precisa de uma revisão humana curta (15–45 min). No máximo 6 revisões por semana (2 h no total nas semanas de Natal e Ano-Novo).

**Tarefas movidas** mantêm o número antigo, com a nota *(era Sx)*. Tarefas novas recebem o próximo número livre da sprint.

## Calendário

| Sprint | Datas | Meta | Capacidade |
|---|---|---|---|
| S0 | qui 12/11 – dom 15/11 | Consolidar, decidir pendências, provar o export (Web, Windows e Android) e HUD de toque | parcial |
| S1 | seg 16/11 – dom 22/11 | Navios visíveis e decisão de ponta a ponta (loop do GDD fechado em *greybox*) | cheia |
| S2 | seg 23/11 – dom 29/11 | Noite 1 roteirizada, corda em 0 com consequência e primeiro playtest interno | cheia |
| S3 | seg 30/11 – dom 06/12 | Arte P0 e **portão de performance do Android** | cheia |
| S4 | seg 07/12 – dom 13/12 | Criatura, telas finais, strings externalizadas, logo → **conteúdo travado** | cheia |
| S5 | seg 14/12 – dom 20/12 | **Beta** (Web, Windows e APK) com 3–5 testadores e tradução EN | cheia |
| S6 | seg 21/12 – dom 27/12 | Natal: correções do beta, balanceamento final e texto da página | ~40% |
| S7 | seg 28/12 – dom 03/01 | Ano-Novo: **RC1** e regressão | ~40% |
| S8 | seg 04/01 – dom 10/01 | **Congelamento seg 04/01**, **lançamento qui 07/01** e janela de hotfix | cheia |

### Marcos

| Marco | Data | Critério |
|---|---|---|
| M0 · Export provado | dom 15/11 | Build Web abre no Chrome, `.exe` abre no Windows e o APK de teste abre num celular Android real |
| M1 · Loop fechado (*greybox*) | dom 22/11 | Um navio regular e um anômalo aparecem no mar, o jogador decide e vê a consequência no resumo |
| M2 · Noite jogável de ponta a ponta | dom 29/11 | Uma pessoa joga 17:30 → 06:00 sem ajuda do desenvolvedor e chega a um resumo |
| M2b · Portão do Android | dom 06/12 | Com a arte P0, o APK roda a ≥ 30 fps no celular de referência. Se não rodar, o Android sai do lançamento e vira atualização pós-demo (decisão sem discussão) |
| M3 · **Conteúdo travado** | dom 13/12 | Nenhuma mecânica, item, fala ou asset novo depois desta data. Só correção, balanceamento, tradução e polimento |
| M4 · **Beta para playtest** | qua 16/12 | Builds Web + Windows + APK na página privada do itch com senha, enviada a 3–5 testadores |
| M5 · **Release candidate** | seg 28/12 | Build RC1 com zero bugs bloqueantes conhecidos, PT e EN completos, nas 4 plataformas |
| M6 · Build congelado | seg 04/01 | RC final marcado no git (`v0.1.0-demo`); depois disso só hotfix de crash ou de build que não abre |
| M7 · **Lançamento** | qui 07/01 | Página pública no itch.io com builds Web, Windows, Linux e Android (APK) |

---

## S0 · qui 12/11 – dom 15/11 · Consolidar, decidir e provar o export

**Meta:** tudo commitado, decisões que travam o resto tomadas, um build Web abrindo no navegador, um APK abrindo num celular e o HUD de toque funcionando.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 0.1 | Commitar o trabalho da semana 2 em commits por sistema (com `.uid`) | humano + qa-tester | 0,5 d | `git status` limpo; smoke e puzzle passam no commit final |
| 0.2 | Teste headless dos status (GDD §4.10, critério 7), se ainda não existir | qa-tester | 0,5 d | Script em `tests/` força sede/fome/vida e checa taxas e limiares; sai com código 0 |
| 0.3 | Export Web e Windows a partir do build atual (sem página pública) | engine-programmer | 0,5 d | Zip Web com `index.html` na raiz abre no Chrome; `.exe` abre num Windows; o FPS e os shaders estão iguais ao editor |
| 0.4 | Limpar a tabela de controles duplicada no fim da GDD §8 | game-designer | 0,1 d | §8 tem uma tabela só, coerente com `project.godot` (incluindo os controles de toque da 0.6) |
| 0.5 | Decisões do humano (abaixo) registradas na GDD §14 | humano | 1 h | As 5 respostas escritas |
| 0.6 | **HUD de toque** (novo): joystick virtual à esquerda, olhar arrastando à direita, botões interagir (toque e segurar, respeitando `hold_time`), pular, lanterna, livro, inventário e pausa; consoles da lâmpada e dos disjuntores e o `overlay.gd` operáveis por toque; aparece só em tela de toque | game-developer | 1 d | No PC, com "emular toque pelo mouse", um jogador acende a lâmpada pelo console e abre inventário, livro e pausa só pelo HUD; o HUD não aparece com teclado/controle; smoke e puzzle passam |
| 0.7 | **Export Android de teste** (novo): preset `arm64-v8a`, GL Compatibility, keystore de debug; credenciais fora do git (`.godot/export_credentials.cfg`) | engine-programmer + humano | 0,5 d | O APK de debug instala por `adb` num celular real, abre o menu, inicia a partida e mostra o FPS; o número fica anotado no PR como linha de base |

**Decisões que precisam sair na S0** (cada uma bloqueia uma sprint):
1. Idioma: PT + EN no lançamento? (recomendação: sim, só texto) → bloqueia 4.6 e 5.3.
2. Assets: modelar por agente no Blender, usar bibliotecas livres (Kenney, Quaternius, Poly Haven) ou misto? (recomendação: misto; agentes nos interativos P0, bibliotecas no que não é interativo) → bloqueia S3.
3. O Blender e o MCP estão instalados e conectados? → bloqueia S3. Se não estiverem até 29/11, a arte da S3 vira texturas sobre o *greybox*.
4. **Celular Android de referência** (substitui a pergunta da orca, que saiu da demo): qual aparelho intermediário o humano tem em mãos para medir os 30 fps (modelo, chip, RAM)? → bloqueia 0.7 e 3.7.
5. Demo gratuita ou "pague o quanto quiser"?

**Revisões:** 7 tarefas, mas 0.4 e 0.5 não precisam de revisão; ficam 5.
**Riscos:** o commit grande pode esconder uma regressão (mitigação: rodar os testes a cada commit parcial). Instalar Android SDK, JDK 17 e templates de export pode tomar a sessão inteira do humano (mitigação: o engine-programmer escreve o passo a passo antes; se travar, a 0.7 passa para segunda 16/11, mas não para depois de 22/11).

---

## S1 · seg 16/11 – dom 22/11 · Navios e decisão

**Meta:** o loop principal do GDD fechado em *greybox*: ver o navio, ouvir o rádio, comparar com o livro, decidir e ver a consequência.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 1.1 | `Ship` (cena + script): casco *greybox*, luzes de navegação (vermelho/verde/topo), rota em `Path3D` ao redor da ilha, ligado à chamada de rádio que já existe | game-developer | 1,5 d | Ao surgir a chamada, um navio aparece no horizonte no rumo anunciado e segue a rota até atracar, passar ou bater |
| 1.2 | Consequência visível: AUTORIZAR leva ao píer; RECUSAR desvia; farol falhando (apagado, fixo ou alcance < 40%) faz o navio bater nas pedras | game-developer | 1 d | Teste headless força cada caso e confere `ships_lost`/salvos e a posição final do navio |
| 1.3 | Navio anômalo: luzes erradas (ex.: só luz verde, ou luz de topo vermelha) e casco do *Santa Aurora* quando ele mente | game-designer → game-developer | 0,5 d | Um testador distingue o anômalo pelas luzes sem ler o código, em 2 de 2 tentativas (também no celular de referência) |
| 1.4 | Binóculo (botão direito / L2 / botão no HUD de toque): zoom da câmera com vinheta | game-developer | 0,5 d | Zoom ×4 sem quebrar o stretch 320×240; funciona no PS4 e no toque; relógio não pausa |
| 1.5 | Sons do navio: buzina distante, motor 3D, casco batendo nas pedras | sound-designer | 0,5 d | Sons procedurais em `synth.gd`, tocados por `GameState.play()`; audíveis do topo do farol |
| 1.6 | Atualizar `puzzle_test.gd`/`smoke_test.gd` com o fluxo do navio | qa-tester | 0,5 d | Ambos passam; um caso novo cobre "autorizar anômalo → consequência" |

**Dependências:** 1.2 e 1.3 dependem de 1.1; 1.6 depende de 1.2; 1.4 depende de 0.6 (botão de toque).
**Marco:** M1 no domingo.
**Riscos:** navios no mar aberto com neblina forte podem ficar invisíveis no 320×240, e mais ainda numa tela de celular. Mitigação: as luzes de navegação são *unshaded* e ignoram a neblina.

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

## S3 · seg 30/11 – dom 06/12 · Arte P0 e portão do Android

**Meta:** cada interativo tem silhueta, cor e detalhe próprios (`LISTA_ASSETS.md` §6), a ilha deixa de ser cinza e o Android prova os 30 fps com a arte nova.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 3.1 | *Style guide* de 1 página: paleta, densidade de textura, limites de polígonos (base: `LISTA_ASSETS.md`) | concept-artist + creative-director | 0,5 d | Página aprovada pelo humano, com 4 cores e 1 prancha de referência |
| 3.2 | Props interativos P0: disjuntores, gerador, rádio, tambor, latas, baú, cadeado, livro (env_24, 25, 30, 41, 42, 43, 53) | artist-3d | 2 d | `.glb` em `assets/modelos/` dentro do limite de triângulos, com `psx_lit`; colisões e `Interactable` intactos; puzzle_test passa |
| 3.3 | Lâmpada e mecanismo (env_02, env_04): chama que segue a PRESSÃO, cabeça que gira com a CORDA, manômetro | artist-3d + game-developer | 1 d | Os critérios "Mundo 3D" do GDD §4.1.1 são visíveis no jogo |
| 3.4 | Texturas P0 128 px ladrilháveis no lugar dos `m_*.tres` (pedra, madeira, metal, reboco, terra, areia) | artist-3d | 1 d | Nenhum material cinza liso visível do píer ao topo do farol |
| 3.6 | Revisão de performance e de visual no Web | engine-programmer | 0,5 d | Export Web com a arte nova roda a 60 fps num notebook comum; tamanho do zip < 60 MB |
| 3.7 | **Teste em aparelho real e performance Android** (novo): medir e otimizar (distância de desenho, densidade da grama em MultiMesh, sombras, resolução interna fixa em 320×240) | engine-programmer + humano | 1 d | No celular de referência, ≥ 30 fps médios e ≥ 25 fps no pior trecho (píer e topo do farol) ao longo de uma noite de 15 min; APK < 100 MB; sem fechar por memória. Resultado registrado e decisão do M2b tomada no domingo |

**Cortada nesta revisão:** 3.5 (vegetação e rochas de biblioteca). A vegetação de `island_details.tscn` fica como está.
**Dependências:** 3.2–3.4 dependem de 3.1 e das decisões 2/3 da S0; 3.6 e 3.7 dependem de 3.2–3.4; 3.7 depende de 0.7 e da decisão 4.
**Marco:** M2b no domingo.
**Riscos:** a modelagem por MCP não fica boa o bastante ou o Blender não está pronto (mitigação: fallback para textura sobre o *greybox* com silhueta melhorada por primitivas, decidido no domingo 29/11). O celular não chega aos 30 fps (mitigação: a 3.7 tem as otimizações listadas; se não bastar, o portão corta o Android sem afetar as outras plataformas).

---

## S4 · seg 07/12 – dom 13/12 · Conteúdo travado

**Meta:** a última leva de conteúdo entra; a partir de domingo, só correção.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 4.1 | Lavado (cre_01): modelo 900 tris com 3 animações (idle, andar, ataque), substitui a silhueta da 2.3 | artist-3d + animator | 1,5 d | O Lavado aparece na escada com a corda em 0 e anima sem *T-pose*; teste da 2.3 continua passando |
| 4.3 | Telas finais: amanhecer com resumo (salvos, perdidos, causa), morte e créditos | game-developer + narrative-designer | 1 d | Os 3 desfechos (sobreviveu, morreu, farol falhou) mostram tela e texto próprios e voltam ao menu (também por toque) |
| 4.4 | Polimento de áudio: ambiente do mar em 3 camadas, vento, rangido do mecanismo como relógio | sound-designer | 1 d | Parar a corda é perceptível só pelo som (teste cego com o humano) |
| 4.6 | Externalizar todas as strings de UI, falas, livro e HUD de toque para tradução (`tr()` + CSV ou `.po`) | localizer + game-developer | 1 d | Trocar o locale para uma língua de teste muda 100% dos textos visíveis; nenhuma string literal de UI fora do arquivo de tradução |
| 5.1 | Logo final e capa provisória para a página privada *(era S5)* | concept-artist | 0,5 d | PNG transparente 1440 px aprovado; capa 630×500; ícone do APK 192 px e 432 px (adaptativo) |

**Cortadas nesta revisão:** 4.2 (navios modelados; ficam em *greybox* com luzes) e 4.5 (pergaminho no livro e cartão de chamada; ficam com o tema atual).
**Dependências:** 4.1 depende de 2.3; 4.6 depende de o texto da 2.2 e da 4.3 estar fechado.
**Marco:** M3 (conteúdo travado) no domingo 13/12.
**Riscos:** a 4.6 toca em quase todos os scripts de UI e pode quebrar telas. Mitigação: um commit por tela e os testes rodando a cada commit. Se a S3 atrasar mais de 1 dia, a 4.1 é a primeira a cair (a silhueta da 2.3 vai para o lançamento).

---

## S5 · seg 14/12 – dom 20/12 · Beta e tradução

**Meta:** 3–5 pessoas de fora jogam o beta (pelo menos 1 no Android), e o EN fica pronto.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 5.2 | Página privada no itch (Restricted, senha) com builds Web + Windows e texto do convite (GUIA §9 e §10A) | marketing-pr + engine-programmer | 0,5 d | O humano abre a página como visitante: o embed roda, o download funciona |
| 5.3 | Tradução EN de UI, falas, livro e página | localizer | 1 d | Jogo completo em EN sem string em PT; textos cabem nos painéis em 320×240 |
| 5.4 | Envio do beta (qua 16/12) e formulário de 4 perguntas (GUIA §10A) | humano + marketing-pr | 1 h | Convite enviado a 3–5 pessoas (pelo menos 1 com Android), com prazo de resposta até 23/12 |
| 5.5 | Passada de QA por checklist (controle PS4, teclado, toque, Web, Windows, Android, save/load, morte, os 3 desfechos) | qa-tester | 1 d | Checklist em `docs/` com cada item marcado ou com bug aberto |
| 5.6 | Correções da 5.5 | game-developer | 1 d | Nenhum bloqueante aberto |
| 5.7 | **Página do itch com o APK** (novo): APK de release assinado com keystore de release (fora do git, com backup), enviado à página privada como "Android", com instruções de instalação em PT/EN | engine-programmer + marketing-pr | 0,5 d | O humano baixa o APK da página no celular como visitante, instala e joga até o primeiro navio; a keystore tem cópia fora da máquina |

**Dependências:** 5.2 depende de 5.1 e do export da S0; 5.3 depende de 4.6; 5.7 depende de 5.2 e do M2b (se o Android caiu no portão, a 5.7 é cancelada).
**Marco:** M4 na quarta 16/12.
**Riscos:** poucos testadores respondem antes do Natal (mitigação: convidar 6 para obter 3; o humano grava a tela de 1 testador presencial). Perder a keystore de release impede atualizar o APK depois (mitigação: backup no critério da 5.7).

---

## S6 · seg 21/12 – dom 27/12 · Natal (capacidade ~40%)

**Meta:** triar o feedback do beta, corrigir só o que bloqueia ou confunde, fechar o balanceamento e o texto da página.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 6.1 | Consolidar o feedback do beta em lista priorizada (MoSCoW) — qui 24/12 | producer | 0,5 d | Lista curta com no máximo 10 itens "Must fix"; o que não é Must vai para depois do lançamento |
| 6.2 | Correções "Must fix" | game-developer | 1,5 d | Itens fechados, testes passando |
| 7.1 | Balanceamento final da Noite 1 com base no beta *(era S7)* | game-designer | 0,5 d | Valores finais na GDD; 2 das 3 respostas do beta dizem "difícil mas justo" ou próximo |
| 7.3 | Texto da página em HTML simples, PT e EN, banner, fundo e embed BG (GUIA §4–6), com a seção de instalação do APK *(era S7)* | marketing-pr + localizer | 0,5 d | Todos os itens do checklist do GUIA marcados, exceto capturas e publicar |

**Regra da semana:** nenhuma feature nova. Revisão humana de no máximo 2 h.

---

## S7 · seg 28/12 – dom 03/01 · Ano-Novo: RC1 e regressão (capacidade ~40%)

**Meta:** RC1 na segunda 28/12; RC final pronto no domingo para ser marcado na segunda 04/01.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 8.1 | RC1 (seg 28/12): exports Web, Windows, Linux e Android *(era S8)* | engine-programmer | 0,5 d | Os 4 builds abrem; o zip Web roda no embed da página privada; o APK instala pela página |
| 8.2 | Regressão completa no RC1 (checklist da 5.5 nas 4 plataformas, PT e EN) *(era S8)* | qa-tester | 1 d | Zero bloqueantes; graves documentados com decisão (corrigir ou conviver) |
| 8.3 | Playtest humano final de 1 noite no Web e no Android *(era S8)* | humano | 1 h | Uma noite inteira sem crash em cada plataforma (o Windows fica coberto pela 8.2) |
| 8.4 | Correções do RC1 e RC final (dom 03/01); tag `v0.1.0-demo` na segunda 04/01 depois da checagem *(era S8)* | game-developer + engine-programmer | 1 d | Tag criada; builds finais sobem para a página privada |

**Regra:** só entra correção de bug encontrado no RC1. Revisão humana de no máximo 2 h (a 8.3 já consome metade).

---

## S8 · seg 04/01 – dom 10/01 · Congelamento, lançamento e hotfix

**Meta:** build congelado na segunda, página pública na quinta 07/01 e resposta rápida a problemas.

| # | Tarefa | Agente | Est. | Pronto quando |
|---|---|---|---|---|
| 6.3 | Capturas de tela da interface final por script (GUIA §3), a partir do build congelado — seg 04/01 *(era S6)* | engine-programmer | 0,5 d | 6–8 PNGs 960×720 e 1 GIF de 10 s gerados por um comando |
| 8.5 | Textos de divulgação prontos (curto e longo, PT e EN; GUIA §10B) e lista de onde postar *(era S8; agora seg 04/01)* | marketing-pr | 0,5 d | Textos revisados pelo humano |
| 9.1 | Checagem final da página privada (ter 05/01) *(era S9)* | humano + marketing-pr | 1 h | Imagens, embed, downloads (incluindo o APK) e texto PT/EN conferidos como visitante, no PC e no celular |
| 9.2 | Publicar (qui 07/01) e postar a divulgação *(era S9)* | humano | 1 h | Página pública; posts feitos |
| 9.3 | Janela de hotfix (qui 07 a dom 10/01): triagem dos comentários e do feedback *(era S9)* | qa-tester + game-developer | 1 d | Crash relatado é reproduzido e corrigido em até 48 h, com novo build `v0.1.1` se for preciso |

**Marcos:** M6 (seg 04/01) e M7 (qui 07/01).
**Regra:** depois de 04/01, só entra correção de crash ou de build que não abre.

---

## Checagem semanal (todo domingo, ~30 min de humano)

1. `godot --headless --path . --script res://tests/smoke_test.gd` e `res://tests/puzzle_test.gd` (e os testes novos das sprints) saem com código 0.
2. Export Web, Windows e Android sem erro (a partir da S3, também o Linux). Enquanto o Android estiver no escopo, instalar o APK no celular de referência e anotar o FPS.
3. O humano joga **uma noite inteira** (15 min) no build exportado, não no editor (alternando PC e celular de uma semana para outra).
4. `git status` limpo e tag semanal `wk-AAAA-MM-DD` no commit testado.
5. Atualizar este plano: marcar tarefas prontas, mover o que atrasou e decidir se algo cruza a linha de corte.

Se a checagem falhar no domingo, a primeira tarefa de segunda é consertá-la; nada novo entra antes disso.

---

## Linha de corte (MoSCoW)

Se uma sprint terminar com mais de 1 dia de atraso, corte de baixo para cima, sem discutir. **A data de 07/01 não se move; o escopo, sim.**

**Must (a demo não sai sem isso)**
- Uma noite completa 17:30 → 06:00 com lâmpada (console), gerador, disjuntores e rádio fixo
- Um navio regular e um anômalo visíveis, com decisão e consequência no resumo
- Corda em 0 com consequência (versão mínima: som, silhueta e dano)
- Arte P0 dos interativos (ou textura + silhueta própria sobre o *greybox*)
- Telas de amanhecer e de morte; menu, pausa, opções e saves
- Build Web e Windows; página no itch com capturas e texto
- Zero crash conhecido

**Should (entra se o cronograma permitir; nesta ordem de corte, de baixo para cima)**
- Tradução EN
- **Build Android com HUD de toque a 30 fps** (portão em 06/12; o HUD de toque já está feito na S0)
- Texturas P0 em toda a ilha
- Binóculo
- Build Linux
- Lavado modelado e animado (no lugar da silhueta) — primeiro a cair

**Could (só se sobrar tempo)**
- CSS customizado na página

**Won't (fora da demo, vão para depois do lançamento)**
- Trailer de 60 s (substituído por capturas e um GIF na 6.3)
- Navios modelados com balanço por shader (ficam em *greybox* com luzes)
- Vegetação e rochas de biblioteca, pergaminho no livro, cartão de chamada
- Orca de quatro patas
- Portinho demônio e as relíquias secretas
- Encalhado, Sineiro, Capitã, A Voz, Gaivotas Mudas, Luzes-de-Vigia, Névoa-Viva
- Noites 2–7, finais narrativos, clima dinâmico, barco de suprimentos, sirene de neblina, modo sinal manual
- Dublagem (o áudio continua procedural)
- Versão iOS e publicação na Google Play (o APK sai só pelo itch)

**Não cortar:** a decisão sobre o navio anômalo. É o coração do jogo.

---

## Riscos e dependências

| # | Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|---|
| R1 | **A revisão e o playtest humano não acompanham a produção dos agentes** (fila de revisão cresce, tarefas "prontas" sem validação); o Android soma testes no celular a cada semana | alta | alto | Máximo de 6 revisões por semana; critério de pronto testável por teste headless sempre que possível; checagem de domingo obrigatória; com 3–5 h/semana, aplicar a linha de corte já na S3 |
| R2 | **A arte P0 atrasa** (Blender/MCP não instalado, modelos ruins, retrabalho) e empurra o conteúdo travado | média | alto | Decisão da S0; fallback textura + silhueta em primitivas decidido em 29/11; vegetação de biblioteca cortada |
| R3 | **O beta coincide com o Natal** e o RC1 com o Ano-Novo: pouco retorno de testadores e pouca capacidade para corrigir | alta | alto | Beta na quarta 16/12 (antes do feriado); convidar 6 para obter 3; S6 e S7 só com correção; no máximo 10 "Must fix" |
| R4 | Externalizar strings (4.6) quebra telas tarde demais | média | médio | Feito antes do conteúdo travado; um commit por tela; regressão na 5.5 |
| R5 | Export Web com problema de performance ou tela preta | baixa | alto | Export provado na S0 e em toda checagem semanal; meta de 60 fps e zip < 60 MB na 3.6 |
| R6 | Escopo cresce com criaturas e o Portinho (pedidos novos na `LISTA_ASSETS.md`) | média | alto | Tudo fora do Must/Should está na linha de corte; criatura nova só depois de 07/01 |
| R7 | **Android abaixo de 30 fps** no celular intermediário (fill rate do pós-processo, grama em MultiMesh, aquecimento) | média | médio | Linha de base medida na 0.7; otimização na 3.7; portão M2b em 06/12 corta o Android sem afetar as outras plataformas |
| R8 | **Controles de toque ruins** nos consoles e nas ações de segurar; o jogo foi desenhado para mouse/controle | média | médio | 0.6 cobre consoles e `hold_time`; pelo menos 1 testador Android no beta; checklist de toque na 5.5 |
| R9 | **Cadeia de ferramentas do Android** (SDK, JDK 17, templates, keystore) trava o humano, ou a keystore de release se perde | média | médio | Passo a passo escrito pelo engine-programmer na 0.7; credenciais fora do git; backup da keystore no critério da 5.7 |
| R10 | **Sem semana de folga** entre o congelamento (04/01) e o lançamento (07/01) | alta | alto | RC1 adiantado para 28/12; após 04/01 só hotfix de crash; qualquer atraso antes disso corta pela linha MoSCoW, nunca a data |

**Dependências externas (do humano):** respostas da S0 (idioma, origem dos assets, Blender, celular de referência, preço); Android SDK e JDK 17 instalados até 15/11 (no máximo 22/11); celular intermediário disponível toda semana; 3–5 testadores confirmados até 13/12, pelo menos 1 com Android; conta e página no itch.io; disponibilidade de ~2 h na semana do Ano-Novo para o RC1.

---

## Mudanças vs. versão anterior

Revisão de 12/11/2026. Motivo: lançamento confirmado para **qui 07/01/2027** (antes: qui 14/01, a confirmar) e Android no escopo.

### Tarefas novas

| # | Sprint | Título | Agente | Est. | Pronto quando |
|---|---|---|---|---|---|
| 0.6 | S0 | HUD de toque | game-developer | 1 d | No PC, com "emular toque pelo mouse", um jogador acende a lâmpada pelo console e abre inventário, livro e pausa só pelo HUD; o HUD não aparece com teclado/controle; smoke e puzzle passam |
| 0.7 | S0 | Export Android de teste | engine-programmer + humano | 0,5 d | O APK de debug instala por `adb` num celular real, abre o menu, inicia a partida e mostra o FPS; o número fica anotado como linha de base; credenciais fora do git |
| 3.7 | S3 | Teste em aparelho real e performance Android | engine-programmer + humano | 1 d | No celular de referência, ≥ 30 fps médios e ≥ 25 fps no pior trecho ao longo de uma noite de 15 min; APK < 100 MB; sem fechar por memória; decisão do portão M2b registrada em 06/12 |
| 5.7 | S5 | Página do itch com o APK | engine-programmer + marketing-pr | 0,5 d | APK de release assinado na página privada com instruções PT/EN; o humano baixa, instala e joga até o primeiro navio; keystore com backup fora da máquina |

### Tarefas que mudaram de sprint

| # | Antes | Agora | Observação |
|---|---|---|---|
| 5.1 Logo final e capa provisória | S5 | S4 | Critério ganha o ícone do APK (192 e 432 px) |
| 7.1 Balanceamento final | S7 | S6 | — |
| 7.3 Texto da página | S7 | S6 | Critério ganha a seção de instalação do APK; capturas saem do critério |
| 8.1 RC1 | S8 (seg 04/01) | S7 (seg 28/12) | Agora 4 plataformas (inclui Android) |
| 8.2 Regressão no RC1 | S8 | S7 | 4 plataformas |
| 8.3 Playtest humano final | S8 | S7 | Web e Android (Windows coberto pela 8.2) |
| 8.4 Correções e RC final, tag `v0.1.0-demo` | S8 (qui 07/01) | S7 (RC dom 03/01, tag seg 04/01) | — |
| 6.3 Capturas por script | S6 | S8 (seg 04/01) | Feitas do build congelado; critério ganha 1 GIF de 10 s |
| 8.5 Textos de divulgação | S8 | S8 (sem mudança de sprint; data seg 04/01) | Sprint S8 tem novas datas |
| 9.1 Checagem final da página | S9 (seg 11/01) | S8 (ter 05/01) | Inclui o APK e a checagem no celular |
| 9.2 Publicar | S9 (qui 14/01) | S8 (qui 07/01) | — |
| 9.3 Janela de hotfix | S9 (14–17/01) | S8 (07–10/01) | — |

Tarefas que ficaram na mesma sprint mas tiveram o critério ajustado para o Android ou o toque: 0.4, 1.3, 1.4, 4.3, 4.6, 5.4, 5.5.

### Tarefas cortadas

| # | Título | Motivo |
|---|---|---|
| 3.5 | Vegetação e rochas de biblioteca livre | Era Could; a vegetação atual de `island_details.tscn` basta. Libera a S3 para a 3.7 |
| 4.2 | Navio regular e *Santa Aurora* modelados | Era Could; os navios ficam em *greybox* com luzes de navegação |
| 4.5 | Pergaminho no livro e cartão de chamada | Era Could; o livro e o portátil ficam com o tema atual |
| 7.2 | Trailer de 60 s | Era Should; sem espaço na semana do Ano-Novo. Vai para depois do lançamento; a página usa capturas e um GIF (6.3) |
| 7.4 | Correções restantes do beta (Must e Should) | Absorvida pela 6.2 (Must) e pela 8.4 (bugs do RC1); os Should do beta vão para depois do lançamento |
| — | Orca de quatro patas (decisão 4 da S0) | Era Could; sai da demo. A decisão 4 passa a ser o celular de referência |

### Novas datas

| Sprint | Antes | Agora |
|---|---|---|
| S0 | qui 12/11 – dom 15/11 | sem mudança |
| S1 | seg 16/11 – dom 22/11 | sem mudança |
| S2 | seg 23/11 – dom 29/11 | sem mudança |
| S3 | seg 30/11 – dom 06/12 | sem mudança (meta inclui o portão do Android) |
| S4 | seg 07/12 – dom 13/12 | sem mudança |
| S5 | seg 14/12 – dom 20/12 | sem mudança |
| S6 | seg 21/12 – dom 27/12 · Natal: correções e capturas | sem mudança de datas · Natal: correções, balanceamento e texto da página |
| S7 | seg 28/12 – dom 03/01 · Ano-Novo: balanceamento, trailer e página | sem mudança de datas · Ano-Novo: RC1 e regressão |
| S8 | seg 04/01 – dom 10/01 · RC e congelamento | sem mudança de datas · congelamento, lançamento e hotfix |
| S9 | seg 11/01 – dom 17/01 · lançamento | **eliminada** (milestone pode ser fechada) |

| Marco | Antes | Agora |
|---|---|---|
| M0 · Export provado (novo) | — | dom 15/11 |
| M1 · Loop fechado | dom 22/11 | dom 22/11 |
| M2 · Noite jogável | dom 29/11 | dom 29/11 |
| M2b · Portão do Android (novo) | — | dom 06/12 |
| M3 · Conteúdo travado | dom 13/12 | dom 13/12 |
| M4 · Beta | qua 16/12 (Web + Windows) | qua 16/12 (Web + Windows + APK) |
| M5 · Release candidate | seg 04/01 | **seg 28/12** |
| M6 · Build congelado | qui 07/01 | **seg 04/01** |
| M7 · Lançamento | qui 14/01 (a confirmar) | **qui 07/01** (confirmado; Web, Windows, Linux e Android) |

---

## Backlog de gameplay (feedback do humano, 12/11)

Blocos independentes, feitos um de cada vez, em ordem. Fora do plano até o humano decidir o que entra na demo de 07/01 (combate, carga de caixas e criatura gigante estão hoje na linha *Won't*).

| Bloco | Tema | Estado |
|---|---|---|
| 1 | Abertura que não aparece ao iniciar jogo novo (diálogo sobre a ilha, versão simples) | em andamento |
| 2 | Aviso de chamada: ícone de telefone no canto da tela, som de rádio/telefone, sem texto no meio | pendente |
| 3 | Ritmo e tamanho da noite (~10 min jogáveis), ver abaixo | pendente |
| 4 | Carga dos navios: atracar e carregar/descarregar ~10 caixas (varia com a carga) | pendente, decisão de escopo |
| 5 | Combate secundário estilo Doom: pistola e horda numa chamada falsa | pendente, decisão de escopo |
| 6 | Presença observadora (inimigo gigante; ver `HISTORIA.md`, "o nono ainda vigia") e terror psicológico | pendente, decisão de escopo |

**Bloco 3 (escopo ajustado):** ao aumentar a ilha, entram mais estruturas e **tarefas pequenas e repetitivas** para o jogador cumprir ao longo da noite (manutenção, abastecer, conferir), e **eventos especiais** não previstos no roteiro da noite, mas já descritos no GDD (§4.6 clima: neblina, tempestade que quebra a janela da lanterna; rajadas; falhas do gerador). Eles entram no `.tres` do roteiro da 2.1. As texturas "com cara de ar" ficam na arte P0 da S3.
