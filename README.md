# LLM Integration Specs - Abordagem Baseada em QFD

Este repositório contém os artefatos resultantes do estudo **"Elicitação e validação de requisitos para integração com APIs de Large Language Models em sistemas de aprendizado de línguas estrangeiras: uma abordagem baseada em QFD"**.

**Trabalho de Conclusão de Curso**  
Bacharelado em Sistemas de Informação  
Universidade Vale do Rio Doce (UNIVALE)  
2025

---

## 📄 Resumo

A integração de Large Language Models (LLMs) em sistemas educacionais amplia as possibilidades de aprendizado, mas a ausência de especificações validadas gera riscos técnicos e arquiteturais. Este projeto apresenta uma especificação sistemática de requisitos para integração com APIs de LLM (OpenAI, Anthropic, Google), validada através de uma adaptação do método *Quality Function Deployment* (QFD).

## 🎯 Objetivos

- Elicitar requisitos candidatos para integração com LLM APIs em contextos educacionais
- Validar e priorizar requisitos utilizando critérios de Engenharia de Software (Viabilidade, Testabilidade, Coesão de Domínio, Impacto, Complexidade)
- Fornecer artefatos prontos para implementação: Especificações técnicas, Critérios de Aceitação (Gherkin/BDD) e Contratos de Interface (OpenAPI 3.1)

## 🏆 Requisitos Fundamentais Validados

A partir de 22 requisitos candidatos, 4 foram classificados como **Fundamentais** (IAR ≥ 2.5):

| ID | Requisito | Categoria | IAR |
|----|-----------|-----------|-----|
| **RC-003** | Padrão *Circuit Breaker* para proteção contra falhas em cascata | Resiliência | 2.91 |
| **RC-004** | Cadeia de *Fallback* em múltiplas camadas | Resiliência | 2.91 |
| **RC-014** | Engenharia de Prompt Iterativa (*Few-shot* + restrições de domínio) | Qualidade | 2.91 |
| **RC-016** | Filtros de moderação de conteúdo (alucinações, conteúdo inadequado) | Segurança | 2.91 |

## 🛠 Metodologia

O estudo utilizou abordagem híbrida combinando:

- **Revisão Bibliográfica e Documental:** Análise de literatura científica, *whitepapers* e documentação oficial de APIs (2018-2025)
- **QFD Adaptado:** Validação através do cálculo do Índice de Adequação do Requisito (IAR)
- **Domain-Driven Design (DDD):** Definição do *Bounded Context* "LLM Integration"
- **Test-Driven Development (TDD/BDD):** Especificação orientada a testes com critérios de aceitação em Gherkin

## 📁 Estrutura do Repositório

```
llm-api-specs-qfd/
├── README.md                          # Este arquivo
├── docs/
│   ├── tcc-full-paper.txt            # Artigo completo (TCC - texto)
│   ├── appendix-a.md                 # Apêndice A: Requisitos Candidatos
│   └── appendix-b.md                 # Apêndice B: Matriz QFD
├── specs/
│   └── fundamentals/                 # Especificações dos 4 requisitos fundamentais
│       ├── RC-003-circuit-breaker.md
│       ├── RC-004-fallback-chain.md
│       ├── RC-014-prompt-engineering.md
│       └── RC-016-content-moderation.md
├── contracts/                        # Contratos OpenAPI 3.1
│   ├── circuit-breaker-service.yaml
│   ├── fallback-orchestrator.yaml
│   ├── prompt-template-engine.yaml
│   └── content-moderation-service.yaml
└── tests/
    └── features/                     # Cenários BDD (Gherkin)
        ├── circuit-breaker.feature
        ├── fallback-chain.feature
        ├── prompt-engineering.feature
        └── content-moderation.feature
```

## 📦 Artefatos Fornecidos

### Especificações Técnicas (`/specs`)
Cada requisito fundamental possui especificação completa contendo:
- Descrição e escopo
- Justificativa técnica com referências bibliográficas
- Critérios de aceitação
- Cenários de teste em formato Gherkin
- Referência ao contrato OpenAPI
- Decisões de design e *trade-offs*

### Contratos de Interface (`/contracts`)
Especificações OpenAPI 3.1 definindo:
- Endpoints e operações
- Esquemas de requisição/resposta
- Códigos de status HTTP
- Modelos de dados

### Testes BDD (`/tests/features`)
Cenários executáveis em formato Gherkin (Given-When-Then) alinhados aos critérios de aceitação.

## 👥 Autores

**Lucas Fernandes Ferreira de Almeida**  
Discente do Curso de Bacharelado em Sistemas de Informação  
Universidade Vale do Rio Doce (UNIVALE)  
lucas.almeida1@univale.br

**Herbert da Silva Costa**  
Professor Orientador  
Universidade Vale do Rio Doce (UNIVALE)  
herbert.costa@univale.br

---

## 📖 Citação

```bibtex
@mastersthesis{almeida2025llm,
  author  = {Almeida, Lucas Fernandes Ferreira de},
  title   = {Elicitação e validação de requisitos para integração com APIs
             de Large Language Models em sistemas de aprendizado de línguas
             estrangeiras: uma abordagem baseada em QFD},
  school  = {Universidade Vale do Rio Doce (UNIVALE)},
  year    = {2025},
  address = {Gov. Valadares, MG, Brasil},
  type    = {Trabalho de Conclusão de Curso}
}
```

## 📄 Licença

Este trabalho está licenciado sob [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).

**Você é livre para:**
- ✅ Compartilhar — copiar e redistribuir o material em qualquer meio ou formato
- ✅ Adaptar — remixar, transformar e criar a partir do material para qualquer finalidade, mesmo comercial

**Sob as seguintes condições:**
- 📖 **Atribuição (obrigatória)** — Você deve dar o crédito apropriado, fornecer um link para a licença e indicar se mudanças foram feitas. Você pode fazê-lo de qualquer forma razoável, mas não de maneira que sugira que o licenciante endossa você ou seu uso.

Para detalhes completos, consulte o arquivo [LICENSE](LICENSE) ou acesse https://creativecommons.org/licenses/by/4.0/legalcode.pt

---

*Para acessar o artigo completo, consulte [`/docs/tcc-full-paper.pdf`](docs/tcc-full-paper.pdf)*  
*Para os apêndices detalhados, consulte [`Apêndice A`](docs/appendix-a.md) e [`Apêndice B`](docs/appendix-b.md)*