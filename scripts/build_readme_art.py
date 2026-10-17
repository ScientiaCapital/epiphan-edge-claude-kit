"""Rebuild the README art in docs/assets: banner, /find-problems card and diagram, in English and Spanish.

Both READMEs use the same layout, so every image exists once per language (`-en`, `-es`). Banner and diagram
also come in light and dark for GitHub's `<picture>` switch; the card is dark in both themes.

Colors are Epiphan Brand MCP tokens (get_style_tokens, colors): Edge is a cloud product, so it uses the vibrant
palette (teal, indigo), with green kept for "online" and "Ready". Priority labels are never red or coral, to match
the calm tone in CLAUDE.md. The logos are the official Brand MCP assets, saved byte-identical in
docs/assets/epiphan-logo*.svg (copied from pearl-episodes); this script only nests them, never edits them.

    python3 scripts/build_readme_art.py
"""

from __future__ import annotations

import re
from html import escape
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "docs" / "assets"
FONT = "Söhne,-apple-system,Segoe UI,Helvetica,Arial,sans-serif"
MONO = "Söhne Mono,ui-monospace,SFMono-Regular,Menlo,monospace"

LIGHT = {
    "bg": "#f1f2f0",
    "fg": "#111111",
    "muted": "#5a5a5a",
    "box": "#ffffff",
    "line": "#c9ccd4",
    "arrow": "#4a4aaf",
    "accent": "#0c3d34",
    "logo": "epiphan-logo-horizontal.svg",
}
DARK = {
    "bg": "#0d231f",
    "fg": "#ffffff",
    "muted": "#cfd3dc",
    "box": "#0c3d34",
    "line": "#316472",
    "arrow": "#d7daf9",
    "accent": "#6651fc",
    "logo": "epiphan-logo-horizontal-light.svg",
}
GREEN = "#83ce41"
AMBER = "#f5a524"

TEXT = {
    "en": {
        "tagline": "Ask your rooms in plain words",
        "ask": "> /check-room 204",
        "answer": "Room 204: Ready",
        "banner_label": "Epiphan Edge and Claude Code: ask your rooms in plain words",
        "card_label": "Example /find-problems output: two items, Fix first and Fix soon, and a storage note",
        "head": ("Priority", "Device", "What's going on", "How we know", "Suggested fix"),
        "rows": (
            ("Fix first", "Lecture 204", "No picture from Camera 2", "Next class at 2 p.m.",
             "Check the SDI cable at the rack"),
            ("Fix soon", "Auditorium", "Firmware one version back", "4.x.5, others on 4.x.6", "/fix-problem 2"),
        ),
        "fyi": ("FYI: 2 Pearls have little or no local space left. That's normal when recordings upload",
                "to your video platform (Panopto, Kaltura, or Edge) after each class."),
        "diagram_label": "You ask Claude Code in plain words. Claude Code, guarded by the kit's hooks, reads your "
                         "rooms through the Epiphan Edge MCP server, and every change asks you first.",
        "you": ("You", "in plain words"),
        "claude": ("Claude Code", "write guard + redaction"),
        "edge": ("Epiphan Edge", "your team"),
        "rooms": "ROOMS",
        "callout": "Reads run on their own. Every change asks you first.",
        "folder": "IN THIS FOLDER",
        "parts": ((".claude/commands/", "ten slash commands"), ("CLAUDE.md", "rules, tone, language"),
                  (".claude/hooks/", "write guard, redaction")),
    },
    "es": {
        "tagline": "Pregúntale a tus salas en palabras sencillas",
        "ask": "> /check-room 204",
        "answer": "Sala 204: Listo",
        "banner_label": "Epiphan Edge y Claude Code: pregúntale a tus salas en palabras sencillas",
        "card_label": "Ejemplo de salida de /find-problems: dos puntos, Arreglar primero y Arreglar pronto, y una "
                      "nota de almacenamiento",
        "head": ("Prioridad", "Dispositivo", "Qué pasa", "Cómo lo sabemos", "Arreglo sugerido"),
        "rows": (
            ("Arreglar primero", "Lecture 204", "No hay imagen de Camera 2", "Próxima clase a las 2 p.m.",
             "Revisar el cable SDI en el rack"),
            ("Arreglar pronto", "Auditorium", "Firmware una versión atrás", "4.x.5, los demás en 4.x.6",
             "/fix-problem 2"),
        ),
        "fyi": ("Nota: 2 Pearl tienen poco o nada de espacio local. Es normal cuando las grabaciones se suben",
                "a tu plataforma de video (Panopto, Kaltura o Edge) después de cada clase."),
        "diagram_label": "Le preguntas a Claude Code en palabras sencillas. Claude Code, protegido por los hooks del "
                         "kit, consulta tus salas a través del servidor MCP de Epiphan Edge, y cada cambio te "
                         "pregunta antes.",
        "you": ("Tú", "en palabras sencillas"),
        "claude": ("Claude Code", "aprobación + claves ocultas"),
        "edge": ("Epiphan Edge", "tu equipo"),
        "rooms": "SALAS",
        "callout": "Las consultas corren solas. Cada cambio te pregunta antes.",
        "folder": "EN ESTA CARPETA",
        "parts": ((".claude/commands/", "diez comandos"), ("CLAUDE.md", "reglas, tono, idioma"),
                  (".claude/hooks/", "aprobación, claves ocultas")),
    },
}


def logo_drawing(name: str) -> str:
    """The logo's drawing, without the XML declaration or its own <svg> wrapper."""
    svg = re.sub(r"<\?xml[^>]*\?>", "", (ASSETS / name).read_text(encoding="utf-8"))
    return re.sub(r"^.*?<svg[^>]*>|</svg>\s*$", "", svg.strip(), flags=re.S)


def banner(t: dict[str, str], s: dict) -> str:
    dots = []
    for row in range(2):
        for col in range(8):
            fill = AMBER if (row, col) == (1, 5) else GREEN
            dots.append(f'<circle cx="{614 + col * 30}" cy="{146 + row * 26}" r="8" fill="{fill}"/>')
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="880" height="200" viewBox="0 0 880 200" role="img" aria-label="{escape(s["banner_label"])}">
  <rect width="880" height="200" rx="16" fill="{t["bg"]}"/>
  <svg x="30" y="14" width="180" height="50" viewBox="0 0 358.2 99.5">{logo_drawing(t["logo"])}</svg>
  <text x="48" y="120" font-family="{FONT}" font-size="36" font-weight="600" fill="{t["fg"]}">Epiphan Edge × Claude Code</text>
  <text x="50" y="158" font-family="{FONT}" font-size="19" fill="{t["muted"]}">{escape(s["tagline"])}</text>
  <rect x="600" y="28" width="240" height="32" rx="8" fill="{t["box"]}" stroke="{t["line"]}"/>
  <text x="616" y="49" font-family="{MONO}" font-size="14" fill="{t["fg"]}">{escape(s["ask"])}</text>
  <rect x="600" y="70" width="240" height="32" rx="8" fill="{t["accent"]}"/>
  <circle cx="620" cy="86" r="6" fill="{GREEN}"/>
  <text x="634" y="91" font-family="{FONT}" font-size="15" font-weight="600" fill="#ffffff">{escape(s["answer"])}</text>
  {"".join(dots)}
</svg>
"""


def card(s: dict) -> str:
    cols = (40, 190, 300, 520, 740)
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="268" viewBox="0 0 1000 268" role="img" '
        f'aria-label="{escape(s["card_label"])}" font-family="{FONT}">',
        '<rect width="1000" height="268" rx="16" fill="#0d231f"/>',
        '<circle cx="28" cy="24" r="6" fill="#316472"/><circle cx="48" cy="24" r="6" fill="#316472"/>'
        '<circle cx="68" cy="24" r="6" fill="#316472"/>',
        f'<text x="40" y="66" font-family="{MONO}" font-size="15" fill="{GREEN}">&gt; /find-problems</text>',
    ]
    parts += [f'<text x="{x}" y="104" font-size="13" font-weight="600" fill="#cfd3dc">{escape(h)}</text>'
              for x, h in zip(cols, s["head"])]
    parts.append('<path d="M40 116 L960 116" stroke="#316472"/>')
    pills = (("#2a2959", "#d7daf9"), ("#316472", "#e2f7f5"))
    for i, row in enumerate(s["rows"]):
        y = 146 + i * 38
        fill, ink = pills[i]
        parts.append(f'<rect x="{cols[0] - 8}" y="{y - 17}" width="{len(row[0]) * 8 + 16}" height="25" rx="12" '
                     f'fill="{fill}"/>')
        parts.append(f'<text x="{cols[0]}" y="{y}" font-size="14" font-weight="600" fill="{ink}">'
                     f'{escape(row[0])}</text>')
        for x, cell in zip(cols[1:], row[1:]):
            font = f' font-family="{MONO}"' if cell.startswith("/") else ""
            parts.append(f'<text x="{x}" y="{y}" font-size="14" fill="#ffffff"{font}>{escape(cell)}</text>')
    parts += [f'<text x="40" y="{226 + i * 20}" font-size="13" fill="#cfd3dc">{escape(line)}</text>'
              for i, line in enumerate(s["fyi"])]
    parts.append("</svg>")
    return "\n  ".join(parts) + "\n"


def node(x: int, y: int, w: int, h: int, title: str, sub: str, t: dict[str, str], mono: bool = False) -> str:
    font = f' font-family="{MONO}"' if mono else ""
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="{t["box"]}" stroke="{t["line"]}"/>\n  '
        f'<text x="{x + w / 2}" y="{y + h / 2 - 6}" text-anchor="middle" dominant-baseline="middle" font-size="14" '
        f'font-weight="600" fill="{t["fg"]}"{font}>{escape(title)}</text>\n  '
        f'<text x="{x + w / 2}" y="{y + h / 2 + 13}" text-anchor="middle" dominant-baseline="middle" font-size="12" '
        f'fill="{t["muted"]}">{escape(sub)}</text>'
    )


def arrow(x1: int, y1: int, x2: int, y2: int, t: dict[str, str], label: str = "") -> str:
    out = f'<path d="M{x1} {y1} L{x2} {y2}" stroke="{t["arrow"]}" stroke-width="2" fill="none" marker-end="url(#head)"/>'
    if label:
        out += (f'\n  <text x="{(x1 + x2) / 2}" y="{y1 - 9}" text-anchor="middle" font-size="11" '
                f'fill="{t["muted"]}">{escape(label)}</text>')
    return out


def diagram(t: dict[str, str], s: dict) -> str:
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="880" height="310" viewBox="0 0 880 310" role="img" '
        f'aria-label="{escape(s["diagram_label"])}" font-family="{FONT}">',
        '<defs><marker id="head" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
        f'orient="auto-start-reverse"><path d="M0 0 L10 5 L0 10 z" fill="{t["arrow"]}"/></marker></defs>',
        f'<rect width="880" height="310" rx="16" fill="{t["bg"]}"/>',
        node(30, 50, 150, 60, *s["you"], t),
        f'<path d="M182 80 L218 80" stroke="{t["arrow"]}" stroke-width="2" fill="none" '
        'marker-start="url(#head)" marker-end="url(#head)"/>',
        node(220, 50, 220, 60, *s["claude"], t),
        arrow(440, 80, 498, 80, t, "MCP"),
        node(500, 50, 150, 60, *s["edge"], t),
        arrow(650, 80, 688, 80, t),
        f'<rect x="690" y="36" width="170" height="88" rx="10" fill="none" stroke="{t["line"]}" '
        'stroke-dasharray="5 4"/>',
        f'<text x="775" y="28" text-anchor="middle" font-size="12" font-weight="600" fill="{t["muted"]}">'
        f'{escape(s["rooms"])}</text>',
        f'<rect x="702" y="50" width="72" height="60" rx="8" fill="{t["accent"]}"/>',
        '<text x="738" y="81" text-anchor="middle" dominant-baseline="middle" font-size="14" font-weight="600" '
        'fill="#ffffff">Pearl</text>',
        f'<rect x="780" y="50" width="68" height="60" rx="8" fill="{t["box"]}" stroke="{t["line"]}"/>',
        f'<text x="814" y="81" text-anchor="middle" dominant-baseline="middle" font-size="14" font-weight="600" '
        f'fill="{t["fg"]}">EC20</text>',
        f'<circle cx="352" cy="146" r="5" fill="{GREEN}"/>',
        f'<text x="364" y="151" font-size="13" fill="{t["fg"]}">{escape(s["callout"])}</text>',
        f'<path d="M330 112 L330 190 M150 190 L730 190 M150 190 L150 218 M440 190 L440 218 M730 190 L730 218" '
        f'stroke="{t["line"]}" stroke-width="2" stroke-dasharray="4 4" fill="none"/>',
        f'<text x="30" y="212" font-size="12" font-weight="600" fill="{t["muted"]}">{escape(s["folder"])}</text>',
    ]
    for x, (title, sub) in zip((30, 320, 610), s["parts"]):
        parts.append(node(x, 220, 240, 60, title, sub, t, mono=True))
    parts.append("</svg>")
    return "\n  ".join(parts) + "\n"


def main() -> None:
    for lang, s in TEXT.items():
        (ASSETS / f"find-problems-{lang}.svg").write_text(card(s), encoding="utf-8")
        for name, theme in (("light", LIGHT), ("dark", DARK)):
            (ASSETS / f"banner-{lang}-{name}.svg").write_text(banner(theme, s), encoding="utf-8")
            (ASSETS / f"architecture-{lang}-{name}.svg").write_text(diagram(theme, s), encoding="utf-8")
    print(f"wrote banners, cards and diagrams (en, es) in {ASSETS}")


if __name__ == "__main__":
    main()
