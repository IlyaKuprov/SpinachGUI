function validate_writeSimpson_exporter()
%VALIDATE_WRITESIMPSON_EXPORTER Deterministic SIMPSON exporter parity smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

model = fixtureModel();
tmpDir = tempname;
mkdir(tmpDir);
cleanup = onCleanup(@() cleanupTempDir(tmpDir));

outFile = fullfile(tmpDir, 'simpson_fixture.in');
spinachgui.writeSimpson(model, outFile, struct( ...
    'QuadrupolarOrder', 2, ...
    'DipolarThreshold', 1.5, ...
    'EnabledChannels', "1H", ...
    'SystemName', "fixture.sxml"));
text = fileread(outFile);

assertContains(text, '# Produced by Spinach GUI MATLAB port');
assertContains(text, '#System Name:fixture.sxml');
assertContains(text, 'spinsys {');
assertContains(text, sprintf('\tchannels 1H\n'));
assertContains(text, sprintf('\tnuclei 14N 1H\n'));
assertContains(text, '# Atom Index  1   2 ');
assertContains(text, '# SpinachGUI  1   2 ');
assertContains(text, sprintf('\tshift 2 23.3333p 16.6667p 0.6000 0.0000 0.0000 0.0000'));
assertContains(text, sprintf('\tshift 2 25.6667p 18.3333p 0.6000 30.0000 45.0000 60.0000'));
assertContains(text, sprintf('\tjcoupling 2 1 130.0000 30.0000 1.0000 0.0000 0.0000 0.0000'));
assertContains(text, sprintf('\tquadrupole 1 2 8.0000 0.6000 0.0000 0.0000 0.0000'));
assertContains(text, sprintf('\tdipole 2 1 %s 0.0000 90.0000 180.0000', expectedDipoleCoupling(model, 2, 1, 1.0)));
assert(~contains(text, 'hfc', 'IgnoreCase', true), 'Ignored HFC interaction leaked into SIMPSON output.');
assert(~contains(text, 'gtensor', 'IgnoreCase', true), 'Ignored GTensor interaction leaked into SIMPSON output.');
assertContains(text, 'proton_frequency 600e6');
assertContains(text, 'proc pulseq {}');
assertContains(text, 'proc main {}');

sections = [firstPosition(text, sprintf('\tshift')), ...
    firstPosition(text, sprintf('\tjcoupling')), ...
    firstPosition(text, sprintf('\tquadrupole')), ...
    firstPosition(text, sprintf('\tdipole'))];
assert(all(sections > 0) && issorted(sections), 'SIMPSON interaction sections are not in legacy order.');

sortedFile = fullfile(tmpDir, 'simpson_fixture_sorted.in');
spinachgui.writeSimpson(model, sortedFile, struct('SortAtomsByIsotope', true, 'DipolarThreshold', 1.5));
sortedText = fileread(sortedFile);
assertContains(sortedText, sprintf('\tchannels 14N 1H\n'));
assertContains(sortedText, sprintf('\tnuclei 1H 14N\n'));
assertContains(sortedText, sprintf('\tshift 1 23.3333p 16.6667p 0.6000 0.0000 0.0000 0.0000'));
assertContains(sortedText, sprintf('\tjcoupling 1 2 130.0000 30.0000 1.0000 0.0000 0.0000 0.0000'));
assertContains(sortedText, sprintf('\tquadrupole 2 1 8.0000 0.6000 0.0000 0.0000 0.0000'));
assertContains(sortedText, sprintf('\tdipole 1 2 %s 0.0000 90.0000 180.0000', expectedDipoleCoupling(model, 2, 1, 1.0)));

assertSimpsonRejectsElectrons(tmpDir);
assertSimpsonRejectsMissingAtoms(tmpDir);

fprintf('SIMPSON_WRITE_EXPORTER_VALIDATION_OK\n');
end

function model = fixtureModel()
model = spinachgui.Model();
model.addAtom("14N", [1 0 0], "nitrogen", false);
model.addAtom("1H", [0 0 0], "proton", false);

model.addInteraction("Shift", 2, 2, diag([10 20 40]), "ppm", "", 1, "", "validation");
orientID = model.addInteraction("Shift", 2, 2, diag([11 22 44]), "ppm", "", 1, "", "validation");
model.Interactions.DCM{model.Interactions.ID == orientID} = frozenDcm();
model.addInteraction("Jcoupling", 2, 1, diag([100 130 160]), "Hz", "", 1, "", "validation");
model.addInteraction("Quadrupolar", 1, 1, diag([1e6 2e6 4e6]), "Hz", "", 1, "", "validation");
model.addInteraction("CBond", 2, 1, eye(3), "Angstroms", "", 1, "", "validation");
model.addInteraction("CBond", 1, 2, 3*eye(3), "Angstroms", "", 1, "", "validation");
model.addInteraction("HFC", 1, 2, diag([1 2 3]), "Gauss", "", 1, "", "validation");
model.addInteraction("GTensor", 1, 1, diag([2.001 2.002 2.003]), "Unknown", "", 1, "", "validation");
end

function matrix = frozenDcm()
% Rz(30 deg) * Ry(45 deg) * Rz(60 deg), hard-coded to catch Euler regressions.
matrix = [ ...
    -0.126826484044322, -0.780330085889911,  0.612372435695795; ...
     0.926776695296637,  0.126826484044322,  0.353553390593274; ...
    -0.353553390593274,  0.612372435695794,  0.707106781186548];
end

function value = expectedDipoleCoupling(model, atomA, atomB, distance)
rowA = find(model.Atoms.ID == atomA, 1);
rowB = find(model.Atoms.ID == atomB, 1);
value = sprintf('%.4f', -1.054571726e-11 * model.Atoms.Magnetogyric(rowA) * ...
    model.Atoms.Magnetogyric(rowB) / (2*pi*distance^3));
end

function assertSimpsonRejectsElectrons(tmpDir)
model = spinachgui.Model();
model.addAtom("1H", [0 0 0], "", false);
model.addAtom("E", [0 0 1], "", false);
try
    spinachgui.writeSimpson(model, fullfile(tmpDir, 'electron.in'));
    error('validation:ExpectedFailureMissing', 'Expected electron rejection was not raised.');
catch err
    assert(strcmp(err.identifier, 'spinachgui:SimpsonElectronUnsupported'), ...
        'Unexpected electron rejection identifier: %s', err.identifier);
end
end

function assertSimpsonRejectsMissingAtoms(tmpDir)
model = spinachgui.Model();
model.addAtom("1H", [0 0 0], "", false);
model.addInteraction("Jcoupling", 1, 99, diag([1 2 3]), "Hz", "", 1, "", "validation");
try
    spinachgui.writeSimpson(model, fullfile(tmpDir, 'missing_atom.in'));
    error('validation:ExpectedFailureMissing', 'Expected missing-atom rejection was not raised.');
catch err
    assert(strcmp(err.identifier, 'spinachgui:InvalidInteractionAtom'), ...
        'Unexpected missing-atom rejection identifier: %s', err.identifier);
end
end

function assertContains(text, snippet)
assert(contains(text, snippet), 'Expected output snippet missing: %s', char(snippet));
end

function pos = firstPosition(text, snippet)
idx = strfind(text, char(snippet));
if isempty(idx)
    pos = 0;
else
    pos = idx(1);
end
end

function cleanupTempDir(tmpDir)
if isfolder(tmpDir)
    rmdir(tmpDir, 's');
end
end
