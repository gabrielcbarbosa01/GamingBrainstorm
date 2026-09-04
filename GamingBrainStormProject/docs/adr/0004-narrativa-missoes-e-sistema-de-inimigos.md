# ADR 0004: Sistema Narrativo, Missões e Mecânicas de Inimigos e Furtividade

## Status
Aprovado / Implementado

## Contexto
O usuário solicitou incluir personagens, uma história envolvente para salvar a floresta do "Consórcio Devastador", e inimigos patrulhando que impeçam o jogador de cumprir os objetivos ecológicos.

## Decisão
1. **Modelagem (`StoryQuest.swift`):**
   - Criação de entidades decoupled `GameNPC`, `DialogueLine`, `QuestObjective`, `StoryQuest`, `WorldEnemy`, `EnemyType`, `BiomeTotem`.
2. **Motor Narrativo & IA de Patrulha (`StoryEngine.swift`):**
   - Progressão estruturada em 3 capítulos com diálogos introdutórios e de conclusão.
   - 4 NPCs aliados distribuídos pelos biomas.
   - 6 Totens Ancestrais que exigem purificação para restaurar os biomas.
   - 13 Inimigos patrulhando com raios de visão dinâmicos, cones de luz/sensores e mecânica de contramedidas via metamorfose animal (ex: *Passo Furtivo* da Onça contra Drones, *Nado Veloz* da Ariranha contra Focos de Incêndio, *Garras Rompedoras* do Tamanduá contra Escavadeiras).
3. **Apresentação SwiftUI & 3D (`StoryDialogueView.swift`, `WorldExploration3DView.swift`):**
   - Modal cinematográfico com avatar dos interlocutores, efeito sonoro e avanço de falas.
   - Rastreamento de objetivos em tempo real no HUD.
   - Renderização 3D com cones de visão, alertas visuais e sonoros.

## Consequências
- **Positivas:**
  - Encaixe perfeito com o core loop de resgate animal e exploração;
  - Utilidade direta para as habilidades de metamorfose em stealth e combate ambiental não violento;
  - 100% desacoplado e testável via testes unitários em `GameEngineTests`.
