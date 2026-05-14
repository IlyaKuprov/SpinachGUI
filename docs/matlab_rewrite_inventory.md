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
