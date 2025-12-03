# 🌍 Guia de Tradução - FinAgeVoz

## 📋 Idiomas Suportados

O FinAgeVoz está preparado para suportar **14 idiomas**:

1. ✅ **Português (Brasil)** - `pt_BR` - **100% Completo**
2. ⚠️ **Português (Portugal)** - `pt_PT` - Pendente
3. ✅ **Inglês** - `en` - **100% Completo**
4. ✅ **Espanhol** - `es` - **100% Completo**
5. ⚠️ **Alemão** - `de` - Pendente
6. ⚠️ **Italiano** - `it` - Pendente
7. ⚠️ **Francês** - `fr` - Pendente
8. ⚠️ **Japonês** - `ja` - Pendente
9. ⚠️ **Chinês** - `zh` - Pendente
10. ⚠️ **Hindi** - `hi` - Pendente
11. ⚠️ **Árabe** - `ar` - Pendente
12. ⚠️ **Indonésio** - `id` - Pendente
13. ⚠️ **Russo** - `ru` - Pendente
14. ⚠️ **Bengali** - `bn` - Pendente

---

## 📁 Arquivos de Tradução

### Arquivo Principal
- **`lib/utils/localization.dart`** - Contém TODAS as traduções

### Template para Tradução
- **`translation_template.csv`** - Template CSV com as principais chaves

---

## 🔧 Como Adicionar um Novo Idioma

### Opção 1: Editar Diretamente o Arquivo Dart

1. Abra `lib/utils/localization.dart`
2. Localize o Map `_localizedValues`
3. Adicione um novo Map com o código do idioma:

```dart
'pt_PT': {  // Código do idioma
  'app_title': 'FinAgeVoz',
  'subtitle': 'O seu assistente financeiro',  // Tradução
  'menu_settings': 'Definições',  // Em PT-PT é "Definições"
  // ... copie todas as chaves de pt_BR e traduza
}
```

### Opção 2: Usar o Template CSV

1. Abra `translation_template.csv` no Excel ou Google Sheets
2. Preencha a coluna do idioma desejado
3. Use o CSV como referência para adicionar no arquivo `.dart`

---

## 📊 Estatísticas de Tradução

### Total de Chaves por Seção:

- **Home/Menu**: ~50 chaves
- **Finance**: ~30 chaves
- **Agenda**: ~20 chaves
- **Reports**: ~25 chaves
- **Settings**: ~60 chaves
- **Categories**: ~100 chaves
- **Help Dialog**: ~40 chaves
- **Messages**: ~30 chaves

**TOTAL**: ~355 chaves para traduzir

---

## 🎯 Prioridade de Tradução

### Alta Prioridade (Interface Principal):
1. `status_tap_to_speak`
2. `nav_finance`, `nav_agenda`, `nav_reports`
3. `menu_settings`, `menu_help`, `menu_about`
4. `save`, `cancel`, `delete`, `edit`, `close`

### Média Prioridade (Funcionalidades):
1. Categorias (`cat_*`)
2. Subcategorias (`sub_*`)
3. Mensagens de erro e sucesso

### Baixa Prioridade (Detalhes):
1. Diálogo de Ajuda completo
2. Mensagens longas
3. Tooltips

---

## 🛠️ Ferramentas Recomendadas

### Para Tradução Automática:
- **DeepL** - Melhor qualidade para idiomas europeus
- **Google Translate** - Boa cobertura global
- **ChatGPT/Claude** - Excelente para contexto e nuances

### Para Edição:
- **VS Code** - Para editar o arquivo `.dart`
- **Excel/Google Sheets** - Para trabalhar com o CSV
- **Notepad++** - Alternativa leve

---

## ✅ Checklist de Tradução

Ao traduzir um idioma, certifique-se de:

- [ ] Todas as ~355 chaves foram traduzidas
- [ ] Emojis foram mantidos (💰, 📅, ⚙️, etc.)
- [ ] Formatação de strings foi preservada (aspas, quebras de linha)
- [ ] Termos técnicos foram traduzidos corretamente
- [ ] Testou o idioma no app
- [ ] Verificou se não há caracteres especiais quebrados

---

## 🔍 Exemplo de Tradução

### Português (Brasil) → Português (Portugal)

```dart
// pt_BR
'menu_settings': 'Configuração',
'menu_help': 'Ajuda',
'save': 'Salvar',

// pt_PT
'menu_settings': 'Definições',  // Mudou
'menu_help': 'Ajuda',           // Igual
'save': 'Guardar',              // Mudou
```

---

## 📞 Suporte

Para dúvidas sobre tradução:
- Consulte o arquivo `lib/utils/localization.dart` como referência
- Veja os idiomas já traduzidos (pt_BR, en, es) como exemplo
- Use o contexto das chaves para entender o significado

---

## 🚀 Após Traduzir

1. Salve o arquivo `lib/utils/localization.dart`
2. Faça hot reload no app (`r` no terminal)
3. Teste mudando o idioma em Configurações
4. Verifique todas as telas principais

**Nenhum código precisa ser alterado!** ✨

---

**Última atualização**: 26/11/2025
**Versão do App**: 1.0.0
