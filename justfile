app_dir := "Warren/App"
docgem_dir := "Warren/DocGem"

# Compila o DocGem (ambas plataformas) e sincroniza os recursos no App
core:
    #!/usr/bin/env bash
    set -e
    just --justfile {{docgem_dir}}/justfile --working-directory {{docgem_dir}} build
    rm -rf {{app_dir}}/src/resources/DocGen
    mkdir -p {{app_dir}}/src/resources/DocGen/win {{app_dir}}/src/resources/DocGen/linux
    cp -rf {{docgem_dir}}/output/win/* {{app_dir}}/src/resources/DocGen/win/
    cp -rf {{docgem_dir}}/output/linux/* {{app_dir}}/src/resources/DocGen/linux/

# Core + servidor de desenvolvimento Electron
dev:
    #!/usr/bin/env bash
    set -e
    just core
    cd {{app_dir}} && npm run dev

# Typechecks do App
check:
    just --justfile {{app_dir}}/justfile --working-directory {{app_dir}} check

# Build React do App
build:
    just --justfile {{app_dir}}/justfile --working-directory {{app_dir}} build

# Build Windows: DocGem (win-x64) + React + Electron (nsis + portable)
build-win:
    #!/usr/bin/env bash
    set -e
    just --justfile {{docgem_dir}}/justfile --working-directory {{docgem_dir}} build-win
    rm -rf {{app_dir}}/src/resources/DocGen/win
    mkdir -p {{app_dir}}/src/resources/DocGen/win
    cp -rf {{docgem_dir}}/output/win/* {{app_dir}}/src/resources/DocGen/win/
    cd {{app_dir}} && npm run build && npx electron-builder --win

# Build Linux: DocGem (linux-x64) + React + Electron (AppImage + deb)
build-linux:
    #!/usr/bin/env bash
    set -e
    just --justfile {{docgem_dir}}/justfile --working-directory {{docgem_dir}} build-linux
    rm -rf {{app_dir}}/src/resources/DocGen/linux
    mkdir -p {{app_dir}}/src/resources/DocGen/linux
    cp -rf {{docgem_dir}}/output/linux/* {{app_dir}}/src/resources/DocGen/linux/
    cd {{app_dir}} && npm install --include=optional && npm run build && npx electron-builder --linux

# Gera commit convencional e push para disparar o pipeline de release
# Uso: just deploy feat "minha feature"
#      just deploy fix "meu fix"
deploy type msg:
    git add -A
    git commit -m "{{type}}: {{msg}}"
    git push origin master
