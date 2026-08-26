# 9. Sistema de Sprites 2D Billboard Procedurais para Estética 2.5D Autêntica

Data: 2026-08-26  
Status: Aprovado  

## Contexto

Em jogos com apresentação 2.5D autêntica (*Paper Mario*, *Don't Starve*, *Cult of the Lamb*, *Ragnarok Online*), o mundo combina dois pilares visuais:
1. Um ambiente tridimensional para o solo, relevo, cursos d'água, iluminação solar dinâmica com sombras em tempo real e névoa de profundidade.
2. Elementos interativos, construções, portais, totens, personagens e inimigos representados como **planos verticais 2D (*billboards*)** que ficam em pé no chão e giram suavemente para encarar a câmera (`SCNBillboardConstraint(freeAxes: .Y)`), projetando sombras físicas no solo.

O usuário perguntou: *"Os objetos que estao em 3d deveriam ser como arvores, assets 2d para manter a estetica desejada de 2.5d. Teria como fazer isto ou eu precisaria incluir os assets?"* e aprovou a implementação da arquitetura procedural sem necessidade de inclusão manual de arquivos de imagem.

## Decisão

1. **Criação da Fábrica de Sprites 2D (`Sprite2DFactory.swift`)**:
   - Criação de um renderizador bitmap de alta resolução em tempo de execução utilizando `CGContext` do CoreGraphics com canal alfa (transparência).
   - Métodos dedicados para cada entidade do jogo:
     - `portalImage(for: BiomePortal)`: Arcos monumentais com runas entalhadas, vórtice de energia na cor do bioma e musgos.
     - `workshopImage()`: Oficina de campo com telhado cerâmico de terracota, bancada de carpinteiro com ferramentas e baú.
     - `fishingDockImage()`: Píer sobre estacas, água límpida, tábuas de madeira, cabeços de corda náutica, vara de pescar e boia.
     - `seedlingBedImage(index:)`: Canteiros de madeira de lei com terra escura adubada e brotos de mudas nativas com folhas verdes.
     - `harpiaAltarImage()`: Altar ancestral de pedra com asas cerimoniais entalhadas e disco solar de ouro.
     - `totemImage(for: BiomeTotem)`: Totem com runas sagradas e olhos brilhantes da entidade guardiã (verde esmeralda quando purificado).
     - `enemyImage(for: WorldEnemy)`: Motosserra com tora, labaredas ardentes, saqueador com gaiola, rede de pesca com boias, trator com lâmina de arado e drone com lente infravermelha.
     - `fieldSignImage()`: Placa de madeira entalhada sobre postes duplos com moldura e linhas de texto educativo.
     - `npcImage(for: GameNPC)`: Pesquisador de campo com colete verde, bolsos utilitários, chapéu de expedição e balão de conversa.
     - `landmarkImage(id:)`: Estação das copas suspensa, tenda dos brigadistas, manduvi centenário com caixa de ninho artificial.
   - **Cache em Memória**: `[String: NSImage]` evitando renderização repetida do mesmo bitmap.
   - **Suporte a Custom Assets**: Verifica previamente se existe uma imagem com a chave no `Assets.xcassets` (`NSImage(named:)`), permitindo substituição imediata por arte externa quando desejado.

2. **Conversão de Objetos para `SCNPlane` Billboard**:
   - Substituição das geometrias 3D sólidas (`SCNBox`, `SCNCylinder`, etc.) por planos verticais (`SCNPlane`) posicionados na altura `height / 2`.
   - Aplicação de `SCNMaterial` com `diffuse.contents = image`, `transparent.contents = image` e `isDoubleSided = true`.
   - Aplicação de `makeYBillboard()` (`SCNBillboardConstraint` com `freeAxes: .Y`) e `castsShadow = true`.
   - Preservação do relevo cônico, do rio plano, da praça de paralelepípedos e das partículas mágicas dos portais.

## Consequências

### Positivas
- Estética 2.5D unificada e consistente em todo o jogo: personagens, árvores, portais, oficina, cais, canteiros, totens e inimigos comportam-se como ilustrações 2D vivas em um mundo 3D com iluminação e sombras.
- Zero dependência de assets rasterizados externos: o jogo compila e roda imediatamente sem necessidade de arquivos PNG incluídos pelo usuário.
- Flexibilidade total: caso o usuário deseje incluir ilustrações personalizadas no futuro, basta adicioná-las ao asset catalog com os identificadores padrão.
- 13/13 testes unitários passando (`✅ [PASS]`).
- Compilação macOS verificada com sucesso no Xcode (`** BUILD SUCCEEDED **`).
