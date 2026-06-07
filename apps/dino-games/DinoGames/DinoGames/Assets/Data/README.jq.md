
1. Identify current libraries in large JSON file
% jq -r '.metadata.libraries | keys[]' fourth.json  
asset_manifest_template
characters
era_manifests
fauna
flora
formation_logic
framing_presets
habitat_logic
habitats
lighting_config_defaults
lighting_presets
style_presets
technical_specs


2. Merge multiple JSON files
% cp matrix.json small.json
% cp environment_config.json large.json
% jq '. | keys' small.json  
[
  "dino_matrix",
  "marine_matrix",
  "ptero_matrix"
]
% jq '.metadata.libraries | keys' large.json 
[
  "asset_manifest_template",
  "characters",
  "era_manifests",
  "fauna",
  "flora",
  "formation_logic",
  "framing_presets",
  "habitat_logic",
  "habitats",
  "lighting_config_defaults",
  "lighting_presets",
  "style_presets",
  "technical_specs"
]
% jq --argjson small "$(cat small.json)" '
  .metadata.libraries.matrix_materials = (.metadata.libraries.matrix_materials // {}) * $small
' large.json > large_updated.json
% ls -l large_updated.json 
-rw-r--r--  1 tim  staff  151491 Jun  3 10:32 large_updated.json
% cat large_updated | jq .
% jq '.metadata.libraries | keys' large_updated.json
[
  "asset_manifest_template",
  "characters",
  "era_manifests",
  "fauna",
  "flora",
  "formation_logic",
  "framing_presets",
  "habitat_logic",
  "habitats",
  "lighting_config_defaults",
  "lighting_presets",
  "matrix_materials",
  "style_presets",
  "technical_specs"
]
% cp large_updated.json environment_config.json
