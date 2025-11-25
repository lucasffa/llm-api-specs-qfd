# Apêndice B: Matriz de Validação QFD

A tabela abaixo apresenta o cálculo do **Índice de Adequação do Requisito (IAR)**.
Fórmula: `IAR = Σ(Critério_i × Peso_i) / Σ(Peso_i)` onde a soma dos pesos é 11.

**Critérios e Pesos:**
1.  **Viabilidade (Viab):** Peso 3
2.  **Testabilidade (Test):** Peso 3
3.  **Coesão de Domínio (Coesão):** Peso 2
4.  **Impacto (Impacto):** Peso 2
5.  **Complexidade (Compl):** Peso 1 (Escala invertida: 3 = baixa complexidade/bom)

**Classificação:**
*   🟢 **Fundamental:** IAR ≥ 2.5
*   🟡 **Importante:** 2.0 ≤ IAR < 2.5
*   🔴 **Descartado:** IAR < 2.0

| ID | Requisito | Viab (x3) | Test (x3) | Coesão (x2) | Impacto (x2) | Compl (x1) | IAR | Classificação |
|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| **RC-003** | **Circuit Breaker** | 3 | 3 | 3 | 3 | 2 | **2.91** | 🟢 **Fundamental** |
| **RC-004** | **Cadeia de Fallback** | 3 | 3 | 3 | 3 | 2 | **2.91** | 🟢 **Fundamental** |
| **RC-014** | **Prompt Iterativo (Few-shot)** | 3 | 3 | 3 | 3 | 2 | **2.91** | 🟢 **Fundamental** |
| **RC-016** | **Filtros de Moderação** | 3 | 3 | 3 | 3 | 2 | **2.91** | 🟢 **Fundamental** |
| RC-012 | Validação Human-in-the-loop | 3 | 2 | 2 | 3 | 2 | 2.45 | 🟡 Importante |
| RC-007 | Cache LRU + Batching | 3 | 2 | 2 | 2 | 2 | 2.27 | 🟡 Importante |
| RC-001 | Orquestração Multi-provedor | 2 | 2 | 3 | 2 | 2 | 2.18 | 🟡 Importante |
| RC-006 | Cache Semântico | 2 | 2 | 3 | 2 | 2 | 2.18 | 🟡 Importante |
| RC-008 | API Processamento em Lote | 3 | 2 | 2 | 1 | 2 | 2.09 | 🟡 Importante |
| RC-011 | Pipeline Validação 3 Camadas | 2 | 2 | 3 | 2 | 1 | 2.09 | 🟡 Importante |
| RC-002 | Eliminação Dep. Rígidas | 3 | 2 | 2 | 2 | 2 | 2.00 | 🟡 Importante |
| RC-009 | Controle Orçamentário | 2 | 2 | 2 | 2 | 2 | 2.00 | 🟡 Importante |
| RC-010 | Contagem Prévia Tokens | 2 | 2 | 2 | 2 | 2 | 2.00 | 🟡 Importante |
| RC-013 | Métricas Qualidade Usuario | 2 | 2 | 2 | 2 | 2 | 2.00 | 🟡 Importante |
| RC-015 | Refinamento Iterativo | 2 | 2 | 2 | 2 | 2 | 2.00 | 🟡 Importante |
| RC-017 | Observabilidade Unificada | 2 | 2 | 2 | 2 | 2 | 2.00 | 🟡 Importante |
| RC-021 | Métricas Específicas LLM | 2 | 2 | 2 | 2 | 2 | 2.00 | 🟡 Importante |
| RC-018 | Tracing Distribuído | 2 | 2 | 2 | 1 | 2 | 1.82 | 🔴 Descartado |
| RC-022 | Atributos Contexto Negócio | 2 | 1 | 2 | 1 | 2 | 1.55 | 🔴 Descartado |
| RC-005 | Redundância Multi-nuvem | 1 | 1 | 1 | 1 | 1 | 1.00 | 🔴 Descartado |
| RC-019 | Detecção Anomalias Auto | 1 | 1 | 1 | 1 | 1 | 1.00 | 🔴 Descartado |
| RC-020 | Stack Multi-ferramenta | 1 | 1 | 1 | 1 | 1 | 1.00 | 🔴 Descartado |