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
        getDailyStatus: jest.fn(),
    },
}))

import { useAuth } from '@/lib/auth'
import { api } from '@/lib/api'
import ProfilePage from './page'

describe('ProfilePage', () => {
    beforeEach(() => {
        ;(useAuth as unknown as jest.Mock).mockReturnValue({
            user: {
                id: 'u1',
                email: 'runner@example.com',
                username: 'runner',
                avatarUrl: null,
                isPublic: true,
                bandeiraId: 'b1',
                bandeiraName: 'Passada Forte',
                role: 'ADMIN',
                totalRuns: 12,
                totalDistance: 78000,
                totalTilesConquered: 18,
            },
            isLoading: false,
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
        ;(api as any).getDailyStatus.mockResolvedValue({
            userActionsUsed: 1,
            userActionsRemaining: 2,
            bandeiraActionsUsed: 3,
            bandeiraActionCap: 8,
        })
    })

    test('renders profile metrics and context', async () => {
        render(<ProfilePage />)

        await waitFor(() =>
            expect(screen.getByRole('heading', { name: '@runner' })).toBeInTheDocument()
        )

        expect(screen.getByText('78.0 km')).toBeInTheDocument()
        expect(screen.getAllByText('Passada Forte')).toHaveLength(2)
        expect(screen.getByText(/Como você está performando/i)).toBeInTheDocument()
    })
})
