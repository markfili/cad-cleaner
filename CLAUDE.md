# CAD Cleaner — working notes

Flutter **desktop** app (Windows + macOS). Detects AutoCAD, uninstalls it
(destructive, irreversible, needs admin), and installs the GstarCAD replacement.

## Toolchain

Flutter is pinned per-project via FVM in `.fvmrc` (**3.44.6**). Always prefix
commands with `fvm`:

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm flutter run -d macos
```

> **Do not run bare `fvm use` in a directory without its own `.fvmrc`.** FVM
> walks *up* the tree, and there is an `.fvmrc` in the user's home directory. A
> `fvm use` that resolves to home silently repins their entire home
> environment. This project has its own `.fvmrc`, which shadows it — keep it
> that way.

## Architecture

`CadService` (`lib/cad/cad_service.dart`) is an abstract interface over
everything that touches the host system. `CadService.forPlatform()` picks:

- `WindowsCadService` — real PowerShell/registry work. **Windows only.**
- `MockCadService` — simulated, with realistic delays. macOS/Linux + tests.

The service is constructed once in `main.dart` and injected into `HomeScreen`,
so mock state (which products remain, whether GstarCAD is installed) persists
across screens. Tests inject their own instance.

Progress messages go through the `onLog` callback, not `print`. Each screen
points `service.onLog` at its own log panel before starting an operation.

```
lib/
  main.dart          # entry point, theme wiring, service injection
  cad/               # the platform abstraction (see above)
  screens/           # home + the two wizards
  widgets/           # InfoCallout, LogPanel, SimulationBanner, WizardScaffold
  theme/             # design tokens; see below
```

`macOS can only exercise the mock.` The Windows code path cannot be run or
built here — it is only ever exercised by CI and real Windows machines. Treat
changes to `windows_cad_service.dart` as unverified until proven otherwise.

## Rules that are load-bearing, not cosmetic

- **The simulation banner must stay obvious.** It is the only thing preventing a
  simulated run from being mistaken for a real one. Persistent, non-dismissible,
  and violet — a hue reserved for simulation alone.
- **Never make the destructive path look inviting.** The uninstall confirmation
  and buttons stay solid `colorScheme.error` fills at full emphasis. Do not
  demote them to tonal/outlined, and do not use success-green anywhere near the
  list of things about to be deleted.
- **Severity comes from `SemanticRole`**, not raw colors. Irreversible ⇒
  `danger`, not `warning`.
- **Verify destructive work; don't assume it happened.** Every removal command
  passes `-ErrorAction SilentlyContinue`, so failure and success look identical.
  `cleanRegistry` reads the keys back and throws listing survivors;
  `uninstallProducts` checks each exit code. Anything new that deletes should do
  the same rather than logging and moving on.
- **The mock must model effects, not just timing.** A mock that sleeps and logs
  but doesn't mutate its state lies: uninstall once reported success while the
  products came straight back on the next scan. If an operation changes the
  system, the mock changes `_installedProducts` / the GstarCAD flags to match.

## Windows elevation

`runner.exe.manifest` sets `requestedExecutionLevel=requireAdministrator`, so
the app always elevates via UAC at launch. This is required, not a nicety: the
removal commands all pass `-ErrorAction SilentlyContinue`, so an unelevated run
would delete nothing and still report success.

`Process.start` (CreateProcess) **cannot elevate** — launching an installer that
requests admin fails with "The requested operation requires elevation". Launch
such things with `Start-Process -Verb RunAs`, and pass `-ErrorAction Stop`
inside a try/catch that does `exit 1`, since a failed `Start-Process` is a
non-terminating error and PowerShell would otherwise exit 0 on failure.

## Reading data out of PowerShell

**Never parse PowerShell's console output.** It is formatted for a display: long
values wrap (~120 columns when stdout is redirected) and text is re-encoded
through the console codepage, so long or non-ASCII product names come back
corrupted. Emit `ConvertTo-Json` to a UTF-8 file with `Set-Content` and read the
file (`_queryProducts`); parse it with `parseRegistryProductsJson`
(`lib/cad/registry_product.dart`), which also strips the BOM Windows PowerShell
writes.

Related: **don't re-look-up a product by its display name.** The name is a label,
not a key. Capture the UninstallString during detection and carry it forward —
matching on a round-tripped name is what produced "no uninstall entry found in
the registry" for a product that had just been detected.

## Registry uninstall strings

Never hand a registry `UninstallString` to `cmd /c`. Autodesk's are typically
unquoted *and* contain spaces (`C:\Program Files\Autodesk\...\Setup.exe
--uninstall`), so cmd splits at the first space and fails with
`'"C:\Program" is not recognized...'`. Parse it with `parseUninstallString`
(`lib/cad/uninstall_command.dart`) and pass the executable and arguments to
`Start-Process` separately.

That parser is deliberately plain Dart with no `dart:io` dependency, so it can
be unit-tested on a Mac — see `test/uninstall_command_test.dart`. When a new
uninstall-string shape turns up, add a case there rather than testing on
Windows by hand.

## Theme

Hand-authored light/dark `ColorScheme`s (`lib/theme/app_colors.dart`), not
seed-generated. `ThemeMode.system`. Semantic colors live in a
`ThemeExtension<SemanticColors>`, reached via `context.semantic`. Use
`AppSpacing` / `AppRadius` rather than magic numbers, and the `TextTheme` roles
rather than inline `fontSize`.

## Releasing

Tag-driven. Pushing a `v*.*.*` tag builds the Windows exe and publishes a
GitHub Release with the installer, the portable zip, and generated notes. CI
fails if the tag and the `pubspec.yaml` version disagree.

```bash
git config core.hooksPath .githooks   # once per clone
```

`git push` then asks whether to bump the version; answering `p`/`m`/`M` bumps,
commits, tags, and stops the push so you can send the new refs. See README
"Releasing".

**`CadService.exe` is not standalone.** It needs `flutter_windows.dll` and the
`data/` folder beside it, which is why releases ship an installer and a zip
rather than a bare exe. Don't "simplify" that to a lone exe.

## Verifying

`fvm flutter test` covers the mock path only. For UI changes, also build and
launch the real app — the tests use a synthetic 1280x1600 viewport and will not
catch overflows at other sizes:

```bash
fvm flutter build macos --release && open build/macos/Build/Products/Release/cad_cleaner.app
```

Before touching `.github/workflows/`, validate the YAML **and** run the script
extracted from it. A heredoc at column 0 silently terminates a YAML block scalar
and GitHub rejects the whole file.
