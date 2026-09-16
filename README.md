# Supply Chain Ontology & Governed Conversational Analytics

Built for the Snowflake CoCo CLI Hackathon.

## Problem

Supply chain data is scattered across ERP, logistics, supplier, and IoT systems
with inconsistent definitions — the same question ("what's our fill rate?")
yields different answers depending on who's asked and which system they
pulled from.

## Solution

An **agentic pipeline** that takes raw, unclustered supply chain data, uses a
CoCo-built agent/skill to impose a governed ontology on it, exposes that
ontology as semantic views with canonical metric definitions, and serves it
through both a conversational (natural language) layer and a dashboard —
so every team gets the same answer, however they ask.

```
Raw / messy data  ─▶  CoCo Ontology Agent  ─▶  Governed Semantic Views  ─▶  ┬─▶ NL Agent (ask questions)
(ERP, logistics,       (maps, dedupes,          (Supplier→Part→Plant→        └─▶ Streamlit Dashboard
 supplier feeds)        resolves, relates)        Shipment→Order→Customer,
                                                    canonical metrics)
```

## Architecture

### 1. Raw data layer
Synthetic, deliberately messy data simulating multiple source systems —
inconsistent column names, mismatched keys/units, duplicate records,
orphaned references. Generated with CoCo.

### 2. CoCo Ontology Agent (skill)
A reusable CoCo skill that ingests the raw tables and:
- Maps inconsistent columns to the canonical ontology entities
- Resolves duplicates and standardizes keys/units
- Builds the entity relationships (Supplier → Part → Plant → Shipment →
  Order → Customer)
- Outputs clean governed **semantic views** with metric definitions baked in

Canonical metrics defined once, at a fixed grain, in the semantic layer:
- **On-time delivery rate**
- **Fill rate**
- **Days of inventory**

### 3. Conversational (agentic) layer
A natural-language agent grounded only in the governed semantic views —
answers resolve identically regardless of phrasing or which persona
(planning, procurement, logistics) asks.

### 4. Dashboard layer
Streamlit app combining a chat interface (hits the NL agent) with curated
visual dashboards of the canonical metrics.

## Tech stack

- Snowflake (database, semantic views)
- Snowflake CoCo CLI (Cortex Code) — used across planning, data generation,
  semantic view authoring, agent/skill build, and testing
- Cortex Analyst / agent for the NL layer
- Streamlit for the app/dashboard

## Setup

```
# 1. Clone this repo
# 2. Configure Snowflake connection (see .env.example)
# 3. Run CoCo to provision database/schema
# 4. Run the ontology agent skill against raw data
# 5. Launch the Streamlit app
streamlit run app.py
```

## Demo flow

1. Show the raw, messy source tables
2. Run the CoCo ontology agent live — watch it produce clean semantic views
3. Ask the same question two different ways (different phrasing, different
   persona) through the NL layer — show identical answers
4. Show the dashboard view of the same metrics

## Judging alignment

| Criterion | How this addresses it |
|---|---|
| Real World Relevance | Mirrors the actual mess of multi-system supply chain data |
| Technical Execution | Ontology agent, semantic views, NL agent, dashboard — full stack |
| Solution Completeness | End-to-end: messy data in, governed answers + visuals out |
| CoCo usage (all phases) | Planning (ontology draft), Development (agent/skill, semantic views, app), Execution (pipeline run), Testing (cross-persona consistency checks) |
| Bonus: reusable skill | Ontology-mapping agent is packaged as a shareable CoCo skill |

## Team / Status

_(fill in team members and current build status)_
