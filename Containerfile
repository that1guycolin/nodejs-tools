FROM node:26-slim

# Install fish & ensure bash up-to-date (their respective lang-servers appreciate it)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash=5.2.37-2+b9 \
    fish=4.0.2-1 \
    shellcheck=0.10.0-1 \
    && rm -rf /var/lib/apt/lists/*

# Install the tools
RUN npm install -g \
    --allow-scripts=core-js \
    bash-language-server@5.6.0 \
    @microsoft/compose-language-service@.5.0 \
    eslint@10.6.0 \
    fish-lsp@1.1.4 \
    markdownlint-cli@0.49.0 \
    marked@18.0.6 \
    prettier@3.9.5 \
    prettier-plugin-glsl@0.3.0 \
    prettier-plugin-yaml@1.2.0 \
    typescript@7.0.2 \
    typescript-language-server@5.3.0\
    vscode-langservers-extracted@4.10.0 \
    yaml-language-server@1.24.0
