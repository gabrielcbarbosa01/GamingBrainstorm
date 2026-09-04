# 0003 — Discovery "Turno da Noite" (cozy horror, iPhone como controle)

## Status

Discovery em branch própria (`discovery/turno-da-noite`), 04/09/2026. **Não é decisão de pivô.** Nada da `main` muda até um playtest e uma decisão registrada.

## Contexto

Surgiu um conceito novo, distinto do aprovado em `main`: jogo 3D em primeira pessoa, hotel em tom cozy horror, policial infiltrada na limpeza, mecânicas físicas de limpar usando o iPhone como controle de movimento, co-op entre Macs. A regra do repositório pede que hipóteses vivam em branches de discovery e só virem requisito depois de validadas.

## Opções consideradas para prototipar

**Renderer 3D no macOS**
1. RealityKit — nativo, ECS, integra com SwiftUI via `RealityView`, suportado em macOS 15+. SceneKit foi depreciado na WWDC25. Escolhido.
2. SceneKit — descartado por depreciação.
3. Metal puro — custo alto demais para discovery.

**iPhone → Mac (controle)**
1. Network.framework, UDP + Bonjour — latência baixa para 60 Hz, sem servidor, campo de IP manual como reserva. Escolhido.
2. MultipeerConnectivity — funciona, mas com mais overhead para stream contínuo.
3. Servidor WebSocket — infraestrutura sem ganho na mesma rede.

**Mac ↔ Mac (co-op)**
1. MultipeerConnectivity — mesmo padrão já usado no repositório. Escolhido para o slice.
2. GameKit — só se for necessário jogar por internet.

**Máscara de sujeira**
1. `LowLevelTexture` do RealityKit atualizada por blit Metal a partir de um buffer na CPU. Escolhido.
2. Regenerar `TextureResource` de uma `CGImage` por frame — caro.

## Decisão (nível discovery)

Prototipar em `Turno/` com dois alvos: `TurnoMac` (RealityKit + SwiftUI) e `TurnoControle` (iOS, CoreMotion + Network.framework). Protocolo compartilhado em `Turno/Shared/Packets.swift`. Tudo isolado atrás de classes pequenas (`ControllerServer`, `CoopSession`, `DirtMask`) para poder trocar.

## Consequências

- Precisa de iPhone físico para validar a sensação do rodo; o simulador não tem sensores.
- No macOS 15+, o app pede permissão de rede local (Bonjour). Sem ela, a descoberta automática falha e sobra o IP manual.
- O modo `TURNO_CAPTURE=1` roda o turno inteiro sem tela e gera PNGs, servindo como teste de integração do slice.
- Se o conceito for aprovado, `PROJECT.md`, `GDD.md`, `DESIGN.md`, `SDD.md` e `APPLE_TECHNOLOGIES.md` da `main` precisam de revisão completa via novo ADR.
