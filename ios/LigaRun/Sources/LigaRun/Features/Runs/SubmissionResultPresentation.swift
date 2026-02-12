import Foundation

enum SubmissionTerritoryImpact: Equatable {
    case conquest
    case attack
    case defense
    case noEffect
}

func submissionTileFocusId(for result: RunSubmissionResult) -> String? {
    result.turnResult?.tileId ?? result.territoryResult?.tileId ?? result.loopValidation.primaryTile
}

func submissionTerritoryImpact(for result: RunSubmissionResult) -> SubmissionTerritoryImpact {
    let actionType = result.turnResult?.actionType ?? result.territoryResult?.actionType
    switch actionType {
    case "CONQUEST":
        return .conquest
    case "ATTACK":
        return .attack
    case "DEFENSE":
        return .defense
    default:
        return .noEffect
    }
}

func submissionTerritoryImpactTitle(for impact: SubmissionTerritoryImpact) -> String {
    switch impact {
    case .conquest:
        return "Conquistou território"
    case .attack:
        return "Atacou território rival"
    case .defense:
        return "Defendeu território"
    case .noEffect:
        return "Sem impacto territorial"
    }
}

func submissionShieldDeltaLabel(for result: RunSubmissionResult) -> String {
    let before = result.turnResult?.shieldBefore ?? result.territoryResult?.shieldBefore
    let after = result.turnResult?.shieldAfter ?? result.territoryResult?.shieldAfter

    guard let before, let after else { return "—" }
    return "\(before) -> \(after)"
}

func submissionRunDurationLabel(for result: RunSubmissionResult) -> String {
    let totalSeconds = max(Int(result.run.duration.rounded()), 0)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%02d:%02d", minutes, seconds)
}

func submissionResultReasons(for result: RunSubmissionResult) -> [String] {
    var rawReasons: [String] = []

    if let turnReasons = result.turnResult?.reasons {
        rawReasons.append(contentsOf: turnReasons)
    }
    rawReasons.append(contentsOf: result.loopValidation.failureReasons)
    rawReasons.append(contentsOf: result.loopValidation.fraudFlags.map { "fraud_flag:\($0)" })
    if let territoryReason = result.territoryResult?.reason {
        rawReasons.append(territoryReason)
    }

    var seen = Set<String>()
    var output: [String] = []
    for reason in rawReasons {
        let translated = translateSubmissionReason(reason)
        guard seen.insert(translated).inserted else { continue }
        output.append(translated)
    }

    return output
}

func translateSubmissionReason(_ reason: String) -> String {
    if reason.hasPrefix("fraud_flag:") {
        let flag = reason.replacingOccurrences(of: "fraud_flag:", with: "")
        return "Padrao suspeito detectado (\(flag))"
    }

    let translations: [String: String] = [
        "distance_too_short": "Distancia muito curta (minimo 1.2km)",
        "duration_too_short": "Duracao muito curta (minimo 7 minutos)",
        "loop_not_closed": "Loop nao fechado (maximo 40m entre inicio e fim)",
        "insufficient_tile_coverage": "Cobertura insuficiente do tile (minimo 60%)",
        "fraud_detected": "Padrao suspeito detectado",
        "outside_game_area": "Fora da area do jogo (Curitiba)",
        "no_primary_tile": "Nao foi possivel determinar um tile principal para essa corrida.",
        "user_daily_cap_reached": "Limite diario de acoes atingido.",
        "bandeira_daily_cap_reached": "Limite diario de acoes da bandeira atingido.",
        "cannot_determine_action": "Nao foi possivel determinar a acao (conquista/ataque/defesa).",
        "tile_already_owned": "Tile ja possui dono.",
        "cannot_attack_neutral": "Nao e possivel atacar um tile neutro.",
        "cannot_attack_own_tile": "Nao e possivel atacar o proprio tile.",
        "tile_in_cooldown": "Tile em cooldown; ataque bloqueado no momento.",
        "cannot_defend_rival_tile": "Nao e possivel defender um tile que nao e seu."
    ]
    return translations[reason] ?? reason
}
