function validate_writeEasySpin_exporter()
%VALIDATE_WRITEEASYSPIN_EXPORTER Deterministic EasySpin exporter smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

tmpDir = tempname;
mkdir(tmpDir);
cleanup = onCleanup(@() cleanupTempDir(tmpDir));

model = spinachgui.Model();
model.addAtom("E", [0 0 0], "", false);
model.addAtom("1H", [1 0 0], "", false);
model.addInteraction("HFC", 2, 1, eye(3), "Gauss", "", 1, "", "validation");
model.addInteraction("GTensor", 1, 1, diag([2.001 2.002 2.003]), "Unknown", "", 1, "", "validation");
model.addInteraction("ZFS", 1, 1, diag([0.001 0.002 0.003]), "GHz", "", 1, "", "validation");
model.addInteraction("Shift", 2, 2, diag([10 20 30]), "ppm", "", 1, "", "ignored by EasySpin");
model.addInteraction("Jcoupling", 2, 2, diag([100 0 0]), "Hz", "", 1, "", "ignored by EasySpin");

outFile = fullfile(tmpDir, 'easyspin_exporter_fixture.m');
spinachgui.writeEasySpin(model, outFile);
text = fileread(outFile);

assertContains(text, 'clear Sys Exp Opt;');
assertContains(text, 'Sys.S=1/2;');
assertContains(text, "Sys = nucspinadd(Sys, '1H', mt2mhz([1.000000, 0.000000, 0.000000; 0.000000, 1.000000, 0.000000; 0.000000, 0.000000, 1.000000]/10));");
assertContains(text, 'Sys.g = [2.001000, 0.000000, 0.000000; 0.000000, 2.002000, 0.000000; 0.000000, 0.000000, 2.003000];');
assertContains(text, 'Sys.D = [1.000000, 0.000000, 0.000000; 0.000000, 2.000000, 0.000000; 0.000000, 0.000000, 3.000000];');
assertContains(text, 'Exp.mwFreq = 9.5;');
assertContains(text, 'Exp.mwPhase = 0.0;');
assertContains(text, 'Exp.Harmonic = 1;');
assertContains(text, 'Exp.nPoints = 1024;');
assertContains(text, "Opt.Method = 'exact' ;");
assertContains(text, 'Sys.lwpp = [0 0];');
assertContains(text, 'Sys.tcorr = 0;');
assertContains(text, 'garlic(Sys,Exp,Opt);');
assert(~contains(text, 'Exp.CenterSweep'), 'Default output must not invent a field range.');
assert(~contains(text, 'Shift'), 'Ignored Shift interaction leaked into EasySpin output.');
assert(~contains(text, 'Jcoupling'), 'Ignored Jcoupling interaction leaked into EasySpin output.');

noHfcModel = spinachgui.Model();
noHfcModel.addAtom("E", [0 0 0], "", false);
noHfcModel.addAtom("13C", [1 0 0], "", false);
noHfcFile = fullfile(tmpDir, 'easyspin_no_hfc_fixture.m');
spinachgui.writeEasySpin(noHfcModel, noHfcFile);
noHfcText = fileread(noHfcFile);
assertContains(noHfcText, "Sys.Nucs= '13C';");

fieldOpts = struct('Center', 3500, 'Sweep', 100, 'FieldUnits', 'Gauss', ...
    'ModAmpEnabled', true, 'ModAmp', 2, 'ModAmpUnits', 'Gauss', ...
    'TemperatureEnabled', true, 'Temperature', 77, ...
    'Function', 'pepper', 'HStrain', [1 2 3], 'DStrain', [4 5]);
fieldFile = fullfile(tmpDir, 'easyspin_pepper_fixture.m');
spinachgui.writeEasySpin(model, fieldFile, fieldOpts);
fieldText = fileread(fieldFile);
assertContains(fieldText, 'Exp.CenterSweep = [350 10];');
assertContains(fieldText, 'Exp.ModAmp = 0.2;');
assertContains(fieldText, 'Exp.Temperature = 77;');
assertContains(fieldText, "Exp.Mode = 'perpendicular' ;");
assertContains(fieldText, 'Exp.CrystalSymmetry = 1;');
assertContains(fieldText, "Opt.Method = 'matrix' ;");
assertContains(fieldText, 'Opt.nKnots = [0 0];');
assertContains(fieldText, 'Opt.Threshold = 0.0001;');
assertContains(fieldText, "Opt.Intensity = 'on';");
assertContains(fieldText, 'Sys.HStrain = [1 2 3];');
assertContains(fieldText, 'Sys.DStrain = [4 5];');
assert(~contains(fieldText, 'Sys.tcorr'), 'Pepper output must not emit dynamics.');
assertContains(fieldText, 'pepper(Sys,Exp,Opt);');

quadrupolarModel = spinachgui.Model();
quadrupolarModel.addAtom("E", [0 0 0], "", false);
quadrupolarModel.addAtom("14N", [1 0 0], "", false);
quadrupolarModel.addInteraction("Quadrupolar", 2, 2, eye(3), "MHz", "", 1, "", "validation");
assertError(@() spinachgui.writeEasySpin(quadrupolarModel, fullfile(tmpDir, 'bad_q.m')), 'spinachgui:EasySpinQuadrupolarUnsupported');

nonContiguousModel = spinachgui.Model();
nonContiguousModel.addAtom("E", [0 0 0], "", false);
nonContiguousModel.addAtom("1H", [1 0 0], "", false);
nonContiguousModel.Atoms.ID(2) = 3;
assertError(@() spinachgui.writeEasySpin(nonContiguousModel, fullfile(tmpDir, 'bad_ids.m')), 'spinachgui:NonContiguousAtomIDs');

fprintf('EASYSPIN_WRITE_EXPORTER_VALIDATION_OK\n');
end

function assertContains(text, snippet)
assert(contains(text, snippet), 'Expected output snippet missing: %s', char(snippet));
end

function assertError(fun, expectedID)
try
    fun();
catch err
    assert(strcmp(err.identifier, expectedID), 'Expected error %s, got %s: %s', expectedID, err.identifier, err.message);
    return
end
error('Expected error %s was not thrown.', expectedID);
end

function cleanupTempDir(tmpDir)
if isfolder(tmpDir)
    rmdir(tmpDir, 's');
end
end
