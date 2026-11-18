# Mãos em primeira pessoa (The Last Keeper)

Antebraços, punhos de oleado e luvas de couro do próprio `assets/personagem/keeper.glb` (mesma geometria e mesmo atlas pintado 256x256; dedos e polegar separados, 2 falanges cada). Luz: cone quente da lanterna + fill azul fraco. Quadros 160x120 (4:3), PNG RGBA com fundo transparente, alfa binário, sem antialiasing, paleta única de 28 cores. Filtro nearest ao importar. Cada animação fica em `<nome>/NN.png` com `<nome>/<nome>_sheet.png` (tira horizontal).

| Animação | Quadros | FPS | Loop | Notas |
|---|---|---|---|---|
| idle | 8 | 8 | sim | respiração, duas mãos livres |
| lanterna_idle | 8 | 8 | sim | direita com lanterna, leve balanço |
| lanterna_ligar | 5 | 10 | não | clique; lente acende no quadro 2 |
| lanterna_desligar | 5 | 10 | não | lanterna_ligar ao contrário (lente apaga no quadro 3) |
| andar | 8 | 10 | sim | lanterna na direita |
| correr | 8 | 12 | sim | amplitude maior |
| andar_vazio | 8 | 10 | sim | mesmo ciclo de andar, mao livre (pose de idle); sem variante _luz |
| correr_vazio | 8 | 12 | sim | mesmo ciclo de correr, mao meio fechada; sem variante _luz |
| andar_lata | 8 | 10 | sim | ciclo de andar segurando a lata (pose de segurar_lata), lata balanca atrasada |
| correr_lata | 8 | 12 | sim | idem, amplitude de correr |
| pegar | 10 | 10 | não | alcança a lata (vermelha) e levanta; termina na pose de segurar_lata |
| segurar_lata | 6 | 8 | sim | lata na mão direita |
| interagir | 7 | 8 | não | gira a válvula (roda de latão) |
| bombear | 8 | 10 | sim | alavanca da bomba de pressão |

Regerar: `flatpak run org.blender.Blender --background --python <abs>/build_maos.py` (poses em `maos_anims.py`; cria `_raw/`), depois `python3 postprocess.py` (paleta, alfa e sheets) e `python3 fix_single_hand.py [anim ...]` (deixa so a mao direita; le de `_original/`). `_raw/` pode ser apagada.

So animacoes novas: passe os nomes depois de `--` no Blender (`... build_maos.py -- andar_vazio correr_vazio`); o `postprocess.py` reaproveita a paleta de 28 cores de `_original/` e o `fix_single_hand.py <nomes>` copia a saida para `_original/` antes de processar, sem tocar nas demais. As clips `*_vazio` e `*_lata` sao renderizadas sem a mao esquerda (corte 0).
