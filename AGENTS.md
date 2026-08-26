# Agent Instructions

Estas instruções valem para qualquer agente que trabalhe neste repositório.

## Ordem de leitura

1. [PROJECT.md](PROJECT.md)
2. [GDD.md](GDD.md)
3. [DESIGN.md](DESIGN.md)
4. [APPLE_TECHNOLOGIES.md](APPLE_TECHNOLOGIES.md)
5. [SDD.md](SDD.md)
6. [TEST_PLAN.md](TEST_PLAN.md)

O [README.md](README.md) funciona como índice. Estes documentos são as fontes de verdade; conversas e suposições não as substituem.

## Regras obrigatórias

- Não transformar `TBD`, hipótese ou exemplo em requisito.
- Não inferir plataforma final a partir do target macOS 26.5 do scaffold.
- Usar SwiftUI para a interface, sem assumir que SwiftUI será o renderer do gameplay.
- Não escolher SpriteKit, GameplayKit, Metal, RealityKit, ARKit ou outra tecnologia sem necessidade validada e decisão documentada.
- Não alterar arquivos Swift, Xcode ou assets quando a tarefa for apenas documental.
- Preservar mudanças existentes e manter o escopo do pedido.
- Atualizar o documento responsável sempre que uma decisão aprovada mudar.
- Criar ADR para decisões técnicas relevantes antes de consolidar dependências difíceis de reverter.
- Incluir acessibilidade, fallbacks e testes na definição de pronto.

## Fluxo de trabalho

1. Inspecionar o estado real do repositório.
2. Identificar fatos confirmados, hipóteses e decisões pendentes.
3. Propor a menor mudança coerente com as fontes de verdade.
4. Implementar sem expandir o escopo silenciosamente.
5. Executar validações proporcionais ao risco.
6. Relatar arquivos alterados, testes e pendências.

## Definição de pronto

- pedido atendido sem decisões inventadas;
- documentos e implementação consistentes;
- testes relevantes executados ou limitação explicada;
- acessibilidade e comportamento de fallback considerados;
- nenhum segredo, artefato de build ou mudança alheia incluído.

