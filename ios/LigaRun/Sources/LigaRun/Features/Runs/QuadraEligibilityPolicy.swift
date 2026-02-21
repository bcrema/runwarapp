import Foundation

enum QuadraEligibilityReason: String, Equatable {
    case missingUserContext = "missing_user_context"
    case missingQuadraOwnershipData = "missing_quadra_ownership_data"
    case userNotOwnerNorChampion = "user_not_owner_nor_champion"
}

enum QuadraEligibilityStatus: Equatable {
    case eligibleCompetitive
    case trainingOnly(reason: QuadraEligibilityReason)
}

struct QuadraEligibilityResult: Equatable {
    let status: QuadraEligibilityStatus

    var reasonSummary: String? {
        guard case let .trainingOnly(reason) = status else { return nil }
        return reason.rawValue
    }
}

struct QuadraEligibilityPolicy {
    func evaluate(currentUser: User?, quadra: Tile) -> QuadraEligibilityResult {
        guard let currentUser else {
            return QuadraEligibilityResult(status: .trainingOnly(reason: .missingUserContext))
        }

        guard hasMinimumOwnershipMetadata(in: quadra) else {
            return QuadraEligibilityResult(status: .trainingOnly(reason: .missingQuadraOwnershipData))
        }

        let isOwner = isOwner(currentUser: currentUser, quadra: quadra)
        let isChampion = isChampion(currentUser: currentUser, quadra: quadra)

        guard isOwner || isChampion else {
            let hasOnlyBandeiraMatchingData = (quadra.ownerType == .bandeira && quadra.ownerId != nil && quadra.championUserId == nil && quadra.championBandeiraId == nil)
                || (quadra.ownerType == nil && quadra.ownerId == nil && quadra.championUserId == nil && quadra.championBandeiraId != nil)

            if hasOnlyBandeiraMatchingData && currentUser.bandeiraId == nil {
                return QuadraEligibilityResult(status: .trainingOnly(reason: .missingUserContext))
            }

            return QuadraEligibilityResult(status: .trainingOnly(reason: .userNotOwnerNorChampion))
        }

        return QuadraEligibilityResult(status: .eligibleCompetitive)
    }

    func canCompete(currentUser: User?, quadra: Tile) -> Bool {
        evaluate(currentUser: currentUser, quadra: quadra).status == .eligibleCompetitive
    }

    private func hasMinimumOwnershipMetadata(in quadra: Tile) -> Bool {
        let hasOwnerMetadata = quadra.ownerType != nil && quadra.ownerId != nil
        let hasChampionMetadata = quadra.championUserId != nil || quadra.championBandeiraId != nil
        return hasOwnerMetadata || hasChampionMetadata
    }

    private func isOwner(currentUser: User, quadra: Tile) -> Bool {
        switch quadra.ownerType {
        case .solo:
            return quadra.ownerId == currentUser.id
        case .bandeira:
            guard let bandeiraId = currentUser.bandeiraId else { return false }
            return quadra.ownerId == bandeiraId
        case .none:
            return false
        }
    }

    private func isChampion(currentUser: User, quadra: Tile) -> Bool {
        if quadra.championUserId == currentUser.id {
            return true
        }

        guard let bandeiraId = currentUser.bandeiraId else { return false }
        return quadra.championBandeiraId == bandeiraId
    }
}
