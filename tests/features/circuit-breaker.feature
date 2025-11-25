# language: pt
Funcionalidade: Circuit Breaker para Proteção contra Falhas em Cascata
  Como desenvolvedor do sistema de integração LLM
  Quero que o circuit breaker proteja contra falhas em cascata
  Para garantir resiliência e preservação de recursos do sistema

  Contexto:
    Dado que o serviço de circuit breaker está operacional
    E o provedor "openai" está configurado com:
      | failure_threshold   | 5  |
      | timeout_seconds     | 60 |
      | half_open_max_calls | 1  |

  @smoke @critical
  Cenário: Transição de CLOSED para OPEN após threshold de falhas
    Dado que o circuit breaker para "openai" está no estado "CLOSED"
    E o contador de falhas está em 0
    Quando ocorrem 5 falhas consecutivas de requisição LLM
    Então o circuit breaker deve transitar para o estado "OPEN"
    E o contador de falhas deve ser 5
    E deve ser registrado evento de log com:
      | estado_anterior | CLOSED |
      | novo_estado     | OPEN   |
      | provedor        | openai |

  @critical
  Cenário: Fail-fast em estado OPEN rejeita requisições imediatamente
    Dado que o circuit breaker para "openai" está no estado "OPEN"
    E o último tempo de falha foi há 30 segundos
    Quando uma nova requisição LLM é feita para "openai"
    Então a requisição deve ser rejeitada imediatamente
    E não deve invocar a API externa
    E deve retornar erro "CircuitBreakerOpenException"
    E a mensagem deve incluir tempo estimado de recuperação
    E a latência de rejeição deve ser menor que 10 milissegundos

  @critical
  Cenário: Transição de OPEN para HALF_OPEN após timeout
    Dado que o circuit breaker para "openai" está no estado "OPEN"
    E o timeout de recuperação é 60 segundos
    E o último tempo de falha foi há 61 segundos
    Quando o temporizador de recuperação expira
    Então o circuit breaker deve transitar para o estado "HALF_OPEN"
    E deve permitir exatamente 1 requisição de teste
    E deve registrar evento de transição

  @critical
  Cenário: Recuperação bem-sucedida: HALF_OPEN para CLOSED
    Dado que o circuit breaker para "openai" está no estado "HALF_OPEN"
    Quando a requisição de teste é bem-sucedida
    Então o circuit breaker deve transitar para o estado "CLOSED"
    E o contador de falhas deve ser resetado para 0
    E deve registrar evento de recuperação bem-sucedida

  @critical
  Cenário: Falha na recuperação: HALF_OPEN retorna a OPEN
    Dado que o circuit breaker para "openai" está no estado "HALF_OPEN"
    Quando a requisição de teste falha com timeout
    Então o circuit breaker deve retornar ao estado "OPEN"
    E o temporizador de recuperação deve ser reiniciado
    E o backoff exponencial deve ser aplicado (timeout aumenta para 120 segundos)
    E deve registrar evento de falha de recuperação

  Cenário: Reset manual do circuit breaker por administrador
    Dado que o circuit breaker para "openai" está no estado "OPEN"
    E o usuário possui permissões administrativas
    Quando o administrador executa reset manual
    Então o circuit breaker deve transitar para o estado "CLOSED"
    E o contador de falhas deve ser resetado
    E deve ser registrado log de auditoria com user_id do administrador

  Cenário: Circuit breakers independentes por provedor
    Dado que existem circuit breakers para:
      | provedor   | estado |
      | openai     | CLOSED |
      | anthropic  | CLOSED |
      | google     | CLOSED |
    Quando o provedor "anthropic" sofre 5 falhas consecutivas
    Então apenas o circuit breaker de "anthropic" deve transitar para OPEN
    E os circuit breakers de "openai" e "google" devem permanecer CLOSED

  @observability
  Cenário: Observabilidade de transições de estado
    Dado que o circuit breaker está operacional
    Quando ocorre transição de estado CLOSED → OPEN
    Então deve ser emitido log estruturado contendo:
      | campo             | tipo      |
      | timestamp         | ISO8601   |
      | estado_anterior   | string    |
      | novo_estado       | string    |
      | provedor          | string    |
      | contador_falhas   | integer   |
      | metadata          | object    |

  @edge-case
  Cenário: Falhas não consecutivas não acionam circuit breaker
    Dado que o circuit breaker para "openai" está no estado "CLOSED"
    E o failure_threshold é 5
    Quando ocorrem 3 falhas seguidas de 1 sucesso
    E então ocorrem mais 3 falhas
    Então o circuit breaker deve permanecer em estado "CLOSED"
    E o contador de falhas deve ter sido resetado após o sucesso

  @performance
  Cenário: Overhead de verificação de estado é mínimo
    Dado que o circuit breaker está no estado "CLOSED"
    E há alto volume de requisições (1000 req/s)
    Quando são feitas 1000 requisições consecutivas
    Então o overhead médio de verificação deve ser menor que 100 microssegundos
    E não deve haver contenção de threads

  @edge-case
  Cenário: Tipos de falha considerados para threshold
    Dado que o circuit breaker está no estado "CLOSED"
    Quando ocorrem as seguintes falhas:
      | tipo_falha         | contabiliza |
      | timeout            | sim         |
      | HTTP 500           | sim         |
      | HTTP 503           | sim         |
      | exceção de rede    | sim         |
      | HTTP 400           | não         |
      | HTTP 401           | não         |
      | HTTP 429           | não         |
    Então apenas 4 falhas devem ser contabilizadas
    E o circuit breaker deve permanecer CLOSED (threshold = 5)

  @configuration
  Cenário: Configuração diferenciada por provedor
    Dado que os provedores estão configurados com:
      | provedor   | failure_threshold | timeout_seconds |
      | openai     | 5                 | 60              |
      | anthropic  | 5                 | 60              |
      | google     | 5                 | 45              |
    Quando o provedor "google" entra em estado OPEN
    Então a tentativa de recuperação deve ocorrer após 45 segundos
    E não após 60 segundos

  @metrics
  Cenário: Métricas de uptime por provedor
    Dado que o circuit breaker registra métricas em tempo real
    E o provedor "openai" teve:
      | requisições_totais | 1000 |
      | requisições_bem_sucedidas | 980 |
    Quando consulto o status do circuit breaker
    Então os metadados devem incluir:
      | success_count       | 980   |
      | total_requests      | 1000  |
      | uptime_percentage   | 98.0  |

  @integration
  Cenário: Integração com cadeia de fallback
    Dado que o circuit breaker para "openai" está no estado "OPEN"
    E a cadeia de fallback está configurada:
      | ordem | provedor  |
      | 1     | openai    |
      | 2     | anthropic |
    Quando uma requisição LLM é iniciada
    Então o circuit breaker deve rejeitar tentativa para "openai"
    E a cadeia de fallback deve automaticamente tentar "anthropic"
    E a resposta deve incluir metadata:
      """
      {
        "fallback_activated": true,
        "fallback_reason": "circuit_breaker_open"
      }
      """

