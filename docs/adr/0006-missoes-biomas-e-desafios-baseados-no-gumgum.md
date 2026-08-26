# 6. Missões Narrativas por Bioma, Desafios Contra o Relógio, Ameaças Reais e Expedições Infinitas

Data: 2026-08-26  
Status: Aprovado  
Origem / Inspiração: Branch `testeDoGumgum`

## Contexto

A branch `testeDoGumgum` consolidou um design narrativo e ecológico aprofundado, traduzindo as ameaças e vulnerabilidades reais de cada bioma brasileiro em regras e mecânicas de jogabilidade concretas.

Os elementos principais definidos foram:
1. **Missões Específicas para os 5 Biomas**:
   - **Mata Atlântica**: Desmatamento e fragmentação. Micos isolados nas copas que não descem ao solo; missão de travessia das copas e plantio de mudas para restabelecer o corredor florestal.
   - **Cerrado**: Incêndios e queimadas no capim seco. Abrir aceiros (linhas de terra nua) em disparada à frente do fogo com o lobo-guará e resgatar animais de atropelamentos em rodovias.
   - **Pantanal**: Tráfico de animais e saque de ninhos nos manduvis centenários. Saqueadores marchando em contagem regressiva de 45 segundos; o jogador deve chegar a tempo e reassumir a forma humana para instalar a proteção de metal com as mãos.
   - **Amazônia**: Pesca predatória com malhadeiras ilegais estendidas no leito do rio que aprisionam pirarucus e botos, impedindo-os de subir para respirar; corte de malhas na forma aquática submersa.
   - **Pampa**: Avanço da monocultura com arados pesados que soterram galerias de tuco-tucos e tatus nas dunas costeiras; evacuação de tocas subterrâneas contra o relógio de 45 segundos.
2. **Provação Clímax da Harpia Ancestral**:
   - Após purificar os 5 totens e deter as ameaças, a Harpia (Gavião-Real) desce majestosamente ao vale e consagra o jogador como Guardião Supremo.
3. **Expedições Infinitas de Monitoramento**:
   - Sistema de missões procedurais pós-campanha para manter o engajamento contínuo (Censo, Operação Resgate, Mutirão de Restauro, Contenção de Ameaças).

## Decisão

1. **Modelagem de Missões e Objetivos (`StoryQuest.swift`)**:
   - Criados os tipos de objetivo `.rastro`, `.canopyCrossing`, `.fireBreak`, `.nestWatch`, `.netCutting`, `.burrowEvacuation`, `.restoration`, `.roadRescue` e `.expedition`.
   - Adicionado suporte a contagem regressiva ativa (`timeLimitSeconds: Double?`, `countdownTimer: Double?`).

2. **Motor Narrativo e Desafios (`StoryEngine.swift`)**:
   - Implementadas as 5 cadeias de história completas correspondentes a cada bioma mais o epílogo da Harpia.
   - Loop de IA com simulação em tempo real de contagem regressiva para ameaças ativas (saqueadores marchando e arados mecânicos).
   - Gerador de expedições infinitas procedurais com dificuldade escalonável.
   - Método `disarmThreat` com validação de habilidades animais específicas e necessidade de forma humana para proteção física de ninhos.

3. **Apresentação em 3D e HUD (`WorldExploration3DView.swift`)**:
   - Modelagem 3D das novas ameaças: `nestPoacher` (saqueador com caixa de transporte e anel de alerta), `chainsawCrew` (madeireiro com motosserra), `malhadeiraNet` (malha submersa com boias ciano no rio), `plowTractor` (trator agrícola com lâmina de aço) e `harpia_ancestral` (águia colossal com envergadura dourada).
   - Banner animado no topo do HUD com contagem regressiva e barra de progresso quando um desafio contra o relógio está ativo.
   - Banners contextuais no rodapé do HUD com indicação de tecla `[Espaço]` priorizando o alvo mais próximo entre Totens, Ameaças, Animais e NPCs.

4. **Efeitos Sonoros Dedicados (`SoundManager.swift`)**:
   - Síntese procedural de ruído de motosserra (`playChainsaw`), estalo de corte de lâmina (`playNetCut`) e tique-taque de relógio (`playTimerTick`).

## Consequências

### Positivas
- Total fidelidade à visão conceitual e biológica detalhada na branch `testeDoGumgum`.
- Dinâmica de jogo mais tensa e variada com desafios contra o relógio.
- Ciclo de vida infinito do jogo através das expedições pós-história.
- 100% de compatibilidade com os testes automatizados existentes e arquitetura SwiftUI + SceneKit.

### Negativas / Mitigações
- Múltiplos sistemas interagindo simultaneamente mitigados por priorização de distância euclidiana para evitar sobreposição de ações de interação.
