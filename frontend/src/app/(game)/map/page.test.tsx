import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'

jest.mock('next/dynamic', () => () => {
    return function MockHexMap() {
        return <div data-testid="hex-map">Hex map</div>
    }
})

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
        getTileStats: jest.fn(),
        getDailyStatus: jest.fn(),
        getMyRuns: jest.fn(),
        getBandeiraRankings: jest.fn(),
        getBandeiras: jest.fn(),
        getBandeiraMembers: jest.fn(),
    },
}))

import { useAuth } from '@/lib/auth'
import { api } from '@/lib/api'
import MapPage from './page'

describe('MapPage', () => {
    beforeEach(() => {
        ;(useAuth as unknown as jest.Mock).mockReturnValue({
            user: {
                id: 'u1',
                username: 'runner',
                role: 'ADMIN',
                bandeiraId: 'b1',
                bandeiraName: 'Passada Forte',
                totalRuns: 12,
                totalDistance: 78000,
            },
        })

        ;(api as any).getTileStats.mockResolvedValue({
            totalTiles: 120,
            ownedTiles: 24,
            neutralTiles: 80,
            tilesInDispute: 16,
            disputePercentage: 13.3,
        })
        ;(api as any).getDailyStatus.mockResolvedValue({
            userActionsUsed: 1,
            userActionsRemaining: 2,
            bandeiraActionsUsed: 3,
            bandeiraActionCap: 8,
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
            {
                id: 'r2',
                userId: 'u1',
                origin: 'IMPORT',
                status: 'VALIDATED',
                distance: 6000,
                duration: 1920,
                startTime: '2026-03-11T07:00:00.000Z',
                endTime: '2026-03-11T07:32:00.000Z',
                minLat: null,
                minLng: null,
                maxLat: null,
                maxLng: null,
                isLoopValid: true,
                loopDistance: 5800,
                territoryAction: 'DEFENSE',
                targetTileId: 'tile-2',
                isValidForTerritory: true,
                fraudFlags: [],
                createdAt: '2026-03-11T07:40:00.000Z',
            },
        ])
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
        ])
        ;(api as any).getBandeiras.mockResolvedValue([
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
        ])
        ;(api as any).getBandeiraMembers.mockResolvedValue([
            {
                id: 'm1',
                username: 'captain',
                avatarUrl: null,
                role: 'ADMIN',
                totalTilesConquered: 9,
            },
        ])
    })

    test('renders the control center dashboard', async () => {
        render(<MapPage />)

        await waitFor(() =>
            expect(
                screen.getByRole('heading', {
                    name: /Tudo o que o corredor e a bandeira precisam ler/i,
                })
            ).toBeInTheDocument()
        )

        expect(screen.getByText('78.0 km')).toBeInTheDocument()
        expect(screen.getByTestId('hex-map')).toBeInTheDocument()
        expect(screen.getByText(/Selecione um tile no mapa\./i)).toBeInTheDocument()
    })
})
