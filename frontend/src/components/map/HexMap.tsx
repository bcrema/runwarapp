'use client'

import { useEffect, useRef, useState, useCallback } from 'react'
import mapboxgl from 'mapbox-gl'
import { cellToBoundary, latLngToCell } from 'h3-js'
import { api, Tile } from '@/lib/api'
import styles from './HexMap.module.css'

// Set Mapbox token
mapboxgl.accessToken = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || ''

interface HexMapProps {
    onTileClick?: (tile: Tile) => void
    className?: string
}

const CURITIBA_CENTER: [number, number] = [-49.27, -25.43]
const H3_RESOLUTION = 8

export default function HexMap({ onTileClick, className }: HexMapProps) {
    const mapContainer = useRef<HTMLDivElement>(null)
    const map = useRef<mapboxgl.Map | null>(null)
    const [tiles, setTiles] = useState<Tile[]>([])
    const [selectedTile, setSelectedTile] = useState<Tile | null>(null)
    const [isLoading, setIsLoading] = useState(true)

    // Load tiles for current viewport
    const loadTiles = useCallback(async () => {
        if (!map.current) return

        const bounds = map.current.getBounds()
        if (!bounds) return

        try {
            const tilesData = await api.getTiles({
                minLat: bounds.getSouth(),
                minLng: bounds.getWest(),
                maxLat: bounds.getNorth(),
                maxLng: bounds.getEast(),
            })
            setTiles(tilesData)
        } catch (error) {
            console.error('Failed to load tiles:', error)
        }
    }, [])

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
                    'fill-color': ['get', 'fillColor'],
                    'fill-opacity': ['get', 'fillOpacity'],
                },
            })

            // Add outline layer
            map.current!.addLayer({
                id: 'hexagons-outline',
                type: 'line',
                source: 'hexagons',
                paint: {
                    'line-color': ['get', 'strokeColor'],
                    'line-width': 1,
                    'line-opacity': 0.6,
                },
            })

            // Click handler
            map.current!.on('click', 'hexagons-fill', (e) => {
                if (e.features && e.features[0]) {
                    const tileId = e.features[0].properties?.id

                    // Look up the full tile object from the current state ref
                    const tile = tilesRef.current.find(t => t.id === tileId)

                    if (tile) {
                        setSelectedTile(tile)
                        onTileClickRef.current?.(tile)
                    }
                }
            })

            // Hover cursor
            map.current!.on('mouseenter', 'hexagons-fill', () => {
                map.current!.getCanvas().style.cursor = 'pointer'
            })
            map.current!.on('mouseleave', 'hexagons-fill', () => {
                map.current!.getCanvas().style.cursor = ''
            })

            loadTiles()
        })

        map.current.on('moveend', loadTiles)

        return () => {
            map.current?.remove()
            map.current = null
        }
    }, [loadTiles]) // Removed tiles and onTileClick dependencies

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

        const features = tiles.map((tile) => {
            // Generate hexagon boundary
            const boundary = tile.boundary.map(([lat, lng]) => [lng, lat])
            boundary.push(boundary[0]) // Close the polygon

            return {
                type: 'Feature' as const,
                properties: {
                    id: tile.id,
                    fillColor: getTileColor(tile),
                    fillOpacity: tile.ownerType ? 0.4 : 0.1,
                    strokeColor: tile.isInDispute ? '#f59e0b' : (tile.ownerColor || '#ffffff'),
                },
                geometry: {
                    type: 'Polygon' as const,
                    coordinates: [boundary],
                },
            }
        })

        const source = map.current.getSource('hexagons') as mapboxgl.GeoJSONSource
        source.setData({
            type: 'FeatureCollection',
            features,
        })
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

            {selectedTile && (
                <TilePopup
                    tile={selectedTile}
                    onClose={() => setSelectedTile(null)}
                />
            )}
        </div>
    )
}

function getTileColor(tile: Tile): string {
    if (!tile.ownerType) return '#6b7280' // Neutral gray
    if (tile.isInDispute) return '#f59e0b' // Dispute yellow
    return tile.ownerColor || '#6366f1' // Owner color or default purple
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
