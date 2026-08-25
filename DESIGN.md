# Experience and Visual Design

## Estado

A direção visual é **2.5D**. A estética será inspirada em títulos como *Cult of the Lamb* e *Don't Starve* (personagens e elementos interativos em 2D estilizado inseridos em um ambiente com perspectiva, proporcionando profundidade sem perder o charme de ilustração).

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

Cores, tipografia, espaçamento, formas, materiais, motion e componentes permanecem `TBD`. A UI do santuário e do catálogo (menus, HUD de gestão) será obrigatoriamente construída em **SwiftUI**. Quando definidos, os tokens deverão ser centralizados e documentados para evitar valores divergentes entre gameplay e a UI.

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

