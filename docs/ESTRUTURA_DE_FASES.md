# Estrutura de fases — uma cena por ato

Cada ato da fase do Farol é uma cena própria em `src/scenes/fase_um/`. Acertar a área carrega a cena do próximo ato. Errar feio (erro grosseiro do AnswerMenu) volta para o Ato 1.

```
src/scenes/fase_um/
├── fase_farol.gd          # script da raiz: exports do ato e troca de cena
├── fase_base_farol.tscn   # luz, chão, Farol, Player, SpawnManager, AnswerMenu, ResultScreen, Hud e sons
├── ato_1_farol.tscn       # herdada da base: ato = 1, próxima = ato_2 (cena principal do projeto)
├── ato_2_farol.tscn       # herdada da base: ato = 2, próxima = ato_3
└── ato_3_farol.tscn       # herdada da base: ato = 3, sem próxima (conclui a fase)
```

Qualquer mudança comum aos atos (iluminação, posição do player, chão) é feita **só na `fase_base_farol.tscn`**. As cenas de ato mudam apenas os exports da raiz.

## Exports da raiz (`fase_farol.gd`)

| Export | Tipo | Papel |
| --- | --- | --- |
| `ato` | int (1 a 3) | Repassado para `Farol.ato`. O Lodo de cada ato está dentro do `.glb` do Farol, e o Farol liga só o do ato ativo |
| `gabarito` | float | Área da casca de Lodo do ato em m². Repassado para `AnswerMenu.correct_ans` |
| `proxima_fase` | caminho `.tscn` | Cena carregada no acerto. Vazio: emite `fase_concluida` |
| `primeiro_ato` | caminho `.tscn` | Cena carregada no erro grosseiro e no tempo esgotado. Padrão: `ato_1_farol.tscn` |
| `tempo_total` | float (segundos) | Tempo da fase somando os 3 atos. Padrão: 300 (5 minutos). Só o Ato 1 lê esse valor, ao zerar o cronômetro |
| `objetivo` | texto | Objetivo do ato em uma frase, exibido no HUD (CG-38) |

Os caminhos usam `@export_file` (texto) e não `PackedScene`. Um export `PackedScene` carrega a cena apontada junto, e uma cadeia que volta para o início (ato 3 → menu → ato 1) viraria referência circular.

Os valores ficam como **UID** (`uid://...`), não como `res://`. O Godot não reescreve texto de export quando uma pasta ou cena é renomeada: com `res://`, renomear a pasta quebra a troca de ato com `Cannot open file`. Selecionar a cena pelo botão de pasta do inspetor grava o UID automaticamente.

## Gabarito

Áreas calculadas a partir dos vértices das cascas `Lodo_Ato1/2/3` em `farol_ponta_verde_oficial.glb` (1 unidade = 1 metro, sem escala no Farol).

| Ato | Casca | Dimensões | Fórmula | Gabarito (m²) |
| --- | --- | --- | --- | --- |
| 1 | Face da pedra da base | Trapézio: base maior 2,6238, base menor 1,7317, altura 3,0272 | (B + b) / 2 × h | **6,59** |
| 2 | Corpo inteiro do farol | Cilindro: diâmetro 1,5972, altura 5,5238 | 2πrh | **27,72** |
| 3 | Metade do corpo + ¼ na metade de cima | O mesmo cilindro do Ato 2 | ½ × 2πrh + ¼ × ½ × 2πrh | **17,32** |

- **Ato 1 é um trapézio, não um retângulo.** A face da pedra afunila para cima e é levemente inclinada. A altura 3,0272 é a distância entre as duas bases medida ao longo da face. A aresta lateral mede 3,0598, e quem multiplicar a base maior pela lateral chega a cerca de 8,03 m², 22% acima do gabarito.
- **Cilindro facetado:** a casca do Ato 2 tem 32 lados, e a área real da malha é 27,67 m², 0,16% abaixo de 2πrh. O gabarito usa a fórmula, que é a conta que o jogador faz, e a diferença fica muito abaixo da margem de acerto.
- **Ato 3:** os setores de 0° a 90° e de 270° a 360° cobrem a altura inteira (metade do cilindro). O setor de 180° a 270° cobre só a metade de cima. O total é 5/8 da área do Ato 2.

### Faixas de resposta

Com as margens padrão do AnswerMenu (`hit_margin = 0.10`, `fail_margin = 1.0`):

| Ato | Acerto (±10%) | Erro grosseiro (abaixo da metade ou acima do dobro) |
| --- | --- | --- |
| 1 | 5,93 a 7,25 | < 3,30 ou > 13,18 |
| 2 | 24,95 a 30,49 | < 13,86 ou > 55,44 |
| 3 | 15,59 a 19,05 | < 8,66 ou > 34,64 |

Qualquer outro valor é "Tente novamente!". O erro grosseiro compara pela razão entre chute e gabarito, e não pelo erro relativo comum: este nunca passa de 100% para chutes abaixo do gabarito, então só chutes altos seriam grosseiros.

O campo não aceita sinal de menos, então não há chute negativo. O chute **0** é sempre erro grosseiro, porque a razão até o gabarito é infinita. Ele só seria acerto com `hit_margin = 1.0`, já que o erro relativo de zero é 100%. Campo vazio ou só com o separador (`,` ou `.`) não é enviado e não conta como erro: o menu continua aberto, com o texto e o foco no campo. Um chute válido limpa o campo e fecha o menu.

## Fluxo dos sinais do AnswerMenu

| Sinal | Tela de resultado | O que a fase faz depois |
| --- | --- | --- |
| `answer_correct` | "Correto!" / "Você conseguiu recuperar a área com sucesso!" (verde) | `change_scene_to_file(proxima_fase)`, ou emite `fase_concluida` se for o último ato |
| `answer_retry` | "Tente novamente!" (vermelho) | Nada: o jogador tenta de novo no mesmo ato |
| `answer_failed` | "Tente novamente..." / "Dessa vez do começo... Ok?" (vermelho) | `change_scene_to_file(primeiro_ato)`: reinicia a fase do Ato 1 |
| `answer_invalid` | Nenhuma por enquanto (aviso previsto na CG-47) | Nada: o menu continua aberto. Emitido quando o envio está vazio ou só com o separador |
| `Cronometro.tempo_esgotado` | "Tempo esgotado!" / "Dessa vez do começo... Ok?" (vermelho) | `change_scene_to_file(primeiro_ato)`: reinicia a fase do Ato 1 |

O menu de chute abre com o Tab ou com o botão "Calcular área" do HUD; os dois chamam `AnswerMenu.toggle_menu()` (o botão passa pela fase, que ignora o clique depois de `_travar_jogo()`).

A tela de resultado é `src/ui/ResultScreen/result_screen.tscn`: fundo cinza transparente (o mesmo do AnswerMenu) numa `CanvasLayer` de camada 4, acima do HUD, do menu e das medidas (ver [HUD.md](HUD.md#camadas-de-desenho)). Fica visível por `duracao` segundos (2,5 por padrão) e some sozinha. Os textos ficam em constantes no topo de `result_screen.gd`.

No acerto, no erro grosseiro e no tempo esgotado, a troca de cena só acontece depois que a tela some. Nesse intervalo a fase trava o Player (`input_locked`), desliga o AnswerMenu e pausa o cronômetro, para o jogador não andar, marcar pontos nem responder de novo, e para o tempo não esgotar no meio de uma troca já decidida. No acerto do último ato não há troca de cena: só o cronômetro para.

## Cronômetro (CG-37)

O tempo corre direto pelos 3 atos. Como cada ato é uma cena própria, o tempo restante fica no autoload `Cronometro` (`src/scripts/cronometro.gd`), que sobrevive ao `change_scene_to_file`.

- **Ato 1** chama `Cronometro.iniciar(tempo_total)`: zera a contagem. Toda derrota volta para o Ato 1, então reiniciar a fase sempre reinicia o tempo.
- **Atos 2 e 3** chamam `Cronometro.continuar()`, que retoma de onde o ato anterior pausou. Se a cena de um desses atos for aberta direto pelo editor, o cronômetro está zerado e é iniciado com o `tempo_total` daquela cena.
- **Tempo esgotado:** o autoload emite `tempo_esgotado` e a fase mostra a tela "Tempo esgotado!" antes de voltar ao Ato 1.
- **Pausa com ESC:** o ESC (ação `pause`) libera o cursor e faz o Player emitir `pause_toggled(paused)`; a fase pausa o cronômetro ou o retoma de onde parou. Abrir e fechar o menu de resposta durante a pausa recaptura o cursor, então fechar o menu também encerra a pausa e o tempo volta a correr.
- **Cronômetro encerrado:** depois de uma troca de cena já decidida ou do acerto do último ato, sair da pausa não retoma o tempo.

O tempo aparece na lanterna do HUD (`src/ui/Hud/hud.tscn`, ver [HUD.md](HUD.md)), em `mm:ss` e com um anel de tempo restante. O tempo é arredondado para cima, então a contagem começa em 05:00 e só mostra 00:00 quando acaba. `Cronometro.iniciar()` também grava `tempo_total`, que o anel usa como volta inteira.

## Por que uma cena por ato

- **Limpeza de graça:** trocar de cena destrói pontos, retas e labels do ato anterior. Não é preciso chamar `clear_lines()` nem resetar o Player.
- **Reinício limpo:** voltar ao Ato 1 recria tudo do zero.
- **Configuração no inspetor:** um ato novo é uma cena herdada com outros valores nos exports, sem código duplicado.

O CG-36 pedia a troca de ato "sem recarregar a cena". A troca de cena foi escolhida por ser mais simples e evitar estado residual entre atos.

## Pontos de atenção

- **Estado entre atos:** `change_scene_to_file` destrói tudo. Pontuação ou tentativas acumuladas entre atos precisam de um autoload em `src/scripts/`, como o `Cronometro` já faz com o tempo.
- **Chão com o topo em y = 0:** o `Ground` da base é um `CSGBox3D` de 1 m de altura, deslocado para y = −0,5. O Farol foi modelado com a base em y = 0. Com a caixa centrada na origem, o topo ficava em y = 0,5 e enterrava os 0,48 m de baixo do Lodo do Ato 1: a área visível caía para 5,37 m² e o gabarito de 6,59 m² não batia. Os pés do Player também ficam em y = 0.
- **Textura do chão:** o `Ground` usa `assets/textures/areia/areia.tres` (triplanar em coordenadas de mundo, então o tamanho da caixa não estica a textura).
- **Faixa vermelha da base escondida sob o Lodo:** o anel `FaixasVermelhas/FaixaBase` (raio 0,8009) fica por fora da casca de Lodo dos Atos 2 e 3, que nessa altura está só 4,5 mm para fora do corpo. Ele apareceria por cima do Lodo, então `farol.gd` esconde a faixa no Ato 2 e, no Ato 3, liga o `RecorteLodoAto3`, que tira a metade x > 0 (a parte coberta pelo Lodo). As outras três faixas e a pedra do Ato 1 ficam por baixo das cascas. Se a casca ou a faixa mudarem, rever essa regra.
- **Gabarito acompanha o modelo:** se a casca de Lodo mudar no Blender, o `gabarito` do ato precisa ser recalculado.
- **Reinício recarrega a cena:** o CG-37 pede que o reinício não recarregue a cena inteira. Ele segue a decisão do CG-36 e troca de cena para o Ato 1, que zera cronômetro, retas, medidas e Lodo de uma vez.
- **Pausa só do tempo:** o ESC para o cronômetro, mas não o jogo. Com o cursor liberado, o Player ainda anda e marca pontos com clique, então dá para medir com o tempo parado.
- **Nós com nome fixo:** `fase_farol.gd` procura `$Farol`, `$Player`, `$AnswerMenu`, `$ResultScreen` e `$Hud` na raiz. Renomear esses nós na base quebra o `_ready`.
- **`fase_concluida` sem ouvinte:** ainda não há tela de fim de fase. O sinal existe para quem for implementá-la.
