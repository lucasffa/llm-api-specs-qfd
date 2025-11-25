# RC-014: Engenharia de Prompt Iterativa com Few-Shot e Restrições de Domínio

## Categoria
Qualidade

## Descrição

Implementação de sistema de engenharia de prompts iterativa que utiliza templates reutilizáveis, exemplos few-shot e restrições específicas do domínio educacional de línguas estrangeiras. O sistema deve permitir versionamento de prompts, validação estrutural e refinamento baseado em métricas de qualidade observadas em produção.

## Justificativa Técnica

A qualidade das respostas de LLMs é diretamente determinada pela estrutura e clareza dos prompts fornecidos. Como observado por Huyen (2023), prompt engineering não é atividade pontual, mas processo iterativo de refinamento que constitui engenharia de interface com modelos não-determinísticos. A abordagem iterativa fundamenta-se em três pilares:

1. **Few-shot learning**: Fornecimento de exemplos representativos do comportamento desejado, técnica documentada na literatura de LLMs como efetiva para guiar geração sem fine-tuning
2. **Restrições de domínio**: Delimitação explícita de escopo (níveis CEFR, faixa etária, objetivos pedagógicos) para prevenir respostas genéricas
3. **Versionamento e rastreabilidade**: Cada iteração de prompt deve ser rastreável a métricas de qualidade, alinhado ao princípio de Test-Driven Development aplicado a prompts (Beck, 2002; Freeman & Pryce, 2009)

Em contextos educacionais, a precisão pedagógica é crítica: prompts mal estruturados podem gerar conteúdo inadequado ao nível de proficiência do estudante, introduzir erros linguísticos ou desviar dos objetivos de aprendizagem. A engenharia iterativa permite refinamento contínuo baseado em feedback de educadores (human-in-the-loop, RC-012) e métricas comportamentais (RC-013).

A adoção de template engines (como Handlebars, Jinja2) oferece separação entre lógica de geração e conteúdo de prompt, favorecendo manutenibilidade e testabilidade conforme princípios de separação de responsabilidades.

## Validação QFD

**IAR (Índice de Adequação do Requisito): 2.91**

| Critério | Score | Peso | Justificativa |
|----------|-------|------|---------------|
| **Viabilidade Técnica** | 3 | ×3 | Template engines maduros (Handlebars, Jinja2) e práticas estabelecidas de prompt engineering. |
| **Testabilidade** | 3 | ×3 | Validadores estruturais (schema validation), métricas estatísticas (taxa de adequação) automatizáveis. |
| **Coesão de Domínio** | 3 | ×2 | Prompts são contrato primário de comunicação no bounded context "LLM Integration". |
| **Impacto na Solução** | 3 | ×2 | Qualidade de prompts determina diretamente experiência pedagógica do estudante. |
| **Complexidade de Implementação** | 2 | ×1 | Moderada: requer infraestrutura de templates, versionamento e pipeline de validação. |

**Classificação: 🟢 Fundamental (P0)**

## Critérios de Aceitação

### CA-01: Templates Reutilizáveis com Variáveis
**Dado** que existe um caso de uso pedagógico (ex: "geração de diálogo para prática de vocabulário")  
**Quando** o sistema constrói um prompt  
**Então** deve utilizar template parametrizado com variáveis injetáveis:
- `{{target_language}}` (idioma alvo)
- `{{proficiency_level}}` (nível CEFR: A1, A2, B1, B2, C1, C2)
- `{{topic}}` (tema específico)
- `{{constraints}}` (restrições adicionais)

### CA-02: Exemplos Few-Shot Estruturados
**Dado** que um template é renderizado  
**Quando** o prompt é construído  
**Então** deve incluir seção de exemplos few-shot com no mínimo 2 e no máximo 5 exemplos  
**E** cada exemplo deve seguir estrutura:
```
Entrada: [contexto específico]
Saída esperada: [resposta modelo]
```

### CA-03: Restrições Explícitas de Domínio
**Dado** que um prompt é construído para contexto educacional  
**Quando** o template é renderizado  
**Então** deve incluir seção de restrições explícitas:
- Nível de proficiência linguística (CEFR)
- Faixa etária apropriada
- Tópicos proibidos (conteúdo sensível)
- Comprimento esperado da resposta
- Formato de saída (JSON, texto livre, lista)

**Exemplo de restrição:**
```
Restrições obrigatórias:
- Nível: A2 (CEFR)
- Vocabulário: máximo 800 palavras conhecidas
- Estruturas gramaticais: presente simples, presente contínuo
- Evitar: gírias, expressões idiomáticas complexas
```

### CA-04: Versionamento de Prompts
**Dado** que um template de prompt existe  
**Quando** ele é modificado  
**Então** deve ser criada nova versão com:
- Identificador único (ex: `dialogue_generator_v2.3`)
- Timestamp de criação
- Changelog descrevendo alterações
- Referência à versão anterior
- Flag de status: `draft`, `testing`, `production`, `deprecated`

### CA-05: Validação Estrutural Pré-Envio
**Dado** que um prompt foi renderizado  
**Quando** antes de enviar para API de LLM  
**Então** deve executar validações:
- Tamanho total < 80% do context window do modelo
- Todas as variáveis obrigatórias foram substituídas (sem `{{placeholder}}` remanescentes)
- Seção de exemplos few-shot presente
- Restrições de domínio incluídas

### CA-06: Métricas de Qualidade de Prompt
**Dado** que um prompt foi utilizado em produção  
**Quando** resposta do LLM é gerada  
**Então** deve coletar métricas:
- Taxa de validação humana aprovada (% respostas aceitas)
- Latência média de geração
- Taxa de regeneração solicitada pelo usuário
- Custo médio (tokens consumidos)

## Especificação de Testabilidade (BDD/Gherkin)

Ver arquivo: `/tests/features/prompt-engineering.feature`

## Contrato de Interface (OpenAPI 3.1)

Ver arquivo: `/contracts/prompt-template-engine.yaml`

## Decisão de Design

### Padrão Arquitetural Escolhido
**Template Method Pattern** com separação entre template engine (infraestrutura) e prompt repository (domínio).

### Arquitetura de Componentes

```
┌─────────────────────────────────────┐
│   Prompt Template Repository        │
│   (Domínio - versionamento)         │
└─────────────┬───────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Template Engine Service           │
│   (Renderização + Validação)        │
└─────────────┬───────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   LLM Provider Abstraction           │
│   (RC-001 - Orquestração)            │
└─────────────────────────────────────┘
```

### Estrutura de Template (Exemplo)

```yaml
# dialogue_generator.yaml
id: "dialogue_generator"
version: "2.1"
status: "production"
description: "Gera diálogos contextualizados para prática de vocabulário"

variables:
  target_language: {type: string, required: true}
  proficiency_level: {type: enum, values: [A1, A2, B1, B2, C1, C2], required: true}
  topic: {type: string, required: true}
  num_turns: {type: integer, default: 4}

few_shot_examples:
  - input: "Idioma: Inglês, Nível: A2, Tópico: Restaurante"
    output: |
      Waiter: Good evening! Are you ready to order?
      Customer: Yes, I would like a salad, please.
      Waiter: Would you like something to drink?
      Customer: Water, please.
      
  - input: "Idioma: Espanhol, Nível: A2, Tópico: Direções"
    output: |
      Persona A: ¿Dónde está la biblioteca?
      Persona B: Está cerca de la plaza principal.

constraints:
  max_tokens: 300
  temperature: 0.7
  cefr_level: "{{proficiency_level}}"
  avoid_topics: ["política", "religião", "violência"]

prompt_template: |
  Você é um assistente pedagógico especializado em ensino de {{target_language}}.
  
  Tarefa: Gere um diálogo natural entre duas pessoas sobre o tema "{{topic}}".
  
  Restrições obrigatórias:
  - Nível CEFR: {{proficiency_level}}
  - Número de turnos: {{num_turns}}
  - Use apenas vocabulário e estruturas apropriadas para {{proficiency_level}}
  - O diálogo deve ser autêntico e útil para prática
  
  Exemplos de referência:
  {{#each few_shot_examples}}
  Exemplo {{@index}}:
  Entrada: {{this.input}}
  Saída:
  {{this.output}}
  
  {{/each}}
  
  Agora gere o diálogo para: {{topic}}
```

### Alternativas Consideradas

1. **Prompts hard-coded no código**
   - ❌ Rejeitado: Dificulta iteração e testes A/B
   - ❌ Viola princípio de separação de responsabilidades

2. **Fine-tuning de modelos próprios**
   - ❌ Rejeitado para MVP: Custo computacional alto (87 de 107 estudos não-replicáveis exigiam fine-tuning, Yan et al., 2024)
   - ❌ Reduz flexibilidade de troca de provedores

3. **Prompts gerados dinamicamente por LLM (meta-prompting)**
   - ⚠️ Interessante para experimentação futura
   - ❌ Adiciona latência e custo
   - ❌ Reduz determinismo e rastreabilidade

### Trade-offs Explícitos

| Aspecto | Benefício | Custo |
|---------|-----------|-------|
| **Manutenibilidade** | ✅ Separação clara entre lógica e conteúdo | ❌ Requer infraestrutura adicional (template engine) |
| **Qualidade** | ✅ Iteração rápida com métricas de produção | ⚠️ Requer disciplina de versionamento |
| **Testabilidade** | ✅ Validação estrutural automatizada | ❌ Validação semântica ainda requer humanos (RC-012) |
| **Determinismo** | ✅ Templates fixos para casos de uso específicos | ⚠️ LLMs permanecem não-determinísticos (temperature > 0) |

### Estratégia de Refinamento Iterativo

1. **Baseline (v1.0)**: Prompt genérico com restrições básicas
2. **Coleta de métricas**: Taxa de aprovação humana, regenerações solicitadas
3. **Análise de falhas**: Categorização de respostas inadequadas
4. **Refinamento (v1.1)**: Adição de exemplos few-shot ou restrições mais explícitas
5. **A/B testing**: Comparação v1.0 vs v1.1 em produção (10% tráfego)
6. **Promoção**: Versão com melhor desempenho torna-se `production`

## Referências

- BECK, K. Test-Driven Development: By Example. Addison-Wesley, 2002.
- FREEMAN, S.; PRYCE, N. Growing Object-Oriented Software, Guided by Tests. Addison-Wesley, 2009.
- HUYEN, C. Building LLM Applications for Production. 2023. Disponível em: https://huyenchip.com/2023/04/11/llm-engineering.html
- YAN, L. et al. Practical and Ethical Challenges of Large Language Models in Education. British Journal of Educational Technology, v. 55, n. 1, p. 90-112, 2024.
- OPENAI. Prompt Engineering Guide. 2025.
- ANTHROPIC. Prompt Engineering for Claude. 2025.

---

**Versão:** 1.0  
**Data:** Novembro 2025  
**Status:** Especificação Validada (QFD)

