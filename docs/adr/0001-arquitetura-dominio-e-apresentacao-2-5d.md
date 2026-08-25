# ADR 0001: Arquitetura de Domínio e Apresentação 2.5D com Billboard Rendering

## Contexto

O jogo *Guardião dos Biomas* exige exploração em mundo aberto com perspectiva 2.5D (estilo *Cult of the Lamb* / *Don't Starve*), metamorfose do jogador em animais nativos ameaçados e gerenciamento profundo de santuário (construção de habitats e alimentação). 

Conforme o [PROJECT.md](../../PROJECT.md), [GDD.md](../../GDD.md) e [SDD.md](../../SDD.md):
- A interface e superfícies de sistema devem usar SwiftUI.
- O domínio do jogo (regras, economia, inventário, estados) deve ser testável e desacoplado de dependências visuais.
- As decisões técnicas devem favorecer código nativo limpo, determinístico e de fácil manutenção.

## Decisão

1. **Separação Rígida em Camadas:**
   - **Camada de Domínio (Pure Swift):** Modelos imutáveis (`Biome`, `AnimalSpecies`, `Transformation`, `Sanctuary`, `Habitat`) e o coordenador de estado `@Observable` (`GameSession`). Essa camada não possui dependências com frameworks de renderização e é 100% testável via testes unitários.
   - **Camada de Apresentação 2.5D (SwiftUI + Billboard Canvas):** O mundo aberto e a perspectiva 2.5D utilizam projeção isométrica/pseudo-3D combinando *billboarding* com ordenação de profundidade em tempo real (Z-sorting e escala perspectivada) em SwiftUI nativo, garantindo total portabilidade, acessibilidade e fluidez gráfica a 60/120fps sem sobrecarga desnecessária de engines pesadas para o protótipo.
   - **Interface de Gestão (SwiftUI):** Telas de gerenciamento de habitats, inventário de comida e catálogo de espécies integradas diretamente ao SwiftUI com suporte a VoiceOver e temas de alto contraste.

## Consequências

### Positivas
- Testabilidade completa do núcleo de gameplay e economia do santuário sem necessidade de emular telas.
- Desenvolvimento ágil e código 100% nativo Swift.
- Acessibilidade de primeira classe fornecida pelos componentes SwiftUI.

### Negativas / Mitigações
- Para mundos 3D de geometria complexa no futuro, pode ser necessário avaliar SceneKit/Metal; no entanto, para a estética 2.5D de sprites em perspectiva aprovada, a projeção atual cumpre todos os requisitos de forma leve e responsiva.

## Status

Aprovado e Implementado.
