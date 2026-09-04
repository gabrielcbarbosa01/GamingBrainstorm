# Turno da Noite — protótipo

Vertical slice de discovery. Ver `docs/discovery/turno-da-noite/GDD.md` e `docs/adr/0003-discovery-turno-da-noite.md`.

## Rodar

```bash
cd Turno && xcodegen generate && open TurnoDaNoite.xcodeproj
```

1. Rode o alvo **TurnoMac** no Mac. Aceite a permissão de rede local se o macOS pedir.
2. Rode o alvo **TurnoControle** no iPhone (mesma rede Wi-Fi). Ele procura o Mac por Bonjour; se não achar, digite o IP do Mac.
3. No Mac, "Começar o turno". Sem iPhone: W A S D anda, setas olham, espaço ou mouse usa, E ação, Esc sai, R recalibra. No modo ferramenta o mouse move a ponta.

Co-op: abra o TurnoMac em outro Mac na mesma rede; eles se conectam sozinhos.

## Teste sem tela

```bash
TURNO_CAPTURE=1 /caminho/para/TurnoMac.app/Contents/MacOS/TurnoMac
```

Joga as cinco noites com entrada roteirizada, verifica as regras (gesto errado não limpa, as 20 provas aparecem, a escuta é interrompida quando a gerente olha, a dedução fecha em 3/3) e grava PNGs das cenas e das telas de campanha em `~/Library/Containers/com.brunamarschner.turno.mac/Data/tmp/turno-capture/`.

Para recomeçar a campanha do zero no jogo normal, use `TURNO_FRESH=1`.

## A campanha

Cinco noites no Grand Oxford. Entre elas, o vestiário: mural de provas, escolha do papel, briefing do delegado e o armário de melhorias. Ao fim da noite 5, a dedução com três perguntas.

Até quatro pessoas, cada uma em seu Mac na mesma rede, com papéis diferentes (camareira, limpadora de vidros, zelador, recepção). Cada papel é rápido na sua ferramenta e lento nas outras.

## Estrutura

- `Shared/Packets.swift` — protocolo UDP iPhone ↔ Mac.
- `TurnoMac/Game/Campaign.swift` — a campanha inteira como dados: noites, provas, papéis, melhorias, falas e a dedução.
- `TurnoMac/Game/Progress.swift` — o que sobrevive entre as noites (mural, estrelas, confiança, melhorias), salvo em JSON.
- `TurnoMac/Game/` — `GameState` (domínio), `GameWorld` + `WorldAreas` (as sete áreas em RealityKit), `GameLoop` (regras por frame), `CleaningSurface` (máscara de sujeira em `LowLevelTexture`), `Textures` (sujeira e provas em CoreGraphics), `DebugCapture`.
- `TurnoMac/Net/` — `ControllerServer` (iPhone) e `CoopSession` (outros Macs).
- `TurnoMac/Audio/` — som procedural (zumbido, esfregar, batimento, susto).
- `TurnoControle/` — app iOS: CoreMotion, cliente UDP, joystick, mensagens e provas.
