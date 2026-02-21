# 04 - Companion HUD (Modo Competitivo vs Treino)

## Objetivo
- Dono sugerido: `Agente iOS Runtime/UX`.
- Adaptar o companion para refletir elegibilidade da quadra em tempo real sem bloquear a corrida.

## Escopo
- Entregaveis:
  - `ActiveRunHUD` com `currentQuadra`.
  - Exibicao de modo atual: `Competitivo` ou `Treino`.
  - Mensagem clara para bloqueio competitivo quando inelegivel.
- Fora de escopo:
  - Persistencia/upload do modo (passo 05).
  - Tela de resultado final (passo 06).

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Features/Runs/ActiveRunHUD.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Map/HexMapView.swift` (bindings se necessario)

## Tarefas detalhadas
1. Migrar referencias runtime:
   - `currentTile` -> `currentQuadra`
2. Integrar `QuadraEligibilityPolicy`:
   - calcular elegibilidade com `session.currentUser` + quadra atual.
3. Exibir estado de modo:
   - se elegivel => `Modo competitivo`
   - se inelegivel => `Modo treino`
4. Exibir detalhe de bloqueio competitivo:
   - razao objetiva e curta
   - manter corrida ativa normalmente
5. Expor contexto de modo para encerramento da corrida (consumo no passo 05).

## Criterios de pronto
1. Corrida nunca e interrompida por inelegibilidade.
2. Usuario entende claramente quando esta em `Treino`.
3. Estado visual atualiza conforme muda de quadra durante a corrida.

## Plano de testes
1. Atualizar `CompanionRunManagerTests` para garantir propagacao de contexto no stop.
2. Smoke manual:
   - iniciar corrida e entrar em quadra elegivel.
   - transitar para quadra inelegivel e validar troca de modo.
   - encerrar corrida e validar continuidade do fluxo.

## Dependencias
- Iniciar apos `01` e `03`.
- Pode rodar em paralelo com `05`.

