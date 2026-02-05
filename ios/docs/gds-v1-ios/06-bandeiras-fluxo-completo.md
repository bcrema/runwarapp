# 06 - Bandeiras fluxo completo

## Objetivo
- Dono sugerido: `Agente iOS Social`.
- Completar fluxo de bandeiras (criar, entrar, sair) com UX clara sobre contagem de acoes para o time.

## Escopo
- Entregaveis:
  - Criacao de bandeira funcional.
  - Fluxos de entrar/sair robustos.
  - Mensagens de estado que confirmam efeito nas acoes futuras.
  - Tratamento de erro e estados vazios de busca/lista.

## Fora de escopo
- Ranking de bandeiras.
- Moderacao/gestao avancada de membros.

## Pre-requisitos
- `00-decisoes-v1-ios.md` lido.
- Endpoint atual de bandeiras acessivel no ambiente.

## Arquivos iOS impactados
- `ios/LigaRun/Sources/LigaRun/Features/Bandeiras/BandeirasView.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Bandeiras/BandeirasViewModel.swift`
- `ios/LigaRun/Sources/LigaRun/Networking/APIClient.swift`
- `ios/LigaRun/Sources/LigaRun/Models/ApiModels.swift`
- `ios/LigaRun/Tests/LigaRunTests/` (novos testes de view model)

## Tarefas detalhadas
1. Adicionar formulario de criacao de bandeira (nome, categoria, cor, descricao).
2. Integrar `createBandeira` no `BandeirasViewModel`.
3. Revisar UX de `join/leave` com feedback de sucesso e erro.
4. Exibir estado vazio para busca sem resultados.
5. Atualizar usuario logado apos mudanca de bandeira para refletir novas acoes.

## Criterios de pronto
1. Usuario cria bandeira e ela aparece na lista.
2. Usuario entra/sai sem estado inconsistente na UI.
3. Mensagem de impacto em acoes futuras e exibida apos entrar.
4. Erros de API sao recuperaveis e compreensiveis.

## Plano de testes
1. Unitario: `join` e `leave` atualizam estado local corretamente.
2. Unitario: criacao de bandeira com sucesso e com erro.
3. Manual: busca vazia e busca com resultados.
4. Manual: entrada em bandeira reflete em `session.currentUser`.
5. Caso mapeado GDS: `Entrada em bandeira altera destino das acoes futuras`.

## Riscos
- Inconsistencia de estado quando `refreshUser` falha apos join/leave.
- Validacoes de backend para criacao podem variar por ambiente.

## Handoff para proximo passo
- Enviar evidencias de fluxo para `09-hardening-release.md`.
- Sincronizar mensagens de UX com `07-perfil-basico-historico.md`.
