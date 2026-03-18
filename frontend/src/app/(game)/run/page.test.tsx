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

jest.mock('@/lib/auth', () => ({
    useAuth: jest.fn(),
}))

jest.mock('@/lib/api', () => ({
    api: {
        getMyRuns: jest.fn(),
    },
}))

import { useAuth } from '@/lib/auth'
import { api } from '@/lib/api'
import RunPage from './page'

describe('RunPage', () => {
    beforeEach(() => {
        ;(useAuth as unknown as jest.Mock).mockReturnValue({
            user: {
                id: 'u1',
                username: 'runner',
                totalRuns: 12,
                totalDistance: 78000,
            },
        })

        ;(api as any).getMyRuns.mockResolvedValue([
            {
                id: 'r1',
                userId: 'u1',
                origin: 'IOS',
                status: 'VALIDATED',
                distance: 10000,
                duration: 3000,
                startTime: '2026-03-14T07:00:00.000Z',
                endTime: '2026-03-14T07:50:00.000Z',
                minLat: null,
                minLng: null,
                maxLat: null,
                maxLng: null,
                isLoopValid: true,
                loopDistance: 9800,
                territoryAction: 'CONQUEST',
                targetTileId: 'tile-1',
                isValidForTerritory: true,
                fraudFlags: [],
                createdAt: '2026-03-14T08:00:00.000Z',
            },
        ])
    })

    test('shows sessions analysis instead of run capture actions', async () => {
        render(<RunPage />)

        await waitFor(() =>
            expect(
                screen.getByRole('heading', {
                    name: /O navegador não grava corrida/i,
                })
            ).toBeInTheDocument()
        )

        expect(screen.getByText(/Últimas sessões lidas pelo sistema/i)).toBeInTheDocument()
        expect(screen.queryByText('Upload GPX')).not.toBeInTheDocument()
        expect(screen.getByText('Conquista')).toBeInTheDocument()
    })
})
