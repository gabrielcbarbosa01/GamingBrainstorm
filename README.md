# Guardiões dos Biomas

Jogo de exploração em Swift sobre cinco animais brasileiros ameaçados de extinção.
Aplicativo macOS: SwiftUI para a interface, SpriteKit para o mundo.

**Não há um único arquivo de imagem no projeto** — todo o sprite e todo o terreno
são desenhados em CoreGraphics em tempo de execução.

## A ideia

Você é guardiã(o) de campo. Sai do **Refúgio Raízes** por portais, explora biomas
gerados proceduralmente sem limite de tamanho, registra vestígios, liberta animais
presos e recupera áreas degradadas. Cada bioma termina no encontro com um Guardião,
que entrega um amuleto — e cada amuleto abre o bioma seguinte.

| Bioma | Animal | Amuleto | Travessia | ESPAÇO faz |
|---|---|---|---|---|
| Mata Atlântica | Mico-leão-dourado | da Copa | cipoais | **Salto** em arco, com salto duplo |
| Cerrado | Lobo-guará | da Campina | espinheiros | **Investida** que rompe e empurra ameaças |
| Pantanal | Arara-azul-grande | do Vento | abismos | **Planar**: segure para se manter no ar |
| Amazônia | Pirarucu | das Águas | água funda | **Arranco**: mergulha, veloz e invisível |
| Pampa | Tuco-tuco-das-dunas | do Subsolo | terra compactada | **Escavar**: some no subsolo |
| — (lendária) | Harpia | Coroa | tudo | **Voo** livre, sem barreira nenhuma |

Cada forma tem um verbo próprio na barra de espaço — é isso, e não a velocidade,
que diferencia jogar de mico e jogar de lobo. O jogador tem **altura real**: o
salto sobe cerca de um tile, a sombra se separa do corpo e no ar você passa por
cima de água, cipó e abismo mesmo sem o amuleto correspondente. Só o paredão de
rocha continua sendo parede.

### A Harpia

Aparece na abertura, dá uma dica enigmática e some. Só volta quando o mundo
inteiro tiver voltado: os cinco amuletos, uma expedição concluída em cada bioma
e quinze mudas cultivadas no viveiro. Aí vira a sexta forma jogável.

Ela é predadora dos próprios micos que você passou o jogo protegendo — e é
exatamente por isso que serve de sinal: onde a harpia ainda se reproduz, a
floresta está inteira.

### A Operação — o laço central

Atravessar o portal não te larga num campo vazio. Você cai no meio de uma
operação em andamento: uma **frente de destruição** avança sobre o território
num relógio visível, e à frente dela há focos de vida.

| Bioma | Frente | O que há para salvar |
|---|---|---|
| Mata Atlântica | Frente de corte | grupos de micos |
| Cerrado | Frente de fogo | ninhadas |
| Pantanal | Linha de saqueadores | ninhos de arara |
| Amazônia | Arrastão de malhadeiras | cardumes |
| Pampa | Linha do arado | galerias |

**Não dá para salvar todos** — a meta é sempre menor que o total. A rota que
você escolhe decide quem fica. Focos ao norte valem mais risco; os do sul
sobrevivem mais tempo sozinhos. Parte deles são **grupos em fuga**: recuam mais
devagar que a máquina e precisam ser escoltados até a borda sul.

O balanço no fim mostra os dois números — salvos e perdidos — porque a perda faz
parte do resultado.

**Ato 1:** bata a meta uma vez e o Guardião entrega o amuleto.
**Ato 2:** a frente volta mais rápida, e agora você tem o corpo do bicho para
alcançar o que antes estava do outro lado da água, do cipó ou do abismo. Só
então o portal seguinte abre. Cada operação corrida deixa a próxima mais rápida.

### As provas

Cada prova é um minijogo com laço próprio, cena separada, câmera travada e
rolagem contínua — e guarda recorde.

| Bioma | Prova | Como joga |
|---|---|---|
| Mata Atlântica | **Corrida na copa** | Runner de 3 faixas. A/D trocam de galho, ESPAÇO salta o baixo; o alto só se desvia. Acelera sem parar. |
| Cerrado | **Fuga do fogo** | Mesma pista, com uma parede de fogo atrás. Cada batida deixa ela ganhar terreno. Sem vidas extras. |
| Pantanal | **Voo entre os manduvis** | Segure ESPAÇO para subir, solte para cair. Passe pelos vãos entre as árvores. |
| Amazônia | **Travessia dos jacarés** | Frogger: pule de tronco em tronco. Eles derivam em velocidades diferentes, e o jacaré afunda se você demorar. |
| Pampa | **Galeria sob o arado** | Túnel escuro com lâminas descendo, telegrafadas por uma marca vermelha. |

O motor é um só (`RunScene`), com cinco modos: `pistas`, `fuga`, `voo`,
`travessia`, `tunel`. As provas também entram no sorteio das expedições infinitas.

### No mundo aberto, cada bioma joga diferente

A etapa central de cada território não é "apertar E num marcador": é uma
mecânica própria, com regras que só existem ali.

| Bioma | Desafio | O laço de jogo |
|---|---|---|
| Mata Atlântica | **Travessia da copa** | Escolta. Um grupo de micos segue o seu rastro com atraso; a confiança cai se você se afasta, e o grupo se dispersa se você deixa de ser mico. |
| Cerrado | **Aceiro** | Simulação de incêndio. O fogo pula de tile em tile pelo material inflamável; a investida do lobo raspa o chão e abre faixas de terra nua. Cercar, não apagar. |
| Pantanal | **Vigília dos ninhos** | Corrida. Um saqueador caminha até o ninho num relógio visível. Voar é o único jeito de chegar; proteger exige voltar à forma humana. |
| Amazônia | **Malhadeiras** | Mergulho com fôlego. Cortar a rede leva 2 s segurando E, e submerso o fôlego cai — a vulnerabilidade real da espécie virada regra. |
| Pampa | **Sob o arado** | Escavação às cegas. A lâmina avança em linha reta; as galerias só se alcançam por baixo, e no subsolo a visão fecha num círculo. |

Todos os cinco também entram no sorteio das expedições infinitas.

### Fauna

Quinze espécies de fundo, três por bioma, montadas a partir de cinco arquétipos
de corpo (quadrúpede, ave, réptil, aquático, pendurado) parametrizados por cor,
porte e um traço marcante — o bico do tucano, o pescoço da ema, o focinho do
tamanduá.

Elas perambulam e fogem. O raio de fuga depende de quem se aproxima: na forma
humana disparam de longe, em forma animal deixam chegar mais perto, e de quem
está no subsolo ou submerso não fogem. Cada primeiro registro abre uma ficha.

### O Refúgio como base

O centro deixou de ser um saguão com portais:

- **Viveiro** — plante juçara, lobeira, manduvi, castanheira e capim-das-dunas.
  Crescem com o tempo de jogo e viram mudas. Sementes vêm dos objetivos de
  restauro e resgate no campo.
- **Açude** — minigame de pesca por tempo. Espécies migradoras e juvenis abaixo
  do tamanho mínimo valem o **dobro** quando devolvidas à água.
- **Oficina** — pontos, mudas e peixes viram melhorias permanentes: mais
  canteiros, mais essência máxima, cais melhor, torre de observação (revela
  caches mesmo na forma humana) e ferramenta que rende mais pontos.

Como cada amuleto vale em todos os biomas, voltar a um território antigo abre
áreas que antes eram intransponíveis.

Depois dos cinco amuletos o jogo **não acaba**: cada bioma passa a gerar expedições
infinitas, com alvo e hostilidade crescentes, alimentando o Índice de Biodiversidade.

## Controles

| Tecla | Ação |
|---|---|
| WASD / setas | andar |
| ESPAÇO | movimento especial da forma atual |
| E | interagir · avançar diálogo |
| 1–6 | vestir um amuleto |
| Q | voltar à forma humana |
| TAB | Códice |
| M | mapa de campo |
| R | iniciar nova expedição |
| ESC | menu |

**Essência** é o recurso central: transformar-se consome essência continuamente e,
quando ela acaba, você volta a ser humano na hora. Só a forma humana conversa com
pessoas, abre armadilhas e planta mudas — a troca entre bicho e gente é o ritmo do jogo.

Ninguém morre. Quem é pego por uma ameaça é afugentado e perde pontos.

## Estrutura

```
GamingBrainstorm/
  Core/    regras: biomas, amuletos, terreno, missões, diálogo, códice, save
  World/   geração procedural infinita por chunks
  Art/     desenho de todo o sprite e terreno em CoreGraphics.
           Creatures.swift gera cada quadro a partir de uma Pose — os ciclos de
           caminhada, salto, investida e batida de asa são calculados, não
           desenhados à mão.
  Scenes/  cena SpriteKit, entidades do mundo, teclado
  UI/      SwiftUI: HUD, diálogo, códice, mapa, menu
```

O Códice traz fichas de conservação baseadas em dados reais (IUCN, ICMBio e
projetos brasileiros de campo) sobre cada espécie e cada bioma.

## Rodar

Abra `GamingBrainstorm.xcodeproj` no Xcode e rode o esquema `GamingBrainstorm`,
ou pela linha de comando:

```
xcodebuild -project GamingBrainstorm/GamingBrainstorm.xcodeproj -scheme GamingBrainstorm build
```

O progresso é salvo em `~/Library/Application Support/GuardioesDosBiomas/save.json`.
