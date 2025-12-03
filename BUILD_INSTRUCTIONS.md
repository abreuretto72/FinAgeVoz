# Instruções para Build de Produção

## Configuração da API Key

**IMPORTANTE**: Para builds de produção (APK/AAB), sempre use a API Key do **Groq**, nunca do Gemini.

### Passos para configurar:

1. **Antes de gerar o APK**, configure a chave Groq no app:
   - Abra o app
   - Vá em Menu → Configurações
   - Clique em "Chave Groq API"
   - Insira sua chave Groq (formato: `gsk_...`)
   - Clique em Salvar

2. **Verifique** se a chave foi salva:
   - A configuração mostra "Configurada" abaixo de "Chave Groq API"

3. **Gere o APK**:
   ```bash
   flutter build apk --release
   ```

### Como funciona:

O app usa a seguinte lógica de prioridade:
1. **Primeiro**: Verifica se há uma chave Groq salva no banco de dados local (Hive)
2. **Se não houver**: Usa a chave Gemini do arquivo `.env` como fallback

### Arquivo .env

O arquivo `.env` deve conter:
```
GEMINI_API_KEY=sua_chave_gemini_aqui
```

**Nota**: A chave Gemini no `.env` é apenas um fallback para desenvolvimento. Em produção, o app usará a chave Groq configurada pelo usuário.

### Modelo Groq Padrão

O modelo padrão usado é: `llama-3.3-70b-versatile`

Este pode ser alterado em Configurações (se implementado) ou está definido em:
- `lib/services/database_service.dart` → método `getGroqModel()`

### Verificação

Para confirmar que o app está usando Groq:
1. Abra o app
2. Faça um comando de voz
3. Verifique os logs do console - deve aparecer mensagens relacionadas ao Groq, não ao Gemini

### Troubleshooting

Se o app não estiver usando a chave Groq:
1. Verifique se a chave foi salva corretamente nas Configurações
2. Reinicie o app completamente
3. Verifique os logs para confirmar qual API está sendo usada
