# Filemetria — Padrão de projeto e arquitetura

Estrutura de pastas adotada no projeto (Godot 4.7):

```
Filemetria/
├── .editorconfig              # raiz (obrigatório)
├── .gitattributes             # normaliza fim de linha para LF
├── .gitignore                 # raiz
├── project.godot              # raiz (obrigatório — define o projeto)
├── default_bus_layout.tres    # buses de áudio (Master e Music)
├── icon.svg                   # raiz por padrão
├── icon.svg.import            # anda sempre colado ao recurso
├── docs/                      # documentação (lista no README)
├── assets/                    # arquivos de recursos
│   ├── models/                # modelos 3D low-poly (.glb usado no jogo + .blend de origem)
│   ├── textures/              # texturas e materiais (.tres), uma pasta por material
│   ├── sprites/               # imagens 2D: ícones SVG do HUD e a mira
│   │   └── renda_file/        # padrões de renda filé do HUD
│   ├── audio/                 # ambient/ (sons de fundo) e music/
│   ├── fonts/                 # fontes, uma pasta por família com o OFL.txt
│   └── refs/                  # fotos de referência da modelagem (fora do build)
└── src/
    ├── entities/              # player/, statics/ (Farol, Point, Line), environment/ (SpawnManager, sunset_lighting)
    ├── scenes/
    │   ├── fase_um/           # fase do Farol: cena base + uma cena por ato
    │   ├── managers/          # cenas de autoload (MusicManager)
    │   └── sandbox/           # cenas de teste manual (não entram no export)
    ├── scripts/               # scripts genéricos e autoloads (.gd)
    ├── shaders/               # shaders reutilizáveis (.gdshader): glow/
    ├── tiles/                 # tilemaps (vazia por enquanto)
    └── ui/                    # interface: Hud, AnswerMenu, ResultScreen
```

## Convenções

- `assets/` guarda apenas recursos importados; nada de lógica.
- `src/` guarda tudo que é cena (`.tscn`), código (`.gd`) ou shader (`.gdshader`).
- Cada entidade em `src/entities/` e cada tela em `src/ui/` fica em sua própria subpasta com a cena e o script juntos (ex.: `src/entities/player/player.tscn` + `player.gd`, `src/ui/Hud/hud.tscn` + `hud.gd`).
- Scripts genéricos/reutilizáveis (autoloads, helpers, singletons) vão em `src/scripts/`. Autoloads que são cena vão em `src/scenes/managers/`.
- Nomes de arquivos e pastas em `snake_case`; nomes de classes em `PascalCase`. **Exceção existente:** várias pastas de cena usam o nome do nó raiz em `PascalCase` (`entities/statics/Farol/`, `entities/environment/SpawnManager/`, `ui/Hud/`, `ui/AnswerMenu/`), enquanto outras seguem a regra (`entities/player/`, `entities/environment/sunset_lighting/`). Pastas novas seguem a regra; renomear as antigas exige fazer pelo editor do Godot, para ele atualizar as referências.
- Documentação em `docs/`, com nomes em `MAIÚSCULO_COM_UNDERLINE` (ver [CONVENCOES_E_BOAS_PRATICAS.md](CONVENCOES_E_BOAS_PRATICAS.md#nomenclatura-de-arquivos-de-documentação)).

## Arquivos gerados pelo Godot — onde ficam

Ficam **na raiz** e não devem ser movidos:

- `project.godot` — o Godot identifica a pasta do projeto por esse arquivo. Mover quebra o projeto.
- `.editorconfig` — convenção de ferramenta; vale para o repositório inteiro.
- A pasta `.godot/` — cache de importação, gerada automaticamente. Fica na raiz e **não** é versionada.

`icon.svg` e `icon.svg.import` **podem** ir para `assets/sprites/`, se houver preferência por manter a raiz limpa. Nesse caso:

1. Mover pelo **FileSystem dock dentro do editor do Godot** (ele reescreve os caminhos sozinho). Movendo por fora, o `.import` tem que ir junto.
2. Ajustar Project Settings → Application → Config → Icon (linha `config/icon=` em `project.godot`).

Deixar o `icon.svg` na raiz também é aceitável — é o padrão do Godot.

## Git

Os arquivos `.import` e `.uid` **devem** ser versionados, apesar de parecerem gerados: sem os `.import` o Godot reimporta todos os recursos do zero em cada máquina, e sem os `.uid` as referências por UID (`uid://...`) quebram.

`.gitignore` atual:

```gitignore
# Godot 4+ specific ignores
.godot/
.vscode/
.claude/
/android/
export_presets.cfg   # contém caminhos locais e às vezes credenciais de assinatura
*.translation
/builds/
```

## Export

O `export_presets.cfg` não é versionado, então cada máquina configura o próprio preset. Por padrão o Godot exporta todos os recursos do projeto, inclusive os que nenhuma cena usa. Em todo preset, na aba **Resources**, preencher **Filters to exclude files/folders from project** com:

```text
assets/refs/*, src/scenes/sandbox/*, assets/models/*.blend
```

- `assets/refs/`: fotos de referência da modelagem; nenhuma cena usa, e algumas são de terceiros (marca d'água ou crédito de fotógrafo), então não podem ser distribuídas (ver [CREDITOS.md](CREDITOS.md#fora-do-build)).
- `src/scenes/sandbox/`: cenas de teste manual.
- `.blend`: fonte do modelo; o jogo usa só o `.glb`.

Os builds vão para `/builds/`, que é ignorado pelo Git.
