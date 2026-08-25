#!/usr/bin/env python3
"""
WCAG 2.2 Contrast Checker (skill: engenharia-de-ui-ux)

Calcula a razao de contraste entre duas cores e reporta quais niveis de
conformidade WCAG 2.2 ela atinge, para texto (SC 1.4.3 / 1.4.6) e para
componentes de UI nao-textuais (SC 1.4.11).

Uso:
    python contrast-check.py <hex_texto_ou_elemento> <hex_fundo> [--large] [--ui]

Exemplos:
    python contrast-check.py "#333333" "#FFFFFF"
    python contrast-check.py "#767676" "#FFFFFF" --large
    python contrast-check.py "#0057FF" "#FFFFFF" --ui
"""
import sys
import argparse


def _hex_to_rgb(hex_color):
    hex_color = hex_color.strip().lstrip('#')
    if len(hex_color) == 3:
        hex_color = ''.join(c * 2 for c in hex_color)
    if len(hex_color) != 6:
        raise ValueError(
            f"Cor hex invalida: '{hex_color}'. Use o formato #RRGGBB ou #RGB."
        )
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return r, g, b


def _relative_luminance(rgb):
    def channel(c):
        c = c / 255.0
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = rgb
    r_lin, g_lin, b_lin = channel(r), channel(g), channel(b)
    return 0.2126 * r_lin + 0.7152 * g_lin + 0.0722 * b_lin


def contrast_ratio(hex_a, hex_b):
    lum_a = _relative_luminance(_hex_to_rgb(hex_a))
    lum_b = _relative_luminance(_hex_to_rgb(hex_b))
    lighter, darker = max(lum_a, lum_b), min(lum_a, lum_b)
    return (lighter + 0.05) / (darker + 0.05)


def evaluate(ratio, large_text=False, ui_component=False):
    """Retorna um dict com quais criterios de sucesso WCAG 2.2 sao atingidos."""
    if ui_component:
        # SC 1.4.11 Non-text Contrast (AA) - 3:1, sem equivalente AAA definido
        return {
            "criterion": "1.4.11 Non-text Contrast",
            "aa_required": 3.0,
            "aaa_required": None,
            "aa_pass": ratio >= 3.0,
            "aaa_pass": None,
        }
    aa_required = 3.0 if large_text else 4.5
    aaa_required = 4.5 if large_text else 7.0
    criterion = "1.4.6 Contrast (Enhanced)" if large_text else "1.4.3 Contrast (Minimum)"
    return {
        "criterion": criterion,
        "aa_required": aa_required,
        "aaa_required": aaa_required,
        "aa_pass": ratio >= aa_required,
        "aaa_pass": ratio >= aaa_required,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Verifica contraste WCAG 2.2 entre duas cores."
    )
    parser.add_argument("foreground", help="Cor do texto/elemento em hex (ex: #333333)")
    parser.add_argument("background", help="Cor de fundo em hex (ex: #FFFFFF)")
    parser.add_argument(
        "--large", action="store_true",
        help="Trata como texto grande (>=24px, ou >=18.66px em negrito)"
    )
    parser.add_argument(
        "--ui", action="store_true",
        help="Trata como componente de UI nao-textual (icone, borda de input) - SC 1.4.11"
    )
    args = parser.parse_args()

    try:
        ratio = contrast_ratio(args.foreground, args.background)
    except ValueError as e:
        print(f"Erro: {e}")
        sys.exit(1)

    result = evaluate(ratio, large_text=args.large, ui_component=args.ui)

    print(f"Razao de contraste: {ratio:.2f}:1")
    print(f"Criterio avaliado: WCAG 2.2 SC {result['criterion']}")
    aa_status = "PASS" if result["aa_pass"] else "FAIL"
    print(f"  Nivel AA (minimo {result['aa_required']}:1): {aa_status}")
    if result["aaa_required"] is not None:
        aaa_status = "PASS" if result["aaa_pass"] else "FAIL"
        print(f"  Nivel AAA (minimo {result['aaa_required']}:1): {aaa_status}")
    else:
        print("  Nivel AAA: nao definido para este criterio (1.4.11 nao tem equivalente AAA)")

    sys.exit(0 if result["aa_pass"] else 1)


if __name__ == "__main__":
    main()