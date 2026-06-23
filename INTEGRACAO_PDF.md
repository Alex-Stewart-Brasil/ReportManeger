# Integração PDF - Documentação

## 📋 O que foi adicionado

### Backend (.NET)
1. **Novo arquivo**: `Plugins/DocumentFormat/DocToPdf.cs`
   - Conversor DOCX → PDF usando LibreOffice CLI
   - Suporta Windows, Linux e macOS
   - Encontra automaticamente o LibreOffice instalado
   - Gerencia limpeza de arquivos temporários

2. **Novos comandos RPC em `Program.cs`**:
   - `gen-relatorio-pdf`: Gera PDF de relatório Minério
   - `gen-agri-pdf`: Gera PDF de relatório Agricultura

### Frontend (Electron + TypeScript)
1. **Novos métodos em `DotnetClient`**:
   - `genPdf()`: Chama gen-relatorio-pdf
   - `genAgriPdf()`: Chama gen-agri-pdf

2. **Novo arquivo**: `src/main/ipcs/GerarPDF/index.ts`
   - Handlers IPC para `gerar-relatorio-pdf` e `gerar-agri-pdf`
   - Mesma estrutura dos handlers existentes

3. **Tipos**: `src/main/ipcs/GerarPDF/index.types.ts`
   - Exporta canais e tipos

## 🚀 Como usar

### No Renderer (React)
```typescript
import { ipcRenderer } from 'electron'

// Gerar PDF de Relatório
const gerarRelatorioPdf = async (payload: RelatorioPayload) => {
  try {
    const result = await ipcRenderer.invoke('gerar-relatorio-pdf', payload)
    console.log('PDF gerado em:', result)
  } catch (error) {
    console.error('Erro ao gerar PDF:', error)
  }
}

// Gerar PDF de Agricultura
const gerarAgriPdf = async (payload: RelatorioPayload) => {
  try {
    const result = await ipcRenderer.invoke('gerar-agri-pdf', payload)
    console.log('PDF gerado em:', result)
  } catch (error) {
    console.error('Erro ao gerar PDF:', error)
  }
}
```

### Fluxo de funcionamento
1. User clica em "Gerar PDF"
2. Renderer invoca IPC handler (`gerar-relatorio-pdf` ou `gerar-agri-pdf`)
3. Main process chama `DotnetClient.genPdf()` ou `DotnetClient.genAgriPdf()`
4. DocGen recebe comando RPC (`gen-relatorio-pdf` ou `gen-agri-pdf`)
5. DocGen gera DOCX normalmente
6. DocGen chama LibreOffice para converter DOCX → PDF
7. DocGen retorna o caminho do PDF
8. Resultado retorna para o Renderer

## ⚙️ Pré-requisitos

### LibreOffice deve estar instalado
- **Windows**: `C:\Program Files\LibreOffice\` ou `C:\Program Files (x86)\LibreOffice\`
- **Linux**: `/usr/bin/libreoffice` ou instalado via package manager
- **macOS**: `/Applications/LibreOffice.app` ou instalado via Homebrew

Instalar LibreOffice:
- Ubuntu/Debian: `sudo apt install libreoffice`
- Fedora: `sudo dnf install libreoffice`
- macOS: `brew install libreoffice`
- Windows: Baixar de https://www.libreoffice.org

## 📁 Estrutura de arquivos criados

```
DocGem/
├── Plugins/DocumentFormat/
│   ├── Doc.cs (existente)
│   ├── DocXml.cs (existente)
│   └── DocToPdf.cs (NOVO)

App/src/main/
├── gen/
│   └── index.ts (atualizado - novos métodos)
└── ipcs/
    ├── index.ts (atualizado - novo import)
    └── GerarPDF/ (NOVO)
        ├── index.ts
        └── index.types.ts
```

## 🔍 Detalhes da implementação

### Conversão DOCX → PDF
1. Gera DOCX normalmente usando templates existentes
2. Cria diretório temporário
3. Chama LibreOffice em modo headless: 
   ```bash
   libreoffice --headless --convert-to pdf --outdir /tmp/ documento.docx
   ```
4. Move o PDF gerado para o local desejado
5. Limpa o diretório temporário

### Tratamento de erros
- Valida se arquivo DOCX existe
- Valida se LibreOffice está instalado
- Timeout de 5 minutos para conversão
- Retorna mensagens de erro descritivas

## 📝 Próximos passos (opcional)

1. **Adicionar opção de formato**: Permitir escolher entre DOCX e PDF na UI
2. **Caching**: Manter DOCX temporário se usuário converter múltiplas vezes
3. **Progresso**: Adicionar barra de progresso durante conversão
4. **Qualidade**: Adicionar opções de resolução/qualidade do PDF
5. **Validação**: Testar geração em diferentes layouts de relatório
