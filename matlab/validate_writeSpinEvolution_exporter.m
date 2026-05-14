function validate_writeSpinEvolution_exporter()
%VALIDATE_WRITESPINEVOLUTION_EXPORTER Deterministic SpinEvolution exporter smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

tmpDir = tempname;
mkdir(tmpDir);
cleanup = onCleanup(@() cleanupTempDir(tmpDir));

model = fixtureModel();

allChannelsFile = fullfile(tmpDir, 'spinevolution_all.in');
spinachgui.writeSpinEvolution(model, allChannelsFile, struct('SystemName', "fixture.sxml"));
allText = fileread(allChannelsFile);
assertContains(allText, '* Produced by Spinach GUI MATLAB port');
assertContains(allText, '*System Name:fixture.sxml');
assertLineMatches(allText, 'channels', 'N14 H1');
assertLineMatches(allText, 'nuclei', 'N14 H1');
assertLineMatches(allText, 'atomic_coords', '1 0 0 0 0 0');
assertLineMatches(allText, 'cs_isotropic', '23.3333 25.6667 ppm');
assertContains(allText, 'csa_parameters     2 16.6667 0.6000 0.0000 0.0000 0.0000 ppm');
assertContains(allText, 'csa_parameters     2 18.3333 0.6000 30.0000 45.0000 60.0000 ppm');
assertContains(allText, 'j_coupling         2 1 130.0000 30.0000 1.0000 0.0000 0.0000 0.0000');
assertContains(allText, 'quadrupole         1 1666666.6667 0.6000 0.0000 0.0000 0.0000');
assertContains(allText, 'dip_switchboard    *');
assertContains(allText, '******* Pulse Sequence ******************************');
assert(countMatches(allText, '(?m)^CHN \d+$') == 2, 'Expected two pulse-sequence channel blocks.');
assert(~contains(allText, 'hfc', 'IgnoreCase', true), 'Ignored HFC interaction leaked into SpinEvolution output.');
assert(~contains(allText, 'gtensor', 'IgnoreCase', true), 'Ignored GTensor interaction leaked into SpinEvolution output.');
assert(~contains(allText, 'CBond', 'IgnoreCase', true), 'Ignored CBond interaction leaked into SpinEvolution output.');

hydrogenOnlyFile = fullfile(tmpDir, 'spinevolution_h_only.in');
spinachgui.writeSpinEvolution(model, hydrogenOnlyFile, struct('EnabledChannels', "H1", 'SystemName', "fixture.sxml"));
hydrogenText = fileread(hydrogenOnlyFile);
assertLineMatches(hydrogenText, 'channels', 'H1');
assertLineMatches(hydrogenText, 'nuclei', 'H1');
assertLineMatches(hydrogenText, 'atomic_coords', '1 0 0 0 0 0');
assertLineMatches(hydrogenText, 'cs_isotropic', '23.3333 25.6667 ppm');
assertContains(hydrogenText, 'csa_parameters     1 16.6667 0.6000 0.0000 0.0000 0.0000 ppm');
assertContains(hydrogenText, 'csa_parameters     1 18.3333 0.6000 30.0000 45.0000 60.0000 ppm');
assertLineMatches(hydrogenText, 'j_coupling', '*');
assertLineMatches(hydrogenText, 'quadrupole', '*');
assert(countMatches(hydrogenText, '(?m)^CHN \d+$') == 1, 'Expected one pulse-sequence channel block.');

assertSpinEvolutionRejectsElectrons(tmpDir);
assertSpinEvolutionRejectsMissingAtoms(tmpDir);
assertSpinEvolutionRejectsUnknownChannels(tmpDir);
assertSpinEvolutionReindexesNonContiguousAtoms(tmpDir);

fprintf('SPINEVOLUTION_WRITE_EXPORTER_VALIDATION_OK\n');
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

function assertSpinEvolutionRejectsElectrons(tmpDir)
model = spinachgui.Model();
model.addAtom("1H", [0 0 0], "", false);
model.addAtom("E", [0 0 1], "", false);
try
    spinachgui.writeSpinEvolution(model, fullfile(tmpDir, 'electron.in'));
    error('validation:ExpectedFailureMissing', 'Expected electron rejection was not raised.');
catch err
    assert(strcmp(err.identifier, 'spinachgui:SpinEvolutionElectronUnsupported'), ...
        'Unexpected electron rejection identifier: %s', err.identifier);
end
end

function assertSpinEvolutionRejectsMissingAtoms(tmpDir)
model = spinachgui.Model();
model.addAtom("1H", [0 0 0], "", false);
model.addInteraction("Jcoupling", 1, 99, diag([1 2 3]), "Hz", "", 1, "", "validation");
try
    spinachgui.writeSpinEvolution(model, fullfile(tmpDir, 'missing_atom.in'));
    error('validation:ExpectedFailureMissing', 'Expected missing-atom rejection was not raised.');
catch err
    assert(strcmp(err.identifier, 'spinachgui:InvalidInteractionAtom'), ...
        'Unexpected missing-atom rejection identifier: %s', err.identifier);
end
end

function assertSpinEvolutionRejectsUnknownChannels(tmpDir)
model = spinachgui.Model();
model.addAtom("1H", [0 0 0], "", false);
try
    spinachgui.writeSpinEvolution(model, fullfile(tmpDir, 'unknown_channel.in'), struct('EnabledChannels', "C13"));
    error('validation:ExpectedFailureMissing', 'Expected unknown-channel rejection was not raised.');
catch err
    assert(strcmp(err.identifier, 'spinachgui:UnknownChannel'), ...
        'Unexpected unknown-channel rejection identifier: %s', err.identifier);
end
end

function assertSpinEvolutionReindexesNonContiguousAtoms(tmpDir)
model = spinachgui.Model();
model.addAtom("14N", [1 0 0], "", false);
model.addAtom("1H", [0 0 0], "", false);
model.Atoms.ID(2) = 7;
model.addInteraction("Shift", 7, 7, diag([10 20 40]), "ppm", "", 1, "", "validation");
outFile = fullfile(tmpDir, 'noncontiguous.in');
spinachgui.writeSpinEvolution(model, outFile, struct('EnabledChannels', "H1"));
text = fileread(outFile);
assertContains(text, 'csa_parameters     1 16.6667 0.6000 0.0000 0.0000 0.0000 ppm');
end

function assertContains(text, snippet)
assert(contains(text, snippet), 'Expected output snippet missing: %s', char(snippet));
end

function assertLineMatches(text, key, expectedPayload)
pattern = sprintf('(?m)^%s\\s+%s\\s*$', regexptranslate('escape', key), regexptranslate('escape', expectedPayload));
assert(~isempty(regexp(text, pattern, 'once')), 'Expected line missing: %s ... %s', key, expectedPayload);
end

function count = countMatches(text, pattern)
count = numel(regexp(text, pattern, 'match'));
end

function cleanupTempDir(tmpDir)
if isfolder(tmpDir)
    rmdir(tmpDir, 's');
end
end
