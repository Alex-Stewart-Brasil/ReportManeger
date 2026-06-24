## Plan: Pipeline CI com DocGem e LibreOffice efêmeros

Objetivo: ajustar o fluxo de release em um único arquivo de workflow para que cada sistema operacional execute o ciclo completo no próprio runner: baixar LibreOffice, compilar DocGem, copiar recursos para o App, buildar Electron e publicar artefato final. Não haverá separação DocGem -> Electron em jobs distintos por SO; cada job por SO é ponta a ponta. O workflow mantém versionamento semântico como gatilho inicial e publicação consolidada no final com suporte a release parcial.

**Steps**
1. Fase 1 - Versão e gatilho de release
2. Manter o job calculate-version como ponto único de decisão de release, preservando semântica atual de master/beta/alpha.
3. Garantir outputs de versão (published, version, notes) como dependência explícita dos jobs de build por SO.
4. Fase 2 - Build ponta a ponta por SO (paralelo)
5. Criar dois jobs dedicados: build-win e build-linux, ambos dependentes de calculate-version e condicionados a new_release_published igual true.
6. Em build-win: checkout, setup .NET e Node, baixar/extrair LibreOffice Windows, compilar DocGem win-x64, copiar output para Warren/App/src/resources/DocGen/win, atualizar versão do package.json do App, executar build web e electron-builder Windows.
7. Em build-linux: checkout, setup .NET e Node, baixar/extrair LibreOffice Linux, compilar DocGem linux-x64, copiar output para Warren/App/src/resources/DocGen/linux, atualizar versão do package.json do App, executar build web e electron-builder Linux.
8. Publicar somente artefatos finais por SO (electron-build-win e electron-build-linux), sem artefato intermediário DocGem.
9. Fase 3 - Publicação final tolerante a falhas parciais
10. Ajustar publish-release para depender de calculate-version, build-win e build-linux com estratégia de não cancelamento global e downloads de artefatos com tolerância (continue-on-error).
11. Publicar release com apenas os artefatos finais disponíveis em downloads, preservando prerelease para beta/alpha.
12. Fase 4 - Robustez operacional e manutenção
13. Adicionar timeout por job e retenção curta dos artefatos finais para reduzir custo.
14. Registrar versão do LibreOffice em variável única do workflow para facilitar manutenção futura.
15. Adicionar validações rápidas de presença dos binários esperados antes do electron-builder (falha explícita e log claro).

**Relevant files**
- .github/workflows/release.yml — reestruturação dos jobs, dependências, handoff de artefatos e política de release parcial.
- Warren/DocGem/justfile — referência dos comandos de download/extração por SO a serem traduzidos para steps do GitHub Actions.
- Warren/DocGem/DocGen.csproj — comportamento de publish e cópia automática de resources/LibreOffice para output.
- Warren/App/electron-builder.yml — origem dos recursos extras por SO em src/resources/DocGen/win e src/resources/DocGen/linux.
- Warren/App/justfile — referência do fluxo local core (DocGem -> App/src/resources/DocGen) para equivalência no CI.
- Warren/App/src/main/gen/index.ts — contrato de runtime que busca binário em resources/DocGen quando empacotado.

**Verification**
1. Rodar workflow em branch de teste com release habilitada e confirmar execução dos 4 blocos: versionamento, build-win, build-linux, publish-release.
2. Validar em logs de cada job por SO que houve sequência completa: download LibreOffice, dotnet publish, cópia para App/src/resources/DocGen/{so}, build do App e electron-builder.
3. Validar geração final de pelo menos um artefato de app por SO alvo: exe portátil no Windows e AppImage no Linux.
4. Confirmar que publish-release cria tag e release mesmo com falha em um SO, anexando somente arquivos existentes.
5. Teste manual de execução do binário final em cada SO disponível para verificar chamada ao DocGen e conversão DOCX->PDF.

**Decisions**
- Política de falha: publicar release parcial quando apenas um SO concluir com sucesso.
- Estratégia LibreOffice: baixar em toda execução do CI (sem cache neste momento).
- Arquitetura de jobs: execução ponta a ponta por SO em job único por sistema (DocGem + App + Electron).
- Organização do CI: manter um único workflow monolítico em .github/workflows/release.yml com múltiplos jobs por fase, sem quebrar em arquivos separados.
- Regra por SO: cada job baixa LibreOffice e compila DocGem apenas para o seu próprio sistema operacional.

- Escopo incluído: somente pipeline de release e publicação dos artefatos finais por SO.
- Escopo excluído: otimizações avançadas de cache, mudança de versão dinâmica do LibreOffice por input manual e suporte macOS.

**Further Considerations**
1. Próxima iteração recomendada: adicionar cache por versão do LibreOffice para reduzir tempo médio de pipeline sem alterar arquitetura.
2. Próxima iteração recomendada: incluir checagem de tamanho dos artefatos para evitar estourar limites de upload/download do GitHub Actions.
3. Próxima iteração recomendada: avaliar job opcional de smoke test do executável pós-build antes de publicar release.


## Refinement: Estrutura em 2 workflows

Recomendação de organização:
- Workflow A (orquestrador de release): calcula versão primeiro e decide se haverá release.
- Workflow B (reutilizável de build): executa 2 jobs (Windows e Linux) recebendo a versão como input.
- Ainda é possível manter tudo em 1 arquivo; a divisão em 2 arquivos melhora legibilidade sem perder ordem lógica.

Por que calcular versão antes do build:
- Evita build desnecessário quando semantic-release conclui que não há nova versão.
- Permite embutir a versão correta no package do App antes do electron-builder.
- Evita artefato com versão interna divergente da tag publicada.

Se calcular versão depois do build:
- Você compila sempre, inclusive quando não haverá release.
- Pode gerar artefatos com nome/metadata fora da versão final da release.
- Exige renomear artefatos ou repetir build para consistência.

Decisão sugerida para este projeto:
- Manter pré-cálculo de versão e, se quiser dividir, usar 2 workflows (não 3):
1) release.yml (calculate + publish)
2) build-artifacts.yml (workflow_call com jobs win/linux).
