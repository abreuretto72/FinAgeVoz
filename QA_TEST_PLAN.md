# 🕵️ PLANO DE TESTES EXAUSTIVO - FinAgeVoz

**Objetivo:** Validar todas as funcionalidades críticas antes da submissão.
**Dispositivo:** SM A256E
**Versão:** 1.0.0

---

## 1. 🚀 INICIALIZAÇÃO & PRIVACIDADE

- [ ] **Splash Screen Animada:**
  - O app abre com logo animado?
  - Duração ~3 segundos?
- [ ] **Privacy Consent (Primeira vez ou Reset):**
  - O diálogo de boas-vindas aparece?
  - Link "Política de Privacidade" abre navegador?
  - Link "Termos de Uso" abre navegador?
  - Botão "Continuar" fecha o diálogo?
- [ ] **Permissões:**
  - App pede permissão de Microfone ao tentar usar voz?
  - App pede permissão de Notificação (Android 13+)?

---

## 2. 💰 FINANÇAS

- [ ] **Adicionar Despesa Simples:**
  - Botão "+" -> Despesa -> Valor 50 -> Categoria Alimentação.
  - Salvar. Aparece na lista? O saldo atualiza?
- [ ] **Adicionar Receita:**
  - Botão "+" -> Receita -> Valor 1000 -> Categoria Salário.
  - Salvar. O saldo aumenta?
- [ ] **Parcelamento:**
  - Criar Despesa -> Valor 300 -> Parcelado em 3x.
  - Verificar se criou 3 lançamentos futuros (Mês 1, 2, 3).
- [ ] **Edição e Exclusão:**
  - Editar uma transação: Mudar valor. Salvou?
  - Excluir uma transação. Sumiu e saldo atualizou?
- [ ] **Relatórios:**
  - Aba Finanças -> Botão Relatórios.
  - Gráfico Pizza aparece?
  - Filtro por mês funciona?


## 2.1 🏦 REGRAS FINANCEIRAS (CRÍTICO)

- [ ] **Despesa Realizada (Pago):**
  - Comando: "Gastei 50 na padaria".
  - Verificar: Status = Pago (Check verde).
- [ ] **Despesa Futura (Pendente):**
  - Comando: "Vou pagar 50 na padaria amanhã".
  - Verificar: Status = Pendente (Relógio/Cinza).
- [ ] **Parcelamento:**
  - Comando: "Comprei TV 1000 reais em 10 vezes".
  - Verificar: 10 parcelas criadas. TODAS Pendentes (a menos que diga "dei entrada").
- [ ] **Aba Pagamentos:**
  - Verificar se mostra APENAS contas Pendentes.

---

## 3. 📅 AGENDA & ANIVERSÁRIOS

- [ ] **Criar Evento Comum:**
  - Aba Agenda -> Botão "+" -> Título: "Teste Reunião" -> Hora: Amanhã 14:00.
  - Salvar. Aparece na lista do dia correto?
- [ ] **Criar Aniversário:**
  - Aba Aniversários -> Botão "+".
  - Nome: "Teste Maria" -> Data: (escolha uma data próxima).
  - Salvar. Aparece?
- [ ] **IA Message Generation (Feature Chave):**
  - Abrir o aniversário criado.
  - Clicar no ícone de "Mensagem IA" (robô/balão).
  - Gera um texto?
  - Botão WhatsApp abre o app com o texto?
- [ ] **Anexos:**
  - Criar evento -> Clicar "Anexar".
  - Tirar foto ou escolher PDF.
  - Salvar. Ao reabrir, o anexo está lá e abre?

---

## 4. 💊 SAÚDE & MEDICAMENTOS

- [ ] **Cadastrar Medicamento:**
  - Aba Saúde -> Botão "+".
  - Nome: "Dipirona".
  - Dosagem: "1 comprimido".
  - Quantidade: 20.
- [ ] **Definir Posologia:**
  - Clicar "Gerenciar Posologia".
  - Escolher "Intervalo de Horas" -> "A cada 8 horas".
  - Início: Agora.
  - Verificar se gerou os horários futuros na lista.
- [ ] **Marcar como Tomado:**
  - Na lista de horários, clicar no check.
  - Muda status para "Tomado"?
  - Estoque diminui de 20 para 19?


## 4.1 💊 REGRAS DE MEDICAMENTOS

- [ ] **Cadastro e Posologia:**
  - Ao criar remédio e adicionar horários, verificar se salva automático.
- [ ] **Confirmação:**
  - Tentar marcar "Tomado" num horário futuro -> Deve pedir confirmação? (Opcional).
- [ ] **Exclusão em Cascata:**
  - Apagar o remédio "Pai". Verificar se todos os horários futuros sumiram da Agenda.

---

## 5. 🎤 COMANDO DE VOZ (Teste Crítico)

*Nota: Requer chave API configurada ou internet.*

- [ ] **Ativação:**
  - Tocar no microfone na Home. Ouve o som/pulsação?
- [ ] **Comandos de Teste:**
  - "Gastei 50 reais com padaria" -> Reconhece e abre tela pré-preenchida?
  - "Reunião amanhã às duas da tarde" -> Cria evento?
  - "Abrir Agenda" -> Navega para agenda?
- [ ] **Erro de Rede:**
  - Desligar Wi-Fi/Dados. Tentar falar. Exibe erro amigável?

---

## 6. ⚙️ CONFIGURAÇÕES & DADOS

- [ ] **Resetar App (Cuidado):**
  - Settings -> Dados -> "Apagar Tudo".
  - Confirmação aparece?
  - Ao confirmar, zera tudo e volta pra Home?
- [ ] **Mudar Idioma:**
  - Mudar idioma do celular para Inglês.
  - App traduz para Inglês? (Títulos, menus, categorias)
- [ ] **Links de Ajuda:**
  - Settings -> Ajuda.
  - Manual abre? Card de Aniversários aparece?

---

## 🧪 SESSÃO DE TESTE GUIADA

**Para começar, escolha uma área:**
1. Finanças
2. Agenda
3. Saúde
4. Voz

Me diga qual número quer testar agora e eu te guio passo a passo! 
