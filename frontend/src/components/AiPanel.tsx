/**
 * AiPanel.tsx — Claude AI question interface and insights archive.
 * Sends question to /ai/ask, displays response with cache/token metadata.
 * Shows cached badge when response served from ai_insights table.
 * Displays full insights archive from /ai/insights.
 */

import { memo, useState, useCallback } from 'react'
import { askAi, getAiInsights, AiAskResponse, AiInsight } from '../api'
import { useApi } from '../hooks/useApi'
import DataTable from './DataTable'

// Preset questions — guide users toward cost-effective queries
const PRESET_QUESTIONS = [
  'Which customer spent the most in Q3?',
  'Which client has a pattern for ordering Asian products, what can I recommend?',
  'Which shipper has shipped the most orders?',
  'Which customers qualify for a loyalty reward based on spending?',
  'Recommend products for customers who order Singaporean Hokkien Fried Mee.'
]

const AiPanel = memo(() => {
  const [question,  setQuestion]  = useState('')
  const [response,  setResponse]  = useState<AiAskResponse | null>(null)
  const [asking,    setAsking]    = useState(false)
  const [askError,  setAskError]  = useState<string | null>(null)

  const insightsApi = useApi<AiInsight[]>([])

  // useCallback: stable reference, prevents child re-renders
  const handleAsk = useCallback(async () => {
    if (!question.trim()) return
    setAsking(true)
    setAskError(null)
    setResponse(null)
    try {
      const result = await askAi(question.trim())
      setResponse(result)
    } catch (err: any) {
      setAskError(err?.response?.data?.detail || err?.message || 'Failed to get AI response')
    } finally {
      setAsking(false)
    }
  }, [question])

  const handlePreset = useCallback((q: string) => {
    setQuestion(q)
  }, [])

  const handleLoadInsights = useCallback(() => {
    insightsApi.execute(getAiInsights)
  }, [insightsApi])

  return (
    <div className="ai-panel">
      {/* Header */}
      <div className="card">
        <h2 className="neon-text" style={{ marginBottom: '1rem', fontSize: '16px' }}>
          🤖 AI Sales Analyst — Powered by Claude
        </h2>

        {/* Preset question shortcuts */}
        <div style={{ marginBottom: '1rem' }}>
          <div style={{ color: 'var(--text-muted)', fontSize: '11px', marginBottom: '6px' }}>
            QUICK QUESTIONS:
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
            {PRESET_QUESTIONS.map((q, i) => (
              <button
                key={i}
                onClick={() => handlePreset(q)}
                style={{ fontSize: '11px', padding: '4px 10px' }}
              >
                {q.length > 40 ? q.slice(0, 40) + '…' : q}
              </button>
            ))}
          </div>
        </div>

        {/* Question input */}
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          <textarea
            rows={2}
            value={question}
            onChange={e => setQuestion(e.target.value)}
            placeholder="Ask a sales or marketing question..."
            style={{ flex: 1, minWidth: '200px', resize: 'vertical' }}
            onKeyDown={e => {
              // Submit on Ctrl+Enter
              if (e.key === 'Enter' && e.ctrlKey) handleAsk()
            }}
          />
          <button
            onClick={handleAsk}
            disabled={asking || !question.trim()}
            style={{ alignSelf: 'flex-end', whiteSpace: 'nowrap' }}
          >
            {asking ? '⏳ Asking…' : '⚡ Ask Claude'}
          </button>
        </div>

        {/* Cost note */}
        <div style={{ color: 'var(--text-muted)', fontSize: '10px', marginTop: '6px' }}>
          💡 Identical or cached questions return instantly at zero API cost.
          SQL handles all math — Claude only interprets patterns.
        </div>
      </div>

      {/* Error display */}
      {askError && (
        <div className="card" style={{ borderColor: 'var(--danger)', color: 'var(--danger)' }}>
          ❌ {askError}
        </div>
      )}

      {/* AI Response */}
      {response && (
        <div className="card neon-border">
          {/* Response metadata badges */}
          <div style={{ display: 'flex', gap: '8px', marginBottom: '10px', flexWrap: 'wrap' }}>
            <span className={`badge ${response.cached ? 'badge-cached' : 'badge-fresh'}`}>
              {response.cached ? '⚡ CACHED' : '🆕 FRESH'}
            </span>
            <span className="badge badge-type">
              {response.insight_type.replace(/_/g, ' ').toUpperCase()}
            </span>
            <span style={{ color: 'var(--text-muted)', fontSize: '11px', alignSelf: 'center' }}>
              {response.cached
                ? 'Served from cache — $0 API cost'
                : `Tokens used: ${response.tokens_used.toLocaleString()}`}
            </span>
          </div>

          {/* Claude's response text */}
          <div className="ai-response">
            {response.insight_text}
          </div>

          {/* Timestamp */}
          <div style={{ color: 'var(--text-muted)', fontSize: '10px', marginTop: '8px' }}>
            Generated: {new Date(response.created_at).toLocaleString()}
          </div>
        </div>
      )}

      {/* Insights Archive */}
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h3 style={{ color: 'var(--neon)', fontSize: '14px' }}>
            📚 Insights Archive (Cached Responses)
          </h3>
          <button onClick={handleLoadInsights} disabled={insightsApi.loading}>
            {insightsApi.loading ? '⏳ Loading…' : '🔄 Load Archive'}
          </button>
        </div>

        {insightsApi.error && (
          <div style={{ color: 'var(--danger)' }}>❌ {insightsApi.error}</div>
        )}

        {insightsApi.data && insightsApi.data.length === 0 && (
          <div style={{ color: 'var(--text-muted)' }}>No cached insights yet. Ask a question above.</div>
        )}

        {insightsApi.data && insightsApi.data.length > 0 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {insightsApi.data.map(insight => (
              <div
                key={insight.id}
                style={{
                  background: 'var(--bg-input)',
                  borderLeft: '3px solid var(--neon-dim)',
                  padding: '10px',
                  borderRadius: '4px'
                }}
              >
                {/* Question */}
                <div style={{ color: 'var(--text-muted)', fontSize: '11px', marginBottom: '4px' }}>
                  Q: {insight.question_text}
                </div>
                {/* Answer */}
                <div style={{ color: 'var(--text)', lineHeight: '1.5', fontSize: '12px' }}>
                  {insight.insight_text}
                </div>
                {/* Metadata row */}
                <div style={{ display: 'flex', gap: '12px', marginTop: '6px', flexWrap: 'wrap' }}>
                  <span className="badge badge-type">
                    {insight.insight_type.replace(/_/g, ' ')}
                  </span>
                  <span style={{ color: 'var(--text-muted)', fontSize: '10px' }}>
                    Tokens: {insight.tokens_used}
                  </span>
                  <span style={{ color: 'var(--text-muted)', fontSize: '10px' }}>
                    {new Date(insight.created_at).toLocaleString()}
                  </span>
                  {insight.expires_at && (
                    <span style={{ color: 'var(--text-muted)', fontSize: '10px' }}>
                      Expires: {new Date(insight.expires_at).toLocaleString()}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
})

AiPanel.displayName = 'AiPanel'
export default AiPanel
