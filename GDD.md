# Game Design Document — Guardião dos Biomas

> Status: discovery consolidada — versão 0.2. Decisões confirmadas orientam protótipos; itens marcados **TBD** ainda exigem validação. O título é provisório.

## High concept

Uma aventura de exploração e investigação ecológica em que uma pessoa guardiã atravessa um Brasil fantástico, assume a forma de animais ameaçados e aprende a restaurar os seis biomas percebendo o mundo pelos sentidos de cada espécie.

## Promessa ao jogador

> Estar na pele de animais brasileiros para compreender como vivem, o que ameaça sua sobrevivência e como a restauração de um ecossistema transforma o mundo.

O conhecimento deve surgir principalmente da ação, da percepção e das consequências no cenário, não de textos expositivos.

## Público, plataforma e duração

- Público: geral, com foco em adultos e jovens adultos.
- Plataforma principal: macOS.
- Experiência: single-player.
- Campanha: pelo menos 4–5 horas; duração final **TBD** após estimativa de conteúdo.
- Sessão comum: 20–30 minutos.
- Entradas primárias: teclado e pointer; suporte completo a controle físico deve ser prototipado.
- Classificação etária e versões mínimas do macOS: **TBD**.

## Tom e emoção

O tom combina aventura, investigação ambiental, esperança e momentos pontuais de melancolia. Aventura é a ênfase principal.

Durante a sessão, pretende-se provocar curiosidade diante de rastros, prazer de dominar uma forma animal, tensão branda sem punição severa, encantamento com a diversidade do Brasil e satisfação ao ver vida e possibilidades retornarem. Depois, pretende-se deixar esperança, vínculo com as espécies e compreensão de que conservação envolve animais, habitat e pessoas.

## Pilares de design

### 1. Olhos de outro animal

Cada animal altera percepção, movimentação e decisão no mesmo ambiente. Uma mecânica só entra no núcleo se ajudar o jogador a compreender o mundo pela perspectiva animal ou agir sobre o que aprendeu.

**Teste:** uma pessoa explica como o ambiente mudou ao assumir uma espécie sem depender de uma tela de texto.

### 2. O mundo responde ao cuidado

Toda restauração relevante produz consequência visual, sonora e sistêmica: água retorna, vegetação cresce, espécies reaparecem, caminhos se abrem ou novos eventos surgem.

**Teste:** a pessoa identifica o que sua ação alterou e por que isso importa para o ecossistema.

### 3. Um Brasil conectado e redescoberto

Os seis biomas formam um território contínuo reconhecível como interpretação do Brasil. Exploração, habilidades e conhecimento revelam caminhos e camadas do mapa.

**Teste:** a viagem transmite continuidade e descoberta sem longos trechos vazios.

### 4. Aventura, domínio e confronto

Exploração contemplativa será alternada com combate de ação-RPG, travessia e encontros intensos. Monstros tornam ameaças ambientais fisicamente enfrentáveis, enquanto formas animais mudam estratégia, mobilidade e ritmo.

**Teste:** o jogador deve alternar deliberadamente entre ataque, esquiva, percepção e habilidade animal, em vez de vencer apenas repetindo um golpe.

### 5. Conservação sem vilões fáceis

Predadores naturais e pessoas não são inimigos de combate. Os adversários são monstros ficcionais gerados pelas ameaças ambientais. As causas continuam documentadas, como fragmentação, tráfico, sobrepesca, incêndios, conflito de uso do solo e governança.

**Teste:** derrotar um monstro contém o perigo imediato, mas a solução permanente exige restaurar o sistema que o originou.

## Estrutura do mundo

O mapa é um território contínuo inspirado no formato do Brasil, condensado para gameplay e sem escala 1:1. Nele existem seis regiões conectadas por zonas de transição:

1. Mata Atlântica;
2. Cerrado;
3. Caatinga;
4. Amazônia;
5. Pantanal;
6. Pampa.

Somente a Mata Atlântica estará acessível no início. Os demais biomas serão liberados progressivamente por rotas inspiradas em seus limites reais, numa estrutura parcialmente aberta inspirada em *Zelda*. Obstáculos exigirão formas ou habilidades futuras. Depois de descobrir destinos relevantes, o jogador poderá desbloquear viagem rápida; no início, atravessará o território.

Ainda é necessário validar se “contínuo” significa uma cena sem carregamento ou regiões ligadas por transições discretas. A experiência deve parecer contínua independentemente da solução técnica.

### Mapa como sistema

O mapa começa incompleto. Exploração e formas revelam rios, trilhas, territórios, profundidade, cheiros, fluxo, galerias e pontos distantes. O mapa final combina essas leituras. A linguagem cartográfica exata permanece **TBD**.

## Personagem guardião

O jogador representa uma pessoa ligada ao **Instituto Caramelo**, organização ficcional dedicada à restauração do Brasil. Deve ser possível escolher ao menos a apresentação de gênero; opções, aparência e forma de tratamento são **TBD**.

O chamado à aventura ocorre quando uma harpia ancestral ameaçada reconhece potencial no guardião e assume o papel de mentora. Animais extintos ou desaparecidos regionalmente podem aparecer como espíritos e carregar memória ecológica, sem apropriar crenças ou símbolos de povos reais.

### Mascote

Uma **harpia** acompanha fisicamente o guardião como mascote, mentora, tradutora e fonte contextual de dicas. A relação entre essa harpia e a manifestação ancestral do chamado à aventura ainda precisa ser detalhada na narrativa.

No arco final, o mascote deixa de falar em linguagem humana porque pode retornar à natureza. O vínculo permanece compreensível por comportamento e afeto.

### Base do Instituto Caramelo

O Instituto Caramelo terá uma base administrável que funciona como ponto de retorno entre expedições. Sua função provisória é reunir planejamento, crafting, melhorias, acompanhamento dos biomas e preparação da próxima saída. O tamanho da base e a frequência obrigatória de retorno serão definidos depois de prototipar o loop de gestão.

## Mecânica central: formas animais

Há um animal transformável principal por bioma. Depois de estabelecer conexão com um indivíduo vivo e receber seu amuleto, o guardião manifesta sobre si uma **forma espiritual inspirada naquele animal**, visualmente semelhante a estar fantasiado dele. O animal real continua existindo de forma independente no mundo; sua consciência e seu corpo não são controlados pelo jogador.

Cada forma possui uma habilidade central profundamente desenvolvida, sem árvore extensa de poderes genéricos.

Transformação e percepção são comandos separados:

- **Olhos da Natureza:** leitura sensorial temporária do ambiente;
- **transformação:** altera corpo, movimentação, acesso, risco e interação.

Essa manifestação concede movimentos, sentidos e capacidades do animal sem retirar sua agência. O estilo visual deve preservar elementos reconhecíveis do guardião dentro de cada forma.

## Core loop

1. Explorar um bioma ou transição.
2. Encontrar rastros, mudanças ou sinais de uma espécie.
3. Investigar a ameaça com percepção e conhecimento disponíveis.
4. Assumir a forma adequada.
5. Executar uma sequência própria de sobrevivência, navegação, investigação ou combate.
6. Conter monstros e perigos imediatos.
7. Resolver ou reduzir a causa ambiental alcançável.
8. Restaurar parte do ecossistema e receber feedback completo.
9. Obter amuleto, conhecimento, recurso ou acesso.
10. Avançar, administrar recursos ou retornar a uma área anterior.

Nem toda ameaça poderá ser concluída ao ser descoberta. O jogo deve comunicar falta de habilidade sem transformar a descoberta antecipada em frustração.

## Estrutura da sessão

Uma sessão de 20–30 minutos deve permitir retomada rápida, uma investigação ou conjunto curto de eventos, uma decisão significativa, mudança persistente e encerramento natural em ponto seguro, descoberta ou restauração. Pausa, autosave, salvamento manual e comportamento ao fechar o app são **TBD**.

## Espécies e capítulos

| Bioma | Espécie principal | Escala | Ameaça-raiz | Fantasia mecânica inicial |
| --- | --- | --- | --- | --- |
| Mata Atlântica | Mico-leão-dourado | Grupo familiar e habitat | Fragmentação e isolamento | Movimento vertical, copas e corredores |
| Cerrado | Lobo-guará | Território individual amplo | Conversão da paisagem e mortalidade | Faro, longas rotas e travessia |
| Caatinga | Ararinha-azul | Indivíduos raríssimos | Tráfico, doença e reintrodução | Voo, cavidades e proteção de indivíduos |
| Amazônia | Pirarucu | Estoque populacional | Sobrepesca e governança | Movimento aquático, lagos e cardumes |
| Pantanal | Onça-pintada | Território e corredores | Conflito com pecuária e fogo | Furtividade, território e refúgios |
| Pampa | Tuco-tuco-das-dunas | Faixa contínua | Remoção e ruptura das dunas | Escavação, vibração e navegação subterrânea |

### Amuletos e acessos confirmados

| Espécie | Habilidade do amuleto | Acesso principal |
| --- | --- | --- |
| Mico-leão-dourado | Escalar cipós | Cerrado |
| Lobo-guará | Investida que atravessa espinhos | Pantanal |
| Onça-pintada | Passo Invisível: furtividade em vegetação e áreas de risco | Caatinga |
| Ararinha-azul (Caatinga) | Voo que atravessa abismos | Amazônia |
| Pirarucu | Nado e travessia aquática | Pampa |
| Tuco-tuco-das-dunas | Escavar e acessar túneis | Áreas secretas e final |

A ararinha-azul pertence à Caatinga e a onça-pintada pertence ao Pantanal. O **Passo Invisível** da onça permite atravessar silenciosamente vegetação alta, corredores fragmentados e zonas de risco sem perturbar animais, abrindo a rota do Pantanal para a Caatinga. A habilidade não concede ataque ou combate. As habilidades devem ser prototipadas para garantir que expressem percepção e comportamento da espécie, e não funcionem somente como chaves de acesso.

### Quatro estruturas de conservação

Para evitar seis capítulos iguais:

- **Construção — mico-leão-dourado:** recuperar e conectar habitat.
- **Contenção — lobo-guará e onça-pintada:** reduzir perdas contínuas numa paisagem compartilhada.
- **Aposta — ararinha-azul:** proteger capital biológico limitado e apoiar reintrodução.
- **Governança — pirarucu e tuco-tuco:** criar e sustentar regras de uso do território.

O pirarucu é deliberadamente um caso de conservação bem-sucedida por manejo sustentável, não uma narrativa simples de espécie à beira da extinção.

## Ameaças e missões

Cada ameaça deriva do documento de referência de espécies e deve ser reconfirmada antes de virar texto final, especialmente dados da ararinha-azul.

Missões podem envolver corredores e passagens de fauna, travessias rodoviárias, armadilhas de tráfico sem vilão humano visível, ninhos seguros, fogo e refúgios, manejo sustentável da pesca, proteção de dunas, lixo e pequenas degradações recorrentes.

Pequenas ameaças podem reaparecer. Problemas estruturais possuem soluções persistentes que reduzem ou encerram sua recorrência. Frequência e custo de manutenção são **TBD**.

## Combate de ação-RPG

O combate é real, frequente e voltado a monstros. Não haverá combate contra animais naturais nem ataque direto a pessoas. As criaturas são manifestações físicas e estilizadas de degradações do mundo.

### Verbos básicos

- ataque rápido para pressão e combinações;
- ataque forte para quebrar defesa, armadura ou objetos;
- esquiva com janela curta de segurança;
- habilidade da forma animal;
- troca de forma durante o confronto;
- Olhos da Natureza para revelar fraquezas, intenção ou relação do monstro com o cenário.

O conjunto deve funcionar em teclado e controle físico. Quantidade de botões, stamina, parry, lock-on e ataques à distância são **TBD** após protótipo.

### Regra temática

Derrotar o inimigo **contém o sintoma**, mas não resolve sozinho a ameaça-raiz. Sem uma intervenção de restauração, certos monstros podem retornar. Uma solução estrutural reduz spawns, muda os inimigos ou elimina sua fonte naquela área.

Exemplo:

1. enfrentar criaturas de brasa para alcançar um foco de incêndio;
2. apagar o foco e salvar a fauna imediata;
3. construir aceiros, recuperar vegetação e instalar monitoramento;
4. reduzir permanentemente o surgimento das criaturas naquela região.

### Famílias iniciais de inimigos

| Família | Origem | Comportamento de combate |
| --- | --- | --- |
| Serradores | Desmatamento | Monstros de madeira e metal com motosserras, ataques amplos e destruição de cobertura |
| Brasas | Incêndio e seca | Criaturas rápidas que propagam zonas de fogo e fortalecem umas às outras |
| Engrenagens de captura | Tráfico e armadilhas | Gaiolas, redes e mecanismos vivos que imobilizam e separam o jogador do mascote |
| Famintos do rio | Sobrepesca e poluição | Redes, anzóis e manchas que puxam, cercam e alteram o terreno aquático |
| Concreto errante | Urbanização e fragmentação | Criaturas blindadas que erguem barreiras e dividem a arena |

Nomes e aparência são provisórios. Nenhuma família deve parecer representação codificada de grupo humano real.

### Encontros e chefes

- encontros comuns: 20–60 segundos;
- elites: combinam duas regras e guardam recurso, passagem ou evento;
- chefes de bioma: manifestações de uma ameaça-raiz, com arena ligada ao ecossistema;
- eventos sistêmicos: ondas curtas que podem reaparecer enquanto a solução permanente não existir.

Cada chefe deve exigir mecânica ambiental e habilidade animal, não apenas causar mais dano.

### Formas no combate

A habilidade central de travessia também possui uso combativo:

- mico-leão-dourado: mobilidade vertical, esquiva por cipós e ataques aéreos;
- lobo-guará: investida que rompe linhas e armaduras frágeis;
- onça-pintada: Passo Invisível, reposicionamento e ataque de surpresa contra monstros;
- ararinha-azul: voo curto, controle aéreo e rajadas que deslocam inimigos;
- pirarucu: avanço aquático, impacto e controle de correnteza;
- tuco-tuco: escavação, evasão subterrânea e surgimento sob pontos fracos.

Esses usos não transformam animais reais em armas: são capacidades da forma espiritual manifestada pelo guardião.

### Progressão de RPG

O crescimento terá três eixos provisórios:

1. **Guardião:** vida, esquiva, combos e uso de Olhos da Natureza.
2. **Formas:** novas propriedades para a habilidade central de cada animal.
3. **Instituto:** consumíveis, preparação, infraestrutura e benefícios persistentes.

Melhorias devem criar novas decisões ou sinergias, evitando aumentos numéricos excessivos. Nível máximo, árvore de habilidades, equipamento, raridade de itens e atributos permanecem **TBD**.

## Falha e recuperação

Não há morte punitiva do animal. Ao perder todo o vigor em exploração ou combate:

- o guardião retorna a um ponto seguro e o encontro pode ser reiniciado;
- um animal observado pode fugir ou a oportunidade terminar;
- o jogador mantém progresso estrutural;
- outra oportunidade surge depois sob condição legível;
- a falha oferece informação para a próxima tentativa.

As ameaças permanecem enquanto ignoradas, mas não devem degradar permanentemente conteúdo quando o jogador ainda não possui a habilidade necessária. Temporizadores e conteúdo perdível são **TBD**.

### Raridade e dificuldade

Espécies mais raras exigem investigação mais longa, pistas menos óbvias e combinações maiores de habilidades. Raridade não deve significar apenas menor probabilidade aleatória de spawn; o jogador aprende onde, quando e como procurar.

## Restauração

Cada problema resolvido concede porcentagem explícita de restauração, acompanhada de retorno de cor, som, vegetação, água, espécies, rotas, atividades e recursos.

É possível restaurar parte substancial de um bioma na primeira visita, mas algumas mudanças dependem de amuletos futuros. Concluir a campanha exige retornar a regiões anteriores; descobertas adicionais podem ser opcionais.

Condições de vitória representam saúde ecológica:

- Mata Atlântica: habitat protegido e conectado;
- Cerrado: sobrevivência e permeabilidade da paisagem;
- Caatinga: gerações saudáveis nascidas em liberdade;
- Amazônia: manejo sustentável e estabilidade comunitária;
- Pantanal: conflitos resolvidos sem morte e corredores consolidados;
- Pampa: faixa de dunas protegida e contínua.

Metas numéricas in-game são **TBD** e não devem copiar metas científicas sem adaptação e validação.

## Progressão, inventário e gestão

Amuletos são a progressão principal e concedem transformação, percepção e ao menos um benefício permanente, permitindo revisitar regiões numa estrutura de Metroidvania leve.

### Modelo econômico provisório

Expedições geram **recursos de restauração** por investigação, eventos, retirada de ameaças e recuperação responsável de materiais. Esses recursos voltam para a base do Instituto Caramelo e podem financiar:

- ferramentas e itens consumíveis criados por crafting;
- infraestrutura permanente nos biomas, como passagens, viveiros e pontos de monitoramento;
- melhorias da base que ampliam análise, armazenamento e preparação;
- medidas estruturais que reduzem a repetição de ameaças já compreendidas.

O crafting deve preparar ou facilitar ações de campo, não substituir a habilidade animal nem transformar conservação em coleta indiscriminada. “Patrocínios” podem existir como projetos ou parcerias desbloqueados por confiança e resultados, mas não serão tratados como itens comprados. Quantidade de moedas, receitas, categorias de recurso e balanceamento permanecem **TBD** até o protótipo do loop base → expedição → restauração → base.

## Eventos do mundo

Eventos de 30 segundos a 3 minutos evitam deslocamentos sem decisão: rastros, sons, avistamentos, lixo, clima, animal fugindo, tempestade, árvore caída, incêndio, armadilha, passagem ou espírito.

Eles devem respeitar o estado ecológico, não interromper continuamente a exploração e nunca exigir habilidade indisponível sem comunicar isso. Geração e recorrência são **TBD**.

## Narrativa ambiental

### Espíritos animais

Animais extintos ou desaparecidos de uma região podem revelar rastros, sons e memórias antes de aparecer. A harpia ancestral inicia esse sistema como mentora.

### Memória da Terra — hipótese

Possível habilidade de visualizar brevemente o passado ecológico. Exemplo: perceber que um rio hoje seco atravessava determinado local e usar essa informação para investigar sua recuperação.

Ainda é necessário decidir se será habilidade obrigatória, ferramenta de capítulos específicos ou conteúdo opcional. Não implementar em escala antes dessa decisão.

## Direção visual e câmera

- Visual 2.5D inspirado na legibilidade e profundidade de *Cult of the Lamb*, sem copiar sua identidade.
- Personagens: sprites em oito direções com animação esquelética 2D.
- Cenário: planos 2D distribuídos em profundidade.
- Câmera elevada com ângulo fixo e sem rotação livre.
- Seguimento com lerp curto, pequena zona morta e antecipação do movimento.
- Idle mais próximo; deslocamento com zoom out moderado.
- Aproximação em diálogos e descobertas; zoom out ao revelar bioma.
- Voo com ganho real de altura e enquadramento mais amplo.

Parâmetros, oclusão, leitura de profundidade, redução de movimento e interiores precisam de protótipo. O renderer não está decidido por esta direção.

## Áudio e acessibilidade

O áudio retorna com a restauração e funciona como informação ecológica. Informação essencial também terá equivalente visual.

- Nenhuma informação essencial dependerá somente de cor, áudio ou partículas.
- Suavização e zoom considerarão redução de movimento.
- Teclado e controle físico deverão permitir o fluxo completo se o suporte for aprovado.
- Ações repetitivas de manutenção precisam de redução ou alternativa.
- Pistas terão redundância sensorial configurável.
- Precisão e reação não serão a única fonte de dificuldade.

## Economia e monetização

Não há monetização definida. “Economia” significa recursos internos de gameplay. Compras no aplicativo, publicidade, serviços online e multiplayer estão fora do escopo atual.

## Métricas do protótipo

- compreensão de movimentação, percepção e transformação;
- capacidade de explicar a ameaça sem exposição longa;
- distinção entre guardião e animal;
- densidade de decisões durante deslocamentos;
- clareza de bloqueios futuros;
- compreensão da restauração;
- conforto da câmera em idle, corrida, voo e diálogos;
- interesse em revisitar um bioma;
- erros por teclado e controle;
- acessibilidade e desempenho no Mac-alvo.

## Escopo do primeiro vertical slice

O slice deve provar uma pequena área degradada, exploração 2.5D, encontro com espécie, percepção separada de transformação, uma habilidade central, uma ameaça real, falha branda, restauração audiovisual e sistêmica, um bloqueio futuro e entradas por teclado e controle.

O primeiro vertical slice será ambientado na **Mata Atlântica** e terá o **mico-leão-dourado** como forma animal principal. Escalar cipós deve ser a habilidade central testada, conectando movimento vertical à necessidade ecológica de atravessar uma floresta fragmentada.

## Questões abertas prioritárias

1. O que ocorre entre descobrir um animal e receber seu amuleto?
2. A harpia mascote é o mesmo ser ancestral que inicia a jornada ou um indivíduo vivo relacionado a ele?
3. Eventos recorrentes pioram porcentagens ou oferecem manutenção e bônus?
4. Quanto conteúdo pode ser perdido e quando uma oportunidade retorna?
5. Memória da Terra é obrigatória, específica ou opcional?
6. O mapa contínuo usa transições discretas ou streaming sem telas?
7. Qual é a classificação etária e até onde ameaças reais podem ser mostradas?
8. Controle físico será requisito de lançamento ou objetivo de protótipo?
9. Qual é o recurso de combate principal: stamina, energia espiritual ou somente tempos de recarga?

## Fora de escopo atual

- combate contra pessoas ou animais naturais e morte punitiva de animais;
- multiplayer, backend e conteúdo gerado por usuários;
- produção dos seis biomas antes de validar o slice;
- representação indígena sem pesquisa e participação cultural adequadas;
- números científicos e textos finais sem revisão de especialistas.
