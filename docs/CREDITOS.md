# Créditos

Lista única de autoria e licenças, para a tela de créditos do jogo e o relatório de entrega (CG-29). O detalhe de cada asset fica no arquivo de fontes da categoria, linkado em cada linha.

## Equipe

Projeto da disciplina de Computação Gráfica (2026.2, prof. Marcelo Costa), IC/UFAL.

- Victor André Lopes Brasileiro
- José Riquelme Teixeira da Silva
- Erasmo da Silva Sá Júnior

## Atribuições obrigatórias

Estes assets usam licenças que **exigem** atribuição. O texto abaixo precisa aparecer nos créditos do jogo e no relatório:

> Padrões de renda filé do HUD: **Hero Patterns**, de Steve Schoger (https://heropatterns.com), licença CC BY 4.0. Cor alterada para branco.

## Engine

| Item | Autor | Licença |
| --- | --- | --- |
| [Godot Engine](https://godotengine.org) 4.7 | Juan Linietsky, Ariel Manzur e contribuidores | MIT |
| Jolt Physics (motor de física usado pelo projeto, embutido no Godot) | Jorrit Rouwe e contribuidores | MIT |

## Assets de terceiros

| Categoria | Assets | Autor | Licença | Detalhe |
| --- | --- | --- | --- | --- |
| Ícones | target, ruler, calculator, keyboard, move, mouse-pointer-click, mouse, circle-alert, circle-check, rotate-ccw, undo-2 | Lucide Contributors | ISC | [ICON_SOURCES.md](ICON_SOURCES.md) |
| Padrões de filé | Lisbon, Formal Invitation, Graph Paper | Steve Schoger (Hero Patterns) | CC BY 4.0 | [ICON_SOURCES.md](ICON_SOURCES.md) |
| Mira | `CrossHair.svg` | SVG Repo | Open License | [ICON_SOURCES.md](ICON_SOURCES.md#mira) |
| Fontes | Bebas Neue | Dharma Type | SIL OFL 1.1 | [FONT_SOURCES.md](FONT_SOURCES.md) |
| Fontes | Barlow | The Barlow Project Authors | SIL OFL 1.1 | [FONT_SOURCES.md](FONT_SOURCES.md) |
| Materiais | Plaster003, Rock022, Metal041A, Metal041B, Wood060, Ground054 | ambientCG | CC0 1.0 | [MATERIAL_SOURCES.md](MATERIAL_SOURCES.md) |
| Som ambiente | Sea Wave | metaepitome / Freesound (via Pixabay) | Pixabay Content License | [AUDIO_SOURCES.md](AUDIO_SOURCES.md) |
| Som ambiente | Smooth Cold Wind - Looped | Shut_Up_Ghost (via Pixabay) | Pixabay Content License | [AUDIO_SOURCES.md](AUDIO_SOURCES.md) |
| Música | Tema da Fase 1 | Gerada pela equipe com o Gemini (Lyria) | Termos do Google | [CREDITS_MUSIC.md](CREDITS_MUSIC.md) |

## Feito pela equipe

- Modelo 3D do Farol da Ponta Verde e cascas de Lodo (`assets/models/modelo_farol/`).
- Shaders de glow da reta, do ponto e do rótulo (`src/shaders/glow/`).
- Programação, cenas e interface.

## Fora do build

As fotos de `assets/refs/` são só referência para a modelagem e **nenhuma cena usa**. Algumas são de terceiros, com marca d'água ou crédito de fotógrafo, então não podem ir no executável nem em material público. Ver [ARQUITETURA.md](ARQUITETURA.md#export) para excluí-las do export.
