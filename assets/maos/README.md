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
| pegar | 10 | 10 | não | alcança a lata (vermelha) e levanta; termina na pose de segurar_lata |
| segurar_lata | 6 | 8 | sim | lata na mão direita |
| interagir | 7 | 8 | não | gira a válvula (roda de latão) |
| bombear | 8 | 10 | sim | alavanca da bomba de pressão |

Regerar: `flatpak run org.blender.Blender --background --python <abs>/build_maos.py` (poses em `maos_anims.py`; cria `_raw/`), depois `python3 postprocess.py` (paleta, alfa e sheets). `_raw/` pode ser apagada.
