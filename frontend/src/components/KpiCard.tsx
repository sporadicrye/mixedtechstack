/**
 * KpiCard.tsx — Reusable KPI metric display card.
 * Memoized with React.memo to prevent re-render when parent updates
 * but this card's props have not changed.
 */

import { memo } from 'react'

interface KpiCardProps {
  label: string
  value: string | number
  sub?:  string
}

const KpiCard = memo(({ label, value, sub }: KpiCardProps) => (
  <div className="card" style={{ textAlign: 'center' }}>
    <div style={{ color: 'var(--text-muted)', fontSize: '11px', marginBottom: '6px' }}>
      {label}
    </div>
    <div className="neon-text" style={{ fontSize: '24px', fontWeight: 'bold' }}>
      {value}
    </div>
    {sub && (
      <div style={{ color: 'var(--text-muted)', fontSize: '11px', marginTop: '4px' }}>
        {sub}
      </div>
    )}
  </div>
))

KpiCard.displayName = 'KpiCard'
export default KpiCard
