# Game Design Document

> Status: conceito aprovado (02/09/2026) — versão 0.1 do novo GDD. Itens marcados `TBD` ainda exigem validação; decisões confirmadas orientam o protótipo 1. Substitui a fase totalmente TBD do template anterior. Não deve ser confundido com o GDD de "Guardiões dos Biomas" mantido apenas em branches de discovery anteriores.

## Visão do jogo

- **High concept:** uma tripulação alienígena cooperativa viaja a planetas desconhecidos para encontrar, estudar e resgatar vacas alienígenas — cada planeta com uma espécie própria e necessidades únicas — e depois precisa cuidar delas dentro de uma nave, dividindo tarefas simultâneas num ritmo caótico inspirado em *Overcooked*.
- **Fantasia do jogador:** fazer parte de uma tripulação alienígena responsável por explorar planetas, descobrir vacas extraordinárias, transportá-las com segurança, administrar uma nave cheia de criaturas imprevisíveis e resolver emergências em equipe.
- **Emoção durante a sessão:** urgência cooperativa, humor, descoberta, caos organizado.
- **Emoção imediatamente após a sessão:** satisfação por ter salvado/cuidado bem das vacas, apego às criaturas, vontade de tentar o próximo planeta.
- **Público principal:** pessoas que gostam de jogos cooperativos, jogos de gerenciamento, animais, humor e ficção científica leve — tipicamente jogado com outra pessoa (amigo/família). Faixa etária exata: `TBD`.
- **Gênero:** gerenciamento cooperativo em tempo real (estilo *Overcooked*) com uma camada de exploração cronometrada.
- **Plataforma e contexto de uso:** macOS nativo; multiplayer local cooperativo — cada jogador no seu próprio Mac, mesma rede local (protótipo 1). Ver [PROJECT.md](PROJECT.md).

## Pilares de design

### 1. Caos cooperativo com propósito
Cada tarefa simultânea dentro da nave existe para forçar comunicação e priorização entre os jogadores, não para gerar dificuldade aleatória.
**Teste:** duas pessoas jogando conseguem descrever quem fez o quê e por quê, sem ficarem confusas sobre sobreposição de tarefas.

### 2. Apego às vacas
Cada vaca deve ter personalidade e necessidades legíveis o suficiente para gerar afeto, não ser apenas um medidor abstrato.
**Teste:** uma pessoa consegue descrever a personalidade e as necessidades da vaca que cuidou, sem consultar um texto de ajuda.

### 3. Ritmo claro entre explorar e cuidar
A alternância entre exploração cronometrada (fora da nave) e gerenciamento cooperativo (dentro da nave) deve ser sempre compreensível sem tutorial extenso.
**Teste:** uma pessoa nova entende em qual fase do loop está e o que precisa fazer sem perguntar.

Pilares adicionais podem ser propostos conforme o protótipo revelar novas necessidades; qualquer pilar novo deve seguir o mesmo formato de teste observável.

## Core loop

1. Escolher planeta e preparar nave/equipamentos.
2. Viajar até o planeta.
3. Explorar o planeta com tempo limitado: procurar pistas, seguir rastros, estudar o comportamento da vaca.
4. Capturar ou resgatar a vaca (cooperando para transportá-la, se necessário).
5. Retornar à nave antes que o tempo termine.
6. Receber o relatório da missão (quanto melhor o resultado, maior a recompensa).
7. Colocar a vaca em um habitat funcional na nave.
8. Cuidar das necessidades da vaca cooperativamente (alimentar, limpar, medicar) enquanto outras tarefas/eventos acontecem.
9. Ganhar recursos e comprar melhorias.
10. Desbloquear novos planetas e repetir.

**Escopo do protótipo 1:** uma única passada do loop — um planeta, uma vaca, sem melhorias nem repetição do "plano de viagem". Ver seção de escopo mais abaixo.

Se os jogadores voltarem à nave dentro do prazo, levam a vaca encontrada e recebem a recompensa cheia. Se não voltarem a tempo, a consequência exata (voltar sem a vaca, com penalidade de recompensa, ou outra consequência) é `TBD` — precisa ser decidida e testada no protótipo.

## Estrutura da sessão

- Tempo para entender a primeira ação: alguns minutos, sem tutorial extenso (meta a validar no protótipo).
- Duração-alvo de uma missão (explorar + cuidar): `TBD`.
- Duração-alvo de uma sessão completa (quantas missões): `TBD`.
- Condição de início: escolher planeta e embarcar.
- Condição de término: retorno da missão (com ou sem a vaca) + relatório.
- Pausa, retomada e salvamento: `TBD`.
- Progressão entre sessões: recursos e melhorias acumulados, novos planetas desbloqueados.

## Sistemas

| Sistema | Estado | Descrição / pergunta de discovery |
| --- | --- | --- |
| Movimento/controle | Confirmado (alto nível) | Movimentação 2D dos alienígenas no planeta e na nave; interação com objetos e estações de cuidado. Mapeamento exato de teclas: `TBD`. |
| Desafio | Confirmado (alto nível) | Timer de exploração no planeta + múltiplas necessidades da vaca (fome, limpeza, saúde) degradando ao mesmo tempo dentro da nave. |
| Feedback | TBD | Como comunicar rapidamente qual necessidade de qual vaca é mais urgente (visual, sonoro, ambos). |
| Progressão | Confirmado (alto nível) | Relatório de missão → recursos → melhorias (ferramentas, habitats, tempo, medicação, limpeza) → novos planetas. |
| Falha/recuperação | TBD | O que exatamente acontece ao não voltar a tempo, ou se uma vaca pode ser perdida permanentemente. |
| Conteúdo | Confirmado (protótipo 1) | 1 planeta, 1 espécie de vaca no protótipo 1; mais planetas/vacas são visão de longo prazo (ver brainstorm de planetas no histórico do projeto). |
| Tutorial/onboarding | TBD | Aprender jogando, sem tela de texto longa — a ser validado no playtest do protótipo. |

## Cooperação

- Protótipo 1: 2 jogadores, cada um em seu próprio Mac, conectados pela mesma rede local (ver ADR 0002 em `docs/adr/`).
- Visão de longo prazo: 1–4 jogadores (`TBD` validar).
- Modo solo: `TBD` — não faz parte do escopo do protótipo 1.
- Tarefas que exigem obrigatoriamente dois jogadores (ex.: transportar uma vaca grande): `TBD`, a definir durante a implementação do protótipo.

## Controles e acessibilidade de gameplay

- Nenhuma ação essencial dependerá exclusivamente de gesto complexo sem alternativa.
- O significado não dependerá apenas de cor ou áudio — necessidades da vaca devem ter indicação visual e textual/iconográfica, não só cor.
- Feedback crítico deverá admitir combinação visual, sonora e, quando aplicável, háptica.
- Velocidade, precisão, tempo de reação e repetição serão avaliadas como barreiras potenciais, dado o ritmo acelerado do gênero.
- Pausa e retomada devem ser definidas conforme o tipo de experiência (sessão cooperativa em tempo real dificulta pausa unilateral — `TBD`).
- Remapeamento, controles alternativos e redução de movimento serão avaliados assim que o protótipo validar o loop.

## Conteúdo, narrativa e economia

Narrativa é leve e não é o foco — tom de humor absurdo e caos cósmico cooperativo. Planetas e espécies de vacas têm identidade visual e comportamental própria (brainstorm inicial documentado no histórico do projeto; nenhum planeta além do primeiro está confirmado para o protótipo 1). Economia interna (recursos, melhorias) é parte do core loop de longo prazo, mas fora do escopo do protótipo 1. Sem monetização.

## Métricas de protótipo

A hipótese principal — combinar exploração cronometrada com gerenciamento cooperativo cria uma experiência divertida, caótica e memorável — é considerada validada quando os jogadores:

- entendem o ciclo sem explicações extensas;
- cooperam espontaneamente e comunicam prioridades;
- se divertem durante o caos;
- demonstram apego ou interesse pelas vacas;
- entendem as necessidades dos animais sem consultar ajuda;
- querem jogar outra missão ou descobrir novos planetas/espécies.

## Fora de escopo atual

Produção de múltiplos planetas/espécies, melhorias compráveis, balanceamento extensivo, backend online, multiplayer pela internet (fora da mesma rede local), monetização, narrativa longa e modo single-player não entram no escopo do protótipo 1.
