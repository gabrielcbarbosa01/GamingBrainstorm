# Guardiões dos Biomas

Protótipo de aventura e conservação para macOS, desenvolvido em Swift. A interface usa SwiftUI e a base jogável importada da branch `testeDoGumgum` usa SpriteKit e CoreGraphics.

O jogador parte de uma base de restauração, explora biomas, investiga ameaças e manifesta formas espirituais inspiradas em animais brasileiros. O animal real permanece independente no mundo. A direção aprovada inclui seis biomas, combate de ação-RPG contra monstros de degradação ambiental e restauração persistente.

## Estado do protótipo

A branch `testeDoGumgum` fornece uma base substancial com:

- mundo procedural por chunks;
- movimentação, formas animais e habilidades de travessia;
- Refúgio Raízes, viveiro, pesca e oficina;
- missões, diálogos, códice, mapa, HUD e salvamento;
- arte procedural produzida em CoreGraphics.

Essa implementação ainda representa uma versão anterior do design, com cinco biomas e sem o sistema de combate aprovado. A fonte de verdade para a adaptação é o GDD atual, que define Mata Atlântica, Cerrado, Caatinga, Amazônia, Pantanal e Pampa.

## Fontes de verdade

| Documento | Responsabilidade |
| --- | --- |
| [PROJECT.md](PROJECT.md) | Visão, objetivos e restrições |
| [GDD.md](GDD.md) | Experiência, regras, sistemas e conteúdo |
| [DESIGN.md](DESIGN.md) | Direção visual, interface e acessibilidade |
| [APPLE_TECHNOLOGIES.md](APPLE_TECHNOLOGIES.md) | Avaliação de tecnologias Apple |
| [SDD.md](SDD.md) | Arquitetura e engenharia |
| [TEST_PLAN.md](TEST_PLAN.md) | Validação e qualidade |
| [AGENTS.md](AGENTS.md) | Instruções do repositório |

## Controles atuais

| Tecla | Ação |
| --- | --- |
| WASD / setas | Andar |
| Espaço | Habilidade da forma |
| E | Interagir ou avançar diálogo |
| 1–6 | Selecionar forma |
| Q | Voltar à forma humana |
| Tab | Códice |
| M | Mapa |
| R | Nova expedição |
| Esc | Menu |

## Executar

Abra `GamingBrainstorm/GamingBrainstorm.xcodeproj` no Xcode e execute o esquema `GamingBrainstorm` para macOS.

Pela linha de comando:

```sh
xcodebuild -project GamingBrainstorm/GamingBrainstorm.xcodeproj \
  -scheme GamingBrainstorm \
  -destination 'platform=macOS' \
  build
```
