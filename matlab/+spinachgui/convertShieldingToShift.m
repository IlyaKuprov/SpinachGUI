function summary = convertShieldingToShift(model, referenceOverrides, interactionIDs)
%CONVERTSHIELDINGTOSHIFT Convert CShielding tensors to Shift tensors.
%   SUMMARY = CONVERTSHIELDINGTOSHIFT(MODEL) converts every positive
%   CShielding interaction in MODEL using the legacy ShieldingtoShift
%   algorithm: Shift = referenceShielding * eye(3) - CShielding. Reference
%   shieldings are in ppm and default to GUI/ShieldingtoShift.cpp values.
%
%   SUMMARY = CONVERTSHIELDINGTOSHIFT(MODEL, OVERRIDES) overlays OVERRIDES on
%   the legacy reference table. OVERRIDES must be a table with Channel and
%   ReferenceShielding columns, plus an optional ReferenceSubstance column.
%
%   SUMMARY = CONVERTSHIELDINGTOSHIFT(MODEL, OVERRIDES, IDS) converts only
%   the selected CShielding interaction IDs. Calling with IDS as the second
%   argument is also accepted.

if nargin < 2
    referenceOverrides = table();
end
if nargin < 3
    interactionIDs = [];
end
if nargin == 2 && ~istable(referenceOverrides)
    interactionIDs = referenceOverrides;
    referenceOverrides = table();
end
if ~isa(model, 'spinachgui.Model')
    error('spinachgui:InvalidModel', 'First argument must be a spinachgui.Model.');
end

[references, overrideChannels] = referenceTableWithOverrides(referenceOverrides);
rowIndices = selectedShieldingRows(model, interactionIDs);
summary = emptySummary(numel(rowIndices));
if isempty(rowIndices)
    return
end

for k = 1:numel(rowIndices)
    rowIndex = rowIndices(k);
    interaction = model.Interactions(rowIndex, :);
    atomIndex = find(model.Atoms.ID == interaction.A, 1);
    if isempty(atomIndex)
        error('spinachgui:InvalidShieldingInteraction', ...
            'CShielding interaction %d refers to missing atom %d.', interaction.ID, interaction.A);
    end
    if interaction.A ~= interaction.B
        error('spinachgui:InvalidShieldingInteraction', ...
            'CShielding interaction %d is not a same-atom interaction.', interaction.ID);
    end

    channel = channelForAtom(model.Atoms(atomIndex, :));
    [referenceShielding, referenceSubstance] = resolveReference(references, ...
        overrideChannels, channel, interaction.Reference, interaction.ID);
    shieldingMatrix = interaction.Matrix{1};
    validateShieldingMatrix(shieldingMatrix, interaction.ID);
    shiftMatrix = referenceShielding * eye(3) - shieldingMatrix;
    [vectors, values] = eig(shiftMatrix);
    dcm = model.referenceFrameToRootMatrix(interaction.ReferenceFrameID) * vectors;

    model.Interactions.Kind(rowIndex) = "Shift";
    model.Interactions.Matrix{rowIndex} = shiftMatrix;
    model.Interactions.Eigenvalues{rowIndex} = diag(values).';
    model.Interactions.DCM{rowIndex} = dcm;
    model.Interactions.Reference(rowIndex) = referenceSubstance;

    summary.InteractionID(k) = interaction.ID;
    summary.AtomID(k) = interaction.A;
    summary.Channel(k) = channel;
    summary.ReferenceShielding(k) = referenceShielding;
    summary.ReferenceSubstance(k) = referenceSubstance;
    summary.Unit(k) = interaction.Unit;
    summary.ShieldingMatrix{k} = shieldingMatrix;
    summary.ShiftMatrix{k} = shiftMatrix;
end
model.Dirty = true;
end

function [references, overrideChannels] = referenceTableWithOverrides(referenceOverrides)
references = spinachgui.shieldingReferenceTable();
overrideChannels = strings(0, 1);
if isempty(referenceOverrides)
    return
end
if ~istable(referenceOverrides)
    error('spinachgui:InvalidShieldingReference', 'Reference overrides must be a table.');
end
names = string(referenceOverrides.Properties.VariableNames);
if ~ismember("Channel", names) || ~ismember("ReferenceShielding", names)
    error('spinachgui:InvalidShieldingReference', ...
        'Reference overrides must contain Channel and ReferenceShielding columns.');
end
hasSubstance = ismember("ReferenceSubstance", names);
overrideChannels = string(referenceOverrides.Channel(:));
if any(strlength(strtrim(overrideChannels)) == 0)
    error('spinachgui:InvalidShieldingReference', 'Reference override channels must not be empty.');
end
if numel(unique(overrideChannels)) ~= numel(overrideChannels)
    error('spinachgui:InvalidShieldingReference', 'Reference override channels must be unique.');
end
for k = 1:height(referenceOverrides)
    channel = strtrim(string(referenceOverrides.Channel(k)));
    referenceShielding = double(referenceOverrides.ReferenceShielding(k));
    if hasSubstance
        referenceSubstance = strtrim(string(referenceOverrides.ReferenceSubstance(k)));
    else
        referenceSubstance = "";
    end
    idx = find(references.Channel == channel, 1);
    if isempty(idx)
        references(end+1, :) = {channel, referenceShielding, referenceSubstance}; %#ok<AGROW>
    else
        references.ReferenceShielding(idx) = referenceShielding;
        if strlength(referenceSubstance) > 0
            references.ReferenceSubstance(idx) = referenceSubstance;
        end
    end
end
end

function rowIndices = selectedShieldingRows(model, interactionIDs)
if isempty(interactionIDs)
    rowIndices = find(model.Interactions.ID > 0 & model.Interactions.Kind == "CShielding").';
    return
end
interactionIDs = double(interactionIDs(:)).';
if any(~isfinite(interactionIDs)) || any(fix(interactionIDs) ~= interactionIDs)
    error('spinachgui:InvalidShieldingSelection', 'Interaction IDs must be finite integers.');
end
if numel(unique(interactionIDs)) ~= numel(interactionIDs)
    error('spinachgui:InvalidShieldingSelection', 'Interaction IDs must be unique.');
end
rowIndices = zeros(size(interactionIDs));
for k = 1:numel(interactionIDs)
    rowIndex = find(model.Interactions.ID == interactionIDs(k), 1);
    if isempty(rowIndex)
        error('spinachgui:InvalidShieldingSelection', 'Interaction ID %d was not found.', interactionIDs(k));
    end
    if model.Interactions.Kind(rowIndex) ~= "CShielding"
        error('spinachgui:InvalidShieldingSelection', ...
            'Interaction ID %d is %s, not CShielding.', interactionIDs(k), model.Interactions.Kind(rowIndex));
    end
    rowIndices(k) = rowIndex;
end
end

function summary = emptySummary(numberOfRows)
summary = table('Size', [numberOfRows 8], ...
    'VariableTypes', {'double', 'double', 'string', 'double', 'string', 'string', 'cell', 'cell'}, ...
    'VariableNames', {'InteractionID', 'AtomID', 'Channel', 'ReferenceShielding', ...
    'ReferenceSubstance', 'Unit', 'ShieldingMatrix', 'ShiftMatrix'});
end

function channel = channelForAtom(atom)
mass = atom.Mass;
if abs(mass - round(mass)) < eps(max(1, abs(mass)))
    massText = string(sprintf('%d', round(mass)));
else
    massText = string(sprintf('%g', mass));
end
channel = massText + string(atom.Element);
end

function [referenceShielding, referenceSubstance] = resolveReference(references, overrideChannels, channel, storedReference, interactionID)
storedReference = strtrim(string(storedReference));
idx = find(references.Channel == channel, 1);
hasOverride = ismember(channel, overrideChannels);

if strlength(storedReference) > 0
    referenceSubstance = storedReference;
    if isempty(idx)
        missingReferenceError(channel, referenceSubstance, interactionID);
    end
    tableSubstance = strtrim(string(references.ReferenceSubstance(idx)));
    if hasOverride && strlength(tableSubstance) > 0 && tableSubstance ~= storedReference
        error('spinachgui:InvalidShieldingReference', ...
            'Override for channel %s names reference %s, but interaction %d already names %s.', ...
            channel, tableSubstance, interactionID, storedReference);
    end
    if ~hasOverride && tableSubstance ~= storedReference
        missingReferenceError(channel, referenceSubstance, interactionID);
    end
    referenceShielding = references.ReferenceShielding(idx);
else
    if isempty(idx)
        missingReferenceError(channel, "", interactionID);
    end
    referenceSubstance = strtrim(string(references.ReferenceSubstance(idx)));
    referenceShielding = references.ReferenceShielding(idx);
end

if strlength(referenceSubstance) == 0 || ~isfinite(referenceShielding)
    missingReferenceError(channel, referenceSubstance, interactionID);
end
end

function missingReferenceError(channel, referenceSubstance, interactionID)
if strlength(referenceSubstance) == 0
    referenceText = 'an unnamed reference';
else
    referenceText = sprintf('reference %s', referenceSubstance);
end
error('spinachgui:MissingShieldingReference', ...
    'No reference shielding was supplied for channel %s with %s in interaction %d.', ...
    channel, referenceText, interactionID);
end

function validateShieldingMatrix(matrix, interactionID)
if ~isequal(size(matrix), [3 3]) || ~isnumeric(matrix) || any(~isfinite(matrix), 'all')
    error('spinachgui:InvalidShieldingInteraction', ...
        'CShielding interaction %d does not contain a finite 3x3 matrix.', interactionID);
end
end
