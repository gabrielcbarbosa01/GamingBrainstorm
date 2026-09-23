# ADR 0001 — Identidade de distribuição Apple

- **Status:** aceito
- **Data:** 2026-09-23

## Contexto

O scaffold da POC usava o bundle ID genérico `Gabriel-Barbosa.GamingBrainstorm` e o time `2PN93JLTQW`. Para distribuir pelo TestFlight e pela App Store, o app precisa de um bundle ID definitivo, registrado na conta Apple Developer que será dona do app.

## Opções

1. Manter o bundle ID e o time da POC.
2. Registrar um bundle ID definitivo na conta da Luísa Cecília (`6Y22927H5J`).

## Decisão

Adotar a opção 2:

- Bundle ID: `com.brainstorm.xisdrivethru`, registrado como App ID explícito.
- Team: `6Y22927H5J`.
- Assinatura: automática no Xcode, com os certificados Apple Development e Apple Distribution existentes.
- App Store Connect: registro "XIS Brainstorm" criado com a plataforma macOS.

## Consequências

- O bundle ID não pode ser alterado depois do primeiro build enviado ao App Store Connect.
- O registro no App Store Connect usa macOS porque o scaffold é macOS. Isso **não** aprova a plataforma final, que continua `TBD` no [PROJECT.md](../../PROJECT.md) e exige ADR própria. Outras plataformas podem ser adicionadas ao mesmo registro sem trocar o bundle ID.
- Capabilities, como Game Center ou iCloud, serão habilitadas no App ID somente quando uma decisão aprovada exigir.
