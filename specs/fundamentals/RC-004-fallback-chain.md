# RC-004: Cadeia de Fallback em Múltiplas Camadas

## Categoria
Resiliência

## Descrição

Implementação de estratégia de fallback em múltiplas camadas para garantir disponibilidade degradada do sistema diante de falhas de provedores LLM. A cadeia opera em três níveis hierárquicos: (1) tentativa no provedor primário, (2) circuit breaker para detecção de falhas, e (3) fallback para provedor secundário ou conteúdo pré-computado/legado. Esta abordagem garante que o sistema continue operacional mesmo com indisponibilidade parcial ou total de APIs externas.

## Justificativa Técnica

A integração com APIs de LLM introduz dependências externas sobre as quais o sistema não possui controle direto. Como documentado por Newman (2021), sistemas distribuídos resilientes devem planejar explicitamente estratégias de degradação graceful. A combinação de circuit breakers com cadeias de fallback constitui padrão consolidado para:

1. **Maximizar disponibilidade**: Sistema permanece operacional mesmo com falha de provedores individuais
2. **Minimizar impacto ao usuário**: Transição transparente entre provedores ou conteúdo legado
3. **Aproveitar redundância multi-provedor**: Orquestração descrita em RC-001 torna-se efetiva através de fallback automático

A literatura de padrões de integração (Fowler, 2009, 2012) estabelece que fallback não é mera recuperação de erro, mas estratégia arquitetural que requer:
- **Ordenação por prioridade**: Provedores classificados por custo, latência e confiabilidade
- **Preservação de contexto**: Estado da requisição deve ser mantido durante transições
- **Observabilidade**: Métricas de ativação de fallback indicam problemas operacionais

Em sistemas educacionais, a continuidade de serviço é crítica: estudantes não devem ter experiência interrompida por falhas temporárias de infraestrutura externa.

## Validação QFD

**IAR (Índice de Adequação do Requisito): 2.91**

| Critério | Score | Peso | Justificativa |
|----------|-------|------|---------------|
| **Viabilidade Técnica** | 3 | ×3 | Padrão bem estabelecido, implementável com lógica condicional e configuração de prioridades. |
| **Testabilidade** | 3 | ×3 | Fluxo de fallback determinístico testável através de injeção de falhas simuladas em cada camada. |
| **Coesão de Domínio** | 3 | ×2 | Essencial para bounded context "LLM Integration" gerenciar múltiplos provedores com resiliência. |
| **Impacto na Solução** | 3 | ×2 | Crítico para disponibilidade contínua em produção educacional. |
| **Complexidade de Implementação** | 2 | ×1 | Moderada: requer orquestração de lógica de fallback, configuração de prioridades e testes end-to-end. |

**Classificação: 🟢 Fundamental (P0)**

## Critérios de Aceitação

### CA-01: Tentativa no Provedor Primário
**Dado** que uma requisição de geração é iniciada  
**Quando** o sistema seleciona o provedor primário baseado em critérios de roteamento  
**Então** deve executar a requisição no provedor primário  
**E** deve aguardar resposta dentro do timeout configurado (5s padrão)

### CA-02: Ativação de Circuit Breaker em Falha
**Dado** que a requisição ao provedor primário falhou  
**Quando** o circuit breaker detecta threshold de falhas excedido  
**Então** deve transitar para estado OPEN  
**E** deve ativar automaticamente a segunda camada de fallback

### CA-03: Fallback para Provedor Secundário
**Dado** que o provedor primário está indisponível (circuit breaker OPEN)  
**Quando** a cadeia de fallback é ativada  
**Então** deve selecionar provedor secundário da lista de prioridades  
**E** deve executar requisição com mesmo payload e contexto  
**E** deve marcar a origem da resposta como "fallback:secondary_provider"

### CA-04: Fallback para Conteúdo Legado
**Dado** que todos os provedores LLM estão indisponíveis  
**Quando** a cadeia de fallback esgota alternativas de provedores  
**Então** deve retornar conteúdo pré-computado ou template genérico  
**E** deve marcar resposta como "fallback:legacy_content"  
**E** deve incluir aviso ao usuário sobre modo degradado

### CA-05: Preservação de Contexto entre Camadas
**Dado** que ocorre transição entre camadas de fallback  
**Quando** a requisição é redirecionada  
**Então** deve preservar:
- Prompt original
- Parâmetros de geração (temperature, max_tokens)
- Metadados de contexto (user_id, session_id)
- Histórico de tentativas para rastreabilidade

### CA-06: Métricas de Ativação de Fallback
**Dado** que a cadeia de fallback é ativada  
**Quando** qualquer camada é utilizada  
**Então** deve incrementar métricas específicas:
- `fallback.activated{provider, layer}`
- `fallback.success{provider, layer}`
- `fallback.latency{provider, layer}`

## Especificação de Testabilidade (BDD/Gherkin)

Ver arquivo: `/tests/features/fallback-chain.feature`

## Contrato de Interface (OpenAPI 3.1)

Ver arquivo: `/contracts/fallback-orchestrator.yaml`

## Decisão de Design

### Padrão Arquitetural Escolhido
**Cadeia de Responsabilidade (Chain of Responsibility)** com três camadas hierárquicas ordenadas por prioridade decrescente.

### Estrutura da Cadeia

```
Requisição de Geração
        ↓
[Camada 1] Provedor Primário (ex: OpenAI GPT-4)
    ↓ (falha)
[Circuit Breaker] Detecção de falha
    ↓ (OPEN)
[Camada 2] Provedor Secundário (ex: Anthropic Claude)
    ↓ (falha)
[Camada 3] Conteúdo Legado/Template
    ↓
Resposta (com flag de origem)
```

### Alternativas Consideradas

1. **Retry simples no mesmo provedor**
   - ❌ Rejeitado: Não aproveita redundância multi-provedor
   - ❌ Aumenta latência sem garantir sucesso

2. **Fallback paralelo (scatter-gather)**
   - ❌ Rejeitado para MVP: Custo multiplicado (todas requisições executadas simultaneamente)
   - ⚠️ Pode ser considerado para cenários de ultra-baixa latência em versões futuras

3. **Fallback apenas para conteúdo estático**
   - ❌ Rejeitado: Desperdiça capacidade de redundância multi-provedor documentada em RC-001

### Trade-offs Explícitos

| Aspecto | Benefício | Custo |
|---------|-----------|-------|
| **Disponibilidade** | ✅ Sistema continua operacional com degradação controlada | ❌ Qualidade de resposta pode variar entre provedores |
| **Latência** | ❌ Latência total pode aumentar (até 2× em fallback) | ✅ Transparente ao usuário através de loading states |
| **Custo** | ✅ Fallback só ocorre em falhas (não aumenta custo base) | ⚠️ Pode utilizar provedores mais caros como secundários |
| **Complexidade** | ❌ Lógica de orquestração e testes multi-camada | ✅ Padrão Chain of Responsibility bem documentado |

### Configuração Recomendada

```yaml
fallback_chain:
  primary:
    provider: "openai"
    model: "gpt-4o-mini"
    timeout: 5s
    
  secondary:
    provider: "anthropic"
    model: "claude-3-5-haiku-20241022"
    timeout: 5s
    
  tertiary:
    type: "legacy_content"
    source: "precomputed_templates"
    
  global_timeout: 12s  # Soma dos timeouts + overhead
  preserve_context: true
  emit_fallback_metrics: true
```

### Critérios de Seleção de Provedor Secundário

1. **Custo**: Preferir modelos mais econômicos para fallback
2. **Latência**: P95 latency documentada (Bian et al., 2025)
3. **Context window**: Deve suportar tamanho de prompt similar ao primário
4. **Capacidade multimodal**: Se requisição contém imagens, provedor secundário deve suportá-las

## Referências

- NEWMAN, S. Building Microservices: Designing Fine-Grained Systems. 2nd ed. O'Reilly Media, 2021.
- FOWLER, M. Patterns of Enterprise Application Architecture. Addison-Wesley, 2002.
- FOWLER, M. Contract Test. Martin Fowler's Bliki, 2009, 2012.
- BIAN, S. et al. What Limits Agentic Systems Efficiency? arXiv:2510.16276, 2025.
- GAMMA, E. et al. Design Patterns: Elements of Reusable Object-Oriented Software. Addison-Wesley, 1994. (Chain of Responsibility pattern)

---

**Versão:** 1.0  
**Data:** Novembro 2025  
**Status:** Especificação Validada (QFD)

