import { api, LinkRequiredError, AuthResponse } from './api'

describe('api client', () => {
    const user = {
        id: 'u1',
        email: 'user@example.com',
        username: 'user',
        avatarUrl: null,
        isPublic: true,
        bandeiraId: null,
        bandeiraName: null,
        role: 'MEMBER',
        totalRuns: 0,
        totalDistance: 0,
        totalTilesConquered: 0,
    }

    const authResponse: AuthResponse = {
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        user,
    }

    beforeEach(() => {
        api.resetTokens()
        localStorage.clear()
        ;(global.fetch as unknown as jest.Mock | undefined)?.mockReset?.()
    })

    test('setToken persists access token', () => {
        api.setToken('token-123')
        expect(localStorage.getItem('runwar_token')).toBe('token-123')
    })

    test('resetTokens clears stored values', () => {
        localStorage.setItem('runwar_token', 'abc')
        localStorage.setItem('runwar_refresh_token', 'refresh')
        api.resetTokens()
        expect(localStorage.getItem('runwar_token')).toBeNull()
        expect(localStorage.getItem('runwar_refresh_token')).toBeNull()
    })

    test('login persists refresh token', async () => {
        (global.fetch as unknown as jest.Mock) = jest.fn().mockResolvedValueOnce({
            ok: true,
            text: async () => JSON.stringify(authResponse),
        })

        const response = await api.login('user@example.com', 'secret')

        expect(response).toEqual(authResponse)
        expect(localStorage.getItem('runwar_refresh_token')).toBe('refresh-1')
    })

    test('retry after 401 refreshes tokens and retries endpoint', async () => {
        const fetchMock = jest.fn()
        fetchMock
            .mockResolvedValueOnce({
                status: 401,
                ok: false,
                json: async () => ({ error: 'UNAUTHORIZED', message: 'Invalid token' }),
                text: async () => '',
            })
            .mockResolvedValueOnce({
                status: 200,
                ok: true,
                json: async () => authResponse,
            })
            .mockResolvedValueOnce({
                status: 200,
                ok: true,
                text: async () => JSON.stringify(user),
            })

        global.fetch = fetchMock
        localStorage.setItem('runwar_refresh_token', 'refresh-1')
        await api.getMe()

        expect(fetchMock).toHaveBeenCalledTimes(3)
        expect(localStorage.getItem('runwar_token')).toBe('access-1')
        expect(localStorage.getItem('runwar_refresh_token')).toBe('refresh-1')
    })

    test('social exchange surfaces link requirement error', async () => {
        global.fetch = jest.fn().mockResolvedValueOnce({
            status: 409,
            ok: false,
            json: async () => ({
                error: 'LINK_REQUIRED',
                message: 'Linking needed',
                linkToken: 'link-token',
                provider: 'google',
                emailMasked: 'u***@example.com',
            }),
        })

        await expect(
            api.socialExchange({ provider: 'google', idToken: 'token' })
        ).rejects.toThrow(LinkRequiredError)
    })
})
