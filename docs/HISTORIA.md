# The Last Keeper — Bíblia Narrativa

> Versão 0.1 · 2026-11-11 · Complementa `docs/GDD.md` (seção 6) e `docs/PLANO.md`.
> Tudo que o jogo já mostra (textos de `game_state.gd`, `puzzles/radio.gd`, `ui/overlay.gd` e as `Clue` de `world/island_details.tscn`) é **canon** e está incorporado aqui. O que é proposta nova vem marcado com **[NOVO]**.

## Sumário

1. [Logline e tom](#1-logline-e-tom)
2. [A ilha e o Farol 7](#2-a-ilha-e-o-farol-7)
3. [O protagonista: Tomé Valadares](#3-o-protagonista-tomé-valadares)
4. [Bestiário e escala de ameaça](#4-bestiário-e-escala-de-ameaça)
5. [O rádio, os navios e as chamadas anômalas](#5-o-rádio-os-navios-e-as-chamadas-anômalas)
6. [Cronologia da noite (17:30 → 06:00)](#6-cronologia-da-noite-1730--0600)
7. [Segredos, pistas e finais da Noite 1](#7-segredos-pistas-e-finais-da-noite-1)
8. [Ganchos para as noites 2–7](#8-ganchos-para-as-noites-27)
9. [Glossário](#9-glossário)
10. [Motivos recorrentes](#10-motivos-recorrentes)
- [Apêndice A: Notas para implementação](#apêndice-a-notas-para-implementação)

---

## 1. Logline e tom

**Logline.** Numa ilha onde oito vigias já foram enterrados, o nono sumiu e o décimo chega para uma noite de turno: manter a luz acesa, o gerador vivo e o rádio atento, decidindo quais vozes vindas do mar são navios e quais são os afogados pedindo para voltar para casa.

**Tom.** Melancólico antes de assustador (GDD §6). Terror por **implicação**, não por exibição: o que está errado é quase sempre um detalhe (uma carga que não bate, um sino sem badalo, pegadas molhadas que terminam no mar). Solidão, culpa e dever; o mar como memória que não esquece.

**Pilares narrativos**

| Pilar | Como aparece |
|---|---|
| A regra é a moral do jogo | "Carga diferente da registrada: não autorize." É útil, é segura, e é também a regra que condenou gente inocente. O jogo pergunta se obedecer sempre basta. |
| O estranho chega devagar | Noite 1 é quase normal; a primeira meia hora após a meia-noite é o primeiro "erro" visível do mundo. |
| Culpa compartilhada | Toda decisão deixa registro no livro. O jogador herda a culpa do protagonista e a do vigia anterior. |
| Luz é compromisso | A lâmpada é a única cor quente (âmbar). Apagá-la tem custo moral, não só mecânico. |

**Estética PS1 a serviço do medo.** Neblina curta esconde o que se aproxima; o jitter de vértices fica mais forte em tudo que é "errado" (silhuetas no mar, mão no vidro); dithering nas sombras faz formas parecerem se mexer quando não se mexem. Áudio manda: mar, mecanismo girando (o relógio sonoro), estática. Vermelho só para anomalia.

**Regra de ouro de escrita.** Nunca explicar o monstro. Mostrar a consequência, depois o indício, depois (só no livro) o nome.

---

## 2. A ilha e o Farol 7

### 2.1 Por que ali

A ilha não tem nome nos mapas náuticos; a Marinha a chamava de **Ponto 7**, o sétimo ponto de uma cadeia de faróis ao longo de uma rota de cabotagem. É um dente de rocha em que a corrente de maré **empurra para dentro** em vez de afastar. A costa sudoeste (onde hoje jaz o naufrágio) tem recifes que só aparecem na baixa-mar. Por isso o farol foi construído: **não para guiar, mas para avisar**. Em termos de lore: *o farol nunca disse "venha"; disse "aqui não"*. Essa inversão é a chave do final verdadeiro.

### 2.2 Linha do tempo da ilha

| Ano (aprox.) | Evento |
|---|---|
| 1887 | O **bergantim *Esperança*** (pescadores e família) naufraga nos recifes SO. Primeiros mortos da costa. Os sobreviventes enterram os corpos no platô norte-oeste: nasce o **cemitério**. |
| 1891 | Construção do **Farol 7** pela Companhia de Faróis e Balizas. Pedra, ferro e uma lente de Fresnel de segunda mão. A rampa em espiral interna (16 m) foi uma gambiarra de engenheiro: a escada original não coube no cálculo de peso. |
| 1891–1960 | Quatro vigias, uma família de zeladores e uma sequência de mortes banais (febre, queda, afogamento). Os túmulos crescem. |
| 1923 | O **vapor *Imperatriz*** (passageiros) bate nos recifes numa noite de neblina com a luz acesa mas *parada* (a corda do mecanismo acabou). Primeiro caso registrado de "o navio não reconhece um farol fixo". |
| 1961 | O **rebocador *Dois Irmãos*** perde-se tentando socorrer um barco. Chama pelo rádio por horas. |
| 1978 | A traineira ***Maria da Graça*** some. O vigia da época anota "nada a fazer, ninguém respondeu". |
| ~30 anos antes do jogo | **A noite do *Santa Aurora***. O cargueiro, com 40 tripulantes, chamou a costa pedindo orientação, declarando uma carga que **não batia com o registro** (carga adulterada: contrabando). Pela regra do posto, a chamada foi **recusada**. O navio bateu nas pedras do SO. Na mesma noite o **vigia (o nono) desapareceu**. O farol foi lacrado. |
| 30 anos de silêncio | A ilha fica fechada. O mar não. |
| Hoje | A Companhia reativa o Farol 7 por pressão de armadores ("a rota voltou a ser usada"). O décimo vigia é enviado. |

### 2.3 O cemitério

49 sepulturas (o jogo já tem o cemitério com um **monumento central** e uma luz de túmulo, `GraveLight`). **Canon do jogo:** *"Inscrição: OITO vigias descansam aqui. O nono ainda vigia."*

**Explicação.** Dos 49 túmulos, **8 são de vigias** (cruz de ferro, nome gravado). Os outros 41 são os náufragos do *Esperança*, do *Imperatriz* e de outros; muitos sem nome, só uma pedra. O **nono vigia** (Anselmo Quaresma, ver §2.5) não está enterrado em lugar algum: *ainda vigia*. É uma frase que o jogador lê como epitáfio na noite 1 e, nas noites seguintes, como ameaça literal.

Regra de atmosfera: a luz do túmulo (âmbar fraca) só acende de verdade depois da meia-noite. Antes, é só uma lanterna velha.

### 2.4 O naufrágio na costa

O casco a sudoeste (a "Wreck", com costelas e mastro quebrado, ~(-40, 24) no mapa) é o ***Santa Aurora***. Cargueiro de 90 m, 40 tripulantes, **bateu nos recifes às 03h05 do dia 8 de março**. Esse é o **8-3-5** do cadeado do porão (ver §10).

O que o jogador pode saber, em camadas:
1. **Visual:** é um casco antigo, enferrujado, tamanho exagerado para a ilha.
2. **Livro (vigia 9):** "A recusa foi correta. Eu confirmei três vezes."
3. **Verdade:** a carga declarada não batia porque o capitão ocultou contrabando, mas o navio estava **adernando e sem rumo**; a chamada era um pedido de socorro disfarçado de rotina. Quem estava ao rádio era um jovem operador da Estação Costeira 12, **Tomé Valadares**, o protagonista (ver §3).

### 2.5 Os vigias anteriores (dez no total contando o jogador)

| # | Nome | Período | Destino | O que deixou |
|---|---|---|---|---|
| 1 | Augusto Pires | 1891–1903 | Febre, enterrado | Primeira pedra do cemitério. |
| 2 | Joaquim Bento | 1903–1908 | Queda na rampa | A frase "a rampa é longa de propósito". |
| 3 | Nair Cavalcante | 1908–1919 | Natural | Única vigia mulher; criou a rotina do livro de registros. |
| 4 | Olavo Brito | 1919–1931 | Afogado no ilhéu | Marcou a regra da maré baixa. |
| 5 | Eusébio Lemos | 1931–1944 | Natural | Nota sobre o sino. |
| 6 | Valdemar Costa | 1944–1957 | Desapareceu na neblina, corpo achado ao amanhecer na praia | Primeira anotação de "vozes nos canais". |
| 7 | Raimundo Teles | 1957–1970 | Natural | Reformou o galpão e o gerador. |
| 8 | Ismênia Dutra | 1970–1989 | Natural | Esta é a que mais escreveu sobre o *Dois Irmãos* e a *Maria da Graça*. |
| 9 | **Anselmo Quaresma** | 1989–*Santa Aurora* | **Desapareceu** | O diário "perdido" (páginas no porão e na casa). É a Voz. |
| 10 | **Tomé Valadares** | Hoje | ? | O jogador. |

> *Nota de coerência:* o texto do monumento diz oito vigias enterrados e o nono "ainda vigia". Os números acima respeitam isso (1–8 enterrados, 9 sumido, 10 você).

### 2.6 O ilhéu do tambor

Rochedo a leste, ligado à ilha por pedras que **só emergem na baixa-mar** (`tide.gd`: ciclo de 120 s, 35% do tempo em baixa). Ali fica o **tambor de óleo** com 3 latas (`oil_drum.gd`). **História:** o vigia 4, Olavo Brito, afogou-se ali; desde então a Companhia deixa as reservas no ilhéu *de propósito*, para obrigar o vigia a atravessar com cuidado e a não deixar o farol sem óleo por preguiça. A maré tem ritmo próprio: a água "chama" quem está nas pedras.

**Lore sutil:** a maré sobe 10 segundos depois do aviso do jogo (`warning = 10`). Pessoas que estavam nas pedras relatam que a água sobe **mais rápido** quando alguém os observa da praia.

### 2.7 O píer, o galpão e a casa

- **Píer:** onde chegam os suprimentos e onde o vigia desembarca. O baú (`chest.gd`) traz lanterna, óleo e combustível: o kit padrão de chegada. *Etiqueta do caixote:* "LOTE 3, ÓLEO DE LAMPARINA" (o **3** do cadeado).
- **Galpão:** gerador e barris de combustível. *Placa do tanque:* "CAPACIDADE 5 LATAS" (o **5** do cadeado).
- **Casa do vigia:** rádio, livro, caixa de fusíveis (disjuntores `radio`, `house`, `motor`; o gerador aguenta 2), cama e **porão com cadeado** (8-3-5): a reserva do vigia 9.

---

## 3. O protagonista: Tomé Valadares

**Nome:** Tomé Valadares (o jogo não o nomeia; o livro e as cartas sim). **Idade:** 52. **Antes:** radiotelegrafista da Estação Costeira 12 (30 anos atrás, 22 anos de idade).

**Como chegou.** Pediu o posto. A Companhia estranhou: ninguém pede o Farol 7. Chegou de barco no fim da tarde, às 17:30 (primeira linha do jogo: *"17:30. O sol está baixo. Você assume o Farol 7 até o amanhecer."*), foi deixado no píer, ao lado de um baú. O barqueiro não desembarcou.

**Motivação (declarada):** dinheiro e silêncio. **Motivação (real):** reparar o que fez.

**O segredo.** Na noite do *Santa Aurora*, Tomé era o operador de plantão na Estação 12 e recebeu a chamada do cargueiro. A carga declarada não batia com o registro. Pela regra ("carga diferente da registrada: não autorize"), ele **recusou**, confirmou três vezes e dormiu depois. Só dias depois viu que o *Santa Aurora* estava adernando e que a voz do imediato dizia o nome do navio devagar, **repetindo**, pedindo ajuda por código. Ele nunca contou. A recusa foi correta segundo o manual. A mesma regra que o jogo ensina é a que matou 40 pessoas.

**Arco.**

| Fase | Estado | Sinal no jogo |
|---|---|---|
| Noites 1–2 | Profissional, controlado. Aprende a rotina. | Texto seco, anotações de procedimento. |
| Noites 3–4 | Começa a duvidar da regra. Reconhece vozes. | Anotações cada vez mais pessoais; menciona "a estação". |
| Noites 5–6 | Colapso e confissão ao livro. | Páginas escritas por ele que o jogador não escreveu (ver §8). |
| Noite 7 | Escolha: obedecer à regra de novo ou julgar. | Final. |

**O que o livro de registros revela dele.** Nada diretamente. O livro tem as páginas dos antecessores e **o que o jogador anota** (as `Clue` lidas viram anotações via `GameState.add_note`). A revelação chega por contraste: a letra do vigia 9 no livro se parece com a letra do jogador. Na noite 5, o livro mostra uma página escrita *pelo próprio Tomé* que o jogador não lembra de ter escrito.

**Voz do personagem (para textos do livro):** frases curtas, horários, quase nenhum adjetivo. Quando pressionado, desvia para procedimento.

> *Exemplo de página de Tomé (noite 3):* "21:40. Recusei o Marlin. Carga certa. Voz errada. Anotei do mesmo jeito. Anotar é a única coisa que sei fazer direito."

---

## 4. Bestiário e escala de ameaça

### 4.1 Princípio

A ilha fica na boca de uma corrente que **traz de volta** o que o mar levou. Marinheiros que morreram sem ser **identificados e atracados** (sem rito de chegada, sem nome gritado do cais) não terminam: **ficam no canal**. Cada tragédia gera uma "família" de criaturas. O mar as transforma: sal nos olhos, algas nos ossos, vozes de rádio no peito. A transformação é **piedosa e cruel**: eles continuam querendo *chegar*.

**O que os atrai (hierarquia):**
1. **Luz do farol** (*chegada*): é a única coisa que lhes diz "aqui é o porto". Também é o que mais os fere se girar errado.
2. **Rádio ligado** (*voz*): chamam pelas ondas; quanto mais energia, mais forte o sinal deles.
3. **Barulho de motor/gerador** (*vida*).
4. **Escuridão** (quando a lâmpada apaga, saem da água).
5. **Nome gritado**: o jogador nunca fala; só o rádio.

**O que os afasta/fere:** feixe girando (corda em dia), sal esparramado (motivo: sal no limiar), o **sino** do píer (ainda sem badalo), nome correto.

### 4.2 Bestiário numerado

#### 01 — Os Lavados (família do *Santa Aurora*)
- **Origem:** os 40 tripulantes do cargueiro que não foram atendidos.
- **Aparência:** silhuetas humanas em pé na linha d'água, de costas para a ilha, encharcadas. Sem rosto definido (dithering nas bordas). Número varia: 1 a 40.
- **Comportamento:** **imóveis enquanto o feixe do farol passa por cima**; avançam alguns passos quando o feixe se afasta (como o jogo de "um, dois, três, estátua"). Nunca correm.
- **Quando aparecem:** da meia-noite em diante, na praia sul e no píer.
- **Sinais:** pegadas molhadas no píer, poças que não secam, som de água escorrendo sem fonte.
- **Fraqueza:** o feixe em rotação contínua. **Se a corda parar, avançam.**
- **Ligação com mecânica:** lâmpada (corda, óleo, lente). Lente suja = feixe fraco = alcance menor.
- **Escala de ameaça:** 1 → 3.

#### 02 — O Sineiro
- **Origem:** o sino de bordo do *Imperatriz* (1923). Ninguém sabe quem o toca.
- **Aparência:** nunca visto. Um som: um sino abafado, debaixo d'água, **sempre três toques e uma pausa** (ligado ao motivo do 3).
- **Comportamento:** toca quando alguém vai morrer no mar; no jogo, toca **antes de um navio anômalo chamar**. É um aviso e uma maldição.
- **Quando:** da noite 1 (uma vez, às 23:45) à noite 7.
- **Fraqueza:** nenhuma; é um sinal. Sirene de neblina o cobre.
- **Mecânica:** rádio (o toque antecede a chamada).
- **Escala:** 0 (informativo, mas conta para a tensão).

#### 03 — A Voz (o Nono)
- **Origem:** Anselmo Quaresma, vigia 9, e algo mais: ele *atendeu o rádio uma última vez* e ficou na frequência.
- **Aparência:** nenhuma. Voz grave, calma, cansada, que recita o registro de cargas **corretamente**. É a única entidade que *ajuda* (às vezes).
- **Comportamento:** aparece em frequências extras; diz o que é verdade ("O Ceres leva tijolos. Autorize.") ou mente por culpa. O jogador não tem certeza qual.
- **Quando:** de 00:00 em diante, rádio ligado.
- **Fraqueza/Regra:** só fala se o rádio está sintonizado **fora** de uma chamada ativa; some se o jogador responde "recusar" duas vezes seguidas.
- **Mecânica:** rádio, dial (frequências extras).
- **Escala:** 1 (confiança), vira 4 (impostor) na noite 6.

#### 04 — Os Encalhados (família do *Esperança* e do *Maria da Graça*)
- **Origem:** pescadores. Eles **não querem entrar**; querem **sair**.
- **Aparência:** figuras curvadas, arrastando algo (rede, corrente). Pele cinza, algas no cabelo. Movem-se em direção ao **mar**, não à ilha.
- **Comportamento:** se a lâmpada está **apagada**, saem da água e vagam pela praia; se acesa, voltam. São **inofensivos para o jogador**, mas bloqueiam o caminho do píer e causam sustos de desorientação (a bússola do HUD, o "Rumo", gira errado perto deles).
- **Quando:** a partir de 02:00 se a lâmpada estiver apagada.
- **Fraqueza:** luz do farol; lanterna de mão os faz recuar.
- **Mecânica:** lâmpada apagada (óleo acabou, ordem errada).
- **Escala:** 1 → 2.

#### 05 — Luzes-de-Vigia
- **Origem:** lanternas de navios que tentaram entrar. Fogos-fátuos marítimos.
- **Aparência:** três pontos âmbar no horizonte, no padrão de luzes de um navio *errado* (vermelho onde devia ser verde). Piscam em padrão curto-longo.
- **Comportamento:** **imitam o farol** para desviar navios *reais* para os recifes SO. Se um navio real está em rota (chamada ativa), as luzes falsas aparecem na proa dele.
- **Quando:** da 01:00 em diante, durante uma chamada ativa.
- **Fraqueza:** o feixe verdadeiro, em rotação, "apaga" os falsos quando passa.
- **Mecânica:** lâmpada (giro), rádio (o navio real pergunta "qual das luzes é a de vocês?").
- **Escala:** 2.

#### 06 — O Casco (o *Santa Aurora* em si)
- **Origem:** o próprio naufrágio.
- **Aparência:** o casco a SO, que **muda de posição entre as noites** e, depois da meia-noite, parece mais inteiro do que deveria. Janelas acesas de âmbar-pálido.
- **Comportamento:** não persegue. **Responde.** Se o jogador pisca a luz para ele (modo sinal, [NOVO]), ele *se endireita um pouco*.
- **Quando:** da 00:30; clímax às 03:05.
- **Fraqueza:** sinal de luz certo (padrão do código do posto); o nome certo no rádio.
- **Mecânica:** lâmpada (modo sinal), rádio, maré (na preamar fica mais visível).
- **Escala:** 3 → 5.

#### 07 — A Capitã
- **Origem:** o comandante do *Santa Aurora*, que mentiu na carga para salvar a tripulação de prisão e matou a todos.
- **Aparência:** uma figura mais alta, no convés do Casco, de casaco longo. Só aparece **pelo binóculo** ([NOVO]) ou de relance à beira do vidro da lanterna.
- **Comportamento:** é a chamada do *Santa Aurora* no rádio. Pede atracação. **Sempre com a carga errada.**
- **Quando:** 03:05 (marco final da noite 1).
- **Fraqueza:** ser ouvida. O que ela quer é que alguém **diga o nome do navio de volta**, sem julgar.
- **Mecânica:** rádio (a chamada mais importante), lâmpada.
- **Escala:** 4 → 5.

#### 08 — Gaivotas Mudas
- **Origem:** o que sobrou de quem se afogou sem nome.
- **Aparência:** gaivotas pousadas em fileira no parapeito do farol e no telhado da casa, **todas olhando para o mesmo lado** (o cemitério).
- **Comportamento:** nunca fazem barulho. Se o jogador acende a lanterna de mão para elas, **todas se viram ao mesmo tempo**.
- **Quando:** da 21:00 (primeiro sinal de "algo está errado" quase inocente).
- **Fraqueza:** nenhuma; são presságios.
- **Escala:** 0.

#### 09 — A Névoa-Viva
- **Origem:** a respiração de quem está sob a água.
- **Aparência:** a neblina do jogo (fog PS1 curta) ganha **forma**: bancos que andam contra o vento, rostos esboçados que desfazem quando o feixe passa.
- **Comportamento:** reduz alcance de luz e binóculo (clima do GDD). Depois da meia-noite, **tem direção**: vem do mar, cobre a ilha de SO a NE.
- **Fraqueza:** sirene de neblina; vento do amanhecer.
- **Mecânica:** clima, sirene.
- **Escala:** 2.

### 4.3 Escala de ameaça

Eixo 1: **dentro da noite** (de `GameState.progress()`). Eixo 2: **entre noites** (GDD §5).

| Nível | Nome | Descrição | Dentro da noite 1 | Noites |
|---|---|---|---|---|
| 0 | Presságio | Sons, gaivotas, objetos fora do lugar. Nada pode te ferir. | 18:00–23:45 | 1–2 |
| 1 | Presença | Silhuetas distantes, vozes extras, pegadas. | 23:45–01:00 | 2–3 |
| 2 | Interferência | Criaturas *interferem* no sistema: luzes falsas, bússola errada, rádio com voz dupla. | 01:00–02:30 | 3–4 |
| 3 | Aproximação | Lavados avançam quando o feixe falha; o Casco se move. | 02:30–03:30 | 4–5 |
| 4 | Contato | A Capitã chama; a Voz vira impostora; pode apagar o farol "sozinha". | 03:05–04:30 | 5–6 |
| 5 | Passagem | Nada é inocente. A ilha *é* o navio. | 04:30–05:30 | 6–7 |

**Relação com `tension()`:** `progress()*0.65 + perdidos*0.08 (máx 0.25) + chamada ativa 0.08 + lâmpada apagada após 19:00 0.1`. Os níveis acima são **bandas** dessa curva: ≤0.25 nível 0; 0.25–0.4 nível 1; 0.4–0.55 nível 2; 0.55–0.7 nível 3; 0.7–0.85 nível 4; >0.85 nível 5.

---

## 5. O rádio, os navios e as chamadas anômalas

### 5.1 O que são os chamados

O rádio do Farol 7 recebe **tudo que passa pelo canal**, vivos e mortos. A diferença entre navio e fantasma **não está na voz**: está no **registro**. Um navio vivo declara carga que bate com o registro; um morto **repete a carga que ele *acha* que levava**, ou o nome do que ele **perdeu**.

### 5.2 Por que alguns navios "mentem" sobre a carga

**Mecânica existente** (`radio.gd`): a cada 3 chamadas (a cada 2 depois de 23:45, quando `progress() > 0.5`), o navio declara uma carga **diferente** da do registro. Se o jogador autoriza: *"O [navio] atracou. O registro dizia outra carga, e a tripulação nunca desceu."* Se recusa: *"Você recusou o [navio]. A voz no rádio se calou."*

**Explicação narrativa.**

1. Cada nome de navio no registro é **real** (um barco vivo que passa pela rota).
2. O que chama pelo rádio, quando a carga está errada, **não é o navio**: é um afogado que **tomou o nome** e a frequência. Ele sabe o nome (o mar o repete) mas **não sabe a carga**, porque *o mar leva tudo que o navio carregava*. Ele chuta.
3. O navio **de verdade** pode estar a 20 milhas dali, sem saber que alguém está se passando por ele.
4. Autorizar a atracação do impostor é **abrir o cais**: a "tripulação" que desce não é gente.
5. Quanto mais tarde a noite, mais afogados com mais prática no nome: a razão para o ritmo de mentira acelerar.

> **Moral oculta:** o Santa Aurora também mentiu na carga. E era verdadeiro. A regra funciona 9 vezes em 10 e a décima custa 40 vidas. *(Este é o coração da noite 7.)*

### 5.3 Os navios do registro (`GameState.SHIPS`)

Registro canônico de cargas (livro, págs. 7–8). Cada um tem uma **verdade** por trás.

| # | Navio | Carga registrada | Quem é de verdade | Mentira (quando chama errado) | Pista para o jogador |
|---|---|---|---|---|---|
| 1 | **Marlin** | café | Cargueiro pequeno de cabotagem. Capitão pontual, cheiro de café na voz. | Um dos Lavados fala "Marlin": a voz está **molhada**, a carga que diz é sempre salgada ("sal", "peixe"). | Estática com **água** no fundo. |
| 2 | **Aurora** | carvão | Carvoeiro velho, **homenagem** ao *Santa Aurora* (mesma companhia). | A Capitã usa este nome quando quer ser atendida: diz "café" (carga leve, "limpa"). | O jogador reconhece o tom de comando. |
| 3 | **Gaivota** | sal | Barco-sal de Mossoró-style. | Quem chama é um Encalhado: **cansado**, pede só "descansar". Diz "lã". | Voz arrastada; faz pausas longas. |
| 4 | **Tritão** | lã | Rebocador que leva fardos de lã para fiação. | Uma Luz-de-Vigia usa o nome (voz sintética, sem respiração). Diz "tijolos". | A voz repete a mesma frase cortada. |
| 5 | **Estrela do Norte** | peixe | Traineira de pesca industrial. | Os do *Maria da Graça*; a voz fala de redes. Diz "carvão". | A voz fala em **pretérito**, nunca no presente. |
| 6 | **Ceres** | tijolos | Barcaça de material de construção, lenta. | Voz da Névoa: eco duplo. Diz "café". | Eco: duas vozes sobrepostas com meio segundo de atraso. |

**Regra para o jogador (já implementada):** igual ao registro, autorize **com a luz acesa**; diferente, recuse. Sem luz, qualquer autorização encalha o navio (`"Sem a luz do farol o %s não achou o canal e encalhou."`).

### 5.4 Chamadas anômalas adicionais [NOVO]

Formato: **frequência**, **roteiro** (falas curtas, em aspas, como aparecem na linha do HUD), **decisão correta** e **consequência**.

#### A1 — "Santa Aurora" (a chamada central)
- **Hora:** 03:05 (única; reaparece nas noites seguintes).
- **Roteiro:**
  > "Farol Sete, Farol Sete. Aqui o *Santa Aurora*. Pedimos orientação. Carga: café."
  > *(pausa)* "Repito. Estamos adernando. Carga: café."
  > "Vocês confirmaram três vezes. Confirmem de novo."
- **Decisão:** **não existe resposta "correta" pela regra**. Autorizar com lâmpada acesa: "O *Santa Aurora* atracou. A tripulação nunca desceu. Ela só queria ouvir que chegou." Recusar: "A voz se calou. Você a ouviu calar da última vez também."
- **Para o final verdadeiro:** responder com **sinal de luz** (padrão curto-longo-curto) [NOVO] e esperar até as 05:30.

#### A2 — "Imperatriz" (já naufragado)
- **Hora:** 00:20, depois todas as noites.
- **Roteiro:** > "Vapor *Imperatriz*, de Santos para o norte. Trezentos passageiros. Neblina. Vejo luz mas ela não gira."
- **Decisão:** **Recusar** (não está no registro). **Alertar** (sirene) corta a chamada e acalma o Sineiro por uma hora. **Autorizar:** a lâmpada para de girar sozinha por 20 s [NOVO].
- **Pista:** a carga é "passageiros" (só aparece no registro de 1923, no livro).

#### A3 — "Dois Irmãos" (só um responde)
- **Hora:** 01:10.
- **Roteiro:** > "Rebocador *Dois Irmãos* chamando. Estamos... aqui. Um de nós está aqui." / > "O outro irmão ficou no mar."
- **Decisão:** **Ignorar.** Qualquer resposta ligada à segunda voz abre um segundo canal.
- **Consequência de autorizar:** um Lavado chega ao píer.

#### A4 — "Maria da Graça" (a traineira que já sumiu)
- **Hora:** 02:00.
- **Roteiro:** > "Traineira *Maria da Graça*, da pesca. Nada pra descarregar, só rede vazia. Alguém na costa?"
- **Decisão:** Recusar. **Alertar** é o certo se disponível: ela fica mais tempo na linha e some só ao amanhecer. Autorizar: "Rede vazia" é o aviso de que "o resto virá depois".

#### A5 — Dois "Marlin" ao mesmo tempo
- **Hora:** 22:50 (a **primeira** chamada visivelmente anômala; é suave).
- **Roteiro:** voz 1: > "Aqui o *Marlin*. Café." voz 2 (mesmo canal, 1 s depois): > "Aqui o *Marlin*. Café."
- **Decisão:** **Qualquer um é o falso.** Pelo jogo atual, a carga bate: é *autorizável*, mas autorizar causa "O *Marlin* atracou. Atracaram dois." [NOVO]
- **Pista:** o dial só capta um deles se você estiver exatamente em 94.3.

#### A6 — A voz sem nome
- **Hora:** 00:00 exato.
- **Roteiro:** (só respiração, 6 s) > "..." > "Você está aí?" > "Você é novo."
- **Decisão:** nenhuma opção válida. Recusar é neutro, mas **não** punido. Responder (se houvesse) seria um erro. É a primeira vez que o rádio *fala com o jogador*.

#### A7 — "Vigia Nove chamando o Farol Sete"
- **Hora:** 01:40.
- **Roteiro:** > "Farol Sete, aqui o Vigia Nove. Eu estou na casa. Aqui na casa. Você não me viu." / > "Não autorize o próximo."
- **Decisão:** **ambígua**: a Voz pode ajudar ou mentir. O próximo navio *é* regular, e recusá-lo é punir um inocente. **Teste de confiança.** No livro, a mesma letra pede "autorize o próximo".

#### A8 — "Ceres" com a carga certa e a voz errada
- **Hora:** 02:20.
- **Roteiro:** > "Ceres. Tijolos." (falas curtas, sem emoção) > "Atracação. Pedimos atracação." > "Sim, sim."
- **Decisão:** **Recusar apesar de a carga bater.** Pela regra seria autorizar; a regra falha aqui. [NOVO: o jogador só saberá pela *voz*, o que exige ter ouvido o Ceres real mais cedo.]

#### A9 — O Navio Mudo
- **Hora:** 03:40.
- **Roteiro:** (só estática com um **sino abafado** em três toques) > *(estática)*
- **Decisão:** **Alertar com sirene.** Recusar ou ignorar deixa o Sineiro tocar mais alto; autorizar não é possível.

#### A10 — "Aurora" falando em outra língua
- **Hora:** 04:15.
- **Roteiro:** > "Aurora, carvão." (...) > "Aurora. Ainda estamos subindo a rampa." (voz de dentro do farol)
- **Decisão:** **A voz vem de dentro do rádio local, não do mar.** Desligar o disjuntor do rádio por 30 s é a única saída. [NOVO]

#### A11 — Chamada de amanhecer (alívio falso)
- **Hora:** 05:20.
- **Roteiro:** > "Marlin chamando. Bom dia, Farol. Cheguei." *(a voz do Marlin real, calorosa)*
- **Decisão:** **Autorizar** (é regular). Mas o jogador, desconfiado depois de tudo, pode recusar: o jogo **pune a paranoia** (navio perdido) e isso é parte do tema.

### 5.5 A voz que chama

Há **uma voz que chama o jogador pelo cargo** ("Farol Sete"), não pelo nome. Ela tem três registros:

1. **Operador** (00:00–02:00): neutro, cansado, às vezes certo. *A Voz (Anselmo).*
2. **Comandante** (03:05–04:30): autoritária, pedindo atracação. *A Capitã.*
3. **Eco do jogador** (04:30–05:30): fala com a voz de Tomé, repetindo o que ele disse 30 anos atrás: *"Carga diferente da registrada. Recuso."*

---

## 6. Cronologia da noite (17:30 → 06:00)

**Parâmetros do relógio:** 1,2 s reais por minuto de jogo (`SECONDS_PER_MINUTE`), 750 min totais, ~15 min reais. **Meia-noite** cai em `progress ≈ 0.52` (390 min depois das 17:30), ou seja, **~7 min 48 s** de jogo real. O limiar de mentiras (`progress() > 0.5`) é às **23:45**: o jogo **já** muda quinze minutos antes de o relógio virar. Isso é canon: "o mar não espera o relógio."

### 6.1 Antes da meia-noite: o que é normal

| Hora | Fase | O que acontece | Tom (tensão base) |
|---|---|---|---|
| 17:30 | Chegada | Píer, baú, lanterna. Pôr do sol. | 0.12 |
| 18:00 | Rotina | Siga o objetivo: casa → livro → gerador → disjuntores. | ~0.04 |
| 19:00 | Escuridão | Se a lâmpada ainda não acendeu: tensão +0.1. | ~0.12–0.22 |
| 20:00 | Primeira chamada normal | Rádio liga, 1ª chamada (carga certa). | ~0.15 |
| 21:00 | Presságios (nível 0) | Gaivotas Mudas no parapeito. Um item no lugar errado. | ~0.2 |
| 22:00 | O livro | A página do vigia 9: "A recusa foi correta." | ~0.25 |
| 22:50 | Primeiro erro | Dois "Marlin" (A5) no mesmo canal. | ~0.28 |
| 23:45 | Limiar | O Sineiro toca três vezes. As mentiras sobem para 1 a cada 2. | ~0.33 |

### 6.2 Meia-noite e depois: o que muda

| Hora | O que muda | Efeito no jogo | Nível |
|---|---|---|---|
| **00:00** | **O relógio de parede para por 3 s**, e o rádio acende sozinho em uma frequência extra. A voz sem nome (A6). | HUD mostra "00:00" travado. Toast: *"O relógio da parede parou. O seu, não."* | 1 |
| 00:10 | O vento **para**. Um silêncio de 20 s (só o mecanismo girando). | Áudio: o mar abaixa. | 1 |
| 00:20 | *Imperatriz* (A2). Névoa vem do mar. | Alcance de luz e binóculo reduzido. | 1 |
| 00:30 | Primeiros **Lavados** na praia sul, *de costas*. | Vistos pelo vidro da lanterna. | 1 |
| 01:00 | Luzes-de-Vigia no horizonte durante chamada. | Navio pergunta qual luz é a certa. | 2 |
| 01:10 | *Dois Irmãos* (A3). A **maré** fica "errada": sobe mesmo no meio da baixa (a janela do ilhéu encurta). | Tempo de travessia cai. | 2 |
| 01:40 | Vigia Nove (A7). A porta da casa **abre sozinha** (o som de dobradiça). | Teste de confiança. | 2 |
| 02:00 | *Maria da Graça* (A4). Se a lâmpada apagou: Encalhados saem. | Bússola do HUD gira errada perto deles. | 2 |
| 02:20 | Ceres falso (A8). O **gerador** respira diferente (ritmo cardíaco no som). | Falhas mais frequentes. | 3 |
| 02:30 | Os Lavados **avançam** quando o feixe se afasta. | Corda obrigatória. | 3 |
| 03:00 | O **céu** muda: estrelas some, a Lua parece **maior** e baixa. | Visual. | 3 |
| **03:05** | ***Santa Aurora* (A1).** O Casco se acende. | **Marco central.** | 4 |
| 03:40 | O Navio Mudo (A9): sino. | Sirene. | 4 |
| 04:00 | A **ilha**: a rampa parece mais longa (14 s → mais), a escada "não termina" por 4 s. | Atraso de subida. | 4 |
| 04:15 | Aurora falsa dentro do rádio (A10). | Desligar disjuntor. | 4 |
| 04:30 | Eco do jogador (voz de Tomé). Visão: o jogador se vê no vidro da lanterna, de costas. | | 5 |
| 05:00 | A **névoa** abre de uma vez. Silêncio. | Alívio falso. | 3 |
| 05:20 | Marlin real (A11). | Teste de paranoia. | 2 |
| 05:30 | O sol "quase". Os Lavados em pé, **encarando o farol**. | | 2 |
| **06:00** | Amanhecer. `night_ended`. Resumo + final. | | 0 |

### 6.3 Acontecimentos bizarros: catálogo por sistema

| Sistema | Acontecimento | Quando | Como se liga ao tom |
|---|---|---|---|
| **Relógio** | Para por 3 s à meia-noite; a 03:05 marca 03:05 mesmo se for outra hora por um quadro. | 00:00, 03:05 | O mundo mostra que sabe o horário do naufrágio. |
| **Rádio** | Frequência extra aparece no dial (`FREQS` ganha um 6º valor) [NOVO]. A voz fala com o jogador. | 00:00+ | Quebra a regra "o rádio só responde". |
| **Maré** | Sobe sem aviso, ou os "10 s de aviso" viram 3 [NOVO]. | 01:10+ | O mar quebra o contrato do jogo. |
| **Mar** | Superfície **lisa como vidro**, sem ondas (shader `psx_water` com amplitude 0). | 00:10, 05:00 | Calma = ameaça. |
| **Névoa** | Anda contra o vento, com formas. | 00:20+ | Eco da Névoa-Viva. |
| **Sons** | Sino de três toques; passos molhados no píer; dobradiça da casa; alguém sobe a rampa. | 23:45+ | Áudio manda. |
| **A ilha** | O cemitério: a luz do túmulo acende. As gaivotas olham para lá. Objetos mudam de lugar (o livro à esquerda da mesa em vez de à direita). | 21:00+ | Presságio progressivo. |
| **O farol** | A lâmpada gira **mais devagar** sozinha por 2 s (a corda "afrouxa"). O feixe aponta, uma vez, para o Casco sem a corda. | 02:00+ | A luz "responde" (noite 6 no GDD, aqui um antegosto). |
| **Visões** | O jogador vê Tomé de 22 anos na estação de rádio refletido no vidro. | 04:30 | Culpa. |

---

## 7. Segredos, pistas e finais da Noite 1

### 7.1 A verdade, revelada em camadas

| Camada | O que o jogador entende | Onde descobre |
|---|---|---|
| 1 | O farol é seguro, o rádio é um trabalho, a regra é "carga igual = autorize". | Livro págs. 1–8 (já existem). |
| 2 | Há algo errado com certos navios: o nome está certo, a carga errada. | Chamadas mentirosas (já existem). |
| 3 | Os mortos chamam. O farol os atrai. | Gaivotas, Sineiro, Lavados. |
| 4 | O vigia 9 sumiu na noite do *Santa Aurora* e deixou um diário. | Páginas escondidas (§7.2). |
| 5 | A recusa do *Santa Aurora* foi o erro. E foi **sua**. | Final e noite 5. |
| 6 | O farol nunca guiou: avisou. Sinalizar "aqui não" mantém os mortos fora; **dizer o nome** os deixa terminar. | Noite 7. |

### 7.2 Pistas distribuídas pela ilha (as existentes e as novas)

**Já existem (canon, via `Clue` e `add_note`):**

| Local | Texto | Função |
|---|---|---|
| Cemitério (monumento), ~(-13, -23) | "Inscrição: OITO vigias descansam aqui. O nono ainda vigia." | Dígito **8**; semente do mistério. |
| Píer, caixote, ~(0.6, 42) | "Etiqueta do caixote: LOTE 3, ÓLEO DE LAMPARINA." | Dígito **3**. |
| Galpão, tanque, ~(-19.6, 19.6) | "Placa do tanque: CAPACIDADE 5 LATAS." | Dígito **5**. |
| Cadeado do porão | "Porão da casa: cadeado de 3 discos. Os números estão escritos pela ilha." | Pista meta. |

**Propostas [NOVO]** (formato: local → texto, pensado para `Clue`):

| # | Local | Texto curto |
|---|---|---|
| N1 | Mesa do rádio, bilhete preso embaixo do aparelho | "Se a voz errar a carga, não é erro. Não responda como se fosse." — A.Q. |
| N2 | Parede da casa, ao lado da cama | Riscos de contagem: 9 grupos de 5, o último riscado pela metade. |
| N3 | Cemitério, cruz do vigia 6 | "VALDEMAR COSTA. Voltou da neblina por um dia." |
| N4 | Cemitério, cruz sem nome, ao fundo | "Aqui jaz quem chegou e não foi anunciado." |
| N5 | Farol, base, na parede ao pé da rampa | Dezesseis marcas de giz, uma para cada metro da rampa; a última apagada. |
| N6 | Sala da lanterna, junto à manivela | "A corda é o relógio. Se ela para, eles andam." |
| N7 | Galpão, atrás do gerador | Um capacete de operador de rádio, com um nome riscado: "T. VALADARES". *(Tomé nunca esteve ali... ainda.)* |
| N8 | Praia, perto do Casco, caixa de lata | Um manifesto do *Santa Aurora* com **duas colunas**: a oficial e a verdadeira. |
| N9 | Ilhéu, base do tambor | "Reserva do vigia 4. Não tire a última lata sem olhar a maré." |
| N10 | Porão (após abrir: 8-3-5) | Diário do vigia 9 (ver §7.3) e uma lanterna de sinal [NOVO]. |
| N11 | Píer, o sino sem badalo | "Três toques: chegada. Dois: perigo. Um: perdido. O badalo foi retirado em 1923." |
| N12 | Livro (página final em branco) | Ao fim da noite, uma página nova escrita com a letra do jogador: o horário de cada decisão. |

### 7.3 Páginas do vigia 9, Anselmo Quaresma (livro/porão) [NOVO]

Páginas de 4–6 linhas, cada uma destravada por uma ação (ler o livro, abrir o porão, sobreviver à meia-noite...).

> **Pág. A (livro, 18:00).** "Primeira regra: carga igual, autorize. Segunda: carga diferente, recuse. Terceira: anote. Nunca pensei em uma quarta."
>
> **Pág. B (livro, 22:00).** "Hoje o Gaivota chamou duas vezes. Uma voz estava seca. A outra, molhada. Recusei a molhada. Acertei."
>
> **Pág. C (porão).** "Se você achou este porão, o mar já te escolheu. Aqui tem óleo. Use para a luz. A luz é a única coisa que eles respeitam."
>
> **Pág. D (porão).** "Os mortos não querem machucar. Querem chegar. O problema é o que vem junto."
>
> **Pág. E (porão, dia 8/3).** "Três da manhã e cinco. O *Santa Aurora* chamou. Eu estava na casa; ouvi pelo rádio da estação *deles*, o jovem operador, repetindo: 'recuso'. Subi a rampa correndo. A luz estava acesa. Ele já tinha recusado."
>
> **Pág. F (última).** "Não vou ficar enterrado. Quem vigia não descansa; só muda de lugar."

*Revelação:* Anselmo ouviu Tomé recusar. **Os dois estavam ligados pela mesma chamada.** É a ponte entre o vigia 9 e o jogador.

### 7.4 Finais da Noite 1

Condições usam o que o jogo já mede: `ships_saved`, `ships_lost`, `lamp_lit`, `notes`, `book_read` e a escolha em A1.

#### Final A: O Vigia (sobreviver/salvar)
- **Condição:** `ships_lost ≤ ships_saved`, lâmpada acesa às 06:00, **sem** autorizar nenhuma chamada mentirosa. (Texto atual: *"O farol resistiu."*)
- **Cena:** o barco de rendição chega às 06:00. O barqueiro diz: "Dormiu bem?". O jogador responde (sem opção). No píer, as pegadas molhadas secam ao sol.
- **Texto do livro:** "Noite 1. Luz acesa. Navios atendidos. Nada a declarar."
- **Gancho:** o jogador é "substituído normalmente" (GDD final 1). Mas na última linha da página: *"Nada a declarar" não está na minha letra.*

#### Final B: A Maré Cheia (falhar)
- **Condição:** `ships_lost > ships_saved` **ou** a lâmpada apagada por mais de 30 min em jogo **ou** autorizou ≥2 navios mentirosos. (Texto atual: *"Muitos não voltaram."*)
- **Cena:** às 06:00 o barco de rendição **não vem**. A maré sobe sobre o píer. As pegadas molhadas vão da praia até a porta da casa.
- **Texto do livro:** "Eles chegaram. Você os deixou chegar."
- **Gancho:** a noite 2 começa **com os Lavados já na ilha** (dificuldade maior) e o livro com mais páginas do vigia 9.

#### Final C: O Nome (verdadeiro)
- **Condições (todas):** leu **todas** as pistas do porão (abriu o 8-3-5); respondeu ao *Santa Aurora* (A1) **sem recusar e sem autorizar**: via sinal de luz (padrão do N11) [NOVO] ou, no mínimo de implementação, **deixou a chamada expirar com a lâmpada acesa e o disjuntor do rádio ligado**; `ships_lost ≤ 1`.
- **Cena:** às 05:30 os Lavados, de frente, **abaixam a cabeça**. O Casco se desfaz em névoa. Pela primeira vez o sino do píer **toca com badalo**: três vezes. A Voz diz: *"Obrigado por ouvir, Tomé."* O jogador nunca disse o próprio nome.
- **Texto do livro:** "03:05. Santa Aurora, 40 almas. Chegaram."
- **Gancho:** o farol **não** tem mais Santa Aurora; a rota fica **mais perigosa**: algo *pior* que a mágoa vem atrás (ver §8, noite 2: "O Que Vinha Junto").

---

## 8. Ganchos para as noites 2–7

Alinhado com a tabela de progressão do GDD §5.

| Noite | Novidade mecânica (GDD) | Narrativa | Ameaça | O que o livro mostra |
|---|---|---|---|---|
| **1** | Lâmpada, corda, rádio | O mundo parece normal; meia-noite como primeira fissura. | 0–4 | Págs. do vigia 9 (A–F). |
| **2** | Gerador, 1ª falha, neblina leve | O gerador "respira". A Voz (Anselmo) pede ajuda para o navio seguinte. | 1–3 | Letra do vigia 9 em páginas *novas*. |
| **3** | 1º barco de suprimentos, manifesto | O barqueiro **não desembarca** e diz: "Fui avisado de que o senhor chegou **ontem**". Primeiro navio fora do manifesto: Imperatriz. | 2–3 | "Dia 3: o calendário está errado." |
| **4** | Sinal manual de luz, tempestade | Vozes no rádio. O jogador aprende o código do posto (N11). | 3–4 | Páginas de Ismênia (vigia 8) sobre o *Dois Irmãos*. |
| **5** | Navios afundados passam a chamar, neblina densa | A ilha muda: a casa tem um cômodo a mais; objetos fora do lugar. O livro mostra a página **escrita pelo jogador** que ele não lembra de ter escrito. | 4 | A confissão: "Eu era o operador." |
| **6** | Recursos escassos, tempestade | O farol "responde" sozinho: gira sem corda por 10 s. A Voz vira impostora; a Capitã fala com a voz de Tomé. | 4–5 | O diário do vigia 9 se contradiz. |
| **7** | Noite final | Confronto: Santa Aurora, a Voz, os 8 vigias (cemitério vazio), e a escolha entre **regra** e **julgamento**. | 5 | O livro fica em branco, **e o jogador escreve**. |

**O Que Vinha Junto (a ameaça do final da noite 7).** Quando o *Santa Aurora* chega a destino, abre-se a passagem que a Capitã fechava com a própria culpa. O que vinha atrás dos 40 (**a Preamar**, uma maré que nunca baixa) entra. Na Noite 7, é preciso escolher entre guiar os mortos (Passagem, GDD final 2) ou acender o farol como *aviso* ("aqui não", Vigia, final 1) ou tornar-se a voz (Substituto, final 3).

**Finais da campanha (cruzando com GDD §6):**

| Final | Condição geral | Resumo |
|---|---|---|
| O Vigia | Só vivos guiados | Você é rendido; os mortos ficam. |
| A Passagem | Guiou todos, inclusive *Santa Aurora* | A ilha afunda com você; eles atracam. |
| O Substituto | Muitas perdas | Você vira a próxima voz do rádio: a voz que Tomé sempre foi. |
| **O Nome** *(verdadeiro)* | Noite 1 C + noite 7 com julgamento | O farol volta a ser porto: "venha", pela primeira vez, e só para quem é nomeado. |

---

## 9. Glossário

| Termo | Definição |
|---|---|
| **Farol 7 / Ponto 7** | Sétimo ponto da cadeia de faróis. A ilha. |
| **Vigia** | O guarda do farol. Dez ao todo; oito enterrados. |
| **Registro de cargas** | Lista de seis navios e suas cargas no livro. Base da decisão. |
| **Carga falsa** | Carga declarada diferente da do registro. Indício de impostor. |
| **Lavados** | Os 40 tripulantes do *Santa Aurora*. |
| **Encalhados** | Mortos do *Esperança* e *Maria da Graça*, que querem sair. |
| **Sineiro** | O sino que ninguém toca. |
| **A Voz / o Nono** | Anselmo Quaresma, na frequência extra. |
| **A Capitã** | Comandante do *Santa Aurora*. |
| **Casco** | O naufrágio SO. |
| **Preamar** | Maré cheia. Na lore final: a maré que não baixa. |
| **Modo sinal** | Piscar a lâmpada manualmente (GDD §4.1). |
| **Estação 12** | Estação costeira onde Tomé trabalhava há 30 anos. |
| **Rendição** | O barco que troca o vigia ao amanhecer. |
| **Chegar** | Verbo central: o que os mortos querem. |
| **Aviso (do farol)** | A função original do farol: dizer "aqui não". |

---

## 10. Motivos recorrentes

| Motivo | Uso |
|---|---|
| **Luz e escuridão** | Âmbar = ordem e chegada; escuridão = ausência de porto. O vermelho é só para o que está errado. |
| **O sino** | Três toques: chegada. Dois: perigo. Um: perdido. Sem badalo no píer desde 1923; ganha badalo no final C. |
| **Sal** | Limiar de proteção (sal nas soleiras), a lente suja, o gosto na boca antes de uma visão. Sal no registro (Gaivota). |
| **Números 8-3-5** | **8** vigias enterrados; **3** o lote (3 toques do sino, 3 vezes que Tomé confirmou); **5** a capacidade do tanque. E a data do naufrágio: **8/3, 03h05**. O cadeado do porão é, na verdade, uma data. |
| **O número 3** | 3 latas no tambor, 3 disjuntores, 3 passos da lâmpada (óleo → corda → lente), 3 chamadas de recusa. |
| **A rampa** | A subida é o arco do herói: 14 s. Em 04:00 ela cresce. |
| **Espelho** | O vidro da lanterna reflete o jogador. O reflexo se atrasa. |
| **"Anotar"** | O único ato de Tomé: escrever. O livro é a consciência dele. |
| **A regra** | "Carga diferente da registrada: não autorize." Repetida, depois contestada. |
| **Contagem** | Os riscos na parede da casa; os dias que não batem. |
| **O nome** | Nomear = fazer chegar. É o ato final. |

---

## Apêndice A: Notas para implementação

Nada exige mexer em código agora; esta tabela só mapeia *o que o jogo já tem* contra *o que precisaria existir*.

### A.1 O que já existe e sustenta a narrativa

| Elemento narrativo | Sistema atual | Arquivo |
|---|---|---|
| Relógio 17:30→06:00 | `GameState.minutes`, `clock_text()`, `progress()` | `game_state.gd` |
| Tensão para música/clima | `tension()` | `game_state.gd` |
| 6 navios e verdades | `SHIPS` | `game_state.gd` |
| Mentira ↑ após 23:45 | `_anomaly_every()` (`progress() > 0.5`) | `puzzles/radio.gd` |
| Chamada, contato, resolução e textos | `_spawn_call`, `_check_contact`, `_resolve` | `puzzles/radio.gd` |
| Registro de cargas / livro | `_pages()` | `ui/overlay.gd` |
| Anotações de pistas | `Clue`, `GameState.add_note` | `puzzles/clue.gd` |
| 8-3-5 | `CODE`, 3 `Clue` | `puzzles/cellar_lock.gd`, `world/island_details.tscn` |
| Maré, ilhéu, óleo | `tide.gd`, `oil_drum.gd` | `puzzles/` |
| Cemitério, Casco, ilhéu | `Cemetery`, `Wreck`, `Islet` | `world/island_details.tscn` |
| Resumo do amanhecer / final | `night_ended`, `_show_ending` | `ui/overlay.gd` |
| Sons e loops | `GameState.play(nome, pos)`, `audio_director.gd` | `audio/` |

### A.2 O que seria novo

| Elemento | O que implica | Esforço |
|---|---|---|
| Novas `Clue` (N1–N12) | Só instanciar nós `Clue` com `text` e posição (mesmo padrão atual). | **Baixo** |
| Páginas do vigia 9 no livro | Ampliar `_pages()` condicionando por flags (`book_read`, porão aberto, hora). | **Baixo** |
| Final A/B (texto) | Trocar `verdict` em `_show_ending()` por 3 variantes com as condições da §7.4. | **Baixo** |
| Chamadas A5–A11 (texto) | Nova lista `ANOMALIES` com `{hora, fala, resposta_correta}`; `radio.gd` as injeta por horário em vez de sorteio. | **Médio** |
| Frequência extra / "A Voz" | 6º valor em `FREQS`, canal que só soa sem chamada ativa. | **Médio** |
| Eventos de hora fixa (23:45, 00:00, 03:05...) | Um `NightDirector` leve (já previsto no GDD §9) que emite sinais por horário e chama `GameState.say` / `play`. | **Médio** |
| Relógio que para 3 s | Congelar `minutes` por 3 s em `_process`. | **Baixo** |
| Maré "errada" | Alterar `warning`/`period` em runtime em `tide.gd`. | **Baixo** |
| Lavados / Encalhados / Gaivotas / Luzes-de-Vigia | Cenas com silhueta PS1 + `MeshInstance3D` com `psx_lit` e movimento condicionado a `lamp_lit` / giro do feixe. | **Médio–Alto** |
| Modo sinal (piscar a lâmpada) | Já no GDD §4.1; novo input + padrão curto/longo em `beacon.gd`. Necessário para o final C completo. | **Médio** |
| Binóculo (zoom) | Semana 5 do `PLANO.md`; necessário para ver a Capitã. | **Médio** |
| Sirene de neblina | Já prevista (cortável); também o "alertar". | **Médio** |
| Sino do píer com badalo | Props + áudio procedural (`synth.gd`: 3 toques). | **Baixo–Médio** |
| Noites 2–7 | Roteiro por noite em `.tres` (GDD §9). | **Alto** |
| Persistência entre noites | `ConfigFile` entre noites (GDD §9). `reset()` hoje zera tudo. | **Médio** |
| Final C (condições) | Flags novas: `porão_aberto`, `santa_aurora_resposta`, `sinal_enviado`. | **Médio** |

### A.3 Escopo mínimo recomendado para a demo (noite 1)

Se for preciso cortar (ver "Se atrasar" em `PLANO.md`), manter:
1. Eventos de hora fixa: **23:45** (Sineiro), **00:00** (relógio + voz sem nome A6), **03:05** (A1).
2. Chamadas **A5**, **A6**, **A1** (só texto).
3. Pistas **N1, N3, N6, N10** e as 6 páginas do vigia 9.
4. Finais **A** e **B** só com texto; o **C** só se o modo sinal existir.
5. Bestiário na demo: **Gaivotas Mudas (08)**, **Sineiro (02)** e **Lavados (01)** como silhuetas distantes.
