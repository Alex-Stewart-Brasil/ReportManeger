app_dir := "Warren/App"
docgem_dir := "Warren/DocGem"

# Compila o DocGem (ambas plataformas) e sincroniza os recursos no App
core:
    #!/usr/bin/env bash
    set -e
    just -d {{docgem_dir}} build
    rm -rf {{app_dir}}/src/resources/DocGen
    cp -rf {{docgem_dir}}/resources/DocGen {{app_dir}}/src/resources/
    cp -rf {{docgem_dir}}/Docs {{app_dir}}/src/resources/DocGen/

# Core + servidor de desenvolvimento Electron
dev:
    #!/usr/bin/env bash
    set -e
    just core
    cd {{app_dir}} && npm run dev

# Typechecks do App
check:
    just -d {{app_dir}} check

# Build React do App
build:
    just -d {{app_dir}} build

# Build Windows: DocGem (win-x64) + React + Electron portable
build-win:
    #!/usr/bin/env bash
    set -e
    just -d {{docgem_dir}} build-win
    rm -rf {{app_dir}}/src/resources/DocGen
    cp -rf {{docgem_dir}}/resources/DocGen {{app_dir}}/src/resources/
    cp -rf {{docgem_dir}}/Docs {{app_dir}}/src/resources/DocGen/
    cd {{app_dir}} && npm run build && npx electron-builder --win portable

# Build Linux: DocGem (linux-x64) + React + Electron AppImage
build-linux:
    #!/usr/bin/env bash
    set -e
    just -d {{docgem_dir}} build-linux
    rm -rf {{app_dir}}/src/resources/DocGen
    cp -rf {{docgem_dir}}/resources/DocGen {{app_dir}}/src/resources/
    cp -rf {{docgem_dir}}/Docs {{app_dir}}/src/resources/DocGen/
    cd {{app_dir}} && npm install --include=optional && npm run build && npx electron-builder --linux AppImage

# Gera commit convencional e push para disparar o pipeline de release
# Uso: just deploy feat "minha feature"
#      just deploy fix "meu fix"
deploy type msg:
    git add -A
    git commit -m "{{type}}: {{msg}}"
    git push origin master
