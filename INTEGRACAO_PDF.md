# Integração PDF - Documentação

## Arquitetura atual

A geração de PDF usa o **LibreOffice instalado no sistema do usuário** — não é mais embutido no pacote do app (isso respondia por ~90% do tamanho do instalador). O fluxo:

1. `DocGen` gera o `.docx` normalmente (templates OpenXML).
2. `DocGen` localiza o `soffice` do sistema (`LibreOfficeManager.cs`: `PATH`, diretórios padrão de instalação, `/opt/libreoffice*`, snap, flatpak).
3. `DocGen` converte o `.docx` para PDF chamando o LibreOffice em modo headless (`DocToPdf.cs`).

Uma abordagem alternativa via `mammoth` (docx→html) + `printToPDF` nativo do Electron foi avaliada e descartada — tem problemas conhecidos com cabeçalhos e imagens em documentos mais complexos.

### Backend (.NET)
- `Plugins/DocumentFormat/LibreOfficeManager.cs`: localiza o `soffice` no sistema; expõe `CheckStatus()` (instalado/caminho/versão) e lança `LibreOfficeNotFoundException` quando não encontrado.
- `Plugins/DocumentFormat/DocToPdf.cs`: conversão via LibreOffice CLI (`--headless --convert-to pdf`).
- `Program/RpcServer.cs`: métodos RPC `gen-relatorio-pdf`/`gen-agri-pdf` (geram o `.docx` e convertem) e `check-libreoffice` (status sem gerar nada).

### Frontend (Electron + TypeScript)
- `src/main/gen/index.ts` (`DotnetClient`): `genPdf()`/`genAgriPdf()`, com suporte a callback de progresso.
- `src/main/ipcs/GerarPDF/index.ts`: handlers IPC `gerar-relatorio-pdf`/`gerar-agri-pdf`.
- `src/main/ipcs/LibreOffice/index.ts`: checagem independente (`verificar-libreoffice`) e atalho para abrir a página de download (`instalar-libreoffice`) — usado para orientar o usuário *antes* de tentar gerar um PDF, sem precisar subir o worker do DocGen.

## 🚀 Como usar

### No Renderer (React)
```typescript
// Checar se está instalado (opcional, para orientar o usuário)
const status = await window.ipc.verificarLibreOffice()
if (!status.installed) {
  await window.ipc.instalarLibreOffice() // abre a página de download
  return
}

// Gerar PDF
const pdfPath = await window.ipc.gerarRelatorioPdf(payload) // ou gerarAgriPdf
```

### Fluxo de funcionamento
1. Usuário clica em "Gerar PDF".
2. Renderer invoca `window.ipc.gerarRelatorioPdf`/`gerarAgriPdf`.
3. Main process chama `DotnetClient.genPdf()`/`genAgriPdf()`.
4. DocGen recebe o RPC (`gen-relatorio-pdf`/`gen-agri-pdf`), gera o `.docx`, localiza o LibreOffice do sistema e converte para PDF.
5. Se o LibreOffice não for encontrado, o RPC retorna erro com mensagem clara — a UI pode usar `verificarLibreOffice`/`instalarLibreOffice` para guiar a instalação.
6. Resultado (caminho do PDF) retorna para o Renderer.

## ⚙️ Pré-requisitos

### LibreOffice deve estar instalado no sistema
- **Windows**: `C:\Program Files\LibreOffice\` ou `C:\Program Files (x86)\LibreOffice\`
- **Linux**: `/usr/bin/soffice`, pacote via gerenciador, snap ou flatpak
- **macOS**: `/Applications/LibreOffice.app`

Instalar:
- Ubuntu/Debian: `sudo apt install libreoffice`
- Fedora: `sudo dnf install libreoffice`
- Windows/macOS: https://www.libreoffice.org/download/download/

## 📁 Estrutura de arquivos relevantes

```
DocGem/
├── Plugins/DocumentFormat/
│   ├── Doc.cs
│   ├── DocXml.cs
│   ├── DocToPdf.cs            # conversão via LibreOffice CLI
│   └── LibreOfficeManager.cs  # localização do soffice no sistema
└── Program/RpcServer.cs        # gen-relatorio-pdf, gen-agri-pdf, check-libreoffice

App/src/main/
├── gen/
│   └── index.ts                # DotnetClient: gen(), genAgri(), genPdf(), genAgriPdf()
└── ipcs/
    ├── GerarPDF/                # gerar-relatorio-pdf, gerar-agri-pdf
    └── LibreOffice/             # verificar-libreoffice, instalar-libreoffice
```

## 🔍 Detalhes da implementação

### Conversão DOCX → PDF
1. Gera DOCX normalmente usando templates existentes.
2. Localiza o `soffice` do sistema (com cache do caminho encontrado).
3. Copia o `.docx` para um diretório de trabalho temporário e chama o LibreOffice em modo headless.
4. Copia o PDF gerado para o local desejado.

### Tratamento de erros
- Valida se o arquivo `.docx` existe.
- Lança erro específico (`LIBREOFFICE_NOT_FOUND`) quando o LibreOffice não é encontrado no sistema.
- Timeout de 5 minutos para a conversão.

## 📝 Próximos passos (opcional)

1. **UI de orientação**: usar `verificarLibreOffice`/`instalarLibreOffice` para mostrar um banner/modal quando o LibreOffice não estiver instalado, antes mesmo de tentar gerar o PDF.
2. **Progresso**: já existe suporte a callback de progresso em `DotnetClient.genPdf`/`genAgriPdf` — falta consumir isso na UI.
3. **Qualidade**: validar fidelidade de conversão em layouts de relatório mais complexos.
