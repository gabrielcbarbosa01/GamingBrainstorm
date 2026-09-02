# Project Charter — Final Challenge

## Propósito

Criar um jogo Apple nativo com uma experiência clara, memorável e executável dentro das restrições do Final Challenge. Este documento governa o projeto; detalhes de gameplay pertencem ao [GDD](GDD.md) e detalhes técnicos ao [SDD](SDD.md).

## Princípios

1. Começar pela experiência desejada, não por uma tecnologia ou gênero favorito.
2. Manter hipótese, decisão e implementação claramente separadas.
3. Favorecer um núcleo jogável pequeno, polido e testável.
4. Considerar acessibilidade, entrada, áudio e feedback desde o primeiro protótipo.
5. Usar tecnologias Apple somente quando resolverem uma necessidade comprovada.
6. Preservar uma única fonte de verdade para humanos, Codex e Claude Code.

## Restrições confirmadas

- SwiftUI será usado na interface do produto.
- **Conceito aprovado (02/09/2026):** jogo cooperativo de exploração espacial e gerenciamento de nave — tripulação alienígena que viaja a planetas para resgatar vacas alienígenas e cuidar delas numa nave, inspirado em *Overcooked*. Ver [GDD](GDD.md) para detalhes. Isso substitui qualquer concepção anterior discutida em branches de discovery (ex.: `testeDoGumgum`, `testeGDD`) — essas branches permanecem como histórico de exploração de conceito, não como direção aprovada, e não devem ser mescladas em `main` sob esta decisão.
- **Plataforma principal:** macOS nativo.
- **Multiplayer cooperativo local confirmado:** a experiência exige pelo menos 2 jogadores cooperando; para o protótipo 1, cada jogador roda o jogo em seu próprio Mac, na mesma rede local, sem necessidade de servidor (ver ADR 0001 e 0002 em `docs/adr/`). Isso substitui o item "online, multiplayer, placares e conquistas" que antes estava em "Não decisões".
- O projeto deve seguir as Human Interface Guidelines aplicáveis à plataforma aprovada.
- Funcionalidades essenciais devem ser utilizáveis sem depender exclusivamente de cor, som ou movimento.
- Mudanças relevantes de arquitetura, plataforma, renderer ou persistência exigem decisão documentada.

## Não decisões

Os itens abaixo continuam deliberadamente abertos:

- classificação etária e faixa etária exata dentro do público geral;
- duração, frequência e estrutura exata das sessões (quantos minutos por missão, quantas missões por sessão);
- modelo visual 2D, 2.5D ou 3D;
- estilo visual e sonoro definitivo;
- suporte a controle físico e remapeamento;
- funcionamento do modo solo (single-player) — o conceito aprovado é cooperativo; se e como um modo solo existirá é aberto;
- número máximo de jogadores suportado (o protótipo 1 valida 2; a visão do conceito considera até 4);
- multiplayer pela internet / jogadores em redes diferentes (fora de escopo do protótipo 1, que assume mesma rede local — ver ADR 0002);
- persistência local ou em nuvem.

O deployment target macOS encontrado no Xcode é somente o estado do scaffold e não define a versão mínima aprovada.

## Processo de discovery

1. Definir emoção durante e depois da sessão.
2. Formular fantasia do jogador e verbos principais.
3. Propor de três a cinco conceitos divergentes.
4. Avaliar cada conceito por clareza, diferenciação, diversão, escopo, acessibilidade e risco técnico.
5. Prototipar a maior incerteza do conceito favorito.
6. Testar com pessoas e registrar evidências.
7. Aprovar um conceito e atualizar os documentos responsáveis.

O conceito "vacas alienígenas" foi aprovado em 02/09/2026 após exploração de um conceito anterior (aventura de conservação da fauna brasileira, "Guardiões dos Biomas") que permanece documentado apenas nas branches onde foi prototipado. A maior incerteza identificada para o protótipo 1 é se a transição entre exploração cronometrada e gerenciamento cooperativo em tempo real é compreensível e divertida — ver [GDD](GDD.md), seção de hipótese e métricas.

## Critérios de sucesso do conceito

- A proposta pode ser explicada em uma frase sem depender de lore.
- A ação central é compreendida rapidamente por uma pessoa nova.
- Uma sessão curta produz a emoção definida no discovery.
- O núcleo cabe no prazo sem depender de conteúdo excessivo.
- Existe um caminho verificável para acessibilidade e bom desempenho.
- A tecnologia escolhida serve à experiência e pode ser prototipada cedo.

## Registro de decisões

Decisões arquiteturais importantes são registradas em `docs/adr/NNNN-titulo.md`. Cada ADR deve conter contexto, opções, decisão, consequências e status. Ver `docs/adr/0001-pivo-conceito-vacas-alienigenas.md` e `docs/adr/0002-tecnologias-prototipo-1.md`.

## Questões abertas prioritárias

1. Qual é a duração ideal de uma missão e de uma sessão completa?
2. Como funciona (ou se existe) um modo solo?
3. A captura de uma vaca será direta ou envolverá puzzles?
4. É possível perder uma vaca permanentemente?
5. Quais tarefas de cuidado exigirão obrigatoriamente dois jogadores?
6. Qual direção visual (2D/2.5D/3D) serve melhor à legibilidade do caos cooperativo?
