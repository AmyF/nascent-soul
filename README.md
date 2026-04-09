# NascentSoul

NascentSoul is a Godot 4.6 zone toolkit for both card games and battlefield tactics. It keeps one shared `Zone` core for selection, drag/drop, display, preview, and runtime state, then lets each family swap in the right spatial model:

- `CardZone` for ordered, linear card containers such as hand, deck, discard, shop, and board rows
- `BattlefieldZone` for square and hex grids with cell occupancy, piece movement, and card-to-board transfer rules

`Zone` stays inspector-friendly through presets and composable resources. Layout, display, interaction, transfer rules, space resolution, sorting, and drag visuals are all resources instead of hardcoded branches.

## Architecture

```mermaid
flowchart LR
    Zone["Zone (Control Core)"] --> Runtime["ZoneRuntime"]
    Zone --> Items["ItemsRoot"]
    Zone --> Preview["PreviewRoot"]
    Zone --> Preset["ZonePreset"]
    Preset --> Space["ZoneSpaceModel"]
    Preset --> Layout["ZoneLayoutPolicy"]
    Preset --> Display["ZoneDisplayStyle"]
    Preset --> Interaction["ZoneInteraction"]
    Preset --> Sort["ZoneSortPolicy"]
    Preset --> Transfer["ZoneTransferPolicy"]
    Preset --> DragVisual["ZoneDragVisualFactory"]
    Runtime --> Placement["ZonePlacementTarget"]
    Runtime --> Request["ZoneTransferRequest"]
    Runtime --> Decision["ZoneTransferDecision"]
    Zone --> CardFamily["CardZone"]
    Zone --> BattleFamily["BattlefieldZone"]
```

The important split in `2.0.0` is:

- `ZoneSpaceModel` decides where a drop lands
- `ZoneLayoutPolicy` decides how managed items render
- `ZoneTransferPolicy` decides whether a move is allowed and whether it directly places the item or spawns a piece

## Why This Shape Works

- Card zones and battlefield zones share the same drag/drop and preview core without pretending they are the same data model.
- Linear index insertion and spatial cell placement both travel through a single `ZonePlacementTarget` protocol.
- A card can move into a battlefield as a card or resolve into a `ZonePiece`, depending on the target zone's transfer rules.
- Square and hex battlefields stay in one family. Geometry is a `ZoneSpaceModel`, not a new subsystem.

## Quick Start

### Card Zone

```gdscript
var hand := CardZone.new()
hand.custom_minimum_size = Vector2(360, 220)
hand.size = hand.custom_minimum_size
hand.preset = load("res://addons/nascentsoul/presets/hand_zone_preset.tres")
add_child(hand)

var card := ZoneCard.new()
card.data = CardData.new()
card.data.title = "Spark"
card.face_up = true

hand.add_item(card)
```

### Battlefield Zone

```gdscript
var field := BattlefieldZone.new()
field.custom_minimum_size = Vector2(560, 420)
field.size = field.custom_minimum_size
field.preset = load("res://addons/nascentsoul/presets/battlefield_square_zone_preset.tres")
add_child(field)

var card := ZoneCard.new()
card.data = CardData.new()
card.data.title = "Aegis"
card.face_up = true

field.add_item(card, ZonePlacementTarget.square(1, 1))
```

### Card To Battlefield

```gdscript
var target := ZonePlacementTarget.hex(2, 1)
hand.move_item_to(card, field, target)
```

If the target battlefield uses a `ZoneTransferPolicy` that returns `SPAWN_PIECE`, the source card is consumed and the battlefield inserts a `ZonePiece` instead.

## Built-In Families

- Linear space: `ZoneLinearSpaceModel`
- Square grid space: `ZoneSquareGridSpaceModel`
- Hex grid space: `ZoneHexGridSpaceModel`
- Card layouts: hand, hbox, vbox, pile
- Battlefield layout: `ZoneBattlefieldLayout`
- Transfer rules: allow-all, capacity, source, occupancy, composite, rule-table
- Example items: `ZoneCard + CardData`, `ZonePiece + PieceData`

## Learn By Opening The Repo

- [`scenes/examples/transfer_playground.tscn`](scenes/examples/transfer_playground.tscn): end-to-end card flow across deck, hand, board, and discard
- [`scenes/examples/permission_lab.tscn`](scenes/examples/permission_lab.tscn): source and capacity rules
- [`scenes/examples/layout_gallery.tscn`](scenes/examples/layout_gallery.tscn): linear layout comparison
- [`scenes/examples/zone_recipes.tscn`](scenes/examples/zone_recipes.tscn): copyable card-zone starter setups
- [`scenes/examples/battlefield_square_lab.tscn`](scenes/examples/battlefield_square_lab.tscn): square battlefield with direct card placement
- [`scenes/examples/battlefield_hex_lab.tscn`](scenes/examples/battlefield_hex_lab.tscn): hex battlefield with spatial placement
- [`scenes/examples/battlefield_transfer_modes.tscn`](scenes/examples/battlefield_transfer_modes.tscn): direct-place-card vs spawn-piece transfer rules

The editor plugin now exposes:

- `Create Card Zone`
- `Create Square Battlefield Zone`
- `Create Hex Battlefield Zone`

## Validation

Current repository validation on Godot 4.6.1:

- Headless regression suite passes with `318` checks
- Card-only demos still pass their previous smoke and regression coverage
- Battlefield coverage now includes square and hex placement, occupancy rejection, spawn-piece transfer, and same-zone piece movement

## Project Status

NascentSoul `2.0.0` is the first release that treats card zones and battlefield zones as first-class siblings on the same runtime core. The public drop protocol is now `ZonePlacementTarget`-based, and the repository examples cover both direct card placement and piece spawning on tactical boards.
