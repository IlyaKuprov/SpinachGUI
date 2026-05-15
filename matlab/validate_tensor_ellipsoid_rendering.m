function validate_tensor_ellipsoid_rendering()
%VALIDATE_TENSOR_ELLIPSOID_RENDERING Headless smoke test for tensor ellipsoid graphics.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

tmpDir = tempname;
mkdir(tmpDir);
cleanup = onCleanup(@() cleanupTempDir(tmpDir));
fixtureFile = fullfile(tmpDir, 'ellipsoid_fixture.sxml');
spinachgui.writeSpinXML(ellipsoidFixture(), fixtureFile);

app = spinachgui.App(fixtureFile);
appCleanup = onCleanup(@() deleteFigureIfValid(app.Figure));

surfaceTags = tensorTags(app.Axes, 'Surface', 'TensorEllipsoid_');
axisTags = tensorTags(app.Axes, 'Line', 'TensorAxis_');
expectedIDs = app.Model.Interactions.ID(app.Model.Interactions.ID > 0 & ...
    ismember(app.Model.Interactions.Kind, ["Shift", "CShielding", "HFC", ...
    "Quadrupolar", "GTensor", "ZFS", "CHITensor"]));
assert(numel(surfaceTags) == numel(expectedIDs), ...
    'Expected one ellipsoid surface per drawable tensor interaction.');
assert(numel(axisTags) == 3 * numel(expectedIDs), ...
    'Expected three principal-axis lines per drawable tensor interaction.');
assert(strcmp(app.TensorControls.HFC.Checkbox.Enable, 'on'), ...
    'HFC tensor control should be enabled when HFC data are present.');
assert(strcmp(app.TensorControls.Shift.Checkbox.Enable, 'on'), ...
    'Shift/shielding tensor control should be enabled when shift or shielding data are present.');

invokeButton(app.Figure, 'NMR');
assert(app.TensorControls.Shift.Checkbox.Value && app.TensorControls.Quadrupolar.Checkbox.Value, ...
    'NMR tensor mode should enable shift/shielding and quadrupolar tensors.');
assert(~app.TensorControls.HFC.Checkbox.Value && ~app.TensorControls.GTensor.Checkbox.Value, ...
    'NMR tensor mode should disable EPR tensor classes.');
invokeButton(app.Figure, 'EPR');
assert(app.TensorControls.HFC.Checkbox.Value && app.TensorControls.GTensor.Checkbox.Value && app.TensorControls.ZFS.Checkbox.Value, ...
    'EPR tensor mode should enable HFC, g-tensor, and ZFS tensors.');
assert(~app.TensorControls.Shift.Checkbox.Value && ~app.TensorControls.Quadrupolar.Checkbox.Value, ...
    'EPR tensor mode should disable NMR tensor classes.');
invokeButton(app.Figure, 'All');
assert(app.TensorControls.Shift.Checkbox.Value && app.TensorControls.HFC.Checkbox.Value && ...
    app.TensorControls.Quadrupolar.Checkbox.Value && app.TensorControls.GTensor.Checkbox.Value, ...
    'All tensor mode should enable all tensor classes.');

hfcID = app.Model.Interactions.ID(app.Model.Interactions.Kind == "HFC");
app.TensorControls.HFC.Checkbox.Value = false;
invokeValueChanged(app.TensorControls.HFC.Checkbox);
assert(~any(surfaceTagsForID(app.Axes, 'Surface', 'TensorEllipsoid_', hfcID)), ...
    'Disabled HFC tensor control should remove HFC ellipsoid surfaces.');
app.TensorControls.HFC.Checkbox.Value = true;
invokeValueChanged(app.TensorControls.HFC.Checkbox);

shiftID = app.Model.Interactions.ID(app.Model.Interactions.Kind == "Shift");
initialRadius = surfaceRadius(app.Axes, shiftID, atomCoords(app.Model, app.Model.Interactions.A(app.Model.Interactions.ID == shiftID)));
app.TensorControls.Shift.Slider.Value = 10;
invokeValueChanged(app.TensorControls.Shift.Slider);
scaledRadius = surfaceRadius(app.Axes, shiftID, atomCoords(app.Model, app.Model.Interactions.A(app.Model.Interactions.ID == shiftID)));
assert(scaledRadius > 5 * initialRadius, ...
    'Shift/shielding logarithmic slider should enlarge the rendered ellipsoid.');

app.TensorControls.Ellipsoids.Value = false;
invokeValueChanged(app.TensorControls.Ellipsoids);
assert(isempty(tensorTags(app.Axes, 'Surface', 'TensorEllipsoid_')), ...
    'Disabling interaction tensor ellipsoids should remove surfaces.');
assert(numel(tensorTags(app.Axes, 'Line', 'TensorAxis_')) == 3 * numel(expectedIDs), ...
    'Principal-axis lines should remain when only ellipsoid surfaces are disabled.');

app.TensorControls.Axes.Value = false;
invokeValueChanged(app.TensorControls.Axes);
assert(isempty(tensorTags(app.Axes, 'Surface', 'TensorEllipsoid_')), ...
    'Ellipsoid surfaces should remain disabled.');
assert(isempty(tensorTags(app.Axes, 'Line', 'TensorAxis_')), ...
    'Disabling interaction tensor axes should remove principal-axis lines.');

fprintf('TENSOR_ELLIPSOID_RENDERING_VALIDATION_OK\n');
end

function model = ellipsoidFixture()
model = spinachgui.Model();
hID = model.addAtom("1H", [0 0 0], "proton", false);
cID = model.addAtom("13C", [1.1 0 0], "carbon", false);
nID = model.addAtom("14N", [0 1.1 0], "nitrogen", false);
eID = model.addAtom("E", [0 0 0], "electron", false);
model.addInteraction("Shift", hID, hID, diag([10 20 40]), "ppm", "shift", 1, "", "validation");
model.addInteraction("CShielding", cID, cID, diag([80 120 160]), "ppm", "shielding", 1, "", "validation");
model.addInteraction("HFC", cID, eID, diag([-10 30 50]), "Gauss", "hfc", 1, "", "validation");
model.addInteraction("Quadrupolar", nID, nID, diag([-1 2 4]), "MHz", "nqi", 1, "", "validation");
model.addInteraction("GTensor", eID, eID, diag([2.001 2.002 2.003]), "Unitless", "g", 1, "", "validation");
model.addInteraction("ZFS", eID, eID, diag([-100 20 80]), "MHz", "zfs", 1, "", "validation");
model.addInteraction("CHITensor", eID, eID, diag([1 2 3]), "Unknown", "chi", 1, "", "validation");
end

function tags = tensorTags(ax, objectType, prefix)
objects = findall(ax, 'Type', objectType);
tags = strings(0, 1);
for k = 1:numel(objects)
    tag = string(objects(k).Tag);
    if startsWith(tag, prefix)
        tags(end+1, 1) = tag; %#ok<AGROW>
    end
end
end

function present = surfaceTagsForID(ax, objectType, prefix, interactionID)
tags = tensorTags(ax, objectType, prefix);
present = tags == prefix + string(interactionID);
end

function radius = surfaceRadius(ax, interactionID, centre)
surfaces = findall(ax, 'Type', 'Surface', 'Tag', sprintf('TensorEllipsoid_%d', interactionID));
assert(isscalar(surfaces), 'Expected exactly one surface for interaction %d.', interactionID);
points = [surfaces.XData(:), surfaces.YData(:), surfaces.ZData(:)];
radius = max(vecnorm(points - centre, 2, 2));
end

function coords = atomCoords(model, atomID)
row = find(model.Atoms.ID == atomID, 1);
assert(~isempty(row), 'Missing atom %d.', atomID);
coords = [model.Atoms.X(row), model.Atoms.Y(row), model.Atoms.Z(row)];
end

function invokeValueChanged(control)
callback = control.ValueChangedFcn;
invokeCallback(callback, control);
end

function invokeButton(fig, label)
button = findall(fig, 'Text', char(label));
assert(isscalar(button), 'Expected exactly one %s button.', label);
invokeCallback(button.ButtonPushedFcn, button);
end

function invokeCallback(callback, source)
if isa(callback, 'function_handle')
    callback(source, []);
elseif iscell(callback)
    feval(callback{:});
else
    error('Missing callback for %s.', class(source));
end
drawnow;
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
