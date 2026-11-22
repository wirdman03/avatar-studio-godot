# Avatar Studio

**Avatar Studio 0.1.0-preview.1** est un éditeur d’avatars 3D réutilisable dans Godot. Essaie la démo avec Ari, puis branche ton propre modèle et un catalogue JSON pour choisir ses coiffures, vêtements, couleurs et expressions.

Le projet contient un éditeur, un composant de personnage 3D utilisable seul et la démo Ari. Les ressources de la démo sont locales et le projet fonctionne hors ligne.

![La démo d’Avatar Studio dans Godot](preuves/01-demo.png)

## Essayer

Ouvre `project.godot` dans **Godot 4.7.2** et lance le projet avec F5. Choisis **Avatar** ou **Tenue**, touche une vignette pour essayer un choix, puis glisse sur l’aperçu pour tourner Ari. Le blouson affiche sa palette à droite de l’aperçu. Les flèches permettent d’annuler et de rétablir. **Enregistrer** garde le choix sur cet appareil.

## Ajouter le créateur à un autre projet

Copie `addons/avatar_studio/` dans ton projet et ajoute un catalogue local JSON et son modèle 3D. Le catalogue de démonstration est dans `demo/modeles/`.

Avec l’écran fourni :

```gdscript
var studio := AvatarStudioEditor.new()
studio.catalogue_path = "res://avatars/catalogue.json"
studio.save_requested.connect(_save_look)
add_child(studio)
studio.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
```

L’application reçoit un dictionnaire d’identifiants. Elle choisit comment le sauvegarder. Pour charger une apparence déjà enregistrée, appelle `studio.restore(choices)` après le signal `catalogue_loaded`.

Pour afficher le bouton **Fermer**, règle `studio.show_close_button = true` avant d’ajouter l’éditeur à la scène, puis connecte le signal `close_requested` à la navigation de l’application.

Pour utiliser uniquement le personnage, instancie `AvatarStudioCharacter`, appelle `configure(catalogue_path)`, puis `choose(category, option)`. `get_choices()` renvoie une copie indépendante. `restore(choices)` accepte un ensemble complet de choix et refuse les identifiants inconnus sans modifier le personnage.

### Catalogue

`model` référence une scène 3D Godot ou un GLB par chemin local. `name` fournit le nom affiché. Chaque catégorie possède un identifiant, un libellé, au moins une option et un identifiant par défaut.

Les catégories apparaissent dans **Avatar** par défaut. `section: "wardrobe"` place une catégorie dans **Tenue**. `framing` accepte `face`, `upper` ou `full` et règle le cadrage à la sélection de la catégorie. `thumbnailFraming` permet de régler séparément le cadrage des vignettes. Avec `thumbnailParts`, le rendu peut se limiter aux nœuds 3D nommés, en plus du groupe sélectionné par l’option. Les aperçus sont calculés avec une seconde instance du personnage.

| Option | Effet |
| --- | --- |
| `group` | Affiche le nœud 3D nommé, par exemple une coiffure ou un haut. |
| `morph` et `weight` | Appliquent une déformation nommée. Le poids va de 0 à 1. |
| `material` et `color` | Changent la couleur d’un matériau standard sur cet avatar. Le dictionnaire optionnel `tints` peut teinter d’autres matériaux dans le même choix, par exemple les reflets des cheveux. |
| `clear: true` | Retire les options de la catégorie, par exemple les lunettes. |

Les nœuds interchangeables doivent avoir des noms uniques. Évite de piloter le même nœud, matériau ou morph depuis deux catégories. Pour les catégories de couleur, `swatches: true` remplace les vignettes 3D par des pastilles. Pour un export Godot, ajoute les catalogues `*.json` aux filtres d’inclusion et inclue les scènes ou GLB qu’ils référencent. Le chargement se fait à partir des chemins indiqués dans les fichiers JSON.

`railGroup` regroupe plusieurs catégories voisines sous une icône. La première catégorie fournit le libellé de la famille, avec `railGroupLabel` pour le préciser et `railLabel` pour les libellés des sous-onglets. Une catégorie de couleurs peut utiliser `paletteFor` pour s’attacher à l’identifiant d’une catégorie de vêtements et `paletteItems` pour limiter la palette aux pièces recolorables. `palettePlacement: "preview"` place une palette autonome à côté de l’avatar. `thumbnailFromCategory` ajoute le modèle choisi dans une autre catégorie aux vignettes 3D, par exemple la coupe courante dans les couleurs des cheveux.

### Vérifier et régénérer la démo

```sh
godot --headless --path . --import
godot --headless --path . --script tests/test_character.gd
godot --path . --script tests/capturer.gd
godot --path . --script tests/capturer.gd -- --wide
```

Le premier test vérifie notamment l’indépendance de deux avatars et l’import d’un catalogue différent. Le second utilise les boutons de l’écran réel avec le rendu graphique actif. Pour régénérer le modèle Ari, lance `godot --headless --path . --script sources/generate_demo.gd`.

## Licence

Le [code et la documentation sont sous licence MIT](LICENSE). [Ari et son catalogue sont sous CC0 1.0](demo/modeles/NOTICE.md).

## Compatibilité

Cette préversion utilise Godot 4.7.2 et le moteur de rendu Compatibility. La démo utilise une pose fixe et un réglage de sourire. L’intégration de ton modèle demande un catalogue qui nomme les pièces, matériaux ou déformations à modifier.
