# The Last Keeper — Game Design Document

> Versão 0.1 · 2026-11-10 · Godot 4.7 (GL Compatibility, Jolt Physics)

---

## 1. Visão geral

| | |
|---|---|
| **Gênero** | Sobrevivência e gestão em primeira pessoa, com terror atmosférico |
| **Plataforma** | PC (Linux / Windows), com possibilidade de exportar para Web |
| **Estética** | PS1: low-poly, texturas de 64–128 px sem filtro, vértices tremendo, neblina curta, 320×240 |
| **Duração** | 2–3 h (7 noites) |
| **Público** | Fãs de terror indie lo-fi, "jogos de turno" e gestão leve com narrativa |

**Pitch:** você é o único vigia do Farol 7, numa ilha rochosa no fim da rota de navegação. Toda noite você precisa manter a luz acesa, o gerador funcionando e o rádio atento. Os navios que passam dependem de você. Mas nem todo navio que chama pelo rádio deveria estar ali.

**Fantasia do jogador:** ser a última linha de defesa entre o mar e quem está nele, sozinho, com recursos limitados, decidindo quem você ajuda.

---

## 2. Pilares

1. **Rotina sob pressão.** As tarefas são simples (abastecer, consertar, responder), mas competem pelo seu tempo e pelos recursos.
2. **Decidir sem informação completa.** Cada navio é uma decisão: o que você sabe vem do rádio, do livro de registros e do que você vê pelo binóculo.
3. **O estranho chega devagar.** As primeiras noites são quase normais. A anomalia cresce aos poucos, sem *jump scare* barato.
4. **Espaço pequeno, conhecido a fundo.** Uma ilha só, que o jogador aprende a percorrer de olhos fechados, e que muda conforme as noites passam.

---

## 3. Loop de jogo

### Loop principal (uma noite, ~12–15 min reais)

```
Anoitecer → Preparar (abastecer, checar gerador, ler manifesto)
        ↓
Turno: eventos chegam (navio no horizonte, chamada de rádio, falha, clima)
        ↓
Agir: identificar navio → decidir (guiar / alertar / ignorar) → manter sistemas
        ↓
Amanhecer → Relatório da noite (navios salvos/perdidos, recursos, anomalias)
```

### Meta loop (7 noites)

- A cada 2 noites chega um **barco de suprimentos** com óleo, peças e um novo manifesto. A quantidade depende do seu desempenho.
- O livro de registros acumula pistas sobre o que aconteceu com o vigia anterior.
- As escolhas sobre os "navios fantasmas" definem o final.

---

## 4. Mecânicas

### 4.1 A luz do farol
- A lâmpada consome **óleo** de forma contínua. Se o óleo acabar, a luz apaga e navios podem bater nas pedras.
- **Lente:** acumula sal e neblina e perde alcance. É preciso limpá-la com um pano (interação de segurar o botão).
- **Rotação:** o mecanismo de corda precisa ser recarregado com uma manivela a cada ~4 min. Sem isso a luz fica parada, e um navio não reconhece um farol fixo.
- **Modo sinal:** o jogador pode interromper a rotação e piscar a luz manualmente para avisar um navio (padrão curto/longo).
- Óleo, corda e lente são operados pelo **console da lâmpada** (4.1.1). A antiga partida a frio em sequência fixa (óleo → corda → lente, ordem errada emperra) e as estações invisíveis foram substituídas.

### 4.1.1 Puzzle da Lâmpada (console)

Queimador de vapor de óleo, como os faróis reais do início do século XX: o óleo só vira chama se o vaporizador estiver **quente** e o tanque **pressurizado**. O jogador interage uma vez com a lâmpada (`E` / Quadrado) e abre um painel de latão. Não há ordem certa decorada: o puzzle é ler 5 mostradores e mantê-los na faixa verde enquanto eles caem em ritmos diferentes.

**Painel (320×240):** cabeçalho com estado ("APAGADA", "ACESA · alcance 80%", "AFOGADA 6s"); linha de 5 mostradores verticais de latão com faixa verde e vermelha pintadas (ÓLEO, TEMP, PRESSÃO, CORDA, LENTE); linha de 6 botões-ícone 40×40; plaqueta gravada no rodapé: "AQUEÇA ATÉ O VERDE · PRESSÃO NO VERDE · ABRA A VÁLVULA". É o único tutorial.

| # | Ação | Tipo | Ícone (latão PS1) | Som |
|---|---|---|---|---|
| 1 | ABASTECER | segurar 1,5 s, gasta 1 lata | lata de óleo com bico, gota âmbar | glub-glub de líquido em funil metálico |
| 2 | AQUECER | segurar | maçarico com chama azul curta | chiado de maçarico de álcool, sobe de tom |
| 3 | BOMBEAR | toque (0,25 s de recarga) | êmbolo de bomba manual com seta para baixo | "tchuf" de bomba de ar com rangido de couro |
| 4 | VÁLVULA | toque (abre/fecha) | volante redondo de válvula | rosca girando + "fuump" de ignição |
| 5 | CORDA | toque no ritmo | manivela em L sobre engrenagem | catraca: clique seco por batida |
| 6 | LENTE | segurar 3 s | pano dobrado sobre anel de Fresnel | fricção úmida em vidro, rangido agudo |

**Regras (valores iniciais, 0–100):**
- **TEMP:** AQUECER +20/s; sem chama cai 4/s; acesa se mantém em 80 enquanto PRESSÃO ≥ 25. Verde ≥ 70.
- **PRESSÃO:** BOMBEAR +8 por toque. Verde 45–75. Vaza 0,5/s apagada e 0,25/s × (1 + p) acesa (p = `progress()`). Acima de 90 a válvula de segurança chia e despeja até 70.
- **Ignição:** abrir a VÁLVULA com ÓLEO > 0, TEMP verde e PRESSÃO verde acende. Como TEMP cai rápido e PRESSÃO devagar, a solução é bombear primeiro e aquecer por último. Essa é a descoberta do puzzle, legível pelos ponteiros.
- **ÓLEO:** acesa queima 100 em 240 s × (1 + p). ABASTECER +50 por lata. Em 0, apaga.
- **CORDA:** desenrola 100 em 150 s (zero se o circuito do motor estiver energizado). A catraca bate num pulso visível e audível; tocar na janela de ±0,15 s dá +10, fora dela +3; 3 erros seguidos fazem a catraca escapar (−20, estalo metálico). Em 0 o feixe para (farol fixo).
- **LENTE (sujeira):** +100 em 360 s × (1 + p). Alcance = (1 − sujeira) × fator de pressão.
- **Escolha de pressão:** no terço de cima do verde o alcance ganha +20% (útil com neblina ou navio longe), mas o óleo queima ×1,3 e a lente suja ×1,5. Pressão baixa poupa óleo e encurta o alcance. É uma decisão, não um valor certo.

**Falhas e consequências:**
- **Afogar** (abrir a válvula com TEMP < 70): fumaça preta, sujeira +25, TEMP → 0, PRESSÃO −20 e válvula travada por 8 s. Custa tempo e lente.
- **Pressão fora do verde ao abrir:** abaixo, "pfft" sem chama e −2 de óleo; acima, labareda que acende mas suja +15.
- **Chama acesa com PRESSÃO < 25:** apaga. Se TEMP ainda estiver ≥ 70 (cerca de 3 s), reacende sem reaquecer.
- **Acima de 75 rodando:** fuligem, sujeira ×3.
- **Luz apagada, farol fixo ou alcance < 40%** contam como farol falhando para os navios (risco de `ships_lost`). Corda em 0 também libera as criaturas (HISTORIA §"a corda é o relógio").

**Escala com `progress()` (p de 0 a 1):** a faixa verde de PRESSÃO estreita de 45–75 para 50–68; os vazamentos de pressão, óleo e sujeira crescem × (1 + p); a batida da corda acelera de 0,8 s para 0,55 s. Com p ≥ 0,5 entram as **rajadas**: a cada 60–90 s o vento derruba PRESSÃO −15 e TEMP −20 (uivo e chama tremendo no mundo).

**Manutenção recorrente (por que voltar):** com p = 0, bombear a cada ~2 min, dar corda a cada ~2,5 min, abastecer a cada ~2 min de queima por lata, limpar a cada ~4 min. No fim da noite os intervalos caem pela metade e as rajadas surgem fora de hora. Nada se resolve sozinho, e a rampa de 14 s faz cada visita competir com o rádio e o gerador.

**Mundo não pausa:** o relógio, o consumo, os navios e as criaturas seguem com o painel aberto. Só o movimento e o olhar do jogador ficam travados. Pausar mataria o pilar "rotina sob pressão" e transformaria o painel em esconderijo. Áudio 3D e mensagens do HUD continuam.

**Controles:**
- Teclado/mouse: clicar no ícone (segurar o clique para ações contínuas); `1`–`6` como atalhos; `A`/`D` ou setas para mover o foco; `E` ou Espaço para ativar (segurar quando for contínua); `Esc`, `E` com o painel ocioso ou `Q` para fechar.
- PS4: direcional ou analógico esquerdo move o foco; X ou Quadrado ativa (segurar quando for contínua); Círculo fecha; Options fecha e pausa.
- O foco começa na ação mais urgente (o mostrador mais perto do vermelho).

**Mundo 3D:** saem as estações invisíveis de óleo, corda e lente (`_add_station` em `beacon.gd`); fica um único `Interactable` na lâmpada, com o prompt "Console da lâmpada". O feedback fica na peça física: brilho e cor da chama seguem PRESSÃO (laranja fraco e trêmulo abaixo do verde, branco com fumaça acima), a cabeça gira na velocidade da CORDA, o alcance do `SpotLight3D` segue o alcance calculado, e há partícula de fumaça preta quando afoga. Um manômetro de agulha na base é legível sem abrir o painel.

**Critérios de pronto:**
1. Interagir com a lâmpada abre o painel. Não existe mais `Interactable` de óleo, corda ou lente na cena.
2. As 6 ações funcionam pelo mouse, pelos atalhos `1`–`6`, pela navegação de foco e pelo controle PS4, cada uma com ícone e som distintos.
3. Partida a frio: bombear até 60, aquecer até 70 e abrir acende. Abrir com TEMP 50 afoga (sujeira +25, válvula travada 8 s).
4. Com o painel aberto o relógio (`GameState.minutes`) avança e os mostradores caem.
5. Corda: toques no pulso somam +10, fora somam +3, 3 erros seguidos −20. Com corda em 0 a cabeça para.
6. Com p = 1 a faixa verde vai a 50–68 e a batida a 0,55 s. Com p ≥ 0,5 ocorrem rajadas.
7. ABASTECER sem lata não faz nada e mostra "Sem óleo" via `GameState.say()`.
8. `tests/puzzle_test.gd` e `smoke_test.gd` atualizados cobrem acender, afogar e apagar por pressão.

### 4.2 Gerador
- Alimenta o **rádio**, a **sirene de neblina** e a iluminação interna. A luz do farol é a óleo e não depende dele.
- Consome **diesel**, que é um estoque separado do óleo do farol.
- **Falhas:** fusível queimado, correia solta ou superaquecimento. Cada uma pede um conserto curto, um minigame físico de trocar a peça na posição certa.
- Se o gerador desligar, o rádio fica mudo.

### 4.3 Rádio
- Os navios chamam com **nome, destino e posição aproximada**.
- O jogador responde com opções curtas: confirmar rota, alertar sobre perigo, pedir identificação ou ficar em silêncio.
- **Sintonia:** girar o dial para achar a frequência. Há estática, sobreposição e, com o tempo, vozes que não deveriam estar ali.

### 4.4 Identificação de navios
Todo navio tem três fontes de informação, que podem concordar ou não:

| Fonte | Como obter |
|---|---|
| **Manifesto** | Lista de navios esperados na semana (papel na mesa) |
| **Rádio** | O que o navio diz sobre si |
| **Binóculo** | Padrão de luzes, formato do casco e direção real |

- **Navio regular:** as três fontes batem. Guiar corretamente rende reputação e suprimentos.
- **Navio anômalo:** algo não bate (não está no manifesto, as luzes estão erradas, o nome é de um navio afundado há décadas).
- **Decisão:** guiar, alertar (sirene ou sinal de luz) ou ignorar. Cada escolha tem consequência imediata (o navio passa, bate ou some) e consequência acumulada (a ilha muda).

### 4.5 Recursos e estoque

| Recurso | Uso | Reposição |
|---|---|---|
| Óleo de farol | Lâmpada | Barco de suprimentos |
| Diesel | Gerador | Barco de suprimentos |
| Peças (fusíveis, correias) | Consertos | Barco de suprimentos e itens achados na ilha |
| Panos | Limpar a lente | Lavar no varal (custa tempo) |

O estoque é físico: latas e caixas no depósito, carregadas à mão escada acima. Carregar ocupa as mãos e deixa o jogador mais lento.

### 4.6 Clima
- **Neblina:** reduz o alcance da luz e do binóculo. A sirene passa a ser necessária.
- **Tempestade:** aumenta o consumo, causa mais falhas e pode quebrar a janela da lanterna (exige conserto).
- **Mar calmo:** noite tranquila, com mais navios.

O clima de cada noite é definido por roteiro, com pequenas variações aleatórias.

### 4.7 Livro de registros
- É o diário do jogador e também a UI de progresso. Ali se anotam os navios vistos, as decisões e as falhas.
- Ele traz páginas do vigia anterior, que vão sendo destravadas aos poucos e funcionam como o canal principal da narrativa.

### 4.8 Rádio portátil
Receptor de mão que retransmite o rádio da casa. Vem no baú do píer (`chest.gd`), junto com lanterna, óleo e combustível. Substitui o `calls_panel` do HUD: fila de chamadas, frequência, nome, rumo, carga declarada e as 3 últimas entradas do registro passam a viver só na tela dele.
- **Abrir/fechar:** `R` (teclado) e direcional para cima (PS4). Fecha com `R`, `Esc`, `Q` ou Círculo. Como os consoles, **o mundo não pausa**: só movimento e olhar travam.
- **Chamada nova:** só um bipe curto 3D no jogador, sem texto no HUD. O jogador decide se abre.
- **Ações no portátil:** ATENDER (faz o contato, equivale a sintonizar no fixo, e o navio aceita esperar: timeout 45 s +30 s, uma vez por chamada), RECUSAR (definitivo, mesma consequência do fixo) e PEDIR REPETIÇÃO (sorteia a estática de novo, 4 s, custa 5 de bateria).
- **O que só o rádio fixo faz:** AUTORIZAR atracação (a ordem final), sinal sempre limpo e recarga. Recusar de longe é possível, mas é uma aposta: o portátil mostra o que o navio *diz*. A mentira (1 navio a cada 3, 1 a cada 2 depois da meia-noite) só aparece comparando a carga com o livro (J).
- **Alcance (distância ao rádio da casa):** até 20 m, limpo. De 20 a 40 m, estática: nome e carga perdem 30% a 60% das letras (`#`), crescendo com a distância. Acima de 40 m ou no porão: "CHAMADA ENTRANDO", sem dados. O topo do farol conta como limpo (altura), e isso o jogador aprende sozinho. Sem energia no circuito `radio` (gerador ou disjuntor desligado), mostra "SEM PORTADORA".
- **Bateria (0–100):** começa em 100. Gasta 0,5/s com a tela aberta e 0,05/s em espera, o que dá ~110 s de tela por noite. Recarrega +2/s na base da casa (interagir; o portátil fica na base e sai do inventário). Em 0: sem bipe e sem tela.

**Critérios de pronto:** (1) abrir o baú adiciona o portátil; (2) `R`/direcional abre e fecha, e `GameState.minutes` avança com a tela aberta; (3) a 30 m a carga aparece com `#` e a 10 m aparece inteira; (4) ATENDER estende o timeout uma vez e AUTORIZAR não existe no portátil; (5) com o disjuntor `radio` desligado aparece "SEM PORTADORA"; (6) a bateria cai 0,5/s aberta e sobe na base; (7) `calls_panel` não aparece mais no HUD.

### 4.9 Inventário (32 slots)
Tela do `Tab`/Triângulo, desenhada como uma caixa de latão. **O mundo não pausa.** Layout em 320×240: grade 8×4 de slots 26×26 (2 px de espaço) à esquerda, coluna de status (4.10) à direita (64 px), nome, quantidade e descrição do item selecionado embaixo. Notas e pistas (`Clue`, código do cadeado) vão para o livro, não ocupam slot.

| Item | Pilha | Onde | Usar |
|---|---|---|---|
| Lanterna | 1 | baú | liga/desliga (= `F`) |
| Rádio portátil | 1 | baú | abre a tela (= `R`) |
| Lata de óleo | 4 | baú, tambor | gasta no console da lâmpada (ABASTECER) |
| Lata de combustível | 2 | baú, galpão | gasta no gerador |
| Garrafa d'água | 3 | galpão, despensa | sede +35 |
| Lata de conserva | 3 | casa, despensa | fome +40, sede −5 |
| Bolacha | 5 | galpão | fome +15 |
| Curativo | 2 | casa, despensa | vida +40 (4 s) |

- **Ações** (clique, X ou E no slot abre o menu): USAR (itens de puzzle só respondem "Use no console…", porque o consumo continua automático nas estações), EXAMINAR (1–2 linhas de texto, às vezes com pista) e LARGAR (cria um item no chão à frente com o prompt "Pegar"; nada some).
- Comer, beber e fazer curativo levam 2 s, 2 s e 4 s com a tela aberta. Com o mundo correndo, comer na escada é um risco.
- **Peso:** 4 ou mais latas (óleo + combustível) somadas tiram a corrida (GDD 4.5). Com o inventário cheio aparece "Inventário cheio" e o item fica no lugar.
- `oil_cans`, `fuel_cans` e `has_flashlight` passam a ser contagens derivadas do inventário, e a API dos puzzles não muda.

**Critérios de pronto:** (1) a grade 8×4 cabe em 320×240, navegável por mouse, teclado e PS4; (2) 5 latas de óleo ocupam 2 slots (4+1); (3) LARGAR cria um pickup que devolve o item; (4) USAR na garrafa sobe a sede em 35 e consome 1; (5) o relógio avança com a tela aberta; (6) `puzzle_test.gd` continua passando.

### 4.10 Vida, sede e fome
Pressão de fundo, não uma segunda rotina: numa noite bem jogada, o jogador bebe uma vez e come uma vez. Os valores aparecem **só na tela de inventário**, em três barras verticais sem número, com um risco em 20. Taxas por hora de jogo (1 h = 72 s reais).

| Status | Início | Queda | Zera sem reposição | Em 0 |
|---|---|---|---|---|
| Sede | 80 | −8/h, ×1,5 correndo | ~03:30 | vida −1/min de jogo e sem corrida |
| Fome | 60 | −5/h, ×1,5 ao ar livre depois das 02:00 (frio) | ~04:40 | vida −0,3/min de jogo e sem corrida |
| Vida | 100 | — | — | morte |

- **Fontes (poucas e fixas):** **cisterna da casa** (beber no local, segurar 2 s, sede +35, infinita; fica junto do rádio, então ir beber e ir autorizar viram uma viagem só); **casa:** 1 conserva e 1 curativo no armário; **galpão:** 1 garrafa e 2 bolachas; **despensa do porão** (cadeado 8-3-5): 3 conservas, 2 garrafas e 1 curativo, a recompensa por resolver o cadeado. O baú não traz comida.
- **Dano à vida:** queda acima de 3 m: (altura − 3) × 12, então cair do topo mata; mar ou pedras do ilhéu submersas (`tide.gd`): −3/s na água e frio em dobro por 60 s; criaturas soltas com a corda em 0: −35 por toque, com 3 s de invulnerabilidade (3 toques matam).
- **Regeneração:** +1/min de jogo até 70 se sede e fome estiverem ≥ 50. Acima de 70, só com curativo.
- **Morte:** o som cai, ruído branco e fade; o resumo da noite mostra a causa ("A sede", "O mar", "Algo na escada") e oferece recomeçar a noite. Não há *jump scare*.
- **HUD:** nada em nível normal. Só no crítico (sede ou fome ≤ 20, vida ≤ 30) aparece um ícone 8×8 no canto inferior esquerdo, piscando devagar, um por status e no máximo três. Cada um tem uma deixa sonora: garganta seca, estômago, coração. Some quando sai do crítico.

**Critérios de pronto:** (1) sem beber, a sede chega a 0 por volta das 03:30 e, correndo, mais cedo; (2) com a sede em 0 a vida cai 1 por minuto de jogo e a corrida é bloqueada; (3) a cisterna dá +35 infinitamente; a despensa só abre com 8-3-5; (4) uma queda de 8 m tira 60; (5) o ícone de HUD aparece só abaixo dos limiares e some acima; (6) com vida 0 o resumo mostra a causa; (7) um teste headless força os status e verifica taxas e limiares.

---

## 5. Progressão (7 noites)

| Noite | Novidade | Clima | Tom |
|---|---|---|---|
| 1 | Tutorial: lâmpada, corda, rádio | Calmo | Normal |
| 2 | Gerador e primeira falha | Neblina leve | Normal |
| 3 | Primeiro barco de suprimentos, manifesto completo | Calmo | Primeiro navio fora do manifesto |
| 4 | Sinal manual de luz | Tempestade | Vozes no rádio |
| 5 | Navios afundados passam a chamar | Neblina densa | A ilha muda (objetos fora do lugar) |
| 6 | Recursos escassos (suprimentos reduzidos) | Tempestade | O farol "responde" sozinho |
| 7 | Noite final, todas as mecânicas | Variável | Confronto com a escolha principal |

---

## 6. Narrativa

**Premissa:** o Farol 7 foi reativado depois de 30 anos fechado. O vigia anterior desapareceu na mesma noite em que o cargueiro *Santa Aurora* afundou nas pedras da ilha, com 40 tripulantes.

**O mistério:** os navios fantasmas são as embarcações que se perderam nessa costa. Eles chamam pedindo orientação para "voltar para casa".

**A escolha:** guiar os fantasmas significa abrir passagem para algo que vem com eles. Ignorá-los é deixar que continuem presos.

**Finais (3):**
1. **O Vigia:** você guiou só os navios vivos. O farol segue funcionando e você é substituído normalmente. Os fantasmas continuam lá.
2. **A Passagem:** você guiou os fantasmas, incluindo o *Santa Aurora*. A ilha "afunda" com você e eles finalmente atracam.
3. **O Substituto:** muitos navios perdidos (vivos ou mortos). Você se torna a próxima voz no rádio.

**Tom:** melancólico antes de assustador. O medo vem da solidão e da responsabilidade, não de monstros.

---

## 7. Mundo: a ilha

```
          [Farol] — topo: sala da lanterna (lâmpada, lente, manivela)
             |       base: depósito (óleo, peças)
   [Casa do vigia] — sala do rádio, mesa, livro de registros, cama (fim da noite)
             |
   [Galpão do gerador] — gerador, diesel, ferramentas
             |
   [Píer] — chegada dos suprimentos
             |
   [Pedras / costa] — destroços, itens, lugar dos eventos estranhos
```

- A ilha tem ~76 m de diâmetro (~25 s de ponta a ponta andando). Ir e voltar entre o rádio, a lâmpada e o gerador é a principal tensão de tempo.
- **Escada do farol:** rampa em espiral de 16 m, ~14 s para subir. É deliberadamente longa e é onde acontecem vários eventos. O rádio fica na casa, ao pé do farol, para que atender uma chamada exija descer.

---

## 8. Controles

| Ação | Teclado / mouse | Controle PS4 |
|---|---|---|
| Mover / olhar | WASD / mouse | analógico esquerdo / direito |
| Correr | Shift (bloqueado com sede ou fome em 0, ou 4+ latas) | L3 |
| Pular | Espaço | X |
| Interagir / pegar item no chão | E (segurar nas ações contínuas) | Quadrado |
| Lanterna | F | R1 |
| Rádio portátil | R | direcional para cima |
| Inventário | Tab | Triângulo |
| Livro de registros | J | L1 |
| Pausa | Esc | Options |

**Consoles (lâmpada, quadro de força, rádio portátil):** clique no ícone (segure nas ações contínuas), `1`–`N` como atalho, `A`/`D` ou setas movem o foco, `E`/Espaço usa; fecha com `Q`, `Esc` (ou `R` no rádio). No PS4: direcional ou analógico move o foco, X ou Quadrado usa, Círculo fecha e Options fecha e pausa.

**Inventário (como no Minecraft):** clique esquerdo pega a pilha inteira e a coloca, junta ou troca; clique direito pega metade ou coloca 1; Shift+clique usa; `Q`, ou clicar fora da grade segurando algo, larga no chão; passar o mouse mostra a descrição. Sem mouse: setas ou WASD movem o cursor de slot, Espaço pega/coloca, `E` usa, `F` divide, `Q` larga, `Tab` ou `Esc` fecha. No PS4: direcional ou analógico move, X pega/coloca, Quadrado usa, Círculo larga, R1 divide e Triângulo fecha.

---|---|
| Mover / olhar | WASD / mouse |
| Interagir | E (segurar para ações contínuas) |
| Binóculo | Botão direito |
| Livro de registros | Tab |
| Lanterna de mão | F |
| Correr | Shift (limitado ao carregar algo) |

---

## 9. Direção de arte e técnica

### Visual PS1
- **Render nativo em 320×240** (stretch mode `viewport`, escala inteira para a janela de 960×720).
- **Shader de vértice com snapping** (o jitter), com intensidade configurável pelos *shader globals* `psx_vertex_snap` e `psx_affine_strength`.
- **Mapeamento afim de textura** (a distorção típica do PS1), aplicado só em superfícies grandes.
- **Texturas** de 64×64 a 128×128, filtro *Nearest*, paleta reduzida.
- **Neblina** forte via `WorldEnvironment`. Ela também esconde o limite de desenho.
- **Dithering** e redução de profundidade de cor no pós-processamento.
- **Modelos** de 300–1500 triângulos. O jogador não tem corpo visível, só as mãos.

### Paleta
Azul-petróleo e cinza para o mar e a noite, amarelo-âmbar para a luz do farol, que é a única cor quente e o ponto de foco. O vermelho fica reservado para alertas e anomalias.

### Técnica
- **Godot 4.7** com GL Compatibility, que serve à estética e roda em hardware fraco e na Web.
- **GDScript** com tipagem estática.
- **Arquitetura:** cada sistema (Lâmpada, Gerador, Rádio, Clima, Navios) é um nó com estado próprio e se comunica por *signals*. Um `NightDirector` (autoload) lê o roteiro da noite e dispara os eventos.
- **Roteiro das noites** em `Resource` (`.tres`), para editar sem mexer no código.
- **Save:** só entre as noites (um `ConfigFile` ou JSON simples).

---

## 10. Áudio

- **Ambiente:** mar, vento e o rangido do mecanismo de rotação, que é o "relógio" sonoro do jogo. Se ele parar, o jogador percebe pelo som.
- **Rádio:** estática processada e vozes com filtro de banda estreita.
- **Sirene de neblina:** grave, e funciona como ferramenta de gameplay.
- **Música:** quase nenhuma. Só drones nas noites 5–7 e no final.
- **Áudio 3D** posicional para os eventos na ilha.

---

## 11. UI / HUD

- **HUD mínimo:** só um ponto de mira e um ícone de interação.
- O estado dos sistemas é lido **no mundo**: medidor de óleo na lâmpada, mostrador do gerador, relógio de parede.
- O livro de registros e o console da lâmpada (4.1.1) são as únicas telas "de menu" e são desenhados como objetos físicos.
- **Menus:** principal, pausa e opções (sensibilidade, intensidade do jitter, volume).

---

## 12. Escopo

### MVP: protótipo jogável (meta: 3–4 semanas)
- [ ] Ilha *greybox* com farol, galpão e píer
- [ ] Controle em primeira pessoa e sistema de interação
- [ ] Lâmpada (óleo, corda, lente) funcionando
- [ ] Gerador com uma falha
- [ ] Rádio com 3 chamadas roteirizadas
- [ ] 1 navio regular e 1 anômalo, com decisão e consequência
- [ ] 1 noite completa do anoitecer ao amanhecer
- [ ] Shader PS1 básico (resolução, jitter, neblina)

### Versão completa
- 7 noites, 3 finais, clima dinâmico, barco de suprimentos, livro de registros com narrativa, arte e áudio finais, menus e save.

### Fora do escopo
- Multiplayer, mundo aberto, combate, crafting complexo, dublagem completa.

---

## 13. Riscos

| Risco | Mitigação |
|---|---|
| Tarefas repetitivas ficarem chatas | Cada noite adiciona uma variação. Testar a 1ª noite cedo |
| Identificar navios ficar confuso | Poucas variáveis (3 fontes) e o manifesto sempre à mão |
| Arte demorar | Estética PS1 é barata, mas definir um *style guide* antes de modelar |
| Terror não funcionar | Priorizar áudio e ritmo. Testar com outras pessoas a partir da noite 4 |
| Escopo narrativo crescer | Texto fechado por noite em `.tres`, sem ramificações além dos 3 finais |

---

## 14. Questões em aberto

1. ~~**Nome final**~~ — definido: **The Last Keeper** (2026-11-10).
2. **Idioma:** só português ou português + inglês desde o início?
3. **Distribuição:** itch.io (gratuito ou pago) ou Steam?
4. **Tempo de dedicação** por semana, que define o cronograma real.
5. **Arte:** você modela (Blender) ou usamos assets low-poly prontos com texturas próprias?
