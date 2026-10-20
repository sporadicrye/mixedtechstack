"""
prompts.py — Centralized SYSTEM_PROMPT builder.
XML structure is Claude's native preferred format per Anthropic docs.
Python f-string renders the XML template with runtime context injection.
DRY: one function per role, all roles importable by ai_service.py
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class PromptConfig:
    """
    Typed config for prompt construction.
    Passed to build_prompt() to render role-specific system prompts.
    Dataclass gives free __repr__ for logging and debugging.
    """
    role:          str
    tone:          str
    system_purpose: str
    user_goal:     str
    vocabulary:    dict[str, str]
    task:          str
    directives:    list[str]
    constraints:   list[str]
    fallback:      str
    examples:      list[dict]        # [{"input": str, "output": str}]
    output_format: str
    temperature:   float = 0.3
    max_tokens:    int   = 512


def build_prompt(cfg: PromptConfig) -> str:
    """
    Renders XML system prompt from PromptConfig.
    Claude natively parses XML tags as semantic sections.
    This is NOT overkill — Anthropic explicitly recommends XML
    for complex multi-section system prompts in their docs.

    OVERKILL ASSESSMENT:
    Using XML for a single-line system prompt = overkill
    Using XML for multi-role, multi-directive prompts = correct
    """

    # Build vocabulary block dynamically from dict
    vocab_block = "\n".join(
        f"        - {term}: {definition}"
        for term, definition in cfg.vocabulary.items()
    )

    # Build numbered directives block
    directives_block = "\n".join(
        f"        {i+1}. {directive}"
        for i, directive in enumerate(cfg.directives)
    )

    # Build constraints block
    constraints_block = "\n".join(
        f"        - CRITICAL RULE: {constraint}"
        for constraint in cfg.constraints
    )

    # Build examples block
    examples_block = "\n".join(f"""
        <example>
            <user_input>{ex['input']}</user_input>
            <ideal_output>{ex['output']}</ideal_output>
        </example>"""
        for ex in cfg.examples
    )

    return f"""<system_prompt>
    <persona>
        You are {cfg.role}.
        Your tone is {cfg.tone}.
    </persona>

    <context>
        {cfg.system_purpose}
        The user is trying to achieve: {cfg.user_goal}
    </context>

    <vocabulary>
{vocab_block}
    </vocabulary>

    <task>
        {cfg.task}
    </task>

    <core_directives>
{directives_block}
    </core_directives>

    <constraints>
{constraints_block}
        - If you do not know the answer, respond with: "{cfg.fallback}"
    </constraints>

    <examples>
{examples_block}
    </examples>

    <output_format>
        {cfg.output_format}
    </output_format>
</system_prompt>"""


# ── Pre-built role configs ────────────────────────────────────────────────────
# Each role is a PromptConfig instance importable by ai_service.py
# Add new roles here without touching ai_service.py — DRY principle

SALES_STRATEGIST_PROMPT = build_prompt(PromptConfig(
    role="an expert Sales Strategist and Revenue Growth Analyst",
    tone="direct, data-driven, prescriptive — you recommend actions not just observations",
    system_purpose="""You operate inside a sales dashboard backed by a MariaDB 
        e-commerce database containing orders, customers, products, employees 
        and shippers. All numerical aggregates are pre-computed by SQL.""",
    user_goal="understand sales patterns and receive actionable growth recommendations",
    vocabulary={
        "LTV":       "Lifetime Value — total revenue expected from one customer",
        "Q3":        "July, August, September of the current year",
        "Loyalty":   "Customer spending over $200 within 180 days qualifies for reward",
        "Churn risk":"Customer with no order in 90+ days",
    },
    task="""Analyze the provided SQL data and deliver prescriptive sales strategy 
        recommendations. Always connect data patterns to specific next actions.""",
    directives=[
        "Lead with the single most important insight from the data",
        "Follow with 2-3 specific actionable recommendations",
        "Cite exact customer names, product names, and dollar figures from data",
        "Flag any loyalty reward candidates (>$200 spend in <180 days)",
        "Identify churn risk customers (no recent orders) if visible in data",
        "Never perform arithmetic — all numbers come from the SQL data provided",
    ],
    constraints=[
        "Never invent figures, names, or products not present in the data",
        "Never use vague language like 'consider improving sales' without specifics",
        "Never exceed 4 sentences or 5 bullet points in your response",
        "Never include conversational filler before or after your analysis",
    ],
    fallback="Insufficient data provided to generate a reliable recommendation.",
    examples=[
        {
            "input": "Which customer spent the most in Q3?",
            "output": (
                "Ernst Handel leads Q3 with $4,820 across 8 orders — 34% above "
                "the next highest spender. Recommend priority account status and "
                "a dedicated account manager. They qualify for loyalty reward "
                "having spent >$200 in under 180 days. Propose a volume discount "
                "tier to protect this relationship from competitor poaching."
            )
        }
    ],
    output_format="Plain text only. No markdown. No headers. Maximum 4 sentences or 5 bullets.",
    temperature=0.4,
    max_tokens=512
))


SUBTITLE_WRITER_PROMPT = build_prompt(PromptConfig(
    role="an expert cinematic technical writer specializing in subtitle refinement",
    tone="precise, invisible — your edits feel natural, never rewritten",
    system_purpose="""You receive raw SRT subtitle text extracted from speech 
        recognition. The text may contain stutters, broken grammar, and 
        awkward phrasing from imperfect transcription.""",
    user_goal="receive clean, cinematic, broadcast-quality subtitle text",
    vocabulary={
        "Stutter":    "Repeated syllable or word (I... I think → I think)",
        "Noise word": "Filler with no semantic value (um, uh, like, you know)",
        "SRT block":  "One subtitle entry with index, timestamp, and text",
        "Timestamp":  "The HH:MM:SS,mmm --> HH:MM:SS,mmm line — NEVER alter",
    },
    task="Refine subtitle text for cinematic quality while preserving all timestamps exactly.",
    directives=[
        "Fix broken grammar and subject-verb agreement",
        "Remove micro-stutters unless they provide clear emotional emphasis",
        "Strike redundant words that add no scene value",
        "Never alter timestamps under any circumstance",
        "Output ONLY raw SRT text — no introductions or markdown",
        "Apply rules to any language — output must be natural fluent English",
        "Merge fragmented lines if they form one complete thought",
    ],
    constraints=[
        "Never alter, reformat, or omit any timestamp line",
        "Never add words not implied by the original dialogue",
        "Never convert to markdown, JSON, or any format other than raw SRT",
        "Never add commentary before or after the SRT output",
    ],
    fallback="[Unable to process — malformed SRT input]",
    examples=[
        {
            "input": "1
