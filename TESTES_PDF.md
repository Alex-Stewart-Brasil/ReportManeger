# 🧪 Testes e Verificação da Geração de PDF

A geração de PDF usa o LibreOffice instalado no sistema do usuário (não é mais embutido no pacote). Ver [INTEGRACAO_PDF.md](INTEGRACAO_PDF.md) para a arquitetura completa.

## 1. Testes Básicos

### Teste 1.1: LibreOffice disponível
```bash
# Linux/macOS
which soffice
soffice --version

# Windows (PowerShell)
Get-Command soffice
```

### Teste 1.2: Compilação
```bash
cd Warren/DocGem
dotnet build
# ✓ Deve compilar sem erros
```

### Teste 1.3: Teste RPC direto
```bash
just -d Warren/DocGem gen-pdf-test
# ✓ Deve retornar {"id":1,"ok":true,"outputPath":".../test-output.pdf"}
```

### Teste 1.4: Checagem de status
```bash
echo '{"id":1,"method":"check-libreoffice","params":{}}' | ./output/linux/DocGen
# ✓ Deve retornar {"id":1,"ok":true,"libreOffice":{"installed":true,"path":"...","version":"..."}}
```

## 2. Testes da UI

### Teste 2.1: Checagem de instalação
```typescript
// DevTools console
const status = await window.ipc.verificarLibreOffice()
console.log(status) // { installed: boolean, path?: string, version?: string }
```

### Teste 2.2: Geração via IPC
```typescript
window.ipc.gerarRelatorioPdf({
  title: "Teste",
  style: "RelatorioStyle1",
  // ... dados necessários
}).then(result => console.log('Sucesso:', result))
  .catch(err => console.error('Erro:', err))
```

## 3. Testes de Funcionalidade

### Teste 3.1: Geração básica
- [ ] Abrir app
- [ ] Preencher formulário de relatório
- [ ] Clicar "Gerar PDF"
- [ ] Verificar Desktop/Relatorios/ tem arquivo .pdf
- [ ] Abrir PDF e verificar conteúdo

### Teste 3.2: Sobrescrita
- [ ] Gerar PDF1 com título "Teste"
- [ ] Gerar novamente (mesmo título)
- [ ] Verificar se sobrescreveu (data de modificação)

### Teste 3.3: Caracteres especiais
- [ ] Título: "Relatório_2024-06-23"
- [ ] Verificar se arquivo criado corretamente

### Teste 3.4: Relatórios diferentes
- [ ] Gerar PDF de Minério (RelatorioStyles)
- [ ] Gerar PDF de Agricultura (AgriStyles)
- [ ] Ambos devem funcionar

### Teste 3.5: LibreOffice ausente
- [ ] Desinstalar LibreOffice temporariamente (ou renomear o binário)
- [ ] Tentar gerar PDF
- [ ] Deve rejeitar com mensagem "LibreOffice não encontrado no sistema..."
- [ ] `verificarLibreOffice()` deve retornar `installed: false`
- [ ] Reinstalar LibreOffice e confirmar que volta a funcionar

## 4. Testes de Performance

### Teste 4.1: Tempo de conversão
```typescript
const start = Date.now()
const result = await window.ipc.gerarRelatorioPdf(payload)
console.log(`Tempo de conversão: ${Date.now() - start}ms`)
// Esperado: alguns segundos (LibreOffice inicia um processo novo a cada conversão)
```

### Teste 4.2: Múltiplas gerações sequenciais
```typescript
for (let i = 0; i < 5; i++) {
  const start = Date.now()
  await window.ipc.gerarRelatorioPdf({ ...payload, title: `Teste_${i}` })
  console.log(`#${i+1}: ${Date.now() - start}ms`)
}
```

## 5. Testes de Qualidade do PDF

### Teste 5.1: Estrutura do PDF
```bash
file relatório.pdf
# Deve retornar: "PDF document, version..."
```

### Teste 5.2: Conteúdo conservado
- [ ] Verificar todas as imagens aparecem
- [ ] Verificar todos os textos aparecem
- [ ] Verificar formatação está correta
- [ ] Verificar quebras de página estão corretas

## 6. Testes de Integração

### Teste 6.1: Fluxo completo
```
1. App aberto
2. Preencher dados
3. Clicar "Gerar Relatório" (docx) → OK?
4. Clicar "Gerar PDF" → OK?
5. Abrir ambos arquivos → conteúdo igual?
6. Fechar e reabrir app
7. Gerar novo PDF → funciona?
```

## 7. Testes de Robustez

### Teste 7.1: Caracteres especiais
- [ ] Título com acentos/caracteres especiais
- [ ] Caracteres acentuados no conteúdo

### Teste 7.2: Paths longos
- [ ] Desktop/Relatorios/Subfolder/SubSub/NomeMuitoLongoDePdf.pdf
- [ ] Deve funcionar normalmente

## 8. Checklist Final

- [ ] Compilação sem erros
- [ ] LibreOffice encontrado automaticamente no sistema
- [ ] PDF gerado com sucesso
- [ ] Conteúdo correto no PDF
- [ ] Múltiplas gerações funcionam
- [ ] Erro claro quando LibreOffice não está instalado
- [ ] Funcionando em Windows/Linux
