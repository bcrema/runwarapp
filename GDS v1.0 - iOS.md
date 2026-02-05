# GDS v1.0 — V1 iOS (Foco Corrida + Território)

## 1) Visão e objetivo da V1 iOS
Entregar o **loop principal** do jogo no iOS: **correr no Fitness/Saúde → sincronizar no LigaRun → validar → conquistar/defender tiles**, garantindo que o corredor viva a experiência de território desde a primeira corrida.

**Objetivo de experiência:** terminar a corrida e ver claramente o impacto territorial (conquista/ataque/defesa) com feedback direto no mapa.

---

## 2) Escopo da V1 iOS (o que entra)
- **Mapa com tiles** (estados: neutro, dominado, em disputa)
- **Companion de corrida** (acompanhar no app) + **sincronização via Fitness/Saúde** (iPhone/Apple Watch)
- **Validação do loop** + antifraude mínimo
- **Resultado territorial pós-corrida** (conquistou/atacou/defendeu)
- **Perfil básico do corredor** (stats simples e histórico de ações)
- **Bandeiras (times)**: criar/entrar, ações contam para o time

---

## 3) Não-escopo (fase 2 / pós-MVP)
- Rankings (solo/bandeira)
- Notificações
- Badges, missões, temporadas completas
- Dashboard de coach
- Bairros, raids, hubs de bandeira
- Integrações externas (Strava/Garmin)

---

## 4) Fluxos essenciais (jornadas-chave)
1. **Primeiro uso → permissões → mapa → iniciar no Fitness**
   - Permissões de Saúde (HealthKit) e localização concedidas
   - Mapa centralizado na área do usuário
   - Corrida iniciada no app Fitness (iPhone/Apple Watch), com LigaRun em modo companion
2. **Finalizar corrida no Fitness → sincronizar → validação → feedback territorial**
   - Loop válido gera ação territorial
   - Feedback imediato: conquista, ataque, defesa ou inválida
3. **Entrar/criar bandeira → ações passam a contar para o time**
   - Histórico solo permanece no perfil

---

## 5) Diretrizes de UX/UI iOS (decisões)
- **Linguagem visual clean (referência)**: interface clara, cards brancos, bordas suaves, sombras leves e foco em legibilidade.
- **Hierarquia tipográfica objetiva**: título forte de estado (“Corrida concluída”), subtítulo curto (tipo de treino + distância) e blocos de informação com labels curtos.
- **Mapa é a home**: abre centralizado no usuário e já mostra tiles e estados, com overlays mínimos para não poluir a leitura.
- **CTA de corrida sempre visível**: botão primário “Acompanhar corrida” fixo no mapa, com ação de abrir/instruir uso do Fitness.
- **Tela companion simples e legível**: métricas essenciais (tempo, distância, pace) em blocos limpos; status de sincronização/monitoramento e mapa com trilha quando disponível.
- **Resultado pós-corrida em formato de resumo clean**:
  - Cabeçalho com status da corrida + distância total.
  - Linha de métricas em cards/círculos (distância, tempo, tiles).
  - Card territorial principal com status “conquistou/atacou/defendeu/sem efeito”.
  - Lista curta de ações territoriais com variação de escudo.
- **Estados de tile visuais e consistentes**: neutro (cinza claro), dominado (cor da bandeira/usuário), em disputa (destaque laranja com contorno).
- **Paleta base (clean)**: fundo claro/neutro, acento principal verde/teal, disputa em laranja, texto principal em alto contraste.
- **Bandeiras objetivas**: lista de bandeiras + ação de criar/entrar; confirma que ações passam a contar para o time.
- **Perfil básico**: métricas simples e histórico curto de ações territoriais.

---

## 6) Regras do jogo (parâmetros operacionais)
### 6.1 Loop válido (MVP)
- **Distância mínima:** 1,2 km
- **Tempo mínimo:** 7 min
- **Fechamento:** ponto final a **≤ 40 m** do ponto inicial
- **Cobertura do tile:** **≥ 60%** da distância do loop dentro do tile
- **Qualidade mínima de GPS:** se degradar de forma persistente, a corrida não gera ação territorial

### 6.2 Antifraude mínimo (impacto em território)
- **Velocidade sustentada improvável:** > 25 km/h por mais de 30s
- **Teleportes:** saltos abruptos de localização
- **Baixa qualidade consistente de sinal**

**Princípio:** não punir o treino, apenas cortar o efeito competitivo.

---

## 7) Propriedade e disputa (escudo + cooldown)
### 7.1 Estados do tile
- Neutro
- Dominado (por usuário solo ou bandeira)
- Em disputa (escudo abaixo de limiar)

### 7.2 Escudo e troca
- Conquista de tile neutro: **Escudo = 100**
- Ataque válido de rival: **-35**
- Defesa válida do dono/mesma bandeira: **+20** (cap 100)
- Troca de dono: quando escudo **≤ 0**
- Novo dono entra com **Escudo = 65**
- **Cooldown após troca:** 18h
  - Durante cooldown, tile não troca de dono
  - Ataques podem reduzir escudo até **mínimo 65**

### 7.3 Em disputa
- Tile em disputa quando escudo **< 70**

---

## 8) Limites de impacto (balanceamento)
- **Cap individual:** 3 ações territoriais/dia
- **Cap por bandeira:** 60 ações territoriais/dia

---

## 9) Modelo Solo + Bandeiras
- Solo é um modo completo
- Ao entrar numa bandeira, histórico solo permanece no perfil
- A partir da entrada, novas ações contam para a bandeira
- Guardião (MVP): usuário com maior contribuição no tile na semana (informativo)

---

## 10) Telas mínimas iOS
- Mapa
- Acompanhamento de corrida (companion Fitness/Saúde)
- Resultado da corrida clean (resumo + métricas + ações territoriais)
- Bandeiras (criar/entrar)
- Perfil básico

---

## 11) Critérios de aceite da V1 iOS
1. Um corredor consegue **correr pelo Fitness/Saúde** e ver a corrida **sincronizada e registrada** no LigaRun com resultado territorial no mapa.
2. Loop válido gera **conquista/ataque/defesa** conforme regras definidas.
3. Loop inválido salva a corrida, mas **não gera ação territorial**.
4. Ao entrar numa bandeira, **ações futuras contam para o time**.
5. A visualização de tiles mostra corretamente **neutro/dominado/em disputa**.

---

## 12) Checklist técnico de aceite (mínimo)
- Permissões de Saúde (HealthKit) e localização tratadas
- Sincronização de corrida via Fitness/Saúde funcional (iPhone/Apple Watch)
- Qualidade de rota/sinal ruim tratada na validação (não gera efeito competitivo quando inválida)
- Corrida inválida salva sem efeito territorial
- Upload/validação responde em menos de 10s em rede estável
- Tiles atualizam no mapa após resultado (sem precisar reiniciar o app)

---

## 13) Tabela rápida de parâmetros (MVP Curitiba)
- Tile: hex ~250m raio
- Loop mínimo: 1,2 km / 7 min / fechamento ≤ 40m / 60% dentro do tile
- Ataque: -35 escudo
- Defesa: +20 escudo (cap 100)
- Troca: escudo ≤ 0 → novo dono com 65
- Cooldown: 18h (sem troca; escudo mínimo 65)
- Em disputa: escudo < 70
- Cap individual: 3 ações/dia
- Cap bandeira: 60 ações/dia
