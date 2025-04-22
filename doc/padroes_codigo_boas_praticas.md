# Padrões de Código e Boas Práticas - Simulador Frete

**Versão:** 0.1.0
**Data:** 2025-04-17

Manter um código limpo, consistente e fácil de entender é crucial para a manutenabilidade e evolução de qualquer projeto. Este projeto **DEVE** aderir às seguintes práticas e padrões:

## Padrão de Codificação: PEP 8 e Ferramentas Associadas

Todo o código Python **DEVE** seguir o [PEP 8 -- Style Guide for Python Code](https://www.python.org/dev/peps/pep-0008/). Para garantir a conformidade e consistência:

*   **Formatação Automática:** **RECOMENDÁVEL** o uso do [Black](https://black.readthedocs.io/) para formatar o código automaticamente antes de commitar.
    ```bash
    # Exemplo de uso (pode ser integrado a hooks de pre-commit)
    black simulador_frete.py docs/
    ```
*   **Linting:** **RECOMENDÁVEL** o uso de linters como [Flake8](https://flake8.pycqa.org/) ou [Pylint](https://www.pylint.org/) para detectar erros de estilo, bugs potenciais e complexidade desnecessária.
    ```bash
    # Exemplo de uso
    flake8 simulador_frete.py
    # pylint simulador_frete.py
    ```
*   **Verificação de Tipos:** Dado o uso extensivo de type hints no projeto (ver seção específica abaixo), **RECOMENDÁVEL** o uso do [MyPy](http://mypy-lang.org/) para análise estática de tipos.
    ```bash
    # Exemplo de uso
    mypy simulador_frete.py
    ```
*   **Exemplo de Código Formatado (do `simulador_frete.py`):**
    ```python
    # Exemplo de boa formatação PEP 8 (espaçamento, nomes, linha em branco)
    def calcular_montagem(entrada: Entrada) -> float:
        """Calcula o valor bruto da montagem."""
        if entrada.tipo_calculo_montagem == "calcular":
            if entrada.grande_sp:
                return entrada.valor_produtos * 0.035
            else:
                # Exemplo de cálculo com múltiplas condições
                distancia_total = entrada.distancia_km * 2
                custo_deslocamento = distancia_total * 3.5
                return entrada.valor_produtos * 0.035 + custo_deslocamento
        elif entrada.tipo_calculo_montagem == "negociado":
            return entrada.valor_montagem_negociado
        else: # nao contratar
            return 0.0

    # Linha em branco separando a próxima definição
    def calcular_multiplicador(entrada: Entrada, frete: float, montagem: float) -> float:
        # ...
    ```
*   **Principais Regras PEP 8 (Reforço):**
    *   Indentação: 4 espaços, **NÃO** tabs.
    *   Limite de Linha: ~79 caracteres para código, ~72 para docstrings/comentários (flexível, mas evite linhas excessivamente longas).
    *   Linhas em Branco: Use para separar funções, classes e blocos lógicos significativos.
    *   Imports: Imports no topo do arquivo, agrupados (standard library, third-party, local), um por linha.
    *   Nomenclatura: Veja seção específica abaixo.
    *   Espaçamento: Use espaços em torno de operadores (`=`, `+`, `*`) e após vírgulas. Evite espaços extras (ex: `func( valor )` -> ruim, `func(valor)` -> bom).

## Boas Práticas Python / Simulador Frete

Além da formatação, siga estas convenções e práticas recomendadas:

### Nomenclatura (Consistente com PEP 8)

| Recurso          | Convenção              | Exemplo (`simulador_frete.py`) | Exemplo Ruim        | Notas                                             |
| :--------------- | :--------------------- | :----------------------------- | :------------------ | :------------------------------------------------ |
| Variáveis        | `snake_case`           | `valor_produtos`, `frete_final` | `valorProdutos`, `VALOR_PRODUTOS` | Descritivo, letras minúsculas.                |
| Funções          | `snake_case`           | `calcular_frete`, `calcular_nf` | `calcularFrete`, `CalculaNF` | Verbos descritivos, letras minúsculas.          |
| Parâmetros Func. | `snake_case`           | `entrada: Entrada`, `valor: float` | `EntradaParam`, `VALOR` | Igual às variáveis.                               |
| Classes          | `PascalCase`/`CapWords` | `Entrada`, `Resultado`         | `entrada`, `resultado_calculo` | Primeira letra maiúscula.                     |
| Métodos          | `snake_case`           | (Nenhum método de classe no exemplo) | `meuMetodo()`       | Igual às funções (em Python).                   |
| Módulos          | `snake_case` (geralmente) | `simulador_frete.py`         | `SimuladorFrete.py` | Arquivos `.py`, letras minúsculas.              |
| Constantes       | `SCREAMING_SNAKE_CASE` | `TABELA_DIFAL`, `TABELA_FCP`   | `tabelaDifal`, `tabela_difal` | Todas as letras maiúsculas.                     |
| Dataclass Fields | `snake_case`           | `valor_produtos`, `estado_destino` | `valorProdutos`     | Convenção de variáveis dentro de dataclasses.   |

### Princípios Arquiteturais

*   **Princípio da Responsabilidade Única (SRP):** Funções e classes (como as Dataclasses `Entrada` e `Resultado`) **DEVEM** ter uma única responsabilidade bem definida.
    *   **Exemplo:** No `simulador_frete.py`, a função `calcular_frete` é responsável *apenas* por calcular o frete bruto. A função `calcular_montagem` cuida *apenas* da montagem. A função `calcular_nf` orquestra a chamada dessas funções menores e os cálculos finais da NF. Isso facilita o entendimento e a modificação de regras específicas.
*   **DRY (Don't Repeat Yourself):** Evite duplicação de código. Se uma lógica de cálculo específica começar a se repetir, extraia-a para uma função auxiliar.
    *   **Exemplo:** As tabelas `TABELA_DIFAL`, `TABELA_FCP`, `TABELA_ICMS_FRETE`, `TABELA_SALIS` centralizam dados que, se não fossem constantes, poderiam estar repetidos em vários pontos do código. O acesso via `.get()` também evita repetição de lógica de tratamento para chaves não encontradas.
*   **Separação de Lógica e Interface (UI):** O código em `simulador_frete.py` demonstra uma boa separação inicial:
    *   **Lógica de Cálculo:** Funções Python puras (`calcular_frete`, `calcular_montagem`, etc.) que recebem dados (`Entrada`) e retornam resultados (`Resultado` ou `float`), sem depender diretamente do Streamlit.
    *   **Interface Streamlit:** Código na seção `=== Interface Streamlit ===` que usa `st.*` para criar a interface, coletar inputs e exibir resultados.
        ```python
        # Exemplo de Separação UI/Lógica
        # --- Lógica de Cálculo ---
        def calcular_nf(entrada: Entrada) -> Resultado:
            # ... muitos cálculos aqui ...
            return Resultado(...)

        # --- Interface Streamlit ---
        st.title("Simulador de Frete e Tributos - Minimal")
        # ... coleta de inputs via st.number_input, st.selectbox etc ...
        submitted = st.form_submit_button("Calcular")

        if submitted:
            # Cria objeto de entrada a partir dos inputs da UI
            entrada_calculo = Entrada(...)
            try:
                # Chama a função de lógica pura
                resultado_calculo = calcular_nf(entrada_calculo)
                st.success("Cálculo realizado com sucesso!")
                # Exibe os resultados usando st.write
                st.write(f"**Frete Final:** R$ {resultado_calculo.frete_final:.2f}")
                # ... mais st.write ...
            except Exception as e:
                st.error(str(e))
        ```
    **DEVE-SE** manter essa separação. Evite colocar regras de negócio complexas diretamente no código da interface Streamlit.
*   **Modularização:** O código já está dividido em funções coesas. Se o projeto crescer, **PODERIA** ser considerado mover funções de cálculo relacionadas para módulos Python separados (arquivos `.py`) e importá-los, especialmente a lógica de cálculo principal.

### Práticas de Código Específicas do Projeto

*   **Type Hints Obrigatórios:** O uso de type hints **DEVE** ser seguido rigorosamente, como já implementado em `simulador_frete.py`. Isso inclui:
    *   Parâmetros de função: `def calcular_frete(entrada: Entrada) -> float:`
    *   Tipo de retorno de função: `-> float`, `-> Resultado`
    *   Variáveis, especialmente em dataclasses:
        ```python
        from dataclasses import dataclass
        from typing import Optional

        @dataclass
        class Entrada:
            valor_produtos: float # Obrigatório
            estado_destino: str
            # ... outros campos
            valor_frete_negociado: Optional[float] = 0.0 # Opcional com valor padrão
        ```
    Use a sintaxe compatível com Python 3.7+ (ex: `typing.Optional`, `typing.List`, `typing.Dict`). Execute `mypy .` para verificar a consistência dos tipos.
*   **Uso de Dataclasses:** **DEVE-SE** usar `@dataclass` para agrupar dados relacionados, especialmente para entradas e saídas de funções complexas, como visto com `Entrada` e `Resultado`. Isso melhora a clareza, a tipagem e a manutenibilidade.
    ```python
    from dataclasses import dataclass

    @dataclass
    class Resultado:
        frete_final: float
        montagem_final: float
        multiplicador: float
        guia_difal: float
        guia_fcp: float
        valor_ipi: float
        valor_nf: float
    ```
*   **Docstrings:** Todas as funções públicas, classes e módulos **DEVEM** ter Docstrings explicando seu propósito, parâmetros e o que retornam. **RECOMENDÁVEL** usar um estilo padrão como [Google Style](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings) ou [reStructuredText (reST)](https://www.python.org/dev/peps/pep-0287/).
    ```python
    # Exemplo (Google Style) para uma função do simulador
    def calcular_frete(entrada: Entrada) -> float:
        """Calcula o valor bruto do frete com base nas regras de negócio.

        Considera o tipo de frete, distância, valor dos produtos e horário
        para determinar a taxa ou valor fixo aplicável.

        Args:
            entrada: Objeto Dataclass contendo todos os dados de entrada necessários
                     para o cálculo, como tipo_frete, distancia_km, valor_produtos, etc.

        Returns:
            O valor bruto do frete calculado em Reais (R$).
            Retorna 0.0 se o frete não for aplicável ou em caso de erro não tratado.
            (Nota: tratamento de erro mais robusto pode ser adicionado)
        """
        if entrada.tipo_frete in ["assistência técnica", "coleta"]:
            if entrada.distancia_km <= 100:
                return 280.0
            else:
                # TODO: Definir regra para distância > 100km em assistência/coleta
                return 0.0 # Retornando 0 por enquanto
        # ... resto da implementação ...
        return 0.0 # Fallback
    ```
*   **Nomes Expressivos:** Use nomes claros e auto-descritivos para variáveis, funções e classes. O código atual segue bem essa prática (ex: `calcular_frete`, `estado_destino`, `TABELA_DIFAL`). Mantenha a consistência.
*   **Evitar Comentários Desnecessários:** Código bem escrito e nomeado geralmente não precisa de comentários explicando *o quê* ele faz. Use comentários (`#`) para explicar o *porquê* de uma lógica não óbvia ou complexa (ex: `# Usar valor mínimo de R$ 30.000 como base se produtos < 30k`), ou para indicar TODOs/FIXMEs.
*   **Tratamento de Erros:** Use blocos `try...except` para capturar exceções esperadas, especialmente em torno de operações que podem falhar. Capture exceções específicas sempre que possível.
    *   **Exemplo (na Interface Streamlit):** O bloco `try...except Exception` no final do `simulador_frete.py` é adequado para capturar *qualquer* erro da lógica de cálculo e apresentá-lo ao usuário via `st.error`.
        ```python
        # Na interface Streamlit
        if submitted:
            # ... cria objeto 'entrada' ...
            try:
                resultado = calcular_nf(entrada)
                st.success("Cálculo realizado com sucesso!")
                # ... st.write(resultado) ...
            except ValueError as ve: # Exemplo: Captura erro específico
                st.error(f"Erro nos dados de entrada: {ve}")
            except ZeroDivisionError: # Exemplo: Captura divisão por zero
                 st.error("Erro no cálculo: Divisão por zero detectada.")
            except Exception as e: # Fallback genérico para erros inesperados
                st.error(f"Ocorreu um erro inesperado no cálculo: {e}")
        ```
    *   **Exemplo (na Lógica):** A função `calcular_multiplicador` **PODERIA** explicitamente levantar um `ValueError` ou `ZeroDivisionError` se `frete_liquido` for zero, em vez de deixar a divisão falhar implicitamente.
        ```python
        def calcular_multiplicador(...) -> float:
            # ... cálculos anteriores ...
            frete_liquido = base - tributos
            if frete_liquido == 0:
                # Levanta uma exceção específica em vez de deixar dividir por zero
                raise ValueError("Erro no cálculo do multiplicador: Frete líquido não pode ser zero.")
            return round(base / frete_liquido, 5)
        ```
*   **Early Return:** Retorne cedo de funções em caso de erro ou condição de saída, reduzindo o aninhamento de `if/else`.
    ```python
    # Exemplo usando Early Return em calcular_frete
    def calcular_frete(entrada: Entrada) -> float:
        """Calcula o valor bruto do frete com base nas regras de negócio."""
        if entrada.tipo_calculo_frete == "nao contratar":
            return 0.0 # Retorna cedo

        if entrada.tipo_calculo_frete == "negociado":
            return entrada.valor_frete_negociado # Retorna cedo

        # Agora só processa o caso 'calcular'
        if entrada.tipo_frete in ["assistência técnica", "coleta"]:
            if entrada.distancia_km <= 100:
                return 280.0
            else:
                return 0.0 # Retorna cedo para distância > 100km

        # Caso 'calcular' e 'entrega normal' (implícito)
        if entrada.distancia_km <= 100:
             # ... cálculo para distância <= 100km ...
             taxa = 0.03 if entrada.horario_entrega == "Comercial" else 0.04
             return entrada.valor_produtos * taxa
        else:
             # ... cálculo para distância > 100km ...
             base = max(entrada.valor_produtos, 30000)
             perc = TABELA_SALIS.get((entrada.estado_destino, entrada.cidade), 0)
             return base * perc

        # Teoricamente, não deveria chegar aqui se todas as condições forem tratadas
        # return 0.0 # Fallback final, se necessário
    ```
*   **Considerações Streamlit:**
    *   **Separação UI/Lógica:** Já abordado. Mantenha a lógica de cálculo em funções Python puras.
    *   **Clareza na UI:** Use widgets apropriados (`st.number_input`, `st.selectbox`, `st.radio`, `st.checkbox`) para cada tipo de entrada. Use `st.form` para agrupar inputs e evitar recálculos a cada mudança individual de widget.
        ```python
        # Exemplo de uso de form
        with st.form("formulario"):
            valor_produtos = st.number_input("Valor dos Produtos (com ICMS)", min_value=0.0)
            estado_destino = st.selectbox("Estado de destino", list(TABELA_DIFAL.keys()))
            # ... outros inputs ...
            submitted = st.form_submit_button("Calcular") # Botão dentro do form

        if submitted: # Código fora do form só executa quando o botão é clicado
            # ... processamento ...
        ```
    *   **Feedback ao Usuário:** Use `st.success`, `st.error`, `st.warning`, `st.info` para dar feedback claro sobre o resultado da operação.
    *   **Gerenciamento de Estado:** Se o aplicativo precisar de estado persistente (ex: histórico de cálculos, configurações do usuário), use `st.session_state`. (Não usado no exemplo atual).
    *   **Performance:** Para operações custosas (não presentes neste exemplo simples), use `@st.cache_data` ou `@st.cache_resource`.

## Uso de Termos RFC 2119 na Documentação

Ao escrever documentação, use os termos da [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) para indicar níveis de obrigatoriedade:

| Inglês (RFC 2119)           | Português (Adotado)         | Significado                                     |
| :-------------------------- | :-------------------------- | :---------------------------------------------- |
| MUST, REQUIRED, SHALL       | **DEVE, DEVEM, REQUER**     | Obrigação absoluta.                             |
| MUST NOT, SHALL NOT         | **NÃO DEVE, NÃO DEVEM**     | Proibição absoluta.                           |
| SHOULD, RECOMMENDED         | **PODERIA, PODERIAM, RECOMENDÁVEL** | Forte recomendação, exceções justificadas. |
| SHOULD NOT, NOT RECOMMENDED | **NÃO PODERIA, NÃO RECOMENDÁVEL** | Forte desaconselhamento, exceções justificadas. |
| MAY, OPTIONAL               | **PODE, PODEM, OPCIONAL**   | Verdadeiramente opcional, sem preferência.      |

Exemplo: _"A função `calcular_nf` **DEVE** retornar um objeto `Resultado`."_ vs. _"**PODERIA** ser considerado mover as tabelas para um arquivo de configuração separado."_ vs. _"Type hints **DEVEM** ser usados em todas as assinaturas de função."_