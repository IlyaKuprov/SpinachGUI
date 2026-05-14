# SpinachGUI MATLAB rewrite inventory

Baseline: `main` at `501c15faa81fb549b7db03f0b608850c3fb3f5cb`.

The historical application is C++/CLI WinForms. The entry point is `GUI/SpinachGui.cpp`, which creates `MainForm`; the core state object is `GUI/System Core/Model.*`; import/export adapters are in `GUI/IO Formats/`; the custom 3D renderer is in `GUI/3D Engine/`.

Top-level WinForms screens/forms:

- `MainForm`: main application shell, atoms table, interactions table, file/import/export controls, OpenGL view, view-plane buttons, tensor visibility controls, status/progress UI, printing, bitmap export, and format exporters.
- `About`: about dialog with project icon, text, link, and university image.
- `IsotopesDialog`: read-only isotope table.
- `OrientationDialog`: tensor/eigen/orientation editor for interactions.
- `RefFrameOrientationDialog`: reference-frame orientation editor.
- `OrientationExport`: orientation export dialog.
- `FilterFile`: import filtering for HFC/J-coupling/quadrupolar tensors and atom removal.
- `ShieldingtoShift`: channel/reference table for chemical shielding to chemical shift conversion.
- `BalloonToolTip`: custom tooltip form.

Main data model classes to port:

- `Isotope` / `Isotopes`: isotope symbol, atom number, mass, radius, RGB colour, spin, quadrupole moment, magnetogyric ratio.
- `Atom`: ID, isotope, label, coordinates.
- `Interaction`: ID, kind, label, atoms A/B, unit, eigenvalues, DCM, reference.
- `Tensor`: interaction with 3x3 matrix and reference frame.
- `ReferenceFrame`: ID, label, DCM, parent frame.
- `Model`: atoms, interactions, reference frames.

Format coverage in the historical code:

- Imports: ADF, CASTEP, COSMOS, GAMESS, Gaussian/GaussView, MOL, ORCA, SpinXML/SXML, XYZ.
- Exports: SpinXML/SXML, EasySpin, Spinach MATLAB file, SIMPSON, SpinEvolution.

First MATLAB slice creates the package scaffold and ports core state, isotope data, XYZ import, basic SpinXML import/export, Spinach export scaffold, and the first `uifigure` shell.

Second MATLAB slice tightens system-core parity: legacy interaction-kind names/order, unit conversion factors, Z-Y-Z Euler/DCM orientation convention, tensor symmetrisation, lab-frame default, positive scientific interactions versus negative auto-bond display interactions, interaction statistics, and reference-frame-to-root DCM composition.

Third MATLAB slice ports the legacy MOL V2000 importer, including its deliberate behaviour of importing atom coordinates/elements while ignoring explicit MOL bond records and rebuilding SpinachGUI display bonds automatically.

Fourth MATLAB slice ports Gaussian/GaussView and ORCA coordinate import. It dispatches `.log`/`.out` files by content markers, handles Gaussian Z-matrix isotope symbols, parses Gaussian `Input orientation`/`Standard orientation`, parses ORCA `CARTESIAN COORDINATES (A.U.)`, applies Bohr-to-Å conversion for ORCA, preserves last-frame-wins geometry, and rebuilds automatic display bonds.

Fifth MATLAB slice ports Gaussian direct tensor import: chemical shielding, electron g tensors, magnetic susceptibility pseudo-atom tensors, and quadrupolar tensors with isotope upgrade and zero-tensor skipping.

Sixth MATLAB slice ports Gaussian J-coupling import, including legacy five-column lower-triangular block parsing, Fortran `D` exponent support, diagonal skipping, and `Jcoupling`/Hz isotropic matrices.

Seventh MATLAB slice tightens the Spinach MATLAB exporter toward one-for-one legacy parity: header/function, default magnet field, isotope/electron spelling, labels, coordinates with empty electron/chi entries, supported coupling matrices, scalar J couplings, susceptibility tensor/coordinates, Zeeman GTensor/Shift output, and final `spin_system=create(sys,inter);` without non-legacy basis boilerplate.

Eighth MATLAB slice ports Gaussian hyperfine coupling import: isotropic Fermi-contact Gauss values, anisotropic spin-dipole principal-axis tensors, electron/default g-tensor creation, and `HFC`/Gauss matrices formed as anisotropic tensor plus isotropic part.

Ninth MATLAB slice ports ORCA tensor import: g tensor, zero-field splitting, chemical shifts as `Shift`/MHz, HFC section parsing with raw HFC matrices stored as `HFC`/Gauss, default electron/default g-tensor creation, quadrupolar EFG-to-MHz conversion with isotope upgrade, and expanded `.log`/`.out` content dispatch markers.

Tenth MATLAB slice adds a pure EasySpin exporter: legacy-style one-electron output with default experiment/options/broadening/dynamics blocks for `garlic`, `chili`, and `pepper`, HFC through `nucspinadd`, one `Sys.g`, one unit-converted `Sys.D`, legacy-ignored interactions skipped, and explicit errors for unsupported or ambiguous cases such as quadrupolar output, multiple g/ZFS tensors, missing electron, chi pseudo-atoms, and non-contiguous atom IDs.

Eleventh MATLAB slice adds a pure SIMPSON exporter: channel selection, optional isotope sorting/reindexing, quadrupole order, dipolar threshold, legacy-order `Shift`, `Jcoupling`, `Quadrupolar`, and CBond-derived `dipole` lines, orientation/Euler handling, and explicit errors for unsupported or invalid electrons, atom references, tensors, bond distances, and options.

Twelfth MATLAB slice adds a pure SpinEvolution exporter: `ElementMass` channel labels, enabled/disabled channel filtering, exported atom reindexing, legacy system/pulse/variables/options scaffold, legacy-supported `Shift`, `Jcoupling`, and `Quadrupolar` lines, and explicit errors for pseudo-atoms, invalid channels/kinds/IDs, and missing interaction atoms.

Thirteenth MATLAB slice ports ADF import: safe `.log`/`.out` content dispatch, Cartesian coordinates, total NMR shielding tensors as `CShielding`/ppm, and legacy scalar total J-couplings as isotropic `Jcoupling`/Hz matrices with reverse-pair duplicate suppression.

Fourteenth MATLAB slice ports CASTEP/MAGRES import: legacy CASTEP shielding and quadrupolar blocks, MAGRES atom coordinates, `ms` shielding tensors, `efg` quadrupolar tensors with isotope upgrade, and total `isc` trace-only J-couplings through `.magres` dispatch. It deliberately leaves component-resolved `isc_*` MAGRES records ignored, matching the historical C++ reader.

Fifteenth MATLAB slice ports GAMESS import: the pure MATLAB `readGAMESS` reader imports only the legacy equilibrium Cartesian coordinate table after `***** EQUILIBRIUM GEOMETRY LOCATED *****`, keeps last-frame-wins geometry semantics, rebuilds display bonds, and adds `.log`/`.out` dispatch on that distinctive marker. GAMESS tensor sections remain outside this slice.

Sixteenth MATLAB slice ports COSMOS import: pure `readCOSMOS` for legacy `.coo` ATOMS geometry, `CS-TENSOR` shielding tensors, and scalar `J-COUPLINGS`, plus `.coo` extension dispatch and safe marker-based text dispatch. Legacy-recognized `RDC-TENSOR`, `ORDER-TENSOR`, `QC-TENSOR`, `DD-TENSOR`, and `DISTANCES` records remain ignored, matching the historical C++ reader.

Seventeenth MATLAB slice ports the read-only isotope browser: `spinachgui.isotopeBrowser` builds a simple `uifigure`/`uitable` view of the existing isotope database with legacy row numbering, display labels, RGB colour swatches, a hidden/offscreen construction path for validation, and wiring from the main app Isotopes button.

Eighteenth MATLAB slice ports shielding-to-shift conversion: pure `convertShieldingToShift` plus a `Model` wrapper convert selected or all `CShielding` interactions to `Shift` using the legacy reference-shielding identity subtraction, preserve interaction units, apply the historical per-channel reference table, require explicit overrides for unknown channels or non-default references, and return a deterministic conversion summary.

Nineteenth MATLAB slice starts tensor-dialog parity with a bounded orientation editor/export helper: `spinachgui.orientationEditor` displays a 3x3 direction-cosine matrix, legacy Z-Y-Z Euler angles in degrees, and export text in a hidden-testable `uifigure`; `spinachgui.orientationExportText` emits MATLAB text blocks for optional interaction matrices, eigenvalues, DCM/eigenvectors, and Euler angles; the Visualization tab exposes a read-only orientation-export launcher for positive interactions. Full tensor editing, spherical tensor coefficients, Wigner rotation matrices, reference-frame orientation editing, lab-frame alignment, anisotropy removal, and model mutation remain outside this slice.
