# Turno da Noite — GDD de discovery

> Status: **hipótese em discovery** (branch `discovery/turno-da-noite`, 04/09/2026). Nada aqui substitui as fontes de verdade da `main`; esta branch existe para prototipar e testar o conceito antes de qualquer decisão de pivô.

## High concept

Um hotel acolhedor com um crime mal explicado. Você é uma policial infiltrada na equipe de limpeza do **Grand Oxford Hotel**. O turno é de verdade: vidros, corredor, quartos. A investigação acontece por baixo do turno. **Limpar bem é o seu disfarce**: cada tarefa mal feita ou cada minuto parada onde não deveria sobe a suspeita da gerente.

- **Gênero:** cozy horror em primeira pessoa, com mecânicas físicas de limpeza e dedução leve.
- **Fantasia:** ser boa no trabalho de fachada enquanto olha tudo; sentir o hotel ficar estranho conforme a sujeira sai.
- **Emoção durante:** satisfação tátil (limpar), tensão sussurrada (a gerente, o que aparece sob a sujeira).
- **Emoção depois:** "eu vi aquilo?", vontade de contar a alguém quem foi.
- **Plataforma:** macOS nativo (jogo) + iPhone (controle de movimento e "celular da policial").
- **Multiplayer:** co-op entre Macs na mesma rede; cada Mac pode ter seu iPhone. Sozinha o jogo fecha.

## O iPhone

O iPhone é a ferramenta na mão **e** o celular da personagem.

| No jogo | No iPhone |
| --- | --- |
| Olhar | Apontar o aparelho (attitude do CoreMotion). |
| Andar | Joystick virtual. |
| Rodo de vidro | Segurar na vertical e puxar de cima para baixo, faixa por faixa. Só o gesto vertical limpa. |
| Vassoura | Segurar como cabo apontando para o chão; varrer de lado a lado. Só o gesto lateral limpa. |
| Pano e spray | Segurar USAR (spray) e esfregar em círculos; várias passadas. |
| Escutar na porta | Encostar o aparelho na orelha e ficar parada. |
| Provas | Fotografar com AÇÃO quando algo aparece sob a sujeira. Ficam na aba Provas. |
| Delegado | Mensagens chegam na aba Mensagens, com vibração. |
| Sustos | Háptica forte no aparelho, luzes piscam no Mac. |

Sem sensores (simulador) ou sem iPhone, teclado e mouse fazem tudo (fallback de teste, não a experiência).

## Vertical slice implementado

- **Lugar:** 7º andar, corredor com quartos 5, 6, 7 (lacrado) e 8, elevador, janela no fim, quarto 5 aberto.
- **Turno (9 min):** limpar o vidro do fim do corredor (rodo), varrer o corredor da suíte 7 (vassoura), limpar a mesa do quarto 5 (pano).
- **Provas (4):** marca de mão do lado de fora do vidro; bituca com batom na poeira; cartão-chave da suíte 7 sob a mancha de vinho; conversa atrás da porta 7.
- **Gerente (Dona Celeste):** patrulha o corredor. Ficar parada perto da suíte 7 ou escutar na porta sob o olhar dela sobe a suspeita; limpar na frente dela baixa. Suspeita cheia = descoberta.
- **Sustos:** ao limpar 85% do vidro, as luzes piscam e uma silhueta aparece do lado de fora por 1,4 s.
- **Fim:** elevador com 2+ provas leva à dedução (3 suspeitos). Culpado: Sr. Almeida, que trocou de quarto com a vítima na véspera e entrou pela cornija.
- **Finais:** descoberta, sem provas, caso resolvido, suspeito errado.

## Pilares (com teste observável)

1. **Limpar tem que ser gostoso em 30 segundos.** Teste: a pessoa faz uma segunda faixa no vidro sem ser pedida.
2. **O trabalho é o disfarce.** Teste: a pessoa descreve que limpou "para a gerente não desconfiar" sem ler ajuda.
3. **O celular é parte do mundo.** Teste: a pessoa olha para o iPhone quando vibra e conta o que o delegado disse.

## Maior incerteza

Se o rodo no iPhone dá sensação de limpar um vidro de verdade (latência, drift de yaw, mapeamento de faixa). O modo de captura (`TURNO_CAPTURE=1`) valida a lógica; a sensação só se valida com iPhone físico na mão.

## Fora de escopo deste slice

Assets 3D/áudio externos (tudo é procedural), múltiplos andares, papéis assimétricos no co-op (camareira/limpador de vidros/porteiro), internet fora da rede local (GameKit), salvamento.
