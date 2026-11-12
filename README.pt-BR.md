# The Last Keeper

[English](README.md) · **Português (BR)**

> Jogo de sobrevivência e gestão em primeira pessoa, com terror atmosférico e visual de PS1, feito em Godot 4.

Você é o único vigia do Farol 7, numa ilha rochosa no fim da rota de navegação. Toda noite você precisa manter a luz acesa, o gerador funcionando e o rádio atento. Os navios dependem de você. Mas nem todo navio que chama pelo rádio deveria estar ali.

**Status:** pré-alfa. A base técnica está pronta; a primeira demo jogável está prevista para janeiro de 2027.

---

## O que já tem

- **Render PS1:** 320×240 nativo, vértices tremendo, texturas distorcidas (mapeamento afim), cor de 15 bits com dithering e neblina densa
- **Controle em primeira pessoa:** andar, correr e olhar com o mouse
- **Sistema de interação:** ações de apertar ou segurar, com texto na tela e barra de progresso
- **Ilha em greybox:** farol com rampa em espiral até a sala da lâmpada, casa do vigia, galpão do gerador e píer
- **Feixe giratório do farol**, que pode ser aceso e apagado

## Requisitos

- [Godot 4.7+](https://godotengine.org/download) (versão padrão ou .NET)
- Placa de vídeo com suporte a OpenGL 3.3 (o projeto usa o renderizador Compatibility)

## Como rodar

1. Clone o repositório.
2. Abra o Godot, clique em **Importar** e selecione o `project.godot`.
3. Aperte **F5**.

Ou pelo terminal:

```bash
godot --path .
```

## Controles

| Ação | Tecla |
|---|---|
| Andar | W A S D |
| Olhar | Mouse |
| Correr | Shift |
| Interagir (apertar ou segurar) | E |
| Soltar o mouse | Esc (clique para capturar de novo) |

## Testes

Um teste automático sem janela sobe o farol e acende/apaga a lâmpada pelo sistema de interação:

```bash
godot --headless --path . --script res://tests/smoke_test.gd
```

## Ajustando o efeito PS1

Em **Projeto → Configurações do Projeto → Shader Globals**:

| Global | Efeito |
|---|---|
| `psx_vertex_snap` | Tamanho da grade do tremor dos vértices, em pixels (`0` desliga) |
| `psx_affine_strength` | Distorção das texturas, de `0` (correta) a `1` (PS1 total) |

A profundidade de cor e o dithering ficam no nó `PsxPost/Filter` da `main.tscn`.

## Estrutura do projeto

```
docs/          GDD e plano de desenvolvimento
interaction/   Componente Interactable
materials/     Materiais do greybox
player/        Jogador em primeira pessoa
shaders/       Shaders PS1 (iluminado, água, pós-processamento)
tests/         Teste automático (headless)
ui/            HUD
world/         Ilha, farol, rampa em espiral, lâmpada
main.tscn      Cena principal
```

## Documentação

- [Game Design Document](docs/GDD.md)
- [Plano de desenvolvimento](docs/PLANO.md)
- [Sprints até o lançamento](docs/SPRINTS.md)

## Licença

Código: [MIT](LICENSE). Arte, narrativa e demais assets criativos: [CC BY-NC 4.0](LICENSE-ASSETS.md). Nomes e logos não estão cobertos por nenhuma das duas.
