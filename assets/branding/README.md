# SolLib4Pascal branding

This folder holds the **project logo** and derivative assets for README, social previews, and optional IDE package icons.

## Meaning

The mark is a **rounded badge** showing **wallet and chain**: a **key bow** and **key body** on the left, **linked circular nodes** on the right. It suggests:

- **Solana SDK for Pascal** — wallets, keys, accounts, and RPC-driven integration.
- **Clarity** — readable at small sizes (favicon / package icon).

It is **not** the official Solana logo. **Solana** is a trademark of its owners. Do not combine this mark with third-party trademarks in a way that implies endorsement.

## Files

| File | Use |
|------|-----|
| [`logo.svg`](logo.svg) | **Source of truth** (light UI / default README on GitHub light theme). |
| [`logo-dark.svg`](logo-dark.svg) | Dark backgrounds (docs sites, dark-themed pages). |
| [`BRAND.md`](BRAND.md) | Colors, clear space, minimum size, do / don’t. |
| [`export/`](export/) (`*.png`) | Raster exports (GitHub social 2:1, Open Graph, social header, square avatar). |
| [`icons/SolLib4Pascal.ico`](icons/SolLib4Pascal.ico) | Multi-resolution Windows icon for `.dproj` / `.lpi`. |

## License

The **library source code** is under the project [MIT License](../../LICENSE). The **logo files in this directory** are also released under the **MIT License** unless the repository maintainers specify otherwise in a future commit; you may use them to refer to SolLib4Pascal. Do not use them to misrepresent authorship or to imply certification by the authors.

## Regenerating PNG and ICO

If you change the SVG, regenerate rasters using one of:

- **Inkscape** (CLI): export PNG at the sizes [listed here](export/README.md).
- **ImageMagick** 7+: `magick logo.svg -resize 512x512 export/logo-512.png`.
