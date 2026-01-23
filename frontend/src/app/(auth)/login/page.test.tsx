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
import LoginPage from './page'

describe('LoginPage', () => {
    const mockLogin = jest.fn()
    const mockPush = jest.fn()

    beforeEach(() => {
        jest.clearAllMocks()
        ;(useRouter as unknown as jest.Mock).mockReturnValue({ push: mockPush })
        ;(useAuth as unknown as jest.Mock).mockReturnValue({ login: mockLogin })
    })

    test('renders form fields', () => {
        render(<LoginPage />)

        expect(screen.getByRole('heading', { name: 'Entrar' })).toBeInTheDocument()
        expect(screen.getByLabelText('Email')).toBeInTheDocument()
        expect(screen.getByLabelText('Senha')).toBeInTheDocument()
        expect(screen.getByRole('button', { name: 'Entrar' })).toBeInTheDocument()
    })

    test('submits and redirects on success', async () => {
        const user = userEvent.setup()
        mockLogin.mockResolvedValueOnce(undefined)

        render(<LoginPage />)

        await user.type(screen.getByLabelText('Email'), 'user@example.com')
        await user.type(screen.getByLabelText('Senha'), 'secret')
        await user.click(screen.getByRole('button', { name: 'Entrar' }))

        await waitFor(() => {
            expect(mockLogin).toHaveBeenCalledWith('user@example.com', 'secret')
        })
        await waitFor(() => {
            expect(mockPush).toHaveBeenCalledWith('/map')
        })
    })

    test('shows error on failure', async () => {
        const user = userEvent.setup()
        mockLogin.mockRejectedValueOnce(new Error('Credenciais inválidas'))

        render(<LoginPage />)

        await user.type(screen.getByLabelText('Email'), 'user@example.com')
        await user.type(screen.getByLabelText('Senha'), 'wrong')
        await user.click(screen.getByRole('button', { name: 'Entrar' }))

        expect(await screen.findByText('Credenciais inválidas')).toBeInTheDocument()
        expect(mockPush).not.toHaveBeenCalled()
    })
})
