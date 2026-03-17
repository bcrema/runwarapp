import XCTest
@testable import LigaRun

final class BandeirasViewModelTests: XCTestCase {
    @MainActor
    func testCreateJoinsLoadAndRefreshesUser() async {
        let bandeira = makeBandeiraFixture(id: "new-b", name: "Nova Bandeira")
        let service = BandeirasServiceSpy()
        service.bandeiras = [bandeira]

        var refreshCalls = 0
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in
                refreshCalls += 1
            }
        )

        await viewModel.create(name: "Nova Bandeira", category: "running", color: "#FF6600", description: "Time")

        XCTAssertEqual(service.createdRequests.count, 1)
        XCTAssertEqual(viewModel.bandeiras.first?.id, "new-b")
        XCTAssertEqual(viewModel.exploreStatus, .loaded)
        XCTAssertEqual(refreshCalls, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testJoinReloadsAndRefreshesUser() async {
        let bandeira = makeBandeiraFixture(id: "join-1", name: "Liga Join")
        let service = BandeirasServiceSpy()
        service.bandeiras = [bandeira]

        var refreshCalls = 0
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in
                refreshCalls += 1
            }
        )

        await viewModel.join(bandeira: bandeira)

        XCTAssertEqual(service.joinCalls, ["join-1"])
        XCTAssertEqual(viewModel.bandeiras.first?.name, "Liga Join")
        XCTAssertEqual(viewModel.exploreStatus, .loaded)
        XCTAssertEqual(refreshCalls, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testLeaveReloadsAndRefreshesUser() async {
        let service = BandeirasServiceSpy()
        service.bandeiras = [makeBandeiraFixture(id: "left")]

        var refreshCalls = 0
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in
                refreshCalls += 1
            }
        )

        await viewModel.leave()

        XCTAssertEqual(service.leaveCalls, 1)
        XCTAssertEqual(viewModel.exploreStatus, .loaded)
        XCTAssertEqual(refreshCalls, 1)
    }

    @MainActor
    func testJoinFailureSetsErrorMessage() async {
        let bandeira = makeBandeiraFixture(id: "error-b")
        let service = BandeirasServiceSpy()
        service.joinError = APIError(error: "JOIN_ERROR", message: "Nao foi possivel entrar", details: nil)
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        await viewModel.join(bandeira: bandeira)

        XCTAssertEqual(viewModel.errorMessage, "Nao foi possivel entrar")
    }

    @MainActor
    func testLoadExplorePublishesEmptyStateWithoutTouchingRanking() async {
        let service = BandeirasServiceSpy()
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.exploreStatus, .empty)
        XCTAssertTrue(viewModel.shouldShowExploreEmptyState)
        XCTAssertEqual(viewModel.exploreEmptyStateTitle, "Nenhuma bandeira disponivel")
        XCTAssertEqual(viewModel.rankingStatus, .idle)
    }

    @MainActor
    func testLoadRankingPublishesLoadingAndLoadedStateIndependently() async {
        let service = BandeirasServiceSpy()
        let gate = AsyncGate()
        service.rankings = [
            makeBandeiraFixture(id: "rank-1", name: "Primeira"),
            makeBandeiraFixture(id: "rank-2", name: "Segunda")
        ]
        service.rankingGate = gate

        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        let task = Task { await viewModel.loadRanking() }
        await Task.yield()

        XCTAssertTrue(viewModel.isRankingLoading)
        XCTAssertTrue(viewModel.rankingBandeiras.isEmpty)
        XCTAssertEqual(viewModel.exploreStatus, .idle)

        await gate.open()
        await task.value

        XCTAssertEqual(viewModel.rankingStatus, .loaded)
        XCTAssertEqual(viewModel.rankingBandeiras.map(\.id), ["rank-1", "rank-2"])
        XCTAssertFalse(viewModel.isRankingLoading)
        XCTAssertEqual(viewModel.exploreStatus, .idle)
    }

    @MainActor
    func testLoadRankingFailureIsIsolatedFromExploreSurface() async {
        let service = BandeirasServiceSpy()
        service.bandeiras = [makeBandeiraFixture(id: "explore-1", name: "Explorar")]
        service.rankingsError = APIError(error: "RANKING_DOWN", message: "Ranking indisponivel", details: nil)

        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        await viewModel.load()
        await viewModel.loadRanking()

        XCTAssertEqual(viewModel.exploreStatus, .loaded)
        XCTAssertEqual(viewModel.bandeiras.map(\.id), ["explore-1"])
        XCTAssertEqual(viewModel.rankingStatus, .failed("Ranking indisponivel"))
        XCTAssertEqual(viewModel.rankingErrorMessage, "Ranking indisponivel")
        XCTAssertTrue(viewModel.rankingBandeiras.isEmpty)
    }

    @MainActor
    func testLoadRankingPublishesEmptyState() async {
        let service = BandeirasServiceSpy()
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        await viewModel.activate(tab: .ranking)

        XCTAssertEqual(viewModel.rankingStatus, .empty)
        XCTAssertTrue(viewModel.shouldShowRankingEmptyState)
        XCTAssertEqual(viewModel.rankingEmptyStateTitle, "Ranking indisponivel")
    }

    @MainActor
    func testRequestMapFocusEmitsCanonicalIntent() {
        let bandeira = makeBandeiraFixture(id: "rank-map", name: "Liga Mapa")
        let service = BandeirasServiceSpy()
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: { nil },
            refreshUserAction: { () async throws in }
        )

        viewModel.requestMapFocus(for: bandeira)

        XCTAssertEqual(
            viewModel.pendingMapIntent,
            BandeirasMapIntent(
                filter: .myBandeira,
                focusContext: .bandeira(bandeiraId: "rank-map")
            )
        )

        viewModel.consumePendingMapIntent()

        XCTAssertNil(viewModel.pendingMapIntent)
    }

    @MainActor
    func testLoadMyTeamSortsContributorsByConquestsAndName() async {
        let service = BandeirasServiceSpy()
        service.members = [
            makeBandeiraMemberFixture(id: "m3", username: "Bruno", role: "MEMBER", totalTilesConquered: 8),
            makeBandeiraMemberFixture(id: "m2", username: "Ana", role: "ADMIN", totalTilesConquered: 12),
            makeBandeiraMemberFixture(id: "m1", username: "Caio", role: "MEMBER", totalTilesConquered: 12),
            makeBandeiraMemberFixture(id: "m4", username: "Duda", role: "MEMBER", totalTilesConquered: 2)
        ]

        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: {
                makeUserFixture(
                    id: "admin-1",
                    bandeiraId: "band-1",
                    bandeiraName: "Liga Centro",
                    role: "ADMIN"
                )
            },
            refreshUserAction: { () async throws in }
        )

        await viewModel.loadMyTeam()

        XCTAssertEqual(viewModel.teamStatus, .loaded)
        XCTAssertEqual(viewModel.sortedTeamMembers.map(\.id), ["m2", "m1", "m3", "m4"])
        XCTAssertEqual(viewModel.topContributors.map(\.id), ["m2", "m1", "m3"])
        XCTAssertEqual(viewModel.teamAdminCount, 1)
        XCTAssertEqual(viewModel.teamTotalConquests, 34)
    }

    @MainActor
    func testLoadMyTeamWithoutBandeiraResetsSurface() async {
        let service = BandeirasServiceSpy()
        service.members = [makeBandeiraMemberFixture()]
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: {
                makeUserFixture(
                    id: "runner-1",
                    bandeiraId: nil,
                    bandeiraName: nil,
                    role: "USER"
                )
            },
            refreshUserAction: { () async throws in }
        )

        await viewModel.loadMyTeam()

        XCTAssertEqual(viewModel.teamStatus, .idle)
        XCTAssertTrue(viewModel.teamMembers.isEmpty)
        XCTAssertEqual(service.getMembersCalls, [])
    }

    @MainActor
    func testUpdateRolePromotesMemberAndReloadsTeam() async {
        let service = BandeirasServiceSpy()
        service.members = [makeBandeiraMemberFixture(id: "member-1", username: "Pat", role: "MEMBER", totalTilesConquered: 3)]
        service.updatedMembers = [makeBandeiraMemberFixture(id: "member-1", username: "Pat", role: "ADMIN", totalTilesConquered: 3)]

        var refreshCalls = 0
        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: {
                makeUserFixture(
                    id: "admin-1",
                    bandeiraId: "band-1",
                    bandeiraName: "Liga Centro",
                    role: "ADMIN"
                )
            },
            refreshUserAction: { () async throws in
                refreshCalls += 1
            }
        )

        await viewModel.loadMyTeam()
        await viewModel.updateRole(for: service.members[0])

        XCTAssertEqual(service.updatedRoleRequests.count, 1)
        XCTAssertEqual(service.updatedRoleRequests.first?.bandeiraId, "band-1")
        XCTAssertEqual(
            service.updatedRoleRequests.first?.request,
            UpdateBandeiraMemberRoleRequest(userId: "member-1", role: "ADMIN")
        )
        XCTAssertEqual(service.getMembersCalls, ["band-1", "band-1"])
        XCTAssertEqual(viewModel.teamMembers.first?.role, "ADMIN")
        XCTAssertEqual(viewModel.noticeMessage, "Pat agora pode gerenciar roles da equipe.")
        XCTAssertEqual(refreshCalls, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testUpdateRoleFailureSurfacesBackendMessage() async {
        let service = BandeirasServiceSpy()
        let member = makeBandeiraMemberFixture(id: "member-1", username: "Pat", role: "ADMIN", totalTilesConquered: 3)
        service.members = [member]
        service.updateRoleError = APIError(error: "LAST_ADMIN", message: "Voce nao pode remover o ultimo admin.", details: nil)

        let viewModel = BandeirasViewModel(
            service: service,
            currentUserProvider: {
                makeUserFixture(
                    id: "admin-1",
                    bandeiraId: "band-1",
                    bandeiraName: "Liga Centro",
                    role: "ADMIN"
                )
            },
            refreshUserAction: { () async throws in }
        )

        await viewModel.loadMyTeam()
        await viewModel.updateRole(for: member)

        XCTAssertEqual(viewModel.errorMessage, "Voce nao pode remover o ultimo admin.")
        XCTAssertEqual(viewModel.roleMutationMemberId, nil)
        XCTAssertEqual(service.updatedRoleRequests.count, 1)
    }

    @MainActor
    func testRoleActionTitleIsHiddenForNonAdminUser() async {
        let member = makeBandeiraMemberFixture(id: "member-1", username: "Pat", role: "MEMBER", totalTilesConquered: 3)
        let viewModel = BandeirasViewModel(
            service: BandeirasServiceSpy(),
            currentUserProvider: {
                makeUserFixture(
                    id: "runner-1",
                    bandeiraId: "band-1",
                    bandeiraName: "Liga Centro",
                    role: "MEMBER"
                )
            },
            refreshUserAction: { () async throws in }
        )

        XCTAssertFalse(viewModel.canManageTeamRoles)
        XCTAssertNil(viewModel.roleActionTitle(for: member))
    }
}

@MainActor
private final class BandeirasServiceSpy: BandeirasServiceProtocol {
    var bandeiras: [Bandeira] = []
    var rankings: [Bandeira] = []
    var members: [BandeiraMember] = []
    var updatedMembers: [BandeiraMember]?
    var joinError: Error?
    var rankingsError: Error?
    var membersError: Error?
    var updateRoleError: Error?
    var rankingGate: AsyncGate?
    private(set) var createdRequests: [CreateBandeiraRequest] = []
    private(set) var joinCalls: [String] = []
    private(set) var getMembersCalls: [String] = []
    private(set) var updatedRoleRequests: [(bandeiraId: String, request: UpdateBandeiraMemberRoleRequest)] = []
    private(set) var leaveCalls = 0

    func getBandeiras() async throws -> [Bandeira] {
        bandeiras
    }

    func getBandeiraMembers(id: String) async throws -> [BandeiraMember] {
        getMembersCalls.append(id)
        if let membersError {
            throw membersError
        }
        return members
    }

    func getBandeiraRankings() async throws -> [Bandeira] {
        if let rankingGate {
            await rankingGate.wait()
        }
        if let rankingsError {
            throw rankingsError
        }
        return rankings
    }

    func searchBandeiras(query: String) async throws -> [Bandeira] {
        bandeiras.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func createBandeira(request: CreateBandeiraRequest) async throws -> Bandeira {
        createdRequests.append(request)
        return bandeiras.first ?? makeBandeiraFixture(id: "created", name: request.name)
    }

    func joinBandeira(id: String) async throws -> Bandeira {
        if let joinError {
            throw joinError
        }
        joinCalls.append(id)
        return bandeiras.first ?? makeBandeiraFixture(id: id)
    }

    func leaveBandeira() async throws {
        leaveCalls += 1
    }

    func updateMemberRole(bandeiraId: String, request: UpdateBandeiraMemberRoleRequest) async throws -> Bool {
        updatedRoleRequests.append((bandeiraId: bandeiraId, request: request))
        if let updateRoleError {
            throw updateRoleError
        }
        if let updatedMembers {
            members = updatedMembers
        }
        return true
    }
}

private actor AsyncGate {
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func open() {
        continuation?.resume()
        continuation = nil
    }
}

private func makeBandeiraMemberFixture(
    id: String = "member-1",
    username: String = "Runner",
    role: String = "MEMBER",
    totalTilesConquered: Int = 5
) -> BandeiraMember {
    BandeiraMember(
        id: id,
        username: username,
        avatarUrl: nil,
        role: role,
        totalTilesConquered: totalTilesConquered
    )
}

private func makeUserFixture(
    id: String,
    bandeiraId: String?,
    bandeiraName: String?,
    role: String
) -> User {
    User(
        id: id,
        email: "\(id)@example.com",
        username: id,
        avatarUrl: nil,
        isPublic: true,
        bandeiraId: bandeiraId,
        bandeiraName: bandeiraName,
        role: role,
        totalRuns: 0,
        totalDistance: 0,
        totalTilesConquered: 0
    )
}
