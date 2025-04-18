#!/bin/bash

# ==============================================================================
# gerar_contexto_llm.sh (v3.0 - Python/Streamlit Adaptation)
#
# Coleta informações de contexto abrangentes de um projeto de desenvolvimento
# Python (foco: Streamlit) e seu ambiente para auxiliar LLMs.
#
# Inclui dados do Git, GitHub (repo, issues, actions, security, project status),
# ambiente do SO (Linux/Python), ferramentas Python (Black, Flake8, MyPy),
# dependências (Pip/requirements), estrutura do projeto, arquivos de config,
# planos e meta-prompts.
#
# Coloca TODOS os arquivos de saída no diretório raiz do timestamp.
#
# Dependências Base:
#   - Bash 4.3+ (para namerefs)
#   - Git
#   - python3/python, pip3/pip (ou equivalentes)
#   - sed, awk, tr, rev, grep, cut, date, head, find, wc, cat
# Dependências Opcionais (script tentará executar se encontradas):
#   - gh (GitHub CLI): Para buscar detalhes do repo, issues, actions, security, project items.
#   - jq: Para processar JSON do 'gh'.
#   - tree: Para visualizar estrutura de diretórios.
#   - cloc: Para contar linhas de código.
#   - black, flake8, mypy: Para análise de qualidade do código Python.
#   - lsb_release: Para informações da distro Linux.
# ==============================================================================

# --- Configuração ---
OUTPUT_BASE_DIR="./context_llm/code"
EMPTY_TREE_COMMIT="4b825dc642cb6eb9a060e54bf8d69288fbee4904" # Hash de um commit vazio inicial (manter ou adaptar se necessário)
GH_ISSUE_JSON_FIELDS="number,title,body,author,state,stateReason,assignees,labels,comments"
TREE_DEPTH=3
# Adicionado .venv, removido vendor, storage, public/build
CLOC_EXCLUDE_REGEX='(\.venv|node_modules|\.git|\.idea|\.vscode|\.fleet|code_context_llm)'
TREE_IGNORE_PATTERN='.venv|node_modules|.git|.idea|.vscode|.fleet|code_context_llm'
GH_ISSUE_LIST_LIMIT=500
GIT_TAG_LIMIT=10
GH_RUN_LIST_LIMIT=10
GH_PR_LIST_LIMIT=20
GH_RELEASE_LIST_LIMIT=10
PYTHON_CMD="python3" # Prioriza python3
PIP_CMD="pip3"       # Prioriza pip3

# --- Configuração GitHub Project (Manter/Adaptar se usado) ---
GH_PROJECT_NUMBER="2" # Ajustar se usar um projeto GitHub
GH_PROJECT_OWNER="@me" # Ajustar se usar um projeto GitHub
GH_PROJECT_STATUS_FIELD_NAME="Status" # Ajustar se usar um projeto GitHub

# Atualizado para refletir etapas adaptadas
TOTAL_STEPS=11

# Habilita saída em caso de erro e falha em pipelines
set -o pipefail

# --- Funções Auxiliares (Mantidas como no original) ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

suggest_install() {
    local cmd_name="$1"
    local pkg_name="${2:-$cmd_name}" # Usa o segundo argumento como nome do pacote se fornecido

    echo "  AVISO: Comando '$cmd_name' não encontrado."
    echo "  > Para coletar esta informação, tente instalar o pacote '$pkg_name'."
    # Tenta detectar o gerenciador de pacotes
    if command_exists apt; then
        echo "  > Sugestão (Debian/Ubuntu): sudo apt update && sudo apt install $pkg_name"
    elif command_exists yum || command_exists dnf; then
        local pm="yum" && command_exists dnf && pm="dnf"
        echo "  > Sugestão (Fedora/RHEL/CentOS): sudo $pm install $pkg_name"
    elif command_exists pacman; then
        echo "  > Sugestão (Arch): sudo pacman -Syu $pkg_name"
    elif command_exists brew; then
        echo "  > Sugestão (macOS): brew install $pkg_name"
    elif command_exists zypper; then
        echo "  > Sugestão (openSUSE): sudo zypper install $pkg_name"
    else
        echo "  > Verifique o gerenciador de pacotes do seu sistema para instalar '$pkg_name'."
    fi
    # Sugestão para ferramentas Python
    if [[ "$cmd_name" == "black" || "$cmd_name" == "flake8" || "$cmd_name" == "mypy" || "$cmd_name" == "pytest" ]]; then
        if command_exists pip || command_exists pip3; then
            local pip_cmd="pip" && command_exists pip3 && pip_cmd="pip3"
             echo "  > Sugestão (Python/Pip): $pip_cmd install $pkg_name"
        fi
    fi
}

# Determina qual comando python/pip usar (Mantido)
if ! command_exists "$PYTHON_CMD"; then
    if command_exists python; then
        PYTHON_CMD="python"
    else
        PYTHON_CMD="" # Nenhum encontrado
    fi
fi
if ! command_exists "$PIP_CMD"; then
    if command_exists pip; then
        PIP_CMD="pip"
    else
        PIP_CMD="" # Nenhum encontrado
    fi
fi


# --- Início do Script ---
echo "Iniciando a coleta de contexto para o LLM (Versão Python/Streamlit)..."
echo "Versão do Script: v3.0"

# Verifica dependências essenciais
essential_cmds=("bash" "git" "$PYTHON_CMD" "$PIP_CMD" "sed" "awk" "tr" "rev" "grep" "cut" "date" "head" "find" "wc" "cat")
missing_essential=""
for cmd in "${essential_cmds[@]}"; do
    # Ignora checagem se o comando estiver vazio (python/pip não encontrados)
    if [[ -n "$cmd" ]] && ! command_exists "$cmd"; then
        missing_essential+="$cmd "
    fi
done
if [[ -n "$missing_essential" ]]; then
    echo >&2 "ERRO FATAL: Comandos essenciais não encontrados: $missing_essential. Instale-os e tente novamente."
    exit 1
fi
if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3) )); then
     echo >&2 "ERRO FATAL: Bash 4.3+ é necessário para esta versão do script (devido a namerefs). Versão atual: $BASH_VERSION";
     exit 1;
fi

TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
TIMESTAMP_DIR="$OUTPUT_BASE_DIR/$TIMESTAMP"

echo "Criando diretório de saída: $TIMESTAMP_DIR"
mkdir -p "$TIMESTAMP_DIR" || { echo >&2 "ERRO FATAL: Não foi possível criar o diretório de saída '$TIMESTAMP_DIR'. Verifique as permissões."; exit 1; }

# --- Coleta de Informações do Ambiente ---
echo "[1/$TOTAL_STEPS] Coletando informações do Ambiente (SO)..."
echo "  Coletando informações do sistema (uname)..."
uname -a > "$TIMESTAMP_DIR/env_uname.txt" 2>/dev/null || echo "Falha ao executar uname" > "$TIMESTAMP_DIR/env_uname.txt"

echo "  Coletando informações da distribuição Linux..."
if command_exists lsb_release; then
    lsb_release -a > "$TIMESTAMP_DIR/env_distro_info.txt" 2>&1
elif [ -f /etc/os-release ]; then
    cat /etc/os-release > "$TIMESTAMP_DIR/env_distro_info.txt" 2>&1
elif [ -f /etc/debian_version ]; then
    echo "Debian $(cat /etc/debian_version)" > "$TIMESTAMP_DIR/env_distro_info.txt"
elif [ -f /etc/redhat-release ]; then
    cat /etc/redhat-release > "$TIMESTAMP_DIR/env_distro_info.txt"
else
    echo "Não foi possível determinar a distribuição Linux automaticamente." > "$TIMESTAMP_DIR/env_distro_info.txt"
fi

# --- Coleta de Informações do Ambiente Python ---
echo "[2/$TOTAL_STEPS] Coletando informações do Ambiente Python..."
if [[ -n "$PYTHON_CMD" ]]; then
    echo "  Coletando versão do Python ($PYTHON_CMD)..."
    "$PYTHON_CMD" --version > "$TIMESTAMP_DIR/env_python_version.txt" 2>&1 || echo "Falha ao obter versão do Python ($PYTHON_CMD)." > "$TIMESTAMP_DIR/env_python_version.txt"
    echo "  Verificando localização do Python ($PYTHON_CMD)..."
    which "$PYTHON_CMD" > "$TIMESTAMP_DIR/env_python_which.txt" 2>&1 || echo "Falha ao localizar Python ($PYTHON_CMD)." > "$TIMESTAMP_DIR/env_python_which.txt"
else
    suggest_install "python3 ou python" "python3"
    echo "Python não encontrado." > "$TIMESTAMP_DIR/env_python_version.txt"
    echo "Python não encontrado." > "$TIMESTAMP_DIR/env_python_which.txt"
fi

if [[ -n "$PIP_CMD" ]]; then
    echo "  Coletando versão do Pip ($PIP_CMD)..."
    "$PIP_CMD" --version > "$TIMESTAMP_DIR/env_pip_version.txt" 2>&1 || echo "Falha ao obter versão do Pip ($PIP_CMD)." > "$TIMESTAMP_DIR/env_pip_version.txt"
else
    suggest_install "pip3 ou pip" "python3-pip"
    echo "Pip não encontrado." > "$TIMESTAMP_DIR/env_pip_version.txt"
fi

echo "  Verificando se um ambiente virtual Python está ativo..."
if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "Ambiente virtual Python ATIVO: $VIRTUAL_ENV" > "$TIMESTAMP_DIR/env_python_venv_status.txt"
else
    echo "Nenhum ambiente virtual Python detectado (variável VIRTUAL_ENV não definida)." > "$TIMESTAMP_DIR/env_python_venv_status.txt"
fi

echo "  Coletando arquivos de gerenciamento de pacotes Python (se existirem)..."
for pkg_file in requirements.txt requirements-dev.txt Pipfile pyproject.toml; do
    if [[ -f "$pkg_file" ]]; then
        echo "    Capturando $pkg_file..."
        cat "$pkg_file" > "$TIMESTAMP_DIR/env_python_pkgfile_${pkg_file//\//_}" 2>/dev/null || echo "Erro ao ler $pkg_file" > "$TIMESTAMP_DIR/env_python_pkgfile_${pkg_file//\//_}"
    else
         echo "    Arquivo $pkg_file não encontrado." # Não cria arquivo se não existe
    fi
done

echo "  Listando pacotes Pip instalados (ambiente ativo)..."
if [[ -n "$PIP_CMD" ]]; then
    "$PIP_CMD" freeze > "$TIMESTAMP_DIR/env_pip_freeze.txt" 2>&1 || echo "Falha ao executar '$PIP_CMD freeze'. Verifique o ambiente Python." > "$TIMESTAMP_DIR/env_pip_freeze.txt"
else
    echo "Pip não encontrado." > "$TIMESTAMP_DIR/env_pip_freeze.txt"
fi


# --- Coleta de Informações do Git ---
echo "[3/$TOTAL_STEPS] Coletando informações do Git..."
# Git já verificado como essencial
echo "  Gerando git log..."
git log --pretty=format:"commit %H%nAuthor: %an <%ae>%nDate:   %ad%n%n%w(0,4)%s%n%n%w(0,4,4)%b%n" > "$TIMESTAMP_DIR/git_log.txt" 2>/dev/null || echo "Falha ao gerar git log" > "$TIMESTAMP_DIR/git_log.txt"
echo "  Gerando git diff (Empty Tree -> HEAD)..."
git diff "$EMPTY_TREE_COMMIT"..HEAD > "$TIMESTAMP_DIR/git_diff_empty_tree_to_head.txt" 2>/dev/null || echo "Falha ao gerar git diff (empty tree)" > "$TIMESTAMP_DIR/git_diff_empty_tree_to_head.txt"
echo "  Gerando git diff (--cached)..."
git diff --cached > "$TIMESTAMP_DIR/git_diff_cached.txt" 2>/dev/null || echo "Nenhuma alteração no stage ou falha." > "$TIMESTAMP_DIR/git_diff_cached.txt"
echo "  Gerando git diff (unstaged)..."
git diff > "$TIMESTAMP_DIR/git_diff_unstaged.txt" 2>/dev/null || echo "Nenhuma alteração unstaged ou falha." > "$TIMESTAMP_DIR/git_diff_unstaged.txt"
echo "  Gerando git status..."
git status > "$TIMESTAMP_DIR/git_status.txt" 2>/dev/null || echo "Falha ao gerar git status" > "$TIMESTAMP_DIR/git_status.txt"
echo "  Listando arquivos rastreados pelo Git..."
git ls-files > "$TIMESTAMP_DIR/git_ls_files.txt" 2>/dev/null || echo "Falha ao executar git ls-files" > "$TIMESTAMP_DIR/git_ls_files.txt"
echo "  Listando tags Git recentes..."
git tag --sort=-creatordate | head -n "$GIT_TAG_LIMIT" > "$TIMESTAMP_DIR/git_recent_tags.txt" 2>/dev/null || echo "Nenhuma tag encontrada ou falha ao listar tags." > "$TIMESTAMP_DIR/git_recent_tags.txt"

# --- Coleta de Informações Adicionais do GitHub ---
echo "[4/$TOTAL_STEPS] Coletando contexto adicional do GitHub (Repo, Actions, Security)..."
if ! command_exists gh; then
    suggest_install "gh" "gh"
    echo "  AVISO: Comando 'gh' não encontrado. Pulando esta seção."
else
    if ! command_exists jq; then
        suggest_install "jq"
        echo "  AVISO: Comando 'jq' não encontrado. Coleta de issues e processamento de project items será pulada/limitada."
    fi
    echo "  Listando execuções recentes do GitHub Actions (limite $GH_RUN_LIST_LIMIT)..."
    gh run list --limit "$GH_RUN_LIST_LIMIT" > "$TIMESTAMP_DIR/gh_run_list.txt" 2>&1 || echo "Falha ao listar runs do Actions (verifique login/permissões/habilitação)." > "$TIMESTAMP_DIR/gh_run_list.txt"
    echo "  Listando workflows do GitHub Actions..."
    gh workflow list > "$TIMESTAMP_DIR/gh_workflow_list.txt" 2>&1 || echo "Falha ao listar workflows." > "$TIMESTAMP_DIR/gh_workflow_list.txt"
    echo "  Listando Pull Requests recentes (limite $GH_PR_LIST_LIMIT)..."
    gh pr list --state all --limit "$GH_PR_LIST_LIMIT" > "$TIMESTAMP_DIR/gh_pr_list.txt" 2>&1 || echo "Falha ao listar Pull Requests." > "$TIMESTAMP_DIR/gh_pr_list.txt"
    echo "  Listando Releases recentes (limite $GH_RELEASE_LIST_LIMIT)..."
    gh release list --limit "$GH_RELEASE_LIST_LIMIT" > "$TIMESTAMP_DIR/gh_release_list.txt" 2>&1 || echo "Falha ao listar Releases (ou nenhuma encontrada)." > "$TIMESTAMP_DIR/gh_release_list.txt"
    echo "  Listando nomes de Secrets do GitHub (requer permissão)..."
    gh secret list > "$TIMESTAMP_DIR/gh_secret_list.txt" 2>&1 || echo "Falha ao listar Secrets (verifique permissões admin/owner)." > "$TIMESTAMP_DIR/gh_secret_list.txt"
    echo "  Listando nomes de Variables do GitHub (requer permissão)..."
    gh variable list > "$TIMESTAMP_DIR/gh_variable_list.txt" 2>&1 || echo "Falha ao listar Variables (verifique permissões)." > "$TIMESTAMP_DIR/gh_variable_list.txt"
    echo "  Coletando visão geral do repositório GitHub..."
    gh repo view > "$TIMESTAMP_DIR/gh_repo_view.txt" 2>&1 || echo "Falha ao obter informações do repositório." > "$TIMESTAMP_DIR/gh_repo_view.txt"
    echo "  Listando Rulesets (requer permissão)..."
    gh ruleset list > "$TIMESTAMP_DIR/gh_ruleset_list.txt" 2>&1 || echo "Falha ao listar Rulesets (verifique permissões/versão gh)." > "$TIMESTAMP_DIR/gh_ruleset_list.txt"
    echo "  Listando alertas do Code Scanning (requer permissão/GHAS)..."
    gh code-scanning alert list > "$TIMESTAMP_DIR/gh_codescanning_alert_list.txt" 2>&1 || echo "Falha ao listar alertas Code Scanning (verifique permissões/GHAS)." > "$TIMESTAMP_DIR/gh_codescanning_alert_list.txt"
    echo "  Listando alertas do Dependabot (requer permissão/Dependabot)..."
    gh dependabot alert list > "$TIMESTAMP_DIR/gh_dependabot_alert_list.txt" 2>&1 || echo "Falha ao listar alertas Dependabot (verifique permissões/Dependabot)." > "$TIMESTAMP_DIR/gh_dependabot_alert_list.txt"
fi

# --- Coleta de Status do GitHub Project ---
echo "[5/$TOTAL_STEPS] Coletando Status do GitHub Project..."
if ! command_exists gh; then
    echo "  AVISO: Comando 'gh' não encontrado. Pulando esta seção."
    echo "gh não encontrado." > "$TIMESTAMP_DIR/gh_project_items_status.log"
elif [[ -z "$GH_PROJECT_NUMBER" || -z "$GH_PROJECT_OWNER" ]]; then
    echo "  AVISO: GH_PROJECT_NUMBER ou GH_PROJECT_OWNER não definidos no script. Pulando esta seção."
    echo "GH_PROJECT_NUMBER ou GH_PROJECT_OWNER não definidos." > "$TIMESTAMP_DIR/gh_project_items_status.log"
else
    echo "  Coletando itens do Projeto #$GH_PROJECT_NUMBER (Owner: $GH_PROJECT_OWNER)..."
    gh project item-list "$GH_PROJECT_NUMBER" --owner "$GH_PROJECT_OWNER" --format json > "$TIMESTAMP_DIR/gh_project_items_status.json" 2>"$TIMESTAMP_DIR/gh_project_items_status.error.log"
    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "  ERRO: Falha ao coletar itens do projeto (Código: $exit_code). Veja gh_project_items_status.error.log."
        # Mantém o arquivo JSON vazio ou incompleto e o arquivo de erro
    else
        echo "  Itens do projeto coletados em gh_project_items_status.json."
        rm -f "$TIMESTAMP_DIR/gh_project_items_status.error.log" # Remove arquivo de erro se sucesso

        if command_exists jq; then
            echo "  Gerando resumo de status dos itens (usando jq e campo '$GH_PROJECT_STATUS_FIELD_NAME')..."
            # Nota: O // "N/A" é um fallback caso o item não tenha o campo de status.
            jq --arg status_field_name "$GH_PROJECT_STATUS_FIELD_NAME" \
               '[ .items[] | { type: .type, number: .content.number, title: .content.title, status: (.fieldValues[] | select(.field.name == $status_field_name) | .value // "N/A") } ]' \
               "$TIMESTAMP_DIR/gh_project_items_status.json" > "$TIMESTAMP_DIR/gh_project_items_summary.json" 2>"$TIMESTAMP_DIR/gh_project_items_summary.error.log"

           if [[ $? -eq 0 ]]; then
               echo "  Resumo gerado em gh_project_items_summary.json."
               rm -f "$TIMESTAMP_DIR/gh_project_items_summary.error.log"
           else
               echo "  ERRO: Falha ao processar JSON com jq. Veja gh_project_items_summary.error.log."
               echo "jq falhou ao processar gh_project_items_status.json" > "$TIMESTAMP_DIR/gh_project_items_summary.json" # Sobrescreve com erro
           fi
        else
            echo "  AVISO: 'jq' não encontrado. Não foi possível gerar o resumo gh_project_items_summary.json."
            echo "jq não encontrado para gerar resumo." > "$TIMESTAMP_DIR/gh_project_items_summary.txt" # Cria arquivo txt indicando ausência
        fi
    fi
fi


# --- Coleta de Estrutura do Projeto ---
echo "[6/$TOTAL_STEPS] Coletando informações da Estrutura do Projeto..."
echo "  Gerando árvore de diretórios (nível $TREE_DEPTH)..."
if command_exists tree; then
    tree -L "$TREE_DEPTH" -a -I "$TREE_IGNORE_PATTERN" > "$TIMESTAMP_DIR/project_tree_L${TREE_DEPTH}.txt" || echo "Erro ao gerar tree (verifique permissões ou profundidade)." > "$TIMESTAMP_DIR/project_tree_L${TREE_DEPTH}.txt"
else
    suggest_install "tree"
    echo "Comando 'tree' não encontrado. Listando diretórios de nível 1..." > "$TIMESTAMP_DIR/project_tree_L${TREE_DEPTH}.txt"
    ls -Ap1 > "$TIMESTAMP_DIR/project_toplevel_dirs.txt" 2>/dev/null || echo "Falha ao executar ls." >> "$TIMESTAMP_DIR/project_tree_L${TREE_DEPTH}.txt"
fi
echo "  Contando linhas de código (cloc)..."
if command_exists cloc; then
    # Usar --fullpath para caminhos completos e --not-match-d para excluir diretórios por regex
    cloc . --fullpath --not-match-d="${CLOC_EXCLUDE_REGEX}" > "$TIMESTAMP_DIR/project_cloc.txt" 2>&1 || echo "Falha ao executar cloc." > "$TIMESTAMP_DIR/project_cloc.txt"
else
    suggest_install "cloc" "cloc" # O pacote geralmente se chama 'cloc'
    echo "Comando 'cloc' não encontrado. Pulando contagem de linhas." > "$TIMESTAMP_DIR/project_cloc.txt"
fi

# --- Coleta de Planos e Meta-Prompts ---
echo "[7/$TOTAL_STEPS] Coletando Planos e Meta-Prompts..."
if [ -d "planos" ]; then
    echo "  Copiando arquivos de 'planos/'..."
    find planos -maxdepth 1 -type f -name '*.txt' -exec cp {} "$TIMESTAMP_DIR/" \; 2>/dev/null || echo "  Falha ao copiar planos ou diretório 'planos' vazio/não existe."
else
    echo "  Diretório 'planos/' não encontrado."
fi
if [ -d "project_templates/meta-prompts" ]; then
    echo "  Copiando arquivos de 'project_templates/meta-prompts/'..."
    find project_templates/meta-prompts -maxdepth 1 -type f -name '*.txt' -exec cp {} "$TIMESTAMP_DIR/" \; 2>/dev/null || echo "  Falha ao copiar meta-prompts ou diretório vazio/não existe."
else
     echo "  Diretório 'project_templates/meta-prompts/' não encontrado."
fi

# --- Coleta de Informações do GitHub Issues ---
echo "[8/$TOTAL_STEPS] Coletando informações das Issues do GitHub..."
if ! command_exists gh || ! command_exists jq; then
    echo "  AVISO: Comando 'gh' ou 'jq' não encontrado. Pulando coleta de issues."
    echo "gh ou jq não encontrado." > "$TIMESTAMP_DIR/github_issues_skipped.log"
else
    echo "  Issues serão salvas em: $TIMESTAMP_DIR"
    echo "  Listando e filtrando issues (limite: $GH_ISSUE_LIST_LIMIT, excluindo 'Closed as not planned')..."
    # Primeiro, tenta obter a lista de números de issues abertas e fechadas (exceto 'not planned')
    issue_numbers_json=$(gh issue list --state all --limit "$GH_ISSUE_LIST_LIMIT" --json number,stateReason -q 'map(select(.stateReason != "NOT_PLANNED")) | [.[].number]')
    if [[ $? -ne 0 || -z "$issue_numbers_json" || "$issue_numbers_json" == "[]" ]]; then
        echo "  AVISO: Não foi possível obter a lista de issues do GitHub (verifique login/permissões) ou nenhuma issue encontrada (após filtro)."
        echo '{ "message": "Nenhuma issue encontrada (após filtrar) ou erro ao listar." }' > "$TIMESTAMP_DIR/no_issues_found.json"
    else
         # Processa cada número de issue encontrado
         echo "$issue_numbers_json" | jq -c '.[]' | while IFS= read -r issue_number; do
            if [[ -n "$issue_number" ]]; then
                echo "    Coletando detalhes da Issue #$issue_number..."
                issue_output_file="$TIMESTAMP_DIR/github_issue_${issue_number}_details.json"
                issue_error_file="$TIMESTAMP_DIR/github_issue_${issue_number}_error.log"

                gh issue view "$issue_number" --json "$GH_ISSUE_JSON_FIELDS" > "$issue_output_file" 2>"$issue_error_file"
                exit_code=$?
                if [[ $exit_code -ne 0 ]]; then
                     echo "    AVISO: Falha ao coletar detalhes da Issue #$issue_number (Código: $exit_code). Verifique $issue_error_file."
                     # Se falhou, remove o arquivo JSON potencialmente vazio/incompleto
                     rm -f "$issue_output_file"
                fi
                # Remove o arquivo de erro se estiver vazio
                if [ -f "$issue_error_file" ] && [ ! -s "$issue_error_file" ]; then
                    rm "$issue_error_file"
                fi
                sleep 0.2 # Pequena pausa para evitar rate limiting
            fi
        done

        # Verifica se algum arquivo de issue foi realmente criado
        if ! find "$TIMESTAMP_DIR" -maxdepth 1 -name 'github_issue_*_details.json' -print -quit > /dev/null 2>&1; then
             echo "  Nenhuma issue pôde ser baixada (verifique permissões/filtros)."
             echo '{ "message": "Nenhuma issue encontrada (após filtrar) ou baixada." }' > "$TIMESTAMP_DIR/no_issues_found.json"
        else
             echo "  Coleta de issues filtradas concluída."
        fi
    fi
fi


# --- Execução das Ferramentas de Qualidade Python ---
echo "[9/$TOTAL_STEPS] Executando análise de qualidade do código Python (Black, Flake8, MyPy)..."

# Black (Check + Diff)
echo "  Verificando formatação com Black..."
BLACK_OUTPUT_FILE="$TIMESTAMP_DIR/python_black_check.txt"
if command_exists black; then
    echo "    Executando: black --check --diff ."
    black --check --diff . > "$BLACK_OUTPUT_FILE" 2>&1
    BLACK_EXIT_CODE=$?
    if [ $BLACK_EXIT_CODE -eq 0 ]; then
        echo "    Verificação Black concluída (Sem problemas encontrados - código 0)."
    elif [ $BLACK_EXIT_CODE -eq 1 ]; then
         echo "    AVISO: Black encontrou problemas de formatação (Código: 1). Veja $BLACK_OUTPUT_FILE para o diff."
         echo "\n\n--- Black Exit Code: $BLACK_EXIT_CODE ---" >> "$BLACK_OUTPUT_FILE"
    else
         echo "    ERRO: Black falhou na execução (Código: $BLACK_EXIT_CODE). Veja $BLACK_OUTPUT_FILE."
         echo "\n\n--- Black Exit Code: $BLACK_EXIT_CODE ---" >> "$BLACK_OUTPUT_FILE"
    fi
else
    suggest_install "black" "black"
    echo "    Black não encontrado. Pulando verificação de formatação." > "$BLACK_OUTPUT_FILE"
fi

# Flake8
echo "  Verificando linting com Flake8..."
FLAKE8_OUTPUT_FILE="$TIMESTAMP_DIR/python_flake8_lint.txt"
if command_exists flake8; then
    echo "    Executando: flake8 ."
    flake8 . > "$FLAKE8_OUTPUT_FILE" 2>&1
    FLAKE8_EXIT_CODE=$?
    # Flake8 retorna 0 mesmo se encontrar erros, então verificamos o conteúdo
    if [ $FLAKE8_EXIT_CODE -ne 0 ] || [ -s "$FLAKE8_OUTPUT_FILE" ]; then
        echo "  AVISO: Flake8 encontrou problemas de linting ou falhou (Código: $FLAKE8_EXIT_CODE). Veja $FLAKE8_OUTPUT_FILE."
        echo "\n\n--- Flake8 Exit Code: $FLAKE8_EXIT_CODE ---" >> "$FLAKE8_OUTPUT_FILE"
    else
        echo "    Verificação Flake8 concluída (Sem problemas encontrados)."
        echo "Flake8 não encontrou problemas." > "$FLAKE8_OUTPUT_FILE" # Coloca msg no arquivo se vazio
    fi
else
    suggest_install "flake8" "flake8"
    echo "    Flake8 não encontrado. Pulando linting." > "$FLAKE8_OUTPUT_FILE"
fi

# MyPy
echo "  Verificando tipos com MyPy..."
MYPY_OUTPUT_FILE="$TIMESTAMP_DIR/python_mypy_types.txt"
if command_exists mypy; then
    echo "    Executando: mypy ."
    # MyPy pode ser lento, avisa o usuário
    echo "    (MyPy pode levar algum tempo...)"
    mypy . --ignore-missing-imports > "$MYPY_OUTPUT_FILE" 2>&1 # Adiciona ignore-missing-imports para focar nos erros do projeto
    MYPY_EXIT_CODE=$?
    if [ $MYPY_EXIT_CODE -eq 0 ]; then
        echo "    Verificação MyPy concluída (Sem erros de tipo encontrados - código 0)."
    else
        echo "  AVISO: MyPy encontrou erros de tipo ou falhou (Código: $MYPY_EXIT_CODE). Veja $MYPY_OUTPUT_FILE."
        echo "\n\n--- MyPy Exit Code: $MYPY_EXIT_CODE ---" >> "$MYPY_OUTPUT_FILE"
    fi
else
    suggest_install "mypy" "mypy"
    echo "    MyPy não encontrado. Pulando verificação de tipos." > "$MYPY_OUTPUT_FILE"
fi

# --- Coleta de Arquivos de Configuração Relevantes ---
echo "[10/$TOTAL_STEPS] Coletando arquivos de configuração relevantes..."
config_files_to_copy=(
    ".editorconfig"
    ".gitignore"
    "Pipfile"
    "Pipfile.lock"
    "pyproject.toml"
    "mypy.ini"
    ".flake8"
    # Adicione outros arquivos de config específicos do Python/Streamlit aqui, se houver
    # Ex: "streamlit_config.toml" (se existir)
)
for config_file in "${config_files_to_copy[@]}"; do
    if [[ -f "$config_file" ]]; then
        echo "  Copiando $config_file..."
        cp "$config_file" "$TIMESTAMP_DIR/config_${config_file//\//_}" 2>/dev/null || echo "    Erro ao copiar $config_file"
    else
        echo "  Arquivo de configuração '$config_file' não encontrado."
    fi
done


# --- Geração do arquivo de manifesto ---
echo "[11/$TOTAL_STEPS] Gerando arquivo de manifesto..."
{
    echo "# Manifesto de Contexto - Gerado por gerar_contexto_llm.sh v3.0 (Python Adaptation)"
    echo "Timestamp: $TIMESTAMP"
    echo "Diretório: $TIMESTAMP_DIR"
    echo ""
    echo "## Conteúdo Coletado:"
    find "$TIMESTAMP_DIR" -maxdepth 1 -type f -printf " - %f\\n" | sort
    echo ""
    echo "## Notas:"
    echo "- Revise os arquivos individuais para o contexto detalhado."
    echo "- 'python_black_check.txt', 'python_flake8_lint.txt', 'python_mypy_types.txt' contêm resultados das ferramentas de qualidade Python."
    # echo "- 'phpunit_test_results.txt' foi removido; adicione resultados de 'pytest' se testes forem implementados."
    echo "- O status dos itens no GitHub Project (se configurado e acessível) está em 'gh_project_items_*.json'."
    echo "- Alguns comandos podem ter falhado (verifique arquivos com mensagens de erro)."
    echo "- A completude depende das ferramentas disponíveis (python, pip, git, gh, jq, tree, cloc, black, flake8, mypy) e permissões."
} > "$TIMESTAMP_DIR/manifest.md"


# --- Finalização ---
echo ""
echo "-----------------------------------------------------"
echo "Coleta de contexto (Python) para LLM concluída!"
echo "Arquivos salvos em: $TIMESTAMP_DIR"
echo "Consulte '$TIMESTAMP_DIR/manifest.md' para um resumo dos arquivos gerados."
echo "Use os arquivos neste diretório como contexto."
echo "-----------------------------------------------------"

exit 0