import type { User } from './api'
import { api } from './api'

describe('api client', () => {
    const user: User = {
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

    beforeEach(() => {
        api.setToken(null)
        localStorage.clear()
        ;(global.fetch as unknown as jest.Mock | undefined)?.mockReset?.()
    })

    test('setToken persists token in localStorage', () => {
        api.setToken('t1')
        expect(localStorage.getItem('runwar_token')).toBe('t1')
    })

    test('getToken reads token from localStorage when not cached', () => {
        api.setToken(null)
        localStorage.setItem('runwar_token', 't1')
        expect(api.getToken()).toBe('t1')
    })

    test('login posts JSON and returns parsed response', async () => {
        global.fetch = jest.fn().mockResolvedValueOnce({
            ok: true,
            text: async () => JSON.stringify({ accessToken: 't1', refreshToken: 'r1', user }),
        })

        const response = await api.login('user@example.com', 'secret')

        expect(response.accessToken).toBe('t1')
        expect(response.refreshToken).toBe('r1')
        expect(response.user).toEqual(user)

        const [url, options] = (global.fetch as unknown as jest.Mock).mock.calls[0]
        expect(String(url)).toContain('/api/auth/login')
        expect(options).toEqual(
            expect.objectContaining({
                method: 'POST',
                body: JSON.stringify({ email: 'user@example.com', password: 'secret' }),
                headers: expect.objectContaining({
                    'Content-Type': 'application/json',
                }),
            })
        )
    })

    test('authenticated requests include Authorization header', async () => {
        api.setToken('t1')

        global.fetch = jest.fn().mockResolvedValueOnce({
            ok: true,
            text: async () => JSON.stringify(user),
        })

        await api.getMe()

        const [, options] = (global.fetch as unknown as jest.Mock).mock.calls[0]
        expect(options.headers).toEqual(
            expect.objectContaining({
                Authorization: 'Bearer t1',
            })
        )
    })

    test('throws API error message when response is not ok', async () => {
        global.fetch = jest.fn().mockResolvedValueOnce({
            ok: false,
            json: async () => ({ error: 'INVALID', message: 'Credenciais inválidas' }),
        })

        await expect(api.login('user@example.com', 'bad')).rejects.toThrow('Credenciais inválidas')
    })
})
