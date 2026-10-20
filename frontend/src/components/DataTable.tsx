/**
 * DataTable.tsx — Reusable generic table component.
 * Accepts any array of objects and renders columns dynamically.
 * Memoized to prevent re-render when parent state changes
 * but table data has not changed.
 */

import { memo, useMemo } from 'react'

interface DataTableProps {
  rows:        Record<string, any>[]
  highlight?:  string   // column key to highlight in neon
  maxRows?:    number
}

const DataTable = memo(({ rows = [], highlight, maxRows = 100 }: DataTableProps) => {
  // useMemo: derive columns only when rows reference changes
  const columns = useMemo(() => {
    if (!rows.length) return []
    return Object.keys(rows[0])
  }, [rows])

  if (!rows.length) return (
    <div style={{ color: 'var(--text-muted)', padding: '1rem' }}>No data found.</div>
  )

  const displayRows = rows.slice(0, maxRows)

  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {columns.map(col => (
              <th key={col} style={col === highlight ? { color: 'var(--warn)' } : {}}>
                {col.replace(/_/g, ' ').toUpperCase()}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {displayRows.map((row, i) => (
            <tr key={i}>
              {columns.map(col => (
                <td
                  key={col}
                  style={col === highlight ? { color: 'var(--neon)', fontWeight: 'bold' } : {}}
                >
                  {row[col] === null || row[col] === undefined
                    ? '—'
                    : typeof row[col] === 'number'
                      ? row[col].toLocaleString()
                      : String(row[col])}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
      {rows.length > maxRows && (
        <div style={{ color: 'var(--text-muted)', padding: '8px', fontSize: '11px' }}>
          Showing {maxRows} of {rows.length} rows.
        </div>
      )}
    </div>
  )
})

DataTable.displayName = 'DataTable'
export default DataTable
