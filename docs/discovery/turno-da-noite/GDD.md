# Turno da Noite — GDD de discovery

> Status: **hipótese em discovery** (branch `discovery/turno-da-noite`). Nada aqui substitui as fontes de verdade da `main`; esta branch existe para prototipar e testar o conceito antes de qualquer decisão de pivô.

## High concept

Um hotel acolhedor com um crime mal explicado. Até quatro policiais entram disfarçados na equipe de limpeza do **Grand Oxford Hotel** e têm **cinco noites** antes de o hotel ser vendido. O turno é de verdade: vidros, corredores, quartos, porão. A investigação acontece por baixo do turno.

**Limpar bem é o disfarce.** A sujeira esconde as provas: só aparece o que você tira. E ficar parada onde não devia, à vista da gerente, é o que te entrega.

- **Gênero:** cozy horror em primeira pessoa, com mecânicas físicas de limpeza e dedução.
- **Emoção durante:** satisfação tátil, tensão de timing, descoberta.
- **Emoção depois:** vontade de contar a alguém quem foi.
- **Plataforma:** macOS nativo + iPhone como controle de movimento e celular da personagem.
- **Multiplayer:** até quatro pessoas, cada uma no seu Mac, na mesma rede. Sozinha a campanha fecha, com mais noites.

## A história

Heitor Vilar, perito de seguros, morreu na suíte 7. A gerência chamou de infarto e barrou a perícia.

| Noite | Título | Onde | O que acontece |
| --- | --- | --- | --- |
| 1 | O sétimo andar | corredor, quarto 5, fachada | A marca de mão do lado de fora, no sétimo andar. Alguém limpa o vidro à noite. |
| 2 | O livro de registro | lobby, corredor | A página arrancada, a gôndola alugada e devolvida sem sair do lugar, a chave de um oitavo andar que não existe. |
| 3 | A suíte 7 | suíte 7, fachada | O crachá arrebentado, os arranhões na cornija e uma palavra escrita por dentro do espelho. |
| 4 | O porão | lavanderia, incinerador | O uniforme queimado de 1974, a planta com oito andares, o livro de ponto com quatro saídas em branco. |
| 5 | O oitavo andar | andar lacrado | O carrinho de Osvaldo, a gôndola ainda pendurada, o contrato e a apólice que Vilar ia negar. |

**A verdade:** Almeida é coproprietário oculto. A venda só fecha com a apólice aprovada, e Vilar ia negá-la por causa do oitavo andar selado depois do incêndio de 1974. Almeida trocou de quarto com ele na véspera, saiu pela janela do 5, andou pela cornija e entrou na 7. Celeste escondeu tudo porque a mãe dela morreu no 803 e o hotel é o que sobrou dela. Osvaldo, o limpador de vidros que caiu naquela noite, continua limpando as janelas.

## Os quatro papéis

| Papel | Ferramenta rápida | Acesso natural |
| --- | --- | --- |
| Camareira | pano e spray | quartos e suítes |
| Limpadora de vidros | rodo | fachada, gôndola, o que se vê de fora |
| Zelador | vassoura e esfregão | porão, lavanderia, casa de máquinas |
| Recepção | flanela de lustrar | balcão, livro de registro, telefone |

Cada papel rende 100% na sua ferramenta, 62% na secundária e 40% nas outras. Com quatro pessoas, uma noite cobre tudo. Sozinha, você escolhe o que importa. As provas que ficaram para trás continuam lá.

## Mecânicas

**Limpeza.** Cada superfície tem uma máscara de sujeira que some onde a ferramenta passa. O gesto precisa bater: o rodo só limpa na vertical, a vassoura só na horizontal, o pano e a flanela pedem passadas repetidas. Sob a sujeira pode haver uma prova, que só aparece quando 60% da área dela está limpa.

**Suspeita.** Dona Celeste faz ronda. Ela te vê se você estiver na frente dela, a menos de 8 m, e fora de um esconderijo. Trabalhando, a suspeita cai; parada perto de uma porta lacrada, sobe. Cheia, você é descoberta e perde a noite. Sem ninguém olhando, ela esfria sozinha.

**Esconderijos.** Dentro dos quartos, na gôndola, atrás do balcão e ao lado do incinerador ela não te enxerga.

**Escutas e conversas.** Escutar atrás da porta 7 ou ouvir a secretária eletrônica leva alguns segundos. Se ela olhar, você endireita o corpo na hora e retoma depois de onde parou.

## Progressão

- **Mural de provas:** 20 cartões que ficam entre as noites, marcados com a pergunta que ajudam a responder.
- **Estrelas:** até 3 por noite (2 por tarefas, 1 por achar todas as provas da noite).
- **Armário:** rodo largo, spray revelador, lanterna de cabeça, luvas silenciosas, rádio da equipe. A lanterna muda o porão e o oitavo andar de injogáveis para jogáveis.
- **Confiança:** sobe com tarefas feitas, cai quando você é descoberta. Confiança baixa deixa a ronda mais atenta.
- **Ser descoberta não acaba a campanha:** a noite é perdida e repetida, e a gerência fica mais vigilante.

## Dedução final

Três perguntas: quem, por quê e como. Só aparecem as respostas que as suas provas sustentam. Duas ou três certas encerram o caso; menos que isso, ele é arquivado.

## O iPhone

| No jogo | No iPhone |
| --- | --- |
| Olhar | apontar o aparelho (attitude do CoreMotion) |
| Andar | joystick virtual |
| Rodo | segurar na vertical e puxar de cima para baixo |
| Vassoura | segurar como cabo e varrer de lado a lado |
| Pano, flanela | segurar USAR e esfregar |
| Escutar | encostar o aparelho na orelha e ficar parada |
| Provas | fotografar com AÇÃO; ficam na aba Provas |
| Delegado | mensagens com vibração, na aba Mensagens |
| Rádio da equipe | vibra quando a gerente entra no andar |

Sem iPhone, teclado e mouse fazem tudo (fallback de teste, não a experiência).

## Maior incerteza

Se o rodo com o iPhone na mão dá a sensação de limpar um vidro de verdade. O modo `TURNO_CAPTURE=1` valida as regras; a sensação só se valida com aparelho físico.

## Fora de escopo

Assets externos (tudo é procedural), vozes, papéis com acesso exclusivo por chave, internet fora da rede local, mais de um culpado possível.
