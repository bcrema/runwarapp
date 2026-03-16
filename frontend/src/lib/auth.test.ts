import type { User } from './api'
import { api } from './api'
import { useAuth } from './auth'

jest.mock('./api', () => ({
    api: {
        login: jest.fn(),
        register: jest.fn(),
        socialExchange: jest.fn(),
        socialLinkConfirm: jest.fn(),
        logout: jest.fn(),
        getToken: jest.fn(),
        getMe: jest.fn(),
        resetTokens: jest.fn(),
    },
}))

describe('useAuth store', () => {
    const mockApi = api as unknown as {
        login: jest.Mock
        register: jest.Mock
        socialExchange: jest.Mock
        socialLinkConfirm: jest.Mock
        logout: jest.Mock
        getToken: jest.Mock
        getMe: jest.Mock
        resetTokens: jest.Mock
    }

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
        jest.clearAllMocks()
        useAuth.setState({ user: null, isLoading: true, isAuthenticated: false })
    })

    test('login updates auth state', async () => {
        mockApi.login.mockResolvedValueOnce({ accessToken: 't1', refreshToken: 'r1', user })

        await useAuth.getState().login('user@example.com', 'secret')

        expect(mockApi.login).toHaveBeenCalledWith('user@example.com', 'secret')
        expect(useAuth.getState().user).toEqual(user)
        expect(useAuth.getState().isAuthenticated).toBe(true)
    })

    test('logout clears state and calls api.logout', async () => {
        useAuth.setState({ user, isAuthenticated: true })
        mockApi.logout.mockResolvedValueOnce(undefined)

        await useAuth.getState().logout()

        expect(mockApi.logout).toHaveBeenCalled()
        expect(useAuth.getState().user).toBe(null)
        expect(useAuth.getState().isAuthenticated).toBe(false)
    })

    test('loadUser without token leaves unauthenticated', async () => {
        mockApi.getToken.mockReturnValueOnce(null)

        await useAuth.getState().loadUser()

        expect(mockApi.getMe).not.toHaveBeenCalled()
        expect(useAuth.getState().isLoading).toBe(false)
        expect(useAuth.getState().user).toBe(null)
        expect(useAuth.getState().isAuthenticated).toBe(false)
    })

    test('loadUser with token populates user', async () => {
        mockApi.getToken.mockReturnValueOnce('t1')
        mockApi.getMe.mockResolvedValueOnce(user)

        await useAuth.getState().loadUser()

        expect(mockApi.getMe).toHaveBeenCalledTimes(1)
        expect(useAuth.getState().isLoading).toBe(false)
        expect(useAuth.getState().isAuthenticated).toBe(true)
        expect(useAuth.getState().user).toEqual(user)
    })

    test('loadUser error resets stored tokens', async () => {
        mockApi.getToken.mockReturnValueOnce('t1')
        mockApi.getMe.mockRejectedValueOnce(new Error('fail'))

        await useAuth.getState().loadUser()

        expect(mockApi.resetTokens).toHaveBeenCalled()
        expect(useAuth.getState().user).toBe(null)
        expect(useAuth.getState().isAuthenticated).toBe(false)
    })

    test('socialAuthenticate sets user', async () => {
        mockApi.socialExchange.mockResolvedValueOnce({ accessToken: 't1', refreshToken: 'r1', user })

        await useAuth.getState().socialAuthenticate({ provider: 'google' })

        expect(mockApi.socialExchange).toHaveBeenCalledWith({ provider: 'google' })
        expect(useAuth.getState().user).toEqual(user)
    })

    test('linkSocialAccount sets user', async () => {
        mockApi.socialLinkConfirm.mockResolvedValueOnce({ accessToken: 't1', refreshToken: 'r1', user })

        await useAuth.getState().linkSocialAccount({
            linkToken: 'link',
            email: 'user@example.com',
            password: 'secret',
        })

        expect(mockApi.socialLinkConfirm).toHaveBeenCalledWith({
            linkToken: 'link',
            email: 'user@example.com',
            password: 'secret',
        })
        expect(useAuth.getState().user).toEqual(user)
    })
})
