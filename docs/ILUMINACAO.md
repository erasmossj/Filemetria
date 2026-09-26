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

## Ambiente (`WorldEnvironment`)

- Céu procedural quente no horizonte. `ground_bottom_color` fica **claro de propósito** (`0.36, 0.31, 0.27`). Com ele escuro, as faces verticais de materiais escuros e lisos refletiam preto e perdiam o contorno.
- Luz ambiente do céu (`sky_contribution 0.7`) misturada com um azul frio, energia `1.25`: as áreas em sombra ficam frias e legíveis, nunca pretas.
- Tonemap Filmic, exposição `1.0`.

## Lodo do Esquecimento

Validado com três proxies (albedo `0.07`, roughness `0.2`) no sandbox, ao sol, na sombra do farol e contra a luz: o contorno de todas as regiões continua legível. Quando o material real do CG-16 entrar, trocar os proxies pelas cascas e repetir a checagem. Se alguma região virar borrão, subir primeiro o albedo do material (evitar abaixo de ~0.05) antes de mexer nesta luz.
