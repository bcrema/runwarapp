import type { User } from './api'
import { api } from './api'
import { useAuth } from './auth'

jest.mock('./api', () => ({
    api: {
        login: jest.fn(),
        register: jest.fn(),
        setToken: jest.fn(),
        getToken: jest.fn(),
        getMe: jest.fn(),
    },
}))

describe('useAuth store', () => {
    const mockApi = api as unknown as {
        login: jest.Mock
        register: jest.Mock
        setToken: jest.Mock
        getToken: jest.Mock
        getMe: jest.Mock
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

    test('login sets token and user', async () => {
        mockApi.login.mockResolvedValueOnce({ token: 't1', user })

        await useAuth.getState().login('user@example.com', 'secret')

        expect(mockApi.login).toHaveBeenCalledWith('user@example.com', 'secret')
        expect(mockApi.setToken).toHaveBeenCalledWith('t1')
        expect(useAuth.getState().user).toEqual(user)
        expect(useAuth.getState().isAuthenticated).toBe(true)
    })

    test('logout clears token and auth state', () => {
        useAuth.setState({ user, isAuthenticated: true })

        useAuth.getState().logout()

        expect(mockApi.setToken).toHaveBeenCalledWith(null)
        expect(useAuth.getState().user).toBe(null)
        expect(useAuth.getState().isAuthenticated).toBe(false)
    })

    test('loadUser with no token clears loading and leaves unauthenticated', async () => {
        mockApi.getToken.mockReturnValueOnce(null)

        await useAuth.getState().loadUser()

        expect(mockApi.getMe).not.toHaveBeenCalled()
        expect(useAuth.getState().isLoading).toBe(false)
        expect(useAuth.getState().user).toBe(null)
        expect(useAuth.getState().isAuthenticated).toBe(false)
    })

    test('loadUser with token loads user', async () => {
        mockApi.getToken.mockReturnValueOnce('t1')
        mockApi.getMe.mockResolvedValueOnce(user)

        await useAuth.getState().loadUser()

        expect(mockApi.getMe).toHaveBeenCalledTimes(1)
        expect(useAuth.getState().isLoading).toBe(false)
        expect(useAuth.getState().user).toEqual(user)
        expect(useAuth.getState().isAuthenticated).toBe(true)
    })

    test('loadUser clears token on error', async () => {
        mockApi.getToken.mockReturnValueOnce('t1')
        mockApi.getMe.mockRejectedValueOnce(new Error('nope'))

        await useAuth.getState().loadUser()

        expect(mockApi.setToken).toHaveBeenCalledWith(null)
        expect(useAuth.getState().isLoading).toBe(false)
        expect(useAuth.getState().user).toBe(null)
        expect(useAuth.getState().isAuthenticated).toBe(false)
    })
})
