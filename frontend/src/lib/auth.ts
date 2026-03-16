import { create } from 'zustand'
import { api, SocialExchangeRequest, SocialLinkConfirmRequest, User } from './api'

export interface AuthState {
    user: User | null
    isLoading: boolean
    isAuthenticated: boolean

    login: (email: string, password: string) => Promise<void>
    register: (email: string, username: string, password: string) => Promise<void>
    logout: () => Promise<void>
    loadUser: () => Promise<void>
    updateUser: (user: Partial<User>) => void
    socialAuthenticate: (payload: SocialExchangeRequest) => Promise<void>
    linkSocialAccount: (payload: SocialLinkConfirmRequest) => Promise<void>
}

export const useAuth = create<AuthState>((set, get) => ({
    user: null,
    isLoading: true,
    isAuthenticated: false,

    login: async (email: string, password: string) => {
        const response = await api.login(email, password)
        set({ user: response.user, isAuthenticated: true })
    },

    register: async (email: string, username: string, password: string) => {
        const response = await api.register(email, username, password)
        set({ user: response.user, isAuthenticated: true })
    },

    socialAuthenticate: async (payload: SocialExchangeRequest) => {
        const response = await api.socialExchange(payload)
        set({ user: response.user, isAuthenticated: true })
    },

    linkSocialAccount: async (payload: SocialLinkConfirmRequest) => {
        const response = await api.socialLinkConfirm(payload)
        set({ user: response.user, isAuthenticated: true })
    },

    logout: async () => {
        try {
            await api.logout()
        } finally {
            set({ user: null, isAuthenticated: false })
        }
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
            api.resetTokens()
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
