# The Last Keeper: lista de assets

Tudo que o jogo precisa daqui para frente, na ordem em que deve ser produzido. Base: o que já existe no projeto (blocos cinza em `world/island.tscn` e `world/island_details.tscn`), a bíblia narrativa (`docs/HISTORIA.md`) e os pedidos novos (criaturas marítimas, orca de quatro patas e o chefe secreto Portinho).

## Como ler

**Prioridade**
- **P0**: bloqueia a jogabilidade (o jogador não consegue entender onde clicar).
- **P1**: dá identidade ao jogo e é preciso para a versão de lançamento.
- **P2**: acabamento, extras e segredos.

**Regras técnicas (visual PS1)**
| Item | Padrão |
|---|---|
| Formato | `.glb` (modelos), `.png` (texturas e ícones), `.wav` ou `.ogg` (som) |
| Escala | 1 unidade = 1 metro, origem (pivô) no chão, eixo Y para cima |
| Texturas | 64×64, 128×128 ou 256×256, paleta reduzida, sem suavização. O dithering e a profundidade de cor 15-bit já são feitos pelo shader do jogo |
| Polígonos | prop pequeno 50–300 triângulos; prop grande 300–800; criatura 400–1500; chefe até 3000; farol e casa 1500–2500 cada |
| UV | afim (sem correção de perspectiva), deixe a textura levemente distorcida: é o look |
| Colisão | caixa ou cápsula simples separada, nomeada `col_<nome>` |
| Nomes | `categoria_nome_variante`, minúsculas, sem espaço. Ex.: `prop_disjuntor_a`, `cre_lavado_02` |
| Materiais | usar `psx_lit` (ou `psx_water`). Um material por textura |

**Regra de legibilidade (resolve o "não sei onde clicar").** Todo objeto interativo precisa de **silhueta própria**, **cor própria** e **um detalhe de função** (alavanca, dial, válvula, etiqueta). Nunca dois interativos com a mesma forma. Ao mirar, o objeto ganha realce e o aviso no HUD já existe.

---

## 1. Criaturas

Conceito: os afogados e náufragos que o mar devolveu. Maioria marinha. O jogador nunca vê tudo de uma vez: primeiro o som, depois a silhueta, só no fim o corpo.

| ID | Criatura | Descrição | Tam. | Tris | Animações | Prior. |
|---|---|---|---|---|---|---|
| cre_01 | **Lavado** (marinheiro afogado, o "zumbi") | Tripulante do *Santa Aurora*: roupa de marujo encharcada, pele azulada, algas, anda arrastando os pés | 1,8 m | 900 | idle, andar, correr curto, ataque, cair | P1 |
| cre_01b | Lavado variante | Mesma base, 3 trocas de textura (marujo, oficial, cozinheiro) | 1,8 m | 0 (textura) | – | P1 |
| cre_02 | **Encalhado** | Preso aos recifes: metade corpo, metade casco, rasteja | 1,2 m | 800 | idle, rastejar, ataque | P1 |
| cre_03 | **Sineiro** | Figura alta que toca o sino sem badalo; só aparece ao longe | 2,3 m | 1100 | idle, balançar sino | P1 |
| cre_04 | **A Voz** | Vulto sem rosto na beira do mar. Quase nunca aparece, é o rádio | 1,9 m | 400 | idle, sumir | P2 |
| cre_05 | **Capitã** | Chefe da noite 3 ou 4 (ver `HISTORIA.md` §4): oficial com chapéu, casaco longo, uma das mãos de corda | 2,0 m | 1500 | idle, andar, ataque, rugido | P1 |
| cre_06 | **Casco** (o *Santa Aurora*) | Navio fantasma que chega à costa, sem tripulação visível. Modelo grande, de longe | 40 m | 2500 | balanço leve (shader) | P1 |
| cre_07 | **Gaivotas Mudas** | Aves pretas silenciosas empoleiradas, viram a cabeça | 0,4 m | 150 | idle, virar cabeça, voar | P2 |
| cre_08 | **Luzes-de-Vigia** | Pontos de luz sobre o mar que imitam a lâmpada do farol | – | – | (efeito, ver §8) | P2 |
| cre_09 | **Névoa-Viva** | Neblina que se move contra o vento | – | – | (efeito, ver §8) | P2 |
| **cre_10** | **Orca de quatro patas** *(novo)* | Orca que sai do mar andando em quatro patas e ataca marinheiros e pescadores. Pele preta e branca, patas curtas e grossas de foca ou crocodilo, boca grande | 4,5 m | 1500 | idle, andar, correr, ataque de mordida, mergulhar, rugido | **P1** |
| cre_10b | Orca: vítimas | Marinheiro e pescador de costas para a orca, para cenas e armadilhas | 1,8 m | 600 | idle, ser derrubado | P2 |

**Pendência:** a imagem da orca de quatro patas foi enviada a você, não a mim. Mande-a para eu escrever a ficha de modelagem (proporção das patas, cicatrizes, cor). Até lá, a descrição acima é provisória.

### Chefe secreto: Portinho (demônio)

O **Portinho** é o farol-mascote da Porto Indie, aqui em **versão demônio**. Ele **não é o farol do jogo**. É um monstro secreto, liberado quando o jogador resolve os puzzles escondidos.

| ID | Asset | Descrição | Tris | Prior. |
|---|---|---|---|---|
| boss_01 | **Portinho demônio**, modelo | Silhueta do Portinho original, deformada: olhos acesos em vermelho, boca de fresta na torre, chifres ou gárgulas no topo, pernas ou raízes de pedra | 3000 | P2 |
| boss_02 | Portinho, 2 fases | Fase 2: rachado, luz mais forte, braços de ferro | +500 | P2 |
| boss_03 | Animações | idle, andar pesado, golpe, rugido, desabar | – | P2 |
| boss_04 | Arena | Local do encontro (proposta: base do farol sob o penhasco), com chão, pedras e iluminação própria | 1500 | P2 |
| boss_05 | Chaves do segredo | 4 relíquias escondidas (proposta: sino, lente, âncora e chave) e o altar onde se encaixam | 4 × 150 | P2 |
| boss_06 | Efeitos | Olhos brilhantes, feixe vermelho, rachaduras, poeira de pedra | – | P2 |
| boss_07 | Áudio | Rugido grave, passos de pedra, sino rachado, trilha própria | 5 sons | P2 |

**Para começar o Portinho**, preciso da arte do Portinho original (logo ou mascote da Porto Indie) e de uma decisão sua sobre o **desbloqueio** (quais puzzles e se é só na noite final). O desenho acima é proposta, a validar.

---

## 2. Cenário: farol e ilha

| ID | Asset | Itens | Tris | Prior. |
|---|---|---|---|---|
| env_01 | **Farol, torre** | Corpo cônico de pedra com anéis, base, galeria com grade, janelas pequenas, porta de ferro | 1800 | **P0** |
| env_02 | **Farol, lanterna** | Sala de vidro, lente de Fresnel (anéis), base de metal, cúpula, para-raios | 900 | **P0** |
| env_03 | **Farol, interior** | Rampa em espiral com corrimão, degraus, janelas, bancada de manutenção | 1200 | P0 |
| env_04 | **Mecanismo do farol** | Tanque de óleo, manivela, engrenagem, corda com peso, lente giratória | 600 | **P0** |
| env_05 | **Ilha, terreno** | Malha do chão com areia, terra, relva, trilhas, praia, ressaca | – | P1 |
| env_06 | Penhascos e rochas | 6 rochas grandes, 6 pequenas, 3 penhascos | 150 cada | P1 |
| env_07 | Praia e água | Linha de espuma, faixa de maré, algas, conchas, gravetos | – | P1 |
| env_08 | **Naufrágio** (casco encalhado) | Casco aberto, mastro quebrado, cordas, caixas | 1200 | P1 |
| env_09 | **Ilhéu do tambor** | Pedras da travessia (maré), tambor de óleo, caixote, corda | 600 | P0 |
| env_10 | Muro e cercas | Muro de pedra baixo, portão, cerca de madeira | 5 peças | P1 |
| env_11 | Horizonte | Céu noturno, nuvens, lua, ilhas ao longe | – | P1 |

## 3. Cenário: construções

### Casa do vigia
| ID | Asset | Prior. |
|---|---|---|
| env_20 | Casa, exterior (paredes, telhado, chaminé, varanda, porta, janelas) | **P0** |
| env_21 | Casa, interior (piso de tábuas, paredes, teto com vigas) | **P0** |
| env_22 | **Cama** (colchão, travesseiro, cobertor, estrado) | P0 |
| env_23 | Mesa de trabalho + cadeira | P0 |
| env_24 | **Livro de registros** (aberto e fechado) | P0 |
| env_25 | **Rádio** (caixa, dial de sintonia, mostrador, alto-falante, microfone, antena) | **P0** |
| env_26 | Estante com livros, caixas, caderno | P1 |
| env_27 | Fogão a lenha + chaleira + lenha | P1 |
| env_28 | Lampião de querosene, vela | P1 |
| env_29 | Tapete, quadro, mapa náutico na parede | P2 |
| env_30 | **Escotilha do porão** + escada + cadeado de 3 discos | **P0** |
| env_31 | Porão (prateleiras, caixas, 2 latas de reserva) | P1 |

### Galpão do gerador e pátio
| ID | Asset | Prior. |
|---|---|---|
| env_40 | Galpão, exterior (chapa metálica, porta de correr, exaustor) | P0 |
| env_41 | **Gerador** (carcaça, painel com 3 válvulas numeradas, manômetro, alavanca de partida, tanque, exaustão) | **P0** |
| env_42 | **Quadro de disjuntores** (caixa metálica, tampa, 3 disjuntores com alavanca e etiqueta) | **P0** |
| env_43 | Barris de combustível (2 cores) + bomba + mangueira | P0 |
| env_44 | Bancada com ferramentas | P1 |
| env_45 | Canos e cabos pelo chão | P1 |

### Píer e entorno
| ID | Asset | Prior. |
|---|---|---|
| env_50 | **Píer** (tábuas, pilares, degraus, corda) | P0 |
| env_51 | Bitas, correntes, pneus de defensa | P1 |
| env_52 | **Poste de luz do píer** (lanterna com chama fraca) | P0 |
| env_53 | **Baú de suprimentos** (aberto e fechado) | **P0** |
| env_54 | Barco a remo + remos | P1 |
| env_55 | Caixotes, rede de pesca, boias | P2 |

### Cemitério
| ID | Asset | Prior. |
|---|---|---|
| env_60 | Lápides (5 variantes: reta, arredondada, quebrada, cruz, cruz torta) | P1 |
| env_61 | Cruzes de madeira, cercas, portão | P1 |
| env_62 | Vasos, flores secas, velas | P2 |
| env_63 | Capela pequena (opcional) | P2 |

---

## 4. Vegetação

| ID | Asset | Variantes | Tris | Prior. |
|---|---|---|---|---|
| veg_01 | **Pinheiro** | 3 alturas | 150–250 | P1 |
| veg_02 | Pinheiro morto | 2 | 120 | P1 |
| veg_03 | Toco e tronco caído | 3 | 80 | P1 |
| veg_04 | **Arbusto** | 3 | 80 | P1 |
| veg_05 | **Capim / grama** (cartões com textura em alfa) | 3 | 4 | P1 |
| veg_06 | Samambaia, mato alto | 2 | 20 | P2 |
| veg_07 | Flores secas, cardos | 2 | 10 | P2 |
| veg_08 | Musgo e líquen (decalque na pedra) | 2 | – | P2 |
| veg_09 | Algas e ervas marinhas (praia) | 3 | 20 | P2 |
| veg_10 | Raízes expostas no penhasco | 2 | 60 | P2 |

## 5. Texturas

Substituem os materiais cinza atuais (`materials/m_*.tres`). 128×128 salvo indicação.

| Material atual | Textura nova | Detalhe |
|---|---|---|
| m_ground | tex_terra, tex_areia, tex_relva | 3 texturas misturadas por vértice |
| m_path | tex_trilha | terra batida com pegadas |
| m_stone / m_rock | tex_pedra_farol, tex_rocha_costa | pedra com limo e sal |
| m_plaster | tex_reboco | reboco descascado |
| m_concrete | tex_concreto | manchas de umidade |
| m_wood | tex_tabua_nova, tex_tabua_velha | tábuas, nós e rachaduras |
| m_deadwood | tex_madeira_morta | tronco seco |
| m_metal | tex_metal_ferrugem, tex_chapa_zinco | ferrugem, parafusos |
| m_pine / m_bush / m_grass | tex_pinheiro, tex_arbusto, tex_capim | folhagem com alfa |
| m_lamp | tex_vidro_sujo, tex_lampada | vidro leitoso |
| m_paper | tex_papel, tex_couro_livro | páginas amareladas |
| m_water | tex_agua, tex_espuma | ondas animadas |
| (novo) | tex_telha, tex_tecido_cama, tex_corda, tex_casco_navio, tex_pele_lavado, tex_pele_orca, tex_sangue_mancha | |

Todas **ladrilháveis** (repetem sem emenda), exceto as de criaturas e de itens únicos. Opcionais para P2: variantes "molhadas" e "mofadas" para a ilha mudar ao longo da noite.

---

## 6. Props interativos

Aqui está o que resolve o "caixa vermelha, impossível saber onde clicar". Cada interativo precisa de modelo próprio com **partes que o jogador reconhece**.

| Prop | Como deve ser | Cor/rótulo | Hoje |
|---|---|---|---|
| **Disjuntores (3)** | Quadro cinza com 3 alavancas grandes que sobem e descem, etiqueta A/B/C e luz verde ou vermelha | cinza + verde/vermelho | caixa vermelha |
| **Gerador** | Motor com 3 válvulas de volante numeradas, manômetro de agulha, alavanca de partida, tanque | amarelo industrial | caixa |
| **Rádio** | Caixa de madeira, dial redondo grande, mostrador de frequência, lâmpada de "chamada" que pisca | madeira + verde | caixa |
| **Tambor de óleo** | Barril azul com tampa e bico, lata ao lado | azul | cilindro |
| **Latas de óleo e combustível** | Latas distintas: óleo (amarela, gota), combustível (vermelha, chama) | amarelo / vermelho | – |
| **Manivela do farol** | Roda com cabo, ao lado do mecanismo | latão | caixa |
| **Lente do farol** | Vidro com anéis, pano de limpeza ao lado | – | caixa |
| **Baú** | Baú de madeira com cinta metálica e fecho | marrom | caixa |
| **Cadeado de 3 discos** | 3 discos com dígitos gravados | latão | caixa |
| **Livro** | Livro grosso em cima da mesa, com marcador | marrom | caixa |
| **Cama** | Cama com colchão e cobertor (para dormir ou descansar, futuro) | tecido | caixa |
| **Pistas** (placas, etiquetas, inscrições) | Placa de madeira, etiqueta de papel, gravação na pedra | – | caixa |

**Itens carregáveis:** os mesmos objetos, em versão pequena, também aparecem no inventário (§7).

## 7. Ícones do inventário e HUD

Ícones 32×32, 1 bit de contorno + 4 cores, estilo PS1.

- Lata de óleo, lata de combustível, lanterna, livro de registros, nota, fusível, pilha, binóculo (final C), chave, sino, lente, relíquias do Portinho (4), mapa
- Ícones de estado: gerador ligado, lâmpada acesa, rádio com sinal, maré alta e baixa
- Ícone de interação (mão, engrenagem, olho)

## 8. Efeitos (VFX)

| Efeito | Uso | Prior. |
|---|---|---|
| Feixe do farol (cone volumétrico, atravessa a neblina) | Noite, com lâmpada acesa | **P0** |
| Cone da lanterna com recorte | Lanterna do jogador | P0 |
| Estática do rádio, tela ligada | Rádio | P1 |
| Faíscas e fumaça do gerador e da chaminé | Gerador | P1 |
| Espuma e ondas na costa | Mar | P1 |
| Neblina baixa que se move | Atmosfera, Névoa-Viva | P1 |
| Pontos de luz sobre o mar | Luzes-de-Vigia | P2 |
| Olhos brilhantes (vermelho/amarelo) | Criaturas, Portinho | P2 |
| Respingos e gotas (criaturas molhadas) | Lavados, orca | P2 |
| Aparição e sumiço (dissolver) | A Voz | P2 |

## 9. Áudio

O jogo hoje usa sons **procedurais** (`audio/synth.gd`). O que falta para versão final:

| Grupo | Itens | Prior. |
|---|---|---|
| Criaturas | Lavado (gemido, passos molhados), Encalhado (arrastar), Sineiro (sino), orca (rugido, mordida, passos pesados na areia), Capitã (voz grave), Portinho (rugido, pedra) | P1/P2 |
| Rádio | Falas das 11 chamadas anômalas e dos navios (voz distorcida), estática, bipes | P1 |
| Ambiente | Mar (3 camadas), vento, gaivotas, madeira rangendo, sino distante | P1 |
| Mecanismo | Gerador (loop), disjuntores, válvulas, manivela, lâmpada, tambor | P1 |
| Música | Trilha própria em camadas (calma, tensão, perigo), tema do Portinho | P1/P2 |

## 10. Interface

Já pronta: tema de painéis e botões, abertura, menu, HUD, pausa, inventário, livro. Falta:
- Fundo de pergaminho para as páginas do livro (P1)
- Mapa da ilha ilustrado (P1)
- Cartão de chamada do rádio com o ícone do navio (P1)
- Telas de final: sobreviver, falhar, verdadeiro (P1)
- Tela de "Game Over" e créditos (P2)

---

## Resumo da produção

| Bloco | Itens | P0 | P1 | P2 |
|---|---|---|---|---|
| Criaturas | 11 | 0 | 6 | 5 |
| Portinho (chefe secreto) | 7 | 0 | 0 | 7 |
| Farol e ilha | 11 | 5 | 6 | 0 |
| Construções | 28 | 12 | 11 | 5 |
| Vegetação | 10 | 0 | 5 | 5 |
| Texturas | ~25 | 10 | 10 | 5 |
| Props interativos | 12 | 12 | 0 | 0 |
| Ícones | ~25 | 8 | 12 | 5 |
| VFX | 10 | 2 | 4 | 4 |
| Áudio | 5 grupos | 0 | 3 | 2 |
| Interface | 5 | 0 | 4 | 1 |

### Ordem recomendada
1. **P0 primeiro**: props interativos (disjuntores, gerador, rádio, baú), farol, casa e píer. É o que mais melhora a jogabilidade, e já resolve o problema de "não sei onde clicar".
2. Texturas P0, para tirar o visual cinza.
3. Criaturas P1: Lavado, orca, Encalhado, Capitã e Casco.
4. Vegetação, cenário P1, VFX e áudio.
5. P2 e o Portinho por último.

### Como produzir
- **Modelagem:** Blender, com os modelos baixos descritos acima. Há integração com o Blender nesta máquina para modelar por script.
- **Atalhos legítimos:** bibliotecas de licença livre (Kenney, Quaternius, Poly Haven) para vegetação, rochas e props genéricos, que cobrem boa parte do P1. Confira a licença de cada arquivo.
- **Texturas:** pintadas em 128 px, ladrilháveis, com paleta curta.
- **Entrega ao jogo:** um `.glb` por asset em `assets/modelos/`, texturas em `assets/texturas/`, sons em `audio/`.

## Pendências

1. **Imagem da orca de quatro patas.** Preciso dela para a ficha.
2. **Arte do Portinho original** (mascote ou logo da Porto Indie).
3. **Desbloqueio do Portinho:** quais puzzles e em que noite.
4. **Estilo dos zumbis** (marujos de época ou modernos?) e se podem morrer ou só recuam.
5. **Quem produz os assets:** modelar aqui, comprar pacotes ou contratar. Isso define o prazo.
