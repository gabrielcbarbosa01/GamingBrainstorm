# Apple Technologies Evaluation

SwiftUI está aprovado para a interface do produto. Nenhuma outra tecnologia desta lista está aprovada por mera presença; a seleção depende do conceito, da plataforma e dos protótipos definidos no [GDD](GDD.md) e no [SDD](SDD.md).

| Tecnologia | Possível uso | Adotar quando | Risco/pergunta |
| --- | --- | --- | --- |
| SwiftUI | Interface, navegação, configurações e overlays | Obrigatório para a interface | Não assumir adequação como renderer de gameplay |
| SpriteKit | Gameplay 2D, física e partículas | O conceito exigir cena 2D e o protótipo provar adequação | Integração com SwiftUI, escala e ferramentas |
| GameplayKit | State machines, pathfinding, agentes, regras e aleatoriedade | Um sistema concreto justificar o módulo | Evitar abstração sem benefício mensurável |
| Metal | Renderização ou computação especializada | Renderers de alto nível não cumprirem requisito medido | Alto custo, complexidade e acessibilidade |
| RealityKit | Conteúdo 3D ou espacial orientado a entidades | A experiência depender de 3D/espacial | Plataforma, performance e pipeline de assets |
| ARKit | Rastreamento e compreensão do ambiente | AR for parte indispensável da fantasia | Privacidade, espaço físico, fallback e conforto |
| GameKit | Placares, conquistas e multiplayer Apple | Recursos sociais melhorarem o loop validado | Autenticação, offline e escopo de backend |
| AVFAudio | Reprodução, mixagem e áudio procedural convencional | O design sonoro exigir controle além do básico | Sessão de áudio, interrupções e latência |
| PHASE | Áudio espacial complexo | Posicionamento sonoro for essencial e testável | Complexidade e disponibilidade por plataforma |
| Core Haptics | Feedback tátil expressivo | Hardware e interação aprovados suportarem háptica | Fallback obrigatório e fadiga |
| Game Controller | Controles físicos | Plataforma ou público justificar suporte | Descoberta, remapeamento e navegação completa |

## Outras APIs a avaliar sob demanda

- Accessibility e APIs SwiftUI de acessibilidade;
- SwiftData/Core Data ou armazenamento simples;
- CloudKit para sincronização;
- StoreKit, apenas se um modelo de distribuição justificar;
- TipKit para orientação contextual;
- MetricKit, Instruments e os Organizer diagnostics para qualidade.

## Processo de seleção

1. Escrever a necessidade em linguagem de experiência.
2. Definir critério mensurável e fallback.
3. Comparar a opção mais simples com as alternativas.
4. Fazer um spike no hardware relevante.
5. Medir desempenho, integração, acessibilidade e custo de produção.
6. Registrar a decisão em ADR e atualizar esta matriz.

## Princípio de fallback

Se uma API depender de sensor, conta, acessório, permissão ou hardware específico, a experiência deve declarar comportamento para indisponibilidade, recusa de permissão e interrupção.
