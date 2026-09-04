# 8. Reconstrução dos Cenários de testeDoGumgum e Sistema de Portais Místicos 3D

Data: 2026-08-26  
Status: Aprovado  

## Contexto

A branch `testeDoGumgum` introduziu um rico conjunto de conceitos de cenário e ambientação focados na conservação ecológica brasileira:
1. O **Refúgio Raízes** como estação central de campo com:
   - Um arco monumental de 5 portais conectando diretamente a cada um dos 5 biomas exploráveis (Mata Atlântica, Cerrado, Pantanal, Amazônia e Pampa).
   - Uma **Oficina de Campo** para manufatura de ferramentas de conservação.
   - Um **Açude com Cais de Pesca** para manejo e soltura de peixes nativos.
   - Um **Viveiro de Mudas** com 10 canteiros de cultivo de espécies reais de restauração (Juçara, Lobeira, Manduvi, Castanheira e Capim-das-dunas).
   - Um **Altar Sagrado da Harpia Ancestral** como marco cerimonial de consagração.
   - **Placas Educativas de Campo** com mensagens reais de preservação ambiental.
2. Marcos e lugares temáticos próprios em cada bioma:
   - Estação das Copas suspensa com passarela de cordas na Mata Atlântica.
   - Posto dos Brigadistas e faixa de solo raspado (aceiro de contenção) no Cerrado.
   - Árvore manduvi monumental com caixa de ninho artificial no Pantanal.
   - Lago de manejo comunitário e píer de contagem de pirarucu na Amazônia.
   - Colônia de dunas com tocas subterrâneas de tuco-tuco no Pampa.

O usuário solicitou: *"Agora imite completamente os lugares do cenario da branch testeDoGoungum, incluindo os portais. Mas a minha estética deve ser mantida."*

## Decisão

1. **Modelagem de Portais Místicos (`BiomePortal`)**:
   - Criação da estrutura de dados `BiomePortal` definindo id, nome, bioma de origem, bioma de destino, coordenadas de entrada, coordenadas de destino no bioma, cor temática emissiva e indicador de portal de retorno (`isReturnPortal`).
   - Configuração de 10 portais: 5 portais de ida dispostos em arco ao norte da praça central do Refúgio Raízes e 5 portais de retorno posicionados estrategicamente dentro de cada bioma, permitindo voltar instantaneamente à base.

2. **Arquitetura Visual 3D dos Portais**:
   - Construção com pilares colossais de pedra talhada (`SCNBox` com chanfro), lintel superior unindo os pilares e base de sustentação.
   - **Anel de Energia Mística**: Toro (`SCNTorus`) levitando verticalmente no vão do portal com material emissivo na cor temática do bioma e animação contínua de rotação em $Z$.
   - **Vórtice Translúcido Interno**: Disco (`SCNCylinder`) com transparência e pulsação cíclica de escala.
   - **Sistema de Partículas**: Emissor de partículas volumétricas (`SCNParticleSystem`) emitindo faíscas brilhantes flutuantes na cor do bioma.

3. **Construção 3D dos Locais do Refúgio Raízes**:
   - **Praça Central**: Pátio circular de paralelepípedos com borda de pedra polida e tochas ornamentais em quatro quadrantes com chamas pulsantes.
   - **Placa Memorial de Campo**: Placa rústica de madeira lavrada sobre estacas cilíndricas: *"Refúgio Raízes — estação de campo. Aqui você está seguro."*
   - **Oficina de Campo**: Estrutura de madeira com 4 pilares, telhado cerâmico de duas águas em terracota, bancada de carpinteiro e baú de suprimentos.
   - **Cais do Açude de Pesca**: Lago límpido lívido com deck de madeira estendido e cabeços de amarração.
   - **Viveiro de Mudas**: 10 canteiros de madeira de lei com solo escuro adubado e brotos verdes cônicos em crescimento.
   - **Altar Sagrado da Harpia**: Pedestal de pedra de 3 níveis com monólito cerimonial.

4. **Marcos e Lugares nos Biomas**:
   - Dossel elevado com pilares e passarela nas copas da Mata Atlântica.
   - Tenda piramidal de campanha e aceiro de contenção no solo no Cerrado.
   - Tronco colossal de manduvi com caixa de ninho artificial no Pantanal.
   - Píer flutuante de manejo comunitário na Amazônia.
   - Montículos cônicos de areia nas galerias de dunas do Pampa.

5. **Interatividade e Áudio**:
   - Integração com `interactWithNearbyPoint()`: ao se aproximar de qualquer portal, o banner de ação no HUD exibe o nome e a descrição do destino, permitindo teletransporte imediato pressionando `[Espaço]` ou clicando no botão.
   - Síntese procedural de áudio `playPortalTeleport()` via `AVAudioEngine`, gerando acorde místico pentatônico ascendente com efeito de transição espacial.

## Consequências

### Positivas
- Fidelidade total a 100% dos lugares, conceitos de conservação e mecânica de portais concebidos em `testeDoGumgum`.
- Preservação integral da estética visual 3D rica (iluminação solar, sombras dinâmicas, ciclo dia/noite, névoa atmosférica e materiais PBR).
- Navegação instantânea e fluida entre o Refúgio Raízes e qualquer região do mapa de 700x700 unidades.
- 13/13 testes unitários passando (`✅ [PASS]`).
- Compilação macOS verificada sem erros no Xcode (`** BUILD SUCCEEDED **`).
