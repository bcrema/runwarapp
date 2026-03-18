import type { Bandeira, DailyStatus, Run, TileStats, User } from './api'

const DAY_IN_MS = 24 * 60 * 60 * 1000

const BANDEIRA_CATEGORY_LABELS: Record<Bandeira['category'], string> = {
    ASSESSORIA: 'Assessoria',
    ACADEMIA: 'Academia',
    BOX: 'Box',
    GRUPO: 'Grupo',
}

const ROLE_LABELS: Record<User['role'], string> = {
    ADMIN: 'Capitão',
    COACH: 'Coach',
    MEMBER: 'Membro',
}

export interface RunnerSnapshot {
    totalDistance: number
    totalRuns: number
    weeklyDistance: number
    activeDays: number
    validatedRate: number
    territoryConversion: number
    averagePace: string
    longestRun: number
    lastRunAt: string | null
}

export interface TerritorySnapshot {
    ownedShare: number
    disputedShare: number
    userActionsRemaining: number | null
    bandeiraActionsRemaining: number | null
    conquestRuns: number
    attackRuns: number
    defenseRuns: number
}

export interface CategoryBreakdownItem {
    category: Bandeira['category']
    label: string
    count: number
    memberCount: number
    totalTiles: number
}

export function getCategoryLabel(category: Bandeira['category']): string {
    return BANDEIRA_CATEGORY_LABELS[category]
}

export function getRoleLabel(role: User['role']): string {
    return ROLE_LABELS[role]
}

export function formatDistance(meters: number): string {
    if (meters >= 1000) {
        return `${(meters / 1000).toFixed(1)} km`
    }
    return `${Math.round(meters)} m`
}

export function formatCompactNumber(value: number): string {
    return new Intl.NumberFormat('pt-BR', {
        notation: 'compact',
        maximumFractionDigits: 1,
    }).format(value)
}

export function formatDuration(seconds: number): string {
    if (seconds <= 0) return '0min'

    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)

    if (hours > 0) {
        return `${hours}h ${String(minutes).padStart(2, '0')}min`
    }

    return `${Math.max(minutes, 1)}min`
}

export function formatPace(distanceMeters: number, durationSeconds: number): string {
    if (distanceMeters <= 0 || durationSeconds <= 0) {
        return '--'
    }

    const secondsPerKm = durationSeconds / (distanceMeters / 1000)
    const minutes = Math.floor(secondsPerKm / 60)
    const seconds = Math.round(secondsPerKm % 60)

    if (Number.isNaN(minutes) || Number.isNaN(seconds)) {
        return '--'
    }

    return `${minutes}:${String(seconds).padStart(2, '0')}/km`
}

export function formatPercentage(value: number): string {
    return `${Math.round(value * 100)}%`
}

export function formatDateLabel(value: string | null): string {
    if (!value) return 'Sem registro'

    return new Intl.DateTimeFormat('pt-BR', {
        day: '2-digit',
        month: 'short',
    }).format(new Date(value))
}

export function sortRunsByDate(runs: Run[]): Run[] {
    return [...runs].sort(
        (a, b) =>
            new Date(b.endTime || b.createdAt).getTime() -
            new Date(a.endTime || a.createdAt).getTime()
    )
}

export function getRecentRuns(runs: Run[], days: number, now = new Date()): Run[] {
    const threshold = now.getTime() - days * DAY_IN_MS

    return runs.filter((run) => {
        const timestamp = new Date(run.endTime || run.createdAt).getTime()
        return Number.isFinite(timestamp) && timestamp >= threshold
    })
}

export function buildRunnerSnapshot(
    user: User | null,
    runs: Run[],
    now = new Date()
): RunnerSnapshot {
    const sortedRuns = sortRunsByDate(runs)
    const weeklyRuns = getRecentRuns(sortedRuns, 7, now)
    const validatedRuns = sortedRuns.filter((run) => run.status === 'VALIDATED')
    const territoryRuns = validatedRuns.filter(
        (run) => run.isValidForTerritory && run.territoryAction !== null
    )
    const totalDistance =
        user?.totalDistance ??
        sortedRuns.reduce((total, run) => total + run.distance, 0)
    const totalRuns = user?.totalRuns ?? sortedRuns.length
    const distanceForPace = validatedRuns.reduce((total, run) => total + run.distance, 0)
    const durationForPace = validatedRuns.reduce((total, run) => total + run.duration, 0)

    return {
        totalDistance,
        totalRuns,
        weeklyDistance: weeklyRuns.reduce((total, run) => total + run.distance, 0),
        activeDays: new Set(
            weeklyRuns.map((run) => new Date(run.endTime || run.createdAt).toISOString().slice(0, 10))
        ).size,
        validatedRate: sortedRuns.length > 0 ? validatedRuns.length / sortedRuns.length : 0,
        territoryConversion:
            validatedRuns.length > 0 ? territoryRuns.length / validatedRuns.length : 0,
        averagePace: formatPace(distanceForPace, durationForPace),
        longestRun: sortedRuns.reduce((longest, run) => Math.max(longest, run.distance), 0),
        lastRunAt: sortedRuns[0]?.endTime || sortedRuns[0]?.createdAt || null,
    }
}

export function buildTerritorySnapshot(
    stats: TileStats | null,
    dailyStatus: DailyStatus | null,
    runs: Run[]
): TerritorySnapshot {
    const validatedRuns = runs.filter((run) => run.status === 'VALIDATED')

    return {
        ownedShare:
            stats && stats.totalTiles > 0 ? stats.ownedTiles / stats.totalTiles : 0,
        disputedShare:
            stats && stats.totalTiles > 0 ? stats.tilesInDispute / stats.totalTiles : 0,
        userActionsRemaining: dailyStatus?.userActionsRemaining ?? null,
        bandeiraActionsRemaining:
            dailyStatus?.bandeiraActionCap != null &&
            dailyStatus.bandeiraActionsUsed != null
                ? Math.max(
                      dailyStatus.bandeiraActionCap - dailyStatus.bandeiraActionsUsed,
                      0
                  )
                : null,
        conquestRuns: validatedRuns.filter((run) => run.territoryAction === 'CONQUEST').length,
        attackRuns: validatedRuns.filter((run) => run.territoryAction === 'ATTACK').length,
        defenseRuns: validatedRuns.filter((run) => run.territoryAction === 'DEFENSE').length,
    }
}

export function buildCategoryBreakdown(
    bandeiras: Bandeira[]
): CategoryBreakdownItem[] {
    const categories: Bandeira['category'][] = ['ASSESSORIA', 'GRUPO', 'ACADEMIA', 'BOX']

    return categories
        .map((category) => {
            const items = bandeiras.filter((bandeira) => bandeira.category === category)

            return {
                category,
                label: getCategoryLabel(category),
                count: items.length,
                memberCount: items.reduce((total, item) => total + item.memberCount, 0),
                totalTiles: items.reduce((total, item) => total + item.totalTiles, 0),
            }
        })
        .filter((item) => item.count > 0)
}

export function getRunStatusLabel(run: Run): string {
    switch (run.status) {
        case 'VALIDATED':
            return 'Validada'
        case 'REJECTED':
            return 'Rejeitada'
        default:
            return 'Recebida'
    }
}

export function getRunOutcomeLabel(run: Run): string {
    switch (run.territoryAction) {
        case 'CONQUEST':
            return 'Conquista'
        case 'ATTACK':
            return 'Ataque'
        case 'DEFENSE':
            return 'Defesa'
        default:
            return run.isValidForTerritory ? 'Sem ação' : 'Fora de território'
    }
}
