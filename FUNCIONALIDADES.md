# FinAgeVoz - Documentação Completa de Funcionalidades

## 📱 Visão Geral

**FinAgeVoz** é um aplicativo Flutter multiplataforma que combina **gestão financeira** e **agenda de eventos** com controle por **comandos de voz** e **inteligência artificial**. O app utiliza a API Groq (com modelo Llama) para processar comandos em linguagem natural e oferece suporte a 14 idiomas.

---

## 🎯 Funcionalidades Principais

### 1. 🎤 **Controle por Voz**

#### Reconhecimento de Voz
- **Palavra de ativação personalizável**: Configure uma palavra-chave para ativar o assistente
- **Suporte multilíngue**: Reconhecimento de voz em 14 idiomas
- **Feedback visual**: Animação de avatar pulsante durante a escuta
- **Confirmação por "OK"**: Comando especial para interromper a escuta

#### Síntese de Voz (Text-to-Speech)
- **Respostas faladas**: O app responde verbalmente aos comandos
- **Velocidade e tom ajustáveis**: Configuração de pitch e velocidade
- **Volume máximo**: Garantia de audibilidade
- **Aguarda conclusão**: Sincronização entre fala e ações

#### Comandos de Voz Suportados

**Transações Financeiras:**
```
"Comprei [item] de [valor] reais"
"Gastei [valor] em [categoria]"
"Recebi [valor] de [descrição]"
"Comprei [item] de [valor] em [N] vezes"
"Comprei [item] total de [valor] em [N] vezes"
```

**Eventos:**
```
"Criar evento [nome] amanhã às [hora]"
"Agendar [evento] dia [data] às [hora]"
"Marcar [evento] para [data]"
```

**Consultas:**
```
"Quanto gastei este mês?"
"Qual meu saldo?"
"Quanto gastei em [categoria]?"
"Quais eventos tenho hoje?"
```

---

### 2. 💰 **Gestão Financeira**

#### Transações
- **Entrada manual**: Diálogo para adicionar transações manualmente
- **Entrada por voz**: Criação de transações via comandos de voz
- **Tipos**: Receitas (income) e Despesas (expense)
- **Campos**:
  - Descrição
  - Valor (com sinal algébrico: positivo para receitas, negativo para despesas)
  - Data
  - Categoria e subcategoria
  - Notas adicionais
  - Anexos (imagens, documentos)

#### Parcelamento Inteligente
- **Compras parceladas**: Suporte a transações divididas em múltiplas parcelas
- **Lógica corrigida**: 
  - "100 reais em 10 vezes" = 10 parcelas de R$100 (total R$1.000)
  - "Total de 1000 reais em 10 vezes" = 10 parcelas de R$100
- **Identificação**: Todas as parcelas compartilham um `installmentId`
- **Gestão em série**: Deletar/editar todas as parcelas de uma vez
- **Relatório dedicado**: Tela específica para visualizar parcelamentos

#### Categorias e Subcategorias
- **Categorias padrão**:
  - **Despesas**: Alimentação, Transporte, Saúde, Educação, Lazer, Moradia, Vestuário, Outros, Imobilizado
  - **Receitas**: Salário, Freelance, Investimentos, Outros, Imobilizado
- **Subcategorias**: Cada categoria possui subcategorias específicas
- **Categorias personalizadas**: Criar, editar e deletar categorias próprias
- **Proteção**: Não permite deletar categorias em uso
- **Reset**: Restaurar categorias padrão
- **Tradução automática**: Categorias traduzidas para todos os idiomas

#### Filtros e Visualização
- **Filtros por período**:
  - Hoje
  - Esta semana
  - Este mês
  - Todos
  - Data personalizada
- **Filtros por tipo**: Todas, Receitas, Despesas
- **Ordenação**:
  - Por data
  - Por valor
  - Por tipo
  - Por descrição
- **Busca**: Campo de pesquisa por descrição
- **Modo de seleção**: Seleção múltipla para ações em lote

#### Saldo e Resumos
- **Saldo atual**: Cálculo automático (receitas - despesas)
- **Total de receitas**: Soma de todas as entradas
- **Total de despesas**: Soma de todas as saídas
- **Atualização em tempo real**: Recalcula ao adicionar/remover transações

---

### 3. 📅 **Agenda de Eventos**

#### Criação de Eventos
- **Entrada manual**: Diálogo completo para criar eventos
- **Entrada por voz**: Criação via comandos de voz com IA
- **Campos**:
  - Nome do evento
  - Data e hora
  - Descrição
  - Recorrência (Nenhuma, Diária, Semanal, Mensal, Anual)
  - Anexos (imagens, documentos)

#### Eventos Recorrentes
- **Tipos de recorrência**:
  - 📅 **Diária**: Repete todos os dias
  - 📅 **Semanal**: Repete toda semana no mesmo dia
  - 📅 **Mensal**: Repete todo mês no mesmo dia
  - 📅 **Anual**: Repete todo ano na mesma data
- **Instâncias virtuais**: Geração automática de repetições
- **Ícone visual**: 🔁 indica eventos recorrentes
- **Limitação**: Instâncias virtuais não podem ser editadas individualmente
- **Edição da série**: Alterar o evento original atualiza todas as instâncias

#### Notificações de Eventos
- **Verificação automática**: Ao abrir o app, verifica eventos do dia
- **Anúncio individual**: Cada evento é anunciado separadamente
- **Ordenação cronológica**: Eventos anunciados do mais cedo ao mais tarde
- **Pausa entre eventos**: 4 segundos de espera entre cada anúncio
- **Confirmação**: Solicita "OK" após cada evento
- **Controle de frequência**: Notifica apenas uma vez por dia
- **Reset automático**: Zera à meia-noite
- **Configuração**: Opção para sempre anunciar ou desabilitar

#### Filtros e Visualização
- **Filtros por período**:
  - Hoje
  - Esta semana
  - Este mês
  - Todos
  - Data personalizada
- **Ordenação**: Por data e hora
- **Busca**: Campo de pesquisa por nome
- **Modo de seleção**: Seleção múltipla para ações em lote
- **Status**: Eventos cancelados são marcados visualmente

#### Edição e Exclusão
- **Editar evento**: Atualizar informações do evento
- **Cancelar evento**: Marcar como cancelado sem deletar
- **Deletar evento**: Remover permanentemente


---



---

### 5. 🤖 **Inteligência Artificial**

#### Processamento de Comandos
- **API Groq**: Utiliza modelos Llama (padrão: `llama-3.3-70b-versatile`)
- **Fallback Gemini**: Suporte opcional para API Gemini
- **Análise de linguagem natural**: Interpreta comandos complexos
- **Extração de dados**: Identifica valores, datas, categorias, etc.
- **Contexto**: Considera ano atual, categorias disponíveis e idioma

#### Respostas Inteligentes
- **Consultas financeiras**: Responde perguntas sobre gastos, saldo, etc.
- **Análise de dados**: Processa transações e eventos para gerar insights
- **Sugestões**: Recomenda categorias com base no contexto
- **Multilíngue**: Responde no idioma configurado

#### Verificação de Modelo
- **Atualização automática**: Verifica se o modelo atual está ativo
- **Busca de modelos**: Consulta modelos disponíveis na API Groq
- **Seleção inteligente**: Escolhe o melhor modelo Llama disponível
- **Configuração remota**: Suporte para arquivo de configuração JSON

---

### 6. 📊 **Relatórios e Análises**

#### Relatórios Financeiros
- **Gráfico de pizza**: Visualização de despesas por categoria
- **Resumo financeiro**:
  - Total de receitas
  - Total de despesas
  - Saldo líquido
- **Lista de transações**: Detalhamento completo
- **Filtros avançados**:
  - Período personalizado
  - Categorias específicas
  - Subcategorias
  - Tipo de transação
  - Valor mínimo/máximo

#### Relatório de Parcelamentos
- **Tela dedicada**: Visualização exclusiva de compras parceladas
- **Agrupamento**: Transações agrupadas por `installmentId`
- **Informações**:
  - Descrição da compra
  - Número de parcelas
  - Valor de cada parcela
  - Total da compra
  - Parcelas pagas/pendentes
- **Ações**: Editar ou deletar série completa

#### Exportação de Relatórios
- **PDF**: Geração de relatórios em PDF
  - Captura de tela do relatório
  - Inclusão de gráficos e tabelas
  - Metadados (data, filtros aplicados)
- **Compartilhamento**:
  - WhatsApp
  - E-mail
  - Outras apps
- **Visualização**: Pré-visualização antes de compartilhar

---

### 7. 💾 **Gestão de Dados**

#### Banco de Dados Local
- **Hive**: Banco de dados NoSQL local
- **Boxes**:
  - `transactions`: Transações financeiras
  - `events`: Eventos da agenda
  - `categories`: Categorias personalizadas
  - `settings`: Configurações do app

- **Persistência**: Dados salvos localmente no dispositivo
- **Performance**: Acesso rápido e eficiente

#### Backup e Restauração
- **Backup manual**: Exportar dados para arquivo JSON
- **Backup no Google Drive**: Sincronização com nuvem
- **Metadados**: Informações sobre data, tamanho, número de registros
- **Restauração**: Importar dados de backup
- **Limpeza automática**: Backup e exclusão de dados antigos

#### Importação e Exportação
- **Formatos suportados**:
  - JSON (transações e eventos)
  - iCalendar (.ics) para eventos
  - CSV (via script Python)
- **Importação de calendário**: Integração com Google Calendar
- **Exportação de calendário**: Criar arquivos .ics
- **Filtros de data**: Exportar apenas período específico

#### Gerenciamento de Espaço
- **Estatísticas**:
  - Número de transações
  - Número de eventos
  - Tamanho do banco de dados
- **Limpeza de dados antigos**: Remover registros anteriores a uma data
- **Reset completo**: Apagar todos os dados do app

---

### 8. 🌍 **Multilíngue (14 Idiomas)**

#### Idiomas Suportados
1. 🇧🇷 Português (Brasil) - `pt_BR`
2. 🇵🇹 Português (Portugal) - `pt_PT`
3. 🇺🇸 English - `en`
4. 🇪🇸 Español - `es`
5. 🇩🇪 Deutsch - `de`
6. 🇮🇹 Italiano - `it`
7. 🇫🇷 Français - `fr`
8. 🇯🇵 日本語 - `ja`
9. 🇨🇳 中文 - `zh`
10. 🇮🇳 हिन्दी - `hi`
11. 🇸🇦 العربية - `ar`
12. 🇮🇩 Bahasa Indonesia - `id`
13. 🇷🇺 Русский - `ru`
14. 🇧🇩 বাংলা - `bn`

#### Sistema de Tradução
- **Arquivo centralizado**: `lib/utils/localization.dart`
- **Chaves de tradução**: Mais de 200 strings traduzidas
- **Tradução automática**: Categorias, subcategorias, mensagens
- **Detecção automática**: Usa idioma do sistema por padrão
- **Troca em tempo real**: Atualiza interface ao mudar idioma
- **Voz sincronizada**: TTS e STT ajustados ao idioma selecionado

#### Localização
- **Formato de data**: Adaptado ao idioma (pt_BR: dd/MM/yyyy)
- **Formato de moeda**: Símbolo e separadores localizados
- **Números**: Formatação de valores conforme região
- **Calendário**: Nomes de meses e dias traduzidos

---

### 9. ⚙️ **Configurações**

#### Configurações de Voz
- **Palavra de ativação**: Personalizar palavra-chave
- **Comandos de voz**: Habilitar/desabilitar reconhecimento
- **Anúncio de eventos**: Sempre anunciar ou desabilitar
- **Idioma**: Selecionar idioma do app e voz

#### Configurações de API
- **Chave Groq API**: Configurar chave pessoal
- **Modelo Groq**: Selecionar modelo Llama (padrão: llama-3.3-70b-versatile)
- **Verificação de modelo**: Atualização automática se modelo inativo
- **Fallback Gemini**: Chave no arquivo `.env` como backup

#### Configurações de Categorias
- **Reset de categorias**: Restaurar categorias padrão
- **Gerenciar categorias**: Adicionar, editar, deletar
- **Subcategorias**: Gerenciar subcategorias personalizadas

#### Configurações de Dados
- **Backup**: Criar backup manual ou automático
- **Restauração**: Importar dados de backup
- **Limpeza**: Remover dados antigos
- **Reset completo**: Apagar todos os dados

---

### 10. 📎 **Anexos**

#### Tipos Suportados
- **Imagens**: JPG, PNG, etc.
- **Documentos**: PDF, TXT, etc.
- **Outros**: Qualquer tipo de arquivo

#### Funcionalidades
- **Adicionar anexos**: Vincular arquivos a transações ou eventos
- **Visualizar anexos**: Abrir arquivos diretamente no app
- **Remover anexos**: Deletar arquivos vinculados
- **Armazenamento local**: Arquivos salvos no dispositivo

---

### 11. 🔍 **Consultas e Perguntas**

#### Consultas Simples (Locais)
- **Saldo atual**: "Qual meu saldo?"
- **Total de gastos**: "Quanto gastei este mês?"
- **Eventos do dia**: "Quais eventos tenho hoje?"
- **Processamento rápido**: Sem uso de API (economia de tokens)

#### Consultas Complexas (IA)
- **Análise de gastos**: "Quanto gastei em alimentação nos últimos 3 meses?"
- **Comparações**: "Gastei mais este mês ou no mês passado?"
- **Previsões**: "Qual categoria gasto mais?"
- **Insights**: Análise detalhada com contexto completo

#### Preparação de Dados
- **Resumo de transações**: Agrupa por categoria, período, tipo
- **Resumo de eventos**: Lista eventos por data
- **Contexto completo**: Envia dados relevantes para IA
- **Otimização**: Minimiza tokens enviados

---

### 12. 🎨 **Interface e Design**

#### Tema
- **Material Design 3**: Design moderno e responsivo
- **Modo escuro**: Tema dark por padrão
- **Cores neon**: Cyan neon (#00E5FF) como cor principal
- **Fundo escuro**: #121212 para conforto visual

#### Animações
- **Fade In**: Entrada suave de elementos
- **Avatar pulsante**: Animação durante escuta de voz
- **Transições**: Navegação fluida entre telas
- **Feedback visual**: Indicadores de carregamento

#### Navegação
- **Drawer (Menu lateral)**:
  - 🏠 Início
  - 💰 Finanças
  - 📅 Agenda
  - 📊 Relatórios
  - 🏷️ Categorias
  - 💾 Gerenciar Dados
  - ⚙️ Configurações
  - ❓ Ajuda
- **Bottom Navigation**: Acesso rápido às telas principais
- **FAB (Floating Action Button)**: Ações rápidas em cada tela

#### Acessibilidade
- **Controle por voz**: Totalmente operável por comandos de voz
- **Feedback auditivo**: Respostas faladas
- **Ícones claros**: Identificação visual intuitiva
- **Contraste**: Cores de alto contraste para legibilidade

---

### 13. 📱 **Telas do Aplicativo**

#### 1. Home Screen (Tela Inicial)
- **Saldo atual**: Exibição destacada
- **Botões de acesso rápido**:
  - Finanças
  - Agenda
  - Relatórios
  - Categorias
- **Controle de voz**: Avatar central para comandos
- **Últimas transações**: Lista resumida
- **Próximos eventos**: Eventos do dia

#### 2. Finance Screen (Finanças)
- **Lista de transações**: Todas as transações com filtros
- **Resumo financeiro**: Receitas, despesas, saldo
- **Filtros**: Período, tipo, categoria
- **Ordenação**: Data, valor, tipo, descrição
- **Ações**: Adicionar, editar, deletar, compartilhar
- **FAB**: Adicionar transação manual

#### 3. Agenda Screen (Agenda)
- **Lista de eventos**: Todos os eventos com filtros
- **Calendário**: Visualização mensal (opcional)
- **Filtros**: Período, status
- **Ordenação**: Data e hora
- **Ações**: Adicionar, editar, cancelar, deletar
- **FAB**: Adicionar evento manual

#### 4. Reports Screen (Relatórios)
- **Gráfico de pizza**: Despesas por categoria
- **Resumo**: Receitas, despesas, saldo
- **Filtros avançados**: Múltiplos critérios
- **Lista de transações**: Detalhamento
- **Exportação**: PDF, compartilhamento
- **Relatório de parcelamentos**: Acesso dedicado

#### 5. Category Screen (Categorias)
- **Abas**: Despesas e Receitas
- **Lista de categorias**: Padrão e personalizadas
- **Subcategorias**: Expansível para cada categoria
- **Ações**: Adicionar, editar, deletar
- **Reset**: Restaurar categorias padrão

#### 6. Data Management Screen (Gerenciar Dados)
- **Estatísticas**: Número de registros, tamanho do DB
- **Backup**: Criar, listar, restaurar
- **Importação**: JSON, iCalendar
- **Exportação**: JSON, iCalendar
- **Limpeza**: Remover dados antigos
- **Reset**: Apagar tudo

#### 7. Settings Screen (Configurações)
- **Idioma**: Seletor de idioma
- **Voz**: Palavra de ativação, habilitar/desabilitar
- **API**: Chave Groq, modelo
- **Categorias**: Reset
- **Dados**: Backup, restauração, reset
- **Sobre**: Versão, informações

#### 8. Onboarding Screen (Primeira Execução)
- **Boas-vindas**: Introdução ao app
- **Configuração inicial**: Idioma, voz
- **Tutorial**: Como usar comandos de voz
- **Permissões**: Microfone, armazenamento

---

### 14. 🔧 **Serviços e Utilitários**

#### AIService
- **Processamento de comandos**: Interpreta linguagem natural
- **Respostas inteligentes**: Gera respostas contextuais
- **Verificação de modelo**: Atualiza modelo se necessário
- **Integração Groq**: Comunicação com API

#### DatabaseService
- **CRUD completo**: Create, Read, Update, Delete
- **Migrações**: Atualização de estrutura de dados
- **Normalização**: Correção de dados inconsistentes
- **Histórico**: Gerenciamento de operações

#### VoiceService
- **Speech-to-Text**: Reconhecimento de voz
- **Text-to-Speech**: Síntese de voz
- **Configuração de idioma**: Ajuste de locale
- **Permissões**: Gerenciamento de acesso ao microfone

#### QueryService
- **Consultas locais**: Respostas rápidas sem IA
- **Preparação de dados**: Resumos para IA
- **Análise financeira**: Processamento de transações
- **Análise de eventos**: Processamento de agenda

#### PDFService
- **Geração de PDF**: Criação de relatórios
- **Captura de tela**: Conversão de widgets para imagem
- **Metadados**: Informações do relatório
- **Compartilhamento**: Integração com apps

#### ImportService
- **Importação de transações**: JSON
- **Importação de eventos**: JSON, iCalendar
- **Validação**: Verificação de dados
- **Conversão**: Adaptação de formatos

#### GoogleDriveService
- **Autenticação**: Login com Google
- **Upload**: Envio de backups
- **Download**: Recuperação de backups
- **Listagem**: Visualização de arquivos

#### EventNotificationService
- **Verificação diária**: Eventos do dia
- **Anúncio por voz**: Notificação falada
- **Controle de frequência**: Uma vez por dia
- **Ordenação**: Cronológica

#### AttachmentsService
- **Adicionar anexos**: Vincular arquivos
- **Visualizar anexos**: Abrir arquivos
- **Remover anexos**: Deletar arquivos
- **Armazenamento**: Gerenciamento de espaço

---

### 15. 🛠️ **Recursos Técnicos**

#### Tecnologias
- **Flutter**: Framework multiplataforma
- **Dart**: Linguagem de programação
- **Hive**: Banco de dados NoSQL local
- **Groq API**: Inteligência artificial (Llama)
- **Speech-to-Text**: Reconhecimento de voz
- **Text-to-Speech**: Síntese de voz
- **FL Chart**: Gráficos e visualizações
- **PDF**: Geração de documentos

#### Arquitetura
- **MVC**: Model-View-Controller
- **Services**: Camada de serviços isolada
- **Models**: Modelos de dados com Hive
- **Widgets**: Componentes reutilizáveis
- **Utils**: Utilitários e constantes

#### Persistência
- **Hive Boxes**: Armazenamento local
- **Adapters**: Serialização de objetos
- **Migrations**: Versionamento de dados
- **Backup**: Exportação JSON

#### Segurança
- **Chaves API**: Armazenamento local seguro
- **Permissões**: Controle de acesso
- **Validação**: Verificação de dados
- **Isolamento**: Dados locais no dispositivo

---

## 🚀 **Fluxos de Uso**

### Fluxo 1: Adicionar Transação por Voz
1. Usuário abre o app
2. Toca no avatar central
3. Diz: "Comprei um café de 5 reais"
4. IA processa o comando
5. Transação é criada automaticamente
6. App confirma: "Transação adicionada: Café, R$ 5,00"
7. Saldo é atualizado

### Fluxo 2: Criar Evento Recorrente
1. Usuário vai para Agenda
2. Toca no FAB (+)
3. Preenche: "Reunião semanal", data, hora
4. Seleciona recorrência: "Semanal"
5. Salva
6. Evento é criado com ícone 🔁
7. Instâncias virtuais aparecem na lista



### Fluxo 4: Gerar Relatório PDF
1. Usuário vai para Relatórios
2. Aplica filtros desejados
3. Toca em "Exportar PDF"
4. App captura tela do relatório
5. Gera PDF com gráficos e dados
6. Abre diálogo de compartilhamento
7. Usuário escolhe WhatsApp
8. PDF é enviado

### Fluxo 5: Backup no Google Drive
1. Usuário vai para Gerenciar Dados
2. Toca em "Backup no Google Drive"
3. Faz login com Google
4. App exporta dados para JSON
5. Envia para Google Drive
6. Confirma: "Backup criado com sucesso"

---

## 📊 **Estatísticas do Projeto**

### Código
- **Linhas de código**: ~15.000+
- **Arquivos Dart**: 38+
- **Telas**: 10
- **Serviços**: 9
- **Modelos**: 5
- **Widgets**: 5+

### Funcionalidades
- **Comandos de voz**: 20+
- **Idiomas suportados**: 14
- **Categorias padrão**: 18 (9 despesas + 9 receitas)
- **Subcategorias**: 50+
- **Chaves de tradução**: 200+

### Tamanho
- **APK**: ~58 MB
- **Banco de dados**: Variável (depende do uso)

---

## 🎯 **Diferenciais**

1. **Controle 100% por voz**: Totalmente operável sem tocar na tela
2. **IA avançada**: Processamento de linguagem natural com Llama
3. **Multilíngue completo**: 14 idiomas com voz sincronizada
4. **Eventos recorrentes**: Sistema completo de repetições

6. **Parcelamento inteligente**: Lógica corrigida e relatório dedicado
7. **Notificações inteligentes**: Anúncio individual de eventos
8. **Backup em nuvem**: Integração com Google Drive
9. **Relatórios PDF**: Exportação profissional
10. **Open source**: Código aberto e personalizável

---

## 📝 **Notas Importantes**

### Configuração Inicial
- **Chave Groq API**: Necessária para comandos de voz
- **Permissões**: Microfone e armazenamento
- **Idioma**: Configurar no primeiro uso

### Limitações
- **Instâncias virtuais**: Eventos recorrentes não editáveis individualmente
- **Backup Google Drive**: Requer autenticação
- **IA**: Depende de conexão com internet

### Próximos Passos Sugeridos
1. Testes em dispositivo físico

3. Testes de eventos recorrentes em diferentes períodos
4. Verificação de comportamento com múltiplas operações no histórico
5. Otimização de performance
6. Testes de usabilidade em diferentes idiomas

---

---

## 🏷️ **Guia de Ícones**

Entenda o significado dos símbolos visuais do app:





| Símbolo (Aproximado) | Nome do Ícone | Função no App |
| :---: | :--- | :--- |
| ☰ | **Menu (Hambúrguer)** | Abre o menu lateral esquerdo. |
| 🔲 / 🏷️ | **Ícone de Categorias** | Acesso ao gerenciamento de categorias. |
| ❓ | **Ajuda** | Acessar tela de Ajuda e Manual. |
| ⚙️ | **Configurações** | Ajustes do app, idioma e chave de API. |
| 🎤 | **Microfone** | Ativa o reconhecimento de voz. |
| ✨ | **Brilho (IA)** | Funcionalidades inteligentes (geração de texto). |
| 🔍 | **Lupa** | Pesquisar transações ou eventos. |
| 📋 / 🌪️ | **Filtro** | Opções de filtro (data, categoria). |
| 📊 | **Gráfico** | Acesso aos Relatórios e estatísticas. |
| ☁️ | **Nuvem** | Status de Backup e Sincronização Google Drive. |
| 📅 | **Calendário** | Seleção de data ou visualização da Agenda. |
| 👤 / 👥 | **Contatos** | Selecionar contato para chamadas ou mensagens. |
| 🔒 / 🛡️ | **Cadeado/Escudo** | Privacidade, Segurança e Permissões. |
| 🔑 | **Chave** | Configuração da chave de API (Groq). |
| 🌐 | **Globo / Idioma** | Alterar idioma do aplicativo. |
| 🗑️ | **Lixeira** | Excluir item permanentemente (Longo pressionamento para deletar). |
| ✅ | **Check / Visto** | Confirmar ação ou Status "Pago". |
| 🕒 | **Relógio** | Status "Pendente", "Agendado" ou Horário. |
| 💲 / 🧾 / 👛 | **Finanças** | Ícones de Transações, Recibos e Carteira. |
| 🔁 | **Recorrente** | Indicador de item que se repete automaticamente. |
| 🎂 | **Bolo** | Eventos de Aniversário e mensagens automáticas. |
| 💊 | **Pílula / Frasco** | Gestão de Medicamentos e lembretes de saúde. |
| 📄 | **PDF** | Exportar relatórios para arquivo PDF. |
| 📎 / 📷 | **Anexo / Câmera** | Adicionar fotos da galeria ou câmera como anexo. |
| ✏️ | **Lápis** | Editar registro existente. |
| ➕ | **Sinal de Mais** | Botão flutuante para criar novo registro. |
| 💾 | **Disquete** | Salvar dados localmente. |
| 📤 | **Compartilhar** | Enviar comprovantes ou relatórios para outros apps. |
| 🚪 | **Sair** | Encerrar o aplicativo (Fechar). |






## 📞 **Suporte e Documentação**

- **README.md**: Introdução ao projeto
- **BUILD_INSTRUCTIONS.md**: Instruções de build
- **TRANSLATION_GUIDE.md**: Guia de tradução
- **walkthrough.md**: Histórico de desenvolvimento
- **FUNCIONALIDADES.md**: Este documento

---

**Desenvolvido com Flutter 💙**
**Versão: 1.0.0**
**Última atualização: Dezembro 2025**
