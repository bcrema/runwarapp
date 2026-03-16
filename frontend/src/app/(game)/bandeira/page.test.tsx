import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

jest.mock('next/link', () => ({
    __esModule: true,
    default: ({ href, children, ...props }: any) => (
        <a href={href} {...props}>
            {children}
        </a>
    ),
}))

jest.mock('next/navigation', () => ({
    useRouter: jest.fn(),
}))

jest.mock('@/lib/auth', () => ({
    useAuth: jest.fn(),
}))

jest.mock('@/lib/api', () => ({
    api: {
        getBandeiras: jest.fn(),
        getBandeiraRankings: jest.fn(),
        getBandeiraMembers: jest.fn(),
    },
}))

import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth'
import { api } from '@/lib/api'
import BandeiraPage from './page'

describe('BandeiraPage', () => {
    beforeEach(() => {
        ;(useRouter as unknown as jest.Mock).mockReturnValue({ push: jest.fn() })
        ;(useAuth as unknown as jest.Mock).mockReturnValue({
            user: {
                id: 'u1',
                username: 'runner',
                bandeiraId: null,
            },
            loadUser: jest.fn(),
        })

        const bandeiras = [
            {
                id: 'b1',
                name: 'Passada Forte',
                slug: 'passada-forte',
                category: 'ASSESSORIA',
                color: '#ff6633',
                logoUrl: null,
                description: 'Assessoria focada em performance.',
                memberCount: 42,
                totalTiles: 18,
                createdById: 'u1',
                createdByUsername: 'runner',
            },
            {
                id: 'b2',
                name: 'Crew da Orla',
                slug: 'crew-da-orla',
                category: 'GRUPO',
                color: '#3366ff',
                logoUrl: null,
                description: 'Grupo social para longoes.',
                memberCount: 18,
                totalTiles: 9,
                createdById: 'u2',
                createdByUsername: 'coach',
            },
        ]

        ;(api as any).getBandeiras.mockResolvedValue(bandeiras)
        ;(api as any).getBandeiraRankings.mockResolvedValue(bandeiras)
        ;(api as any).getBandeiraMembers.mockResolvedValue([])
    })

    test('filters the directory for new communities', async () => {
        const user = userEvent.setup()

        render(<BandeiraPage />)

        await waitFor(() =>
            expect(
                screen.getByRole('heading', {
                    name: /O lugar para gerir a equipe atual e atrair novas comunidades/i,
                })
            ).toBeInTheDocument()
        )

        await user.type(
            screen.getByPlaceholderText(/Buscar bandeira, assessoria ou grupo/i),
            'Orla'
        )

        expect(screen.getByText('Crew da Orla')).toBeInTheDocument()
        expect(screen.queryByText('Passada Forte')).not.toBeInTheDocument()
    })
})
