/**
 * App.tsx — Root component and navigation controller.
 * Lazy loads each tab panel to reduce initial bundle size.
 * useMemo on nav items prevents recreation on every render.
 * All data fetching delegated to child components via useApi hook.
 */

import {
  useState, useCallback, useEffect,
  useMemo, memo, lazy, Suspense
} from 'react'
import {
  getDashboard, getOrders, getEmployees,
  getCustomers, getShipments,
  DashboardData, Order, Employee, Customer, Shipment
} from './api'
import { useApi } from './hooks/useApi'
import KpiCard      from './components/KpiCard'
import DataTable    from './components/DataTable'
import RevenueChart from './components/RevenueChart'

// Lazy load AI panel — heaviest component, only loaded when tab selected
const AiPanel = lazy(() => import('./components/AiPanel'))

// ── Nav tab definitions ───────────────────────────────────────────────────────
type Tab = 'dashboard' | 'orders' | 'employees' | 'customers' | 'shipments' | 'ai'

interface NavItem { id: Tab; label: string }

// ── Lookup filter component ───────────────────────────────────────────────────
interface LookupBarProps {
  placeholder: string
  onSearch:    (val: string) => void
  loading:     boolean
}

const LookupBar = memo(({ placeholder, onSearch, loading }: LookupBarProps) => {
  const [val, setVal] = useState('')

  const handleSearch = useCallback(() => {
    onSearch(val.trim() || 'all')
  }, [val, onSearch])

  return (
    <div style={{ display: 'flex', gap: '8px', marginBottom: '1rem', flexWrap: 'wrap' }}>
      <input
        value={val}
        onChange={e => setVal(e.target.value)}
        placeholder={placeholder}
        style={{ maxWidth: '300px' }}
        onKeyDown={e => e.key === 'Enter' && handleSearch()}
      />
      <button onClick={handleSearch} disabled={loading}>
        {loading ? '⏳' : '🔍 Search'}
      </button>
      <button onClick={() => { setVal(''); onSearch('all') }} disabled={loading}>
        Show All
      </button>
    </div>
  )
})
LookupBar.displayName = 'LookupBar'

// ── Main App ──────────────────────────────────────────────────────────────────
export default function App() {
  const [activeTab, setActiveTab] = useState<Tab>('dashboard')

  // Separate API state per entity — useApi is generic and reusable
  /*
  const dashApi      = useApi<DashboardData>()
  const ordersApi    = useApi<Order[]>()
  const employeesApi = useApi<Employee[]>()
  const customersApi = useApi<Customer[]>()
  const shipmentsApi = useApi<Shipment[]>()
  */
  const dashApi = useApi<DashboardData>({
    summary: { total_revenue: 0, total_orders: 0, total_customers: 0, avg_order_value: 0, products_sold: 0 },
    monthly_revenue: [],
    top_products: []
  })
  const ordersApi    = useApi<Order[]>([])
  const employeesApi = useApi<Employee[]>([])
  const customersApi = useApi<Customer[]>([])
  const shipmentsApi = useApi<Shipment[]>([])

  // useMemo: nav items are static, never recreated
  const navItems = useMemo<NavItem[]>(() => [
    { id: 'dashboard',  label: '📊 Dashboard'  },
    { id: 'orders',     label: '📦 Orders'     },
    { id: 'employees',  label: '👤 Employees'  },
    { id: 'customers',  label: '🏢 Customers'  },
    { id: 'shipments',  label: '🚚 Shipments'  },
    { id: 'ai',         label: '🤖 AI Analyst' }
  ], [])

  // Load dashboard on mount
  useEffect(() => {
    dashApi.execute(getDashboard)
  }, [])

  // useCallback: stable tab switch handler
  const handleTab = useCallback((tab: Tab) => {
    setActiveTab(tab)
    // Auto-load data on first tab visit
    if (tab === 'orders'     && !ordersApi.data)    ordersApi.execute(() => getOrders('all'))
    if (tab === 'employees'  && !employeesApi.data) employeesApi.execute(() => getEmployees('all'))
    if (tab === 'customers'  && !customersApi.data) customersApi.execute(() => getCustomers('all'))
    if (tab === 'shipments'  && !shipmentsApi.data) shipmentsApi.execute(() => getShipments('all'))
  }, [ordersApi, employeesApi, customersApi, shipmentsApi])

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg)' }}>

      {/* Navigation */}
      <nav className="nav">
        <span className="neon-text" style={{ fontWeight: 'bold', marginRight: '8px' }}>
          ⚡ POC SALES
        </span>
        {navItems.map(item => (
          <button
            key={item.id}
            onClick={() => handleTab(item.id)}
            style={{
              background:  activeTab === item.id ? 'var(--neon)' : 'transparent',
              color:       activeTab === item.id ? 'var(--bg)'   : 'var(--neon)',
              boxShadow:   activeTab === item.id ? '0 0 12px var(--neon)' : 'none'
            }}
          >
            {item.label}
          </button>
        ))}
      </nav>

      {/* Content */}
      <div style={{ padding: '1rem', maxWidth: '1400px', margin: '0 auto' }}>

        {/* ── Dashboard Tab ── */}
        {activeTab === 'dashboard' && (
          <div>
            <h2 className="neon-text" style={{ marginBottom: '1rem' }}>
              Sales Dashboard
            </h2>

            {dashApi.loading && (
              <div style={{ color: 'var(--neon)' }}>⏳ Loading dashboard…</div>
            )}
            {dashApi.error && (
              <div style={{ color: 'var(--danger)' }}>❌ {dashApi.error}</div>
            )}

            {dashApi.data && (
              <>
                {/* KPI Cards */}
                <div className="kpi-grid" style={{ marginBottom: '1.5rem' }}>
                  <KpiCard
                    label="TOTAL REVENUE"
                    value={`$${dashApi.data?.summary?.total_revenue?.toLocaleString()}`}
                  />
                  <KpiCard
                    label="TOTAL ORDERS"
                    value={dashApi.data?.summary?.total_orders?.toLocaleString()}
                  />
                  <KpiCard
                    label="CUSTOMERS"
                    value={dashApi.data?.summary?.total_customers?.toLocaleString()}
                  />
                  <KpiCard
                    label="AVG ORDER VALUE"
                    value={`$${dashApi.data?.summary?.avg_order_value?.toLocaleString()}`}
                  />
                </div>

                {/* Revenue Chart */}
                <div className="card" style={{ marginBottom: '1.5rem' }}>
                  <h3 style={{ color: 'var(--neon)', marginBottom: '1rem', fontSize: '13px' }}>
                    MONTHLY REVENUE
                  </h3>
                  <RevenueChart data={dashApi.data.monthly_revenue} />
                </div>

                {/* Top Products */}
                <div className="card">
                  <h3 style={{ color: 'var(--neon)', marginBottom: '1rem', fontSize: '13px' }}>
                    TOP 10 PRODUCTS BY REVENUE
                  </h3>
                  <DataTable
                    rows={dashApi.data.top_products}
                    highlight="revenue"
                  />
                </div>
              </>
            )}
          </div>
        )}

        {/* ── Orders Tab ── */}
        {activeTab === 'orders' && (
          <div>
            <h2 className="neon-text" style={{ marginBottom: '1rem' }}>Orders</h2>
            <LookupBar
              placeholder="Order ID (number or leave blank for all)"
              loading={ordersApi.loading}
              onSearch={val => ordersApi.execute(() => getOrders(val))}
            />
            {ordersApi.loading && (
              <div style={{ color: 'var(--neon)' }}>⏳ Loading orders…</div>
            )}
            {ordersApi.error && (
              <div style={{ color: 'var(--danger)' }}>❌ {ordersApi.error}</div>
            )}
            {ordersApi.data && (
              <div className="card">
                <div style={{ color: 'var(--text-muted)', fontSize: '11px', marginBottom: '8px' }}>
                  {ordersApi.data.length.toLocaleString()} rows returned
                </div>
                <DataTable rows={ordersApi.data} highlight="line_total" />
              </div>
            )}
          </div>
        )}

        {/* ── Employees Tab ── */}
        {activeTab === 'employees' && (
          <div>
            <h2 className="neon-text" style={{ marginBottom: '1rem' }}>Employees</h2>
            <LookupBar
              placeholder="Employee ID (number or leave blank for all)"
              loading={employeesApi.loading}
              onSearch={val => employeesApi.execute(() => getEmployees(val))}
            />
            {employeesApi.loading && (
              <div style={{ color: 'var(--neon)' }}>⏳ Loading employees…</div>
            )}
            {employeesApi.error && (
              <div style={{ color: 'var(--danger)' }}>❌ {employeesApi.error}</div>
            )}
            {employeesApi.data && (
              <div className="card">
                <div style={{ color: 'var(--text-muted)', fontSize: '11px', marginBottom: '8px' }}>
                  {employeesApi.data.length.toLocaleString()} rows returned
                </div>
                <DataTable rows={employeesApi.data} highlight="total_sales" />
              </div>
            )}
          </div>
        )}

        {/* ── Customers Tab ── */}
        {activeTab === 'customers' && (
          <div>
            <h2 className="neon-text" style={{ marginBottom: '1rem' }}>Customers</h2>
            <LookupBar
              placeholder="Customer ID (e.g. ALFKI or leave blank for all)"
              loading={customersApi.loading}
              onSearch={val => customersApi.execute(() => getCustomers(val))}
            />
            {customersApi.loading && (
              <div style={{ color: 'var(--neon)' }}>⏳ Loading customers…</div>
            )}
            {customersApi.error && (
              <div style={{ color: 'var(--danger)' }}>❌ {customersApi.error}</div>
            )}
            {customersApi.data && (
              <div className="card">
                <div style={{ color: 'var(--text-muted)', fontSize: '11px', marginBottom: '8px' }}>
                  {customersApi.data.length.toLocaleString()} rows returned
                </div>
                <DataTable rows={customersApi.data} highlight="total_spent" />
              </div>
            )}
          </div>
        )}

        {/* ── Shipments Tab ── */}
        {activeTab === 'shipments' && (
          <div>
            <h2 className="neon-text" style={{ marginBottom: '1rem' }}>Shipments</h2>
            <LookupBar
              placeholder="Shipper ID (1-6 or leave blank for all)"
              loading={shipmentsApi.loading}
              onSearch={val => shipmentsApi.execute(() => getShipments(val))}
            />
            {shipmentsApi.loading && (
              <div style={{ color: 'var(--neon)' }}>⏳ Loading shipments…</div>
            )}
            {shipmentsApi.error && (
              <div style={{ color: 'var(--danger)' }}>❌ {shipmentsApi.error}</div>
            )}
            {shipmentsApi.data && (
              <div className="card">
                <div style={{ color: 'var(--text-muted)', fontSize: '11px', marginBottom: '8px' }}>
                  {shipmentsApi.data.length.toLocaleString()} rows returned
                </div>
                <DataTable rows={shipmentsApi.data} highlight="order_value" />
              </div>
            )}
          </div>
        )}

        {/* ── AI Analyst Tab ── */}
        {activeTab === 'ai' && (
          <div>
            <h2 className="neon-text" style={{ marginBottom: '1rem' }}>AI Sales Analyst</h2>
            {/* Suspense fallback while AiPanel lazy loads */}
            <Suspense fallback={
              <div style={{ color: 'var(--neon)' }}>⏳ Loading AI panel…</div>
            }>
              <AiPanel />
            </Suspense>
          </div>
        )}

      </div>

      {/* Footer */}
      <footer style={{
        textAlign:    'center',
        padding:      '1.5rem',
        color:        'var(--text-muted)',
        fontSize:     '11px',
        borderTop:    '1px solid var(--border)',
        marginTop:    '2rem'
      }}>
        ryancarlo's POC E-Commerce Sales Dashboard — AI powered by Claude (Anthropic) —
        Backend: FastAPI + MariaDB — Frontend: Vite + React TSX
      </footer>
    </div>
  )
}
