# RC-003: Padrão Circuit Breaker para Proteção contra Falhas em Cascata

## Categoria
Resiliência

## Descrição

Implementação do padrão Circuit Breaker para proteger o sistema contra falhas em cascata causadas por indisponibilidade ou degradação de APIs de LLM externas. O circuit breaker atua como disjuntor automático que detecta falhas repetidas e interrompe temporariamente requisições a serviços degradados, preservando recursos do sistema e permitindo recuperação gradual.

## Justificativa Técnica

A dependência de APIs externas de LLM introduz riscos operacionais significativos. Como documentado por Newman (2021), retries simples em cenários de degradação prolongada consomem recursos sem agregar valor, podendo esgotar pools de conexão e propagar falhas para componentes dependentes. O padrão Circuit Breaker, descrito originalmente por Fowler e amplamente adotado em arquiteturas de microserviços, oferece mecanismo fail-fast que:

1. **Previne cascata de falhas**: Interrompe automaticamente chamadas a serviços não-responsivos
2. **Preserva recursos**: Evita esgotamento de threads, conexões e timeouts desnecessários
3. **Permite recuperação gradual**: Estado HALF-OPEN testa periodicamente a recuperação do serviço

Em contextos de integração multi-provedor com LLMs (OpenAI, Anthropic, Google), a variabilidade de latência documentada por Bian et al. (2025) e os rate limits complexos descritos por OpenAI (2025) tornam este padrão essencial para garantir disponibilidade degradada preferível a falhas totais.

## Validação QFD

**IAR (Índice de Adequação do Requisito): 2.91**

| Critério | Score | Peso | Justificativa |
|----------|-------|------|---------------|
| **Viabilidade Técnica** | 3 | ×3 | Bibliotecas maduras disponíveis: Polly (.NET), Resilience4j (Java), PyBreaker (Python). Padrão consolidado na indústria. |
| **Testabilidade** | 3 | ×3 | Transições de estado determinísticas (CLOSED → OPEN → HALF-OPEN) simuláveis por injeção de falhas controladas. |
| **Coesão de Domínio** | 3 | ×2 | Mecanismo essencial ao bounded context "LLM Integration" para gerenciar dependências externas não-determinísticas. |
| **Impacto na Solução** | 3 | ×2 | Crítico para prevenção de falhas em cascata e manutenção de disponibilidade em produção. |
| **Complexidade de Implementação** | 2 | ×1 | Moderada: requer configuração de thresholds, timeouts e testes de transição de estados. |

**Classificação: 🟢 Fundamental (P0)**

## Critérios de Aceitação

### CA-01: Detecção Automática de Falhas
**Dado** que o circuit breaker está no estado CLOSED  
**Quando** ocorrem N falhas consecutivas dentro de uma janela temporal T  
**Então** o circuit breaker deve transitar automaticamente para o estado OPEN

**Parâmetros configuráveis:**
- Threshold de falhas: 5 falhas consecutivas (padrão)
- Janela temporal: 60 segundos
- Tipos de falha considerados: timeout, HTTP 5xx, exceções de rede

### CA-02: Fail-Fast em Estado OPEN
**Dado** que o circuit breaker está no estado OPEN  
**Quando** uma requisição é feita ao provedor LLM  
**Então** o sistema deve rejeitar imediatamente a requisição sem invocar a API externa  
**E** deve retornar erro `CircuitBreakerOpenException` com tempo estimado de recuperação

### CA-03: Recuperação Gradual (Half-Open)
**Dado** que o circuit breaker está no estado OPEN por tempo >= timeout de recuperação  
**Quando** o temporizador expira  
**Então** o circuit breaker deve transitar para o estado HALF-OPEN  
**E** deve permitir exatamente 1 requisição de teste

### CA-04: Transição de HALF-OPEN para CLOSED
**Dado** que o circuit breaker está no estado HALF-OPEN  
**Quando** a requisição de teste é bem-sucedida  
**Então** o circuit breaker deve transitar para CLOSED  
**E** deve resetar o contador de falhas

### CA-05: Retorno a OPEN em Caso de Falha
**Dado** que o circuit breaker está no estado HALF-OPEN  
**Quando** a requisição de teste falha  
**Então** o circuit breaker deve retornar ao estado OPEN  
**E** deve reiniciar o temporizador de recuperação com backoff exponencial

### CA-06: Observabilidade de Estados
**Dado** que o circuit breaker está operacional  
**Quando** ocorre qualquer transição de estado  
**Então** o sistema deve emitir evento de log estruturado com:
- Timestamp
- Estado anterior e novo estado
- Provedor LLM afetado
- Contadores de falha atuais

## Especificação de Testabilidade (BDD/Gherkin)

Ver arquivo: `/tests/features/circuit-breaker.feature`

## Contrato de Interface (OpenAPI 3.1)

Ver arquivo: `/contracts/circuit-breaker-service.yaml`

## Decisão de Design

### Padrão Arquitetural Escolhido
**Circuit Breaker por Provedor** com configuração independente para cada provedor de LLM (OpenAI, Anthropic, Google).

### Alternativas Consideradas

1. **Retries simples com backoff exponencial**
   - ❌ Rejeitado: Consome recursos em degradações prolongadas
   - ❌ Não protege contra esgotamento de pools de conexão
   - ❌ Aumenta latência percebida pelo usuário

2. **Circuit Breaker global único**
   - ❌ Rejeitado: Um provedor degradado bloquearia todos os provedores
   - ❌ Impede aproveitamento de redundância multi-provedor

3. **Circuit Breaker por endpoint**
   - ⚠️ Granularidade excessiva para MVP
   - ⚠️ Complexidade operacional desproporcional

### Trade-offs Explícitos

| Aspecto | Benefício | Custo |
|---------|-----------|-------|
| **Resiliência** | ✅ Fail-fast preserva recursos | ❌ Requisições legítimas podem ser rejeitadas durante recuperação |
| **Observabilidade** | ✅ Estados explícitos facilitam debugging | ❌ Overhead de logging e métricas |
| **Complexidade** | ❌ Introduz estado adicional e lógica de transição | ✅ Padrão bem documentado com bibliotecas maduras |
| **Latência** | ✅ Rejeição imediata em estado OPEN (< 1ms) | ⚠️ Overhead de verificação de estado em CLOSED (~100μs) |

### Configuração Recomendada por Provedor

```yaml
OpenAI:
  failure_threshold: 5
  timeout: 60s
  half_open_max_calls: 1
  
Anthropic:
  failure_threshold: 5
  timeout: 60s
  half_open_max_calls: 1
  
Google:
  failure_threshold: 5
  timeout: 45s  # Menor devido a SLA mais agressivo
  half_open_max_calls: 1
```

## Referências

- FOWLER, M. Circuit Breaker Pattern. Martin Fowler's Bliki.
- NEWMAN, S. Building Microservices: Designing Fine-Grained Systems. 2nd ed. O'Reilly Media, 2021.
- NYGARD, M. T. Release It!: Design and Deploy Production-Ready Software. Pragmatic Bookshelf, 2007.
- OPENAI. Rate Limits - OpenAI API. 2025.
- BIAN, S. et al. What Limits Agentic Systems Efficiency? arXiv:2510.16276, 2025.

---

**Versão:** 1.0  
**Data:** Novembro 2025  
**Status:** Especificação Validada (QFD)

