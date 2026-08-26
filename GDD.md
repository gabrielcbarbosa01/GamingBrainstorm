# Game Design Document

> Status: discovery. Todo conteúdo marcado `TBD` exige validação antes de orientar implementação.

## Visão do jogo

- High concept: Um jogo de aventura e gerenciamento 3D onde o jogador explora biomas brasileiros em mundo aberto, assumindo a forma de animais ameaçados para investigar perigos e resgatá-los para o santuário.
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
| Movimento/controle | Definido | Navegação suave no mapa contínuo, D-Pad, WASD e atalhos rápidos [1-6 e 0] para metamorfose. |
| Desafio | Definido | Evasão furtiva de patrulhas de caçadores e drones, combate a focos de queimada e gestão de energia. |
| Feedback | Definido | Áudio procedural adaptativo por superfície, mini-mapa radar com cones de alerta e notificações dinâmicas. |
| Atmosfera e Clima | Definido | Ciclo Dia/Noite com bônus de furtividade noturna e sistemas de partículas de clima por bioma. |
| Fauna Silvestre Livre | Definido | Animais livres perambulando pelo mapa com comportamento de fuga ao detectar ameaças. |
| Santuário (Management) | Definido | Construção e aprimoramento de habitats, visualização interativa 3D e reabilitação de espécies. |
| Catálogo e Mapa | Definido | Registro de animais encontrados, sua localização e dados de estado. |

## Controles e acessibilidade de gameplay

- Nenhuma ação essencial dependerá exclusivamente de gesto complexo sem alternativa.
- O significado não dependerá apenas de cor ou áudio.
- Feedback crítico deverá admitir combinação visual, sonora e, quando aplicável, háptica.
- Velocidade, precisão, tempo de reação e repetição serão avaliados como barreiras potenciais.
- Pausa e retomada devem ser definidas conforme o tipo de experiência.
- Remapeamento, controles alternativos e redução de movimento serão avaliados assim que plataforma e loop forem escolhidos.

## Conteúdo, narrativa e economia

- **Enredo & Missão Central:** O "Consórcio Devastador" ameaça extinguir o equilíbrio ecológico dos 6 biomas brasileiros instalando maquinário predatório, queimadas descontroladas e caçadores ilegais. Muri, o Guardião da Floresta, deve viajar pelos biomas, purificar os 6 Totens Ancestrais e resgatar espécies da fauna nacional.
- **Personagens Aliados (NPCs):**
  - *Muri (Guardião Metamorfo):* Protagonista que adquire habilidades animais.
  - *Poti (Arara-Canindé):* Guia aéreo da Amazônia e mensageiro da floresta.
  - *Seu Bento (Guardião Caatingueiro):* Ancião do sertão e mestre das plantas xerófilas.
  - *Mãe da Mata (Espírito Ancestral):* Entidade milenar da Mata Atlântica e guardiã dos totens.
  - *Dra. Flora (Bióloga do Santuário):* Pesquisadora do Cerrado especializada em reabilitação de fauna.
- **Inimigos & Ameaças:**
  - *Caçadores Ilegais (Poachers):* Patrulham com lanternas; evitados com Camuflagem ou Passo Furtivo.
  - *Drones de Vigilância:* Sensores aéreos com feixe de luz vermelha; neutralizados ou evitados com Faro Rastreador e Voo.
  - *Focos de Queimada (Wildfire Entities):* Labaredas agressivas que drenam energia humana; extintas com a habilidade de Nado da Ariranha.
  - *Escavadeiras Predatórias (Timber Harvesters):* Maquinário pesado derrubando árvores; desativadas com Garras Rompedoras.
- **Totens Ancestrais:** 6 obeliscos de energia telúrica (1 por bioma) que precisam ser purificados para recuperar o florescimento da fauna e flora.

## Métricas de protótipo

- compreensão da ação central sem ajuda;
- tempo até a primeira decisão significativa;
- capacidade de descrever a emoção sentida;
- vontade espontânea de repetir uma sessão;
- erros de controle e barreiras de acessibilidade;
- desempenho e estabilidade no hardware-alvo provisório.

## Fora de escopo atual

Produção de conteúdo final, balanceamento extensivo, backend, multiplayer, monetização e narrativa longa não entram no escopo até aprovação explícita no [PROJECT.md](PROJECT.md).

