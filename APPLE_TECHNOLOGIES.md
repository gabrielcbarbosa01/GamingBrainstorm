# Apple Technologies Evaluation

Nenhuma tecnologia desta lista está aprovada para produção final por mera presença. Para o protótipo 1, `docs/adr/0002-tecnologias-prototipo-1.md` registra as candidatas escolhidas para prototipagem descartável; consolidação definitiva ainda depende de spike e ADR próprio, conforme processo abaixo.

| Tecnologia | Possível uso | Adotar quando | Risco/pergunta |
| --- | --- | --- | --- |
| SwiftUI | Interface, navegação, configurações e overlays | Obrigatório para a interface | Não assumir adequação como renderer de gameplay |
| SpriteKit | Gameplay 2D (exploração no planeta e cena da nave/habitat) | Candidata para o protótipo 1 — o conceito exige cena 2D com múltiplos atores simultâneos (ver ADR 0002) | Integração com SwiftUI, escala e ferramentas |
| MultipeerConnectivity | Conexão par-a-par local entre os Macs dos jogadores, sem servidor | Candidata para o protótipo 1 — co-op precisa funcionar na mesma rede local sem infraestrutura de backend (ver ADR 0002) | Descoberta, reconexão, sincronização de estado compartilhado, alcance limitado à mesma rede/Bluetooth |
| GameKit | Placares, conquistas e multiplayer Apple pela internet | Se o produto final precisar de co-op entre redes diferentes ou recursos sociais (fora do escopo do protótipo 1) | Autenticação, offline e escopo de backend |
| GameplayKit | State machines, pathfinding, agentes, regras e aleatoriedade | Um sistema concreto justificar o módulo (ex.: comportamento autônomo de uma vaca) | Evitar abstração sem benefício mensurável |
| Metal | Renderização ou computação especializada | Renderers de alto nível não cumprirem requisito medido | Alto custo, complexidade e acessibilidade |
| RealityKit | Conteúdo 3D ou espacial orientado a entidades | A experiência depender de 3D/espacial (não é o caso do protótipo 1) | Plataforma, performance e pipeline de assets |
| ARKit | Rastreamento e compreensão do ambiente | AR for parte indispensável da fantasia (não é o caso) | Privacidade, espaço físico, fallback e conforto |
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

Para o protótipo 1, os passos 4–5 (spike e medição) ainda não foram executados de forma completa; a escolha de SpriteKit + MultipeerConnectivity em `docs/adr/0002` é uma decisão de nível protótipo descartável, não uma consolidação arquitetural.

## Princípio de fallback

Se uma API depender de sensor, conta, acessório, permissão ou hardware específico, a experiência deve declarar comportamento para indisponibilidade, recusa de permissão e interrupção.
