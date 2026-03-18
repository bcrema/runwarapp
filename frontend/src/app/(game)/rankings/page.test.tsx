import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'

jest.mock('next/link', () => ({
    __esModule: true,
    default: ({ href, children, ...props }: any) => (
        <a href={href} {...props}>
            {children}
        </a>
    ),
}))

jest.mock('@/lib/api', () => ({
    api: {
        getBandeiraRankings: jest.fn(),
    },
}))

import { api } from '@/lib/api'
import RankingsPage from './page'

describe('RankingsPage', () => {
    beforeEach(() => {
        ;(api as any).getBandeiraRankings.mockResolvedValue([
            {
                id: 'b1',
                name: 'Passada Forte',
                slug: 'passada-forte',
                category: 'ASSESSORIA',
                color: '#ff6633',
                logoUrl: null,
                description: null,
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
                description: null,
                memberCount: 18,
                totalTiles: 9,
                createdById: 'u2',
                createdByUsername: 'coach',
            },
        ])
    })

    test('renders the competitive radar context', async () => {
        render(<RankingsPage />)

        await waitFor(() =>
            expect(
                screen.getByRole('heading', {
                    name: /O ranking agora serve para leitura e captação/i,
                })
            ).toBeInTheDocument()
        )

        expect(screen.getAllByText('Passada Forte')).toHaveLength(2)
        expect(screen.getByText(/Assessoria - 42 membros/i)).toBeInTheDocument()
    })
})
