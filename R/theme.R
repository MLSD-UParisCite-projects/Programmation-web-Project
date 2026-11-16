# ==================================================================
# Thème visuel : couleurs communes (interface + graphiques) et thème
# Bootstrap 5 (bslib). Les classes CSS sont dans www/styles.css.
# ==================================================================

# Palette unique : à réutiliser dans les graphiques
COULEURS <- c(
  principale  = "#2563eb",   # bleu : éléments principaux, courbes
  remplissage = "#93c5fd",   # bleu clair : barres et histogrammes
  remplissage2 = "#99f6e4",  # vert d'eau clair : 2e histogramme
  accent      = "#dc2626",   # rouge : densité, droite de régression
  succes      = "#15803d",
  attention   = "#b45309",
  erreur      = "#c62828",
  neutre      = "#64748b"
)

theme_app <- bslib::bs_theme(
  version   = 5,
  primary   = COULEURS[["principale"]],
  success   = COULEURS[["succes"]],
  warning   = COULEURS[["attention"]],
  danger    = COULEURS[["erreur"]],
  info      = "#0284c7",
  base_font = bslib::font_collection("system-ui", "-apple-system", "Segoe UI",
                                     "Roboto", "Helvetica Neue", "Arial", "sans-serif"),
  font_scale = 0.95,
  "navbar-bg" = "#1e293b"
)
