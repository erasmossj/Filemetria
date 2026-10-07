# Sistema de pontos — PointSystem e SpawnManager

O jogador ancora dois pontos em superfícies com colisão e o jogo traça uma reta entre eles, guardando o comprimento em metros (1 unidade = 1 metro). O **PointSystem** decide o que criar e apagar; o **SpawnManager** só executa. O **Player** lê o input e chama as funções públicas do PointSystem.

## Controles

| Tecla | Ação no Input Map | Função chamada | Efeito |
| --- | --- | --- | --- |
| Clique esquerdo | `left_click_mouse` | `add_point(posição)` | Ancora o ponto A; se já houver um A, fecha a reta no ponto B |
| Clique direito | `right_click_mouse` | `remove_point(ponto)` | Apaga o ponto mirado e a reta a que ele pertence |
| Q | `cancel_line` | `cancel_line()` | Cancela a reta em andamento (apaga o ponto A) |
| E | `undo_line` | `undo_last_line()` | Desfaz a última reta fechada |
| R | `clear_lines` | `clear_lines()` | Apaga todas as retas e a reta em andamento |

A lista completa de teclas está em [CONTROLES.md](CONTROLES.md).

## Visão geral

```mermaid
flowchart LR
    Player["<b>Player</b><br/>player.gd<br/>lê input e raycast"]
    RayCast["<b>RayCast3D</b><br/>filho de Head/Vertical<br/>até o far da câmera, para −Z (a mira)"]
    PointSystem["<b>PointSystem</b><br/>point_system.gd, no Player<br/>guarda o A pendente<br/>e a lista de retas"]
    SpawnManager["<b>SpawnManager</b><br/>spawn_manager.gd, na cena<br/>cria e remove entidades"]
    Point["<b>Point</b><br/>point.gd + point.tscn<br/>esfera de raio 0,05<br/>+ medida na tela"]
    Line["<b>Line</b><br/>line.gd + line.tscn<br/>cilindro deitado no eixo Z"]

    Player -- "1. force_raycast_update<br/>get_collider" --> RayCast
    Player -- "2. add_point / remove_point<br/>cancel_line / undo_last_line<br/>clear_lines" --> PointSystem
    PointSystem -- "3. spawn_entity<br/>remove_entity" --> SpawnManager
    SpawnManager -- "4" --> Point
    SpawnManager -- "5. look_at + set_length" --> Line
```

Pontos e retas são filhos da cena atual, não do SpawnManager. O único estado do sistema fica no PointSystem.

## Player: leitura do input

O bloco fica no fim de `_physics_process` em `src/entities/player/player.gd` e roda em duas partes.

**Ações que não dependem da mira** (Q, R, E) são checadas antes do raycast, então funcionam mirando em qualquer lugar:

1. Q chama `cancel_line()`.
2. R chama `clear_lines()`.
3. Senão, E com `exact_match = true` chama `undo_last_line()`. O `elif` garante que R e E não rodem no mesmo frame. O `exact_match` faz o E ser ignorado com qualquer modificador pressionado, inclusive o **Shift** (descer): segurando Shift, o E não desfaz.

**Ações que dependem da mira** (cliques):

1. `raycast.force_raycast_update()` recalcula o raio no frame atual. Sem isso, o Player lê o resultado do frame anterior, que pode apontar para um ponto já apagado (`get_collider()` volta `null` e o jogo quebra).
2. Se o raio não acertou nada, os cliques são ignorados.
3. `target` é o `owner` do collider: o raio acerta a `Area3D` interna do ponto, mas o grupo `Iteráveis` fica no nó raiz `Point`.
4. **Clique esquerdo:** só cria ponto se o collider **não** for `Area3D`. Pontos e retas são `Area3D`, então clicar em cima deles não cria ponto novo; chão, Farol e cascas de Lodo são corpos e aceitam o ponto.
5. **Clique direito:** se `target` estiver no grupo `Iteráveis`, chama `remove_point(target)`.

O `RayCast3D` tem `collide_with_areas = true` (para o clique direito achar os pontos) e enxerga as camadas 1 e 2: a 1 é a máscara padrão e a 2 (cascas de Lodo) é ligada no `_ready` do Player. As camadas estão em [CONVENCOES_E_BOAS_PRATICAS.md](CONVENCOES_E_BOAS_PRATICAS.md#física-e-colisões).

## PointSystem

Fica no nó `Head/Vertical/PointSystem` de `player.tscn`, com o script `src/scripts/point_system.gd`.

| Membro | Tipo | Papel |
| --- | --- | --- |
| `POINT_SCENE` | const PackedScene | `point.tscn` |
| `LINE_SCENE` | const PackedScene | `line.tscn` |
| `MIN_LINE_LENGTH` | const float | 0,001 m; abaixo disso não existe reta |
| `sp` | SpawnManager | achado por `$"../../../../SpawnManager"`, que sobe Vertical → Head → Player → raiz da cena |
| `has_a_point` | bool | verdadeiro enquanto há uma reta em andamento |
| `point_a` | Node3D | o ponto A pendente (`null` sem reta em andamento) |
| `point_a_position` | Vector3 | posição global de A |
| `lines` | Array[Dictionary] | retas fechadas, **em ordem de criação** |

Cada item de `lines` guarda a reta, seus dois pontos e o comprimento:

```gdscript
{"line": Node3D, "a": Node3D, "b": Node3D, "length": float}
```

### Funções públicas

**`add_point(point_position)`** — clique esquerdo.

- Sem A pendente: cria o ponto, guarda como A e liga `has_a_point`.
- Com A pendente: calcula o comprimento L entre A e B. Se L ≤ `MIN_LINE_LENGTH` (B em cima de A), ignora o clique e A continua esperando. Senão, cria o ponto B, escreve a medida no label dele (`HUD/LabelGroup/PointLabel`, formato `"%.2fm"`, ex.: `2.35m`), cria a reta no ponto médio M, adiciona o registro ao fim de `lines` e zera o estado de reta em andamento.

**`cancel_line()`** — Q. Se houver A pendente, apaga o ponto e zera `has_a_point` e `point_a`. Sem A, não faz nada.

**`undo_last_line()`** — E. Apaga o último item de `lines`: a reta e os dois pontos. Com a lista vazia, não faz nada. Não mexe no A pendente (para isso existe o Q).

**`clear_lines()`** — R. Chama `cancel_line()`, apaga reta e pontos de todos os itens de `lines` e esvazia a lista.

**`remove_point(point)`** — clique direito.

- Se `point` for o A pendente, equivale a `cancel_line()`.
- Senão, procura em `lines` o registro com esse ponto como A ou B e apaga a reta **e os dois pontos**. Não sobra ponto solto na cena.

**`get_line_lengths()`** — devolve os comprimentos de todas as retas fechadas, em ordem de criação e com precisão completa.

**Sinal `lines_changed(lengths)`** — emitido com `get_line_lengths()` sempre que uma reta é fechada (`add_point`) ou apagada (`undo_last_line`, `remove_point`, `clear_lines`). Cancelar a reta em andamento não emite. A fase liga esse sinal ao HUD, que lista as retas (ver [HUD.md](HUD.md)).

**`get_last_line_length()`** — devolve o comprimento da última reta fechada, em metros (0 se não houver). O label do ponto B não usa esta função (recebe o texto direto em `add_point`); ela fica para quem precisar do valor fora do PointSystem. O comprimento de qualquer reta também está em `lines[i]["length"]`.

### Matemática da reta

Com A = `point_a_position` e B = posição do segundo clique. O comprimento é a distância entre A e B, calculado com `A.distance_to(B)`:

$$
L = \lVert B - A \rVert = \sqrt{(B_x - A_x)^2 + (B_y - A_y)^2 + (B_z - A_z)^2}
$$

O centro da reta é o ponto médio, calculado com `A.lerp(B, 0.5)`:

$$
M = \frac{A + B}{2}
$$

A reta é sempre um segmento reto entre A e B, mesmo em superfície curva. A translação, a rotação e o comprimento da reta estão detalhados, com as matrizes, em [TRANSFORMACOES.md](TRANSFORMACOES.md).

## SpawnManager

Fica na raiz da cena base das fases (`fase_base_farol.tscn`) e dos sandboxes `test_trace_lines.tscn` e `test_answer_menu.tscn`, como instância de `spawn_manager.tscn` com o script `src/scripts/spawn_manager.gd`. Não decide nada: cria e remove o que o PointSystem pedir.

### `spawn_entity(entity, spawn_position, entity_length = null, destiny = null) -> Node3D`

| Parâmetro | Para o ponto | Para a reta |
| --- | --- | --- |
| `entity` | `POINT_SCENE` | `LINE_SCENE` |
| `spawn_position` | posição clicada | ponto médio M |
| `entity_length` | (omitido) | comprimento L |
| `destiny` | (omitido) | ponto B |

1. **`entity.instantiate()`** cria a instância, ainda fora da árvore.
2. **`get_tree().current_scene.add_child(new_entity)`** coloca na raiz da cena atual. Nesse momento o `_ready` da entidade roda.
3. **`global_position = spawn_position`** posiciona. Vem depois do `add_child` porque a posição global depende da árvore.
4. **Só com comprimento e destino:** calcula a direção de M até B. Se ela for quase paralela a `Vector3.UP` (produto escalar em módulo acima de 0,99), usa `Vector3.RIGHT` como "para cima", porque o `look_at` falha com direção paralela ao vetor de referência.
5. **`look_at(destiny, up)`** gira a entidade para que o −Z dela aponte para B.
6. **`set_length(entity_length)`** delega o tamanho para a própria entidade.
7. **Retorna a entidade**, que o PointSystem guarda em `lines`.

### `remove_entity(entity)`

Chama `queue_free()` se a entidade ainda for válida. Quem decide o que apagar é o PointSystem.

## Line e Point

A estrutura de `line.tscn`:

```text
Line (Node3D, line.gd)
└── Area3D
    ├── LineMesh (MeshInstance3D, CylinderMesh, raio 0,02)          rotação X = 90°
    └── LineCollision (CollisionShape3D, CylinderShape3D, raio 0,02)  rotação X = 90°
```

- **Rotação de 90° em X:** o cilindro do Godot é comprido no eixo Y. Girando os filhos, o comprimento fica no Z do nó `Line`, o eixo que o `look_at` aponta.
- **`_ready` duplica malha e shape:** sub-recursos de um `.tscn` são compartilhados entre instâncias. Sem o `duplicate()`, mudar a altura de uma reta mudaria a de todas.
- **`set_length(length)`:** a malha recebe o comprimento inteiro, de centro a centro dos pontos. O colisor recebe `length − 2 × POINT_RADIUS` (mínimo 0,01), para terminar na superfície de cada ponto e não bloquear o clique direito neles.
- **Por que não usar `scale`:** o Jolt não aceita escala não uniforme em cilindros e troca por outra escala, deixando o colisor do tamanho errado.
- **Material:** azul, com o contorno glow do CG-45 (`src/shaders/glow/`). Um passe marca o stencil com a própria reta e outro desenha só o traçado branco em volta, por cima de tudo, então a reta aparece como contorno através de paredes.

A estrutura de `point.tscn`:

```text
Point (Node3D, point.gd, grupo Iteráveis)
├── PointArea (Area3D)
│   ├── PointMesh (MeshInstance3D, SphereMesh, raio 0,05, vermelha)
│   └── PointCollision (CollisionShape3D, SphereShape3D, raio 0,05)
└── HUD (CanvasLayer, camada 1)
    └── LabelGroup (CanvasGroup)
        └── PointLabel (Label, fonte 20, contorno preto de 6, começa sem texto)
```

### Label da medida

A medida da reta aparece acima do ponto B como um `Label` 2D numa `CanvasLayer`, não como `Label3D`. Assim o texto é desenhado **por cima** da geometria próxima (a própria reta, o chão, a esfera) sem precisar de No Depth Test. O texto também fica com tamanho constante na tela, legível a qualquer distância.

Todo frame, `point.gd` faz em `_process`:

1. Pega a câmera ativa (`get_viewport().get_camera_3d()`) e calcula o alvo: posição global do ponto + `LABEL_OFFSET` (0,15 m para cima).
2. **Esconde o label** se o texto estiver vazio (ponto A e pontos sem reta), se não houver câmera ou se o alvo estiver atrás da câmera (`is_position_behind`).
3. **Oclusão:** `_oculto()` lança um raio (`PhysicsRayQueryParameters3D`) da câmera até o alvo com a máscara `OCLUSAO_MASK` = camadas 1 e 2 (mundo e cascas de Lodo). Se acertar algo, tem parede no caminho e o texto vira **só o traçado** (glow): `_set_glow` põe o `glow_text.gdshader` no `LabelGroup`, que apaga o miolo e deixa o contorno, igual à reta e à esfera vistas através das paredes. Áreas (pontos e retas) não entram na checagem, e o Player (camada 3) também não.
4. Mostra o label e o posiciona com `cam.unproject_position(alvo)`, deslocado por `label.size * (0,5; 1)` para ficar centralizado na horizontal e logo acima do ponto.

| Membro | Tipo | Papel |
| --- | --- | --- |
| `LABEL_OFFSET` | const Vector3 | `(0, 0,15, 0)`, altura do texto acima do centro do ponto |
| `OCLUSAO_MASK` | const int | `0b11`, camadas que escondem o label |
| `label` | Label | `$HUD/LabelGroup/PointLabel` |
| `label_group` | CanvasGroup | recebe o material do glow quando o ponto está escondido |

## Tabela de chamadas

| Quem chama | Chamada | Argumentos | Quando |
| --- | --- | --- | --- |
| Player | `ps.cancel_line()` | — | Q |
| Player | `ps.clear_lines()` | — | R |
| Player | `ps.undo_last_line()` | — | E sem modificador |
| Player | `raycast.force_raycast_update()`, `get_collider()` | — | todo frame de física |
| Player | `ps.add_point()` | posição clicada | clique esquerdo em um corpo |
| Player | `ps.remove_point()` | nó `Point` | clique direito em um ponto |
| PointSystem | `sp.spawn_entity()` | `POINT_SCENE`, posição | ponto A ou B |
| PointSystem | `sp.spawn_entity()` | `LINE_SCENE`, M, L, B | segundo clique, se L > 0,001 |
| PointSystem | `point_b.get_node("HUD/LabelGroup/PointLabel").text = ...` | L formatado | segundo clique, depois de criar B |
| PointSystem | `lines_changed.emit()` | comprimentos | reta fechada ou apagada |
| Godot | `Line._ready()` | — | durante o `add_child` da reta |
| Godot | `Point._process()` | — | todo frame, para cada ponto na cena |
| SpawnManager | `new_entity.look_at()` | B, up | só com comprimento e destino |
| SpawnManager | `new_entity.set_length()` | L | só com comprimento e destino |
| PointSystem | `sp.remove_entity()` | reta ou ponto | cancelar, desfazer, apagar todas, remover ponto |

## Pontos de atenção

- **Onde dá para marcar:** o raio acerta o chão e o corpo de colisão `Farol` que vem no `.glb` (camada 1), e as cascas de Lodo dos atos (camada 2, que `farol.gd` aplica nos `StaticBody3D` das cascas). As cascas dos atos inativos ficam com `process_mode` desligado e saem da física.
- **Reta dentro de superfície curva:** uma reta entre dois pontos de um cilindro passa por dentro dele e fica escondida pela malha do Farol; só o contorno glow aparece através da parede.
- **Caminho fixo até o SpawnManager:** `$"../../../../SpawnManager"` exige o Player na raiz da cena e um SpawnManager irmão dele. Os sandboxes `test_player_movement.tscn`, `test_collision_atos.tscn` e `test_sunset_lighting.tscn` não têm SpawnManager: rodando essas cenas, o primeiro clique dá erro. As cenas de ato (`src/scenes/fase_um/`), incluindo a cena principal `ato_1_farol.tscn`, já têm o SpawnManager.
- **Nomes internos da reta:** `line.gd` procura `$Area3D/LineMesh` e `$Area3D/LineCollision`. Renomear esses nós quebra o `_ready`.
- **Raio do ponto repetido:** `POINT_RADIUS` em `line.gd` precisa acompanhar o raio definido em `point.tscn`.
- **`set_length` obrigatório:** qualquer cena passada ao `spawn_entity` com comprimento e destino precisa ter esse método.
- **Troca de ato em runtime não limpa a cena:** mudar o `ato` do Farol com a cena rodando deixa os pontos, as retas e as medidas do ato anterior visíveis. Nas fases isso não acontece, porque cada ato é uma cena própria (ver [ESTRUTURA_DE_FASES.md](ESTRUTURA_DE_FASES.md)).
- **Alcance sem limite:** o `_ready` do Player troca o `target_position` do `RayCast3D` por `(0, 0, −camera.far)`, então o jogador marca pontos em qualquer superfície que a câmera enxerga. O valor de 2 m que está na cena é sobrescrito. Se o `far` da câmera diminuir, o alcance diminui junto.
- **Caminho fixo do label:** `point_system.gd` e `point.gd` procuram `HUD/LabelGroup/PointLabel`. Renomear ou mover esses nós quebra os dois.
- **Máscara de oclusão manual:** `OCLUSAO_MASK` em `point.gd` precisa acompanhar as camadas de física. Se outro cenário sólido ganhar uma camada nova, ela tem que entrar na máscara, senão a medida aparece através dele.
- **Um raio por ponto por frame:** a oclusão custa um `intersect_ray` por ponto visível. Tranquilo para dezenas de pontos; se a cena chegar a centenas, vale checar a cada poucos frames.
- **Física em thread separada:** a consulta de oclusão roda em `_process`, o que funciona com a física na thread principal (padrão). Se "Run on Separate Thread" for ligado nas configurações de física, mover a checagem para `_physics_process`.
- **Formato da medida:** o rótulo do ponto usa ponto decimal (`5.52m`), e o HUD usa vírgula (`5,52 m`). O menu de chute aceita os dois.
