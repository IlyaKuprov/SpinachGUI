function validate_audit_hardening()
%VALIDATE_AUDIT_HARDENING Edge-case probes added by the post-PR audit.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

tmpDir = tempname;
mkdir(tmpDir);
cleanup = onCleanup(@() cleanupTempDir(tmpDir));

validateSpinXMLIDsAndEntities(tmpDir);
validateSpinXMLTensorForms(tmpDir);
validateModelInputGuards();
validateExporterAndImporterGuards(tmpDir);
validateAppLooseTails();

fprintf('AUDIT_HARDENING_VALIDATION_OK\n');
end

function validateSpinXMLIDsAndEntities(tmpDir)
filename = fullfile(tmpDir, 'noncontiguous_entities.sxml');
fid = fopen(filename, 'w');
assert(fid > 0, 'Could not create SpinXML fixture.');
closer = onCleanup(@() fclose(fid));
fprintf(fid, ['<?xml version="1.0"?>\n<spin_system>\n' ...
    '<reference_frame id="3" label=''frame&amp;one''>\n' ...
    '<dcm xx="1" xy="0" xz="0" yx="0" yy="1" yz="0" zx="0" zy="0" zz="1" />\n' ...
    '</reference_frame>\n' ...
    '<spin id="0" isotope="1H" label="H&amp;one"><coordinates x="0" y="0" z="0" /></spin>\n' ...
    '<spin id="20" isotope="16O" label=''O&apos;two''><coordinates x="1" y="0" z="0" /></spin>\n' ...
    '<interaction kind="Jcoupling" id="0" units="Hz" spin_a="0" spin_b="20" reference_frame_id="3" reference="a&amp;b">\n' ...
    '<tensor xx="1" xy="0" xz="0" yx="0" yy="2" yz="0" zx="0" zy="0" zz="3" /></interaction>\n' ...
    '</spin_system>\n']);
clear closer

model = spinachgui.readSpinXML(filename);
assert(isequal(model.Atoms.ID(:).', [1 2]), 'SpinXML atom IDs should be normalised to MATLAB-positive IDs.');
assert(isequal(model.Interactions.ID(:).', 1), 'SpinXML interaction IDs should be normalised to MATLAB-positive IDs.');
assert(model.Interactions.A(1) == 1 && model.Interactions.B(1) == 2, ...
    'SpinXML interaction atom references were not remapped from external IDs.');
assert(model.Atoms.Label(1) == "H&one", 'Double-quoted XML entity was not unescaped.');
assert(model.Atoms.Label(2) == "O'two", 'Single-quoted XML entity was not unescaped.');
assert(model.Atoms.Element(2) == "O" && model.Atoms.Mass(2) == 16 && model.Atoms.Spin(2) == 0, ...
    'Unknown spin-zero isotope masses should fall back to element display metadata.');
assert(model.ReferenceFrames.Label(model.ReferenceFrames.ID == 3) == "frame&one", ...
    'Reference-frame XML entity was not unescaped.');
assert(model.Interactions.Reference(1) == "a&b", 'Interaction reference XML entity was not unescaped.');

schemaStyle = fullfile(tmpDir, 'schema_style_spinxml.sxml');
writeTextFile(schemaStyle, ['<spin_system>\n' ...
    '<reference_frame id="2" name="child" parent_reference_frame_id="3"><dcm xx="1" xy="0" xz="0" yx="0" yy="1" yz="0" zx="0" zy="0" zz="1" /></reference_frame>\n' ...
    '<reference_frame id="3" name="parent"><dcm xx="1" xy="0" xz="0" yx="0" yy="1" yz="0" zx="0" zy="0" zz="1" /></reference_frame>\n' ...
    '<spin id="1" isotope="1H"><coordinates><element>1</element><element>2</element><element>3</element></coordinates></spin>\n' ...
    '<interaction type="shift" units="ppm" spin_1="1" reference_frame_id="2"><tensor xx="1" xy="0" xz="0" yx="0" yy="2" yz="0" zx="0" zy="0" zz="3" /></interaction>\n' ...
    '</spin_system>\n']);
schemaModel = spinachgui.readSpinXML(schemaStyle);
assert(isequal([schemaModel.Atoms.X(1) schemaModel.Atoms.Y(1) schemaModel.Atoms.Z(1)], [1 2 3]), ...
    'Nested SpinXML coordinate elements were not parsed.');
assert(schemaModel.Interactions.Kind(1) == "Shift", 'SpinXML interaction type= alias was not parsed.');
assert(schemaModel.ReferenceFrames.ParentID(schemaModel.ReferenceFrames.ID == 2) == 3, ...
    'Forward-declared SpinXML reference-frame parent was not resolved.');
assert(schemaModel.ReferenceFrames.Label(schemaModel.ReferenceFrames.ID == 2) == "child", ...
    'SpinXML reference-frame name= alias was not parsed.');
end

function validateSpinXMLTensorForms(tmpDir)
filename = fullfile(tmpDir, 'forms.sxml');
fid = fopen(filename, 'w');
assert(fid > 0, 'Could not create SpinXML form fixture.');
closer = onCleanup(@() fclose(fid));
fprintf(fid, ['<spin_system>\n' ...
    '<spin id="1" isotope="1H"><coordinates x="0" y="0" z="0" /></spin>\n' ...
    '<spin id="2" isotope="13C"><coordinates x="1" y="0" z="0" /></spin>\n' ...
    '<reference_frame id="1"><direction><dcm xx="1" xy="0" xz="0" yx="0" yy="1" yz="0" zx="0" zy="0" zz="1" /></direction></reference_frame>\n' ...
    '<reference_frame id="2" parent_reference_frame_id="1"><direction><dcm xx="0" xy="-1" xz="0" yx="1" yy="0" yz="0" zx="0" zy="0" zz="1" /></direction></reference_frame>\n' ...
    '<interaction kind="shift" id="1" units="ppm" spin_a="1" reference_frame_id="2"><eigenvalues xx="1" yy="2" zz="3" /><orientation><euler_angles alpha="90" beta="0" gamma="0" /></orientation></interaction>\n' ...
    '<interaction kind="shift" id="2" units="ppm" spin_a="2"><span_skew iso="10" span="6" skew="0.25" /></interaction>\n' ...
    '<interaction kind="jcoupling" id="3" units="Hz" spin_a="1" spin_b="2"><scalar>29.13</scalar></interaction>\n' ...
    '</spin_system>\n']);
clear closer

model = spinachgui.readSpinXML(filename);
assert(model.ReferenceFrames.ParentID(model.ReferenceFrames.ID == 2) == 1, ...
    'SpinXML parent_reference_frame_id was not parsed.');
assert(height(model.Interactions) == 3, 'SpinXML form fixture should import three interactions.');
rot = spinachgui.eulerToDcm(pi/2, 0, 0);
expectedEigenMatrix = spinachgui.symmetrizeTensor(rot * diag([1 2 3]) * rot.');
assertClose(model.Interactions.Matrix{1}, expectedEigenMatrix, 1e-12, 'SpinXML eigenvalue/orientation tensor');
assertClose(model.Interactions.Matrix{2}, diag([12.75 10.5 6.75]), 1e-12, 'SpinXML span/skew tensor');
assertClose(model.Interactions.Matrix{3}, 29.13 * eye(3), 1e-12, 'SpinXML scalar tensor');
end

function validateModelInputGuards()
model = spinachgui.Model();
assertThrows(@() model.addAtom("1H", [NaN 0 0], "bad", false), 'MATLAB:expectedFinite');
assertThrows(@() model.addAtom("1H", [0 0 0], "bad", false, 0), 'spinachgui:InvalidID');
firstID = model.addAtom("1H", [0 0 0], "first", false, 10);
assert(firstID == 10, 'Requested atom ID was not returned.');
assertThrows(@() model.addAtom("13C", [1 0 0], "duplicate", false, 10), ...
    'spinachgui:DuplicateAtomID');
assertThrows(@() model.addInteraction("Shift", 99, 99, eye(3), "ppm"), ...
    'spinachgui:MissingAtom');
assertThrows(@() model.addReferenceFrame([1 2; 3 4], "bad", NaN, "validation", false), ...
    'MATLAB:incorrectSize');
frameID = model.addReferenceFrame(2 * eye(3), "normalised", NaN, "validation", false, 5);
assert(frameID == 5, 'Requested reference-frame ID was not returned.');
assertClose(model.ReferenceFrames.Matrix{model.ReferenceFrames.ID == frameID}, eye(3), 1e-12, ...
    'Reference-frame normalisation');
interactionID = model.addInteraction("Shift", 10, 10, diag([1 2 3]), "ppm", "", 5, "", "validation", 11);
assert(interactionID == 11, 'Requested interaction ID was not returned.');
assertThrows(@() model.addInteraction("Shift", 10, 10, eye(3), "ppm", "", 1, "", "validation", 11), ...
    'spinachgui:DuplicateInteractionID');
assertThrows(@() model.addInteraction("Shift", 10, 10, eye(3), "ppm", "", 1, "", "validation", -2), ...
    'spinachgui:InvalidInteractionID');
assertThrows(@() model.addInteraction("Shift", 10, 10, eye(3), "ppm", "", 1234, "", "validation"), ...
    'spinachgui:MissingReferenceFrame');
childFrameID = model.addReferenceFrame(eye(3), "child", frameID, "validation", false, 6);
descendantInteractionID = model.addInteraction("Shift", 10, 10, diag([3 5 7]), "ppm", "", childFrameID, "", "validation", 12);
descendantRow = model.Interactions.ID == descendantInteractionID;
oldDcm = model.Interactions.DCM{descendantRow};
model.setReferenceFrameMatrix(frameID, spinachgui.eulerToDcm(0.3, -0.2, 0.1));
assert(~isequal(model.Interactions.DCM{descendantRow}, oldDcm), ...
    'Ancestor reference-frame edits should refresh descendant interaction DCMs.');
replacementDcm = model.Interactions.DCM{descendantRow};
model.addReferenceFrame(spinachgui.eulerToDcm(-0.1, 0.2, -0.3), "normalised", NaN, "validation", false, frameID);
assert(~isequal(model.Interactions.DCM{descendantRow}, replacementDcm), ...
    'Reference-frame replacement should refresh descendant interaction DCMs.');
assertThrows(@() model.addReferenceFrame(eye(3), "missing", 1234, "validation", false), ...
    'spinachgui:MissingReferenceFrame');
assertThrows(@() model.addReferenceFrame(eye(3), "cycle", childFrameID, "validation", false, frameID), ...
    'spinachgui:ReferenceFrameCycle');
end

function validateExporterAndImporterGuards(tmpDir)
model = spinachgui.Model();
model.addAtom("1H", [0 0 0], "A", false, 10);
model.addAtom("13C", [1 0 0], "B", false, 20);
model.addInteraction("Jcoupling", 10, 20, 12 * eye(3), "Hz", "", 1, "", "validation");
spinachFile = fullfile(tmpDir, 'noncontiguous_spinach.m');
spinachgui.writeSpinach(model, spinachFile);
text = fileread(spinachFile);
assert(contains(text, 'inter.coupling.scalar{1,2}') && ~contains(text, '{10') && ~contains(text, '{20'), ...
    'Spinach writer should remap non-contiguous model atom IDs to dense cell indices.');

xyzFile = fullfile(tmpDir, 'bad_header.xyz');
writeTextFile(xyzFile, sprintf('version 5\ncomment\nH 0 0 0\n'));
assertThrows(@() spinachgui.readXYZ(xyzFile), 'spinachgui:XYZAtomCount');

utf16XYZFile = fullfile(tmpDir, 'utf16.xyz');
utf16Body = sprintf('1\nUTF-16 test\nH 0 0 0\n');
fid = fopen(utf16XYZFile, 'w');
assert(fid > 0, 'Could not create UTF-16 XYZ fixture.');
utf16Cleanup = onCleanup(@() fclose(fid));
fwrite(fid, uint8([255 254]), 'uint8');
fwrite(fid, unicode2native(utf16Body, 'UTF-16LE'), 'uint8');
clear utf16Cleanup
utf16Model = spinachgui.readXYZ(utf16XYZFile);
assert(height(utf16Model.Atoms) == 1 && utf16Model.Atoms.Element(1) == "H", ...
    'UTF-16LE XYZ files should import.');

spinXMLXYZFile = fullfile(tmpDir, 'spinxml_payload.xyz');
writeTextFile(spinXMLXYZFile, ['<?xml version="1.0" encoding="utf-8"?>\n' ...
    '<spin_system><spin id="1" isotope="1H"><coordinates x="0" y="0" z="0" /></spin></spin_system>\n']);
spinXMLXYZModel = spinachgui.importFile(spinXMLXYZFile);
assert(height(spinXMLXYZModel.Atoms) == 1 && spinXMLXYZModel.Atoms.Element(1) == "H", ...
    'SpinXML payloads with .xyz extension should be content-dispatched safely.');

molFile = fullfile(tmpDir, 'v3000.mol');
writeTextFile(molFile, sprintf('x\n\n\n  0  0  0  0  0  0            999 V3000\nM  V30 BEGIN CTAB\nM  END\n'));
assertThrows(@() spinachgui.readMOL(molFile), 'spinachgui:UnsupportedMOL');

gaussianProbe = spinachgui.Model();
gID = gaussianProbe.addAtom("E", [0 0 0], "electron", false);
gaussianProbe.addInteraction("GTensor", gID, gID, eye(3), "Unitless", "", 1, "", "validation");
assert(gaussianProbe.Interactions.Unit(1) == "Unitless", 'g tensor unit should be unitless.');
end

function validateAppLooseTails()
appText = fileread(fullfile(fileparts(mfilename('fullpath')), '+spinachgui', 'App.m'));
assert(contains(appText, '*.magres') && contains(appText, '*.coo'), ...
    'Open dialog supported-file filter should include MAGRES and COSMOS files.');
app = spinachgui.App();
cleanup = onCleanup(@() deleteFigureIfValid(app.Figure));
labels = {"XY", "XZ", "YZ", "YX", "ZX", "ZY"};
expected = [0 90; 0 0; 90 0; 180 -90; 180 0; -90 0];
for idx = 1:numel(labels)
    button = findall(app.Figure, 'Text', char(labels{idx}));
    assert(isscalar(button), 'Expected exactly one %s view-plane button.', labels{idx});
    assert(isa(button.ButtonPushedFcn, 'function_handle'), '%s view-plane callback missing.', labels{idx});
    button.ButtonPushedFcn(button, []);
    assertClose(app.CurrentView, expected(idx, :), 1e-12, labels{idx} + " view");
end
model = spinachgui.Model();
model.addAtom("1H", [0 0 0], "H", false);
model.addAtom("13C", [1 0 0], "C", false);
app.Model = model;
app.VisibilityControls.AtomIDs.Value = true;
app.VisibilityControls.AtomIDs.ValueChangedFcn(app.VisibilityControls.AtomIDs, []);
labelsOnAxes = findall(app.Axes, 'Type', 'text');
assert(~isempty(labelsOnAxes), 'Atom-ID checkbox should create text labels on the axes.');
app.VisibilityControls.Axes.Value = false;
app.VisibilityControls.Axes.ValueChangedFcn(app.VisibilityControls.Axes, []);
assert(strcmp(app.Axes.Visible, 'off'), 'Axes checkbox should hide the axes.');
model.addInteraction("Shift", 1, 1, diag([1 2 4]), "ppm", "", 1, "", "validation");
app.Model = model;
app.VisibilityControls.AtomIDs.ValueChangedFcn(app.VisibilityControls.AtomIDs, []);
app.VisualizationInteractionsTable.Selection = [];
matrixBefore = app.Model.Interactions.Matrix{app.Model.Interactions.Kind == "Shift"};
removeButton = findall(app.Figure, 'Text', 'Remove anisotropy');
removeButton.ButtonPushedFcn(removeButton, []);
matrixAfter = app.Model.Interactions.Matrix{app.Model.Interactions.Kind == "Shift"};
assertClose(matrixAfter, matrixBefore, 0, 'Empty interaction selection should not mutate tensors');
gTensorCheckbox = findall(app.Figure, 'Text', 'G-TENSOR');
assert(isscalar(gTensorCheckbox) && strcmp(gTensorCheckbox.Enable, 'off'), ...
    'Unimplemented tensor visibility controls should be disabled, not inert.');
end

function writeTextFile(filename, text)
fid = fopen(filename, 'w');
assert(fid > 0, 'Could not create %s.', filename);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', text);
end

function assertThrows(functionHandle, expectedID)
try
    functionHandle();
catch err
    expectedTail = regexp(expectedID, '[^:]+$', 'match', 'once');
    matched = strcmp(err.identifier, expectedID) || endsWith(err.identifier, [':' expectedTail]);
    assert(matched, 'Expected %s, got %s.', expectedID, err.identifier);
    return
end
error('Expected error %s was not thrown.', expectedID);
end

function assertClose(actual, expected, tolerance, context)
assert(all(abs(actual - expected) <= tolerance, 'all'), 'Unexpected value for %s.', context);
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
