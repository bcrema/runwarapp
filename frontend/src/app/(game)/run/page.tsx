'use client'

import { useState, useRef, useCallback } from 'react'
import { api, RunSubmissionResult } from '@/lib/api'
import { requestTilesRefresh } from '@/lib/tilesRefresh'
import styles from './page.module.css'

export default function RunPage() {
    const [mode, setMode] = useState<'upload' | 'record'>('upload')
    const [isLoading, setIsLoading] = useState(false)
    const [result, setResult] = useState<RunSubmissionResult | null>(null)
    const [error, setError] = useState<string | null>(null)

    return (
        <div className={styles.container}>
            <h1 className={styles.title}>Registrar Corrida</h1>

            {/* Mode Tabs */}
            <div className={styles.tabs}>
                <button
                    className={`${styles.tab} ${mode === 'upload' ? styles.tabActive : ''}`}
                    onClick={() => setMode('upload')}
                >
                    📁 Upload GPX
                </button>
                <button
                    className={`${styles.tab} ${mode === 'record' ? styles.tabActive : ''}`}
                    onClick={() => setMode('record')}
                >
                    📍 Gravar GPS
                </button>
            </div>

            {error && (
                <div className={styles.error}>
                    {error}
                </div>
            )}

            {result ? (
                <RunResult result={result} onReset={() => setResult(null)} />
            ) : mode === 'upload' ? (
                <GpxUploader
                    onSubmit={async (file) => {
                        setIsLoading(true)
                        setError(null)
                        try {
                            const result = await api.submitRunGpx(file)
                            setResult(result)
                            if (result.turnResult.actionType) requestTilesRefresh()
                        } catch (err: any) {
                            setError(err.message || 'Erro ao enviar corrida')
                        } finally {
                            setIsLoading(false)
                        }
                    }}
                    isLoading={isLoading}
                />
            ) : (
                <GpsRecorder
                    onSubmit={async (coordinates, timestamps) => {
                        setIsLoading(true)
                        setError(null)
                        try {
                            const result = await api.submitRunCoordinates(coordinates, timestamps)
                            setResult(result)
                            if (result.turnResult.actionType) requestTilesRefresh()
                        } catch (err: any) {
                            setError(err.message || 'Erro ao enviar corrida')
                        } finally {
                            setIsLoading(false)
                        }
                    }}
                    isLoading={isLoading}
                />
            )}
        </div>
    )
}

interface GpxUploaderProps {
    onSubmit: (file: File) => void
    isLoading: boolean
}

function GpxUploader({ onSubmit, isLoading }: GpxUploaderProps) {
    const [file, setFile] = useState<File | null>(null)
    const inputRef = useRef<HTMLInputElement>(null)

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const selectedFile = e.target.files?.[0]
        if (selectedFile) {
            setFile(selectedFile)
        }
    }

    const handleSubmit = () => {
        if (file) {
            onSubmit(file)
        }
    }

    return (
        <div className={styles.uploaderCard}>
            <div
                className={styles.dropzone}
                onClick={() => inputRef.current?.click()}
            >
                <input
                    ref={inputRef}
                    type="file"
                    accept=".gpx"
                    onChange={handleFileChange}
                    className={styles.fileInput}
                />

                {file ? (
                    <div className={styles.fileSelected}>
                        <span className={styles.fileIcon}>📄</span>
                        <span className={styles.fileName}>{file.name}</span>
                        <span className={styles.fileSize}>
                            {(file.size / 1024).toFixed(1)} KB
                        </span>
                    </div>
                ) : (
                    <div className={styles.dropzoneContent}>
                        <span className={styles.uploadIcon}>📤</span>
                        <p>Clique para selecionar um arquivo GPX</p>
                        <p className={styles.hint}>Exportado do Strava, Garmin, etc.</p>
                    </div>
                )}
            </div>

            <button
                className="btn btn-primary btn-lg"
                onClick={handleSubmit}
                disabled={!file || isLoading}
                style={{ width: '100%' }}
            >
                {isLoading ? 'Enviando...' : 'Enviar Corrida'}
            </button>
        </div>
    )
}

interface GpsRecorderProps {
    onSubmit: (coordinates: Array<{ lat: number; lng: number }>, timestamps: number[]) => void
    isLoading: boolean
}

function GpsRecorder({ onSubmit, isLoading }: GpsRecorderProps) {
    const [isRecording, setIsRecording] = useState(false)
    const [points, setPoints] = useState<Array<{ lat: number; lng: number; timestamp: number }>>([])
    const [error, setError] = useState<string | null>(null)
    const watchIdRef = useRef<number | null>(null)

    const stopRecording = useCallback(() => {
        if (watchIdRef.current !== null) {
            navigator.geolocation.clearWatch(watchIdRef.current)
            watchIdRef.current = null
        }
        setIsRecording(false)
    }, [])

    const startRecording = useCallback(() => {
        if (!navigator.geolocation) {
            setError('Geolocalização não suportada pelo navegador')
            return
        }

        setError(null)
        setPoints([])
        setIsRecording(true)

        watchIdRef.current = navigator.geolocation.watchPosition(
            (position) => {
                setPoints((prev) => [
                    ...prev,
                    {
                        lat: position.coords.latitude,
                        lng: position.coords.longitude,
                        timestamp: Date.now(),
                    },
                ])
            },
            (err) => {
                setError(`Erro GPS: ${err.message}`)
                stopRecording()
            },
            {
                enableHighAccuracy: true,
                maximumAge: 0,
                timeout: 5000,
            }
        )
    }, [stopRecording])

    const handleSubmit = () => {
        if (points.length < 2) {
            setError('Pontos insuficientes. Continue gravando.')
            return
        }

        const coordinates = points.map((p) => ({ lat: p.lat, lng: p.lng }))
        const timestamps = points.map((p) => p.timestamp)
        onSubmit(coordinates, timestamps)
    }

    const totalDistance = calculateDistance(points)
    const duration = points.length > 1
        ? Math.round((points[points.length - 1].timestamp - points[0].timestamp) / 1000)
        : 0

    return (
        <div className={styles.recorderCard}>
            {error && (
                <div className={styles.recorderError}>{error}</div>
            )}

            <div className={styles.recordingStats}>
                <div className={styles.recordingStat}>
                    <span className={styles.recordingValue}>
                        {(totalDistance / 1000).toFixed(2)}
                    </span>
                    <span className={styles.recordingLabel}>km</span>
                </div>
                <div className={styles.recordingStat}>
                    <span className={styles.recordingValue}>
                        {formatDuration(duration)}
                    </span>
                    <span className={styles.recordingLabel}>tempo</span>
                </div>
                <div className={styles.recordingStat}>
                    <span className={styles.recordingValue}>{points.length}</span>
                    <span className={styles.recordingLabel}>pontos</span>
                </div>
            </div>

            {isRecording && (
                <div className={styles.recordingIndicator}>
                    <span className={styles.recordingDot}></span>
                    Gravando...
                </div>
            )}

            <div className={styles.recordingActions}>
                {!isRecording ? (
                    <button
                        className="btn btn-success btn-lg"
                        onClick={startRecording}
                        style={{ width: '100%' }}
                    >
                        ▶️ Iniciar Gravação
                    </button>
                ) : (
                    <button
                        className="btn btn-danger btn-lg"
                        onClick={stopRecording}
                        style={{ width: '100%' }}
                    >
                        ⏹️ Parar Gravação
                    </button>
                )}

                {!isRecording && points.length > 0 && (
                    <button
                        className="btn btn-primary btn-lg"
                        onClick={handleSubmit}
                        disabled={isLoading || points.length < 2}
                        style={{ width: '100%', marginTop: 'var(--space-md)' }}
                    >
                        {isLoading ? 'Enviando...' : 'Enviar Corrida'}
                    </button>
                )}
            </div>
        </div>
    )
}

interface RunResultProps {
    result: RunSubmissionResult
    onReset: () => void
}

function RunResult({ result, onReset }: RunResultProps) {
    const { loopValidation, turnResult } = result

    type TurnOutcome = 'CONQUEST' | 'ATTACK' | 'DEFENSE' | 'NO_EFFECT'

    const outcome: TurnOutcome =
        turnResult.actionType ?? 'NO_EFFECT'

    const badges: Record<TurnOutcome, { class: string; label: string }> = {
        CONQUEST: { class: 'badge-conquest', label: '🏴 Conquistou' },
        ATTACK: { class: 'badge-attack', label: '⚔️ Atacou' },
        DEFENSE: { class: 'badge-defense', label: '🛡️ Defendeu' },
        NO_EFFECT: { class: 'badge-neutral', label: '😐 Sem efeito' },
    }

    const actionBadge = badges[outcome]

    const reasons =
        turnResult.reasons.length > 0
            ? turnResult.reasons.map(translateTurnReason)
            : ['Nenhuma ação territorial foi aplicada.']
    const shouldShowReasons = outcome === 'NO_EFFECT'

    const shieldChange =
        turnResult.shieldBefore != null && turnResult.shieldAfter != null
            ? turnResult.shieldAfter - turnResult.shieldBefore
            : null

    const ownerChanged = turnResult.previousOwner?.id !== turnResult.newOwner?.id ||
        turnResult.previousOwner?.type !== turnResult.newOwner?.type

    return (
        <div className={styles.resultCard}>
            <div className={styles.resultHeader}>
                {loopValidation.isValid ? (
                    <>
                        <span className={styles.resultIcon}>✅</span>
                        <h2>Loop Válido!</h2>
                    </>
                ) : (
                    <>
                        <span className={styles.resultIcon}>ℹ️</span>
                        <h2>Corrida Registrada</h2>
                    </>
                )}
            </div>

            <div className={styles.actionResult}>
                <span
                    className={`badge ${actionBadge.class}`}
                    style={{ fontSize: '1.2rem', padding: '0.5rem 1rem' }}
                >
                    {actionBadge.label}
                </span>

                {turnResult.actionType && (
                    <>
                        <div className={styles.shieldChange}>
                            <span>Escudo: {turnResult.shieldBefore ?? '—'} → {turnResult.shieldAfter ?? '—'}</span>
                            {shieldChange !== null && (
                                <span className={shieldChange > 0 ? styles.positive : styles.negative}>
                                    ({shieldChange > 0 ? '+' : ''}{shieldChange})
                                </span>
                            )}
                        </div>

                        {turnResult.tileId && (
                            <div className={styles.shieldChange}>
                                <span>Tile: {turnResult.tileId}</span>
                            </div>
                        )}

                        {ownerChanged && (
                            <div className={styles.ownerChanged}>
                                🎉 Tile conquistado!
                            </div>
                        )}
                    </>
                )}
            </div>

            <div className={styles.resultStats}>
                <div className={styles.resultStat}>
                    <span className={styles.resultStatValue}>
                        {(loopValidation.distance / 1000).toFixed(2)} km
                    </span>
                    <span className={styles.resultStatLabel}>Distância</span>
                </div>
                <div className={styles.resultStat}>
                    <span className={styles.resultStatValue}>
                        {formatDuration(loopValidation.duration)}
                    </span>
                    <span className={styles.resultStatLabel}>Duração</span>
                </div>
                <div className={styles.resultStat}>
                    <span className={styles.resultStatValue}>
                        {loopValidation.closingDistance.toFixed(0)}m
                    </span>
                    <span className={styles.resultStatLabel}>Fechamento</span>
                </div>
            </div>

            {shouldShowReasons && (
                <div className={styles.failureReasons}>
                    <h4>Por que não gerou ação territorial:</h4>
                    <ul>
                        {reasons.map((reason, idx) => (
                            <li key={`${idx}-${reason}`}>{reason}</li>
                        ))}
                    </ul>
                </div>
            )}

            <div className={styles.actionsRemaining}>
                <span>Ações restantes hoje:</span>
                <strong>{turnResult.capsRemaining.userActionsRemaining}</strong>
            </div>

            <button
                className="btn btn-secondary btn-lg"
                onClick={onReset}
                style={{ width: '100%' }}
            >
                Nova Corrida
            </button>
        </div>
    )
}

// Helper functions
function calculateDistance(points: Array<{ lat: number; lng: number }>): number {
    let total = 0
    for (let i = 1; i < points.length; i++) {
        total += haversine(points[i - 1], points[i])
    }
    return total
}

function haversine(p1: { lat: number; lng: number }, p2: { lat: number; lng: number }): number {
    const R = 6371000
    const φ1 = (p1.lat * Math.PI) / 180
    const φ2 = (p2.lat * Math.PI) / 180
    const Δφ = ((p2.lat - p1.lat) * Math.PI) / 180
    const Δλ = ((p2.lng - p1.lng) * Math.PI) / 180

    const a = Math.sin(Δφ / 2) ** 2 + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) ** 2
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

function formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins}:${secs.toString().padStart(2, '0')}`
}

function translateTurnReason(reason: string): string {
    const translations: Record<string, string> = {
        // Loop validation
        distance_too_short: 'Distância muito curta (mínimo 1.2km)',
        duration_too_short: 'Duração muito curta (mínimo 7 minutos)',
        loop_not_closed: 'Loop não fechado (máximo 40m entre início e fim)',
        insufficient_tile_coverage: 'Cobertura insuficiente do tile (mínimo 60%)',
        fraud_detected: 'Padrão suspeito detectado',
        outside_game_area: 'Fora da área do jogo (Curitiba)',

        // Turn / caps
        no_primary_tile: 'Não foi possível determinar um tile principal para essa corrida.',
        user_daily_cap_reached: 'Limite diário de ações atingido.',
        bandeira_daily_cap_reached: 'Limite diário de ações da bandeira atingido.',

        // Territory action validation
        cannot_determine_action: 'Não foi possível determinar a ação (conquista/ataque/defesa).',
        tile_already_owned: 'Tile já possui dono.',
        cannot_attack_neutral: 'Não é possível atacar um tile neutro.',
        cannot_attack_own_tile: 'Não é possível atacar o próprio tile.',
        tile_in_cooldown: 'Tile em cooldown; ataque bloqueado no momento.',
        cannot_defend_rival_tile: 'Não é possível defender um tile que não é seu.',
    }
    return translations[reason] || reason
}
