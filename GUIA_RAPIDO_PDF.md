# 🎯 Guia Rápido de Integração PDF

## Passo 1: Instalar LibreOffice (se não tiver)

```bash
# Ubuntu/Debian
sudo apt install libreoffice

# Fedora
sudo dnf install libreoffice

# macOS
brew install libreoffice

# Windows: Baixar de https://www.libreoffice.org
```

## Passo 2: Usar o hook no seu componente

```tsx
import { useGerarPdf } from '@/hooks/useGerarPdf'

export const MeuComponente = () => {
  const { gerarRelatorioPdf, gerarAgriPdf, loading, error } = useGerarPdf()

  const handleGerarPdf = async () => {
    const pdfPath = await gerarRelatorioPdf({
      title: "Meu Relatório",
      style: "RelatorioStyle1",
      // ... outros dados
    })
    
    if (pdfPath) {
      console.log('PDF gerado em:', pdfPath)
    }
  }

  return (
    <div>
      <button onClick={handleGerarPdf} disabled={loading}>
        {loading ? 'Gerando...' : 'Gerar PDF'}
      </button>
      {error && <p style={{color: 'red'}}>{error.message}</p>}
    </div>
  )
}
```

## Passo 3: Usar o componente pronto

Se preferir usar o componente pronto:

```tsx
import GerarPdfButton from '@/components/GerarPdfButton'

export const Pagina = () => {
  const relatorioData = { /* seu dados */ }

  return (
    <div>
      <GerarPdfButton 
        payload={relatorioData}
        onPdfGenerated={(path) => console.log('PDF:', path)}
      />
    </div>
  )
}
```

## Passo 4: Testar

1. Abra o app Electron
2. Preencha os dados do relatório normalmente
3. Clique em "Gerar PDF" (novo botão)
4. O PDF será salvo na pasta `Desktop/Relatorios/`

## 📊 Fluxo visual

```
┌─────────────────────────────────────────┐
│          React Component (UI)           │
│  ┌──────────────────────────────────┐  │
│  │  useGerarPdf() Hook              │  │
│  │  ou GerarPdfButton Component     │  │
│  └──────────────┬───────────────────┘  │
└─────────────────┼──────────────────────┘
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
   ┌─────────────┐   ┌──────────────┐
   │  Gera DOCX  │──▶│LibreOffice CLI│
   │   Template  │   │  Converte PDF │
   └─────────────┘   └──────────────┘
                          │
                          ▼
                    ┌──────────────┐
                    │   PDF Salvo  │
                    │   Desktop/   │
                    │ Relatorios/  │
                    └──────────────┘
```

## 🐛 Troubleshooting

### Erro: "LibreOffice não encontrado"
- Verifique se LibreOffice está instalado
- Reinicie a aplicação após instalar
- Tente executar no terminal: `libreoffice --version`

### Erro: "PDF não foi gerado"
- Verifique se há espaço em disco
- Verifique permissões da pasta
- Verifique se o DOCX gerado está válido

### Conversão demora muito
- Normal na primeira vez (LibreOffice inicia)
- Conversões subsequentes são mais rápidas
- Se durar mais de 5 minutos, há timeout automático

## 📝 Estrutura de dados

```typescript
interface RelatorioPayload {
  title: string              // Nome do arquivo (sem extensão)
  style: string             // Estilo do template
  sobrescrever?: boolean    // Sobrescrever arquivo existente
  // ... outros campos específicos do relatório
}

// Resposta
{
  ok: true,
  outputPath: "/home/user/Desktop/Relatorios/Meu_Relatorio.pdf"
}

// Erro
{
  ok: false,
  error: "Mensagem de erro descritiva"
}
```

## ✅ Checklist de teste

- [ ] LibreOffice instalado e testado
- [ ] Hook `useGerarPdf` importado corretamente
- [ ] Botão "Gerar PDF" aparece na UI
- [ ] Clique no botão gera arquivo em `Desktop/Relatorios/`
- [ ] Arquivo PDF é válido e abrível
- [ ] Dados do relatório aparecem corretamente no PDF
- [ ] Erro é tratado e exibido ao usuário
- [ ] Múltiplas gerações funcionam sem problema
