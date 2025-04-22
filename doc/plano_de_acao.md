**Plano de Ação de Alto Nível: Migração das Macros para Python**

**Fase 0: Preparação e Configuração do Ambiente (Baseado nas Boas Práticas)**

1.  **Instalar Ferramentas de Qualidade:**
    *   Instalar `black`, `flake8`, `mypy` e `pytest` no ambiente de desenvolvimento (idealmente usando um `requirements-dev.txt` ou gerenciador como `poetry`/`pipenv`).
    *   Configurar as ferramentas (ex: `pyproject.toml` para Black, Flake8, MyPy) para garantir consistência.
2.  **Criar Estrutura de Testes:**
    *   Criar um diretório `tests/`.
    *   Adicionar um arquivo de configuração básico para `pytest` (se necessário).
3.  **Gerenciamento de Dependências:**
    *   Criar/Atualizar `requirements.txt` para listar dependências do script principal (ex: `streamlit`, potencialmente `pandas` para ler CSVs).
    *   Criar `requirements-dev.txt` para dependências de desenvolvimento.
4.  **Git:** Garantir que o repositório esteja limpo (commitar ou stashear mudanças não relacionadas). Criar um *feature branch* dedicado para esta migração (ex: `feature/migrar-macros-excel`).

**Fase 1: Análise e Design da Integração**

1.  **Analisar Lógica das Macros:**
    *   Estudar detalhadamente o conteúdo de `calculadoraNFe.txt` e `calculadoraNFSe.txt` para entender as regras de negócio, cálculos e fluxos que eles descrevem.
    *   Mapear como essas regras se relacionam (ou substituem/complementam) as funções existentes em `simulador_frete.py`.
2.  **Analisar Dados das Macros:**
    *   Examinar a estrutura e o conteúdo de `catacao_transportadoras.csv`, `DIfal_FCP.csv` e `pedidos.csv`.
    *   Identificar como esses dados serão usados nos cálculos (lookup, filtros, etc.).
    *   Comparar `DIfal_FCP.csv` com os dicionários `TABELA_DIFAL` e `TABELA_FCP` existentes em `simulador_frete.py` e decidir como unificar/priorizar. O mesmo para `TABELA_SALIS` vs. `catacao_transportadoras.csv` ou `pedidos.csv`.
3.  **Definir Estratégia de Carregamento de Dados:**
    *   **Decidir Formato:** Manter os dados como CSV ou converter para outro formato (JSON, YAML, dicionários Python em um módulo separado)?
        *   *Recomendação Inicial:* Manter como CSV para flexibilidade e separação. Mover os CSVs para um diretório dedicado (ex: `data/`). Considerar mover os dicionários `TABELA_` existentes para CSVs também, para consistência.
    *   **Decidir Biblioteca:** Usar o módulo `csv` nativo do Python ou instalar e usar `pandas`?
        *   *Recomendação Inicial:* Se as operações nos dados forem complexas (filtragem, junção), usar `pandas`. Se for apenas lookup simples, `csv` pode ser suficiente. Instalar a biblioteca escolhida e adicionar ao `requirements.txt`.
    *   **Definir Localização:** Criar um diretório `data/` na raiz do projeto e mover os arquivos `.csv` para lá.
4.  **Planejar Refatoração:**
    *   Identificar quais funções em `simulador_frete.py` precisam ser modificadas.
    *   Esboçar novas funções necessárias para encapsular lógicas específicas das macros (seguindo o princípio SRP).
    *   Planejar como passar os dados carregados (dos CSVs) para as funções de cálculo (ex: injetar como argumentos, usar classes de configuração/dados).

**Fase 2: Implementação e Refatoração do Código Python**

1.  **Implementar Carregamento de Dados:**
    *   Criar função(ões) para carregar os dados dos arquivos CSV (usando `csv` ou `pandas`) no início do script ou sob demanda (considerar caching se os arquivos forem grandes e a leitura for frequente).
    *   Armazenar os dados carregados em estruturas apropriadas (DataFrames pandas, listas de dicionários, etc.).
2.  **Refatorar Funções Existentes:**
    *   Modificar `calcular_frete`, `calcular_montagem`, `calcular_multiplicador`, `calcular_difal_fcp_ipi`, `calcular_nf` para:
        *   Receber os dados carregados (dos CSVs) como parâmetros ou acessá-los de uma fonte centralizada.
        *   Utilizar os dados e a lógica derivada das macros (arquivos `.txt` e `.csv`).
        *   Remover ou ajustar o uso dos dicionários `TABELA_` hardcoded, substituindo-os pelos dados carregados.
3.  **Criar Novas Funções (se necessário):**
    *   Implementar novas funções Python puras para encapsular cálculos específicos identificados na análise das macros (Fase 1).
4.  **Garantir Conformidade com Boas Práticas:**
    *   Aplicar `black` para formatação automática.
    *   Usar `flake8` para verificar estilo e erros simples.
    *   Adicionar/Atualizar Type Hints (`typing`) em todas as funções novas/modificadas.
    *   Executar `mypy` para verificar a consistência dos tipos.
    *   Escrever/Atualizar Docstrings claras (seguindo um padrão, como Google Style) para todas as funções.
    *   Revisar a aderência aos princípios SRP e DRY.

**Fase 3: Adaptação da Interface Streamlit (UI)**

1.  **Revisar Inputs:** Verificar se as novas lógicas/dados requerem inputs adicionais ou modificados na interface Streamlit (`st.number_input`, `st.selectbox`, etc.). Atualizar o código da UI conforme necessário.
2.  **Revisar Outputs:** Ajustar a exibição dos resultados (`st.write`, `st.success`, etc.) para refletir quaisquer mudanças nos valores calculados ou novos resultados provenientes das macros.
3.  **Manter Separação:** Assegurar que a lógica de negócio complexa permaneça nas funções Python puras e não seja movida para dentro do código da UI Streamlit.

**Fase 4: Testes e Validação**

1.  **Escrever Testes Unitários (`pytest`):**
    *   Criar testes para as *novas* funções de cálculo implementadas.
    *   Criar/Atualizar testes para as funções *refatoradas*, cobrindo casos de uso com os novos dados/lógicas.
    *   Focar em testar a lógica de cálculo pura, independentemente da UI. Mockar o carregamento de dados se necessário.
2.  **Testes de Integração (Opcional/Simples):**
    *   Considerar testes simples que verifiquem a interação entre as funções de cálculo principais.
3.  **Validação Manual:** Executar o aplicativo Streamlit e testar manualmente com diferentes cenários de entrada, comparando os resultados com os esperados (potencialmente derivados das macros originais do Excel) para garantir a correção da migração.

**Fase 5: Documentação e Finalização**

1.  **Atualizar README.md:** Descrever as novas fontes de dados (`data/` diretório), como atualizar os dados (se aplicável), e quaisquer mudanças significativas no funcionamento ou configuração.
2.  **Atualizar/Remover Documentação das Macros:** Considerar se os arquivos em `doc/macros/` ainda são necessários ou se podem ser arquivados/removidos após a migração bem-sucedida. Se mantidos, adicionar uma nota indicando que a lógica agora reside no código Python.
3.  **Revisar `padroes_codigo_boas_praticas.md`:** Atualizar se novas convenções foram adotadas durante a refatoração.
4.  **Commit e Pull Request:** Fazer commits atômicos e claros durante o processo. Criar um Pull Request do *feature branch* para o branch principal, descrevendo as mudanças realizadas.
5.  **Limpeza:** Remover código antigo/comentado que não é mais necessário.