function validate_shielding_to_shift()
%VALIDATE_SHIELDING_TO_SHIFT Deterministic shielding-to-shift conversion test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

references = spinachgui.shieldingReferenceTable();
assert(height(references) == 10, 'Legacy shielding reference count changed.');
assertClose(references.ReferenceShielding(references.Channel == "1H"), 33.440, 1e-12, '1H reference shielding');
assert(references.ReferenceSubstance(references.Channel == "31P") == "H3PO4", '31P reference substance changed.');

model = spinachgui.Model();
hAtom = model.addAtom('1H', [0 0 0], "H1");
cAtom = model.addAtom('13C', [1 0 0], "C1");
bAtom = model.addAtom('11B', [0 1 0], "B1");
nAtom = model.addAtom('15N', [0 0 1], "N1");

hShielding = [30 1 -2; 1 31 3; -2 3 32];
cShielding = diag([180 181 182]);
bShielding = [70 0.4 0.5; 0.4 71 0.6; 0.5 0.6 72];
nShielding = [-140 2 0; 2 -141 -3; 0 -3 -142];

hID = model.addInteraction("CShielding", hAtom, hAtom, hShielding, "ppm", "", 1, "", "validation");
cID = model.addInteraction("CShielding", cAtom, cAtom, cShielding, "ppm", "", 1, "", "validation");
bID = model.addInteraction("CShielding", bAtom, bAtom, bShielding, "ppm", "", 1, "BF3", "validation");
nID = model.addInteraction("CShielding", nAtom, nAtom, nShielding, "ppm", "", 1, "CH3NO2", "validation");
preexistingShiftID = model.addInteraction("Shift", hAtom, hAtom, eye(3), "ppm", "", 1, "TMS", "validation");
model.Dirty = false;

overrides = table("11B", 73.25, "BF3", ...
    'VariableNames', {'Channel', 'ReferenceShielding', 'ReferenceSubstance'});
summary = spinachgui.convertShieldingToShift(model, overrides, [hID bID]);
assert(height(summary) == 2, 'Selected conversion should report two interactions.');
assert(model.Dirty, 'Conversion should mark the model dirty.');
assertKind(model, hID, "Shift");
assertKind(model, bID, "Shift");
assertKind(model, cID, "CShielding");
assertKind(model, nID, "CShielding");
assertKind(model, preexistingShiftID, "Shift");
assertReference(model, hID, "TMS");
assertReference(model, bID, "BF3");
assertClose(findMatrix(model, hID), 33.440 * eye(3) - hShielding, 1e-12, '1H shift matrix');
assertClose(findMatrix(model, bID), 73.25 * eye(3) - bShielding, 1e-12, '11B shift matrix');
assert(model.Interactions.Unit(model.Interactions.ID == hID) == "ppm", 'Conversion should preserve units.');
assert(model.Interactions.Unit(model.Interactions.ID == bID) == "ppm", 'Custom-channel conversion should preserve units.');
assert(summary.Channel(1) == "1H" && summary.ReferenceShielding(1) == 33.440, 'Summary should record default 1H reference.');
assertClose(summary.ShieldingMatrix{2}, bShielding, 1e-12, 'Summary should preserve shielding matrix.');
assertClose(summary.ShiftMatrix{2}, 73.25 * eye(3) - bShielding, 1e-12, 'Summary should preserve shift matrix.');

secondSummary = model.convertShieldingToShift([cID nID]);
assert(height(secondSummary) == 2, 'Model wrapper should report two remaining conversions.');
assertKind(model, cID, "Shift");
assertKind(model, nID, "Shift");
assertReference(model, cID, "TMS");
assertReference(model, nID, "CH3NO2");
assertClose(findMatrix(model, cID), 186.38 * eye(3) - cShielding, 1e-12, '13C shift matrix');
assertClose(findMatrix(model, nID), -134.42 * eye(3) - nShielding, 1e-12, '15N shift matrix');
assert(sum(model.Interactions.Kind == "CShielding") == 0, 'All selected shieldings should be converted.');
assert(sum(model.Interactions.Kind == "Shift") == 5, 'Converted and pre-existing shifts should coexist.');
assertThrows(@() spinachgui.convertShieldingToShift(model, hID), 'spinachgui:InvalidShieldingSelection');

mismatchModel = spinachgui.Model();
hAtom = mismatchModel.addAtom('1H', [0 0 0], "H1");
hID = mismatchModel.addInteraction("CShielding", hAtom, hAtom, hShielding, "ppm", "", 1, "H2O", "validation");
assertThrows(@() spinachgui.convertShieldingToShift(mismatchModel), 'spinachgui:MissingShieldingReference');
waterReference = table("1H", 31.0, "H2O", ...
    'VariableNames', {'Channel', 'ReferenceShielding', 'ReferenceSubstance'});
spinachgui.convertShieldingToShift(mismatchModel, waterReference);
assertReference(mismatchModel, hID, "H2O");
assertClose(findMatrix(mismatchModel, hID), 31.0 * eye(3) - hShielding, 1e-12, 'non-default 1H reference shift matrix');

unknownModel = spinachgui.Model();
naAtom = unknownModel.addAtom('23Na', [0 0 0], "Na1");
unknownModel.addInteraction("CShielding", naAtom, naAtom, eye(3), "ppm", "", 1, "", "validation");
assertThrows(@() spinachgui.convertShieldingToShift(unknownModel), 'spinachgui:MissingShieldingReference');

fprintf('SHIELDING_TO_SHIFT_VALIDATION_OK\n');
end

function assertKind(model, interactionID, expectedKind)
idx = find(model.Interactions.ID == interactionID, 1);
assert(~isempty(idx), 'Missing interaction %d.', interactionID);
assert(model.Interactions.Kind(idx) == expectedKind, 'Unexpected kind for interaction %d.', interactionID);
end

function assertReference(model, interactionID, expectedReference)
idx = find(model.Interactions.ID == interactionID, 1);
assert(~isempty(idx), 'Missing interaction %d.', interactionID);
assert(model.Interactions.Reference(idx) == expectedReference, 'Unexpected reference for interaction %d.', interactionID);
end

function matrix = findMatrix(model, interactionID)
idx = find(model.Interactions.ID == interactionID, 1);
assert(~isempty(idx), 'Missing interaction %d.', interactionID);
matrix = model.Interactions.Matrix{idx};
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

function assertClose(actual, expected, tolerance, context)
assert(all(abs(actual - expected) <= tolerance, 'all'), 'Unexpected value for %s.', context);
end
