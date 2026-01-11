import { create } from 'zustand'
import { api, User } from './api'

interface AuthState {
    user: User | null
    isLoading: boolean
    isAuthenticated: boolean

    // Actions
    login: (email: string, password: string) => Promise<void>
    register: (email: string, username: string, password: string) => Promise<void>
    logout: () => void
    loadUser: () => Promise<void>
    updateUser: (user: Partial<User>) => void
}

export const useAuth = create<AuthState>((set, get) => ({
    user: null,
    isLoading: true,
    isAuthenticated: false,

    login: async (email: string, password: string) => {
        const response = await api.login(email, password)
        api.setToken(response.token)
        set({ user: response.user, isAuthenticated: true })
    },

    register: async (email: string, username: string, password: string) => {
        const response = await api.register(email, username, password)
        api.setToken(response.token)
        set({ user: response.user, isAuthenticated: true })
    },

    logout: () => {
        api.setToken(null)
        set({ user: null, isAuthenticated: false })
    },

    loadUser: async () => {
        set({ isLoading: true })
        try {
            const token = api.getToken()
            if (!token) {
                set({ isLoading: false, user: null, isAuthenticated: false })
                return
            }

            const user = await api.getMe()
            set({ user, isAuthenticated: true, isLoading: false })
        } catch (error) {
            api.setToken(null)
            set({ user: null, isAuthenticated: false, isLoading: false })
        }
    },

    updateUser: (updates: Partial<User>) => {
        const current = get().user
        if (current) {
            set({ user: { ...current, ...updates } })
        }
    },
}))
