# Guardiões dos Biomas

Jogo de exploração e conservação ambiental sobre cinco animais brasileiros ameaçados de extinção e a lendária Harpia Real.
Aplicativo nativo macOS em SwiftUI com motor SceneKit 3D em projeção **2.5D Isométrica**, com áudio procedural e geração dinâmica de mundo.

## A ideia

Você é guardiã(o) de campo. Explora os biomas brasileiros em um mundo contínuo, registra vestígios ecológicos, liberta animais presos, abre aceiros contra o fogo, corta redes de pesca clandestinas e recupera áreas degradadas. Cada bioma apresenta desafios ecológicos inspirados em ameaças reais.

| Bioma | Animal | Amuleto / Forma | Travessia & Habilidade | Desafio Central |
|---|---|---|---|---|
| Mata Atlântica | Mico-leão-dourado | Amuleto da Copa | Salto e escalada nas copas | **Travessia da copa & Corredor**: Restauração da conectividade biológica |
| Cerrado | Lobo-guará | Amuleto da Campina | Disparada ágil e rasante | **Aceiro contra o fogo & Rodovias**: Conter queimadas no capim seco |
| Pantanal | Arara-azul-grande | Amuleto do Vento | Voo livre e vigilância | **Vigília dos ninhos (45s)**: Proteger manduvis de saqueadores de fauna |
| Amazônia | Pirarucu / Ariranha | Amuleto das Águas | Nado veloz e mergulho | **Malhadeiras submersas**: Cortar redes clandestinas no leito do rio |
| Pampa | Tuco-tuco / Tatu | Amuleto do Subsolo | Escavação subterrânea | **Evacuação sob o arado (45s)**: Resgatar famílias antes da lâmina avançar |
| Clímax | Harpia Real | Coroa da Harpia | Voo supremo e consagração | **Reconhecimento dos Céus**: Consagração como Guardião Supremo |

Após purificar os cinco biomas e vencer a provação da Harpia, o jogo gera **Expedições Infinitas de Monitoramento** com dificuldade escalonável.

## Controles

| Tecla | Ação |
|---|---|
| WASD / Setas | Movimentação pelo mundo |
| ESPAÇO | Interagir com pontos ecológicos, desarmar ameaças e purificar totens |
| 1 a 6 | Metamorfose rápida para formas animais desbloqueadas |
| 0 | Retornar à forma humana (obrigatório para manusear ferramentas e ninhos) |
| +/- | Zoom da câmera 2.5D isométrica |

## Fontes de verdade e Documentação

- [GDD.md](GDD.md) — Game Design Document
- [DESIGN.md](DESIGN.md) — Direção Visual e Design Tokens
- [APPLE_TECHNOLOGIES.md](APPLE_TECHNOLOGIES.md) — Tecnologias nativas Apple
- [TEST_PLAN.md](TEST_PLAN.md) — Estratégia de testes
- [docs/adr/](docs/adr/) — Architecture Decision Records
