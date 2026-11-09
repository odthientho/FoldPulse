#!/usr/bin/env python3
"""WCAG 2.x contrast check for FoldPulse colour tokens (light & dark)."""
TOKENS = {
    "light": {"bg": "#F2F4F8", "surface": "#FFFFFF", "text": "#0B1B33", "text2": "#55606E",
              "accentText": "#1D5FD8", "accent": "#2F7BFF", "shortcut": "#0B6F85", "manual": "#55606E",
              "positive": "#1E7F4F", "warning": "#A15C00", "destructive": "#C2362B"},
    "dark":  {"bg": "#070F1F", "surface": "#12233F", "text": "#FFFFFF", "text2": "#9FB1CF",
              "accentText": "#6FA2FF", "accent": "#4C8DFF", "shortcut": "#5CC8FF", "manual": "#B4C0D3",
              "positive": "#5BD08E", "warning": "#FFB547", "destructive": "#FF6B5E"},
}

def lum(hexc):
    r, g, b = (int(hexc[i:i+2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)

def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

rows, failures = [], 0
for mode, t in TOKENS.items():
    for fg in ["text", "text2", "accentText", "shortcut", "manual", "positive", "warning", "destructive", "accent"]:
        for bgk in ["bg", "surface"]:
            r = ratio(t[fg], t[bgk])
            need = 3.0 if fg == "accent" else 4.5   # raw accent only for large text / graphics
            ok = r >= need
            failures += not ok
            rows.append(f"| {mode} | `{fg}` {t[fg]} | `{bgk}` {t[bgk]} | {r:.2f}:1 | {need}:1 | {'Pass' if ok else 'FAIL'} |")
print("| Mode | Foreground | Background | Ratio | Required | Result |\n|---|---|---|---|---|---|")
print("\n".join(rows))
print(f"\nFailures: {failures}")
