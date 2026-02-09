import Foundation

func submissionTileFocusId(for result: RunSubmissionResult) -> String? {
    result.turnResult?.tileId ?? result.territoryResult?.tileId ?? result.loopValidation.primaryTile
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
