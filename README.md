The portable current Visual Studio build tree is in `NewGUI/`.

To build after copying only that directory to another Windows machine, open
`NewGUI/SpinachGUI.sln` in current Visual Studio or run MSBuild from a Developer
Command Prompt:

```
msbuild SpinachGUI.sln /m /p:Configuration=Release /p:Platform=x64 /p:RestorePackages=false
```

The associated paper is here:

https://doi.org/10.1016/j.jmr.2014.01.004

But, in the current funding climate, it is impossible to get a graphical 
user interface funded - that is not "cutting edge science". Anyone with
an inclination to continue this work is welcome to do so.
