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
        return "Padrão suspeito detectado (\(flag))"
    }

    let translations: [String: String] = [
        "distance_too_short": "Distância muito curta (mínimo 1.2km)",
        "duration_too_short": "Duração muito curta (mínimo 7 minutos)",
        "loop_not_closed": "Loop não fechado (máximo 40m entre início e fim)",
        "insufficient_tile_coverage": "Cobertura insuficiente do tile (mínimo 60%)",
        "fraud_detected": "Padrão suspeito detectado",
        "outside_game_area": "Fora da área do jogo (Curitiba)",
        "no_primary_tile": "Não foi possível determinar um tile principal para essa corrida.",
        "user_daily_cap_reached": "Limite diário de ações atingido.",
        "bandeira_daily_cap_reached": "Limite diário de ações da bandeira atingido.",
        "cannot_determine_action": "Não foi possível determinar a ação (conquista/ataque/defesa).",
        "tile_already_owned": "Tile já possui dono.",
        "cannot_attack_neutral": "Não é possível atacar um tile neutro.",
        "cannot_attack_own_tile": "Não é possível atacar o próprio tile.",
        "tile_in_cooldown": "Tile em cooldown; ataque bloqueado no momento.",
        "cannot_defend_rival_tile": "Não é possível defender um tile que não é seu."
    ]
    return translations[reason] ?? reason
}
