# Doublenegative — Swift App Setup

Universal SwiftUI app for macOS 14+ and iPadOS 17+. No dependencies beyond Apple frameworks (SwiftUI, SwiftData, CoreImage, ImageIO).

## Prerequisites

- Xcode 15 or later
- macOS 14 Sonoma or later (for development)
- An Apple Developer account (free tier works for running on a personal device)

## Create the Xcode Project

The source files live in `swift-app/Sources/Doublenegative/`. You need to wrap them in an Xcode project.

### Step 1 — New Project

1. Open Xcode → **File › New › Project**
2. Choose **Multiplatform › App** → Next
3. Fill in:
   - **Product Name:** `Doublenegative`
   - **Team:** your personal team
   - **Bundle Identifier:** e.g. `com.yourname.doublenegative`
   - **Interface:** SwiftUI
   - **Storage:** SwiftData
4. **Save inside** `swift-app/` (creates `swift-app/Doublenegative.xcodeproj`)

### Step 2 — Replace Generated Sources

Xcode generates a starter `ContentView.swift` and `DoublenegativeApp.swift`. Replace them:

1. In the Xcode project navigator, **delete** the generated source files (move to Trash).
2. Drag the entire `Sources/Doublenegative/` folder into the project navigator.
3. In the dialog, check **"Copy items if needed"** → **Finish**.

Your project navigator should show:

```
Doublenegative/
├── DoublenegativeApp.swift
├── Models/
│   ├── EditParams.swift
│   ├── ImageItem.swift
│   ├── PhotoCollection.swift
│   └── Recipe.swift
├── Services/
│   └── ImageProcessor.swift
├── ViewModels/
│   ├── EditorViewModel.swift
│   └── LibraryViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── Editor/
│   │   ├── EditorView.swift
│   │   ├── FilmStrip.swift
│   │   └── ImageCanvas.swift
│   ├── Library/
│   │   ├── CollectionSidebar.swift
│   │   └── LibraryView.swift
│   └── Panels/
│       ├── ColorSection.swift
│       ├── DetailSection.swift
│       ├── EditPanel.swift
│       ├── HistogramView.swift
│       ├── LabeledSlider.swift
│       ├── LightSection.swift
│       └── RecipePanel.swift
└── Extensions/
    └── URL+SecurityScope.swift
```

### Step 3 — Configure Targets

Select the project in the navigator → select the **Doublenegative** target:

**General tab:**
- Deployment Target: macOS 14.0 / iOS 17.0
- Supported Destinations: Mac and iPhone/iPad

**Signing & Capabilities tab:**
- Add **App Sandbox** (macOS) — required for security-scoped bookmarks
- Under App Sandbox, enable **User Selected File → Read/Write**
- Add **iCloud** (optional, for SwiftData sync across devices)

### Step 4 — Build & Run

Select **My Mac** (or a connected iPad) as the run destination and press **⌘R**.

On first launch:
1. Click **Import** (or drag RAW/JPEG files onto the library grid)
2. Double-click a photo to open the Develop editor
3. Use sliders to adjust; **⌘S** saves edits to the library
4. Use **Recipes** to save your settings and apply them to other images

## RAW Format Support

The app uses Apple's **ImageIO** framework, which supports all RAW formats natively via the built-in camera RAW decoder:

| Manufacturer | Extensions |
|---|---|
| Canon | CR2, CR3 |
| Nikon | NEF |
| Sony | ARW |
| Adobe | DNG |
| Fujifilm | RAF |
| Olympus | ORF |
| Panasonic | RW2 |
| Pentax | PEF |
| Samsung | SRW |

No third-party libraries are required.

## Project Notes

- **Non-destructive**: Original files are never modified. Edits are stored as JSON in SwiftData alongside a security-scoped bookmark.
- **GPU rendering**: CoreImage renders all adjustments on the GPU via a single shared `CIContext`.
- **Recipes**: Save your edit parameters and batch-apply them to other images from the Recipes panel in the editor.
