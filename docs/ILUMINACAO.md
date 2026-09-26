# Iluminação de fim de tarde (CG-13)

Cena reutilizável: `src/entities/environment/sunset_lighting/sunset_lighting.tscn` (`WorldEnvironment` + `DirectionalLight3D` "Sun"). Basta instanciar na fase. Sandbox de validação: `src/scenes/sandbox/test_sunset_lighting.tscn`.

> As sombras daqui são só iluminação. Elas se movem com o sol e não têm área calculável; **nunca** usar como alvo de medição. O que o jogador mede é o Lodo do Esquecimento (geometria com material próprio, CG-16).

## Sol (`DirectionalLight3D`)

| Parâmetro | Valor | Motivo |
|---|---|---|
| Elevação / direção | 20° acima do horizonte, vindo de -X/-Z | Sol baixo de fim de tarde, com sombras longas que marcam os volumes |
| `light_color` | `(1, 0.76, 0.54)` | Tom quente sem saturar os materiais |
| `light_energy` | `1.0` | Com 1.3, as faces brancas do farol estouravam |
| `shadow_bias` / `shadow_normal_bias` | `0.04` / `1.5` | Sem acne na luz rasante e sem peter-panning visível |
| `directional_shadow_mode` | PSSM 4 splits, `blend_splits` ativo | Tira a costura/cintilação entre cascatas quando a câmera anda |
| `directional_shadow_max_distance` | `120` | Cobre a área jogável sem perder resolução perto do jogador |

## Ambiente (`WorldEnvironment`, CG-12)

- Céu procedural quente no horizonte. `ground_bottom_color` fica **claro de propósito** (`0.36, 0.31, 0.27`). Com ele escuro, as faces verticais de materiais escuros e lisos refletiam preto e perdiam o contorno.
- Luz ambiente do céu (`sky_contribution 0.7`) misturada com um azul frio, energia `1.25`: as áreas em sombra ficam frias e legíveis, nunca pretas.

| Parâmetro | Valor | Motivo |
|---|---|---|
| Tonemap | ACES, `exposure 0.9`, `white 6.0` | Com Filmic 1.0 as faces brancas do farol estouravam (~0,8% da tela em branco puro) e a cena ficava lavada. ACES dá mais contraste e segura os altos; a exposição menor compensa o ganho de contraste dele |
| SSAO | `radius 3`, `intensity 3`, `power 1.5`, `light_affect 0.2` | Escurece o contato dos blocos e do farol com o chão (o farol tem ~49 m, então um raio pequeno some). `light_affect` baixo deixa o AO aparecer também no lado iluminado sem sujar as faces |
| Névoa | Exponencial, `density 0.002`, `sky_affect 0` | Só uma leve névoa de distância para separar os planos. Não custa nada de fps (medido) e não toca o céu; a 60 m ela cobre ~11% da cor |

Resultado no sandbox: nenhum pixel estourado nas três vistas de teste (antes, até 0,84%) e nenhuma área preta nova além do contorno dos proxies de Lodo.

### Renderer

O SSAO **só existe no Forward+**, então o projeto passou a usar `forward_plus` no desktop (`rendering_method.mobile` continua `mobile`, e nele o AO é ignorado). A qualidade do SSAO fica em **Very Low** (`rendering/environment/ssao/quality=0`), porque na GPU integrada de referência (Intel, 1280×720) as medições foram:

| Configuração | fps |
|---|---|
| Mobile (antes) | ~380 |
| Forward+ sem SSAO | ~265 |
| Forward+ SSAO Medium (padrão) | ~95 |
| Forward+ SSAO Very Low | ~145 |

Se o desempenho apertar numa fase, o SSAO é o primeiro a desligar. A névoa pode ficar.

## Lodo do Esquecimento

Validado com três proxies (albedo `0.07`, roughness `0.2`) no sandbox, ao sol, na sombra do farol e contra a luz: o contorno de todas as regiões continua legível. Quando o material real do CG-16 entrar, trocar os proxies pelas cascas e repetir a checagem. Se alguma região virar borrão, subir primeiro o albedo do material (evitar abaixo de ~0.05) antes de mexer nesta luz.
