#!/usr/bin/env python3
"""
Script para extrair todas as chaves de tradução do arquivo localization.dart
e gerar um CSV completo para tradução.

Uso:
    python extract_translation_keys.py

Saída:
    all_translation_keys.csv - Arquivo CSV com todas as chaves
"""

import re
import csv

def extract_keys_from_dart(file_path):
    """Extrai todas as chaves de tradução do arquivo Dart."""
    keys = {}
    current_section = "General"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Encontrar o bloco pt_BR
    pt_br_match = re.search(r"'pt_BR':\s*\{(.*?)\},\s*'en':", content, re.DOTALL)
    if not pt_br_match:
        print("Erro: Não foi possível encontrar o bloco pt_BR")
        return keys
    
    pt_br_content = pt_br_match.group(1)
    
    # Extrair chaves e valores
    pattern = r"'([^']+)':\s*[\"']([^\"']*(?:\\.[^\"']*)*)[\"']"
    matches = re.findall(pattern, pt_br_content)
    
    for key, value in matches:
        # Limpar o valor de escapes
        value = value.replace('\\"', '"').replace('\\n', '\n')
        keys[key] = {
            'pt_BR': value,
            'section': current_section
        }
    
    # Detectar seções pelos comentários
    comment_pattern = r"//\s*([^\r\n]+)"
    comments = re.findall(comment_pattern, pt_br_content)
    
    return keys

def generate_csv(keys, output_file):
    """Gera um arquivo CSV com todas as chaves."""
    languages = ['pt_BR', 'pt_PT', 'en', 'es', 'de', 'it', 'fr', 'ja', 'zh', 'hi', 'ar', 'id', 'ru', 'bn']
    
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        
        # Cabeçalho
        writer.writerow(['key', 'section'] + languages)
        
        # Dados
        for key, data in sorted(keys.items()):
            row = [key, data.get('section', 'General')]
            for lang in languages:
                row.append(data.get(lang, ''))
            writer.writerow(row)
    
    print(f"✅ Arquivo gerado: {output_file}")
    print(f"📊 Total de chaves: {len(keys)}")

if __name__ == '__main__':
    dart_file = 'lib/utils/localization.dart'
    output_file = 'all_translation_keys.csv'
    
    print("🔍 Extraindo chaves de tradução...")
    keys = extract_keys_from_dart(dart_file)
    
    if keys:
        print(f"✅ {len(keys)} chaves encontradas")
        generate_csv(keys, output_file)
        print("\n📝 Próximos passos:")
        print("1. Abra 'all_translation_keys.csv' no Excel ou Google Sheets")
        print("2. Preencha as colunas dos idiomas que deseja traduzir")
        print("3. Use o CSV como referência para atualizar lib/utils/localization.dart")
    else:
        print("❌ Nenhuma chave encontrada. Verifique o arquivo.")
