# Convenções e boas práticas — Godot 4.7 (3D)

Este documento complementa o [ARQUITETURA.md](ARQUITETURA.md), que já cobre estrutura de pastas, nomenclatura de arquivos/pastas e organização do Git. Aqui ficam as convenções de **código, cenas e configuração do projeto** para jogos 3D.

## GDScript

- Usar **tipagem estática** sempre que possível (`var speed: float = 5.0`, `func take_damage(amount: int) -> void:`). Facilita autocomplete e evita bugs bobos de tipo.
- Ativar `@tool` apenas quando o script realmente precisa rodar no editor; não deixar como hábito.
- Nomes: `snake_case` para variáveis, funções e sinais; `PascalCase` para classes (`class_name`) e nomes de nó; `CONSTANTE_MAIUSCULA` para `const`.
- Variáveis privadas/internas (não pensadas para uso fora do script) prefixadas com `_` (ex.: `_internal_state`), seguindo a convenção do próprio Godot.
- Preferir `@export` a variáveis públicas soltas para expor parâmetros ajustáveis no Inspector; agrupar exports relacionados com `@export_group` ou `@export_category` quando o script crescer.
- Ordem sugerida dentro de um script: `class_name` / `extends` → sinais (`signal`) → constantes/enums → `@export` → variáveis normais → `_ready`/`_process`/outros métodos virtuais → métodos públicos → métodos privados (`_`).
- Evitar lógica pesada em `_process`/`_physics_process` sem necessidade; preferir sinais e `await` a polling quando der.

## Sinais

- Nomear sinais no passado ou como evento (`health_depleted`, `door_opened`), nunca como comando (`open_door`).
- Conectar sinais **pelo código** (`signal.connect(callable)`) quando a ligação for entre scripts/entidades diferentes; conexões pelo editor (Inspector) só para casos simples dentro da mesma cena, pois não aparecem no diff do Git de forma clara.
- Preferir sinais a referências diretas entre nós distantes na árvore (evita acoplamento entre entidades que não deveriam se conhecer).

## Cenas (.tscn) e árvore de nós

- Um `.tscn` por entidade/elemento reutilizável, com o script correspondente anexado à raiz da cena (já convencionado em `src/entities/`).
- Nomes de nós na árvore em `PascalCase` (padrão do próprio editor), descrevendo a função do nó (`HitboxArea`, `CameraPivot`) e não o tipo (`Area3D` já aparece no ícone).
- Usar **grupos** (`add_to_group`) para categorias transversais (ex.: `"enemies"`, `"interactable"`) em vez de checar tipo/nome manualmente.
- Cenas de teste manual continuam em `src/scenes/sandbox/` (já definido na arquitetura) — não referenciar nós de sandbox a partir de cenas de produção.
- Evitar herança de cena (`Inherits`) profunda; preferir composição (cenas menores instanciadas dentro de cenas maiores) para reduzir acoplamento.

## Assets 3D

- Modelos exportados em `.glb`/`.gltf` (já definido na arquitetura); aplicar transformações (escala, rotação) no software de origem antes de exportar — evitar corrigir escala/rotação só no import do Godot.
- Ao importar, preferir gerar **LODs** e ativar **compressão de textura** adequada (VRAM Compressed) para assets que vão a build final; assets de sandbox/teste podem ficar sem otimização.
- Malhas de colisão: usar formas de colisão simplificadas (`ConvexPolygonShape3D`/`primitivas`) em vez de colisão por malha (`ConcavePolygonShape3D`/trimesh) sempre que o objeto se mover ou colidir com física dinâmica; trimesh só para geometria estática do cenário.
- Materiais compartilhados devem ser salvos como recursos `.tres` reutilizáveis em `assets/textures/` (ou subpasta `materials/`, se necessário), não duplicados dentro de cada malha.

## Física e colisões

- Nomear as **camadas de física** (Project Settings → Layer Names → 3D Physics) em vez de deixar como "Layer 1", "Layer 2" — isso já documenta o propósito de cada camada para quem abrir o projeto depois.
- Definir layers/masks pensando em categorias (`world`, `player`, `enemies`, `interactables`, `hitbox`, `hurtbox`) e manter essa lista atualizada neste documento conforme for crescendo.

## Input

- Toda entrada do jogador passa pelo **Input Map** (Project Settings → Input Map), nunca por checagem direta de tecla/botão no código (`Input.is_key_pressed`). Isso mantém o jogo remapeável e portável entre teclado/controle.
- Nomes de ações em `snake_case` e descritivos por função, não por tecla (`move_forward`, não `key_w`).

## Autoloads / Singletons

- Autoloads (Project Settings → Autoload) só para estado ou serviços realmente globais (ex.: gerenciador de cena, estado de save, áudio global). Ficam em `src/scripts/`, já coberto na arquitetura.
- Evitar transformar autoload em "bag" de utilidades genéricas sem relação — cada autoload deve ter uma responsabilidade clara.

## UI

- Cenas de UI usam **Control** e Anchors/Containers (não posicionamento manual por pixel) para se adaptar a diferentes resoluções.
- Textos exibidos ao jogador não ficam hardcoded espalhados pelo código; centralizar em constantes ou (se o projeto crescer e precisar de i18n) em arquivos de tradução do Godot.

## Recursos customizados (`Resource`)

- Preferir `Resource`/`class_name` customizado a dicionários soltos para dados estruturados reutilizáveis (ex.: definição de um tipo de inimigo, item, fase). Salvar como `.tres` junto do que ele descreve.

## Comentários e documentação

- Comentar apenas o que não é óbvio pelo nome (uma decisão não trivial, uma limitação conhecida, um workaround). Não narrar o que a linha faz.
- Usar docstrings do GDScript (`## comentário`) acima de classes e funções públicas quando o comportamento não for óbvio pela assinatura.

## Nomenclatura de arquivos de documentação

- Arquivos `.md` dentro de `docs/` em **MAIÚSCULO_COM_UNDERLINE** (ex.: `ARQUITETURA.md`, `CONVENCOES_E_BOAS_PRATICAS.md`). Sem espaços, sem acentos, sem hífen.

## Convenção de branches

- Formato: `CG-[código no Jira]/tipo-descricao-curta`.
- `tipo` segue os mesmos prefixos usados em commits (`docs`, `feat`, `fix`, `chore`, etc.), e a descrição fica em `kebab-case`, curta e no português do restante do projeto.
- Exemplo: `CG-3/docs-boas-praticas-e-convencoes`.

## Versionamento de cenas

- Evitar que duas pessoas editem a mesma cena `.tscn` ao mesmo tempo em branches diferentes — o formato de texto do Godot gera conflitos de merge difíceis de resolver manualmente (a ordem dos nós e os UIDs mudam facilmente).
- Nunca editar `uid` de recursos manualmente; se um conflito de UID aparecer após merge, deixar o Godot reimportar/regenerar.
