# 05 - Minha Equipe, Top Contribuidores e Roles

## Issue canonica
`GDS v3 iOS / 05 - Minha equipe, top contribuidores e roles`

## Objetivo
- Dono sugerido: `Agente iOS Team/Admin`.
- Dar utilidade minima real para assessoria dentro do iOS sem criar dashboard novo.

## Subagentes
- `05A` Cabecalho da equipe e roster.
- `05B` Top contribuidores e ordenacao.
- `05C` Mutacao de roles para admins.

## Escopo
- Entregaveis:
  - superficie `Minha equipe` dentro do hub de bandeiras;
  - top 3 contribuidores;
  - lista completa de membros;
  - promocao/rebaixamento de role para admin.
- Fora de escopo:
  - presenca semanal;
  - analytics de coach;
  - convites e moderacao avancada.

## Arquivos iOS impactados (minimo)
- `ios/LigaRun/Sources/LigaRun/Features/Bandeiras/BandeirasView.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Bandeiras/BandeirasViewModel.swift`
- `ios/LigaRun/Sources/LigaRun/Networking/APIClient.swift`

## Tarefas detalhadas
1. Exibir estado `sem bandeira` com CTA claro para `Explorar`.
2. Para usuario com bandeira:
   - mostrar cabecalho da equipe;
   - destacar top 3 por `totalQuadrasConquered desc`;
   - listar membros ordenados por contribuicao e nome.
3. Expor mutacao de role somente quando `currentUser.role == ADMIN`.
4. Tratar erros de backend para role:
   - usuario fora da equipe;
   - ultimo admin;
   - permissao insuficiente.

## Criterios de pronto
1. A assessoria enxerga rapidamente os principais contribuidores.
2. O admin consegue gerenciar role sem sair do app.
3. O membro comum nao ve controles administrativos.

## Plano de testes
1. Testes de carregamento de membros.
2. Testes de ordenacao de top contribuidores.
3. Testes de sucesso e erro na mutacao de role.
4. Smoke manual com:
   - usuario sem bandeira;
   - membro;
   - admin.

## Dependencias
- Iniciar apos `02` e `04`.
- Libera `09`.

## Handoff
- Registrar na issue os estados de erro finais para reuso em `09`.

