function validate_orientation_editor()
%VALIDATE_ORIENTATION_EDITOR Deterministic tensor/orientation editor smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

eulerRadians = [0.31, 0.72, -0.44];
dcm = spinachgui.eulerToDcm(eulerRadians(1), eulerRadians(2), eulerRadians(3));
roundTripDegrees = rad2deg(spinachgui.dcmToEuler(dcm));
assertClose(roundTripDegrees, rad2deg(eulerRadians), 1e-10, 'Euler/DCM helper round trip');
assertClose(spinachgui.normalizeDcm(dcm + 1e-10), dcm, 1e-8, 'DCM normalisation');

interactionMatrix = [10 2 -1; 2 11 3; -1 3 12];
eigenvalues = [8 11 14];
text = spinachgui.orientationExportText(dcm, 'InteractionMatrix', interactionMatrix, ...
    'Eigenvalues', eigenvalues, 'DcmVariableName', 'eigenvectors');
assert(contains(text, "interactionmatrix=["), 'Export text should include interaction matrix.');
assert(contains(text, "eigenvalues=["), 'Export text should include eigenvalues.');
assert(contains(text, "eigenvectors=["), 'Export text should include DCM/eigenvectors.');
assert(contains(text, "eulerangles=["), 'Export text should include Euler angles.');

callbackCount = 0;
editor = spinachgui.orientationEditor(dcm, 'Visible', 'off', 'Title', 'Validation orientation', ...
    'InteractionMatrix', interactionMatrix, 'Eigenvalues', eigenvalues, ...
    'ValueChangedFcn', @recordCallback);
assert(isstruct(editor), 'Editor should return a struct.');
assert(isvalid(editor.Figure), 'Editor figure was not constructed.');
assert(isvalid(editor.MatrixTable), 'Interaction matrix table was not constructed.');
assert(isvalid(editor.EigenvaluesTable), 'Eigenvalue table was not constructed.');
assert(isvalid(editor.DcmTable), 'DCM table was not constructed.');
assert(isvalid(editor.EulerTable), 'Euler table was not constructed.');
assert(isvalid(editor.ExportTextArea), 'Export preview was not constructed.');
assert(isequal(editor.Figure.Visible, 'off'), 'Headless orientation editor should be invisible.');
assertClose(editor.CurrentDcm(), dcm, 1e-12, 'Initial editor DCM');
assertClose(editor.CurrentEulerDegrees(), roundTripDegrees, 1e-10, 'Initial editor Euler angles');
assertClose(editor.CurrentInteractionMatrix(), interactionMatrix, 1e-12, 'Initial editor interaction matrix');
assertClose(editor.CurrentEigenvalues(), eigenvalues, 1e-12, 'Initial editor eigenvalues');
assert(contains(editor.ExportText(), "eigenvectors=["), 'Editor export preview should use legacy eigenvector name for interactions.');

newEigenvalues = [1 2 5];
editor.SetEigenvalues(newEigenvalues);
assertClose(editor.CurrentInteractionMatrix(), dcm * diag(newEigenvalues) * dcm.', 1e-10, ...
    'SetEigenvalues matrix update');
assertClose(editor.EigenvaluesTable.Data, newEigenvalues, 1e-12, 'SetEigenvalues table update');

newEulerDegrees = [30 40 50];
editor.SetEulerDegrees(newEulerDegrees);
expectedDcm = spinachgui.eulerToDcm(deg2rad(newEulerDegrees(1)), deg2rad(newEulerDegrees(2)), ...
    deg2rad(newEulerDegrees(3)));
assertClose(editor.CurrentDcm(), expectedDcm, 1e-12, 'SetEulerDegrees DCM');
assertClose(editor.DcmTable.Data, expectedDcm, 1e-12, 'SetEulerDegrees DCM table update');
assertClose(editor.EulerTable.Data, newEulerDegrees, 1e-12, 'SetEulerDegrees Euler table update');
assertClose(editor.CurrentInteractionMatrix(), expectedDcm * diag(newEigenvalues) * expectedDcm.', 1e-10, ...
    'SetEulerDegrees matrix update');

matrixEdit = [3 0.2 0.1; 0.2 4 0.3; 0.1 0.3 5];
editor.SetInteractionMatrix(matrixEdit);
assertClose(editor.CurrentInteractionMatrix(), matrixEdit, 1e-12, 'SetInteractionMatrix matrix');
assertClose(sort(editor.CurrentEigenvalues()), sort(eig(matrixEdit)).', 1e-12, 'SetInteractionMatrix eigenvalues');

editor.SetDcm(dcm);
assertClose(editor.CurrentDcm(), dcm, 1e-12, 'SetDcm DCM');
assertClose(editor.CurrentEulerDegrees(), roundTripDegrees, 1e-10, 'SetDcm Euler table update');
assert(callbackCount == 4, 'ValueChangedFcn should run once per programmatic edit.');

delete(editor.Figure);
validateModelMutationMethods();
validateAppTensorButtons();

fprintf('ORIENTATION_EDITOR_VALIDATION_OK\n');

    function recordCallback(~, newDcm)
        validateattributes(newDcm, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'callback DCM');
        callbackCount = callbackCount + 1;
    end
end

function validateModelMutationMethods()
model = spinachgui.Model();
model.addAtom("1H", [1 0 0], "proton", false);
model.addAtom("13C", [0 1 0], "carbon", false);
frameDcm = spinachgui.eulerToDcm(0.1, 0.2, 0.3);
frameID = model.addReferenceFrame(frameDcm, "validation frame", 1, "validation", false);
interactionID = model.addInteraction("Shift", 1, 1, diag([1 2 4]), "ppm", "", frameID, "", "validation");
idx = model.Interactions.ID == interactionID;
originalDcm = model.Interactions.DCM{idx};

newRootDcm = spinachgui.eulerToDcm(0.4, 0.5, 0.6);
newEigenvalues = [2 3 7];
model.setInteractionEigenSystem(interactionID, newEigenvalues, newRootDcm);
assertClose(model.Interactions.Eigenvalues{idx}, newEigenvalues, 1e-10, 'Model eigen-system eigenvalues');
assertClose(model.Interactions.DCM{idx}, newRootDcm, 1e-10, 'Model eigen-system DCM');
assert(model.Dirty, 'Model mutation should set dirty flag.');

model.Dirty = false;
replacementFrame = spinachgui.eulerToDcm(-0.2, 0.3, -0.4);
model.setReferenceFrameMatrix(frameID, replacementFrame);
assertClose(model.ReferenceFrames.Matrix{model.ReferenceFrames.ID == frameID}, replacementFrame, 1e-12, ...
    'Reference frame matrix update');
assert(~isequal(model.Interactions.DCM{idx}, originalDcm), 'Reference-frame update should refresh interaction DCM.');
assertClose(model.Interactions.DCM{idx}, expectedInteractionDcm(model, idx), 1e-10, ...
    'Reference-frame update should refresh interaction DCM to the frame closure.');
assert(model.Dirty, 'Reference-frame mutation should set dirty flag.');

model.addInteraction("Jcoupling", 1, 2, diag([10 20 30]), "Hz", "", 1, "", "validation");
coordsBefore = [model.Atoms.X, model.Atoms.Y, model.Atoms.Z];
model.alignLabFrameToInteraction(interactionID);
coordsAfter = [model.Atoms.X, model.Atoms.Y, model.Atoms.Z];
assert(~isequal(coordsBefore, coordsAfter), 'Lab-frame alignment should rotate atom coordinates.');

model.removeInteractionAnisotropy(interactionID);
isoMatrix = model.Interactions.Matrix{idx};
assertClose(isoMatrix, trace(isoMatrix) * eye(3) / 3, 1e-12, 'Remove anisotropy');
end

function validateAppTensorButtons()
app = spinachgui.App();
cleanup = onCleanup(@() deleteFigureIfValid(app.Figure));
assertButton(app, 'Orientation export...');
assertButton(app, 'Reference frame...');
assertButton(app, 'Remove anisotropy');
assertButton(app, 'Align lab frame');
end

function assertButton(app, label)
button = findall(app.Figure, 'Text', label);
assert(isscalar(button), 'App should expose exactly one %s button.', label);
assert(isa(button.ButtonPushedFcn, 'function_handle'), '%s callback missing.', label);
end

function assertClose(actual, expected, tolerance, context)
assert(all(abs(actual - expected) <= tolerance, 'all'), 'Unexpected value for %s.', context);
end

function dcm = expectedInteractionDcm(model, interactionRow)
[vectors, ~] = eig(spinachgui.symmetrizeTensor(model.Interactions.Matrix{interactionRow}));
dcm = spinachgui.normalizeDcm(model.referenceFrameToRootMatrix(model.Interactions.ReferenceFrameID(interactionRow)) * vectors);
end

function deleteFigureIfValid(fig)
if ~isempty(fig) && isvalid(fig)
    delete(fig);
end
end
