# GamingBrainstorm

Repositório oficial de descoberta, especificação e implementação do projeto **Final Challenge**.

O conceito de produto foi aprovado em 02/09/2026: um jogo cooperativo de exploração espacial e gerenciamento de nave, no qual uma tripulação alienígena resgata e cuida de vacas alienígenas em planetas diferentes, com ritmo caótico cooperativo inspirado em *Overcooked*. Um conceito anterior (aventura de conservação da fauna brasileira, "Guardiões dos Biomas") foi explorado em profundidade em branches de discovery (`testeDoGumgum`, `testeGDD`, `claude/profundidade-transformacao`, entre outras) mas não foi aprovado como direção final; essas branches permanecem como histórico e não devem ser mescladas em `main` sob o conceito atual. O trabalho do novo conceito está na branch `pivot/vacas-alienigenas`.

Direção visual final (2D/2.5D/3D) e renderer de gameplay definitivo ainda estão em validação — ver [DESIGN.md](DESIGN.md), [APPLE_TECHNOLOGIES.md](APPLE_TECHNOLOGIES.md) e os ADRs em `docs/adr/`.

## Fontes de verdade

| Documento | Responsabilidade |
| --- | --- |
| [PROJECT.md](PROJECT.md) | Visão, objetivos, restrições, processo e decisões pendentes |
| [GDD.md](GDD.md) | Experiência do jogador, regras, sistemas e conteúdo |
| [DESIGN.md](DESIGN.md) | Direção visual, interface, HIG e acessibilidade |
| [APPLE_TECHNOLOGIES.md](APPLE_TECHNOLOGIES.md) | Avaliação de tecnologias Apple candidatas |
| [SDD.md](SDD.md) | Arquitetura e decisões de engenharia |
| [TEST_PLAN.md](TEST_PLAN.md) | Estratégia de validação e critérios de qualidade |
| [AGENTS.md](AGENTS.md) | Instruções compartilhadas para agentes de desenvolvimento |
| [CLAUDE.md](CLAUDE.md) | Entrada do Claude Code para as mesmas fontes de verdade |
| `docs/adr/` | Registro de decisões arquiteturais (ADRs) |

## Estado atual

- Fase: protótipo 1 em desenvolvimento.
- Conceito: cooperativo de exploração/gerenciamento de nave ("vacas alienígenas") — ver [GDD](GDD.md).
- Público e duração de sessão exata: `TBD`.
- Plataforma: macOS nativo.
- Multiplayer: cooperativo local confirmado (protótipo 1 usa a mesma rede local, sem servidor).
- Direção visual e sonora: `TBD`.
- Interface: SwiftUI obrigatório.
- Renderer de gameplay: candidato SpriteKit para o protótipo (ver ADR 0002), ainda não consolidado como decisão definitiva.
- Rede: candidato MultipeerConnectivity para o protótipo (ver ADR 0002), ainda não consolidado como decisão definitiva.
- Scaffold atual: app SwiftUI para macOS; isso **não** aprova sozinho a versão mínima final.

## Regra de decisão

Uma hipótese só se torna requisito quando for validada pela equipe e registrada no documento responsável. Decisões técnicas relevantes devem receber um ADR antes da implementação irreversível.

## Próximo passo

Escaffoldar o protótipo 1 (1 planeta, 1 vaca, timer de exploração, captura, habitat com alimentar/limpar/medicar, co-op via MultipeerConnectivity entre 2 Macs) e rodar o primeiro playtest para validar a hipótese central descrita no [GDD](GDD.md).
