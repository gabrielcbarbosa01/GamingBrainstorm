# 0001 — Pivô de conceito para "vacas alienígenas" e confirmação de multiplayer cooperativo

## Status

Aceito — 02/09/2026.

## Contexto

O processo de discovery descrito no [PROJECT.md](../../PROJECT.md) previa propor de três a cinco conceitos divergentes antes de aprovar um. Um desses conceitos — uma aventura de exploração e conservação da fauna brasileira ("Guardiões dos Biomas") — foi prototipado em profundidade em branches de feature (`testeDoGumgum`, `testeGDD`, `claude/profundidade-transformacao`, entre outras), incluindo um app SwiftUI + SpriteKit funcional com seis biomas, formas animais, combate de ação-RPG e uma base administrável. Esse trabalho nunca foi mesclado em `main` como decisão de produto — `main` permaneceu no template de discovery, com todos os campos do GDD como `TBD`.

Em 02/09/2026 a equipe decidiu pivotar para um conceito diferente: um jogo cooperativo de exploração espacial e gerenciamento de nave, no qual uma tripulação alienígena resgata e cuida de vacas alienígenas em planetas diferentes, com ritmo caótico cooperativo inspirado em *Overcooked*. Esse conceito é fundamentalmente multiplayer/cooperativo, o que conflita com a leitura anterior do PROJECT.md, que listava "online, multiplayer, placares e conquistas" entre as "não decisões" (ou seja, nem sequer confirmado como fora de escopo — apenas aberto).

## Opções consideradas

1. Continuar a exploração do conceito "Guardiões dos Biomas" (fauna brasileira, single-player, ação-RPG) já parcialmente implementado.
2. Pivotar para o conceito "vacas alienígenas" (cooperativo, exploração + gerenciamento de nave), tratando o trabalho anterior como uma branch de discovery preservada, não como base de código a evoluir.
3. Manter os dois conceitos em paralelo até um novo playtest decidir.

## Decisão

Adotar a opção 2. O conceito "vacas alienígenas" é aprovado como direção de produto e detalhado no [GDD.md](../../GDD.md) atualizado. O trabalho de "Guardiões dos Biomas" permanece preservado nas branches onde foi feito, como histórico de discovery, e não é mesclado em `main` nem na branch `pivot/vacas-alienigenas`. Retomar esse conceito no futuro exigiria uma nova decisão explícita da equipe.

Como parte desta decisão, o multiplayer cooperativo local passa de "não decisão" para restrição confirmada no [PROJECT.md](../../PROJECT.md): a experiência exige pelo menos 2 jogadores cooperando; para o protótipo 1, cada jogador roda o jogo em seu próprio Mac, na mesma rede local.

## Consequências

- PROJECT.md, GDD.md, DESIGN.md, APPLE_TECHNOLOGIES.md, SDD.md e README.md foram atualizados nesta mesma branch (`pivot/vacas-alienigenas`) para refletir o novo conceito.
- O código Swift/SpriteKit existente para "Guardiões dos Biomas" não é reaproveitado diretamente; o protótipo 1 do novo conceito parte de um escopo mínimo definido no GDD.
- Decisões de tecnologia específicas para o protótipo 1 (renderer, rede) são registradas separadamente em `0002-tecnologias-prototipo-1.md`.
- Se a equipe quiser retomar "Guardiões dos Biomas" no futuro, as branches `testeDoGumgum`, `testeGDD` e `claude/profundidade-transformacao` continuam disponíveis; nenhuma delas foi apagada por esta decisão.
