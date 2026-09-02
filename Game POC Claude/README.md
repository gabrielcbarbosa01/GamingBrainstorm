# Protocolo Bovino — protótipo M1

Co-op caótico sobre alienígenas que acham que a vaca é a espécie dominante da Terra.
Este repositório é o **protótipo do Marco 1**: o verbo central do jogo, jogável.

O design completo (blocos 2 a 13) está em [DESIGN.md](DESIGN.md) e no
[documento de design publicado](https://claude.ai/code/artifact/d26e276c-32ab-49b4-bbea-7992e29c3f3b).

## Rodar

```bash
xcodebuild -project ProtocoloBovino.xcodeproj -scheme ProtocoloBovino -configuration Debug -destination 'platform=macOS' SYMROOT=/tmp/pb-build build && open /tmp/pb-build/Debug/ProtocoloBovino.app
```

> `SYMROOT` fora do Desktop é obrigatório: a pasta está no iCloud e a assinatura de código falha lá dentro.

Ou abra `ProtocoloBovino.xcodeproj` no Xcode e dê Run.

### Controles

| Tecla | Ação |
|---|---|
| `W A S D` | mover |
| mouse | olhar — **clique na janela para capturar**, `ESC` para soltar |
| roda do mouse | aproxima / afasta a câmera |
| `Shift` | correr — **faz barulho e sobe o alerta** |
| `C` | agachar (silencioso, lento) |
| `E` | pegar / soltar — vaca, lanterna, fardo, porteira |
| `F` | acender / apagar a lanterna |
| `R` | Alavanca de Subida (encerra a expedição, 10 s, abortável) |

A câmera é de terceira pessoa sobre o ombro, com mais curso para baixo que para cima —
é no chão que estão as vacas, a lama e o feno.

## O que já funciona

- **Carregar** é o verbo central: cinco portes, cada um com velocidade, tempo de erguida e cambaleio próprios. Sozinho sempre é possível — a Colossal a 14% da velocidade, sem correr e sem girar rápido.
- **Mãos ocupadas**: quem carrega a vaca larga a lanterna. Escuridão é mecânica, não estética.
- **Alerta é uma escada**: barulho acumula; ao estourar, a fazenda debanda, o medidor volta a 40 e a **Vigília sobe permanentemente**. Vacas em pânico atropelam.
- **Porteira**: só abre com as mãos livres. Largar a vaca, abrir, pegar de novo.
- **Lamaçal**: velocidade despenca sob peso e há chance de escorregar e derrubar.
- **Feixe de extração**: 6 s por vaca, +12 de alerta, coluna de luz visível do mapa inteiro.
- **Rebanho**: dorme, acorda, pasta, entra em pânico, contagia as vizinhas e não se atravessa.

## O que ainda não existe

Multiplayer (M2), habitat e necessidades, ordenha, cota, economia, upgrades, fazendeiro e cães,
níveis de Vigília 2–4, traços das vacas, adornos com efeito mecânico. Ver [DESIGN.md](DESIGN.md).

## Verificação headless

O app roda sem janela para inspeção e teste — útil em terminal sem sessão gráfica e em CI.

```bash
BIN=/tmp/pb-build/Debug/ProtocoloBovino.app/Contents/MacOS/ProtocoloBovino

# laço completo: erguer -> carregar -> soltar no feixe -> extrair
"$BIN" --haul

# 4 minutos correndo perto do rebanho: alerta, debandada, atropelamento
"$BIN" --soak 240

# renderiza um PNG da cena, sem abrir janela
"$BIN" --render /tmp/cena.png --daylight --cam 0 70 55 --look 0 0 -22
"$BIN" --render /tmp/campo.png --teleport -6 -22 3.14159 --seconds 2 --grab
```

Flags: `--daylight` (luz plena, para conferir escala e layout) · `--teleport x z [yaw]` ·
`--grab` (pega o que estiver ao alcance no boot) · `--facing yaw` · `--cam x y z` + `--look x y z` ·
`--seconds n` · `--width` / `--height`.

## Arquitetura

```
Packages/GameCore/     Swift puro. ZERO imports de render — o compilador garante.
  Model/               Cow, CowSize, Player, Farm, Balance, Math
  Systems/             PlayerSystem, CarrySystem, HerdSystem
  Sim/                 World (passo fixo 60 Hz), Interaction
ProtocoloBovino/       App macOS
  Presenter/           ScenePresenter (SceneKit), ProceduralAssets, AssetLoader, OfflineRenderer
  HUD/                 HUDView (SwiftUI)
  GameController       input -> simulação -> apresentação
  Assets3D/            .usdz
```

Três decisões que sustentam o resto:

1. **`GameCore` não importa nenhum framework de render.** Prototipar em SceneKit hoje (que a Apple marcou como *deprecated* na WWDC25) e migrar para RealityKit depois não toca em regra de jogo. Também permite testar tudo sem abrir janela — é o que `--haul` e `--soak` fazem.
2. **A vaca carregada não é um corpo físico.** Ela é cinemática, presa a uma âncora à frente de quem carrega; o peso é penalidade de input e o cambaleio é mola visual. Isso resolve física e, no M2, rede — juntas em rede explodiriam com latência.
3. **Passo fixo de 60 Hz na main thread**, alimentado pelo `CADisplayLink` da view. O host do multiplayer roda exatamente esta simulação.

Todos os números do design vivem em `GameCore/Model/Balance.swift`. Próximo passo natural:
mover para `Content/Balance/*.json` com hot-reload, para balancear sem recompilar.

## Créditos

Modelos 3D sob **CC-BY-4.0** (Sketchfab) — atribuição obrigatória em qualquer distribuição:

- **Cow** e **Vaca Morango** — Kyuta ([sketchfab.com/dwkyuta](https://sketchfab.com/dwkyuta))
- **Nave Espacial UFO** — olamultimedia ([sketchfab.com/olamultimedia](https://sketchfab.com/olamultimedia))
- **Alien Frank** — DavidePrestino ([sketchfab.com](https://sketchfab.com))

Cerca, porteira, lamaçal, fardo de feno, lanterna, alavanca, feixe, terreno e vegetação são
geometria procedural do projeto (`Presenter/ProceduralAssets.swift`).
