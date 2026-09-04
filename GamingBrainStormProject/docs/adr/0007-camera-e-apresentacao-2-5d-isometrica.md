# 7. Apresentação Visual 2.5D Isométrica Ortográfica no Motor SceneKit 3D

Data: 2026-08-26  
Status: Aprovado  

## Contexto

A branch `testeDoGumgum` foi originalmente iniciada como um experimento de renderização 2D em grade de tiles via SpriteKit. No entanto, diante da maturidade do motor SceneKit 3D consolidado na branch `feat/game` — que já contava com mundo aberto contínuo de 700x700, rio plano sem inclinações, vegetação densa, fauna silvestre viva, ciclo dia/noite com clima dinâmico, áudio procedural sintetizado, santuário e todo o sistema de missões e ameaças com contagem regressiva inspiradas no Gumgum —, o usuário solicitou explicitamente:
1. A migração completa do ecossistema 3D para a branch `testeDoGumgum`.
2. A transformação da apresentação de câmera para uma **projeção 2.5D isométrica**.

## Decisão

1. **Projeção Ortográfica (`usesOrthographicProjection = true`)**:
   - A câmera do SceneKit foi configurada para projeção ortográfica pura, eliminando as linhas de fuga da perspectiva e preservando proporções geométricas constantes em toda a tela.
   - Isso confere ao mundo 3D o clássico estilo visual 2.5D isométrico consagrado em RPGs e jogos de aventura (como *Hades*, *Diablo*, *Monument Valley* e *Final Fantasy Tactics*).

2. **Modos de Ângulo 2.5D**:
   - **Isométrico Clássico (45° Diagonal)**: Inclinação de $-35.264^\circ$ ($\approx -0.615$ rad) com rotação em $Y$ de $45^\circ$ ($\approx 0.785$ rad). As grades e o terreno adquirem o padrão de losango isométrico clássico ($2:1$).
   - **Oblíquo 2.5D (Frontal Elevado)**: Inclinação de $-45^\circ$ ($\approx -0.785$ rad) com rotação em $Y$ de $0^\circ$, simulando a clássica visão de jogos de exploração 2.5D (como *The Legend of Zelda* e *Pokémon*).
   - Um alternador contextual no HUD (`[Isométrico 45°] / [2.5D Frontal]`) permite ao jogador trocar de modo instantaneamente com transição suave via `SCNTransaction`.

3. **Zoom Ortográfico**:
   - O zoom é controlado por `camera.orthographicScale` (intervalo de 14.0 a 44.0, padrão 26.0), permitindo aproximar e afastar a visão com nitidez perfeita sem qualquer distorção de distâncias focais.

4. **Billboard Constraints nos Sprites 2.5D**:
   - O nó do jogador utiliza `SCNBillboardConstraint(freeAxes: .Y)`, garantindo que o sprite 2.5D animado do personagem esteja sempre voltado diretamente para a câmera sem deformações angulares.

5. **Eliminação de Conflitos e Unificação**:
   - Foram removidos os módulos legados do SpriteKit 2D que geravam colisões de compilação (`Art/`, `Core/`, `Scenes/`, `UI/`, `World/`), unificando o projeto no ecossistema SwiftUI + SceneKit + AVAudioEngine.

## Consequências

### Positivas
- Estética 2.5D impecável: paralelismo perfeito de linhas, iluminação com sombras dinâmicas em ângulo e vegetação volumétrica em 3D.
- Controle total do enquadramento com zoom ortográfico e alternador de ângulo.
- 100% de reaproveitamento de todos os sistemas de gameplay, narrativa, áudio e santuário.
- 12/12 testes unitários passando e compilação limpa no Xcode macOS.
