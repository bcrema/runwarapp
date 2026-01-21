# GDS v1.0 — Aplicativo de Corrida Gamificado: Corrida & Conquista de Territórios (Piloto Curitiba)

## 1) Objetivo do produto
Criar um “War” no mundo real para corredores, onde **corridas (GPS) conquistam e defendem territórios**, gerando:
- Engajamento individual (progressão, coleção, ranking)
- Engajamento social (bandeiras, disputas por bairro/tiles, ações coordenadas)
- Valor B2B2C (assessorias/boxes usam como motor de comunidade e retenção)

**Público-alvo do piloto:** 3–6 bandeiras (assessorias e/ou boxes), até 100 membros cada, com 30–60 usuários ativos totais.

---

## 2) Conceitos e entidades
- **Usuário (Corredor)**
- **Bandeira (Comunidade)**: assessoria, academia, box de CrossFit, grupo de corrida.
  - Roles: **Admin/Coach**, **Membro**
  - Campo: **Categoria** (Assessoria | Academia | Box | Grupo)
- **Tile (micro-território)**: unidade jogável do mapa.
- **Território (macro)**: agrupamento visual/estatístico de tiles (fase 2: “bairros”). No MVP, usar apenas tiles + clusters.
- **Ação de Território (derivada de uma corrida válida)**: conquista, ataque, defesa.

---

## 3) Mapa e granularidade territorial (Curitiba)
**Tile (MVP):** grade hexagonal equivalente a ~250m de raio (centro-vértice).  
Objetivo: equilíbrio entre clareza, densidade e antifraude.

**Estados do tile:**
- Neutro
- Dominado (por Usuário solo ou por Bandeira)
- Em disputa (escudo abaixo de um limiar)

---

## 4) Regras do núcleo: validação da corrida e “Loop de Conquista”

### 4.1 Regras de “Loop Válido”
Uma corrida gera uma **Ação de Território** se contiver um loop (circuito fechado) válido:

**Parâmetros iniciais (MVP)**
- Distância mínima do loop: **1,2 km**
- Tempo mínimo do loop: **7 min**
- Fechamento do loop: ponto final a **≤ 40 m** do ponto inicial
- Cobertura do tile: **≥ 60%** da distância do loop dentro do tile (ou checkpoints equivalentes)
- Qualidade mínima de GPS: se precisão degradar de forma persistente, a corrida ainda é salva, mas **não gera ação territorial**

### 4.2 Antifraude mínimo (impacto em território)
Uma corrida pode ser “válida para treino” mas **inválida para território** se:
- Velocidade sustentada improvável: **> 25 km/h por mais de 30s** (indicador de bike/carro/spoof)
- “Teleportes” (saltos abruptos de localização)
- Baixa qualidade consistente de sinal (ex.: precisão muito alta por longos períodos)

**Princípio do MVP:** “Não punir o treino; só cortar o efeito competitivo.”

---

## 5) Propriedade e disputa: escudo + cooldown

### 5.1 Atributos do tile
- **OwnerType:** Solo (Usuário) ou Bandeira
- **OwnerId**
- **Escudo (0–100)**
- **Cooldown (timestamp até quando não pode trocar de dono)**
- **Guardião (MVP):** usuário com maior contribuição no tile na semana (ataque+defesa), apenas informativo

### 5.2 Ganhos/perdas do escudo (parâmetros MVP)
- Ao conquistar tile neutro: **Escudo = 100**
- **Ataque válido de rival:** **-35**
- **Defesa válida do dono/mesma bandeira:** **+20** (cap 100)
- Troca de dono: quando escudo **≤ 0**
- Ao trocar: novo dono entra com **Escudo = 65**
- **Cooldown após troca:** **18 horas**
  - Durante cooldown, o tile **não pode trocar de dono**
  - Ataques podem reduzir escudo até **mínimo 65** (marca disputa, mas não vira)

### 5.3 “Em disputa” (para UX e notificações)
Tile é marcado “em disputa” quando escudo **< 70**.

---

## 6) Solo vs Bandeiras: incentivos e convivência

### 6.1 Modo Solo (sem bandeira)
O solo deve ser um jogo completo, com:
- **Domínio pessoal visível** (tile mostra avatar/nome do dono)
- **Ranking Solo Curitiba** (semanal e de temporada)
- **Conquistas (badges) e progressão**
- **Missões semanais Solo** (MVP)
  - Ex.: “Conquiste 2 tiles novos”, “Defenda 1 tile em disputa”, “Complete 1 loop com elevação”

**Regras de transição Solo → Bandeira**
- Ao entrar numa bandeira, o histórico solo permanece no perfil.
- A partir da entrada, novas ações territoriais passam a contar para a bandeira (não converte automaticamente tiles passados; evita sensação de perda/roubo).

### 6.2 Bandeiras (assessorias, academias, boxes)
- Bandeira “pinta” tiles no mapa.
- Guardião por tile mantém o incentivo individual.
- Categorias servem para segmentação e futuras regras (fase 2), mas no MVP o jogo é igual para todas.

---

## 7) Limites de impacto (balanceamento para times até 100)
Para evitar que “o maior time ganha sempre por volume”:

**Cap individual de ações territoriais por dia:** **3 ações/dia**  
(Ex.: 2 defesas + 1 ataque; ou 3 ataques. Corridas adicionais não geram ações, mas contam para métricas fitness.)

**Cap por bandeira de ações territoriais por dia:** **60 ações/dia**  
(Feature flag por bandeira, ajustável conforme densidade de usuários ativos.)

---

## 8) Temporadas e pontuação (para manter o mapa vivo)
**Temporada MVP:** **6 semanas**.

**Pontuação diária por bandeira (temporada):**
- **+1 ponto por tile controlado por dia**
- **Bônus de cluster:** a cada **5 tiles conectados** (adjacentes), **+5 pontos/dia**
- **Decaimento por abandono:** tile sem defesa por **10 dias** começa a perder **10 de escudo/dia** até **30** (fica fácil de invadir)

**Rankings**
- Solo semanal e de temporada
- Bandeiras semanal e de temporada

---

## 9) Notificações (mínimas e controladas)
**Gatilhos**
- Tile do usuário/bandeira entrou em disputa (escudo < 70)
- Tile foi tomado

**Limites**
- Usuário: máximo **2 notificações/dia** + **1 resumo diário** (digest)
- Bandeira (coach/admin): digest com “tiles em disputa” e “tiles perdidos” (sem spam)

---

## 10) Privacidade e segurança (mínimo aceitável)
- Ofuscar início/fim de rotas (não mostrar ponto exato; aplicar “blur” local)
- Controles de visibilidade: perfil público/privado
- Sem chat entre rivais no MVP (reduz moderação)
- Regras e mensagens de segurança (horário/local) no onboarding

---

## 11) Telas / entregáveis do MVP (escopo funcional)
1. **Mapa** (tiles, cores, estado “em disputa”)
2. **Registro de corrida** + upload
3. **Validação de loop** + feedback pós-corrida (conquistou/atacou/defendeu)
4. **Bandeiras**: criar/entrar, roles
5. **Rankings** (solo e bandeiras)
6. **Perfil** (tiles, badges, missões, stats básicos)
7. **Dashboard do coach (mínimo)**: mapa + top contribuidores + presença semanal
8. **Notificações essenciais**

---

## 12) Métricas de sucesso do piloto (critérios de “go/no-go”)
- WAU/inscritos: **≥ 35%**
- Retenção semana 2: **≥ 30%**
- Sessões por semana por usuário: **≥ 2,0**
- Tiles em disputa: **5–15%** (saudável)
- Relato qualitativo dos coaches: “melhorou adesão ao treino / gerou ação social”

---

## 13) Pós-MVP (fase 2) — extensões naturais
- **Raids** (janela de ataque coordenado com multiplicador)
- **Bairros (macro-território)**: pintar bairro quando controla X% dos tiles
- **Hub de bandeira** (especialmente útil para boxes/academias): força maior no entorno
- Integrações (Strava/Garmin/Apple Health) como “selo de confiabilidade”
- Ligas/handicaps por tamanho de bandeira

---

## Anexo: Tabela de parâmetros (MVP Curitiba)
- Tile: hex ~250m raio  
- Loop mínimo: 1,2 km / 7 min / fechamento ≤ 40m / 60% dentro do tile  
- Ataque: -35 escudo  
- Defesa: +20 escudo (cap 100)  
- Troca: escudo ≤ 0 → novo dono com 65  
- Cooldown: 18h (sem troca; escudo mínimo 65)  
- Em disputa: escudo < 70  
- Cap individual: 3 ações/dia  
- Cap bandeira: 60 ações/dia  
- Temporada: 6 semanas  
- Decaimento: após 10 dias sem defesa, -10 escudo/dia até 30  
