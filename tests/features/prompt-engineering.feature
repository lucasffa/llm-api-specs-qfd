# language: pt
Funcionalidade: Engenharia de Prompt Iterativa com Few-Shot e Restrições
  Como desenvolvedor pedagógico
  Quero gerenciar templates de prompts versionados com exemplos few-shot
  Para garantir qualidade e consistência das gerações de LLM

  Contexto:
    Dado que o serviço de Prompt Template Engine está operacional
    E existe um template "dialogue_generator" versão "2.1" com status "production"

  @smoke @critical
  Cenário: Renderização de template com substituição de variáveis
    Dado que o template "dialogue_generator" possui variáveis:
      | variável          | tipo   | obrigatória |
      | target_language   | string | sim         |
      | proficiency_level | enum   | sim         |
      | topic             | string | sim         |
      | num_turns         | integer| não         |
    Quando renderizo o template com valores:
      """
      {
        "target_language": "Inglês",
        "proficiency_level": "A2",
        "topic": "Compras no supermercado",
        "num_turns": 4
      }
      """
    Então o prompt renderizado deve conter:
      | texto esperado                          |
      | ensino de Inglês                        |
      | Nível CEFR: A2                          |
      | Compras no supermercado                 |
      | Número de turnos: 4                     |
    E não deve conter placeholders não substituídos como "{{variable}}"
    E o campo "validation_result.valid" deve ser true

  @critical
  Cenário: Validação de variáveis obrigatórias faltantes
    Dado que o template "dialogue_generator" requer "proficiency_level"
    Quando tento renderizar sem fornecer "proficiency_level":
      """
      {
        "target_language": "Inglês",
        "topic": "Restaurante"
      }
      """
    Então a renderização deve falhar com erro 400
    E a mensagem deve incluir "Variável obrigatória 'proficiency_level' não fornecida"
    E o campo "details.missing_variables" deve listar: ["proficiency_level"]

  @critical
  Cenário: Template inclui exemplos few-shot estruturados
    Dado que o template "dialogue_generator" tem 2 exemplos few-shot
    Quando o template é renderizado
    Então o prompt deve incluir seção "Exemplos de referência:"
    E deve conter no mínimo 2 exemplos
    E cada exemplo deve seguir estrutura:
      """
      Exemplo N:
      Entrada: <contexto>
      Saída:
      <resposta modelo>
      """

  @critical
  Cenário: Restrições explícitas de domínio pedagógico
    Dado que renderizo template para nível "A2"
    Quando o prompt é construído
    Então deve incluir seção "Restrições obrigatórias:" contendo:
      | restrição                                  |
      | Nível CEFR: A2                             |
      | Use apenas vocabulário apropriado para A2  |
      | Evitar gírias e expressões idiomáticas     |
    E deve especificar tópicos proibidos:
      | tópico    |
      | política  |
      | religião  |
      | violência |

  @versioning
  Cenário: Criação de nova versão preserva histórico
    Dado que existe template "dialogue_generator" versão "2.1" em produção
    Quando um pedagogo atualiza o template adicionando 2 novos exemplos few-shot
    E fornece changelog: "Adicionados exemplos para prática de vocabulário de transporte"
    Então uma nova versão "2.2" deve ser criada com status "draft"
    E a versão "2.1" deve permanecer em "production"
    E o changelog da versão "2.2" deve registrar:
      | campo     | valor                                              |
      | version   | 2.2                                                |
      | author    | <user_id>                                          |
      | changes   | Adicionados exemplos para prática de vocabulário... |
      | timestamp | <ISO8601>                                          |

  @validation
  Cenário: Validação estrutural pré-envio detecta problemas
    Dado que um prompt foi renderizado com 8000 caracteres
    E o modelo alvo "gpt-4o-mini" tem context window de 128k tokens
    Quando a validação estrutural é executada
    Então deve verificar:
      | validação                           | resultado |
      | Tamanho < 80% do context window     | pass      |
      | Variáveis substituídas              | pass      |
      | Seção few-shot presente             | pass      |
      | Restrições de domínio incluídas     | pass      |
    E o campo "estimated_tokens" deve ser calculado (~2400 tokens)
    E o campo "context_window_usage_percent" deve ser ~1.9%

  @validation
  Cenário: Validação falha quando prompt excede context window
    Dado que um prompt renderizado tem 400k caracteres
    E o modelo alvo "gpt-4o-mini" tem context window de 128k tokens (~512k chars)
    Quando a validação é executada
    Então deve retornar erro de validação:
      """
      {
        "valid": false,
        "errors": [{
          "code": "EXCEEDS_CONTEXT_WINDOW",
          "message": "Prompt excede 80% do context window permitido",
          "severity": "error"
        }]
      }
      """

  @metrics
  Cenário: Coleta de métricas de qualidade de prompt em produção
    Dado que o template "dialogue_generator" v2.1 foi usado 100 vezes
    E dessas:
      | resultado                        | quantidade |
      | aprovadas por validação humana   | 87         |
      | regeneração solicitada           | 8          |
      | bloqueadas por moderação         | 5          |
    Quando consulto as métricas do template
    Então deve retornar:
      | métrica                      | valor |
      | taxa_aprovacao_humana        | 87%   |
      | taxa_regeneracao             | 8%    |
      | latencia_media_geracao_ms    | 1420  |
      | custo_medio_tokens           | 142   |
      | custo_medio_usd              | 0.00021 |

  @edge-case
  Cenário: Variável com valor padrão é aplicada quando não fornecida
    Dado que o template tem variável "num_turns" com default = 4
    Quando renderizo sem fornecer "num_turns"
    Então o prompt deve usar valor padrão: "Número de turnos: 4"

  @configuration
  Cenário: Promoção de template de testing para production
    Dado que existe template "dialogue_generator" v2.2 em status "testing"
    E testes A/B mostraram taxa de aprovação 12% maior que v2.1
    Quando um administrador promove v2.2 para "production"
    Então o status de v2.2 deve mudar para "production"
    E v2.1 deve ser movida para "deprecated"
    E novas requisições devem usar v2.2 por padrão

  @integration
  Cenário: Template renderizado integra com geração LLM
    Dado que renderizei template "dialogue_generator" com sucesso
    Quando envio o prompt renderizado para API de geração (RC-004)
    Então o sistema deve:
      | ação                                    |
      | Passar por moderação de entrada (RC-016) |
      | Executar geração com fallback (RC-004)   |
      | Moderar saída (RC-016)                  |
      | Retornar resposta aprovada              |

  @few-shot
  Cenário: Adição de exemplos few-shot melhora qualidade
    Dado que template v1.0 tem 0 exemplos few-shot
    E template v2.0 tem 3 exemplos few-shot
    Quando comparo métricas de qualidade:
      | versão | taxa_aprovacao | custo_medio |
      | v1.0   | 72%            | 0.00018     |
      | v2.0   | 87%            | 0.00021     |
    Então v2.0 deve mostrar melhoria de 15 pontos percentuais
    E o custo adicional de 16% é justificado pela qualidade

  @edge-case
  Cenário: Validação de tipo de variável enum
    Dado que variável "proficiency_level" aceita apenas: [A1, A2, B1, B2, C1, C2]
    Quando tento renderizar com valor inválido "Intermediário"
    Então deve retornar erro de validação:
      """
      {
        "error": "INVALID_ENUM_VALUE",
        "message": "Valor 'Intermediário' não permitido para 'proficiency_level'",
        "details": {
          "allowed_values": ["A1", "A2", "B1", "B2", "C1", "C2"]
        }
      }
      """

  @observability
  Cenário: Rastreabilidade de template usado na resposta
    Quando uma resposta LLM é gerada usando template
    Então os metadados devem incluir:
      | campo               | exemplo              |
      | template_id         | dialogue_generator   |
      | template_version    | 2.1                  |
      | character_count     | 487                  |
      | estimated_tokens    | 142                  |
    E deve ser possível auditar qual versão gerou qual resposta

  Cenário: Templates por categoria pedagógica
    Dado que existem templates para categorias:
      | categoria              | quantidade |
      | dialogue               | 5          |
      | vocabulary             | 8          |
      | grammar                | 6          |
      | reading_comprehension  | 4          |
      | writing_assistance     | 3          |
    Quando consulto templates por categoria "vocabulary"
    Então deve retornar 8 templates
    E todos devem ter category = "vocabulary"

  @performance
  Cenário: Renderização de template é eficiente
    Dado que um template tem 5 variáveis e 4 exemplos few-shot
    Quando renderizo 1000 vezes consecutivas
    Então a latência média deve ser menor que 10ms por renderização
    E não deve haver memory leaks
    E o overhead deve ser desprezível comparado à geração LLM

  @security
  Cenário: Template não permite injeção de código
    Dado que tento criar template com conteúdo malicioso:
      """
      {
        "prompt_template": "{{user_input}} <script>alert('xss')</script>"
      }
      """
    Quando o template é validado
    Então deve rejeitar com erro de segurança
    E não deve permitir tags HTML ou JavaScript
    E deve sanitizar entradas antes de armazenar

  @iterative-refinement
  Cenário: Ciclo de refinamento iterativo baseado em feedback
    Dado que template v1.0 tem taxa de aprovação de 75%
    Quando analiso falhas comuns:
      | tipo_falha               | ocorrências |
      | vocabulário muito avançado | 12          |
      | estrutura complexa       | 8           |
    Então crio v1.1 com restrições adicionais:
      """
      - Limitar a 500 palavras mais comuns do inglês
      - Usar apenas present simple e present continuous
      """
    E após deploy, a taxa de aprovação aumenta para 88%
    E v1.1 é promovida para production

