const envApiUrl = process.env.NEXT_PUBLIC_API_URL
const API_URL =
    envApiUrl && envApiUrl.trim().length > 0
        ? envApiUrl
        : typeof window !== 'undefined'
            ? window.location.origin
            : 'http://localhost:8080'

interface ApiError {
    error: string
    message: string
    details?: Record<string, string>
}

class ApiClient {
    private token: string | null = null

    setToken(token: string | null) {
        this.token = token
        if (token) {
            if (typeof window !== 'undefined') {
                localStorage.setItem('runwar_token', token)
            }
        } else {
            if (typeof window !== 'undefined') {
                localStorage.removeItem('runwar_token')
            }
        }
    }

    getToken(): string | null {
        if (this.token) return this.token
        if (typeof window !== 'undefined') {
            this.token = localStorage.getItem('runwar_token')
        }
        return this.token
    }

    private async request<T>(
        endpoint: string,
        options: RequestInit = {}
    ): Promise<T> {
        const token = this.getToken()

        const headers: Record<string, string> = {
            ...(options.headers as Record<string, string>),
        }

        if (token) {
            headers['Authorization'] = `Bearer ${token}`
        }

        if (!(options.body instanceof FormData)) {
            headers['Content-Type'] = 'application/json'
        }

        const response = await fetch(`${API_URL}${endpoint}`, {
            ...options,
            headers,
        })

        if (!response.ok) {
            const error: ApiError = await response.json().catch(() => ({
                error: 'UNKNOWN',
                message: 'An error occurred',
            }))
            throw new Error(error.message)
        }

        // Handle empty responses
        const text = await response.text()
        if (!text) return {} as T

        return JSON.parse(text)
    }

    // Auth
    async register(email: string, username: string, password: string) {
        return this.request<AuthResponse>('/api/auth/register', {
            method: 'POST',
            body: JSON.stringify({ email, username, password }),
        })
    }

    async login(email: string, password: string) {
        return this.request<AuthResponse>('/api/auth/login', {
            method: 'POST',
            body: JSON.stringify({ email, password }),
        })
    }

    // User
    async getMe() {
        return this.request<User>('/api/users/me')
    }

    async updateProfile(data: Partial<UpdateProfileRequest>) {
        return this.request<User>('/api/users/me', {
            method: 'PUT',
            body: JSON.stringify(data),
        })
    }

    // Tiles
    async getTiles(
        bounds: { minLat: number; minLng: number; maxLat: number; maxLng: number },
        options?: { signal?: AbortSignal }
    ) {
        const params = new URLSearchParams({
            minLat: bounds.minLat.toString(),
            minLng: bounds.minLng.toString(),
            maxLat: bounds.maxLat.toString(),
            maxLng: bounds.maxLng.toString(),
        })
        return this.request<Tile[]>(`/api/tiles?${params}`, { signal: options?.signal })
    }

    async getTile(id: string) {
        return this.request<Tile>(`/api/tiles/${id}`)
    }

    async getTileAtCoordinate(lat: number, lng: number) {
        return this.request<Tile>(`/api/tiles/at?lat=${lat}&lng=${lng}`)
    }

    async getDisputedTiles() {
        return this.request<Tile[]>('/api/tiles/disputed')
    }

    async getTileStats() {
        return this.request<TileStats>('/api/tiles/stats')
    }

    // Runs
    async submitRunGpx(file: File) {
        const formData = new FormData()
        formData.append('file', file)

        return this.request<RunSubmissionResult>('/api/runs', {
            method: 'POST',
            body: formData,
        })
    }

    async submitRunCoordinates(coordinates: Array<{ lat: number; lng: number }>, timestamps: number[]) {
        return this.request<RunSubmissionResult>('/api/runs/coordinates', {
            method: 'POST',
            body: JSON.stringify({ coordinates, timestamps }),
        })
    }

    async getMyRuns(limit = 20) {
        return this.request<Run[]>(`/api/runs?limit=${limit}`)
    }

    async getDailyStatus() {
        return this.request<DailyStatus>('/api/runs/daily-status')
    }

    // Bandeiras
    async getBandeiras() {
        return this.request<Bandeira[]>('/api/bandeiras')
    }

    async getBandeira(id: string) {
        return this.request<Bandeira>(`/api/bandeiras/${id}`)
    }

    async getBandeiraMembers(id: string) {
        return this.request<BandeiraMember[]>(`/api/bandeiras/${id}/members`)
    }

    async createBandeira(data: CreateBandeiraRequest) {
        return this.request<Bandeira>('/api/bandeiras', {
            method: 'POST',
            body: JSON.stringify(data),
        })
    }

    async joinBandeira(id: string) {
        return this.request<Bandeira>(`/api/bandeiras/${id}/join`, {
            method: 'POST',
        })
    }

    async leaveBandeira() {
        return this.request<{ success: boolean }>('/api/bandeiras/leave', {
            method: 'POST',
        })
    }

    async getBandeiraRankings() {
        return this.request<Bandeira[]>('/api/bandeiras/rankings')
    }

    async searchBandeiras(query: string) {
        return this.request<Bandeira[]>(`/api/bandeiras/search?q=${encodeURIComponent(query)}`)
    }
}

// Types
export interface AuthResponse {
    user: User
    token: string
}

export interface User {
    id: string
    email: string
    username: string
    avatarUrl: string | null
    isPublic: boolean
    bandeiraId: string | null
    bandeiraName: string | null
    role: 'ADMIN' | 'COACH' | 'MEMBER'
    totalRuns: number
    totalDistance: number
    totalTilesConquered: number
}

export interface UpdateProfileRequest {
    username?: string
    avatarUrl?: string
    isPublic?: boolean
}

export interface Tile {
    id: string
    lat: number
    lng: number
    boundary: number[][]
    ownerType: 'SOLO' | 'BANDEIRA' | null
    ownerId: string | null
    ownerName: string | null
    ownerColor: string | null
    shield: number
    isInCooldown: boolean
    isInDispute: boolean
    guardianId: string | null
    guardianName: string | null
}

export interface TileStats {
    totalTiles: number
    ownedTiles: number
    neutralTiles: number
    tilesInDispute: number
    disputePercentage: number
}

export interface Run {
    id: string
    userId: string
    distance: number
    duration: number
    startTime: string
    endTime: string
    isLoopValid: boolean
    loopDistance: number | null
    territoryAction: 'CONQUEST' | 'ATTACK' | 'DEFENSE' | null
    targetTileId: string | null
    isValidForTerritory: boolean
    fraudFlags: string[]
    createdAt: string
}

export interface RunSubmissionResult {
    run: Run
    loopValidation: {
        isValid: boolean
        distance: number
        duration: number
        closingDistance: number
        tilesCovered: string[]
        primaryTile: string | null
        primaryTileCoverage: number
        fraudFlags: string[]
        failureReasons: string[]
    }
    territoryResult: {
        success: boolean
        actionType: string | null
        reason: string | null
        ownerChanged: boolean
        shieldChange: number
        shieldBefore: number
        shieldAfter: number
        inDispute: boolean
        tileId: string | null
    } | null
    dailyActionsRemaining: number
}

export interface DailyStatus {
    userActionsUsed: number
    userActionsRemaining: number
    bandeiraActionsUsed: number | null
    bandeiraActionCap: number | null
}

export interface Bandeira {
    id: string
    name: string
    slug: string
    category: 'ASSESSORIA' | 'ACADEMIA' | 'BOX' | 'GRUPO'
    color: string
    logoUrl: string | null
    description: string | null
    memberCount: number
    totalTiles: number
    createdById: string
    createdByUsername: string
}

export interface BandeiraMember {
    id: string
    username: string
    avatarUrl: string | null
    role: string
    totalTilesConquered: number
}

export interface CreateBandeiraRequest {
    name: string
    category: string
    color: string
    description?: string
}

export const api = new ApiClient()
