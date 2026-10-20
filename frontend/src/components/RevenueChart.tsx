/**
 * RevenueChart.tsx — SVG-based monthly revenue bar chart.
 * No external chart library needed — pure SVG keeps bundle small.
 * Memoized: only re-renders when monthlyRevenue data changes.
 */

import { memo, useMemo } from 'react'
import { MonthlyRevenue } from '../api'

interface RevenueChartProps {
  data: MonthlyRevenue[]
}

const RevenueChart = memo(({ data = [] }: RevenueChartProps) => {
  const WIDTH  = 600
  const HEIGHT = 200
  const PAD    = { top: 20, right: 20, bottom: 40, left: 60 }

  // useMemo: recalculate chart geometry only when data changes
  const { bars, yLabels, xLabels } = useMemo(() => {
    if (!data.length) return { bars: [], yLabels: [], xLabels: [] }

    const maxRev  = Math.max(...data.map(d => d.revenue))
    const chartW  = WIDTH  - PAD.left - PAD.right
    const chartH  = HEIGHT - PAD.top  - PAD.bottom
    const barW    = Math.max(8, chartW / data.length - 4)

    const bars = data.map((d, i) => ({
      x:       PAD.left + i * (chartW / data.length) + 2,
      y:       PAD.top  + chartH - (d.revenue / maxRev) * chartH,
      h:       (d.revenue / maxRev) * chartH,
      w:       barW,
      revenue: d.revenue,
      month:   d.month,
      orders:  d.orders
    }))

    const yLabels = [0, 0.25, 0.5, 0.75, 1].map(pct => ({
      y:     PAD.top + (1 - pct) * chartH,
      label: `$${(maxRev * pct).toLocaleString(undefined, { maximumFractionDigits: 0 })}`
    }))

    const xLabels = data.map((d, i) => ({
      x:     PAD.left + i * (chartW / data.length) + barW / 2,
      label: d.month.slice(5) // show MM only
    }))

    return { bars, yLabels, xLabels }
  }, [data])

  if (!data.length) return (
    <div style={{ color: 'var(--text-muted)' }}>No revenue data.</div>
  )

  return (
    <svg
      viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
      style={{ width: '100%', height: 'auto', display: 'block' }}
    >
      {/* Y axis labels */}
      {yLabels.map((yl, i) => (
        <g key={i}>
          <line
            x1={PAD.left} y1={yl.y}
            x2={WIDTH - PAD.right} y2={yl.y}
            stroke="#1f1f1f" strokeWidth="1"
          />
          <text
            x={PAD.left - 6} y={yl.y + 4}
            textAnchor="end" fill="#666" fontSize="10"
          >
            {yl.label}
          </text>
        </g>
      ))}

      {/* Bars */}
      {bars.map((b, i) => (
        <g key={i}>
          <rect
            x={b.x} y={b.y} width={b.w} height={b.h}
            fill="#39ff14" opacity="0.8" rx="2"
          >
            <title>{b.month}: ${b.revenue.toLocaleString()} ({b.orders} orders)</title>
          </rect>
        </g>
      ))}

      {/* X axis labels */}
      {xLabels.map((xl, i) => (
        <text
          key={i}
          x={xl.x} y={HEIGHT - PAD.bottom + 16}
          textAnchor="middle" fill="#666" fontSize="10"
        >
          {xl.label}
        </text>
      ))}

      {/* Axis lines */}
      <line
        x1={PAD.left} y1={PAD.top}
        x2={PAD.left} y2={HEIGHT - PAD.bottom}
        stroke="#333" strokeWidth="1"
      />
      <line
        x1={PAD.left} y1={HEIGHT - PAD.bottom}
        x2={WIDTH - PAD.right} y2={HEIGHT - PAD.bottom}
        stroke="#333" strokeWidth="1"
      />
    </svg>
  )
})

RevenueChart.displayName = 'RevenueChart'
export default RevenueChart
