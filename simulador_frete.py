# simulador_frete.py

import streamlit as st
from decimal import Decimal, getcontext

getcontext().prec = 10
st.set_page_config(page_title="Calculadora de Frete - Minimal", layout="wide")
st.title("Calculadora de Frete - Minimal Design")

# Tabelas fixas
TABELA_SALIS = {
    ("Acre", "Capital"): 0.22, ("Acre", "Interior"): 0.23,
    ("Alagoas", "Capital"): 0.12, ("Alagoas", "Interior"): 0.12,
    ("Amapá", "Capital"): 0.27, ("Amapá", "Interior"): 0.28,
    ("Amazonas", "Capital"): 0.27, ("Amazonas", "Interior"): 0.28,
    ("Bahia", "Capital"): 0.10, ("Bahia", "Interior"): 0.11,
    ("Ceará", "Capital"): 0.14, ("Ceará", "Interior"): 0.15,
    ("DF - Difal 5%", "Capital"): 0.09, ("DF - Difal 13%", "Capital"): 0.09,
    ("Espírito Santo", "Capital"): 0.08, ("Espírito Santo", "Interior"): 0.09,
    ("Goiás", "Capital"): 0.09, ("Goiás", "Interior"): 0.10,
    ("Maranhão", "Capital"): 0.15, ("Maranhão", "Interior"): 0.16,
    ("Mato Grosso", "Capital"): 0.12, ("Mato Grosso", "Interior"): 0.13,
    ("Mato Grosso do Sul", "Capital"): 0.10, ("Mato Grosso do Sul", "Interior"): 0.11,
    ("Minas Gerais", "Capital"): 0.06, ("Minas Gerais", "Interior"): 0.07,
    ("Pará", "Capital"): 0.15, ("Pará", "Interior"): 0.16,
    ("Paraíba", "Capital"): 0.13, ("Paraíba", "Interior"): 0.14,
    ("Paraná", "Capital"): 0.06, ("Paraná", "Interior"): 0.07,
    ("Pernambuco", "Capital"): 0.12, ("Pernambuco", "Interior"): 0.13,
    ("Piauí", "Capital"): 0.14, ("Piauí", "Interior"): 0.15,
    ("Rio De Janeiro", "Capital"): 0.05, ("Rio De Janeiro", "Interior"): 0.06,
    ("Rio Grande Do Norte", "Capital"): 0.14, ("Rio Grande Do Norte", "Interior"): 0.15,
    ("Rio Grande Do Sul", "Capital"): 0.08, ("Rio Grande Do Sul", "Interior"): 0.09,
    ("Rondônia", "Capital"): 0.22, ("Rondônia", "Interior"): 0.23,
    ("Roraima", "Capital"): None, ("Roraima", "Interior"): None,
    ("Santa Catarina", "Capital"): 0.07, ("Santa Catarina", "Interior"): 0.08,
    ("Sergipe", "Capital"): 0.11, ("Sergipe", "Interior"): 0.12,
    ("Tocantins", "Capital"): 0.12, ("Tocantins", "Interior"): 0.13
}
TABELA_DIFAL = {
    'Acre': 0.12, 'Alagoas': 0.12, 'Amazonas': 0.13, 'Amapá': 0.13, 'Bahia': 0.135, 'Ceará': 0.13,
    'DF - Difal 5%': 0.05, 'DF - Difal 13%': 0.13, 'Espírito Santo': 0.10, 'Goiás': 0.12, 'Maranhão': 0.15,
    'Minas Gerais': 0.06, 'Mato Grosso do Sul': 0.10, 'Mato Grosso': 0.10, 'Paraná': 0.075, 'Pará': 0.12,
    'Paraíba': 0.13, 'Pernambuco': 0.135, 'Piauí': 0.14, 'Rio De Janeiro': 0.08, 'Rio Grande Do Norte': 0.13,
    'Rio Grande Do Sul': 0.05, 'Rondônia': 0.125, 'Roraima': 0.13, 'Santa Catarina': 0.05, 'Sergipe': 0.12,
    'Tocantins': 0.13, 'São Paulo': 0.0
}
TABELA_FCP = {'Alagoas': 0.01, 'Rio De Janeiro': 0.02, 'Sergipe': 0.01}
TABELA_ICMS = {
    'Acre': 0.07, 'Alagoas': 0.07, 'Amazonas': 0.07, 'Amapá': 0.07, 'Bahia': 0.07, 'Ceará': 0.07,
    'DF - Difal 5%': 0.07, 'DF - Difal 13%': 0.07, 'Espírito Santo': 0.07, 'Goiás': 0.07, 'Maranhão': 0.07,
    'Minas Gerais': 0.12, 'Mato Grosso do Sul': 0.07, 'Mato Grosso': 0.07, 'Paraná': 0.12, 'Pará': 0.07,
    'Paraíba': 0.07, 'Pernambuco': 0.07, 'Piauí': 0.07, 'Rio De Janeiro': 0.12, 'Rio Grande Do Norte': 0.07,
    'Rio Grande Do Sul': 0.12, 'Rondônia': 0.07, 'Roraima': 0.07, 'Santa Catarina': 0.12, 'Sergipe': 0.07,
    'Tocantins': 0.07, 'São Paulo': 0.18
}

# Funções utilitárias
def formatar(valor):
    return f"R$ {valor:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")

# Formulário Streamlit
with st.form("formulario"):
    valor_produtos = st.number_input("Valor dos produtos (com ICMS embutido)", min_value=0.0, format="%.2f")
    estado = st.selectbox("Estado de destino (UF)", list(TABELA_DIFAL.keys()))
    cidade = st.selectbox("Cidade de destino", ["Capital", "Interior"])
    horario = st.radio("Horário da entrega", ["Comercial", "Fora do comercial"])
    tem_ie = st.radio("Cliente possui inscrição estadual?", ["Sim", "Não"])
    frete_opcao = st.radio("Frete", ["Calcular Salis", "Informar valor negociado", "Não contratar"])
    montagem_opcao = st.radio("Montagem", ["Calcular automaticamente", "Valor negociado", "Não contratar"])

    frete_negociado = 0
    montagem_negociada = 0
    km_ida_volta = 0
    if frete_opcao == "Informar valor negociado":
        frete_negociado = st.number_input("Valor negociado do frete", min_value=0.0, format="%.2f")
    if montagem_opcao == "Valor negociado":
        montagem_negociada = st.number_input("Valor negociado da montagem", min_value=0.0, format="%.2f")
    if montagem_opcao == "Calcular automaticamente" and estado != "São Paulo":
        km_ida_volta = st.number_input("Distância ida e volta (km) de Barueri-SP", min_value=0.0, format="%.2f")

    submit = st.form_submit_button("Calcular")

if submit:
    st.info("Entradas capturadas com sucesso. Calculando...")

    # Aqui serão implementadas as etapas 1 a 4 conforme combinado:
    # 1. Cálculo do frete (Salis)
    # 2. Montagem
    # 3. Multiplicador de carga tributária
    # 4. Cálculo do DIFAL / FCP / IPI / Valor NF

    # 1. Cálculo do Frete (Salis)
    frete_base = Decimal(0)
    if frete_opcao == "Calcular Salis":
        if estado == "São Paulo":
            if cidade == "Capital" and horario == "Comercial":
                frete_base = Decimal(valor_produtos) * Decimal("0.03")
            elif cidade == "Capital" and horario == "Fora do comercial":
                frete_base = Decimal(valor_produtos) * Decimal("0.04")
            elif cidade == "Interior":
                frete_base = Decimal(valor_produtos) * Decimal("0.04")
        else:
            if valor_produtos > 30000:
                percentual = TABELA_SALIS.get((estado, cidade))
                if percentual is not None:
                    frete_base = Decimal(valor_produtos) * Decimal(percentual)
                else:
                    st.warning(f"Salis não atende {estado} - {cidade}.")
                    frete_base = Decimal(0)
            else:
                percentual = TABELA_SALIS.get((estado, cidade))
                if percentual is not None:
                    frete_base = Decimal("30000.00") * Decimal(percentual)
                else:
                    st.warning(f"Salis não atende {estado} - {cidade}.")
                    frete_base = Decimal(0)
    elif frete_opcao == "Informar valor negociado":
        frete_base = Decimal(frete_negociado)
    elif frete_opcao == "Não contratar":
        frete_base = Decimal(0)

    st.success(f"Cotação do frete: {formatar(frete_base)}")

    # 2. Cálculo da Montagem
    montagem_base = Decimal(0)
    if montagem_opcao == "Calcular automaticamente":
        if estado == "São Paulo" and cidade == "Capital":
            montagem_base = Decimal(valor_produtos) * Decimal("0.035")
        else:
            valor_base = Decimal(valor_produtos) * Decimal("0.035")
            custo_km = Decimal(km_ida_volta) * Decimal("3.50")
            montagem_base = valor_base + custo_km
    elif montagem_opcao == "Valor negociado":
        montagem_base = Decimal(montagem_negociada)
    elif montagem_opcao == "Não contratar":
        montagem_base = Decimal(0)

    st.success(f"Cotação da montagem: {formatar(montagem_base)}")

    # 3. Cálculo do Multiplicador de Carga Tributária
    BASE = Decimal("500000")
    IPI = Decimal("0.0325")
    ICMS = Decimal(TABELA_ICMS.get(estado, 0))
    DIFAL = Decimal(TABELA_DIFAL.get(estado, 0))
    FCP = Decimal(TABELA_FCP.get(estado, 0))

    ipi_frete = BASE * IPI / (1 + IPI)
    icms_frete = BASE * ICMS
    base_liquida = BASE - ipi_frete
    pis_cofins = base_liquida * Decimal("0.0365")
    irpj = base_liquida * Decimal("0.08") * Decimal("0.25")
    csll = base_liquida * Decimal("0.12") * Decimal("0.09")

    if tem_ie == "Não":
        difal_frete = BASE * DIFAL
        fcp_frete = BASE * FCP
        t_imp_frete = ipi_frete + icms_frete + pis_cofins + irpj + csll + difal_frete + fcp_frete
    else:
        t_imp_frete = ipi_frete + icms_frete + pis_cofins + irpj + csll

    frete_liquido = BASE - t_imp_frete
    if frete_liquido == 0:
        st.error("Erro: Frete líquido igual a zero. Divisão por zero não permitida.")
        multiplicador = Decimal("1.0")
    else:
        multiplicador = BASE / frete_liquido

    frete_final = frete_base * multiplicador
    montagem_final = montagem_base * multiplicador

    st.success(f"Multiplicador: {multiplicador:.5f}")
    st.success(f"Valor do Frete final: {formatar(frete_final)}")
    st.success(f"Valor da Montagem final: {formatar(montagem_final)}")

    # 4. Cálculo de DIFAL/FCP/IPI/Nota Fiscal
    if tem_ie == "Não":
        base_difal1 = (Decimal(valor_produtos) + frete_final + montagem_final) / (1 - DIFAL - FCP)
        base_difal2 = 1 - ((IPI * (1 - DIFAL - FCP)) / (1 + IPI))
        base_difal = base_difal1 / base_difal2

        guia_difal = base_difal * DIFAL
        guia_fcp = base_difal * FCP
        valor_ipi = base_difal * IPI / (1 + IPI)

        difal_embutido = ((base_difal - Decimal(valor_produtos) - frete_final - montagem_final - valor_ipi) * DIFAL) / (DIFAL + FCP) if (DIFAL + FCP) != 0 else Decimal(0)
        fcp_embutido = base_difal - Decimal(valor_produtos) - frete_final - montagem_final - difal_embutido - valor_ipi
    else:
        base_difal1 = (Decimal(valor_produtos) + frete_final + montagem_final) / 1
        base_difal2 = 1 - IPI * (1 + IPI)
        base_difal = base_difal1 / base_difal2

        guia_difal = Decimal(0)
        guia_fcp = Decimal(0)
        valor_ipi = base_difal * IPI / (1 + IPI)

        difal_embutido = Decimal(0)
        fcp_embutido = Decimal(0)

    despesas_acessorias = base_difal - Decimal(valor_produtos) - frete_final - valor_ipi
    valor_nf = Decimal(valor_produtos) + frete_final + valor_ipi + despesas_acessorias

    # Resultados finais
    st.subheader("Valores Calculados")
    st.write(f"Cotação do frete: {formatar(frete_base)}")
    st.write(f"Cotação da montagem: {formatar(montagem_base)}")
    st.write(f"Difal embutido: {formatar(difal_embutido)}")
    st.write(f"FCP embutido: {formatar(fcp_embutido)}")

    st.subheader("Resumo da Nota Fiscal")
    st.write(f"Valor dos produtos: {formatar(Decimal(valor_produtos))}")
    st.write(f"Valor do Frete: {formatar(frete_final)}")
    st.write(f"Valor da Montagem: {formatar(montagem_final)}")
    st.write(f"Despesas acessórias: {formatar(despesas_acessorias)}")
    st.write(f"Valor do IPI: {formatar(valor_ipi)}")
    st.write(f"Valor da NF: {formatar(valor_nf)}")

    st.subheader("Guias")
    st.write(f"Guia Difal: {formatar(guia_difal)}")
    st.write(f"Guia FCP: {formatar(guia_fcp)}")
