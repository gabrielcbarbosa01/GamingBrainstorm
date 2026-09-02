# 0002 — Tecnologias candidatas para o protótipo 1

## Status

Proposto para protótipo descartável — não é uma consolidação arquitetural definitiva. 02/09/2026.

## Contexto

O protótipo 1 (ver escopo no [GDD.md](../../GDD.md)) precisa de: uma cena 2D com múltiplos atores em movimento simultâneo (jogadores, vaca, estações de cuidado) e uma forma dos dois jogadores — cada um em seu próprio Mac, na mesma rede local — cooperarem em tempo real sem depender de infraestrutura de servidor. O processo de seleção do [APPLE_TECHNOLOGIES.md](../../APPLE_TECHNOLOGIES.md) pede um spike no hardware relevante antes de registrar uma decisão; para o protótipo 1, o time optou por decidir as candidatas mais prováveis primeiro e validar via o próprio protótipo jogável, dado o prazo do Final Challenge.

## Opções consideradas

**Renderer de gameplay:**
1. SpriteKit — renderer 2D nativo da Apple, integra com SwiftUI, adequado a cenas com múltiplos sprites e física simples.
2. RealityKit/Metal — poder e complexidade desnecessários para uma experiência 2D.

**Camada de rede para co-op local:**
1. MultipeerConnectivity — framework nativo da Apple para descoberta e conexão par-a-par entre dispositivos próximos (Wi-Fi/Bluetooth), sem servidor. Adequado quando os jogadores estão na mesma rede/local físico, que é a premissa confirmada do protótipo 1.
2. GameKit — pensado para matchmaking e multiplayer via internet/Game Center; exigiria contas e infraestrutura desnecessárias para validar o loop cooperativo local.
3. Servidor próprio (ex.: WebSocket) — infraestrutura adicional sem benefício claro para dois Macs na mesma rede.

## Decisão

Para o protótipo 1: **SpriteKit** como renderer da cena de exploração e da cena da nave/habitat, e **MultipeerConnectivity** como camada de rede para sincronizar o estado compartilhado (posição dos jogadores, estado da vaca, estado do habitat) entre os dois Macs.

Ambas as escolhas ficam isoladas atrás de limites do [SDD.md](../../SDD.md) (`Rendering` e `Networking`) para permitir troca sem reescrever o domínio do jogo, caso o spike revele problemas de desempenho, sincronização ou escala.

## Consequências

- Não substitui a necessidade de um spike de desempenho e sincronização antes de qualquer consolidação em produção — esta decisão vale para um protótipo descartável.
- Multiplayer pela internet (jogadores em redes diferentes) fica fora do escopo do protótipo 1; se vier a ser necessário, exigirá reavaliar GameKit ou um servidor próprio em um novo ADR.
- APPLE_TECHNOLOGIES.md foi atualizado para refletir estas candidatas.
