function validate_orientation_editor()
%VALIDATE_ORIENTATION_EDITOR Deterministic DCM/Euler editor/export smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

eulerRadians = [0.31, 0.72, -0.44];
dcm = spinachgui.eulerToDcm(eulerRadians(1), eulerRadians(2), eulerRadians(3));
roundTripDegrees = rad2deg(spinachgui.dcmToEuler(dcm));
assertClose(roundTripDegrees, rad2deg(eulerRadians), 1e-10, 'Euler/DCM helper round trip');

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
assert(isvalid(editor.DcmTable), 'DCM table was not constructed.');
assert(isvalid(editor.EulerTable), 'Euler table was not constructed.');
assert(isvalid(editor.ExportTextArea), 'Export preview was not constructed.');
assert(isequal(editor.Figure.Visible, 'off'), 'Headless orientation editor should be invisible.');
assertClose(editor.CurrentDcm(), dcm, 1e-12, 'Initial editor DCM');
assertClose(editor.CurrentEulerDegrees(), roundTripDegrees, 1e-10, 'Initial editor Euler angles');
assert(contains(editor.ExportText(), "eigenvectors=["), 'Editor export preview should use legacy eigenvector name for interactions.');

newEulerDegrees = [30 40 50];
editor.SetEulerDegrees(newEulerDegrees);
expectedDcm = spinachgui.eulerToDcm(deg2rad(newEulerDegrees(1)), deg2rad(newEulerDegrees(2)), ...
    deg2rad(newEulerDegrees(3)));
assertClose(editor.CurrentDcm(), expectedDcm, 1e-12, 'SetEulerDegrees DCM');
assertClose(editor.DcmTable.Data, expectedDcm, 1e-12, 'SetEulerDegrees table update');
assertClose(editor.EulerTable.Data, newEulerDegrees, 1e-12, 'SetEulerDegrees Euler table update');

editor.SetDcm(dcm);
assertClose(editor.CurrentDcm(), dcm, 1e-12, 'SetDcm DCM');
assertClose(editor.CurrentEulerDegrees(), roundTripDegrees, 1e-10, 'SetDcm Euler table update');
assert(callbackCount == 2, 'ValueChangedFcn should run once per programmatic edit.');

delete(editor.Figure);

app = spinachgui.App();
button = findall(app.Figure, 'Text', 'Orientation export...');
assert(isscalar(button), 'App should expose exactly one orientation export button.');
assert(isa(button.ButtonPushedFcn, 'function_handle'), 'Orientation export button callback missing.');
delete(app.Figure);

fprintf('ORIENTATION_EDITOR_VALIDATION_OK\n');

    function recordCallback(~, newDcm)
        validateattributes(newDcm, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'callback DCM');
        callbackCount = callbackCount + 1;
    end
end

function assertClose(actual, expected, tolerance, context)
assert(all(abs(actual - expected) <= tolerance, 'all'), 'Unexpected value for %s.', context);
end
