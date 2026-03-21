# Dental Morphology Source of Truth

**Purpose:** Record which source was used for dinosaur–tooth morphology mappings in Dino Toothache, and why. If these games are reviewed by paleontology professionals, expect praise for their existence followed by harsh criticism for mistakes. This document helps remember the thinking at the time and what to do differently if the source changes.

---

## Current Source (as of this note)

| Item | Value |
|------|-------|
| **Source** | Google Gemini |
| **Model** | Gemini 3 Flash |
| **Tier** | Free |
| **Image generation** | Nano Banana 2 |
| **Use** | Dinosaur → tooth morphology mappings in `ToothacheGameView.swift` (`dinoToothacheToothTypeBySlug`) |

Gemini was confident in its recommendations; the tooth images were crafted based on that data. Note: Gemini’s opinions can change between sessions—double-checking later may yield different answers.

---

## If You Pivot to a Different Source

When changing the source of truth (e.g. after professional feedback or to use peer‑reviewed literature):

1. **Update this file** – Replace the table above with the new source, model/version, and date.
2. **Document the reason** – Why the pivot? (e.g. “Paleontologist review identified X errors; switching to [source].”)
3. **Re-audit all mappings** – Don’t assume the new source agrees with the old; re-check every dinosaur.
4. **Consider image regeneration** – If tooth images were generated from the old source, they may need to be regenerated to match the new taxonomy.
5. **Version the change** – Add a dated entry below when you pivot.

---

## Pivot History

*(Add entries here when you change sources.)*

| Date | From | To | Reason |
|------|------|----|--------|
| — | — | — | — |
