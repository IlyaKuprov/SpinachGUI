function validate_app_export_wiring()
%VALIDATE_APP_EXPORT_WIRING Headless app-level export wiring smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

tmpDir = tempname;
mkdir(tmpDir);
cleanup = onCleanup(@() cleanupTempDir(tmpDir));

app = spinachgui.App();
appCleanup = onCleanup(@() deleteFigureIfValid(app.Figure));

assertExportButton(app, "SpinXML");
assertExportButton(app, "Spinach");
assertExportButton(app, "Bitmap");
assertExportButton(app, "EasySpin");
assertExportButton(app, "SIMPSON");
assertExportButton(app, "SpinEvolution");
assert(~contains(fileread(fullfile(thisDir, '+spinachgui', 'App.m')), 'notYet'), ...
    'App still contains a deferred-export placeholder.');

app.Model = easySpinFixture();
easySpinFile = fullfile(tmpDir, 'app_easyspin.m');
app.exportModel(easySpinFile, 'EasySpin');
assert(isfile(easySpinFile), 'App EasySpin export did not create a file.');
assertContains(fileread(easySpinFile), 'garlic(Sys,Exp,Opt);');
assertStatus(app, easySpinFile);

app.Model = nuclearFixture();
simpsonFile = fullfile(tmpDir, 'app_simpson.in');
app.exportModel(simpsonFile, 'SIMPSON');
assert(isfile(simpsonFile), 'App SIMPSON export did not create a file.');
assertContains(fileread(simpsonFile), 'spinsys {');
assertStatus(app, simpsonFile);

spinEvolutionFile = fullfile(tmpDir, 'app_spinevolution.in');
app.exportModel(spinEvolutionFile, 'SpinEvolution');
assert(isfile(spinEvolutionFile), 'App SpinEvolution export did not create a file.');
assertContains(fileread(spinEvolutionFile), '******* Pulse Sequence');
assertStatus(app, spinEvolutionFile);

spinachFile = fullfile(tmpDir, 'app_spinach.m');
app.exportModel(spinachFile, 'Spinach');
assert(isfile(spinachFile), 'App Spinach export did not create a file.');
assertContains(fileread(spinachFile), 'spin_system=create(sys,inter);');
assertStatus(app, spinachFile);

sxmlFile = fullfile(tmpDir, 'app_system.sxml');
app.exportModel(sxmlFile, 'SpinXML');
assert(isfile(sxmlFile), 'App SpinXML export did not create a file.');
assert(~app.Model.Dirty, 'SpinXML export should clear the dirty flag.');
assertStatus(app, sxmlFile);

assertThrows(@() app.exportModel(fullfile(tmpDir, 'bad.txt'), 'NotAFormat'), ...
    'spinachgui:UnsupportedExportKind');

fprintf('APP_EXPORT_WIRING_VALIDATION_OK\n');
end

function model = easySpinFixture()
model = spinachgui.Model();
model.addAtom("E", [0 0 0], "electron", false);
model.addAtom("1H", [1 0 0], "proton", false);
model.addInteraction("HFC", 2, 1, eye(3), "Gauss", "", 1, "", "validation");
model.addInteraction("GTensor", 1, 1, diag([2.001 2.002 2.003]), ...
    "Unknown", "", 1, "", "validation");
end

function model = nuclearFixture()
model = spinachgui.Model();
model.addAtom("14N", [1 0 0], "nitrogen", false);
model.addAtom("1H", [0 0 0], "proton", false);
model.addInteraction("Shift", 2, 2, diag([10 20 40]), "ppm", "", 1, "", "validation");
model.addInteraction("Jcoupling", 2, 1, diag([100 130 160]), "Hz", "", 1, "", "validation");
model.addInteraction("Quadrupolar", 1, 1, diag([1e6 2e6 4e6]), ...
    "Hz", "", 1, "", "validation");
model.addInteraction("CBond", 2, 1, eye(3), "Angstroms", "", 1, "", "validation");
end

function assertExportButton(app, label)
button = findall(app.Figure, 'Text', char(label));
assert(isscalar(button), 'App should expose exactly one %s export button.', label);
assert(isa(button.ButtonPushedFcn, 'function_handle'), '%s export callback missing.', label);
end

function assertStatus(app, filename)
assert(contains(string(app.StatusLabel.Text), string(filename)), ...
    'App status label did not report %s.', filename);
end

function assertContains(text, snippet)
assert(contains(text, snippet), 'Expected output snippet missing: %s', char(snippet));
end

function assertThrows(functionHandle, expectedID)
try
    functionHandle();
catch err
    assert(strcmp(err.identifier, expectedID), 'Expected %s, got %s.', expectedID, err.identifier);
    return
end
error('Expected error %s was not thrown.', expectedID);
end

function deleteFigureIfValid(fig)
if ~isempty(fig) && isvalid(fig)
    delete(fig);
end
end

function cleanupTempDir(tmpDir)
if isfolder(tmpDir)
    rmdir(tmpDir, 's');
end
end
