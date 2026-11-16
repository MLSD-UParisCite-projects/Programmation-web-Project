# UX evaluation of the Shiny app: tabs 1 to 5 (data, preparation, exploration, modelling, case study)

Reviewed from the code at commit `3c87346` (app.R, modules/, R/). The app was not run.

## Anti-pattern verdict

Clean. No deceptive or manipulative patterns. Two common UX failures from the catalog appear: a dead-end page (tab 5) and silent destructive actions (reset and history wipe without confirmation). Both are listed below as findings.

## Priority issues

### Critical

**A multiclass target is accepted in tab 1 and rejected only in tab 4.**
Where: `verifier_cible()` in R/cible.R treats 3 to 20 classes as valid (a warning only above 10), so "Valider" succeeds; the 2-class check lives in the training observer, mod_modelisation.R:196.
Why it matters: three of the ten datasets in the brief are multiclass (Dermatology has 6 classes, Cardiotocography 3 or 10, Mice Protein 8). A user picks one of those, cleans it, explores it, configures both models, clicks "Entraîner" and only then learns the whole pipeline cannot model it. The teacher testing the deployed app with a multiclass file hits a hard stop at the step that carries the most marks.
Heuristic: error prevention.
Change: decide the target's class count at selection time. In tab 1, when the target has more than 2 classes, say so next to the selector ("La modélisation compare 2 classes") and offer a one-vs-rest choice: pick the positive class, the others become "Autre". Then tab 4 never receives a target it cannot use.

### Major

**The training summary shows the current slider values, not the values the models were trained with.**
Where: `output$bilan_entrainement`, mod_modelisation.R:341-342, reads `input$classe_positive` and `input$seuil` live.
Why it matters: after training, moving the threshold slider or changing the positive class updates the banner ("Classe positive = 'X' (seuil = 0.70)") while the metrics table, ROC and confusion matrices still come from the old run. The screen then states a configuration that did not produce the numbers under it, which is the worst kind of status error in a results view, and easy to screenshot into the case study report.
Heuristic: visibility of system status.
Change: store the positive class and threshold in `rv$dernier` at training time and display those. When the sidebar no longer matches the last run, show a "Paramètres modifiés : relancez l'entraînement" notice like the one tab 1 already uses.

**Training gives no progress feedback and accepts repeat clicks.**
Where: `btn_entrainer`, mod_modelisation.R:176. Random Forest with 300 trees, auto-tune on, or a wide dataset (Arcene has 10 000 columns) can take many seconds.
Why it matters: nothing on screen changes until the end, so a user clicks again. Each extra click queues a full second training and adds duplicate rows to the run history, which then pollutes the comparison table and the multi-run ROC plot.
Heuristic: visibility of system status.
Change: disable the button and show a progress message per step (découpage, logistique, forêt) while training runs; re-enable it when done.

**Reset and history wipe destroy work with no confirmation and no undo.**
Where: "Réinitialiser" in tab 2 history (`hist_reinitialiser` keeps only step 0), "Vider l'historique" and "Supprimer les runs sélectionnés" in tab 4.
Why it matters: the red reset button sits next to "Annuler la dernière étape". One misclick discards the whole cleaning sequence, and "Annuler" cannot bring it back because the steps are gone. Clearing the run history loses every model result the case study depends on.
Heuristics: user control and freedom; error prevention.
Change: ask for confirmation stating what is lost ("Supprimer les 6 étapes de nettoyage ?"), or keep the previous history so the reset itself can be undone.

**Tab 5 "Étude de cas" is an empty page.**
Where: app.R:20, a bare `h3()`.
Why it matters: it is a numbered step in the navigation, so a user following 1 to 5 ends on a heading and nothing else. The brief requires a full case study inside the interface.
Heuristic: aesthetic and minimalist design (a navigation item that leads nowhere); common UX failure: dead-end page.
Change: until the content exists, hide the tab or show what it will contain. The final page should let the reader load the chosen dataset in one click and walk through its findings tab by tab.

**The first screen is blank until the user finds an English "Load" button.**
Where: tab 1. Choosing a file shows Shiny's "Upload complete" bar, then nothing: every main-panel output waits on `input$go`. The button is labelled "Load" in an otherwise French interface. Changing the separator or decimal afterwards also does nothing until "Load" is clicked again, with no hint that the preview is stale.
Why it matters: "Upload complete" reads as done, so the user waits on an empty page. A wrong separator choice is caught well (R/lecture.R:25), but only after they find the button.
Heuristics: visibility of system status; consistency and standards.
Change: relabel it "Charger", put a short empty state in the main panel ("Choisissez un fichier CSV puis cliquez sur Charger"), and flag the preview as outdated when a reading option changes after loading. A "Charger un jeu d'exemple" button would also let the teacher try the app without preparing a file.

### Minor

**Successful cleaning operations give feedback only at the top of the page.**
Where: tab 2, operations A to E. Only no-op cases raise a notification; a successful one just updates the summary box at the top of the main panel and the button labels.
Why it matters: the sidebar is long, so after scrolling to D or E the summary is off screen and the click looks ignored.
Heuristic: visibility of system status.
Change: show a short notification on success ("Plafonnement de 37 valeurs sur 4 colonnes"), the same text already written to the history.

**Outlier capping is preselected on every column with outliers.**
Where: tab 2 section C. `cols_outliers` is prefilled with all columns that have IQR outliers and the method defaults to "Plafonner".
Why it matters: one click caps every flagged value. On medical datasets an extreme value is often the signal (a very high cholesterol or tumour size), and capping it can weaken the models without the user having chosen to. Undo exists, so the damage is recoverable.
Heuristic: error prevention.
Change: default the method to "Garder" or leave the column list empty, and show the outlier count per column so the choice is deliberate.

**Raw R error text and code-style column names reach the user.**
Where: read errors pass `conditionMessage(e)` (often English, e.g. "more columns than column names", or an encoding error on a Latin-1 French CSV since `fileEncoding = "UTF-8"` is fixed); table headers show `A_verifier`, `Type_final`, `Corrige`, `Probleme`, `Gravite`, `F_score`.
Why it matters: the user sees the internals instead of a cause and a fix.
Heuristics: match between system and real world; help users recognize, diagnose, and recover from errors.
Change: map the common read errors to French messages with a suggestion (check separator, header, or encoding), and give tables display names with accents and spaces.

**Confusion matrices are printed R console output.**
Where: `verbatimTextOutput` in tab 4.
Why it matters: rows and columns are not labelled "réel" and "prédit", so the reader has to know R's `table()` layout to read it.
Heuristic: match between system and real world.
Change: render it as a labelled table with the positive class marked.

**Plots have no text alternative.**
Where: every `renderPlot` uses the default alt text.
Why it matters: screen reader users get nothing from the exploration and ROC views.
Heuristic: accessibility (outside Nielsen's ten).
Change: pass `alt =` to `renderPlot` with the variable names and the key figure (e.g. "ROC, AUC logistique 0.91, forêt 0.94").

### Cosmetic

**The row-NA threshold is set in two places.**
Where: tab 1 "Vérifications" and tab 2 section B. Tab 2 copies tab 1's value at validation, then they diverge.
Change: keep one control, or label the second as "repris de l'onglet 1".

## Heuristic verdicts

- Visibility of system status: broken (training summary shows the current slider values)
- Match between system and real world: strained (raw R error text and code-style column names)
- User control and freedom: broken (reset and history wipe)
- Consistency and standards: strained (English "Load" button)
- Error prevention: broken (multiclass target)
- Recognition rather than recall: holds
- Flexibility and efficiency of use: holds
- Aesthetic and minimalist design: broken (empty case study tab)
- Help users recognize, diagnose, and recover from errors: strained (raw R error text)
- Help and documentation: holds

## Cognitive walkthrough results

Task: load a UCI multiclass CSV (Dermatology) and compare the two models.

| Step | Motivation | Visibility | Understanding | Feedback | Finding |
|---|---|---|---|---|---|
| Choose the file | yes | yes | yes | no | The first screen is blank until the user finds an English "Load" button |
| Click "Load" | yes | no | no | yes | The first screen is blank until the user finds an English "Load" button |
| Validate the target | no | yes | yes | yes | A multiclass target is accepted in tab 1 and rejected only in tab 4 |
| Apply a cleaning step from the bottom of the sidebar | yes | yes | yes | no | Successful cleaning operations give feedback only at the top of the page |
| Click "Entraîner les modèles" | yes | yes | yes | no | A multiclass target is accepted in tab 1 and rejected only in tab 4; Training gives no progress feedback |
| Adjust the threshold to read the results | yes | yes | no | no | The training summary shows the current slider values |

## Positive findings

- The data leakage handling is explained where the user configures it: the blue note in "Transformations" says the parameters are learned on train only, and the training summary repeats what was applied.
- Buttons in tab 2 carry their own count ("Supprimer les 12 ligne(s) avec plus de 50 % de NA"), so the user knows the effect before clicking.
- The cleaning history with step-by-step undo and "revenir à l'étape" is a strong recovery model; protect it when adding confirmation to reset.
- Tab 1 states detected types as suggestions and lets the user override them, with corrected rows highlighted.
- The validation gate shows "Modifications non validées" when tab 1 has drifted from what the other tabs use.
- A wrong separator is caught and named ("le séparateur est probablement mauvais").
- Exploration adapts its plots and statistics to the variable types and says which case applies.
- Model runs are archived with their split, pipeline and parameters, best F-score and AUC are highlighted, and the history exports to CSV.

## Recommended actions

1. A multiclass target is accepted in tab 1 and rejected only in tab 4
2. The training summary shows the current slider values, not the values the models were trained with
3. Tab 5 "Étude de cas" is an empty page
4. Training gives no progress feedback and accepts repeat clicks
5. Reset and history wipe destroy work with no confirmation and no undo
6. The first screen is blank until the user finds an English "Load" button
7. Outlier capping is preselected on every column with outliers
8. Successful cleaning operations give feedback only at the top of the page
9. Raw R error text and code-style column names reach the user
10. Confusion matrices are printed R console output
11. Plots have no text alternative
12. The row-NA threshold is set in two places
