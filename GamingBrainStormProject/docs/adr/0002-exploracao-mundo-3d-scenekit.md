# ADR 0002: Renderização de Mundo 3D com SceneKit e SceneView no SwiftUI

## Contexto

Após a validação do conceito e do protótipo 2.5D, surgiu a necessidade de explorar uma experiência de mundo 3D com mapa expandido, rio 3D navegável, florestas volumétricas, sombras em tempo real e neblina volumétrica.

Conforme o [PROJECT.md](../../PROJECT.md) e o [SDD.md](../../SDD.md):
- A tecnologia deve ser nativa Apple.
- O domínio do jogo (`GameSession`, `AnimalSpecies`, `Sanctuary`) deve permanecer isolado da engine de apresentação.
- Decisões de rendering devem ser documentadas em ADR.

## Decisão

Adotar o **SceneKit** (`SceneView` no SwiftUI) para a camada de apresentação 3D.

1. **Vantagens do SceneKit:**
   - Framework nativo de alto desempenho integrado diretamente ao ecossistema Apple.
   - Suporte a iluminação PBR, sombras dinâmicas de alta resolução, neblina volumétrica e sistemas de partículas.
   - Renderização fluida de geometrias 3D (terrenos, leito de rio, malha de água) combinadas com texturas de sprites (como os quadros de animação do macaco e árvores em planos cruzados).
   - Excelente consumo de memória e desempenho constante em 60/120 FPS no macOS e iOS.

2. **Integração com SwiftUI:**
   - A cena 3D (`SCNScene`) é gerenciada e atualizada através de um coordenador acoplado ao estado reativo do `@Observable GameSession`.
   - A interface de usuário (HUD, inventário, mapa, botões de ação e diálogos) continua 100% em SwiftUI puro sobreposta à `SceneView`.

## Consequências

- O jogo agora suporta uma rica experiência de exploração 3D com rio, florestas densas e sombras reais.
- Mantém-se total portabilidade e conformidade com as Human Interface Guidelines da Apple.

## Status

Aprovado e Implementado.
