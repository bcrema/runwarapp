const envApiUrl = process.env.NEXT_PUBLIC_API_URL
const API_URL =
    envApiUrl && envApiUrl.trim().length > 0
        ? envApiUrl
        : typeof window !== 'undefined'
            ? window.location.origin
            : 'http://localhost:8080'

const ACCESS_TOKEN_KEY = 'runwar_token'
const REFRESH_TOKEN_KEY = 'runwar_refresh_token'

export interface SocialExchangeRequest {
    provider: string
    idToken?: string
    authorizationCode?: string
    nonce?: string
    emailHint?: string
    givenName?: string
    familyName?: string
    avatarUrl?: string
}

export interface SocialLinkConfirmRequest {
    linkToken: string
    email: string
    password: string
}

export interface LinkRequiredPayload {
    linkToken: string
    provider: string
    emailMasked?: string
}

interface RefreshRequest {
    refreshToken: string
}

export class LinkRequiredError extends Error {
    readonly payload: LinkRequiredPayload

    constructor(payload: LinkRequiredPayload, message: string) {
        super(message)
        this.name = 'LinkRequiredError'
        this.payload = payload
    }
}

interface ApiError {
    error: string
    message: string
    details?: Record<string, string>
}

class ApiClient {
    private token: string | null = null
    private refreshToken: string | null = null

    setToken(token: string | null) {
        this.storeTokens(token, token ? this.refreshToken : null)
    }

    getToken(): string | null {
        if (this.token) return this.token
        if (typeof window !== 'undefined') {
            this.token = localStorage.getItem(ACCESS_TOKEN_KEY)
        }
        return this.token
    }

    private getRefreshToken(): string | null {
        if (this.refreshToken) return this.refreshToken
        if (typeof window !== 'undefined') {
            this.refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY)
        }
        return this.refreshToken
    }

    private storeTokens(accessToken: string | null, refreshToken: string | null) {
        this.token = accessToken
        this.refreshToken = refreshToken
        if (typeof window === 'undefined') return

        if (accessToken) {
            localStorage.setItem(ACCESS_TOKEN_KEY, accessToken)
        } else {
            localStorage.removeItem(ACCESS_TOKEN_KEY)
        }

        if (refreshToken) {
            localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken)
        } else {
            localStorage.removeItem(REFRESH_TOKEN_KEY)
        }
    }

    private clearTokens() {
        this.storeTokens(null, null)
    }

    private async request<T>(
        endpoint: string,
        options: RequestInit = {},
        allowRetry = true
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

        if (response.status === 401 && allowRetry) {
            const refreshed = await this.tryRefreshAuth()
            if (refreshed) {
                return this.request(endpoint, options, false)
            }
        }

        if (!response.ok) {
            await this.handleError(response)
        }

        const text = await response.text()
        if (!text) return {} as T

        return JSON.parse(text)
    }

    private async handleError(response: Response): Promise<never> {
        const error: ApiError = await response.json().catch(() => ({
            error: 'UNKNOWN',
            message: 'An error occurred',
        }))

        if (response.status === 409 && error.error === 'LINK_REQUIRED') {
            const details = error.details ?? ({} as Record<string, string>)
            const linkPayload: LinkRequiredPayload = {
                linkToken: (details as any).linkToken ?? (error as any).linkToken ?? '',
                provider: (details as any).provider ?? (error as any).provider ?? '',
                emailMasked: (details as any).emailMasked ?? (error as any).emailMasked,
            }
            throw new LinkRequiredError(linkPayload, error.message)
        }

        throw new Error(error.message)
    }

    private async tryRefreshAuth(): Promise<boolean> {
        const refreshToken = this.getRefreshToken()
        if (!refreshToken) {
            return false
        }

        try {
            const response = await fetch(`${API_URL}/api/auth/refresh`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ refreshToken }),
            })
            if (!response.ok) {
                this.clearTokens()
                return false
            }

            const auth = (await response.json()) as AuthResponse
            this.handleAuthResponse(auth)
            return true
        } catch {
            this.clearTokens()
            return false
        }
    }

    private handleAuthResponse(response: AuthResponse): AuthResponse {
        this.storeTokens(response.accessToken, response.refreshToken)
        return response
    }

    // Auth
    async register(email: string, username: string, password: string) {
        const response = await this.request<AuthResponse>('/api/auth/register', {
            method: 'POST',
            body: JSON.stringify({ email, username, password }),
        })
        return this.handleAuthResponse(response)
    }

    async login(email: string, password: string) {
        const response = await this.request<AuthResponse>('/api/auth/login', {
            method: 'POST',
            body: JSON.stringify({ email, password }),
        })
        return this.handleAuthResponse(response)
    }

    async socialExchange(payload: SocialExchangeRequest) {
        const response = await this.request<AuthResponse>('/api/auth/social/exchange', {
            method: 'POST',
            body: JSON.stringify(payload),
        })
        return this.handleAuthResponse(response)
    }

    async socialLinkConfirm(payload: SocialLinkConfirmRequest) {
        const response = await this.request<AuthResponse>('/api/auth/social/link/confirm', {
            method: 'POST',
            body: JSON.stringify(payload),
        })
        return this.handleAuthResponse(response)
    }

    async logout() {
        const refreshToken = this.getRefreshToken()
        try {
            await fetch(`${API_URL}/api/auth/logout`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ refreshToken }),
            })
        } finally {
            this.clearTokens()
        }
    }

    resetTokens() {
        this.clearTokens()
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
    accessToken: string
    refreshToken: string
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
    origin: 'IOS' | 'WEB' | 'IMPORT'
    status: 'RECEIVED' | 'VALIDATED' | 'REJECTED'
    distance: number
    duration: number
    startTime: string
    endTime: string
    minLat: number | null
    minLng: number | null
    maxLat: number | null
    maxLng: number | null
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
    turnResult: {
        actionType: 'CONQUEST' | 'ATTACK' | 'DEFENSE' | null
        tileId: string | null
        h3Index: string | null
        previousOwner: { id: string | null; type: 'SOLO' | 'BANDEIRA' | null } | null
        newOwner: { id: string | null; type: 'SOLO' | 'BANDEIRA' | null } | null
        shieldBefore: number | null
        shieldAfter: number | null
        cooldownUntil: string | null
        disputeState: 'NONE' | 'STABLE' | 'DISPUTED' | null
        capsRemaining: { userActionsRemaining: number; bandeiraActionsRemaining: number | null }
        reasons: string[]
    }
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
