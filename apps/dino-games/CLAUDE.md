Audio must complete before user input is re-enabled

## Flora series naming (Dino / Ptero / Marine Flora)

Plant instance = `(pack, formation, taxon)`. Registry: `dinoFloraPlants` in `LandGameDisplayMoment.swift`.

- **Images:** `{pack}-flora-{formation}-{taxon}-habitat` / `-seeds` (globally unique imageset names)
- **Audio:** `Audio/{Pack}-Flora/{FormationFolder}/{pack}-flora-{formation}-{taxon}.m4a`
- **Audio key:** same as filename stem (e.g. `dino-flora-morrison-cycad`)
- **FormationFolder** uses underscores (`Lance_Hell_Creek`); **formation slug** in names uses hyphens (`lance-hell-creek`)
- **Hints:** `Audio/{Pack}-Flora/hints/{pack}-hint-{concept}.m4a`

Add new plants to the registry first; CI audio contract tests must pass.
