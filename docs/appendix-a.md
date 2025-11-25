# Apêndice A: Requisitos Candidatos Identificados

Abaixo estão listados os 22 requisitos levantados na fase de elicitação, categorizados por área técnica.

| ID | Categoria | Requisito | Descrição Resumida | Fonte Principal |
| :--- | :--- | :--- | :--- | :--- |
| **RC-001** | Resiliência | Orquestração multi-provedor | Roteamento inteligente e fallback automático entre provedores. | Evans (2003), Vernon (2013) |
| **RC-002** | Resiliência | Eliminação de dependências rígidas | Pré-computação + cache para evitar dependências no caminho crítico. | Sculley et al. (2015) |
| **RC-003** | Resiliência | Padrão Circuit Breaker | Proteção contra falhas em cascata de APIs externas. | Fowler, Newman (2021) |
| **RC-004** | Resiliência | Cadeia de Fallback | Tentativa → Circuit Breaker → Conteúdo Legado. | Newman (2021) |
| **RC-005** | Resiliência | Redundância Multi-nuvem | Eliminação de ponto único de falha via multi-cloud. | Armbrust et al. (2010) |
| **RC-006** | Otimização | Cache Semântico (Embeddings) | Deduplicação de prompts similares usando vetores. | Anthropic, Huyen (2023) |
| **RC-007** | Otimização | Cache LRU + Batching | Gravações em lote para redução de custos de I/O. | Huyen (2023) |
| **RC-008** | Otimização | API de Processamento em Lote | Uso de Batch APIs para requisições não sensíveis ao tempo. | OpenAI (2025) |
| **RC-009** | Governança | Controle Orçamentário | Limites de custo configuráveis por usuário/sessão. | OpenAI, Google AI |
| **RC-010** | Governança | Contagem Prévia de Tokens | Estimativa precisa antes da requisição (Rate Limiting Aware). | OpenAI (2025) |
| **RC-011** | Qualidade | Pipeline de Validação (3 camadas) | Geração → Validação Humana → Filtro Algorítmico. | Yan et al. (2024b) |
| **RC-012** | Qualidade | Validação Human-in-the-loop | Validação obrigatória humana após geração. | Yan et al. (2024b) |
| **RC-013** | Qualidade | Métricas Comportamentais | Avaliação baseada no uso do usuário, não apenas acurácia técnica. | Langfuse (2025) |
| **RC-014** | Qualidade | Engenharia de Prompt Iterativa | Exemplos *few-shot* + restrições específicas de domínio. | Freeman & Pryce (2009) |
| **RC-015** | Qualidade | Refinamento Iterativo (Feedback) | Ciclo de feedback para ajuste fino de prompts. | Beck (2002) |
| **RC-016** | Segurança | Filtros de Moderação | Prevenção de alucinações e conteúdo inadequado. | OWASP (2025), Benjamin et al. |
| **RC-017** | Observabilidade | Observabilidade Unificada | Métricas + Traces + Logs em plataforma única. | ZenML (2024) |
| **RC-018** | Observabilidade | Tracing Distribuído (OpenTelemetry) | Spans personalizados para chamadas de LLM. | ZenML (2024) |
| **RC-019** | Observabilidade | Detecção de Anomalias | Monitoramento automático de *drift* nos dados. | Sculley et al. (2015) |
| **RC-020** | Observabilidade | Stack Multi-ferramenta | Infraestrutura complexa integrada para monitoramento de ML. | ZenML (2024) |
| **RC-021** | Observabilidade | Métricas Específicas de LLM | Latência por provedor, taxa de cache, custo/token. | Langfuse (2025) |
| **RC-022** | Observabilidade | Atributos de Contexto de Negócio | Rastreamento por custo, cohort ou variante de experimento. | Amershi et al. (2019) |