# SolLib4Pascal — lightweight brand guide

## Primary mark

- **Default:** [`logo.svg`](logo.svg) — **wallet and chain**: **gold key bow**, **teal-stroked** key body with **cyan** slot, **three linked nodes** (accounts / chain) in **violet** rings. Reads as **Solana SDK**: keys, wallets, and on-chain connection.
- **Dark UI:** [`logo-dark.svg`](logo-dark.svg) — same layout with **amber** bow, **ice** slot, **lilac** node rings on **near-black** violet badge.

**Solana** and related marks are trademarks of their owners. This artwork is original for the project and does not imply endorsement by the Solana Foundation or others.

## Palette (default logo)

| Role | Hex | Notes |
|------|-----|--------|
| Badge top | `#5b21b6` | Violet gradient start. |
| Badge bottom | `#1e1b4b` | Deep indigo end. |
| Key bow | `#fbbf24` | Warm accent (custody / value). |
| Key body fill | `#312e81` | Panel behind slot. |
| Key body stroke | `#5eead4` | Mint frame. |
| Key slot | `#22d3ee` | Cyan “hole”. |
| Chain nodes | `#312e81` fill, `#a78bfa` stroke | Linked accounts. |
| Connectors | `#5eead4` | Short mint links between nodes. |

Dark variant uses `#1e1b4b`–`#0a0618`, bow `#fde68a`, slot `#67e8f9`, node fill `#1e293b`, node stroke `#d8b4fe`, connectors `#99f6e4`.

**Banner background** (flat fill behind the logo for wide social and Open Graph PNGs [here](export/)): RGB **61, 31, 129** (`#3d1f81`), midpoint between badge top and bottom.

## Typography (pairing)

The logo has **no embedded wordmark**. When setting type next to the mark:

- Prefer **clean sans-serif** system or UI fonts (e.g. Segoe UI, Inter, Source Sans 3).
- **Do not** use Embarcadero’s proprietary Delphi logotype in a way that suggests a product bundle with this library.

## Clear space

Keep padding around the badge at least **1/4 of the mark’s width** (e.g. ~32 px clear space on a 128 px square canvas).

## Minimum size

- **Favicon / IDE:** readable at **16×16** when exported to ICO; prefer **32×32** or larger for clarity.
- **README / docs:** **128–200 px** wide for the SVG or equivalent raster is typical.

## Correct use

- Scale **uniformly** (preserve aspect ratio).
- Place on backgrounds with enough contrast (use [`logo-dark.svg`](logo-dark.svg) on dark pages).
- Prefer **SVG** for web; use **PNG** where required (some social crawlers).

## Incorrect use

- Do not **stretch** or **skew** the badge.
- Do not **change hue** arbitrarily (keep palette cohesive with the table above or update this doc when rebranding).
- Do not **crop** away the rounded corners entirely.
- Do not imply **Solana trademark** ownership; attribute the standard where appropriate in docs.
- Do not place **third-party logos inside** the badge.

## Wordmark

“SolLib4Pascal” in plain text beside or below the mark is sufficient; no official custom logotype is required.
