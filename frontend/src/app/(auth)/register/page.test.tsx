import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

jest.mock('next/navigation', () => ({
    useRouter: jest.fn(),
}))

jest.mock('next/link', () => ({
    __esModule: true,
    default: ({ href, children, ...props }: any) => (
        <a href={href} {...props}>
            {children}
        </a>
    ),
}))

jest.mock('@/lib/auth', () => ({
    useAuth: jest.fn(),
}))

import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth'
import { LinkRequiredError } from '@/lib/api'
import RegisterPage from './page'

jest.mock('@/components/social-auth/SocialAuthButtons', () => ({
    __esModule: true,
    default: ({ onSocialSignIn }: any) => (
        <div data-testid="social-buttons">
            <button type="button" onClick={() => onSocialSignIn({ provider: 'google' })}>
                Google Stub
            </button>
        </div>
    ),
}))

describe('RegisterPage', () => {
    const mockRegister = jest.fn()
    const mockSocialAuthenticate = jest.fn()
    const mockLinkSocialAccount = jest.fn()
    const mockPush = jest.fn()

    beforeEach(() => {
        jest.clearAllMocks()
        ;(useRouter as unknown as jest.Mock).mockReturnValue({ push: mockPush })
        ;(useAuth as unknown as jest.Mock).mockReturnValue({
            register: mockRegister,
            socialAuthenticate: mockSocialAuthenticate,
            linkSocialAccount: mockLinkSocialAccount,
        })
    })

    test('submits and redirects on success', async () => {
        const user = userEvent.setup()
        mockRegister.mockResolvedValueOnce(undefined)

        render(<RegisterPage />)

        await user.type(screen.getByLabelText('Email'), 'user@example.com')
        await user.type(screen.getByLabelText('Nome de usuário'), 'runner')
        await user.type(screen.getByLabelText('Senha'), 'secret1')
        await user.type(screen.getByLabelText('Confirmar senha'), 'secret1')
        await user.click(screen.getByRole('button', { name: 'Criar conta' }))

        await waitFor(() => {
            expect(mockRegister).toHaveBeenCalledWith('user@example.com', 'runner', 'secret1')
        })
        await waitFor(() => {
            expect(mockPush).toHaveBeenCalledWith('/map')
        })
    })

    test('highlights explicit linking flow when social auth requires account confirmation', async () => {
        const user = userEvent.setup()
        mockSocialAuthenticate.mockRejectedValueOnce(
            new LinkRequiredError(
                {
                    linkToken: 'link-token',
                    provider: 'google',
                    emailMasked: 'u***@example.com',
                },
                'Vínculo necessário'
            )
        )

        render(<RegisterPage />)

        await user.click(screen.getByRole('button', { name: 'Google Stub' }))

        expect(
            await screen.findByRole('heading', { name: 'Confirme sua conta para continuar com Google' })
        ).toBeInTheDocument()
        expect(screen.getByText('Ação necessária')).toBeInTheDocument()
        expect(screen.getByText('2. Informe a senha atual dessa conta.')).toBeInTheDocument()
        expect(screen.getByPlaceholderText('Senha atual da conta')).toBeInTheDocument()
        expect(screen.getByRole('button', { name: 'Vincular e entrar' })).toBeInTheDocument()
    })
})
