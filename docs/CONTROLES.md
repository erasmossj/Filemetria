# Controles e Input Map

Toda entrada passa pelo Input Map (`project.godot`, seção `[input]`), como pede o [CONVENCOES_E_BOAS_PRATICAS.md](CONVENCOES_E_BOAS_PRATICAS.md#input). As ações do jogo usam a posição física da tecla (`physical_keycode`), então funcionam igual em teclado ABNT2 e US.

## Ações do jogo

| Ação | Tecla | O que faz | Quem lê |
| --- | --- | --- | --- |
| `up` / `down` / `left` / `right` | W / S / A / D ou setas | Andar | `player.gd` |
| — | Mover o mouse | Olhar (girar o Player e a cabeça) | `player.gd` (`InputEventMouseMotion`) |
| `fly_up` | Espaço | Subir | `player.gd` |
| `fly_down` | Shift | Descer | `player.gd` |
| `left_click_mouse` | Botão esquerdo | Marcar ponto (A; o próximo, B, fecha a reta) | `player.gd` → `PointSystem.add_point` |
| `right_click_mouse` | Botão direito | Apagar o ponto mirado e a reta dele | `player.gd` → `PointSystem.remove_point` |
| `cancel_line` | Q | Cancelar a reta em andamento | `player.gd` → `PointSystem.cancel_line` |
| `undo_line` | E (sem modificador) | Desfazer a última reta | `player.gd` → `PointSystem.undo_last_line` |
| `clear_lines` | R | Apagar todas as retas | `player.gd` → `PointSystem.clear_lines` |
| `answer_menu` | Tab | Abrir e fechar o menu de chute da área | `answer_menu.gd` |
| `show_controls` | F1 (segurar) | Mostrar o painel de controles do HUD | `hud.gd` |
| `pause` | Esc | Liberar o cursor e pausar o cronômetro | `player.gd` → `fase_farol.gd` |

As ações `ui_up`, `ui_down`, `ui_left` e `ui_right` são as padrão do Godot para navegar na interface, com WASD acrescentado às setas e ao direcional do controle.

## Onde os controles aparecem para o jogador

- Chip "F1 controles" no canto inferior esquerdo do HUD e o painel aberto por F1 (ver [HUD.md](HUD.md#painel-de-controles-f1)). As linhas do painel ficam nas constantes `CONTROLES_ESQUERDA` e `CONTROLES_DIREITA` de `src/ui/Hud/hud.gd`.
- Tecla Tab no botão "Calcular área".

**Ao mudar uma tecla no Input Map, atualizar esta tabela e as constantes do `hud.gd`.** O HUD não lê o Input Map, porque mostra nomes amigáveis ("Espaço", "botão dir.") em vez dos nomes do Godot.

## Detalhes

- **E com `exact_match`:** o `player.gd` checa o E com `exact_match = true`, então segurar qualquer modificador, inclusive o Shift de descer, impede o desfazer.
- **Esc pausa só o tempo:** o jogo continua rodando. Com o cursor liberado o Player ainda anda e marca pontos (ver [ESTRUTURA_DE_FASES.md](ESTRUTURA_DE_FASES.md#cronômetro-cg-37)).
- **Clique com o mouse capturado:** durante o jogo o cursor fica preso no centro, então o botão "Calcular área" só é clicável com o cursor livre (Esc ou menu aberto). O Tab funciona sempre.
- **Alcance da mira:** sem limite prático. O raio vai até o `far` da câmera (4000 m), então qualquer superfície visível aceita ponto (ver [SISTEMA_DE_PONTOS.md](SISTEMA_DE_PONTOS.md#pontos-de-atenção)).
- **Altura do Player:** a câmera fica a 1,45 m do chão, e a cápsula de colisão tem 1,45 m de altura, com os pés em y = 0.
