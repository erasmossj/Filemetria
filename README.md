# Filemetria

Projeto da disciplina de Computação Gráfica, período 2026.2, ministrada pelo professor Marcelo Costa no Instituto de Computação da Universidade Federal de Alagoas (IC/UFAL).

## Sobre o jogo

*Filemetria* é um jogo 3D ambientado em Alagoas, no qual o jogador restaura monumentos tomados pelo **Lodo do Esquecimento**, uma matéria escura que simboliza o apagamento da memória cultural. Para isso, ele mede os monumentos, estima a área afetada e calcula quanto de renda filé será necessário para cobri-la. A proposta une patrimônio cultural alagoano, geometria e Computação Gráfica.

A primeira fase é o **Farol da Ponta Verde**, em três atos, com **10 minutos compartilhados pela fase inteira**. Em cada ato o jogador traça retas sobre o Lodo, anota os comprimentos e chuta a área total antes que o tempo acabe. Efeitos sonoros acompanham as interações e respostas válidas; um alerta toca uma única vez por tentativa ao entrar nos 30 segundos finais.

### Objetivo da modelagem

Desenvolver modelos 3D, em estilo low-poly, de monumentos e elementos culturais de Alagoas para compor as fases do jogo, permitindo a interação e a realização de medições diretamente sobre suas superfícies, que servirão de base para as mecânicas de cálculo e estimativa de áreas.

## Equipe

- Victor André Lopes Brasileiro     | 202407269
- José Riquelme Teixeira da Silva   | 202407400
- Erasmo da Silva Sá Júnior         | 202407358

## Engine

[Godot Engine](https://godotengine.org/) 4.7, renderer Forward+ e física Jolt.

## Como rodar

1. Abrir a pasta do projeto no Godot 4.7 (Import → `project.godot`). Na primeira abertura o editor importa os recursos.
2. Apertar F5. A cena principal é o Ato 1 (`src/scenes/fase_um/ato_1_farol.tscn`).

## Controles

| Tecla | Ação |
| --- | --- |
| W A S D / setas | Andar |
| Mouse | Olhar |
| Espaço / Shift | Subir / descer |
| Clique esquerdo | Marcar ponto (dois pontos fecham uma reta) |
| Clique direito | Apagar o ponto mirado |
| Q / E / R | Cancelar a reta / desfazer a última / apagar todas |
| Tab | Menu de chute da área |
| F1 (segurar) | Painel de controles |
| Esc | Liberar o cursor e pausar o tempo |

Detalhes em [`CONTROLES.md`](docs/CONTROLES.md).

## Documentação

A documentação do projeto está na pasta [`docs/`](docs).

**Projeto e convenções**

- [`ARQUITETURA.md`](docs/ARQUITETURA.md) — estrutura de pastas, Git e export.
- [`CONVENCOES_E_BOAS_PRATICAS.md`](docs/CONVENCOES_E_BOAS_PRATICAS.md) — convenções de código, cenas, camadas de física, commits e branches.

**Jogo**

- [`ESTRUTURA_DE_FASES.md`](docs/ESTRUTURA_DE_FASES.md) — uma cena por ato, gabarito das áreas, menu de chute, respostas inválidas, telas de resultado e cronômetro.
- [`SISTEMA_DE_PONTOS.md`](docs/SISTEMA_DE_PONTOS.md) — como o PointSystem e o SpawnManager criam, ligam e apagam pontos e retas.
- [`HUD.md`](docs/HUD.md) — elementos do HUD da fase, menu de chute e aviso de resposta inválida, de onde vêm os dados e camadas de desenho.
- [`EFEITOS_SONOROS.md`](docs/EFEITOS_SONOROS.md) — eventos de gameplay, SFXManager, bus SFX, alerta único entre atos e roteiro de teste (CG-25).
- [`CONTROLES.md`](docs/CONTROLES.md) — ações do Input Map e onde cada uma é lida.
- [`TRANSFORMACOES.md`](docs/TRANSFORMACOES.md) — translação, rotação e escala no código, com as matrizes (requisito AB1, CG-22).

**Cenário e arte**

- [`PROPORCOES_FAROL.md`](docs/PROPORCOES_FAROL.md) — medidas de referência e medidas do modelo do Farol.
- [`ILUMINACAO.md`](docs/ILUMINACAO.md) — iluminação de fim de tarde e ambiente.

**Créditos e licenças**

- [`CREDITOS.md`](docs/CREDITOS.md) — lista única para os créditos do jogo e o relatório, com as atribuições obrigatórias.
- [`ICON_SOURCES.md`](docs/ICON_SOURCES.md), [`FONT_SOURCES.md`](docs/FONT_SOURCES.md), [`MATERIAL_SOURCES.md`](docs/MATERIAL_SOURCES.md), [`AUDIO_SOURCES.md`](docs/AUDIO_SOURCES.md), [`CREDITS_MUSIC.md`](docs/CREDITS_MUSIC.md) — origem e licença de cada asset.
