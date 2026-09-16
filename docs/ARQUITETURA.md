# Telemetria — Padrão de projeto e arquitetura

Estrutura de pastas adotada no projeto (Godot 4):

```
telemetria/
├── .editorconfig      # raiz (obrigatório)
├── .gitignore         # raiz
├── project.godot      # raiz (obrigatório — define o projeto)
├── icon.svg           # raiz por padrão
├── icon.svg.import    # anda sempre colado ao recurso
├── assets/            # arquivos de recursos
│   ├── models/        # modelos 3D low-poly (.glb / .gltf)
│   ├── textures/      # texturas e materiais
│   ├── sprites/       # imagens 2D (caso necessário)
│   ├── audio/         # música e efeitos sonoros
│   └── fonts/         # fontes
└── src/
    ├── entities/      # entidades como o jogador
    ├── scenes/        # cenas e fases
    │   └── sandbox/   # cenas de teste manual (não entram no export)
    ├── scripts/       # scripts em GDScript (.gd)
    ├── tiles/         # tilemaps
    └── ui/            # interface do jogador
```

## Convenções

- `assets/` guarda apenas recursos importados; nada de lógica.
- `src/` guarda tudo que é cena (`.tscn`) ou código (`.gd`).
- Cada entidade em `src/entities/` fica em sua própria subpasta com a cena e o script juntos (ex.: `src/entities/player/player.tscn` + `player.gd`).
- Scripts genéricos/reutilizáveis (autoloads, helpers, singletons) vão em `src/scripts/`.
- Nomes de arquivos e pastas em `snake_case`; nomes de classes em `PascalCase`.

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

Os arquivos `.import` **devem** ser versionados, apesar de parecerem gerados: sem eles o Godot reimporta todos os recursos do zero em cada máquina.

`.gitignore` atual:

```gitignore
# Godot 4+ specific ignores
.godot/
.vscode/
.claude/
/android/

# Exports e artefatos locais
export_presets.cfg   # contém caminhos locais e às vezes credenciais de assinatura
*.translation
/builds/
```