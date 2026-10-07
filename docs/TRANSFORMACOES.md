# Transformações gráficas (CG-22)

O requisito AB1 pede "aplicar transformações". Este documento junta, para o relatório (CG-29) e o vídeo (CG-28), onde o código aplica translação, rotação e escala hoje, com o trecho correspondente e a matemática.

## Situação dos critérios do CG-22

| Critério | Situação no código | Onde |
| --- | --- | --- |
| **Rotação:** feixe do farol gira continuamente | **Não implementado.** O Farol não tem feixe nem nó girando | — |
| **Escala:** retas escaladas conforme a distância entre os pontos | **Parcial.** O comprimento da reta é definido uma vez, ao fechar a reta, mudando a altura da malha (`CylinderMesh.height`), e não a escala do `Transform3D` | `line.gd`, `set_length()` |
| **Translação + rotação:** reta no ponto médio, girada para A→B | **Implementado** | `spawn_manager.gd`, `spawn_entity()` |
| Transformações identificadas no relatório | Este documento | — |
| Visíveis no vídeo | Roteiro no fim deste documento | — |

Além da reta, o jogo já aplica rotação contínua na câmera (mouse), escala uniforme na mira e uma transformação de projeção nos rótulos das medidas. Elas também servem de exemplo no relatório (seção 3).

## 1. Base: o `Transform3D` do Godot

Cada `Node3D` tem um `Transform3D`: uma base 3×3 (rotação e escala) e uma origem (translação). Em coordenadas homogêneas, um ponto local $p$ vai para o mundo por

$$
p_{\text{mundo}} = T \cdot R \cdot S \cdot p
$$

com $T$ a translação, $R$ a rotação e $S$ a escala. O Godot guarda $R \cdot S$ na `basis` e $T$ na `origin`, e compõe a transformação de cada nó com a do pai: $M_{\text{mundo}} = M_{\text{pai}} \cdot M_{\text{local}}$.

## 2. A reta: translação, rotação e "escala"

Quando o jogador fecha uma reta entre A e B, o `PointSystem` calcula o comprimento e o ponto médio e pede a reta ao `SpawnManager`.

`src/scripts/point_system.gd` (`add_point`):

```gdscript
var length := point_a_position.distance_to(point_position)
# ...
var midpoint := point_a_position.lerp(point_position, 0.5)
var line: Node3D = sp.spawn_entity(LINE_SCENE, midpoint, length, point_position)
```

`src/scripts/spawn_manager.gd` (`spawn_entity`):

```gdscript
new_entity.global_position = spawn_position

if entity_length != null and destiny != null:
	## Retas verticais: o "para cima" padrão não serve, troca por outro eixo.
	var direction: Vector3 = (destiny - spawn_position).normalized()
	var up := Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.RIGHT

	## −Z do nó passa a apontar para o destino.
	new_entity.look_at(destiny, up)

	## A própria reta ajusta o comprimento da malha e do colisor.
	new_entity.set_length(entity_length)
```

`src/entities/statics/Line/line.gd` (`set_length`):

```gdscript
func set_length(length: float) -> void:
	## A malha vai de centro a centro dos pontos.
	mesh_instance.mesh.height = length
	## O colisor desconta um raio de ponto em cada ponta, para não cobrir os pontos.
	collision.shape.height = max(length - 2.0 * POINT_RADIUS, 0.01)
```

### Translação

`global_position = spawn_position` coloca a origem do nó `Line` no ponto médio:

$$
M = \frac{A + B}{2} = A + 0{,}5\,(B - A),
\qquad
T(M) =
\begin{bmatrix}
1 & 0 & 0 & M_x \\
0 & 1 & 0 & M_y \\
0 & 0 & 1 & M_z \\
0 & 0 & 0 & 1
\end{bmatrix}
$$

`lerp(b, 0.5)` é exatamente a interpolação $A + 0{,}5\,(B - A)$.

### Rotação

`look_at(destiny, up)` monta uma base ortonormal em que o −Z do nó aponta de M para B:

$$
z = -\frac{B - M}{\lVert B - M \rVert},\quad
x = \frac{\text{up} \times z}{\lVert \text{up} \times z \rVert},\quad
y = z \times x,
\qquad
R = \begin{bmatrix} x & y & z \end{bmatrix}
$$

Se a direção for quase paralela ao `up` ($|\hat{d} \cdot \text{up}| > 0{,}99$, reta quase vertical), o produto vetorial tende a zero e a base fica indefinida. Por isso o código troca o `up` por `Vector3.RIGHT` nesse caso.

A reta também usa uma **rotação fixa na cena**: em `line.tscn`, a malha e o colisor são filhos girados 90° em X, porque o cilindro do Godot é comprido no eixo Y. Composta com a rotação do `look_at`, ela deixa o comprimento do cilindro no Z do nó `Line`:

$$
M_{\text{malha}} = T(M)\; R_{\text{look\_at}}\; R_x(90°)
$$

### Comprimento (no lugar da escala)

O comprimento é aplicado mudando a **geometria**: `mesh.height = L`, com

$$
L = \lVert B - A \rVert = \sqrt{(B_x - A_x)^2 + (B_y - A_y)^2 + (B_z - A_z)^2}
$$

Na tela o resultado é o mesmo de uma escala no eixo do cilindro, $S = \operatorname{diag}(1, L/h_0, 1)$, mas não passa pelo `Transform3D`: a `basis` da reta continua só com rotação. Por isso o `_ready` de `line.gd` duplica a malha e o shape (sem isso, mudar a altura de uma reta mudaria todas).

O código não usa `scale` por causa do colisor: o Jolt não aceita escala não uniforme em cilindros (ver [SISTEMA_DE_PONTOS.md](SISTEMA_DE_PONTOS.md#line-e-point)). Para o critério de escala do CG-22, falta decidir se:

- a escala vira uma transformação de verdade só na malha visível (`LineMesh.scale`), com o colisor continuando pela altura do shape; e
- ela passa a ser **dinâmica**, por exemplo com uma prévia que estica de A até a mira antes do segundo clique. Hoje a reta só existe depois do segundo clique, com o tamanho final.

## 3. Outras transformações já presentes

### Rotação da câmera pelo mouse

`src/entities/player/player.gd` (`_input`):

```gdscript
rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
cam_ver -= deg_to_rad(event.relative.y * MOUSE_SENSITIVITY)
cam_ver = clamp(cam_ver, deg_to_rad(LIMIT_DOWN), deg_to_rad(LIMIT_UP))
$Head/Vertical.rotation.x = cam_ver
```

- O movimento horizontal do mouse **acumula** uma rotação em Y no corpo do Player: $B_{n+1} = R_y(\Delta\theta)\,B_n$, com $\Delta\theta$ proporcional ao deslocamento do mouse.
- O movimento vertical é **absoluto e limitado**: o ângulo `cam_ver` fica entre −80° e 80° e é escrito direto na rotação X do nó `Head/Vertical`.
- A câmera, filha de `Head/Vertical`, herda as duas rotações: $M_{\text{câmera}} = M_{\text{Player}}\;R_y\;\cdot\;T_{\text{Head}}\;R_x(\text{cam\_ver})\;\cdots$

$$
R_y(\theta) =
\begin{bmatrix}
\cos\theta & 0 & \sin\theta \\
0 & 1 & 0 \\
-\sin\theta & 0 & \cos\theta
\end{bmatrix},
\qquad
R_x(\varphi) =
\begin{bmatrix}
1 & 0 & 0 \\
0 & \cos\varphi & -\sin\varphi \\
0 & \sin\varphi & \cos\varphi
\end{bmatrix}
$$

### Translação do Player

O movimento usa a base do próprio Player para converter o input local em direção no mundo, e o `move_and_slide()` aplica a translação com colisão:

```gdscript
var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
```

$p_{n+1} = p_n + v\,\Delta t$, com $v$ = `direction × SPEED` no plano e ±`FLY_VELOCITY` em Y.

### Escala uniforme da mira

Em `player.tscn`, o nó `Aim` (filho da câmera, pai do `Sprite3D` da mira) tem `Transform3D(0.001, 0, 0, 0, 0.001, 0, 0, 0, 0.001, 0, 0, -0.1)`: escala uniforme $S = 0{,}001\,I$ e translação de 0,1 m para a frente da câmera. É uma escala de verdade no `Transform3D`, mas fixa.

### Projeção dos rótulos das medidas

`src/entities/statics/Point/point.gd` (`_process`):

```gdscript
label.position = cam.unproject_position(alvo) - label.size * Vector2(0.5, 1.0)
```

`unproject_position` aplica a transformação de visão e a projeção perspectiva da câmera ao ponto 3D e devolve a posição em pixels:

$$
p_{\text{clip}} = P \cdot V \cdot p_{\text{mundo}},
\qquad
p_{\text{tela}} = \left(\frac{x_{\text{clip}}/w + 1}{2}\,W,\; \frac{1 - y_{\text{clip}}/w}{2}\,H\right)
$$

## Onde ver no jogo (roteiro para o vídeo, CG-28)

1. **Rotação da câmera:** girar o mouse; olhar para cima e para baixo até o limite de 80°.
2. **Translação + rotação da reta:** marcar A e B em direções diferentes (no chão, depois subindo com Espaço e marcando no corpo do Farol). Cada reta nasce centrada entre os pontos e alinhada com A→B.
3. **Caso vertical:** uma reta de baixo para cima no corpo do Farol mostra a troca do `up`.
4. **Comprimento:** retas de tamanhos diferentes, com a medida no rótulo do ponto B e no cartão "Retas" do HUD.
5. **Projeção:** andar em volta de uma reta; o rótulo acompanha o ponto na tela e vira só contorno atrás de paredes.

O feixe giratório do farol não existe ainda, então não entra no roteiro.
