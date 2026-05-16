# SpinachGUI portable Visual Studio tree

This directory is intended to be copied as a standalone build tree. It contains the C++/CLI GUI project, the `gTrackBar` Visual Basic project that it depends on, the vendored Eigen headers, required resources, and a compact set of smoke-test input files.

## Requirements

- Current Visual Studio with MSBuild.
- Desktop C++ workload with C++/CLI support.
- .NET Framework 4.8 targeting pack.
- Windows 10 SDK.

## Build

From a Developer Command Prompt:

```
msbuild SpinachGUI.sln /m /p:Configuration=Release /p:Platform=x64 /p:RestorePackages=false
msbuild SpinachGUI.sln /m /p:Configuration=Release /p:Platform=Win32 /p:RestorePackages=false
```

Build outputs are written under `build/<platform>/<configuration>/`. The solution builds `Libraries/gTrackBar/gTrackBar.vbproj` first; its `AfterBuild` target copies `gTrackBar.dll` into `GUI/` for the C++/CLI `#using` directive.

## Manual smoke test

Run the built `SpinachGUI.exe` and use `examples/` to check basic import/export paths. The bundled fixtures are intentionally small and cover representative formats without carrying the old full example corpus.

