import type { Bandeira, DailyStatus, Run, TileStats, User } from './api'
import {
    buildCategoryBreakdown,
    buildRunnerSnapshot,
    buildTerritorySnapshot,
    formatDistance,
    formatPace,
    getCategoryLabel,
    getRunOutcomeLabel,
    getRunStatusLabel,
} from './dashboard'

describe('dashboard helpers', () => {
    const baseUser: User = {
        id: 'u1',
        email: 'runner@example.com',
        username: 'runner',
        avatarUrl: null,
        isPublic: true,
        bandeiraId: 'b1',
        bandeiraName: 'Passada Forte',
        role: 'ADMIN',
        totalRuns: 12,
        totalDistance: 78000,
        totalTilesConquered: 18,
    }

    const baseRuns: Run[] = [
        {
            id: 'r1',
            userId: 'u1',
            origin: 'IOS',
            status: 'VALIDATED',
            distance: 10000,
            duration: 3000,
            startTime: '2026-03-14T07:00:00.000Z',
            endTime: '2026-03-14T07:50:00.000Z',
            minLat: null,
            minLng: null,
            maxLat: null,
            maxLng: null,
            isLoopValid: true,
            loopDistance: 9800,
            territoryAction: 'CONQUEST',
            targetTileId: 'tile-1',
            isValidForTerritory: true,
            fraudFlags: [],
            createdAt: '2026-03-14T08:00:00.000Z',
        },
        {
            id: 'r2',
            userId: 'u1',
            origin: 'IMPORT',
            status: 'VALIDATED',
            distance: 6000,
            duration: 1920,
            startTime: '2026-03-11T07:00:00.000Z',
            endTime: '2026-03-11T07:32:00.000Z',
            minLat: null,
            minLng: null,
            maxLat: null,
            maxLng: null,
            isLoopValid: true,
            loopDistance: 5800,
            territoryAction: 'DEFENSE',
            targetTileId: 'tile-2',
            isValidForTerritory: true,
            fraudFlags: [],
            createdAt: '2026-03-11T07:40:00.000Z',
        },
        {
            id: 'r3',
            userId: 'u1',
            origin: 'WEB',
            status: 'REJECTED',
            distance: 4500,
            duration: 1500,
            startTime: '2026-02-28T07:00:00.000Z',
            endTime: '2026-02-28T07:25:00.000Z',
            minLat: null,
            minLng: null,
            maxLat: null,
            maxLng: null,
            isLoopValid: false,
            loopDistance: null,
            territoryAction: null,
            targetTileId: null,
            isValidForTerritory: false,
            fraudFlags: ['SHORT_LOOP'],
            createdAt: '2026-02-28T07:30:00.000Z',
        },
    ]

    test('formats public labels', () => {
        expect(getCategoryLabel('ASSESSORIA')).toBe('Assessoria')
        expect(formatDistance(14200)).toBe('14.2 km')
        expect(formatPace(10000, 3000)).toBe('5:00/km')
        expect(getRunStatusLabel(baseRuns[0])).toBe('Validada')
        expect(getRunOutcomeLabel(baseRuns[2])).toBe('Fora de territorio')
    })

    test('buildRunnerSnapshot aggregates runner indicators', () => {
        const snapshot = buildRunnerSnapshot(
            baseUser,
            baseRuns,
            new Date('2026-03-15T12:00:00.000Z')
        )

        expect(snapshot.totalDistance).toBe(78000)
        expect(snapshot.totalRuns).toBe(12)
        expect(snapshot.weeklyDistance).toBe(16000)
        expect(snapshot.activeDays).toBe(2)
        expect(snapshot.validatedRate).toBeCloseTo(2 / 3)
        expect(snapshot.territoryConversion).toBe(1)
        expect(snapshot.averagePace).toBe('5:08/km')
        expect(snapshot.longestRun).toBe(10000)
        expect(snapshot.lastRunAt).toBe('2026-03-14T07:50:00.000Z')
    })

    test('buildTerritorySnapshot aggregates territory indicators', () => {
        const stats: TileStats = {
            totalTiles: 120,
            ownedTiles: 24,
            neutralTiles: 80,
            tilesInDispute: 16,
            disputePercentage: 13.3,
        }
        const dailyStatus: DailyStatus = {
            userActionsUsed: 1,
            userActionsRemaining: 2,
            bandeiraActionsUsed: 3,
            bandeiraActionCap: 8,
        }

        const snapshot = buildTerritorySnapshot(stats, dailyStatus, baseRuns)

        expect(snapshot.ownedShare).toBeCloseTo(0.2)
        expect(snapshot.disputedShare).toBeCloseTo(16 / 120)
        expect(snapshot.userActionsRemaining).toBe(2)
        expect(snapshot.bandeiraActionsRemaining).toBe(5)
        expect(snapshot.conquestRuns).toBe(1)
        expect(snapshot.attackRuns).toBe(0)
        expect(snapshot.defenseRuns).toBe(1)
    })

    test('buildCategoryBreakdown groups directory by category', () => {
        const bandeiras: Bandeira[] = [
            {
                id: 'b1',
                name: 'Passada Forte',
                slug: 'passada-forte',
                category: 'ASSESSORIA',
                color: '#ff6633',
                logoUrl: null,
                description: null,
                memberCount: 42,
                totalTiles: 18,
                createdById: 'u1',
                createdByUsername: 'runner',
            },
            {
                id: 'b2',
                name: 'Pace Clube',
                slug: 'pace-clube',
                category: 'GRUPO',
                color: '#3366ff',
                logoUrl: null,
                description: null,
                memberCount: 18,
                totalTiles: 9,
                createdById: 'u2',
                createdByUsername: 'coach',
            },
            {
                id: 'b3',
                name: 'Sprint House',
                slug: 'sprint-house',
                category: 'ASSESSORIA',
                color: '#11aa88',
                logoUrl: null,
                description: null,
                memberCount: 25,
                totalTiles: 12,
                createdById: 'u3',
                createdByUsername: 'captain',
            },
        ]

        expect(buildCategoryBreakdown(bandeiras)).toEqual([
            {
                category: 'ASSESSORIA',
                label: 'Assessoria',
                count: 2,
                memberCount: 67,
                totalTiles: 30,
            },
            {
                category: 'GRUPO',
                label: 'Grupo',
                count: 1,
                memberCount: 18,
                totalTiles: 9,
            },
        ])
    })
})
