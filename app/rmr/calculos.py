"""
Tablas Bieniawski (RMR76 / RMR89) y funciones de cálculo.
Estas tablas codifican el estándar y NO deben modificarse.
"""

import math
from datetime import datetime

# ─────────────────────────────────────────────────────────────────────────────
# TABLAS RMR
# ─────────────────────────────────────────────────────────────────────────────

RESISTENCIA_TABLA = [
    # (ucs_min, ucs_max_excl, codigo, r89, r76)
    (250, float("inf"), "R6", 15, 15),
    (100, 250,          "R5", 12, 12),
    (50,  100,          "R4",  7,  7),
    (25,   50,          "R3",  4,  4),
    (5,    25,          "R2",  2,  2),
    (1,     5,          "R1",  1,  1),
    (0,     1,          "R0",  0,  0),
]

AGUA_TABLA = {
    "C": {"r89": 15, "r76": 10, "label": "Completamente seco"},
    "H": {"r89": 10, "r76": 10, "label": "Húmedo"},
    "M": {"r89":  7, "r76":  7, "label": "Mojado"},
    "E": {"r89":  4, "r76":  4, "label": "Goteando"},
    "F": {"r89":  0, "r76":  0, "label": "Fluyendo"},
}

RQD_TABLA = [
    (90, 100, 20, 20),
    (75,  90, 17, 17),
    (50,  75, 13, 13),
    (25,  50,  8,  8),
    ( 0,  25,  3,  3),
]

ESPACIAMIENTO_TABLA_89 = [
    (2.0,  float("inf"), 20),
    (0.6,  2.0,          15),
    (0.2,  0.6,          10),
    (0.06, 0.2,           8),
    (0.0,  0.06,          5),
]

ESPACIAMIENTO_TABLA_76 = [
    (3.0,  float("inf"), 30),
    (1.0,  3.0,          25),
    (0.3,  1.0,          20),
    (0.05, 0.3,          10),
    (0.0,  0.05,          5),
]

ABERTURA_TABLA = [
    # (min_incl, max_excl, r89, r76)
    (5.0,        float("inf"), 0, 0),
    (1.0,        5.0,          1, 1),
    (0.1,        1.0,          3, 3),
    (0.0000001,  0.1,          5, 4),
    (0.0,        0.0000001,    6, 5),
]

CONTINUIDAD_TABLA = [
    (20.0, float("inf"), 0, 0),
    (10.0, 20.0,         1, 1),
    (3.0,  10.0,         2, 3),
    (1.0,   3.0,         4, 4),
    (0.0,   1.0,         6, 5),
]

# rugosidad_codigo: 1–9 (no 1–5)
RUGOSIDAD_TABLA = {
    1: (6, 5), 2: (5, 4), 3: (5, 4),
    4: (3, 2), 5: (3, 2),
    6: (1, 0), 7: (1, 0),
    8: (0, 0), 9: (0, 0),
}

ALTERACION_TABLA = {
    "f": (6, 5), "d": (5, 5), "m": (3, 4),
    "a": (3, 3), "c": (2, 2), "s": (1, 1),
}

# tipo 1 = duro (si, sf, ep, ox), tipo 2 = blando (g, cl, ca), tipo 3 = sin relleno (cwf)
RELLENO_TABLA = {
    "cwf": {"tipo": 3, "sin89": 6,  "sin76": 5},
    "si":  {"tipo": 1, "dlt5_89": 4, "dlt5_76": 4, "dgt5_89": 2, "dgt5_76": 3},
    "sf":  {"tipo": 1, "dlt5_89": 4, "dlt5_76": 4, "dgt5_89": 2, "dgt5_76": 3},
    "ep":  {"tipo": 1, "dlt5_89": 4, "dlt5_76": 4, "dgt5_89": 2, "dgt5_76": 3},
    "ox":  {"tipo": 1, "dlt5_89": 4, "dlt5_76": 4, "dgt5_89": 2, "dgt5_76": 3},
    "g":   {"tipo": 2, "blt5_89": 2, "blt5_76": 2, "bgt5_89": 0, "bgt5_76": 0},
    "cl":  {"tipo": 2, "blt5_89": 2, "blt5_76": 2, "bgt5_89": 0, "bgt5_76": 0},
    "ca":  {"tipo": 2, "blt5_89": 2, "blt5_76": 2, "bgt5_89": 0, "bgt5_76": 0},
}


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def _num(val):
    if val is None or val == "":
        return None
    try:
        return float(str(val).replace(",", "."))
    except (ValueError, TypeError):
        return None


def _int(val):
    n = _num(val)
    return int(n) if n is not None else None


def _tipo(code):
    """Normaliza código de tipo de estructura (J, F, SZ, etc.)."""
    MAP = {"JN": "J", "BED": "J", "F": "F", "SZ": "SZ", "CON": "C"}
    return MAP.get(str(code).upper(), str(code)) if code else ""


def tabla_lookup(value, tabla):
    """Lookup en tabla de rangos [min_incl, max_excl, ...]"""
    for row in tabla:
        lo, hi = row[0], row[1]
        if lo <= value < hi:
            return row[2:]
    return None


def resistencia_from_ucs(ucs):
    for ucs_min, ucs_max, codigo, r89, r76 in RESISTENCIA_TABLA:
        if ucs_min <= ucs < ucs_max:
            return codigo, r89, r76
    return "R0", 0, 0


def rqd_rating(rqd_pct):
    for lo, hi, r89, r76 in RQD_TABLA:
        if lo <= rqd_pct <= hi:
            return r89, r76
    return 3, 3


def get_relleno_rating(code, espesor_mm):
    r = RELLENO_TABLA.get(code)
    if not r:
        return None, None
    if r["tipo"] == 3:
        return r["sin89"], r["sin76"]
    menor5 = espesor_mm < 5
    if r["tipo"] == 1:
        return (r["dlt5_89"], r["dlt5_76"]) if menor5 else (r["dgt5_89"], r["dgt5_76"])
    if r["tipo"] == 2:
        return (r["blt5_89"], r["blt5_76"]) if menor5 else (r["bgt5_89"], r["bgt5_76"])
    return None, None


def calc_jv_rqd(rows):
    """Calcula JV y RQD% a partir de las filas de discontinuidades."""
    familias = {}
    for r in rows:
        fam   = r.get("familia_id")
        espac = r.get("espaciamiento_m")
        if fam is not None and espac and float(espac) > 0:
            familias.setdefault(fam, []).append(float(espac))

    jv = 0.0
    for espaciamientos in familias.values():
        prom = sum(espaciamientos) / len(espaciamientos)
        if prom > 0:
            jv += 1.0 / prom

    rqd_pct = max(0.0, 115.0 - 3.3 * jv)
    return jv, rqd_pct


def calc_espac_prom(rows):
    """Promedio ponderado de espaciamiento (Σ(nstr*espac)/Σnstr)."""
    num = den = 0.0
    for r in rows:
        nstr  = float(r.get("n_estructuras", 1) or 1)
        espac = r.get("espaciamiento_m")
        if espac and float(espac) > 0:
            num += nstr * float(espac)
            den += nstr
    return num / den if den > 0 else None


def calc_row_scores(row):
    """Ratings de condición de discontinuidad para una fila."""
    alt_code = row.get("alteracion_codigo", "")
    a89, a76 = ALTERACION_TABLA.get(alt_code, (None, None))

    espesor      = float(row.get("espesor_mm", 0) or 0)
    r1_89, r1_76 = get_relleno_rating(row.get("relleno_1_codigo", ""), espesor)
    r2_89, r2_76 = get_relleno_rating(row.get("relleno_2_codigo", ""), espesor)

    if r1_89 is not None and r2_89 is not None:
        rel89, rel76 = min(r1_89, r2_89), min(r1_76, r2_76)
    elif r1_89 is not None:
        rel89, rel76 = r1_89, r1_76
    elif r2_89 is not None:
        rel89, rel76 = r2_89, r2_76
    else:
        rel89 = rel76 = None

    cont_val = float(row.get("continuidad_m", 0) or 0)
    ct        = tabla_lookup(cont_val, CONTINUIDAD_TABLA)
    co89, co76 = (ct[0], ct[1]) if ct else (None, None)

    aber_val   = float(row.get("abertura_mm", 0) or 0)
    ab         = tabla_lookup(aber_val, ABERTURA_TABLA)
    ab89, ab76 = (ab[0], ab[1]) if ab else (None, None)

    rug_code   = int(row.get("rugosidad_codigo", 0) or 0)
    rp         = RUGOSIDAD_TABLA.get(rug_code)
    rug89, rug76 = (rp[0], rp[1]) if rp else (None, None)

    vals89 = [a89, rel89, co89, ab89, rug89]
    vals76 = [a76, rel76, co76, ab76, rug76]

    v89 = sum(vals89) if all(v is not None for v in vals89) else None
    v76 = sum(vals76) if all(v is not None for v in vals76) else None

    return v89, v76


def calcular_largo_celda(este_ini, norte_ini, cota_ini, este_fin, norte_fin, cota_fin):
    """Distancia euclidiana 3D entre el punto inicial y final de la celda de mapeo."""
    try:
        dx = float(este_fin)  - float(este_ini)
        dy = float(norte_fin) - float(norte_ini)
        dz = float(cota_fin)  - float(cota_ini)
        return math.sqrt(dx**2 + dy**2 + dz**2)
    except (TypeError, ValueError):
        return None


def generar_json_objetivo(data):
    """
    Orquesta la conversión del payload del formulario al JSON objetivo con RMR calculado.
    data = { header: {...}, rows: [...], rmr: {...} }
    """
    hdr    = data.get("header", {})
    rows   = data.get("rows", [])
    rmr_in = data.get("rmr", {})

    discontinuidades = []
    for r in rows:
        nstr = int(float(r.get("nstr") or r.get("n_estructuras") or 1))
        discontinuidades.append({
            "familia_id":          int(float(r.get("fam") or r.get("familia_id") or 0)),
            "distancia_m":         _num(r.get("dist") or r.get("distancia_m")),
            "tipo_estructura":     _tipo(r.get("tipo") or r.get("tipo_estructura")),
            "dip":                 _int(r.get("dip")),
            "dip_dir":             _int(r.get("dipdir") or r.get("dip_dir")),
            "abertura_mm":         _num(r.get("aber") or r.get("abertura_mm")),
            "espesor_mm":          _num(r.get("esp") or r.get("espesor_mm")),
            "continuidad_m":       _num(r.get("cont") or r.get("continuidad_m")),
            "espaciamiento_m":     _num(r.get("espac") or r.get("espaciamiento_m")),
            "n_extremos_visibles": _int(r.get("next") or r.get("n_extremos_visibles")),
            "terminacion":         _int(r.get("term") or r.get("terminacion")),
            "relleno_1_codigo":    r.get("r1") or r.get("relleno_1_codigo") or "",
            "relleno_2_codigo":    r.get("r2") or r.get("relleno_2_codigo") or "",
            "jrc":                 _int(r.get("jrc")),
            "rugosidad_codigo":    _int(r.get("rug") or r.get("rugosidad_codigo")),
            "forma_estructura":    r.get("forma") or r.get("forma_estructura") or "",
            "alteracion_codigo":   r.get("alt") or r.get("alteracion_codigo") or "",
            "n_estructuras":       nstr,
        })

    ucs        = float(rmr_in.get("ucs_mpa") or 74)
    is50       = float(rmr_in.get("is50_mpa") or 5)
    agua_code  = rmr_in.get("agua_codigo", "C")
    gsi_cond   = rmr_in.get("gsi_superficie", "G")
    gsi_estruc = rmr_in.get("gsi_estructura", "VB")
    gsi_visual = _int(rmr_in.get("gsi_visual", 56))
    ctrl       = _int(rmr_in.get("control_estructural", 3))
    vol        = _int(rmr_in.get("efectos_voladura", 3))

    # Resistencia: código manual tiene prioridad sobre UCS calculado
    _manual_res   = (rmr_in.get("resistencia_codigo") or "").strip()
    _valid_res    = {row[2] for row in RESISTENCIA_TABLA}
    if _manual_res in _valid_res:
        res_code = _manual_res
        res_r89, res_r76 = next(
            (r89, r76) for _, _, c, r89, r76 in RESISTENCIA_TABLA if c == _manual_res
        )
    else:
        res_code, res_r89, res_r76 = resistencia_from_ucs(ucs)
    agua        = AGUA_TABLA.get(agua_code, {"r89": 15, "r76": 10})
    jv, rqd_pct = calc_jv_rqd(discontinuidades)
    rqd_r89, rqd_r76 = rqd_rating(rqd_pct)

    espac_prom = calc_espac_prom(discontinuidades)
    if espac_prom:
        er        = tabla_lookup(espac_prom, ESPACIAMIENTO_TABLA_89)
        espac_r89 = er[0] if er else 0
        er        = tabla_lookup(espac_prom, ESPACIAMIENTO_TABLA_76)
        espac_r76 = er[0] if er else 0
    else:
        espac_r89 = espac_r76 = 0

    num89 = num76 = den = 0.0
    for r in discontinuidades:
        nstr     = r["n_estructuras"]
        v89, v76 = calc_row_scores(r)
        if v89 is not None:
            num89 += v89 * nstr
        if v76 is not None:
            num76 += v76 * nstr
        if v89 is not None or v76 is not None:
            den += nstr

    condisc89 = num89 / den if den > 0 else 0
    condisc76 = num76 / den if den > 0 else 0

    rmr76 = round(agua["r76"] + res_r76 + rqd_r76 + espac_r76 + condisc76)
    rmr89 = round(agua["r89"] + res_r89 + rqd_r89 + espac_r89 + condisc89)

    fecha_raw = hdr.get("fecha") or hdr.get("fecha_mapeo") or datetime.today().strftime("%Y-%m-%d")
    campania  = _int(hdr.get("campania")) or (int(fecha_raw[:4]) if fecha_raw else datetime.today().year)

    return {
        "codigo":              hdr.get("td2") or hdr.get("codigo", ""),
        "fecha_mapeo":         fecha_raw,
        "mapeador":            hdr.get("mapeador", ""),
        "campania":            campania,
        "fase":                _int(hdr.get("fase")),
        "este_ini":            _num(hdr.get("iniX") or hdr.get("este_ini")),
        "norte_ini":           _num(hdr.get("iniY") or hdr.get("norte_ini")),
        "cota_ini":            _num(hdr.get("iniC") or hdr.get("cota_ini")),
        "este_fin":            _num(hdr.get("finX") or hdr.get("este_fin")),
        "norte_fin":           _num(hdr.get("finY") or hdr.get("norte_fin")),
        "cota_fin":            _num(hdr.get("finC") or hdr.get("cota_fin")),
        "altura_m":            _num(hdr.get("altura") or hdr.get("altura_m")),
        "dip_talud":           _int(hdr.get("dipT") or hdr.get("dip_talud")),
        "lito_1":              hdr.get("lito1") or hdr.get("lito_1") or "",
        "lito_2":              hdr.get("lito2") or hdr.get("lito_2") or "",
        "lito_3":              hdr.get("lito3") or hdr.get("lito_3") or "",
        "unidad_litologica":   hdr.get("lmtM") or hdr.get("unidad_litologica") or "",
        "alteracion_codigo":   hdr.get("altZona") or hdr.get("alteracion_codigo") or "",
        "intemperismo_codigo": hdr.get("intemp") or hdr.get("intemperismo_codigo") or "",
        "sector":              hdr.get("sector", ""),
        "nivel":               _int(hdr.get("nivel")),
        "sector_geotecnico":   hdr.get("sectG") or hdr.get("sector_geotecnico") or "",
        "rmr": {
            "agua_codigo":         agua_code,
            "resistencia_codigo":  res_code,
            "gsi_estructura":      gsi_estruc,
            "gsi_superficie":      gsi_cond,
            "gsi_visual":          gsi_visual,
            "control_estructural": ctrl,
            "efectos_voladura":    vol,
            "ucs_mpa":             round(ucs, 4),
            "is50_mpa":            round(is50, 4),
            "comentario":          rmr_in.get("comentario", ""),
            "_calc": {
                "jv":           round(jv, 6),
                "rqd_pct":      round(rqd_pct, 4),
                "espac_prom_m": round(espac_prom, 6) if espac_prom else None,
                "rmr76":        rmr76,
                "rmr89":        rmr89,
            },
        },
        "discontinuidades": discontinuidades,
    }
