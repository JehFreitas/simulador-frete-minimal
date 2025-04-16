# Simulador de Frete, Montagem e Tributos - Minimal (com Streamlit)

import streamlit as st
from dataclasses import dataclass
from typing import Optional

# === Dados de entrada e saída ===
@dataclass
class Entrada:
    valor_produtos: float
    estado_destino: str
    cidade: str
    horario_entrega: str
    inscricao_estadual: bool
    tipo_frete: str
    tipo_calculo_frete: str
    valor_frete_negociado: Optional[float] = 0.0
    tipo_calculo_montagem: str = "nao contratar"
    valor_montagem_negociado: Optional[float] = 0.0
    distancia_km: Optional[float] = 0.0
    grande_sp: bool = True

@dataclass
class Resultado:
    frete_final: float
    montagem_final: float
    multiplicador: float
    guia_difal: float
    guia_fcp: float
    valor_ipi: float
    valor_nf: float

# === Tabelas ===
TABELA_DIFAL = {
    'São Paulo': 0.00,
    'Minas Gerais': 0.06,
    'Rio De Janeiro': 0.08,
}
TABELA_FCP = {
    'Rio De Janeiro': 0.02,
}
TABELA_ICMS_FRETE = {
    'São Paulo': 0.18,
    'Minas Gerais': 0.12,
    'Rio De Janeiro': 0.12,
}
TABELA_SALIS = {
    ('São Paulo', 'Capital'): 0.03,
    ('São Paulo', 'Interior'): 0.04,
    ('Minas Gerais', 'Capital'): 0.06,
}

# === Funções de cálculo ===
def calcular_frete(entrada: Entrada) -> float:
    if entrada.tipo_frete in ["assistência técnica", "coleta"]:
        if entrada.distancia_km <= 100:
            return 280.0
        else:
            return 0.0
    if entrada.tipo_calculo_frete == "calcular":
        if entrada.distancia_km <= 100:
            return entrada.valor_produtos * (0.03 if entrada.horario_entrega == "Comercial" else 0.04)
        else:
            base = max(entrada.valor_produtos, 30000)
            perc = TABELA_SALIS.get((entrada.estado_destino, entrada.cidade), 0)
            return base * perc
    elif entrada.tipo_calculo_frete == "negociado":
        return entrada.valor_frete_negociado
    else:
        return 0.0

def calcular_montagem(entrada: Entrada) -> float:
    if entrada.tipo_calculo_montagem == "calcular":
        if entrada.grande_sp:
            return entrada.valor_produtos * 0.035
        else:
            return entrada.valor_produtos * 0.035 + entrada.distancia_km * 2 * 3.5
    elif entrada.tipo_calculo_montagem == "negociado":
        return entrada.valor_montagem_negociado
    else:
        return 0.0

def calcular_multiplicador(entrada: Entrada, frete: float, montagem: float) -> float:
    base = 500000
    difal = base * TABELA_DIFAL.get(entrada.estado_destino, 0)
    ipi = base * 0.0325 / (1 + 0.0325)
    icms = base * TABELA_ICMS_FRETE.get(entrada.estado_destino, 0)
    fcp = base * TABELA_FCP.get(entrada.estado_destino, 0)
    base_liquida = base - ipi
    pis_cofins = base_liquida * 0.0365
    irpj = base_liquida * 0.08 * 0.25
    csll = base_liquida * 0.12 * 0.09
    tributos = difal + ipi + icms + fcp + pis_cofins + irpj + csll
    frete_liquido = base - tributos
    if frete_liquido == 0:
        raise ValueError("Erro: Frete líquido igual a 0")
    return round(base / frete_liquido, 5)

def calcular_difal_fcp_ipi(entrada: Entrada, frete_final: float, montagem_final: float):
    difal_pct = TABELA_DIFAL.get(entrada.estado_destino, 0)
    fcp_pct = TABELA_FCP.get(entrada.estado_destino, 0)
    ipi_pct = 0.0325
    base1 = (entrada.valor_produtos + frete_final + montagem_final) / (1 - difal_pct - fcp_pct)
    base2 = 1 - ((ipi_pct * (1 - difal_pct - fcp_pct)) / (1 + ipi_pct))
    base_difal = base1 / base2
    guia_difal = base_difal * difal_pct
    guia_fcp = base_difal * fcp_pct
    valor_ipi = base_difal * ipi_pct / (1 + ipi_pct)
    return guia_difal, guia_fcp, valor_ipi, base_difal

def calcular_nf(entrada: Entrada) -> Resultado:
    frete_bruto = calcular_frete(entrada)
    montagem_bruta = calcular_montagem(entrada)
    multiplicador = calcular_multiplicador(entrada, frete_bruto, montagem_bruta)
    frete_final = round(frete_bruto * multiplicador, 2)
    montagem_final = round(montagem_bruta * multiplicador, 2)
    guia_difal, guia_fcp, valor_ipi, base_difal = calcular_difal_fcp_ipi(entrada, frete_final, montagem_final)
    despesas_acessorias = base_difal - entrada.valor_produtos - frete_final - valor_ipi
    valor_nf = round(entrada.valor_produtos + frete_final + valor_ipi + despesas_acessorias, 2)
    return Resultado(frete_final, montagem_final, multiplicador, round(guia_difal, 2), round(guia_fcp, 2), round(valor_ipi, 2), valor_nf)

# === Interface Streamlit ===
st.title("Simulador de Frete e Tributos - Minimal")
st.markdown("Insira os dados abaixo:")

with st.form("formulario"):
    valor_produtos = st.number_input("Valor dos Produtos (com ICMS)", min_value=0.0)
    estado_destino = st.selectbox("Estado de destino", list(TABELA_DIFAL.keys()))
    cidade = st.radio("Cidade", ["Capital", "Interior"])
    horario_entrega = st.radio("Horário da entrega", ["Comercial", "Fora do comercial"])
    inscricao_estadual = st.radio("Cliente possui inscrição estadual?", ["Sim", "Não"]) == "Sim"
    tipo_frete = st.selectbox("Tipo de frete", ["entrega normal", "assistência técnica", "coleta"])
    tipo_calculo_frete = st.selectbox("Frete", ["calcular", "negociado", "nao contratar"])
    valor_frete_negociado = st.number_input("Valor negociado do frete", min_value=0.0)
    tipo_calculo_montagem = st.selectbox("Montagem", ["calcular", "negociado", "nao contratar"])
    valor_montagem_negociado = st.number_input("Valor negociado da montagem", min_value=0.0)
    distancia_km = st.number_input("Distância ida (km)", min_value=0.0)
    grande_sp = st.checkbox("Entrega na Grande São Paulo?", value=True)
    submitted = st.form_submit_button("Calcular")

if submitted:
    entrada = Entrada(
        valor_produtos=valor_produtos,
        estado_destino=estado_destino,
        cidade=cidade,
        horario_entrega=horario_entrega,
        inscricao_estadual=inscricao_estadual,
        tipo_frete=tipo_frete,
        tipo_calculo_frete=tipo_calculo_frete,
        valor_frete_negociado=valor_frete_negociado,
        tipo_calculo_montagem=tipo_calculo_montagem,
        valor_montagem_negociado=valor_montagem_negociado,
        distancia_km=distancia_km,
        grande_sp=grande_sp
    )

    try:
        resultado = calcular_nf(entrada)
        st.success("Cálculo realizado com sucesso!")
        st.write(f"**Frete Final:** R$ {resultado.frete_final:.2f}")
        st.write(f"**Montagem Final:** R$ {resultado.montagem_final:.2f}")
        st.write(f"**Multiplicador de Carga Tributária:** {resultado.multiplicador:.5f}")
        st.write(f"**Guia DIFAL:** R$ {resultado.guia_difal:.2f}")
        st.write(f"**Guia FCP:** R$ {resultado.guia_fcp:.2f}")
        st.write(f"**Valor IPI:** R$ {resultado.valor_ipi:.2f}")
        st.write(f"**Valor Final da NF:** R$ {resultado.valor_nf:.2f}")
    except Exception as e:
        st.error(str(e))
