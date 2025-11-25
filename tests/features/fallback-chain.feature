# language: pt
Funcionalidade: Cadeia de Fallback em Múltiplas Camadas
  Como desenvolvedor do sistema de integração LLM
  Quero que o sistema execute fallback automático entre provedores
  Para garantir disponibilidade contínua mesmo com falhas parciais

  Contexto:
    Dado que o orquestrador de fallback está operacional
    E a cadeia de fallback está configurada com:
      | camada | provedor  | modelo                      | timeout |
      | 1      | openai    | gpt-4o-mini                 | 5s      |
      | 2      | anthropic | claude-3-5-haiku-20241022   | 5s      |
      | 3      | legacy    | precomputed_templates       | N/A     |
    E o global_timeout é 12 segundos

  @smoke @critical
  Cenário: Sucesso no provedor primário sem ativação de fallback
    Dado que o provedor "openai" está disponível
    Quando uma requisição de geração é enviada:
      """
      {
        "prompt": "Crie um diálogo em inglês sobre ir ao supermercado",
        "parameters": {"temperature": 0.7, "max_tokens": 300},
        "context": {"proficiency_level": "A2"}
      }
      """
    Então a resposta deve ser gerada pelo provedor "openai"
    E o campo "fallback_activated" deve ser false
    E o campo "fallback_chain" deve estar vazio
    E a latência total deve ser menor que 6 segundos

  @critical
  Cenário: Fallback para provedor secundário após falha primária
    Dado que o circuit breaker para "openai" está no estado "OPEN"
    E o provedor "anthropic" está disponível
    Quando uma requisição de geração é enviada
    Então a resposta deve ser gerada pelo provedor "anthropic"
    E o campo "fallback_activated" deve ser true
    E o campo "fallback_chain" deve conter:
      """
      [
        {
          "provider": "openai",
          "reason": "circuit_breaker_open",
          "timestamp": "<ISO8601>"
        }
      ]
      """
    E o campo "provider_used" deve ser "anthropic"

  @critical
  Cenário: Fallback para conteúdo legado quando todos os provedores falham
    Dado que todos os provedores LLM estão indisponíveis:
      | provedor  | motivo             |
      | openai    | circuit_breaker_open |
      | anthropic | timeout            |
      | google    | rate_limit_exceeded |
    Quando uma requisição de geração é enviada
    Então o status HTTP deve ser 503 Service Unavailable
    E o campo "provider_used" deve ser "legacy"
    E o campo "fallback_activated" deve ser true
    E o conteúdo deve incluir mensagem de modo degradado
    E o campo "fallback_chain" deve conter tentativas em todos os 3 provedores
    E os metadados devem incluir "degraded_mode": true

  @critical
  Cenário: Preservação de contexto entre camadas de fallback
    Dado que o provedor "openai" falha com timeout
    E o provedor "anthropic" está disponível
    Quando uma requisição de geração é enviada com contexto:
      """
      {
        "prompt": "Crie diálogo",
        "context": {
          "user_id": "student_12345",
          "session_id": "sess_abc123",
          "proficiency_level": "A2",
          "target_language": "en"
        }
      }
      """
    Então a requisição ao provedor "anthropic" deve preservar:
      | campo              | valor         |
      | prompt original    | Crie diálogo  |
      | user_id            | student_12345 |
      | session_id         | sess_abc123   |
      | proficiency_level  | A2            |
      | target_language    | en            |

  Cenário: Métricas de ativação de fallback por camada
    Dado que o sistema está em produção
    E houve 100 requisições nas últimas 24 horas com:
      | camada  | sucessos |
      | primário     | 85       |
      | secundário   | 13       |
      | legacy       | 2        |
    Quando consulto as métricas de fallback
    Então os dados devem mostrar:
      | metrica              | valor |
      | total_requests       | 100   |
      | primary_success      | 85    |
      | secondary_success    | 13    |
      | legacy_fallback      | 2     |
      | fallback_rate        | 15%   |

  @observability
  Cenário: Rastreabilidade de tentativas de fallback
    Dado que o provedor primário falha
    Quando a cadeia de fallback é ativada
    Então cada tentativa deve ser registrada com:
      | campo     | tipo      | exemplo                 |
      | provider  | string    | openai                  |
      | reason    | enum      | circuit_breaker_open    |
      | timestamp | ISO8601   | 2025-11-25T14:32:18Z    |
    E o histórico completo deve estar disponível na resposta
    E métricas devem ser incrementadas:
      | métrica                           | incremento |
      | fallback.activated{openai, layer1} | +1        |
      | fallback.success{anthropic, layer2} | +1        |

  @edge-case
  Cenário: Global timeout previne tentativas infinitas
    Dado que a cadeia de fallback está configurada com global_timeout de 12 segundos
    E cada provedor tem timeout individual de 5 segundos
    Quando o provedor primário demora 6 segundos (timeout)
    E o provedor secundário começa a processar
    Então o orquestrador deve calcular tempo restante: 12 - 6 = 6 segundos
    E deve permitir tentativa no secundário
    E se o secundário também atingir timeout, deve retornar erro imediatamente
    E não deve tentar terceira camada se global_timeout for excedido

  @configuration
  Cenário: Configuração dinâmica de prioridades de provedor
    Dado que a configuração atual de fallback é:
      | ordem | provedor  |
      | 1     | openai    |
      | 2     | anthropic |
    Quando um administrador atualiza a configuração para:
      | ordem | provedor  |
      | 1     | anthropic |
      | 2     | openai    |
    Então as próximas requisições devem tentar "anthropic" primeiro
    E a alteração deve ser aplicada sem reinicialização do serviço

  @performance
  Cenário: Latência adicional de fallback é aceitável
    Dado que o provedor primário falha imediatamente (circuit breaker OPEN)
    E o provedor secundário responde em 2 segundos
    Quando uma requisição é processada com fallback
    Então a latência total deve ser aproximadamente 2 segundos
    E o overhead de orquestração deve ser menor que 50ms
    E a experiência do usuário deve ser mantida com loading states

  @integration
  Cenário: Integração com moderação de conteúdo na cadeia de fallback
    Dado que o provedor primário retorna conteúdo inadequado
    E a moderação bloqueia a resposta
    Quando a cadeia de fallback tenta o provedor secundário
    Então o novo conteúdo deve passar novamente pela moderação
    E apenas conteúdo aprovado deve ser retornado
    E as tentativas de moderação devem ser contabilizadas

  @edge-case
  Cenário: Desabilitação de fallback por requisição específica
    Dado que a cadeia de fallback está habilitada globalmente
    Quando uma requisição é enviada com configuração:
      """
      {
        "prompt": "Teste",
        "fallback_config": {
          "enable_fallback": false
        }
      }
      """
    E o provedor primário falha
    Então o sistema deve falhar imediatamente
    E não deve tentar provedores secundários
    E deve retornar erro indicando falha no provedor primário

  @edge-case
  Cenário: Limitar número máximo de retries
    Dado que a configuração permite max_retries de 2
    E existem 5 provedores configurados
    Quando o provedor primário falha
    Então o sistema deve tentar no máximo 2 provedores adicionais
    E não deve tentar os 5 provedores
    E deve retornar erro se os 2 retries falharem

  Cenário: Conteúdo legado é apropriado ao contexto pedagógico
    Dado que todos os provedores LLM estão indisponíveis
    E a requisição tem contexto:
      | proficiency_level | A2      |
      | target_language   | inglês  |
      | topic             | restaurante |
    Quando o fallback para conteúdo legado é ativado
    Então o conteúdo retornado deve ser um template apropriado para:
      | campo              | valor       |
      | nível              | A2          |
      | idioma             | inglês      |
      | tópico próximo     | restaurante |
    E deve incluir aviso de modo degradado
    E deve sugerir que o usuário tente novamente mais tarde

  @cost-optimization
  Cenário: Fallback considera custo de provedor secundário
    Dado que os provedores têm custos diferentes:
      | provedor  | custo_por_1k_tokens |
      | openai    | $0.0015             |
      | anthropic | $0.0010             |
      | google    | $0.0007             |
    E o provedor primário "openai" está indisponível
    Quando fallback é ativado
    Então o sistema deve preferir "google" (mais econômico) como secundário
    E os metadados devem incluir custo real da requisição

  @resilience
  Cenário: Circuit breaker por provedor não afeta cadeia
    Dado que existem 3 provedores na cadeia
    E 2 provedores têm circuit breakers em estado OPEN
    Quando uma requisição é feita
    Então o sistema deve tentar apenas o provedor com circuit breaker CLOSED
    E deve completar a requisição com sucesso
    E deve registrar que 2 camadas foram skipadas por circuit breaker

