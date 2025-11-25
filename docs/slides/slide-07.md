# DISCUSSÃO (Parte 2)
## Bounded Context & Anti-Corruption Layer

---

## BOUNDED CONTEXT "LLM INTEGRATION"

```
┌─────────────────────────────────┐
│   DOMÍNIO PEDAGÓGICO (Core)     │
│   [Experiência de Aprendizado]  │
└──────────┬──────────────────────┘
           │ Anti-Corruption Layer
┌──────────▼──────────────────────┐
│   LLM INTEGRATION (Suporte)     │
│   ┌─────────────────────────┐   │
│   │ Multi-Provider Strategy │   │
│   │ • Circuit Breaker       │   │
│   │ • Fallback Chain        │   │
│   │ • Semantic Cache        │   │
│   └─────────────────────────┘   │
│   OpenAI | Anthropic | Google   │
└─────────────────────────────────┘
```

## JUSTIFICATIVAS

- ✅ **Coesão funcional:** Lógica de roteamento/custos = subdomínio válido [Evans, 2003]
- ✅ **Autonomia:** APIs LLM evoluem em ritmo diferente do pedagógico [Vernon, 2013]
- ✅ **Testabilidade:** Isolamento permite mocks/stubs [Meszaros, 2007]

---

**Linguagem Ubíqua:** Provider • Model • GenerationRequest • PromptTemplate • SemanticCache • CircuitBreaker • FallbackChain

**Referências:** [Evans, 2003] • [Vernon, 2013] • [Meszaros, 2007] • [Newman, 2021] • [Fowler, 2014]

