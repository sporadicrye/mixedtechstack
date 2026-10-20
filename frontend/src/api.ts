/**
 * api.ts — Axios instance and all typed API calls.
 * Single source of truth for backend communication.
 * All components import from here — DRY principle.
 */

import axios from 'axios'

// Base URL — Vite proxy handles /api prefix in dev
//const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'
const BASE_URL = ''

export const api = axios.create({
  baseURL: BASE_URL,
  timeout: 30000,
  headers: { 'Content-Type': 'application/json' }
})

// ── Types ─────────────────────────────────────────────────────────────────────

export interface DashboardSummary {
  total_orders:    number
  total_customers: number
  total_revenue:   number
  avg_order_value: number
  products_sold:   number
}

export interface MonthlyRevenue {
  month:   string
  revenue: number
  orders:  number
}

export interface TopProduct {
  product_name:  string
  category_name: string
  units_sold:    number
  revenue:       number
}

export interface DashboardData {
  summary:         DashboardSummary
  top_products:    TopProduct[]
  monthly_revenue: MonthlyRevenue[]
}

export interface Order {
  order_id:         number
  order_date:       string
  required_date:    string
  shipped_date:     string | null
  freight:          number
  ship_name:        string
  ship_country:     string
  customer_name:    string
  customer_country: string
  employee_first:   string
  employee_last:    string
  shipper_name:     string
  product_id:       number
  product_name:     string
  unit_price:       number
  quantity:         number
  discount:         number
  line_total:       number
}

export interface Employee {
  employee_id:   number
  first_name:    string
  last_name:     string
  title:         string
  hire_date:     string
  country:       string
  total_orders:  number
  total_sales:   number
}

export interface Customer {
  customer_id:   string
  company_name:  string
  contact_name:  string
  country:       string
  city:          string
  phone:         string
  total_orders:  number
  total_spent:   number
  first_order:   string | null
  last_order:    string | null
}

export interface Shipment {
  shipper_id:    number
  shipper_name:  string
  shipper_phone: string
  order_id:      number
  order_date:    string
  shipped_date:  string | null
  freight:       number
  ship_country:  string
  customer_name: string
  order_value:   number
}

export interface AiInsight {
  id:            number
  question_text: string
  insight_type:  string
  insight_text:  string
  tokens_used:   number
  created_at:    string
  expires_at:    string | null
}

export interface AiAskResponse {
  insight_text:  string
  insight_type:  string
  tokens_used:   number
  cached:        boolean
  created_at:    string
}

// ── API calls ─────────────────────────────────────────────────────────────────

export const getDashboard = async (): Promise<DashboardData> => {
  const { data } = await api.get('/getDashboard/summary')
  return data
}

export const getOrders = async (id: string | number = 'all'): Promise<Order[]> => {
  const { data } = await api.get(`/getOrder/order_id/${id}`)
  return Array.isArray(data) ? data : [data]
}

export const getEmployees = async (id: string | number = 'all'): Promise<Employee[]> => {
  const { data } = await api.get(`/getEmployee/employee_id/${id}`)
  return Array.isArray(data) ? data : [data]
}

export const getCustomers = async (id: string = 'all'): Promise<Customer[]> => {
  const { data } = await api.get(`/getCustomer/customer_id/${id}`)
  return Array.isArray(data) ? data : [data]
}

export const getShipments = async (id: string | number = 'all'): Promise<Shipment[]> => {
  const { data } = await api.get(`/getShip/ship_via/${id}`)
  return Array.isArray(data) ? data : [data]
}

export const askAi = async (question: string): Promise<AiAskResponse> => {
  const { data } = await api.post('/ai/ask', { question })
  return data
}

export const getAiInsights = async (): Promise<AiInsight[]> => {
  const { data } = await api.get('/ai/insights')
  return data
}
