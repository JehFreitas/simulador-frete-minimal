# Guia de Estratégia de Desenvolvimento - Simulador Frete Minimal

**Versão:** 0.1.0
**Data:** 2025-04-18

## 1. Introdução

### 1.1. Propósito deste Guia

Este documento serve como o guia oficial de desenvolvimento para o projeto **simulador-frete-minimal**. Ele detalha a metodologia, as ferramentas e as práticas recomendadas para garantir um desenvolvimento consistente, rastreável e de alta qualidade, mesmo para um projeto de escopo minimalista ou com desenvolvimento individual.

### 1.2. Público-Alvo

Este guia destina-se a qualquer pessoa envolvida no desenvolvimento ou manutenção deste projeto, incluindo o desenvolvedor principal e potenciais futuros colaboradores.

### 1.3. Importância da Organização e do Processo

Adotar um processo estruturado, mesmo em projetos menores ou solo, é fundamental para:

*   **Manter a clareza:** Saber o que precisa ser feito e o que está em andamento.
*   **Garantir a qualidade:** Facilitar a revisão (mesmo auto-revisão) e a detecção de problemas.
*   **Melhorar a manutenibilidade:** Criar um histórico de código compreensível.
*   **Aumentar a produtividade:** Reduzir a sobrecarga cognitiva.

## 2. Visão Geral da Metodologia Adotada

Adotamos uma metodologia leve e iterativa, baseada em boas práticas de Git e GitHub, focada na rastreabilidade e na organização, mesmo para desenvolvimento individual.

### 2.1. Filosofia Central: Issues Atômicas e Commits Atômicos

A organização do trabalho gira em torno de dois conceitos chave:

*   **Issues Atômicas:** Toda unidade de trabalho (bug, feature, melhoria, tarefa técnica) **DEVE** ser representada por uma **Issue do GitHub**. A Issue deve ser focada, bem descrita e ter critérios de aceite claros. Templates são fornecidos em `templates/issue_bodies/`.
*   **Commits Atômicos:** Cada `git commit` **DEVE** representar a **menor unidade lógica de trabalho concluído** que contribui para resolver uma Issue. Commits devem ser frequentes, focados e referenciar a Issue correspondente.

### 2.2. Rastreabilidade (Commit <> Issue <> PR)

Manter um vínculo claro entre o código (Commits), a tarefa (Issue) e o processo de integração (Pull Request, mesmo que auto-mergeado) é essencial para entender o histórico e a evolução do projeto.

## 3. Ferramentas Essenciais

Para contribuir com este projeto, as seguintes ferramentas são necessárias ou recomendadas:

*   **Git:** Sistema de controle de versão. Essencial.
*   **Python:** Versão **3.10.10** (conforme `env_python_version.txt`). Essencial.
*   **Pip:** Versão **23.0.1** (conforme `env_pip_version.txt`). Essencial para gerenciamento de dependências.
*   **Streamlit:** Framework principal da aplicação (`simulador_frete.py`, `devcontainer.json`). Essencial.
*   **GitHub CLI (`gh`):** Usada para interagir com o GitHub via linha de comando, especialmente pelos scripts de automação (`scripts/create_issue.py`). Recomendado.
*   **(Recomendado) Ferramentas de Qualidade:** Conforme definido em `doc/padroes_codigo_boas_praticas.md`:
    *   **Black:** Para formatação automática de código Python.
    *   **Flake8:** Para linting e detecção de erros de estilo/lógica.
    *   **MyPy:** Para verificação estática de tipos (type hints).
    *(Nota: No momento da coleta de contexto, essas ferramentas não foram encontradas, mas são recomendadas para manter a qualidade).*

## 4. Ciclo de Vida Detalhado do Desenvolvimento

### 4.1. Criação e Detalhamento de Issues

*   **Origem:** Todas as tarefas começam como uma Issue no GitHub.
*   **Templates:** **SEMPRE** utilize os templates em `templates/issue_bodies/` ao criar Issues:
    *   `bug_body.md`: Para bugs.
    *   `feature_body.md`: Para novas funcionalidades.
    *   `chore_body.md`: Para tarefas técnicas, refatorações, etc.
    *   `test_body.md`: Para criação de testes.
*   **Conteúdo da Issue:**
    *   **Título:** Claro e descritivo.
    *   **Descrição:** Detalhada, explicando o *quê* e o *porquê*. Use o template como guia.
    *   **Critérios de Aceite (AC):** **OBRIGATÓRIO.** Defina pontos claros e verificáveis (`- [ ]`) que indicam quando a Issue está concluída.
    *   **Labels:** Use para categorizar (`bug`, `feature`, `chore`, `test`, `documentation`, `devtools`, etc.).
    *   **Assignee:** Atribua a si mesmo (`@me`) quando começar a trabalhar.
    *   **(Opcional) Milestone/Project:** Use para agrupar Issues relacionadas.
*   **(Opcional) Automação:** O script `scripts/create_issue.py` pode ser usado para criar Issues a partir de arquivos de plano estruturados (ver `planos/`).

### 4.2. Desenvolvimento (Branching e Committing)

1.  **Criar Branch:** Antes de codificar, crie um branch a partir do branch principal (`main` ou `develop`) usando uma convenção clara. Com base no histórico recente (`git_log.txt` e `git_status.txt`), o padrão sugerido é:
    *   `feature/<descrição-curta>` (ex: `feature/calcular-impostos-complexos`)
    *   `fix/<descrição-curta>` (ex: `fix/erro-calculo-ipi`)
    *   `chore/<descrição-curta>` (ex: `chore/atualizar-dependencias`)
    *   `doc/<descrição-curta>` (ex: `doc/atualizar-guia-dev`)
    *   `test/<descrição-curta>` (ex: `test/adicionar-testes-calculo-nf`)
    *   *(Opcional, mas recomendado: incluir ID da issue no nome do branch, ex: `feature/45-calcular-impostos`)*
2.  **Implementar:** Codifique a solução focada nos Critérios de Aceite da Issue. Siga **OBRIGATORIAMENTE** os padrões definidos em `doc/padroes_codigo_boas_praticas.md`.
3.  **Commits Atômicos:** Faça commits pequenos, lógicos e frequentes.
4.  **Mensagens de Commit:** **OBRIGATÓRIO** seguir o estilo encontrado em `git_log.txt`.
    *   **Formato:**
        ```
        <tipo>: <Descrição concisa no imperativo>

        [Corpo opcional explicando o 'porquê' e detalhes relevantes.
        Pode ter múltiplos parágrafos.]

        [Pode incluir listas:
        - Alteração 1
        - Alteração 2]

        [Rodapé Opcional: Ex: Refs #<ID_Issue_Relacionada>, BREAKING CHANGE: ...]
        ```
    *   **Tipos Comuns (deduzidos do log):** `feat`, `fix`, `chore`, `doc`, `test`, `refactor`.
    *   **Referência à Issue:** **RECOMENDÁVEL** incluir uma referência clara à Issue principal no corpo ou rodapé (ex: `Refs #<ID>` ou `Relacionado a #<ID>`), embora o log atual não mostre essa prática consistentemente.
    *   **Exemplo (Baseado no Log):**
        ```
        feat: Adiciona cálculo de frete baseado em regras complexas

        Implementa a lógica para determinar o valor do frete
        considerando estado de destino, tipo de cidade (capital/interior)
        e horário de entrega, conforme tabelas fornecidas.

        - Usa a tabela TABELA_SALIS para taxas base.
        - Aplica multiplicador de carga tributária.

        Refs #45
        ```
    *   **(Opcional) Automação:** O script `scripts/llm_interact.py commit-mesage -i <ID>` pode auxiliar na geração da mensagem, mas **SEMPRE revise** e ajuste para garantir conformidade com o estilo do projeto.

### 4.3. Pull Requests (PRs) - Recomendado

Mesmo para desenvolvimento individual, criar um Pull Request (PR) antes de integrar ao branch principal é uma **boa prática**.

*   **Propósito:** Facilita a auto-revisão, mantém um registro da integração e pode disparar verificações de CI/CD.
*   **Criação:** Após finalizar o desenvolvimento no branch e fazer push: `gh pr create --fill` (ou via interface web).
*   **Conteúdo do PR:**
    *   **Título:** Claro, relacionado à Issue (ex: `feat: Implementa cálculo de frete complexo #45`).
    *   **Descrição:** Resumo das mudanças. **OBRIGATÓRIO** usar `Closes #<ID>` para vincular e fechar a Issue no merge.
    *   **(Opcional) Automação:** `scripts/llm_interact.py create-pr -i <ID>` pode gerar título/corpo e criar o PR. **REVISE** o conteúdo gerado.

### 4.4. Revisão e Merge

1.  **Auto-Revisão:** Revise seu próprio PR no GitHub. Verifique o diff, os critérios de aceite e os padrões de código.
2.  **(Opcional) CI:** Se houver Actions configuradas, aguarde a passagem das verificações (testes, linting, etc.).
3.  **Merge:** Faça o merge do PR no branch principal (ex: `main`). Use "Squash and merge" ou "Rebase and merge" se preferir um histórico linear no branch principal.
4.  **Limpeza:** Exclua o branch da feature local e remotamente (`git branch -d feature/...`, `git push origin --delete feature/...`).

## 5. Padrões de Código e Boas Práticas

A fonte **única e autoritativa** para padrões de codificação, estilo, nomenclatura e boas práticas Python/Streamlit neste projeto é o documento:

**`doc/padroes_codigo_boas_praticas.md`**

**NÃO REPITA** as regras aqui. Consulte o documento específico para todos os detalhes. A aderência a esses padrões é **OBRIGATÓRIA**.

## 6. Gerenciamento de Dependências

*   **Método:** O gerenciamento de dependências Python **DEVE** ser feito através de um arquivo `requirements.txt`. (Inferido da configuração do `devcontainer.json` e prática padrão).
*   **Atualização:** Ao adicionar ou atualizar uma dependência, atualize o `requirements.txt` e faça commit do arquivo. Use `pip freeze > requirements.txt` (dentro de um ambiente virtual, se usado) para gerar/atualizar.
*   **Ambiente Virtual:** É **ALTAMENTE RECOMENDÁVEL** usar um ambiente virtual Python (como `venv` ou `conda`) para isolar as dependências do projeto.

## 7. Documentação do Projeto

*   **README.md:** Visão geral do projeto, como configurar e executar.
*   **`doc/guia_desenvolvimento.md` (este guia):** Define o fluxo de trabalho.
*   **`doc/padroes_codigo_boas_praticas.md`:** Define os padrões de código.
*   **`doc/plano_de_acao.md`:** Descreve os próximos passos planejados.
*   **Atualização:** A documentação **DEVE** ser mantida atualizada. Mudanças significativas no processo, padrões ou arquitetura requerem atualização dos documentos relevantes. Trate atualizações de documentação como tarefas normais (Issues, Commits, PRs).

## 8. Ferramentas de Automação (`scripts/`)

O diretório `scripts/` contém ferramentas para auxiliar no desenvolvimento:

*   **`create_issue.py`:** Script Python para criar ou editar Issues no GitHub a partir de arquivos de plano estruturados (em `planos/`), utilizando os templates de corpo de issue (`templates/issue_bodies/`). Ajuda a agilizar a criação em lote de tarefas planejadas.
*   **`llm_interact.py`:** Script Python para interagir com a API do Google Gemini. Utiliza meta-prompts (`templates/meta-prompts/`) e o contexto do projeto (gerado por `generate_context.sh`) para auxiliar em tarefas como:
    *   Gerar código para resolver um AC (`resolve-ac`).
    *   Sugerir mensagens de commit (`commit-mesage`).
    *   Analisar o atendimento de um AC (`analyze-ac`).
    *   Atualizar documentação (`update-doc`).
    *   Gerar título/corpo de PR e criá-lo (`create-pr`).
*   **`update_project.py`:** Script Python auxiliar (provavelmente usado por `llm_interact.py`) para aplicar atualizações de código/documentação geradas pela IA nos arquivos locais do projeto, baseado em um formato delimitado (`--- START/END OF FILE ...`).
*   **`generate_context.sh`:** Script Shell (invocado por `llm_interact.py -g`) para coletar um contexto abrangente do estado atual do projeto (Git, código, ambiente, etc.) e salvá-lo em `context_llm/code/<timestamp>/` para ser usado pelo `llm_interact.py`.

Consulte os scripts individuais ou seus meta-prompts associados para entender melhor seu uso e opções.