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

Roda o turno inteiro com entrada roteirizada, verifica as regras (gesto errado não limpa, provas aparecem, dedução) e grava PNGs em `~/Library/Containers/com.brunamarschner.turno.mac/Data/tmp/turno-capture/`.

## Estrutura

- `Shared/Packets.swift` — protocolo UDP iPhone ↔ Mac.
- `TurnoMac/Game/` — `GameState` (domínio), `GameWorld` (cena RealityKit procedural), `GameLoop` (regras por frame), `CleaningSurface` (máscara de sujeira em `LowLevelTexture`), `Textures` (sujeira e provas desenhadas com CoreGraphics), `Story` (texto), `DebugCapture`.
- `TurnoMac/Net/` — `ControllerServer` (iPhone) e `CoopSession` (outros Macs).
- `TurnoMac/Audio/` — som procedural (zumbido, esfregar, batimento, susto).
- `TurnoControle/` — app iOS: CoreMotion, cliente UDP, joystick, mensagens e provas.
