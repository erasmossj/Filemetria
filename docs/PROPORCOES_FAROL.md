# Proporções: Farol da Ponta Verde

## Medidas de referência

- Altura da torre: **11 m**
- Altitude do plano focal: **13 m**

## Proporções estimadas para modelagem

- Diâmetro do corpo: **2,2–2,4 m**
- Diâmetro da plataforma superior: **3,1–3,4 m**
- Altura do corpo até o conjunto superior: **7,6–8,0 m**
- Diâmetro do volume vermelho no topo: **1,4–1,7 m**
- Altura do volume vermelho no topo: **~0,6 m**
- Porta:
  - largura: **0,8–1,0 m**
  - altura: **2,0–2,2 m**
- Pedestal de concreto:
  - largura no topo: **2,3–2,6 m**
  - largura na base: **3,5–4,0 m**

> As dimensões além da altura oficial de 11 m são estimativas obtidas a partir das referências fotográficas.

## Medidas do modelo no jogo

Medidas das caixas das malhas de `farol_ponta_verde_oficial.glb` dentro de `farol.tscn` (1 unidade = 1 metro, base do Farol em y = 0), tiradas no Godot 4.7. **O gabarito das áreas usa o modelo, não as estimativas acima** (ver [ESTRUTURA_DE_FASES.md](ESTRUTURA_DE_FASES.md#gabarito)).

| Parte | Malha no `.glb` | Medida | Altura (y) |
| --- | --- | --- | --- |
| Altura total | — | **11,00 m** | 0 → 11,00 |
| Pedestal de concreto | `Base_concreto_001` | largura na base 2,62 m, altura 2,53 m | 0,03 → 2,56 |
| Corpo | `Corpo_Farol` | diâmetro 1,59 m, altura 5,52 m | 2,56 → 8,08 |
| Plataforma superior | `Cilindro` | diâmetro 2,49 m, altura 0,83 m | 8,05 → 8,88 |
| Volume vermelho do topo | `Cilindro_001` | diâmetro 1,38 m, altura 1,24 m | 8,19 → 9,43 |
| Lanterna | `Cilindro_006` a `Cilindro_011` | diâmetro ~0,55 m | 9,56 → 9,88 |
| Blocos de concreto em volta | `Base_Concreto` e cópias | altura 3,02 m | 0,02 → 3,04 |

A altura total bate com a oficial. O diâmetro do corpo e o da plataforma ficaram menores que as estimativas (1,59 m contra 2,2–2,4 m, e 2,49 m contra 3,1–3,4 m). A altura do corpo até o conjunto superior, contada do chão, fica logo acima da faixa estimada (8,08 m contra 7,6–8,0 m).
