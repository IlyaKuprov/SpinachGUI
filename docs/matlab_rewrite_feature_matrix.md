# SpinachGUI MATLAB R2026a rewrite feature matrix

This file is the parity ledger for the one-for-one MATLAB rewrite. It is intentionally conservative: a feature is marked complete only after MATLAB code and a validation gate exist.

| Area | Original source | MATLAB status | Validation |
| --- | --- | --- | --- |
| Application entry point | `GUI/SpinachGui.cpp`, `MainForm` | First slice: `matlab/SpinachGUI.m` calls `spinachgui.App` | `SPINACHGUI_UI_OK` |
| Core model | `GUI/System Core/Model.*` | Slice 2: `spinachgui.Model` preserves lab-frame default, canonical interaction kinds, positive vs negative auto-bond IDs, tensor symmetrisation, positive-interaction filtering, interaction statistics, and reference-frame-to-root DCM composition | `SPINACHGUI_SLICE2_OK` |
| Isotope database | `GUI/System Core/isotopes.*` | First slice: generated `spinachgui.isotopeTable` and `findIsotope` | 121-row isotope table checked |
| XYZ import | `GUI/IO Formats/XYZ.*` | First slice: `spinachgui.readXYZ` | methane XYZ imported with 5 atoms |
| SpinXML import | `GUI/IO Formats/SpinXML.*`, generated schema headers | Slice 2: atom/reference-frame/interaction parser for historical SXML shape, preserving explicit reference-frame IDs and canonicalising legacy interaction-kind spellings | alanine SXML imported with 13 atoms / 91 positive interactions |
| SpinXML export | `GUI/IO Formats/SpinXML.*` | Slice 2: `spinachgui.writeSpinXML`, omitting negative auto-bond display interactions from saved SpinXML and emitting legacy lowercase kind names | SXML round-trip preserved 13 atoms / 91 positive interactions |
| Spinach export | `GUI/IO Formats/Spinach.*` | Slice 2: `spinachgui.writeSpinach` scaffold for isotopes, coordinates, positive tensor interactions | MATLAB file generation exercised |
| Main window layout | `GUI/MainForm.*` | Slice 2: `uifigure` shell with Home/Visualization tabs, tables, 3D axes, file/export/view/tensor controls; interaction tables display positive scientific interactions rather than negative auto-bonds | `SPINACHGUI_SLICE2_UI_OK` |
| 3D molecule view | `GUI/3D Engine/OpenGL.*` | First slice: MATLAB `uiaxes`, atoms, bonds | headless render path checked through app construction |
| Orientation math | `GUI/System Core/orientation.*` | Slice 2: pure MATLAB Z-Y-Z Euler/DCM conversion helpers matching legacy `Rz(alpha)*Ry(beta)*Rz(gamma)` convention | DCM round-trip in `SPINACHGUI_SLICE2_OK` |
| Unit catalogue/conversion | `GUI/System Core/unit.h` | Slice 2: `spinachgui.units`, `unitFactor`, `convertUnit` reproduce legacy factors | mTesla→Gauss and 22-unit table in `SPINACHGUI_SLICE2_OK` |
| Tensor dialogs | `OrientationDialog`, `RefFrameOrientationDialog`, `OrientationExport` | Orientation math helpers exist; dialog UI not yet ported | pending |
| Isotope browser | `IsotopesDialog` | First slice: isotope `uitable` window | pending |
| MOL import | `GUI/IO Formats/MOL.*` | Slice 3: V2000 atom block parser with legacy behaviour of ignoring explicit bond records and rebuilding display bonds | `SPINACHGUI_SLICE3_MOL_OK` |
| Gaussian/GaussView coordinate import | `GUI/IO Formats/Gauss.*`, `IOSpinSystem.*` | Slice 4: `.log`/`.out` content dispatch, isotope-symbol scan, `Input orientation`/`Standard orientation` parser, last-frame-wins coordinates, automatic display-bond rebuild | `SPINACHGUI_SLICE4_COORD_IMPORT_OK` |
| ORCA coordinate import | `GUI/IO Formats/Orca.*`, `IOSpinSystem.*` | Slice 4: `.log`/`.out` content dispatch, `CARTESIAN COORDINATES (A.U.)` parser, Bohr-to-Å conversion, last-frame-wins coordinates, automatic display-bond rebuild | `SPINACHGUI_SLICE4_COORD_IMPORT_OK` |
| Gaussian direct tensor import | `GUI/IO Formats/Gauss.*`, `IOSpinSystem.*` | Slice 5: chemical shielding (`CShielding`/ppm), g tensor (`GTensor`/Bohr magneton with electron pseudoatom), magnetic susceptibility (`CHITensor`/Bohr magneton with `chi` pseudoatom), and quadrupolar tensors (`Quadrupolar`/MHz with isotope upgrade and zero-tensor skip) | `GAUSSIAN_DIRECT_TENSORS_VALIDATION_OK` |
| Import formats ADF/Castep/COSMOS/GAMESS/Gaussian J/HFC/ORCA tensors | `GUI/IO Formats/*` | Not yet ported | pending |
| Export formats EasySpin/SIMPSON/SpinEvolution | `GUI/IO Formats/*` | Not yet ported | pending |
| Filtering dialog | `FilterFile.*` | Not yet ported | pending |
| Shielding-to-shift conversion | `ShieldingtoShift.*` | Not yet ported | pending |
| Bitmap/print export | `MainForm.*` | Print callback only; bitmap export not yet ported | pending |
