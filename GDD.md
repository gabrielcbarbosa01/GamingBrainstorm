# Game Design Document

> Status: discovery. Todo conteúdo marcado `TBD` exige validação antes de orientar implementação.

## Visão do jogo

- High concept: Um jogo de aventura e gerenciamento 2.5D onde o jogador explora biomas brasileiros em mundo aberto, assumindo a forma de animais ameaçados para investigar perigos e resgatá-los para o santuário.
- Fantasia do jogador: Guardião metamorfo do ecossistema brasileiro.
- Emoção durante a sessão: Curiosidade (ao explorar biomas e descobrir mecânicas dos animais) e Tensão (ao lidar com ameaças ambientais).
- Emoção imediatamente após a sessão: Satisfação e alívio ao expandir o santuário e garantir a segurança das espécies.
- Público principal: Jovens e adultos interessados em exploração, coleta e cozy management.
- Gênero: Aventura / Sanctuary Management.
- Plataforma e contexto de uso: Mac / iPad (a ser validado), focado em sessões de média duração para exploração e microgerenciamento.

## Pilares de design

Os pilares serão escolhidos após a definição emocional. Cada pilar deverá:

- descrever uma propriedade percebida pela pessoa jogadora;
- orientar decisões de inclusão e exclusão;
- possuir ao menos um teste observável;
- não prescrever tecnologia.

## Core loop

1. **Explorar e Investigar:** O jogador navega pelo mapa aberto (biomas brasileiros), atraído por sinais de animais em perigo (estímulo).
2. **Transformar:** O jogador assume a forma de um animal específico para acessar áreas restritas ou investigar ameaças (decisão e verbo).
3. **Resgatar:** O jogador coleta/salva o animal, recebendo feedback de conclusão (resposta).
4. **Gerenciar:** O jogador retorna ao santuário para construir habitats adequados, gerenciar comida e acomodar o animal resgatado, liberando dados no mapa/catálogo e recursos para explorar novas áreas (mudança de estado e motivação).

Ao ser definido, o loop deve explicitar:

1. estímulo ou objetivo percebido;
2. decisão tomada pela pessoa;
3. ação ou verbo executado;
4. resposta audiovisual, háptica ou sistêmica;
5. mudança de estado e motivação para repetir.

## Estrutura da sessão

- Tempo para entender a primeira ação: `TBD`.
- Duração-alvo: `TBD`.
- Condição de início e término: `TBD`.
- Pausa, retomada e salvamento: `TBD`.
- Progressão entre sessões: `TBD`.

## Sistemas

| Sistema | Estado | Pergunta de discovery |
| --- | --- | --- |
| Movimento/controle | Em design | Qual ação física ou abstrata expressa a fantasia? (Navegação no mapa e controles de transformação animal) |
| Desafio | Em design | Que habilidade ou decisão é testada? (Otimização de recursos no santuário e escolha da forma animal) |
| Feedback | TBD | Como o jogo torna causa e efeito inequívocos? |
| Progressão | Em design | O que muda dentro e entre sessões? (O santuário cresce, catálogo é preenchido e mapa revela novas áreas) |
| Falha/recuperação | TBD | Como falhar ensina sem quebrar o ritmo? |
| Conteúdo | Em design | Quanto conteúdo é necessário para sustentar o loop? (Biomas, variedade de animais e habitats do santuário) |
| Tutorial/onboarding | TBD | Como aprender jogando, sem instrução excessiva? |
| Santuário (Management) | Definido | Construção de habitats, gestão de comida e alocação de resgatados. |
| Catálogo e Mapa | Definido | Registro de animais encontrados, sua localização e dados de estado. |

## Controles e acessibilidade de gameplay

- Nenhuma ação essencial dependerá exclusivamente de gesto complexo sem alternativa.
- O significado não dependerá apenas de cor ou áudio.
- Feedback crítico deverá admitir combinação visual, sonora e, quando aplicável, háptica.
- Velocidade, precisão, tempo de reação e repetição serão avaliados como barreiras potenciais.
- Pausa e retomada devem ser definidas conforme o tipo de experiência.
- Remapeamento, controles alternativos e redução de movimento serão avaliados assim que plataforma e loop forem escolhidos.

## Conteúdo, narrativa e economia

Narrativa, personagens, mundo, níveis, itens, recompensas, moedas e qualquer monetização permanecem `TBD`. Nenhum deles deve ser produzido em escala antes de o core loop ser validado.

## Métricas de protótipo

- compreensão da ação central sem ajuda;
- tempo até a primeira decisão significativa;
- capacidade de descrever a emoção sentida;
- vontade espontânea de repetir uma sessão;
- erros de controle e barreiras de acessibilidade;
- desempenho e estabilidade no hardware-alvo provisório.

## Fora de escopo atual

Produção de conteúdo final, balanceamento extensivo, backend, multiplayer, monetização e narrativa longa não entram no escopo até aprovação explícita no [PROJECT.md](PROJECT.md).

