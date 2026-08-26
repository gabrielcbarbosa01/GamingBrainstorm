# 5. Ciclo Dia/Noite, Clima Dinâmico, Mini-Mapa Radar, Fauna Silvestre Livre e Santuário 3D

Data: 2026-08-25  
Status: Aprovado

## Contexto

Após a consolidação da exploração em 3D de mundo aberto contínuo e a introdução da narrativa e mecânicas de furtividade, era necessário elevar o nível de polimento visual, consciência espacial e enriquecimento ecológico da experiência.

Os novos pilares requeridos foram:
1. **Ciclo Dia/Noite e Clima**: Transição orgânica da iluminação solar e sistemas de partículas de clima para cada bioma (chuva tropical, névoa, calor e vagalumes noturnos).
2. **Mini-Mapa/Radar Tático**: Consciência espacial em tempo real no HUD mostrando o Guardião, Totens Ancestrais, rotas de patrulha dos inimigos, rio e amigos.
3. **Fauna Silvestre Livre**: Presença viva de animais nativos não-jogáveis (araras, capivaras, borboletas, tatus e emas) com comportamento de fuga orgânica quando ameaçados.
4. **Santuário 3D Interativo**: Visualização tridimensional dos recintos construídos e dos animais resgatados descansando e se alimentando.
5. **Trilha Sonora Procedural Dinâmica**: Síntese de acordes e ambiências musicais harmônicas nativas por bioma via `AVAudioEngine`.
6. **Atalhos Numéricos**: Metamorfose instantânea mapeada para as teclas `1` a `6` e `0` (humano).

## Decisão

1. **Ciclo Dia/Noite (`TimeOfDay.swift`)**:
   - Quatro fases: *Aurora*, *Meio-Dia*, *Entardecer* e *Noite*.
   - A luz solar (`SCNLight.directional`) e o céu ajustam cores, ângulos e sombras dinamicamente.
   - À noite, bônus de furtividade para a *Onça-Pintada* e o *Lobo-Guará* reduz a distância de detecção de inimigos.

2. **Mini-Mapa Radar (`MiniMapRadarView.swift`)**:
   - Renderizado em SwiftUI com bússola, marcadores de totens (verde para purificados, roxo para corrompidos), cones de alerta de inimigos e traçado do rio.

3. **Fauna Silvestre Livre (`AmbientFaunaEngine.swift`)**:
   - População de animais selvagens dispersos pelo mapa com perambulação suave e leashing em torno do bioma de origem.
   - Quando o jogador ou patrulhas se aproximam (raio < 20m), os animais entram em estado de fuga (`isScattering`), servindo como indicador tático de perigo.

4. **Santuário 3D (`Sanctuary3DView.swift`)**:
   - Cena SceneKit dedicada com recintos, abrigos de madeira, lago central e animais resgatados perambulando em tempo real.

5. **Trilha Sonora Procedural (`SoundManager.swift`)**:
   - Síntese de ondas harmônicas com afinações modais (pentatônica para Amazônia, violas para Caatinga e Cerrado, acordes aquáticos para Pantanal).

6. **Atalhos Numéricos (`MainGameView.swift`)**:
   - Mapeamento das teclas `1` (Mico), `2` (Lobo), `3` (Tatu), `4` (Onça), `5` (Ariranha), `6` (Tamanduá) e `0` (Humano).

## Consequências

### Positivas
- Aumento drástico na imersão e na sensação de um mundo vivo e pulsante.
- Feedback tático claro no HUD sem poluição visual.
- Acessibilidade e agilidade na jogabilidade com atalhos numéricos diretos.
- Zero dependência de bibliotecas ou arquivos de áudio pesados de terceiros.

### Negativas / Mitigações
- Custo de renderização adicional no SceneKit mitigado com reuso de geometrias, transições por `SCNTransaction` e timers espaçados para IA ambiental.
