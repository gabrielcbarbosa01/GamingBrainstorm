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
- O jogo será single-player e terá macOS como plataforma principal.
- O público será geral, com foco em adultos e jovens adultos.
- A experiência terá sessões típicas de 20–30 minutos e campanha de pelo menos 4–5 horas, sujeita a validação de escopo.
- O projeto deve seguir as Human Interface Guidelines aplicáveis à plataforma aprovada.
- Funcionalidades essenciais devem ser utilizáveis sem depender exclusivamente de cor, som ou movimento.
- Mudanças relevantes de arquitetura, plataforma, renderer ou persistência exigem decisão documentada.

## Não decisões

Os itens abaixo continuam deliberadamente abertos:

- classificação etária e versões mínimas do macOS;
- plataformas secundárias e dispositivos adicionais;
- duração, frequência e estrutura das sessões;
- renderer e pipeline técnico para o visual 2.5D aprovado como direção;
- direção sonora final;
- suporte de lançamento a controle físico e remapeamento;
- online, multiplayer, placares e conquistas;
- persistência local ou em nuvem.

O deployment target encontrado no Xcode descreve somente o scaffold e não define a versão mínima aprovada.

## Processo de discovery

1. Definir emoção durante e depois da sessão.
2. Formular fantasia do jogador e verbos principais.
3. Propor de três a cinco conceitos divergentes.
4. Avaliar cada conceito por clareza, diferenciação, diversão, escopo, acessibilidade e risco técnico.
5. Prototipar a maior incerteza do conceito favorito.
6. Testar com pessoas e registrar evidências.
7. Aprovar um conceito e atualizar os documentos responsáveis.

## Critérios de sucesso do conceito

- A proposta pode ser explicada em uma frase sem depender de lore.
- A ação central é compreendida rapidamente por uma pessoa nova.
- Uma sessão curta produz a emoção definida no discovery.
- O núcleo cabe no prazo sem depender de conteúdo excessivo.
- Existe um caminho verificável para acessibilidade e bom desempenho.
- A tecnologia escolhida serve à experiência e pode ser prototipada cedo.

## Registro de decisões

Decisões arquiteturais importantes serão registradas em `docs/adr/NNNN-titulo.md` quando a primeira decisão for aprovada. Cada ADR deve conter contexto, opções, decisão, consequências e status. Até lá, menções técnicas nos documentos são candidatas, não compromissos.

## Questões abertas prioritárias

1. O que queremos que a pessoa sinta enquanto joga e após a sessão?
2. Qual fantasia permite produzir essa emoção?
3. Quais são os verbos mínimos dessa fantasia?
4. Qual é a duração ideal de uma sessão?
5. Em qual contexto e dispositivo a experiência funciona melhor?
