# Plano de Desenvolvimento: Demo Jogável

> **The Last Keeper** · Início 2026-11-10 · Meta: demo em **~2027-01-05** (8 semanas) · Ritmo: 3–5 h/semana (~30 h no total)

**A demo é o MVP do GDD (seção 12):** uma noite completa, do anoitecer ao amanhecer, com lâmpada, gerador, rádio e dois navios (um regular, um anômalo), no visual PS1, publicada no itch.io.

**Divisão do trabalho:** o Claude escreve código, cenas e modelos (Blender via MCP). Você testa, decide e aprende: cada semana tem uma tarefa sua de aprendizado ligada ao que foi construído.

---

## Semana 1: Base técnica ✅ (concluída em 2026-11-10)

- [x] Projeto configurado: 320×240 nativo, filtro *nearest*, inputs, camadas de física
- [x] Shaders PS1: jitter de vértice, textura afim, mar com ondas, dithering 15-bit
- [x] Jogador em primeira pessoa (andar, correr, olhar, respawn ao cair no mar)
- [x] Sistema de interação (apertar e segurar, prompt e barra no HUD)
- [x] Ilha *greybox*: farol com rampa em espiral, casa do vigia, galpão, píer, pedras
- [x] Lâmpada giratória (*placeholder*) que acende e apaga segurando E
- [x] Teste automático: sobe o farol e aciona a lâmpada (`tests/smoke_test.gd`)

**Sua tarefa:** abrir o projeto no Godot, rodar com F5, andar pela ilha e subir o farol. Abrir `player/player.gd` e mudar `walk_speed` para sentir o efeito.

---

## Semana 2: Lâmpada completa

- [ ] Óleo: consumo contínuo, medidor no mundo, abastecer com a lata (segurar E)
- [ ] Corda da rotação: manivela, a rotação para quando a corda acaba
- [ ] Lente suja: o alcance do feixe cai, limpar com pano (segurar E)
- [ ] Som do mecanismo girando (o "relógio" sonoro)

**Entregável:** dá pra manter a luz acesa por uma noite cuidando dos três recursos.
**Sua tarefa:** ajustar os tempos de consumo no Inspector e ver o que deixa a noite tensa sem ficar chata.

## Semana 3: Gerador e carregar itens

- [ ] Gerador: diesel, liga/desliga, mostrador de estado
- [ ] Uma falha (fusível queimado) com conserto curto
- [ ] Carregar objetos (latas, peças): ocupa as mãos e deixa o jogador mais lento
- [ ] Depósito na base do farol com estoque físico

**Entregável:** o gerador falha e você corre até o galpão, pega a peça e conserta.

## Semana 4: Rádio e diretor da noite

- [ ] `NightDirector` (autoload): relógio da noite (anoitecer → amanhecer em ~12 min)
- [ ] Roteiro da noite em `.tres`: lista de eventos com horário
- [ ] Rádio: sintonizar o dial, ouvir a chamada, escolher a resposta
- [ ] 3 chamadas roteirizadas (texto + áudio *placeholder*)

**Entregável:** a noite tem começo, meio e fim, com eventos acontecendo sozinhos.

## Semana 5: Navios e a decisão

- [ ] Navio: modelo simples, rota pelo mar, luzes de navegação
- [ ] Binóculo (botão direito): zoom da câmera
- [ ] Manifesto na mesa (papel legível)
- [ ] Decisão: guiar / alertar (sirene ou sinal de luz) / ignorar, com consequências
- [ ] 1 navio regular + 1 anômalo na noite

**Entregável:** o *loop* principal do GDD completo, ainda em *greybox*. **Marco: primeira versão jogável de ponta a ponta.**

## Semana 6: Arte no Blender

- [ ] Instalar o Blender e conectar o MCP (ver "Pendências")
- [ ] *Style guide*: paleta, densidade de textura, limite de polígonos
- [ ] Modelar: farol, casa do vigia, galpão, píer (com as skills `psx-horror-style`, `lowpoly-style`, `godot-export`)
- [ ] Props-chave: lâmpada, gerador, rádio, lata de óleo, navio
- [ ] Trocar o *greybox* pelos modelos mantendo as colisões

**Sua tarefa:** acompanhar uma modelagem e fazer um prop simples sozinho (ex.: a lata de óleo).

## Semana 7: Áudio, atmosfera e telas

- [ ] Ambiente: mar, vento, chuva leve, rangidos
- [ ] Vozes do rádio com filtro e estática
- [ ] Relatório do amanhecer (navios salvos/perdidos)
- [ ] Menu principal, pausa e opções (sensibilidade, intensidade do jitter, volume)

## Semana 8: Polimento e lançamento da demo

- [ ] Playtest com 2–3 pessoas e ajuste de dificuldade
- [ ] Correções de bugs
- [ ] Export: Linux, Windows e Web
- [ ] Página no itch.io (capturas, GIF, descrição)

**Entregável:** demo publicada.

---

## Se atrasar: o que cortar (nesta ordem)

1. Sirene de neblina (fica só o sinal de luz)
2. Lente suja (fica só óleo e corda)
3. Export Web
4. Arte final dos props pequenos (ficam em *greybox* texturizado)
5. Menu de opções (fica só pausa)

**Não cortar:** a decisão sobre o navio anômalo. É o coração do jogo.

## Pendências

- **Blender:** não está instalado. Antes da semana 6, rode `sudo snap install blender --classic`, depois instale o addon do MCP: em *Edit → Preferences → Add-ons → Install*, escolha o `addon.py` de <https://github.com/ahujasid/blender-mcp> e clique em *Connect* no painel lateral (N) do Blender. O MCP `blender` já está registrado no Claude Code.
- **Git:** o projeto ainda não é um repositório. Recomendado antes da semana 2.
- **Questões em aberto do GDD (seção 14):** nome final e idioma da demo.

## Como rodar o teste

```bash
godot-4 --headless --path . --script res://tests/smoke_test.gd
```
