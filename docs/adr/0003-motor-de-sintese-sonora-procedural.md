# ADR 0003: Motor de Áudio Procedural Zero-Dependency com AVAudioEngine

## Status
Aprovado / Implementado

## Contexto
O jogo necessita de feedback sonoro imersivo e orgânico para os passos do jogador adaptados a diferentes superfícies (folhas, água, cascalho, capim), fluxo de rios com atenuação espacial por distância, alertas de inimigos (sirene de drones, apito de caçadores, estalar de fogo) e fanfarras de vitória/metamorfose, sem adicionar dependências externas ou arquivos de áudio estáticos pesados.

## Decisão
Implementar um sintetizador sonoro procedural nativo (`SoundManager`) utilizando `AVAudioEngine`, `AVAudioPlayerNode` e `AVAudioPCMBuffer` com taxa de amostragem de 44.1 kHz.

## Consequências
- **Positivas:**
  - Zero arquivos de áudio externos ou dependências de terceiros;
  - Variações infinitas de passos com micro-modulação orgânica de tom (pitch modulation) para eliminar monotonia auditiva;
  - Atenuação espacial contínua do som da água conforme a distância matemática até o rio central ($x = -15.0$);
  - Isolamento condicional (`#if !TEST_RUNNER`) garantindo execução instantânea e determinística dos testes unitários no CI/CLI.
- **Negativas / Riscos:**
  - Pequeno overhead na alocação inicial de buffers PCM na inicialização do app (mitigado com buffers pré-alocados no `init`).
