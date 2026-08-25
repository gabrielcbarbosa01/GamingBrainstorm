# Experience and Visual Design

## Estado

A direção aprovada para prototipagem é 2.5D: personagens em sprites de oito direções com animação esquelética 2D e cenários construídos com planos 2D distribuídos em profundidade. A referência de legibilidade e composição é *Cult of the Lamb*, sem reproduzir sua identidade visual. Paleta, acabamento, proporções, texturas e pipeline permanecem `TBD`.

## Câmera de gameplay

- ângulo elevado e fixo, sem rotação livre;
- seguimento com lerp curto, pequena zona morta e antecipação na direção do movimento;
- enquadramento mais próximo durante idle;
- zoom out moderado durante deslocamento;
- aproximação em diálogos e descobertas;
- zoom out de apresentação ao revelar um bioma;
- ganho de altura e campo visual durante voo.

O protótipo deve medir legibilidade de profundidade, oclusão por vegetação, conforto, julgamento de distância e transições entre enquadramentos. A preferência de redução de movimento deve reduzir ou eliminar zooms e atrasos não essenciais.

## Objetivos da direção futura

A direção aprovada deverá:

- reforçar a emoção e a fantasia definidas no [GDD](GDD.md);
- comunicar hierarquia, estado e consequência sem ambiguidade;
- ser realizável no prazo e consistente com o renderer escolhido;
- funcionar com tamanhos de texto, contraste e preferências de movimento;
- manter linguagem própria sem sacrificar padrões de plataforma úteis.

## SwiftUI e gameplay

SwiftUI é obrigatório para interface de aplicativo: navegação, menus, configurações, overlays e superfícies de sistema quando apropriado. Isso não o torna automaticamente o renderer do gameplay. A escolha do renderer será registrada no [SDD](SDD.md) após protótipo.

## Human Interface Guidelines

Quando a plataforma for aprovada, cada fluxo deve verificar:

- componentes e comportamentos familiares da plataforma;
- áreas de interação adequadas e foco de teclado/controle quando aplicável;
- navegação previsível e saída clara de modais ou estados imersivos;
- tratamento de janelas, tela cheia, orientação e safe areas conforme o dispositivo;
- feedback imediato para ações e estados de carregamento;
- permissões solicitadas no contexto e apenas quando necessárias.

## Requisitos verificáveis de acessibilidade

1. Todos os controles SwiftUI interativos terão rótulo e valor acessíveis quando o significado não estiver no texto visível.
2. A ordem de foco acompanhará a ordem lógica da tarefa.
3. O jogo permanecerá compreensível sem depender somente de cor.
4. Texto essencial respeitará configurações de tamanho quando suportadas pela plataforma.
5. Contraste de texto e indicadores será medido, não avaliado apenas visualmente.
6. Animações não essenciais responderão à preferência de redução de movimento.
7. Áudio essencial terá equivalente visual; informação visual essencial terá alternativa acessível apropriada.
8. O fluxo principal será testado com VoiceOver quando houver elementos de interface tradicionais.
9. Teclado, controle, toque, pointer ou outras entradas serão testados conforme a matriz de dispositivos aprovada.

## Tokens e componentes

Cores, tipografia, espaçamento, formas, materiais, motion e componentes permanecem `TBD`. Quando definidos, deverão ser centralizados e documentados para evitar valores divergentes entre gameplay e SwiftUI.

## Motion

Toda animação deve ter função identificável: continuidade, feedback, orientação ou expressão. Animação decorativa não pode atrasar uma ação essencial, e efeitos intensos devem possuir versão reduzida quando necessário.

## Áudio e háptica

Direção sonora e háptica permanece `TBD`. Áudio e háptica devem complementar feedback visual, nunca ser o único canal para informação crítica.

## Checklist de aprovação visual

- moodboard ligado aos pilares aprovados;
- protótipo em escala e hardware plausíveis;
- estados normal, foco, pressionado, desabilitado, erro e sucesso;
- contraste e legibilidade medidos;
- teste com redução de movimento e tecnologias assistivas relevantes;
- custo de produção compatível com o cronograma.
