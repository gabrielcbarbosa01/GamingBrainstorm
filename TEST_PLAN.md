# Test Plan

## Objetivo

Validar simultaneamente experiência, regras, integração Apple, acessibilidade, desempenho e estabilidade. O plano será refinado quando conceito e plataforma forem aprovados.

## Pirâmide de validação

### Discovery e playtests

- testar compreensão, emoção e desejo de repetir;
- observar comportamento antes de fazer perguntas direcionadas;
- registrar dispositivo, build, roteiro, evidências e mudanças propostas;
- separar preferência individual de problema recorrente.

### Testes unitários

- regras do domínio, transições de estado, cálculos e progressão;
- aleatoriedade com seed quando aplicável;
- codificação, migração e recuperação de dados;
- mapeamento de comandos de entrada.

### Testes de integração

- SwiftUI com ciclo de vida do jogo;
- renderer com estado do domínio;
- áudio, háptica, persistência e serviços Apple;
- interrupções, segundo plano, restauração e perda de foco.

### Testes de interface e sistema

- fluxo completo de primeira sessão;
- teclado, controle, toque ou pointer conforme plataforma;
- menus, configurações, pausa, reinício e saída;
- permissões recusadas e recursos indisponíveis.

## Matriz mínima de acessibilidade

| Área | Verificação |
| --- | --- |
| VoiceOver | Rótulos, valores, ordem de foco e conclusão do fluxo aplicável |
| Cor/contraste | Informação não depende só de cor; contraste medido |
| Texto | Tamanhos e truncamento nas superfícies SwiftUI |
| Movimento | Preferência de redução de movimento respeitada |
| Áudio | Informação sonora essencial possui equivalente visual |
| Entrada | Alternativas para gestos/ações complexas quando aplicável |
| Cognição | Instruções claras, consistência e recuperação de erros |

## Desempenho

Após a decisão de plataforma, registrar budgets para frame time, memória, inicialização, carregamento e energia. Executar Instruments e testes em hardware representativo, incluindo cenas de pior caso.

## Critérios de entrada do vertical slice

- emoção, fantasia, verbos e sessão descritos no [GDD](GDD.md);
- plataforma e renderer provisórios justificados;
- maior risco identificado;
- roteiro de playtest e métricas definidos.

## Critérios de saída do vertical slice

- uma pessoa nova consegue iniciar, agir e terminar sem intervenção;
- causa e efeito do core loop são compreendidos;
- a emoção-alvo aparece de forma recorrente nas evidências;
- não há crash, perda de progresso ou bloqueador conhecido no fluxo principal;
- requisitos de acessibilidade aplicáveis possuem resultado registrado;
- desempenho atende ao budget provisório no hardware escolhido;
- riscos e decisões seguintes estão documentados.

## Gestão de defeitos

Priorizar por impacto na experiência:

- **P0:** perda de dados, crash generalizado, risco de privacidade ou fluxo impossível.
- **P1:** core loop ou acessibilidade essencial seriamente comprometidos.
- **P2:** comportamento incorreto com contorno disponível.
- **P3:** polimento sem impacto relevante na conclusão da sessão.

Todo bug deve incluir build, ambiente, passos, resultado esperado, resultado observado e evidência quando útil.

## Verificação documental

- links Markdown locais resolvem;
- nenhum `TBD` é apresentado como decisão;
- GDD, design, arquitetura e matriz tecnológica não se contradizem;
- AGENTS.md e CLAUDE.md apontam para as mesmas fontes de verdade.

