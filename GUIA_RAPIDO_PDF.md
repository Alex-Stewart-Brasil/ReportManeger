# 🎯 Guia Rápido de Geração de PDF

## Como funciona

A geração de PDF usa o **LibreOffice já instalado na máquina do usuário** — o app não embute mais o LibreOffice no pacote (isso inflava o instalador em ~700MB). O fluxo é:

1. `DocGen` (.NET) gera o `.docx` a partir do template.
2. `DocGen` localiza o `soffice` instalado no sistema (`PATH`, `Program Files`, `/usr/bin`, `/opt/libreoffice*`, snap, flatpak — ver `Plugins/DocumentFormat/LibreOfficeManager.cs`).
3. `DocGen` chama o LibreOffice em modo headless (`--headless --convert-to pdf`) para converter o `.docx` em `.pdf`.

Implementação: `Warren/DocGem/Plugins/DocumentFormat/DocToPdf.cs` + `LibreOfficeManager.cs`, expostos via RPC `gen-relatorio-pdf`/`gen-agri-pdf` (`Warren/DocGem/Program/RpcServer.cs`).

## Passo 1: Instalar LibreOffice (se não tiver)

```bash
# Ubuntu/Debian
sudo apt install libreoffice

# Fedora
sudo dnf install libreoffice

# Windows: baixar de https://www.libreoffice.org/download/download/
```

O app já expõe uma checagem pronta (`window.ipc.verificarLibreOffice()`) e um atalho para abrir a página de download (`window.ipc.instalarLibreOffice()`) — ver `Warren/App/src/main/ipcs/LibreOffice/`.

## Usar no componente

```tsx
const handleGerarPdf = async () => {
  const pdfPath = await window.ipc.gerarRelatorioPdf(data) // ou gerarAgriPdf
  console.log('PDF gerado em:', pdfPath)
}
```

Exemplo real de uso: `src/renderer/src/pages/Relatorio/components/FormMineiro.tsx` e `FormAgri.tsx`.

## Testar

1. Abra o app Electron (`just dev`).
2. Preencha os dados do relatório normalmente.
3. Clique em "Gerar PDF".
4. O PDF será salvo em `Desktop/Relatorios/`.

Ou via CLI: `just -d Warren/DocGem gen-pdf-test`.

## 📊 Fluxo visual

```
┌─────────────────────────────────────────┐
│          React Component (UI)           │
│     window.ipc.gerarRelatorioPdf()       │
└─────────────────┬─────────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │   IPC Handler       │
        │  gerar-relatorio-pdf│
        │  gerar-agri-pdf     │
        └─────────┬───────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │   DotnetClient      │
        │  genPdf()           │
        │  genAgriPdf()       │
        └─────────┬───────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │   DocGen (.NET)     │
        │  gen-relatorio-pdf  │
        │  gen-agri-pdf       │
        └─────────┬───────────┘
                  │
        ┌─────────┴───────────┐
        ▼                     ▼
   ┌─────────────┐   ┌──────────────────┐
   │  Gera DOCX  │──▶│LibreOffice do     │
   │   Template  │   │sistema (headless) │
   └─────────────┘   └──────────────────┘
                          │
                          ▼
                    ┌──────────────┐
                    │   PDF Salvo  │
                    │ Desktop/     │
                    │ Relatorios/  │
                    └──────────────┘
```

## 🐛 Troubleshooting

### Erro: "LibreOffice não encontrado no sistema"
- Instale o LibreOffice (ver Passo 1) e tente novamente.
- Em instalações não padrão, confirme que `soffice`/`soffice.exe` está no `PATH`.

### Erro: "PDF não foi gerado"
- Verifique se há espaço em disco.
- Verifique permissões da pasta `Desktop/Relatorios/`.
- Verifique se o `.docx` gerado está válido.

### Conversão demora muito
- Normal na primeira vez (LibreOffice inicia um processo novo a cada conversão).
- Se durar mais de 5 minutos, há timeout automático (`DocToPdf.cs`).

## 📝 Estrutura de dados

```typescript
interface RelatorioPayload {
  title: string              // Nome do arquivo (sem extensão)
  style: string               // Estilo do template
  sobrescrever?: boolean      // Sobrescrever arquivo existente
}

// Resposta: caminho do PDF gerado (string).
// Em caso de erro, a Promise rejeita com a mensagem do RPC
// (ex.: "LibreOffice não encontrado no sistema. Instale...").
```
