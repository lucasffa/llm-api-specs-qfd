# RC-016: Filtros de Moderação de Conteúdo para Segurança

## Categoria
Segurança

## Descrição

Implementação de pipeline de moderação de conteúdo em múltiplas camadas para detecção e filtragem de: (1) alucinações factuais em respostas de LLM, (2) conteúdo inadequado para contexto educacional (violência, conteúdo sexual, discurso de ódio), (3) vulnerabilidades de prompt injection, e (4) respostas fora do escopo pedagógico. O sistema deve operar tanto em entradas (prompts do usuário) quanto em saídas (respostas do LLM).

## Justificativa Técnica

A OWASP classificou prompt injection como vulnerabilidade #1 no Top 10 for LLM Applications 2025, com estudos demonstrando taxa de sucesso de 56% em ataques contra 36 LLMs testados (Benjamin et al., 2024). O UK National Cyber Security Centre declarou que prompt injection pode ser questão inerente à tecnologia LLM para a qual ainda não há mitigações completamente seguras. Em contextos educacionais, os riscos são amplificados:

1. **Proteção de menores**: Estudantes podem ser expostos a conteúdo inadequado gerado por LLMs
2. **Integridade pedagógica**: Alucinações não detectadas podem ensinar informações incorretas
3. **Conformidade regulatória**: LGPD, COPPA e regulamentações educacionais exigem proteção de dados de menores

A literatura sobre alucinações em LLMs (Ji et al., 2023; Sahoo et al., 2024 apud Yan et al., 2024b) documenta que a falta de transparência nos processos decisórios dificulta identificação de quando e por que alucinações ocorrem. Como observado por Yan et al. (2024b), o caráter não-determinístico introduz imprecisões potenciais quando se depende exclusivamente de IA generativa sem validação adequada.

A abordagem de defesa em profundidade (defense-in-depth) com múltiplas camadas de validação é recomendada pela literatura de segurança para sistemas críticos:
- **Camada 1**: Validação de entrada (input sanitization)
- **Camada 2**: Moderação via APIs especializadas (OpenAI Moderation, Perspective API)
- **Camada 3**: Validação semântica de saída (fact-checking heurístico)
- **Camada 4**: Human-in-the-loop review (RC-012) para casos ambíguos

## Validação QFD

**IAR (Índice de Adequação do Requisito): 2.91**

| Critério | Score | Peso | Justificativa |
|----------|-------|------|---------------|
| **Viabilidade Técnica** | 3 | ×3 | APIs de moderação maduras (OpenAI Moderation, Perspective API) e técnicas estabelecidas de validação. |
| **Testabilidade** | 3 | ×3 | Casos de teste com conteúdo inadequado conhecido, métricas de precisão/recall automatizáveis. |
| **Coesão de Domínio** | 3 | ×2 | Segurança é responsabilidade transversal crítica do bounded context "LLM Integration". |
| **Impacto na Solução** | 3 | ×2 | Essencial para conformidade regulatória e proteção de estudantes em ambiente educacional. |
| **Complexidade de Implementação** | 2 | ×1 | Moderada: integração com APIs externas, gestão de falsos positivos e latência adicional. |

**Classificação: 🟢 Fundamental (P0)**

## Critérios de Aceitação

### CA-01: Validação de Entrada (Input Sanitization)
**Dado** que um usuário submete prompt ou texto de entrada  
**Quando** antes de enviar para API de LLM  
**Então** deve executar validações:
- Detecção de tentativas de prompt injection (palavras-chave: "ignore previous instructions", "system:", "jailbreak")
- Limitação de comprimento (max 4000 caracteres para A1-A2, 8000 para B1-C2)
- Remoção de caracteres de controle e encoding maliciosos
- Detecção de padrões de script injection (`<script>`, SQL keywords)

**E** se detectada violação, deve:
- Rejeitar entrada com código de erro `400 Bad Request`
- Retornar mensagem amigável: "Sua entrada contém padrões não permitidos"
- Logar incidente para auditoria (sem armazenar conteúdo sensível)

### CA-02: Moderação de Conteúdo via API Especializada
**Dado** que texto de entrada passou validação inicial  
**Quando** antes de processar com LLM principal  
**Então** deve enviar para API de moderação (OpenAI Moderation ou equivalente)  
**E** deve analisar scores para categorias:
- `hate`: discurso de ódio (threshold: 0.3)
- `hate/threatening`: ameaças (threshold: 0.2)
- `self-harm`: automutilação (threshold: 0.1)
- `sexual`: conteúdo sexual (threshold: 0.4 para menores, 0.7 para adultos)
- `sexual/minors`: conteúdo envolvendo menores (threshold: 0.0 - bloqueio total)
- `violence`: violência (threshold: 0.5)
- `violence/graphic`: violência gráfica (threshold: 0.3)

**E** se qualquer categoria exceder threshold:
- Bloquear processamento
- Retornar erro `451 Unavailable For Legal Reasons`
- Notificar moderadores humanos para casos acima de score 0.8

### CA-03: Validação Semântica de Saída
**Dado** que LLM gerou resposta  
**Quando** antes de retornar ao usuário  
**Então** deve executar validações heurísticas:
- **Detecção de alucinação**: Verificar se resposta contém afirmações factuais implausíveis (ex: datas anacrónicas, fatos científicos obviamente falsos)
- **Alinhamento de escopo**: Resposta está dentro do domínio pedagógico (não contém código, SQL, comandos de sistema)
- **Consistência com prompt**: Resposta aborda efetivamente a solicitação original
- **Adequação ao nível**: Vocabulário e estruturas compatíveis com CEFR declarado

**E** deve calcular confidence score agregado (0-1)  
**E** se confidence < 0.6, deve marcar para revisão humana (RC-012)

### CA-04: Filtragem de Respostas Inadequadas
**Dado** que resposta do LLM foi gerada  
**Quando** validação detecta conteúdo inadequado  
**Então** deve:
- Bloquear resposta completa (não retornar parcialmente)
- Retornar mensagem padrão: "Não foi possível gerar resposta adequada. Por favor, reformule sua solicitação."
- Logar incidente com hash da resposta (não texto completo por privacidade)
- Acionar fallback para tentativa com prompt mais restritivo (RC-004)

### CA-05: Auditoria e Rastreabilidade
**Dado** que conteúdo foi bloqueado ou marcado  
**Quando** incidente ocorre  
**Então** deve registrar log estruturado contendo:
- Timestamp ISO8601
- User ID (pseudonimizado)
- Session ID
- Categoria de violação detectada
- Camada de detecção (entrada/saída, API de moderação/validação heurística)
- Severity level (LOW, MEDIUM, HIGH, CRITICAL)
- Hash SHA-256 do conteúdo (para deduplicação sem armazenar texto)

**E** não deve armazenar conteúdo sensível em logs (compliance LGPD/GDPR)

### CA-06: Métricas de Efetividade de Moderação
**Dado** que sistema está em produção  
**Quando** moderação é executada  
**Então** deve coletar métricas:
- Taxa de bloqueio por categoria
- Latência adicional introduzida por moderação (target: < 500ms)
- Taxa de falsos positivos (conteúdo legítimo bloqueado)
- Taxa de escalação para revisão humana
- Cobertura de moderação (% requisições moderadas vs. total)

## Especificação de Testabilidade (BDD/Gherkin)

Ver arquivo: `/tests/features/content-moderation.feature`

## Contrato de Interface (OpenAPI 3.1)

Ver arquivo: `/contracts/content-moderation-service.yaml`

## Decisão de Design

### Padrão Arquitetural Escolhido
**Pipeline de Validação em Camadas (Layered Validation Pipeline)** com estratégia fail-fast.

### Arquitetura do Pipeline

```
┌─────────────────────────────────────────────────┐
│ Camada 1: Input Sanitization                   │
│ (Regex patterns, length limits)                │
│ Latência: ~5ms                                  │
└────────────┬────────────────────────────────────┘
             ↓ (passa)
┌─────────────────────────────────────────────────┐
│ Camada 2: API de Moderação Externa             │
│ (OpenAI Moderation / Perspective API)          │
│ Latência: ~200-400ms                            │
└────────────┬────────────────────────────────────┘
             ↓ (passa)
┌─────────────────────────────────────────────────┐
│ Geração LLM (Provedor Principal)               │
└────────────┬────────────────────────────────────┘
             ↓
┌─────────────────────────────────────────────────┐
│ Camada 3: Validação Semântica de Saída         │
│ (Heurísticas de alucinação, scope check)       │
│ Latência: ~50ms                                 │
└────────────┬────────────────────────────────────┘
             ↓ (confidence >= 0.6)
┌─────────────────────────────────────────────────┐
│ Retorno ao Usuário                              │
└─────────────────────────────────────────────────┘

         (confidence < 0.6) → Human Review Queue
```

### Estratégia de Thresholds por Faixa Etária

```yaml
age_groups:
  children:  # 6-12 anos
    age_range: [6, 12]
    moderation_thresholds:
      sexual: 0.1          # Muito restritivo
      violence: 0.3
      hate: 0.2
      self_harm: 0.0       # Bloqueio total
      
  teenagers:  # 13-17 anos
    age_range: [13, 17]
    moderation_thresholds:
      sexual: 0.4
      violence: 0.5
      hate: 0.3
      self_harm: 0.1
      
  adults:  # 18+ anos
    age_range: [18, 120]
    moderation_thresholds:
      sexual: 0.7          # Mais permissivo
      violence: 0.6
      hate: 0.4
      self_harm: 0.2
```

### Alternativas Consideradas

1. **Moderação apenas na saída**
   - ❌ Rejeitado: Desperdiça custo de geração em entradas maliciosas
   - ❌ Permite ataques de prompt injection alcançarem o modelo

2. **Moderação totalmente baseada em LLM (LLM-as-judge para segurança)**
   - ⚠️ Interessante mas não suficiente isoladamente
   - ❌ LLMs podem ser manipulados por prompt injection
   - ❌ Aumenta latência (requisição adicional)
   - ✅ Pode ser usado como camada complementar

3. **Blacklist de palavras simples**
   - ❌ Rejeitado: Alta taxa de falsos positivos
   - ❌ Facilmente contornável por variações ortográficas

4. **Moderação assíncrona pós-entrega**
   - ❌ Rejeitado: Estudante já foi exposto a conteúdo inadequado
   - ⚠️ Pode ser usada para auditoria retrospectiva complementar

### Trade-offs Explícitos

| Aspecto | Benefício | Custo |
|---------|-----------|-------|
| **Segurança** | ✅ Proteção em múltiplas camadas reduz riscos | ❌ Latência adicional (~250-500ms total) |
| **Conformidade** | ✅ Auditoria rastreável para regulamentações | ❌ Infraestrutura de logging estruturado |
| **Falsos Positivos** | ⚠️ Thresholds conservadores para menores | ❌ Conteúdo legítimo pode ser bloqueado |
| **Custo** | ❌ Chamadas adicionais a APIs de moderação | ✅ Evita desperdício em conteúdo rejeitado |

### Estratégia de Mitigação de Falsos Positivos

1. **Feedback loop**: Usuários podem reportar bloqueios incorretos
2. **Revisão periódica**: Análise quinzenal de logs de bloqueio
3. **Ajuste de thresholds**: Calibração baseada em métricas de produção
4. **Whitelist de contextos**: Termos técnicos educacionais (anatomia, história) não devem ser bloqueados

### Integração com Human-in-the-Loop (RC-012)

Casos que devem ser escalados para revisão humana:
- Confidence score < 0.6 (ambiguidade)
- Score de moderação entre threshold e threshold + 0.2 (zona cinzenta)
- Primeiro bloqueio de um novo padrão de ataque (aprendizado)
- Feedback negativo de usuário sobre bloqueio incorreto

## Referências

- OWASP. Top 10 for Large Language Model Applications. Version 2025. Disponível em: https://genai.owasp.org/llm-top-10/
- BENJAMIN, V. et al. Systematically Analyzing Prompt Injection Vulnerabilities in Diverse LLM Architectures. arXiv:2410.23308, 2024.
- YAN, L. et al. Practical and Ethical Challenges of Large Language Models in Education. British Journal of Educational Technology, v. 55, n. 1, 2024.
- JI, Z. et al. Survey of Hallucination in Natural Language Generation. ACM Computing Surveys, 2023.
- UK NATIONAL CYBER SECURITY CENTRE. Prompt Injection Attacks on Large Language Models. 2024.
- OPENAI. Moderation API Documentation. 2025.
- GOOGLE. Perspective API Documentation. 2025.

---

**Versão:** 1.0  
**Data:** Novembro 2025  
**Status:** Especificação Validada (QFD)

