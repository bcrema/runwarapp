'use client'

import { useState } from 'react'
import {
    SocialExchangeRequest,
} from '@/lib/api'
import styles from './social-auth.module.css'

const GOOGLE_SCRIPT = 'https://accounts.google.com/gsi/client'
const APPLE_SCRIPT = 'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js'
const GOOGLE_CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID
const APPLE_CLIENT_ID = process.env.NEXT_PUBLIC_APPLE_CLIENT_ID
const APPLE_REDIRECT_URI = process.env.NEXT_PUBLIC_APPLE_REDIRECT_URI

interface SocialAuthButtonsProps {
    onSocialSignIn: (payload: SocialExchangeRequest) => Promise<void>
    onError?: (error: Error) => void
    disabled?: boolean
}

export default function SocialAuthButtons({
    onSocialSignIn,
    onError,
    disabled = false,
}: SocialAuthButtonsProps) {
    const [loadingProvider, setLoadingProvider] = useState<string | null>(null)

    const handleGoogleClick = async () => {
        if (disabled) return
        if (!GOOGLE_CLIENT_ID) {
            onError?.(new Error('Google OAuth não configurado.'))
            return
        }

        setLoadingProvider('google')
        try {
            const google = await ensureGoogleLibrary()
            google.accounts.id.initialize({
                client_id: GOOGLE_CLIENT_ID,
                callback: async (response: Record<string, string>) => {
                    try {
                        const credential = response.credential
                        if (!credential) throw new Error('Nenhuma credencial Google foi retornada.')
                        await onSocialSignIn({
                            provider: 'google',
                            idToken: credential,
                        })
                    } catch (error) {
                        onError?.(error as Error)
                    }
                },
            })
            google.accounts.id.prompt()
        } catch (error) {
            onError?.(error as Error)
        } finally {
            setLoadingProvider(null)
        }
    }

    const handleAppleClick = async () => {
        if (disabled) return
        if (!APPLE_CLIENT_ID || !APPLE_REDIRECT_URI) {
            onError?.(new Error('Sign in with Apple não configurado.'))
            return
        }

        setLoadingProvider('apple')
        try {
            await ensureAppleLibrary()
            const apple = window.AppleID
            apple.auth.init({
                clientId: APPLE_CLIENT_ID,
                scope: 'name email',
                redirectURI: APPLE_REDIRECT_URI,
                usePopup: true,
            })
            const response = await apple.auth.signIn()
            const authorization = response?.authorization
            const idToken = authorization?.id_token
            const code = authorization?.code

            if (!idToken) throw new Error('Apple nao retornou um token.')

            await onSocialSignIn({
                provider: 'apple',
                idToken,
                authorizationCode: code,
            })
        } catch (error) {
            onError?.(error as Error)
        } finally {
            setLoadingProvider(null)
        }
    }

    return (
        <div className={styles.wrapper}>
            <p className={styles.lead}>Use Google ou Apple para entrar mais rapido.</p>
            <div className={styles.buttons}>
                <button
                    type="button"
                    className={`${styles.button} ${styles.google}`}
                    disabled={disabled || loadingProvider === 'google'}
                    onClick={handleGoogleClick}
                >
                    {loadingProvider === 'google' ? 'Carregando...' : 'Continuar com Google'}
                </button>
                <button
                    type="button"
                    className={`${styles.button} ${styles.apple}`}
                    disabled={disabled || loadingProvider === 'apple'}
                    onClick={handleAppleClick}
                >
                    {loadingProvider === 'apple' ? 'Carregando...' : 'Continuar com Apple'}
                </button>
            </div>
        </div>
    )
}

async function ensureGoogleLibrary() {
    if (typeof window === 'undefined') {
        throw new Error('Ambiente do navegador necessário.')
    }

    if (window.google?.accounts?.id) {
        return window.google
    }

    await loadScript(GOOGLE_SCRIPT)

    if (!window.google?.accounts?.id) {
        throw new Error('Biblioteca de identidade do Google falhou ao carregar.')
    }

    return window.google
}

async function ensureAppleLibrary() {
    if (typeof window === 'undefined') {
        throw new Error('Ambiente do navegador necessário.')
    }

    if (window.AppleID?.auth) {
        return
    }

    await loadScript(APPLE_SCRIPT)

    if (!window.AppleID?.auth) {
        throw new Error('Biblioteca Sign in with Apple falhou ao carregar.')
    }
}

function loadScript(src: string) {
    return new Promise<void>((resolve, reject) => {
        if (typeof document === 'undefined') {
            reject(new Error('Document nao esta disponivel.'))
            return
        }

        if (document.querySelector(`script[src="${src}"]`)) {
            resolve()
            return
        }

        const script = document.createElement('script')
        script.src = src
        script.async = true
        script.onload = () => resolve()
        script.onerror = () => reject(new Error(`Falha ao carregar ${src}`))
        document.body.appendChild(script)
    })
}

declare global {
    interface Window {
        google?: any
        AppleID?: any
    }
}

