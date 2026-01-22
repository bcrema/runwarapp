'use client'

import { useEffect, useRef, useState, useCallback } from 'react'
import mapboxgl from 'mapbox-gl'
import { cellToBoundary } from 'h3-js'
import { api, Tile } from '@/lib/api'
import { onTilesRefresh } from '@/lib/tilesRefresh'
import styles from './HexMap.module.css'

// Set Mapbox token
mapboxgl.accessToken = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || ''

interface HexMapProps {
    onTileClick?: (tile: Tile) => void
    className?: string
}

const CURITIBA_CENTER: [number, number] = [-49.27, -25.43]

const PALETTE = {
    neutral: '#6b7280',
    solo: '#3b82f6',
    bandeiraFallback: '#22c55e',
    dispute: '#f59e0b',
} as const

const TILE_OPACITY = {
    neutral: 0.08,
    owned: 0.22,
    dispute: 0.18,
} as const

export default function HexMap({ onTileClick, className }: HexMapProps) {
    const mapContainer = useRef<HTMLDivElement>(null)
    const map = useRef<mapboxgl.Map | null>(null)
    const [tiles, setTiles] = useState<Tile[]>([])
    const [selectedTile, setSelectedTile] = useState<Tile | null>(null)
    const [isLoading, setIsLoading] = useState(true)
    const [topBandeiras, setTopBandeiras] = useState<Array<{ id: string; name: string; color: string }>>([])

    const inFlightRequest = useRef<AbortController | null>(null)
    const debounceTimer = useRef<number | null>(null)
    const boundaryCache = useRef(new Map<string, number[][]>())

    // Load tiles for current viewport
    const loadTiles = useCallback(async () => {
        if (!map.current) return

        const bounds = map.current.getBounds()
        if (!bounds) return

        try {
            inFlightRequest.current?.abort()
            const controller = new AbortController()
            inFlightRequest.current = controller

            const tilesData = await api.getTiles({
                minLat: bounds.getSouth(),
                minLng: bounds.getWest(),
                maxLat: bounds.getNorth(),
                maxLng: bounds.getEast(),
            }, { signal: controller.signal })
            setTiles(tilesData)
        } catch (error) {
            if (error instanceof DOMException && error.name === 'AbortError') return
            console.error('Failed to load tiles:', error)
        }
    }, [])

    const scheduleLoadTiles = useCallback(() => {
        if (debounceTimer.current) window.clearTimeout(debounceTimer.current)
        debounceTimer.current = window.setTimeout(() => {
            loadTiles()
        }, 150)
    }, [loadTiles])

    // Allow other screens (e.g. run upload) to request a viewport refresh.
    useEffect(() => {
        return onTilesRefresh(() => {
            loadTiles()
        })
    }, [loadTiles])

    // Initialize map
    useEffect(() => {
        if (!mapContainer.current || map.current) return

        map.current = new mapboxgl.Map({
            container: mapContainer.current,
            style: 'mapbox://styles/mapbox/dark-v11',
            center: CURITIBA_CENTER,
            zoom: 13,
            minZoom: 10,
            maxZoom: 18,
        })

        map.current.on('load', () => {
            setIsLoading(false)

            // Add source for hexagons
            map.current!.addSource('hexagons', {
                type: 'geojson',
                promoteId: 'id',
                data: {
                    type: 'FeatureCollection',
                    features: [],
                },
            })

            // Add fill layer
            map.current!.addLayer({
                id: 'hexagons-fill',
                type: 'fill',
                source: 'hexagons',
                paint: {
                    'fill-color': [
                        'case',
                        ['==', ['get', 'ownerType'], 'SOLO'],
                        PALETTE.solo,
                        ['==', ['get', 'ownerType'], 'BANDEIRA'],
                        ['coalesce', ['get', 'ownerColor'], PALETTE.bandeiraFallback],
                        PALETTE.neutral,
                    ],
                    'fill-opacity': [
                        'case',
                        ['==', ['get', 'ownerType'], null],
                        TILE_OPACITY.neutral,
                        TILE_OPACITY.owned,
                    ],
                },
            })

            map.current!.addLayer({
                id: 'hexagons-fill-dispute',
                type: 'fill',
                source: 'hexagons',
                filter: ['==', ['get', 'isInDispute'], true],
                paint: {
                    'fill-color': PALETTE.dispute,
                    'fill-opacity': TILE_OPACITY.dispute,
                },
            })

            // Add outline layer
            map.current!.addLayer({
                id: 'hexagons-outline',
                type: 'line',
                source: 'hexagons',
                paint: {
                    'line-color': [
                        'case',
                        ['==', ['get', 'ownerType'], 'BANDEIRA'],
                        ['coalesce', ['get', 'ownerColor'], '#ffffff'],
                        '#ffffff',
                    ],
                    'line-width': 1,
                    'line-opacity': 0.6,
                },
            })

            map.current!.addLayer({
                id: 'hexagons-outline-dispute',
                type: 'line',
                source: 'hexagons',
                filter: ['==', ['get', 'isInDispute'], true],
                paint: {
                    'line-color': PALETTE.dispute,
                    'line-width': 2,
                    'line-opacity': 0.9,
                    'line-dasharray': [2, 2],
                },
            })

            // Click handler
            const handleClick = (e: mapboxgl.MapLayerMouseEvent) => {
                if (!e.features?.[0]) return

                const tileId = e.features[0].properties?.id
                if (!tileId) return

                const tile = tilesRef.current.find((t) => t.id === tileId)
                if (!tile) return

                setSelectedTile(tile)
                onTileClickRef.current?.(tile)
            }

            map.current!.on('click', 'hexagons-fill', handleClick)
            map.current!.on('click', 'hexagons-fill-dispute', handleClick)

            // Hover cursor
            const setPointerCursor = () => {
                map.current!.getCanvas().style.cursor = 'pointer'
            }
            const clearPointerCursor = () => {
                map.current!.getCanvas().style.cursor = ''
            }

            map.current!.on('mouseenter', 'hexagons-fill', setPointerCursor)
            map.current!.on('mouseleave', 'hexagons-fill', clearPointerCursor)
            map.current!.on('mouseenter', 'hexagons-fill-dispute', setPointerCursor)
            map.current!.on('mouseleave', 'hexagons-fill-dispute', clearPointerCursor)

            loadTiles()
        })

        map.current.on('moveend', scheduleLoadTiles)
        map.current.on('zoomend', scheduleLoadTiles)

        return () => {
            inFlightRequest.current?.abort()
            if (debounceTimer.current) window.clearTimeout(debounceTimer.current)
            map.current?.remove()
            map.current = null
        }
    }, [loadTiles, scheduleLoadTiles]) // Removed tiles and onTileClick dependencies

    // Refs to keep track of current state/props for event handlers
    const tilesRef = useRef(tiles)
    const onTileClickRef = useRef(onTileClick)

    useEffect(() => {
        tilesRef.current = tiles
    }, [tiles])

    useEffect(() => {
        onTileClickRef.current = onTileClick
    }, [onTileClick])


    // Update hexagons when tiles change
    useEffect(() => {
        if (!map.current || !map.current.getSource('hexagons')) return

        const features = tiles
            .map((tile) => {
                const ring = getTileRing(tile, boundaryCache.current)
                if (!ring) return null

                return {
                    type: 'Feature' as const,
                    properties: {
                        id: tile.id,
                        ownerType: tile.ownerType,
                        ownerId: tile.ownerId,
                        ownerName: tile.ownerName,
                        ownerColor: tile.ownerColor,
                        isInDispute: tile.isInDispute,
                    },
                    geometry: {
                        type: 'Polygon' as const,
                        coordinates: [ring],
                    },
                }
            })
            .filter(Boolean)

        const source = map.current.getSource('hexagons') as mapboxgl.GeoJSONSource
        source.setData({
            type: 'FeatureCollection',
            features: features as any,
        })
    }, [tiles])

    useEffect(() => {
        const bandeiraCounts = new Map<string, { id: string; name: string; color: string; count: number }>()
        for (const tile of tiles) {
            if (tile.ownerType !== 'BANDEIRA' || !tile.ownerId) continue
            const current = bandeiraCounts.get(tile.ownerId)
            if (current) {
                current.count += 1
                continue
            }
            bandeiraCounts.set(tile.ownerId, {
                id: tile.ownerId,
                name: tile.ownerName || 'Bandeira',
                color: tile.ownerColor || PALETTE.bandeiraFallback,
                count: 1,
            })
        }

        const top = Array.from(bandeiraCounts.values())
            .sort((a, b) => b.count - a.count)
            .slice(0, 3)
            .map(({ id, name, color }) => ({ id, name, color }))

        setTopBandeiras(top)
    }, [tiles])

    return (
        <div className={`${styles.container} ${className || ''}`}>
            <div ref={mapContainer} className={styles.map} />

            {isLoading && (
                <div className={styles.loading}>
                    <div className={styles.spinner}></div>
                    <span>Carregando mapa...</span>
                </div>
            )}

            <Legend bandeiras={topBandeiras} />

            {selectedTile && (
                <TilePopup
                    tile={selectedTile}
                    onClose={() => setSelectedTile(null)}
                />
            )}
        </div>
    )
}

function getTileRing(tile: Tile, cache: Map<string, number[][]>): number[][] | null {
    const cached = cache.get(tile.id)
    if (cached) return cached

    try {
        const boundary = cellToBoundary(tile.id, true)
        if (!boundary?.length) return null

        const ring = [...boundary, boundary[0]]
        cache.set(tile.id, ring)
        return ring
    } catch {
        // Fall back to backend-provided boundary if the tile ID isn't a valid H3 index
        if (!tile.boundary?.length) return null
        const boundary = tile.boundary.map(([lat, lng]) => [lng, lat] as [number, number])
        const ring = [...boundary, boundary[0]]
        cache.set(tile.id, ring)
        return ring
    }
}

interface TilePopupProps {
    tile: Tile
    onClose: () => void
}

function TilePopup({ tile, onClose }: TilePopupProps) {
    const shieldLevel = tile.shield >= 70 ? 'high' : tile.shield >= 40 ? 'medium' : 'low'

    return (
        <div className={styles.popup}>
            <button className={styles.closeBtn} onClick={onClose}>×</button>

            <div className={styles.popupHeader}>
                {tile.ownerColor && (
                    <span
                        className={styles.ownerColor}
                        style={{ backgroundColor: tile.ownerColor }}
                    />
                )}
                <div>
                    <h4>{tile.ownerName || 'Território Neutro'}</h4>
                    {tile.ownerType && (
                        <span className={`badge ${tile.ownerType === 'BANDEIRA' ? 'badge-conquest' : 'badge-defense'}`}>
                            {tile.ownerType === 'BANDEIRA' ? 'Bandeira' : 'Solo'}
                        </span>
                    )}
                </div>
            </div>

            {tile.ownerType && (
                <>
                    <div className={styles.shieldSection}>
                        <div className={styles.shieldHeader}>
                            <span>Escudo</span>
                            <span className={styles.shieldValue}>{tile.shield}/100</span>
                        </div>
                        <div className="shield-bar">
                            <div
                                className="shield-bar-fill"
                                data-level={shieldLevel}
                                style={{ width: `${tile.shield}%` }}
                            />
                        </div>
                    </div>

                    {tile.isInDispute && (
                        <div className={styles.disputeWarning}>
                            ⚔️ Tile em disputa!
                        </div>
                    )}

                    {tile.isInCooldown && (
                        <div className={styles.cooldownInfo}>
                            🔒 Em cooldown (não pode trocar de dono)
                        </div>
                    )}

                    {tile.guardianName && (
                        <div className={styles.guardian}>
                            <span>Guardião:</span>
                            <strong>{tile.guardianName}</strong>
                        </div>
                    )}
                </>
            )}

            <div className={styles.tileId}>
                ID: {tile.id.slice(0, 12)}...
            </div>
        </div>
    )
}

function Legend({ bandeiras }: { bandeiras: Array<{ id: string; name: string; color: string }> }) {
    const labels = ['A', 'B', 'C'] as const

    return (
        <div className={styles.legend} aria-label="Legenda do mapa">
            <div className={styles.legendTitle}>Legenda</div>
            <LegendItem color={PALETTE.neutral} label="Neutro" />
            <LegendItem color={PALETTE.solo} label="Solo" />
            {bandeiras.map((b, idx) => (
                <LegendItem
                    key={b.id}
                    color={b.color}
                    label={`Bandeira ${labels[idx]} — ${b.name}`}
                />
            ))}
            <LegendItem color={PALETTE.dispute} label="Disputa" isDashed />
        </div>
    )
}

function LegendItem({ color, label, isDashed }: { color: string; label: string; isDashed?: boolean }) {
    return (
        <div className={styles.legendRow}>
            <span
                className={styles.legendSwatch}
                style={{
                    backgroundColor: color,
                    borderStyle: isDashed ? 'dashed' : 'solid',
                    borderColor: isDashed ? color : 'rgba(255,255,255,0.3)',
                }}
            />
            <span className={styles.legendLabel}>{label}</span>
        </div>
    )
}
