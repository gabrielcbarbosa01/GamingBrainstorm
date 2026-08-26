# Software Design Document

## Estado da arquitetura

A arquitetura está em discovery. O repositório contém um app SwiftUI macOS mínimo, criado com Xcode 26.6 e deployment target 26.5. Esses valores descrevem o scaffold atual; não constituem plataforma, versão mínima ou arquitetura aprovadas.

## Objetivos de engenharia

- manter gameplay testável sem depender da camada visual sempre que possível;
- separar estado, regras, apresentação, serviços e integração de plataforma;
- permitir protótipos descartáveis antes da consolidação arquitetural;
- preservar determinismo onde ele facilitar testes, replay ou depuração;
- tratar acessibilidade e entrada como requisitos de arquitetura;
- medir desempenho no hardware-alvo antes de otimizar.

## Limites propostos

Estes limites orientam protótipos, mas só serão concretizados após escolha do conceito:

- **App/UI:** ciclo de vida e superfícies SwiftUI.
- **Game domain:** regras, estado e comandos independentes de framework quando viável.
- **Rendering:** adaptador para SpriteKit, RealityKit, Metal ou alternativa aprovada.
- **Input:** ações semânticas originadas por teclado, controle, toque, pointer ou sensores.
- **Audio/haptics:** feedback disparado por eventos de domínio, com fallbacks.
- **Persistence/services:** salvamento e integrações externas atrás de protocolos pequenos.

## Fluxo de dependências

A UI e o renderer podem observar o domínio e enviar comandos; o domínio não deve importar uma tecnologia de UI ou serviço externo sem justificativa registrada. Dependências específicas de plataforma ficam nas bordas.

## Concorrência

- Preferir isolamento explícito e APIs Swift modernas.
- Atualizações de UI ocorrem no ator principal.
- Trabalho pesado não deve bloquear frames ou interação.
- Concorrência só será introduzida onde houver necessidade medida.

## Dados e persistência

Modelo, formato, migração, autosave, sincronização e privacidade são `TBD`. Antes da escolha:

- definir quais dados realmente precisam sobreviver à sessão;
- evitar armazenar dados pessoais sem necessidade;
- testar corrupção, interrupção e evolução de esquema;
- documentar comportamento offline e conflitos se houver nuvem.

## Desempenho

Metas numéricas serão definidas após plataforma e renderer. Todo protótipo técnico deve registrar:

- frame rate e frame pacing no hardware relevante;
- tempo de inicialização e transições;
- memória, CPU/GPU, energia e temperatura quando aplicável;
- custo de assets, partículas, áudio e efeitos;
- resposta a pressão de memória e mudanças de estado do app.

## Observabilidade

Erros recuperáveis devem produzir diagnóstico útil em builds de desenvolvimento sem expor dados sensíveis. Logs não substituem feedback adequado à pessoa jogadora.

## Segurança e privacidade

- solicitar somente permissões necessárias e no contexto correto;
- oferecer comportamento seguro quando a permissão for recusada;
- não incluir segredos no repositório;
- minimizar coleta, retenção e transmissão de dados;
- revisar APIs online, contas e conteúdo gerado por usuários antes da adoção.

## Decisões que exigem ADR

- plataformas e versões mínimas;
- renderer e engine de gameplay;
- modelo de estado e arquitetura principal;
- persistência e sincronização;
- serviços online, analytics ou autenticação;
- formatos de assets e pipeline de conteúdo;
- qualquer dependência externa relevante.

## Estratégia de entrega inicial

O primeiro incremento deve ser um vertical slice mínimo: uma ação central, resposta completa, começo e fim de sessão, instrumentação suficiente e pelo menos uma verificação de acessibilidade. Ver [TEST_PLAN.md](TEST_PLAN.md).

