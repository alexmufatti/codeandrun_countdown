# CLAUDE.md — codeandrun_countdown

App nativa macOS che vive nella menu bar e mostra il tempo restante (o trascorso) a una o più date/eventi configurabili dall'utente.

## Stack

- Swift 6 / SwiftUI, `MenuBarExtra` (macOS 13+)
- Swift Package Manager — nessun progetto Xcode `.xcodeproj` in repo, solo `Package.swift`
- **Richiede Xcode.app installato** (non bastano i Command Line Tools): gli SDK recenti usano macro Swift (`@State`, ecc.) il cui plugin di compilazione è distribuito solo con Xcode.app
- Persistenza: JSON in `~/Library/Application Support/CodeAndRunCountdown/countdowns.json` (nessun database, nessuna rete)

## Struttura

```
Sources/CountdownMenuBar/
  App.swift                       — entry point, MenuBarExtra + label con refresh periodico
  Models/Countdown.swift          — modello countdown + logica di formattazione
  Models/CountdownFormat.swift    — enum formato display (adattivo / solo giorni / giorni+ore:minuti)
  Store/CountdownStore.swift      — ObservableObject, CRUD + persistenza JSON
  Views/MenuContentView.swift     — contenuto del menu a tendina (lista, aggiungi/modifica/elimina)
  Views/AddEditCountdownView.swift — form di creazione/modifica
Resources/
  AppIcon.iconset/                — PNG per ogni risoluzione richiesta da iconutil, generati da Scripts/generate-icon.swift
  AppIcon.icns                    — `iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns`, referenziata da Scripts/build-app.sh
Scripts/
  generate-icon.swift             — disegna l'icona (clessidra, palette Code and Run) via Core Graphics ed esporta i PNG in Resources/AppIcon.iconset/
  build-app.sh                    — swift build -c release + assembla CountdownMenuBar.app (Info.plist + icona) in .build/
```

## Comportamento

- La menu bar mostra il countdown "attivo": il prossimo evento futuro più vicino; se tutti gli eventi sono passati, mostra il più recente tra i passati.
- Formato **adattivo** (default): giorni interi finché manca più di un giorno, poi passa a ore/minuti, poi minuti/secondi quando l'evento è imminente. Ogni countdown può forzare un formato fisso (`daysOnly`, `daysHoursMinutes`) tramite il picker nel form.
- L'etichetta nella menu bar si aggiorna ogni 15s via `Timer.publish`, indipendentemente dal resto della UI.

## Comandi

```bash
swift build      # compila (richiede Xcode.app, vedi sopra)
swift run         # esegue l'app da terminale (icona apparirà nella menu bar)
```

```bash
Scripts/build-app.sh   # swift build -c release + genera .build/CountdownMenuBar.app con icona e Info.plist
```

Per rigenerare l'icona dopo una modifica al design:
```bash
swift Scripts/generate-icon.swift Resources/AppIcon.iconset
iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
```

## Non ancora fatto

- Code signing / notarizzazione, "avvia al login"
- Nessun test automatico
