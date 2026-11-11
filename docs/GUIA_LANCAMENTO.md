# Guia passo a passo: do jogo pronto ao lançamento no itch.io

Feito a partir do que foi realmente executado em *The Last Keeper* (Godot 4, terror PS1). Serve como tutorial, como artigo para o site da Porto Indie e como roteiro de serviço de lançamento para outros jogos.

Tempo estimado: 1 a 2 dias de trabalho por jogo, com o jogo já jogável.

---

## Visão geral

| # | Etapa | Entrega |
|---|---|---|
| 1 | Identidade visual e logo | Logo em PNG transparente |
| 2 | Telas de entrada (abertura) | Cena de intro no jogo |
| 3 | Capturas de tela | 6 a 8 imagens do jogo atual |
| 4 | Imagens da página | Capa, banner, fundo, fundo do embed |
| 5 | Texto da página | Descrição em HTML simples |
| 6 | Estilo da página | Custom CSS (opcional) |
| 7 | Builds | Web (zip), Windows e Linux |
| 8 | Trailer | Vídeo de 60 s com música |
| 9 | Publicar e testar | Página privada com senha |
| 10 | Convocar testadores e divulgar | Textos prontos |

Regra de ouro: **faça nessa ordem.** O logo alimenta o trailer, a capa e o banner. As capturas de tela só valem depois que a interface do jogo estiver definitiva.

---

## 1. Identidade visual e logo

1. Defina 3 palavras de tom (ex.: sombrio, marítimo, PS1) e 4 cores (fundo quase preto, verde-musgo, latão, vermelho-sangue).
2. Faça o logo em **PNG com fundo transparente**, no tamanho de 1440 px de largura.
3. Para o visual PS1: desenhe em baixa resolução (ex.: 360×180) e amplie 4× **sem suavizar** (filtro *nearest*). Aplique *dithering* e extrusão nas letras.
4. Teste o logo sobre fundo escuro e sobre foto do jogo. Sem contorno claro, ele some em fundo branco, então só use em fundo escuro.

Erro comum: logo muito limpo para um jogo sujo. Se o jogo é de terror, o logo precisa ter desgaste (sangue, rachaduras, bordas comidas).

## 2. Telas de entrada (abertura)

Sequência usada: preto → "UMA PRODUÇÃO DE" + logo do estúdio → "UM OFERECIMENTO" + logo do parceiro → menu.

- Cada logo: surge em 1 s, fica 1,6 s, some em 1 s.
- Qualquer tecla pula.
- Em Godot: uma cena `intro.tscn` como cena principal do projeto, que muda para o menu no final.
- Logos em SVG entram direto no Godot. Defina `svg/scale` na importação para não carregar uma textura enorme.

## 3. Capturas de tela

1. Capture **o jogo atual**, com a interface final. Capturas antigas denunciam jogo desatualizado.
2. Faça de 6 a 8: menu principal, 3 ou 4 cenas do jogo com HUD, inventário, pausa, algum item especial.
3. Mantenha a resolução original e amplie 3× sem suavizar (ex.: 320×240 vira 960×720).
4. Se o jogo é escuro, confira se as imagens aparecem no site. Clareie só nas capturas se precisar.

Dica: faça um script que posiciona o jogador, tira a captura e fecha. Refazer todas leva 1 minuto quando a interface muda.

## 4. Imagens da página (tamanhos)

| Imagem | Tamanho | Observação |
|---|---|---|
| Capa (*Cover image*) | 630×500 | Logo sobre uma cena escurecida |
| Banner | 1920×480 | Logo à esquerda, cena à direita |
| Plano de fundo | 256×256 | **Pattern que repete**, não imagem grande. Use *Repeat: Both* |
| Fundo do embed (*Embed BG*) | 960×720 | Mesmo tamanho da janela do jogo |
| Screenshots | 960×720 | Sobe no campo de screenshots, não na descrição |

O plano de fundo precisa ser quase invisível (contraste baixo), senão atrapalha a leitura do texto.

## 5. Texto da página

**O itch.io pode ignorar o CSS da descrição.** Na prática, o estilo inline não foi reconhecido e a página ficou sem formatação. Escreva em **HTML simples**, sem `style`, e deixe o visual para o tema.

Tags que funcionam bem: `h2`, `p`, `ul`, `li`, `b`, `i`, `table`.

Estrutura que funcionou:
1. Uma frase de gancho em negrito
2. Parágrafo do que o jogador faz
3. **A história** (sem spoiler de final)
4. Criaturas ou elementos principais (lista curta)
5. A mecânica central (lista)
6. Recursos (lista)
7. Controles (tabela)
8. Linha final: engine e estado de desenvolvimento

Deixe comentários `<!-- IMAGEM: ... -->` nos pontos onde vão as imagens, para colocar à mão pelo editor do site.

## 6. Estilo da página (opcional)

Em **Edit theme → Custom CSS**. Regras que dão efeito sem quebrar:
- Fundo da coluna principal escuro e borda fina de latão
- Títulos `h2` em caixa alta com espaçamento entre letras
- Links dourados, botões vermelho-sangue
- Imagens com borda fina

Aviso: o itch.io muda suas páginas de vez em quando. CSS que "refaz tudo" quebra; CSS que só melhora o que existe dura.

## 7. Builds

### Pré-requisito importante
O **Godot mono (C#) não exporta para Web.** Se o projeto é só GDScript, use o editor Godot **padrão** da mesma versão. Os *export templates* precisam ser **da mesma versão exata** do editor (ex.: 4.7.2). Template de outra versão gera jogo que não abre.

### Web
1. Preset **Web**, com `thread_support` desligado (o itch.io não manda os cabeçalhos que threads exigem).
2. Exporte para uma pasta. Saem `index.html`, `index.js`, `index.wasm`, `index.pck` e outros.
3. Compacte **tudo** num `.zip`, com o `index.html` **na raiz** do zip. Não suba o `index.html` solto: sem os outros arquivos o jogo fica numa tela preta. Esse foi o problema que tivemos.
4. No itch.io: marque o zip como *"This file will be played in the browser"*. Tamanho do embed: 960×720.
5. Teste num Chrome normal antes de publicar.

### Windows e Linux
1. Presets Windows e Linux, com o `.pck` embutido no executável (um arquivo só).
2. Suba os arquivos soltos, marcando a plataforma de cada um.

### Antes de cada versão
Rode os testes automáticos do jogo e confira que a abertura nova está no build.

## 8. Trailer (60 s)

**Estrutura:**
| Tempo | Conteúdo |
|---|---|
| 0–8 s | Telas pretas com os logos do estúdio e do parceiro |
| 8–45 s | 5 planos do jogo, sem interface, com 3 frases curtas |
| 45–52 s | Fade para preto |
| 52–60 s | Logo do jogo e a data de lançamento |

**Como gravar:** o Godot grava vídeo e áudio sozinho (modo *movie maker*, `--write-movie`, 30 fps). Um script move a câmera em linha reta por cada plano. Esconda a interface, e aumente o brilho (jogos escuros ficam pretos no vídeo).

**Como montar (ffmpeg):**
- Recorte 16:9 do centro, amplie para 1920×1080 sem suavizar
- Corrija brilho e contraste, adicione grão e vinheta
- Textos como PNG transparente sobre o vídeo, com fade
- Fade de entrada e saída

**Música:** encaixe o trecho mais forte da faixa na revelação do logo. Para isso meça a energia da faixa por segundo e calcule o ponto de entrada. Um silêncio curto antes da virada de ato dá efeito.

**Atenção:** música de filme ou jogo comercial pode ser bloqueada no YouTube e no itch.io. Prefira faixa própria, licenciada ou livre de direitos.

Importante: **mostre só o que é do lançamento.** Se há outras chamadas (testadores, código aberto), faça outro vídeo ou outro post.

## 9. Publicar e testar

1. Deixe a página como **Restricted** (privada), com senha.
2. Suba os builds, as imagens e o texto.
3. Abra a página como se fosse um visitante e confira: imagens carregam? O embed abre? O botão de download funciona?
4. Só depois mude a visibilidade.

## 10. Convocar testadores e divulgar

Dois textos prontos (curto para chat e redes, longo para post), em dois casos:

**A. Convite a testadores escolhidos:** link da página, senha, o que testar e o que perguntar:
- Entendeu o que fazer logo no começo?
- Algum momento foi confuso ou injusto?
- Algo travou, bugou ou ficou escuro demais?
- Até onde chegou?

**B. Convocação aberta:** **sem link nem senha.** Quem quer participar se inscreve em formulário, e só os escolhidos recebem o acesso. Diga quem você procura, o que a pessoa ganha (jogar antes, nome nos agradecimentos) e como se inscrever.

Dica: se a senha for pública, ela deixa de proteger. Use uma só para os testadores.

---

## Checklist final

- [ ] Logo em PNG transparente
- [ ] Abertura no jogo, qualquer tecla pula
- [ ] 6 a 8 capturas do jogo **atual**
- [ ] Capa 630×500, banner 1920×480, fundo repetível, embed BG 960×720
- [ ] Descrição em HTML simples
- [ ] Zip Web com `index.html` na raiz
- [ ] Builds Windows e Linux
- [ ] Trailer de 60 s com música liberada
- [ ] Página testada em modo privado
- [ ] Textos de testadores e de divulgação

## Como isso vira serviço

Cada etapa acima é um item de escopo com entrega clara. Pacotes possíveis:
1. **Identidade:** logo, capa, banner, fundo (etapas 1 e 4)
2. **Página:** texto, estilo e publicação (etapas 5, 6 e 9)
3. **Lançamento completo:** tudo, mais builds, trailer e textos de divulgação (etapas 1 a 10)

O tempo gasto está na gravação e montagem do trailer e na revisão da página. O resto é repetível.
