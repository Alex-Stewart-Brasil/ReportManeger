# 🧪 Testes e Verificação da Integração PDF

## 1. Testes Básicos

### Teste 1.1: LibreOffice disponível
```bash
# Linux/macOS
which libreoffice
libreoffice --version

# Windows (abra Power Shell)
Get-Command soffice
```

### Teste 1.2: Compilação
```bash
cd Warren/DocGem
dotnet build
# ✓ Deve compilar sem erros
```

### Teste 1.3: Teste RPC direto (opcional)
```bash
# Inicie o DocGen
./bin/Debug/net8.0/linux-x64/DocGen

# Em outro terminal, envie um comando JSON:
echo '{"id":1,"method":"gen-relatorio-pdf","params":{"config":{"outputPath":"/tmp","sobrescrever":true},"data":{...}}}' | ./bin/Debug/net8.0/linux-x64/DocGen
```

## 2. Testes da UI

### Teste 2.1: Hook funcionando
```typescript
// No console do DevTools (Ctrl+Shift+I)
import { ipcRenderer } from 'electron'

// Chamar o IPC diretamente
ipcRenderer.invoke('gerar-relatorio-pdf', {
  title: "Teste",
  style: "RelatorioStyle1",
  // ... dados necessários
}).then(result => console.log('Sucesso:', result))
  .catch(err => console.error('Erro:', err))
```

### Teste 2.2: Verificar canais
```typescript
// DevTools console
const { ipcMain } = require('electron')
console.log('Canais registrados:', Object.keys(ipcMain._events || {}))
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

### Teste 3.5: Tratamento de erros
- [ ] Desinstalar LibreOffice temporariamente
- [ ] Tentar gerar PDF
- [ ] Deve mostrar erro: "LibreOffice não encontrado"
- [ ] Reinstalar LibreOffice

## 4. Testes de Performance

### Teste 4.1: Tempo de conversão
```typescript
const start = Date.now()
const result = await ipcRenderer.invoke('gerar-relatorio-pdf', payload)
const elapsed = Date.now() - start
console.log(`Tempo de conversão: ${elapsed}ms`)
// Esperado: 3-10 segundos (primeira vez) ou 2-5 segundos (seguintes)
```

### Teste 4.2: Múltiplas gerações sequenciais
```typescript
for (let i = 0; i < 5; i++) {
  const start = Date.now()
  await ipcRenderer.invoke('gerar-relatorio-pdf', {
    ...payload,
    title: `Teste_${i}`
  })
  console.log(`#${i+1}: ${Date.now() - start}ms`)
}
```

### Teste 4.3: Gerações em paralelo
```typescript
const promises = Array.from({ length: 3 }, (_, i) =>
  ipcRenderer.invoke('gerar-relatorio-pdf', {
    ...payload,
    title: `Paralelo_${i}`
  })
)
const results = await Promise.all(promises)
console.log('Todos completados:', results)
```

## 5. Testes de Qualidade do PDF

### Teste 5.1: Estrutura do PDF
```bash
# Verificar se PDF é válido
file relatório.pdf
# Deve retoriar: "PDF document, version..."

# Verificar com pdfinfo (se tiver)
pdfinfo relatório.pdf
```

### Teste 5.2: Conteúdo conservado
- [ ] Verificar todas as imagens aparecem
- [ ] Verificar todos os textos aparecem
- [ ] Verificar formatação está correta
- [ ] Verificar quebras de página estão corretas

### Teste 5.3: Tamanho do arquivo
- [ ] DOCX: ~2-5 MB típico
- [ ] PDF: ~3-8 MB típico (maior por compressão de imagens)
- [ ] Ratio: PDF/DOCX < 2x

## 6. Testes de Integração

### Teste 6.1: Fluxo completo
```
1. App aberto
2. Preencher dados
3. Clicar "Gerar DOCX" → OK?
4. Clicar "Gerar PDF" → OK?
5. Abrir ambos arquivos → conteúdo igual?
6. Fechar e reabrir app
7. Gerar novo PDF → funciona?
```

### Teste 6.2: Diferentes estilos
```typescript
// Para cada RelatorioStyle disponível
const styles = ['Estilo1', 'Estilo2', 'Estilo3']

for (const style of styles) {
  try {
    const result = await ipcRenderer.invoke('gerar-relatorio-pdf', {
      ...payload,
      style
    })
    console.log(`✓ ${style}: ${result}`)
  } catch (error) {
    console.error(`✗ ${style}: ${error}`)
  }
}
```

## 7. Testes de Robustez

### Teste 7.1: Espaço em disco
- [ ] Listar 50 PDFs grandes
- [ ] Sistema não deve travar
- [ ] Verificar limpeza de temporários

### Teste 7.2: Caracteres especiais
- [ ] Título: "Test_ã_é_ç_ü_ñ.pdf"
- [ ] Caracteres acentuados no conteúdo
- [ ] Emojis no conteúdo (opcional)

### Teste 7.3: Paths longos
- [ ] Desktop/Relatorios/Subfolder/SubSub/NomeMuitoLongoDePdf.pdf
- [ ] Deve funcionar normalmente

### Teste 7.4: Fechamento durante conversão
- [ ] Iniciar conversão
- [ ] Imediatamente fechar app
- [ ] Verificar se limpeza funcionou

## 8. Checklist Final

- [ ] Compilação sem erros
- [ ] LibreOffice encontrado automaticamente
- [ ] PDF gerado com sucesso
- [ ] Conteúdo correto no PDF
- [ ] Múltiplas gerações funcionam
- [ ] Erros tratados corretamente
- [ ] Performance aceitável
- [ ] Sem vazamento de memória
- [ ] Funcionando em Windows/Linux/Mac
- [ ] Documentação clara

## 9. Logs para análise

Se algo não funcionar, ative logs:

```typescript
// DevTools Console
localStorage.setItem('debug', '*')

// Ou específico para DocGen
localStorage.setItem('debug', '*:docgen:*')
```

Depois verifique:
- `~/.config/Code/User/workspaceStorage/.../debug.log` 
- Console do DevTools (F12)
- Stderr do processo DocGen

## 10. Rollback (se necessário)

Se precisar reverter:

```bash
git status
git diff
git checkout -- .

# Ou remover arquivos novos
rm -rf Warren/App/src/main/ipcs/GerarPDF/
rm Warren/App/src/renderer/src/hooks/useGerarPdf.ts
rm Warren/App/src/renderer/src/components/GerarPdfButton.tsx
```
