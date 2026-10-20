/**
 * useApi.ts — Generic reusable async data fetching hook.
 * Handles loading, error, and data states for any API call.
 * Memoized with useCallback to prevent unnecessary re-renders.
 * Used by all dashboard components — DRY principle.
 */

import { useState, useCallback } from 'react'

interface UseApiState<T> {
  data:    T | null
  loading: boolean
  error:   string | null
}

export function useApi<T>(initialData: T) {
  const [state, setState] = useState<UseApiState<T>>({
    data:    null,
    loading: false,
    error:   null
  })

  // useCallback prevents function recreation on every render
  const execute = useCallback(async (apiFn: () => Promise<T>) => {
    setState({ data: null, loading: true, error: null })
    try {
      const data = await apiFn()
      setState({ data, loading: false, error: null })
      return data
    } catch (err: any) {
      const error = err?.response?.data?.detail || err?.message || 'Unknown error'
      setState({ data: null, loading: false, error })
      return null
    }
  }, [])

  return { ...state, execute }
}
