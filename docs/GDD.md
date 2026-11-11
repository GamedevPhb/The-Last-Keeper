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

## 8. Controles (teclado e mouse; controle depois)

| Ação | Tecla |
|---|---|
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
- O livro de registros é a única tela "de menu" e é desenhado como objeto físico.
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
