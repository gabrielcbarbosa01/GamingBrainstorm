# Protocolo Bovino — folha de especificação

Resumo executável do documento de design (`design/protocolo-bovino.html`).
Só números, estruturas e checklists. A justificativa de cada escolha está no documento.

## Vigas (mudar uma destas quebra vários blocos)

1. Alerta é escada, não cronômetro — estourar sobe o Nível de Vigília permanentemente na noite.
2. Necessidades das vacas correm durante a expedição.
3. Energia é um barramento único e compartilhado da nave.
4. Tudo que importa é objeto físico carregável (vaca, feno, balde, amigo caído).
5. O adorno que dá valor é o que dá trabalho.
6. Vaca viva rende mais que vaca entregue, mas só depois do investimento.
7. Voltar é ato físico e público (Alavanca de Subida, 10 s de buzina, abortável).

## Portes

| Porte    | Escala | Baia | Vel. solo | Vel. dupla | Valor | Leite/ciclo |
|----------|-------:|-----:|----------:|-----------:|------:|------------:|
| Bezerro  | 0,55×  | 1    | 85%       | —          | 45    | 2 L         |
| Novilha  | 0,80×  | 2    | 65%       | 90%        | 95    | 6 L         |
| Adulta   | 1,00×  | 3    | 45%       | 78%        | 170   | 10 L        |
| Matrona  | 1,35×  | 4    | 26%       | 62%        | 320   | 16 L        |
| Colossal | 1,90×  | 6    | 14%       | 44% (trio 70%) | 640 | 24 L     |

Solo é sempre possível (decisão travada do Bloco 1). Colossal solo: sem correr, sem giro rápido, dropa em rampa.

## Alerta (0–100, global)

| Fonte | Delta |
|---|---|
| Correr perto de vaca acordada | +1/s |
| Sino em movimento | +2/s |
| Lanterna apontada para vaca | +3/s |
| Derrubar vaca | +8 |
| Porteira batendo | +5 |
| Feixe de extração | +12 por vaca |
| Vaca em pânico (contágio) | +2/s cada |
| Silêncio ≥ 8 s | −2/s |

Em 100: debandada, alerta volta a 40, **Vigília +1 (permanente na noite)**.

### Níveis de Vigília
- **0** Noite morna — nada ativo.
- **1** Holofote varrendo + cães latindo. Iluminado = ganho de alerta dobrado.
- **2** Fazendeiro com sal grosso. Tiro derruba o jogador e faz soltar a carga. Persegue barulho.
- **3** Vizinhança + estrada + drone. Nave acumula Exposição → multa de 250 cr.
- **4** Subida forçada em 90 s. Único cronômetro do jogo.

Backstop externo: amanhecer aos 22 min → Exposição sobe continuamente (céu clareia, sem HUD).

## Expedição — ritmo alvo

Descida 75 s → reconhecimento 2–3 min → colheita 5–7 → complicação 3–5 → saída 1–3.
**Total 12–18 min.** Ciclo = 3 noites + prestação de contas.

Morte: Derrubado (carregável como vaca, 60 s) → Perdido → Clonagem 20 s / 120 cr / defeito cosmético.
Todos caídos = subida automática, perde equipamento no chão, run continua. **Só a cota encerra a run.**

## Habitat — 3 medidores

- **Saciedade** (por vaca, 0–100): cai `1,5/min × (baiaUnits/3)`. Enche com feno (objeto, 25 cr/fardo, 1 unidade de espaço) + água (condensador, 2 de energia).
- **Estresse** (por vaca, 0–100): ver tabela no HTML. Contágio acima de 70 = +3/min nas vizinhas.
- **Sujeira** (por BAIA, 0–100): +0,8/min por vaca. >60 risco de doença. >80 todo leite contaminado.

Superlotação permitida: +15/min de estresse por unidade excedente.
Nave inicial: 6 unidades (2 baias de 3) + porão de trânsito de 4 (estresse dobrado, produção zero).

Estados de saúde (evento, não barra): Fraca → Doente → Enlouquecida → Perdida (vira biomassa).

Regras de interação entre vacas: contágio, intimidação (grande sobre pequena), companhia (bezerro+adulta),
sino (+2/min na nave inteira), rota (vaca solta bloqueia corredor).

## Produção

Produz só com `saciedade > 50 && estresse < 60`.

```
litros = base_do_porte × (saciedade/100) × (1 − estresse/150)
       × mod_traços × (1 + 0,15 × ciclos_de_serviço)
```

Ordenha manual 12 s → balde 5 L. Latão 20 L exige 2 jogadores.

| Grau | Pureza | cr/L |
|---|---|---|
| S Tributo Sagrado | 92+ | 20 |
| A Digno | 75–91 | 12 |
| B Aceitável | 55–74 | 7 |
| C Duvidoso | 30–54 | 4 |
| X Vivo | <30 | 1 |

Balde fora do resfriador: −2 Pureza/min (dobro perto de baia suja). Derrubado: perde tudo, +15 sujeira.

| Máquina | Espaço | Energia | Efeito |
|---|---|---|---|
| Resfriador | 2 | 2 cont. | Zera perda de Pureza |
| Centrífuga | 2 | 3 em uso | 10 L → manteiga, ×1,8 imediato |
| Fermentador | 4 | 2 cont. | 10 L → queijo, ×2,5 após 1 ciclo, +30%/ciclo, teto 3 |
| Condensador | 2 | 2 cont. | Água para os cochos |
| Reprocessador | 3 | 4 em uso | Biomassa/leite X → feno |

## Economia

Duas moedas: **Créditos** (paga cota, compra) e **Prestígio** (só desbloqueia camadas do catálogo).

```
valor_espécime = base × (1 + 0,25 × adornos) × (1 + 0,20 × ciclos_serviço)
               × fator_saúde(1,0 / 0,6 / 0,3) × (1,6 se atende pedido)
```

Saídas: cota, feno 25/fardo, energia 40/ciclo + 15 por capacidade extra, clonagem 120,
reparos 40–200, multa de Exposição 250, melhorias.
Liquidez: tudo vendável de volta a 60% a qualquer momento.

## Cota

`cota(n) = arredonda(400 × 1,42^(n−1), 25)`

| Ciclo | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Cota | 400 | 575 | 800 | 1150 | 1625 | 2300 | 3275 | 4650 |

Sem rubber banding. Degrau extra de +40% a cada 5 ciclos.
Painel diegético "Projeção do Conselho" na ponte, ao vivo, inclusive durante a expedição.
Ciclos 1–3 sem eventos e sem pedidos. Falhar = fim de jogo (travado).
Persiste após a morte: só codex, placa de honra e cosméticos — nenhum poder.

## Energia

Núcleo inicial: **10 unidades**. Estourar derruba o disjuntor (luz, resfriador, condensador param).
Camadas do catálogo: 1 livre · 2 = 3 Prestígio · 3 = 8 · 4 = 15.

Melhorias que dão verbo novo (não %): manta gravitacional, poste de ancoragem portátil,
rádio bovino, cabo de reboque, guindaste de convés, disjuntor seletivo, tubulação de leite.

## Progressão das vacas

Renomear é livre (maior retorno por custo do documento).
Tempo de serviço: +1 por ciclo saudável e não superlotado. +15% produção / +20% valor, teto 10.
Títulos: 3 Anciã · 6 Matriarca (−3/min de estresse na nave) · 10 Dignitária Vitalícia.

10 traços (1–3 por vaca, ocultos): Fonte, Estoica, Líder, Glutona, Escapista, Sonâmbula,
Sino Interno, Amaldiçoada, Ímã de Pânico, Couro Grosso.

## Multiplayer

- Host autoritativo, sem migração de host. Tick 30 Hz, snapshot 20 Hz, interpolação 100 ms.
- Predição **só do próprio avatar**. Sem rollback.
- **Objeto carregado é cinemático, nunca junta física.** Balanço = mola visual + penalidade de input.
- Autoridade migra ao pegar, volta ao soltar. Em dupla, o primeiro a pegar é o líder e dono da âncora.
- Alerta, vigília, cota e necessidades: só no host, nunca previstos no cliente.
- Drop-in pela cabine de clonagem. Sair = solta tudo. Solo jogável, cota não escala com jogadores.

## MVP

**Dentro:** alienígena a pé · carregar 1p/2p · 1 malha de vaca em 3 escalas · 6 vacas · 1 pasto
com lamaçal, cerca, porteira e escuridão · lanterna · alerta com 3 fontes e 1 consequência ·
nave ancorada com rampa e feixe · 2 baias de 3 · só Saciedade · feno · ordenha → balde → tubo ·
1 noite, 1 cota, vitória/derrota · 2 jogadores online.

**Fora:** genética, planetas, traços, temperamento, adornos, escâner, vigília, fazendeiro, cães,
estresse, sujeira, doença, qualidade, processamento, energia, upgrades, prestígio, contratos,
clonagem, 3–4 jogadores, drop-in, dossiês. (Nomear vacas volta primeiro se sobrar tempo.)

**Marcos:** M1 Peso (offline) → M2 Dois (rede, maior risco) → M3 Atrito → M4 Loop → M5 Tensão.

**Validação:** alguém gritou "espera"? organizaram-se sozinhos? quiseram mais uma vaca?
contaram a história depois?

## Tecnologia

- **`GameCore` em Swift puro, sem nenhum import de render.** Passo fixo, testável, roda no host e no cliente.
- Renderer alvo: **RealityKit**. SceneKit está deprecated (WWDC25) — serve para prototipar, não para construir.
- GameplayKit: `GKStateMachine` para vaca, `GKNoise` para terreno. Boids próprio, não `GKAgent`.
- Rede: `GKMatch` atrás de um protocolo `Transport`.
- Controlador de personagem próprio (cápsula + varredura). Colisão convexa simples, nunca a malha do `.usdz`.
- Save: JSON `Codable` versionado, escrita atômica, em Application Support. Só o host escreve.
  Salva no fim de expedição e de ciclo, nunca no meio.
- Balanceamento em `Content/Balance/*.json` com hot-reload no debug.

```
Packages/GameCore   Model · Systems · Sim · Data
Packages/GameNet    Transport · GKMatchTransport · snapshot · autoridade
Packages/GameRender SceneKitPresenter hoje, RealityKitPresenter depois
App/                Game_PocApp · Input · UI (SwiftUI)
Content/            Assets3D · Audio · Balance
```

## Estado do protótipo

O M1 está implementado neste repositório — ver [README.md](README.md).
Carregar, mãos ocupadas, lanterna, alerta em escada, debandada, atropelamento, porteira,
lamaçal e feixe de extração funcionam e têm teste headless (`--haul`, `--soak`).

Ajustes de balanceamento que os testes forçaram, e que não estavam no design original:

- Correr precisa contar vacas **dormindo** também. Contar só as acordadas criava um impasse:
  elas só acordam por barulho, e o barulho só contava se elas já estivessem acordadas.
- Barulho ambiente acorda até 0,6 de alarme; pânico exige > 0,7. Sem esse teto, uma única
  vaca derrubada disparava a avalanche em segundos.
- Lamaçal de raio 5 m com 35%/s de escorregão era intransponível carregando. Ficou 3,2 m,
  12%/s e 40% de velocidade — obstáculo, não parede.
- A vaca é largada **ao lado**, não à frente: largada no caminho ela bloqueava a porteira.
- O foco de interação pesa a **mira**, não só a distância. Sem isso, uma vaca no chão perto
  da porteira tornava a porteira inalcançável.

## Pendências práticas

- [x] **Pivotar o protótipo:** feito. O alienígena anda a pé e ergue a vaca com as mãos; a nave fica ancorada.
- [ ] **Tela de créditos CC-BY-4.0** (obrigatório antes de distribuir): texto pronto em `ProtocoloBovino/Creditos.swift`, falta exibir.
- [x] **Build fora do Desktop:** documentado no README (`SYMROOT=/tmp/pb-build`).
- [ ] Título do jogo indefinido. Propostas: Protocolo Bovino · Tributo Líquido · Casta Serva · O Conselho Não Revisa.
- [ ] Alien em T-pose, sem animação. Não atrapalha o M1, mas é a primeira coisa que salta aos olhos.
