# SpinachGUI MATLAB R2026a rewrite feature matrix

This file is the parity ledger for the one-for-one MATLAB rewrite. It is intentionally conservative: a feature is marked complete only after MATLAB code and a validation gate exist.

| Area | Original source | MATLAB status | Validation |
| --- | --- | --- | --- |
| Application entry point | `GUI/SpinachGui.cpp`, `MainForm` | First slice: `matlab/SpinachGUI.m` calls `spinachgui.App` | `SPINACHGUI_UI_OK` |
| Core model | `GUI/System Core/Model.*` | First slice: `spinachgui.Model` with atoms, interactions, reference frames | `SPINACHGUI_CORE_AND_CHECKCODE_OK` |
| Isotope database | `GUI/System Core/isotopes.*` | First slice: generated `spinachgui.isotopeTable` and `findIsotope` | 121-row isotope table checked |
| XYZ import | `GUI/IO Formats/XYZ.*` | First slice: `spinachgui.readXYZ` | methane XYZ imported with 5 atoms |
| SpinXML import | `GUI/IO Formats/SpinXML.*`, generated schema headers | First slice: atom/reference-frame/interaction parser for historical SXML shape | alanine SXML imported with 13 atoms / 91 interactions |
| SpinXML export | `GUI/IO Formats/SpinXML.*` | First slice: `spinachgui.writeSpinXML` | SXML round-trip preserved atom/interaction counts |
| Spinach export | `GUI/IO Formats/Spinach.*` | First slice: `spinachgui.writeSpinach` scaffold for isotopes, coordinates, tensors | MATLAB file generation exercised |
| Main window layout | `GUI/MainForm.*` | First slice: `uifigure` shell with Home/Visualization tabs, tables, 3D axes, file/export/view/tensor controls | headless `uifigure` construction checked |
| 3D molecule view | `GUI/3D Engine/OpenGL.*` | First slice: MATLAB `uiaxes`, atoms, bonds | headless render path checked through app construction |
| Tensor dialogs | `OrientationDialog`, `RefFrameOrientationDialog`, `OrientationExport` | Not yet ported | pending |
| Isotope browser | `IsotopesDialog` | First slice: isotope `uitable` window | pending |
| Import formats ADF/Castep/COSMOS/GAMESS/Gauss/MOL/ORCA | `GUI/IO Formats/*` | Not yet ported | pending |
| Export formats EasySpin/SIMPSON/SpinEvolution | `GUI/IO Formats/*` | Not yet ported | pending |
| Filtering dialog | `FilterFile.*` | Not yet ported | pending |
| Shielding-to-shift conversion | `ShieldingtoShift.*` | Not yet ported | pending |
| Bitmap/print export | `MainForm.*` | Print callback only; bitmap export not yet ported | pending |
