# Cutscene de abertura: "A travessia"

> Versão 0.1 · 2026-11-12 · Base: `docs/HISTORIA.md` (§2.2, §2.4, §2.7, §3, §10), `docs/GDD.md`, `puzzles/radio.gd`.
> Toca ao iniciar um novo jogo, depois da escolha do slot, e entrega o controle no píer, ao lado do baú, às 17:30.
> Itens marcados com **[NOVO]** não estão na bíblia narrativa; os outros já são canon.

## Resumo

Fim de tarde. Um barco pequeno leva o décimo vigia até o Farol 7, lacrado há 30 anos. O barqueiro fala pouco, evita o casco a sudoeste, desliga o próprio rádio quando ele chia "Farol Sete" e deixa o vigia no píer sem desembarcar. Lembra a regra, promete voltar às seis "se a luz estiver acesa" e vai embora tocando o sino de bordo duas vezes. O protagonista não fala nada, e o jogo também não diz o nome dele.

## Parâmetros

| Item | Valor |
|---|---|
| Duração | ~82 s (faixa 60–90 s) |
| Pular | Segurar `interact` (E / Quadrado) por 1 s, com o mesmo anel de progresso do HUD. Qualquer tecla só mostra o aviso "Segure E para pular". Pular corta para o plano 12 com fade de 0,5 s. |
| Caixa de diálogo | Rodapé, máx. 2 linhas × 40 caracteres, sem nome do falante (quem fala fica claro pelo plano). Texto aparece letra a letra (~30 car/s) e fica 1,5 s depois de completo. Fala de rádio em itálico ou entre aspas, com tremor leve. |
| Câmera | `Camera3D` própria da cutscene, `Path3D`/tween linear com ease suave. Sem câmera na mão. O jitter PS1 dos shaders já basta. |
| Luz | Céu de crepúsculo de `world/day_night.gd` congelado em 17:25 → 17:30. Lâmpada do farol **apagada** do começo ao fim. |
| Elementos | Ilha existente (`world/island.tscn` + `island_details.tscn`), o barco (mesh simples de casco + cabine) e o barqueiro como silhueta parada, sempre de costas ou contra o sol. |

## Planos

| # | Duração | Câmera | Fala | Som |
|---|---|---|---|---|
| 1 | 0–5 s (5 s) | Tela preta. Letreiro centralizado, fade in/out. | **Letreiro:** "PONTO 7" / "Lacrado há trinta anos." | Mar baixo, ondas espaçadas. Vento fraco entra no fim. |
| 2 | 5–13 s (8 s) | Plano geral bem aberto a partir do mar, ao sul, câmera quase na linha d'água. Travelling lateral lento da direita para a esquerda. A ilha é uma silhueta escura contra o sol baixo, com o farol como um risco vertical. O barco é um ponto entrando no quadro pela direita. | (nenhuma) | Mar, vento. Motor do barco distante (pulso grave e irregular, baixo na mixagem). |
| 3 | 13–21 s (8 s) | Por trás do barqueiro, na popa do barco: a silhueta dele (casaco, boné) de costas, mão no leme. A ilha cresce ao fundo, centralizada. Câmera fixa, com balanço leve de onda (rotação de ±1°). | **Barqueiro:** "Ninguém pede o Sete." / (pausa 1 s) "O senhor pediu." | Motor perto, em primeiro plano. Respingo no casco a cada 2 s. |
| 4 | 21–29 s (8 s) | Contra-plongée: tilt lento da base do farol até a sala da lanterna, vista do mar. O vidro está escuro e a lente parada. O céu passa de laranja a roxo no quadro. | **Barqueiro (off):** "A luz não gira desde aquela noite." | O motor abafa um pouco. Vento sobe. Um rangido metálico isolado lá no alto (ferro velho dilatando). |
| 5 | 29–38 s (9 s) | Travelling pelo lado do barco, paralelo à costa sudoeste. Passa o casco do naufrágio (`Wreck`, ~(-40, 24)), com as costelas para fora d'água. Câmera mais lenta que o barco, então o casco demora a sair do quadro. | **Barqueiro:** "Não olhe pra lá." | Mar batendo nas costelas do casco: estalos ocos e água entrando e saindo. Motor constante. |
| 6 | 38–46 s (8 s) | Close no painel da cabine: rádio de bordo com o mostrador aceso, fraco e esverdeado. A mão (silhueta) entra no quadro e gira o botão até desligar. | **Rádio (estática):** "...arol Sete... Farol S..." / (corte seco quando ele desliga) | Estática de rádio que sobe do nada, com um fragmento de voz grave e molhada. O clique do botão. Depois só sobra o motor, que parece mais alto. |
| 7 | 46–53 s (7 s) | Plano geral do píer visto de cima e de lado (câmera na altura do galpão, olhando para o mar). O barco encosta devagar, o motor cai para marcha lenta. O baú e o caixote ficam visíveis na ponta do píer. | (nenhuma) | Motor em marcha lenta. Madeira do píer rangendo quando o casco encosta. Corda batendo. |
| 8 | 53–61 s (8 s) | Plano fixo a partir do píer, na altura dos olhos, olhando o barco: o barqueiro na cabine, de perfil contra o sol. Ele não se mexe para descer. | **Barqueiro:** "Daqui o senhor segue." / "O baú tem o que precisa." | Marcha lenta. Água entre o barco e o píer. |
| 9 | 61–68 s (7 s) | O mesmo plano, com um corte para mais perto (meio plano). | **Barqueiro:** "Conhece a regra." / (pausa 1,5 s, sem resposta) "Carga diferente, não autorize." | Marcha lenta. O vento cai e o silêncio fica mais fundo. |
| 10 | 68–73 s (5 s) | Contraplano: a câmera olha para a ilha, a partir do barco. Píer vazio, baú, a casa ao fundo, o farol apagado acima de tudo. (O vigia fica fora do quadro, sem silhueta, para preservar a primeira pessoa.) | **Barqueiro (off):** "Volto às seis." / "Se a luz estiver acesa." | Motor acelera. |
| 11 | 73–79 s (6 s) | Plano geral a partir do píer: o barco se afasta para o sul, ficando pequeno na luz baixa. Já longe, uma lanterna de proa acende. | (nenhuma) | Sino de bordo: **dois** toques secos, espaçados. Motor sumindo. No fim fica só o mar. |
| 12 | 79–82 s (3 s) | Fade para o preto. Título. Fade do título para a câmera do jogador, em primeira pessoa no píer, ao lado do baú, já com o controle. | **Letreiro:** "THE LAST KEEPER" | Mar e vento, que continuam no jogo sem corte de áudio. |

**Entrega do controle:** no primeiro quadro jogável, o HUD mostra a linha canônica de `game_state.gd`: *"17:30. O sol está baixo. Você assume o Farol 7 até o amanhecer."* O relógio só começa a contar aqui.

## Pistas plantadas (verdadeiras e enganosas)

| Plano | Pista | Tipo |
|---|---|---|
| 3 | "Ninguém pede o Sete. O senhor pediu." Tomé escolheu vir (§3). | Verdadeira. Semente da motivação real. |
| 4 | "Aquela noite": a noite do *Santa Aurora* e do sumiço do vigia 9 (§2.2). | Verdadeira, sem nome. |
| 5 | O barqueiro evita o casco. O jogador lê como medo do lugar. | Verdadeira (é o *Santa Aurora*), mas sem dizer o porquê. |
| 6 | O rádio de bordo chama "Farol Sete" num farol vazio, com voz molhada (marca dos Lavados, §5.3). | Ambígua: pode ser só interferência da rota. É o único "erro" do mundo na cutscene, coerente com o nível 0 (presságio). |
| 9 | A regra dita como verdade absoluta. | **Enganosa por omissão.** É a regra que funciona 9 vezes em 10 e condenou o *Santa Aurora* (§5.2). |
| 10 | "Se a luz estiver acesa": a rendição depende da lâmpada. | Verdadeira. Prepara os finais A e B (§7.4). |
| 11 | O sino toca **dois** toques, que no código do sino significa perigo (§10). | Verdadeira, mas só se lê depois da placa N11. |

## O que foi acrescentado à história

- **[NOVO] As falas e a caracterização do barqueiro.** A bíblia só diz que ele "não desembarcou" (§3). As falas dele não contradizem nada, e ele não chama o protagonista pelo nome, o que preserva o momento do final C ("O jogador nunca disse o próprio nome").
- **[NOVO] O rádio de bordo chiando "Farol Sete"** antes das 17:30. Isso antecipa levemente a "voz que chama pelo cargo" (§5.5), sem voz identificável e sem chamada resolvível.
- **[NOVO] O sino de bordo do barqueiro, com dois toques.** É um sino diferente do sino sem badalo do píer, que continua mudo, e usa o código de N11 (§7.2, também [NOVO] na bíblia).
- "Volto às seis" fixa o barqueiro da chegada como o mesmo do barco de rendição. A bíblia não diz o contrário, e o final A já tem um barqueiro às 06:00.
