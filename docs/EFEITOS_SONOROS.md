# Efeitos sonoros de gameplay (CG-25)

Os efeitos dão feedback para a marcação de pontos, a abertura do menu de chute, as respostas válidas e a entrada na faixa urgente do cronômetro. Os quatro arquivos ficam em `assets/audio/sfx/` e são reproduzidos pelo autoload `SFXManager` (`src/scripts/sfx_manager.gd`).

## Eventos e arquivos

| Arquivo | Onde dispara | Quando toca |
| --- | --- | --- |
| `interaction.mp3` | `PointSystem.add_point()` | Depois que o primeiro ponto A é criado e ancorado |
| `interaction.mp3` | `PointSystem.add_point()` | Depois que o ponto B válido e a reta são criados e registrados |
| `interaction.mp3` | `AnswerMenu._set_menu_open()` | Quando o menu passa de fechado para aberto, tanto pelo Tab quanto pelo botão do HUD |
| `correct.mp3` | `fase_farol.gd`, `_on_answer_correct()` | Uma vez por `answer_correct`, junto da tela "Correto!", inclusive no último ato |
| `wrong.mp3` | `fase_farol.gd`, `_on_answer_retry()` e `_on_answer_failed()` | Uma vez por resposta válida errada, seja para tentar de novo ou reiniciar a fase |
| `time_warning.mp3` | `SFXManager`, conectado a `Cronometro.tempo_urgente` | Uma vez por tentativa completa da fase, quando o HUD entra na faixa urgente de 30 segundos |

Fechar o menu não toca som. Cliques ignorados pelo Player ou por `MIN_LINE_LENGTH` não tocam som. Cancelar, desfazer e apagar retas também não tocam.

`answer_invalid` fica fora dos efeitos: campo vazio, só com separador decimal e zero mantêm o aviso da CG-47 e o menu aberto, sem `wrong.mp3`. Tempo esgotado também não dispara `wrong.mp3`.

## Serviço de áudio e volume

O `SFXManager` é registrado em `project.godot` depois do `Cronometro`. No `_ready()`, cria quatro `AudioStreamPlayer`, um por arquivo, e conecta `Cronometro.tempo_urgente` a `play(TIME_WARNING)`. Os demais eventos chamam `SFXManager.play()` com as constantes `INTERACTION`, `CORRECT` ou `WRONG`.

Os players são reutilizados e sobrevivem às trocas de ato. Cada um tem `max_polyphony = 4`, permitindo que interações rápidas se sobreponham. Players separados por arquivo permitem que uma resposta ou interação toque sem interromper o alerta. Não há players de SFX espalhados pelas cenas de gameplay.

O bus `SFX` está no `default_bus_layout.tres`, enviado ao `Master`, com volume inicial de **−8 dB**. O ajuste é feito no painel **Audio** do Godot, pelo volume do bus; salve o layout após ajustar. Silenciar esse bus permite conferir os efeitos sem alterar o bus `Music`.

O `MusicManager` mantém sua cena, reprodução e bus `Music`. Os sons ambientes existentes também permanecem como estavam. Os quatro SFX são importados com `loop=false`; seus `.import` e o `.uid` do novo script acompanham o código no versionamento.

## Alerta único entre os atos

O HUD já verifica `tempo_restante <= limite_urgente` com tempo total maior que zero. `limite_urgente` continua sendo **30 segundos** por padrão. Ao entrar nesse estado, `_aplicar_urgencia(true)` chama `Cronometro.alertar_tempo_urgente()`, sem uma segunda condição de tempo exclusiva para áudio.

A trava `_alerta_urgente_emitido` pertence ao autoload `Cronometro`:

1. `iniciar()` define a trava como `false`, junto do início de uma nova tentativa.
2. O primeiro pedido de alerta define a trava como `true` antes de emitir `tempo_urgente`.
3. Pedidos seguintes retornam sem emitir o sinal.
4. `pausar()` e `continuar()` não alteram a trava.

Cada ato recria o HUD. Se os Atos 2 e 3 começarem com 30 segundos ou menos, seus HUDs entram no modo urgente, mas o `Cronometro` preserva a trava e não repete o som já disparado. Reiniciar por erro grosseiro ou tempo esgotado volta ao Ato 1, que chama `iniciar()` e libera um novo alerta para a nova tentativa.

## Como são evitados disparos duplicados

- **Pontos e retas:** o som fica depois da criação confirmada em `add_point()`. O retorno para comprimento menor ou igual a `MIN_LINE_LENGTH` vem antes do áudio. `lines_changed` continua alimentando as listas; não dispara som, pois também é emitido ao apagar retas.
- **Menu:** `abrindo` compara o estado anterior com o pedido de abertura. Fechar ou pedir abertura de um menu já aberto não toca.
- **Respostas:** os sons ficam apenas nos handlers dos sinais existentes da fase. A avaliação do AnswerMenu e a ResultScreen não disparam uma segunda cópia. Nenhuma margem ou validação de resposta foi duplicada para o áudio.
- **Tempo:** o estado persistente no `Cronometro` bloqueia repetições entre quadros, pausas e atos.

## Tempo da fase e escopo

O tempo padrão passou de 300 para **600 segundos (10 minutos)** no export `tempo_total` de `fase_farol.gd`. É um único tempo para os três atos; avançar de ato não repõe o tempo. O HUD começa em **10:00**, e o alerta continua em 30 segundos. Ver [ESTRUTURA_DE_FASES.md](ESTRUTURA_DE_FASES.md#cronômetro-cg-37).

Os efeitos não mudam regras de respostas, tolerâncias, medidas, UI, duração das telas ou fluxo de atos. Passos não fazem parte desta implementação. Não há áudio de restauração: a versão atual não tem animação de Lodo retraindo ou filé assentando; o feedback sonoro de acerto é `correct.mp3`.

## Roteiro de teste manual

1. Rode o Ato 1 com F5 e confira que o HUD começa em 10:00. Ancore A, tente um clique ignorado e feche uma reta válida: uma interação em A e uma no fechamento, nenhuma no clique ignorado. Para conferir especificamente `MIN_LINE_LENGTH`, execute `add_point()` com A e B separados por no máximo 0,001 m em uma cena de teste.
2. Abra e feche o menu pelo Tab e, com o cursor livre, pelo botão "Calcular área": uma interação ao abrir, nenhuma ao fechar. Cancele, desfaça e apague retas: nenhum efeito adicional.
3. Envie vazio, `,`, `.`, `0` e `0,000`: o menu e o aviso da CG-47 permanecem, sem som de erro. Envie um valor de retry, um erro grosseiro e um acerto, conforme [as faixas de resposta](ESTRUTURA_DE_FASES.md#faixas-de-resposta): um som correspondente por envio, junto do resultado visual.
4. Em uma tentativa nova, no Inspector remoto de `/root/Cronometro`, ajuste apenas `tempo_restante` para 31. Ao cruzar 30, confira o alerta único e a urgência visual. Pause e continue com ESC: o alerta não repete.
5. Acerte os Atos 1 e 2 ainda na faixa urgente e confirme que os novos HUDs dos Atos 2 e 3 não repetem o alerta. Acerte o último ato e confira o som e a conclusão existentes.
6. Reinicie por erro grosseiro e depois por tempo esgotado. Cada nova tentativa deve começar em 10:00 e permitir outro alerta ao cruzar 30. O timeout não toca `wrong.mp3`.
7. No painel Audio, ajuste ou silencie SFX e confira a independência da música. Verifique os imports com Loop desativado e avalie o equilíbrio auditivo dos quatro sons.

## Validação

A implementação foi validada em Godot 4.7.2 headless com **56 verificações de integração, sem falhas**. A execução cobriu o início em 600 segundos com HUD em 10:00, os gatilhos de áudio, respostas inválidas, cliques ignorados, as trocas reais entre os três atos já na faixa urgente, pausa/continuação e reinícios por erro grosseiro e tempo esgotado. Os scripts de validação foram temporários e não fazem parte do repositório.

A avaliação de volume e percepção dos sons depende do teste manual.

A origem, o autor e a licença de cada áudio são registrados em [AUDIO_SOURCES.md](AUDIO_SOURCES.md); as informações dos novos SFX ainda precisam ser preenchidas.
