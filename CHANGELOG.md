# Changelog

## [2.1.0] - 2025-12-19

### ✨ New Features
- **Relatórios Auditáveis**: Adicionada funcionalidade de clique nos cartões de "Saldo Total" e "Fluxo de Caixa" na tela de finanças.
  - **Fluxo de Caixa**: Gera PDF contendo apenas as transações realizadas que compõem o saldo do período.
  - **Saldo Total**: Gera PDF contendo o histórico de transações realizadas E parcelas futuras a vencer, oferecendo uma visão completa da saúde financeira.
  - **Novo Layout de PDF**: Relatórios financeiros agora utilizam um layout de 4 colunas (Data, Título, Receita, Despesa) com totais claros no rodapé.

- **Business Intelligence (BI) Financeiro**:
  - Aprimorada a capacidade da IA de responder perguntas financeiras complexas (ex: "Quanto gastei este mês?", "Tenho contas a vencer?").
  - O prompt do sistema agora recebe um resumo financeiro contextualizado (saldos, totais por categoria) para gerar respostas precisas.

### 🐛 Bug Fixes
- **Duplicação de Valores na Descrição**: Corrigido problema onde valores monetários apareciam no título da transação (ex: "Compra 50.00"). Implementada estratégia de limpeza cirúrgica e priorização da extração local sobre a IA.
- **Títulos de Relatórios**: Corrigida a falta de personalização nos títulos dos PDFs gerados.

### 🔧 Improvements
- **Refatoração PdfService**: Métodos de geração de PDF agora aceitam `titleOverride` ou parâmetros de título explícitos.
- **Internacionalização**: Todos os novos textos e títulos de relatórios estão preparados para internacionalização (embora strings padrão tenham sido usadas temporariamente nos títulos dos relatórios clicáveis).
