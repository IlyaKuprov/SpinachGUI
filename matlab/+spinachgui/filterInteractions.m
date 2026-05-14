function [filteredModel, summary] = filterInteractions(model, thresholds, removeOrphanAtoms)
%FILTERINTERACTIONS Apply legacy SpinachGUI import-filter semantics.
%   FILTEREDMODEL = FILTERINTERACTIONS(MODEL, THRESHOLDS, REMOVEORPHANATOMS)
%   returns a filtered copy of MODEL. THRESHOLDS may be a struct with fields
%   Jcoupling/JC, HFC, and Quadrupolar/QC, or a three-element numeric vector
%   [JCOUPLING HFC QUADRUPOLAR]. Missing thresholds default to zero.
%
%   The filtering follows GUI/FilterFile.cpp exactly where the historical
%   behavior is unambiguous: J-couplings are measured as abs(Matrix(1,1)) and
%   removed when <= threshold; HFC and quadrupolar tensors are measured by the
%   Frobenius norm and kept when >= threshold. Optional orphan-atom removal
%   keeps atoms referenced by remaining non-CBond interactions, drops
%   interactions touching removed atoms, and compacts atom IDs.
%
%   [FILTEREDMODEL, SUMMARY] also returns deterministic counts, removed IDs,
%   ID maps, and the legacy 20-bin threshold histograms used by the dialog.

if nargin < 2
    thresholds = struct();
end
if nargin < 3
    removeOrphanAtoms = false;
end
if ~isa(model, 'spinachgui.Model')
    error('spinachgui:InvalidModel', 'Input must be a spinachgui.Model object.');
end
thresholds = normalizeThresholds(thresholds);
removeOrphanAtoms = normalizeLogicalScalar(removeOrphanAtoms, 'removeOrphanAtoms');

originalInteractions = model.Interactions;
[thresholdStats, measures] = thresholdStatistics(originalInteractions);
keepThreshold = true(height(originalInteractions), 1);
removalReason = strings(height(originalInteractions), 1);

for row = 1:height(originalInteractions)
    kind = string(originalInteractions.Kind(row));
    switch kind
        case "Jcoupling"
            if measures.Jcoupling(row) <= thresholds.Jcoupling
                keepThreshold(row) = false;
                removalReason(row) = "Jcoupling threshold";
            end
        case "HFC"
            if measures.HFC(row) < thresholds.HFC
                keepThreshold(row) = false;
                removalReason(row) = "HFC threshold";
            end
        case "Quadrupolar"
            if measures.Quadrupolar(row) < thresholds.Quadrupolar
                keepThreshold(row) = false;
                removalReason(row) = "Quadrupolar threshold";
            end
    end
end

interactions = originalInteractions(keepThreshold, :);
removedByThreshold = originalInteractions.ID(~keepThreshold);
removedThresholdReasons = removalReason(~keepThreshold);

atoms = model.Atoms;
atomIDMap = table(atoms.ID, atoms.ID, 'VariableNames', {'OriginalID','NewID'});
removedAtomIDs = zeros(0, 1);
removedByOrphanAtoms = zeros(0, 1);

if removeOrphanAtoms
    [atoms, interactions, atomIDMap, removedAtomIDs, removedByOrphanAtoms] = ...
        removeOrphans(atoms, interactions);
end

[interactions, interactionIDMap] = compactInteractionIDs(interactions);

filteredModel = spinachgui.Model();
filteredModel.Atoms = atoms;
filteredModel.Interactions = interactions;
filteredModel.ReferenceFrames = model.ReferenceFrames;
filteredModel.SourceFile = model.SourceFile;
filteredModel.Dirty = model.Dirty || ~isempty(removedByThreshold) || ...
    ~isempty(removedAtomIDs) || ~isempty(removedByOrphanAtoms) || ...
    idsChanged(originalInteractions(keepThreshold, :), interactionIDMap);

summary = struct();
summary.Thresholds = struct2table(thresholds);
summary.RemoveOrphanAtoms = removeOrphanAtoms;
summary.InteractionCounts = interactionCounts(originalInteractions, interactions);
summary.ThresholdStatistics = thresholdStats;
summary.RemovedInteractionIDsThreshold = removedByThreshold(:).';
summary.RemovedInteractionThresholdReasons = removedThresholdReasons(:).';
summary.RemovedAtomIDs = removedAtomIDs(:).';
summary.RemovedInteractionIDsOrphanAtoms = removedByOrphanAtoms(:).';
summary.AtomIDMap = atomIDMap;
summary.InteractionIDMap = interactionIDMap;
summary.OriginalAtomCount = height(model.Atoms);
summary.FilteredAtomCount = height(filteredModel.Atoms);
summary.OriginalInteractionCount = height(model.Interactions);
summary.FilteredInteractionCount = height(filteredModel.Interactions);
end

function thresholds = normalizeThresholds(input)
thresholds = struct('Jcoupling', 0.0, 'HFC', 0.0, 'Quadrupolar', 0.0);
if isempty(input)
    return
end
if isnumeric(input)
    if numel(input) ~= 3
        error('spinachgui:InvalidFilterThresholds', ...
            'Numeric thresholds must be [Jcoupling HFC Quadrupolar].');
    end
    thresholds.Jcoupling = double(input(1));
    thresholds.HFC = double(input(2));
    thresholds.Quadrupolar = double(input(3));
elseif isstruct(input)
    thresholds.Jcoupling = fieldOrDefault(input, {'Jcoupling','JC','J'}, 0.0);
    thresholds.HFC = fieldOrDefault(input, {'HFC'}, 0.0);
    thresholds.Quadrupolar = fieldOrDefault(input, {'Quadrupolar','QC'}, 0.0);
else
    error('spinachgui:InvalidFilterThresholds', ...
        'Thresholds must be a struct, an empty value, or a three-element vector.');
end
validateThreshold(thresholds.Jcoupling, 'Jcoupling');
validateThreshold(thresholds.HFC, 'HFC');
validateThreshold(thresholds.Quadrupolar, 'Quadrupolar');
end

function value = fieldOrDefault(input, names, defaultValue)
value = defaultValue;
for idx = 1:numel(names)
    if isfield(input, names{idx})
        value = double(input.(names{idx}));
        return
    end
end
end

function validateThreshold(value, name)
if ~isscalar(value) || ~isnumeric(value) || ~isfinite(value) || value < 0
    error('spinachgui:InvalidFilterThresholds', ...
        '%s threshold must be a finite non-negative scalar.', name);
end
end

function value = normalizeLogicalScalar(value, name)
if isempty(value)
    value = false;
end
if ~(islogical(value) || isnumeric(value)) || ~isscalar(value)
    error('spinachgui:InvalidFilterOptions', '%s must be a scalar logical value.', name);
end
value = logical(value);
end

function [stats, measures] = thresholdStatistics(interactions)
kinds = ["Jcoupling"; "HFC"; "Quadrupolar"];
minMeasure = zeros(numel(kinds), 1);
maxMeasure = zeros(numel(kinds), 1);
maxHistogramCount = zeros(numel(kinds), 1);
histograms = cell(numel(kinds), 1);
count = zeros(numel(kinds), 1);
measures = table(zeros(height(interactions), 1), zeros(height(interactions), 1), ...
    zeros(height(interactions), 1), 'VariableNames', {'Jcoupling','HFC','Quadrupolar'});

for kindIdx = 1:numel(kinds)
    kind = kinds(kindIdx);
    values = zeros(0, 1);
    rows = find(interactions.Kind == kind);
    for row = rows(:).'
        matrix = interactionMatrix(interactions, row);
        switch kind
            case "Jcoupling"
                value = abs(matrix(1, 1));
                measures.Jcoupling(row) = value;
            case "HFC"
                value = norm(matrix, 'fro');
                measures.HFC(row) = value;
            case "Quadrupolar"
                value = norm(matrix, 'fro');
                measures.Quadrupolar(row) = value;
        end
        values(end+1, 1) = value; %#ok<AGROW>
    end
    count(kindIdx) = numel(values);
    if isempty(values)
        histograms{kindIdx} = zeros(1, 20);
        continue
    end
    minMeasure(kindIdx) = min(values);
    maxMeasure(kindIdx) = max(values);
    histograms{kindIdx} = legacyHistogram(values, minMeasure(kindIdx), ...
        maxMeasure(kindIdx));
    maxHistogramCount(kindIdx) = max(histograms{kindIdx});
end

stats = table(kinds, count, minMeasure, maxMeasure, maxHistogramCount, histograms, ...
    'VariableNames', {'Kind','Count','MinMeasure','MaxMeasure', ...
    'MaxHistogramCount','Histogram'});
end

function matrix = interactionMatrix(interactions, row)
matrix = interactions.Matrix{row};
if ~isnumeric(matrix) || ~isequal(size(matrix), [3 3])
    error('spinachgui:InvalidInteractionMatrix', ...
        'Interaction %g does not contain a numeric 3x3 matrix.', interactions.ID(row));
end
end

function histogram = legacyHistogram(values, minValue, maxValue)
histogram = zeros(1, 20);
for idx = 1:numel(values)
    bin = floor(20 * (values(idx) - minValue) / (maxValue - minValue + 1.0e-5)) + 1;
    bin = min(max(bin, 1), 20);
    histogram(bin) = histogram(bin) + 1;
end
end

function [atoms, interactions, atomIDMap, removedAtomIDs, removedInteractionIDs] = ...
    removeOrphans(atoms, interactions)
activeAtomIDs = zeros(0, 1);
for row = 1:height(interactions)
    if interactions.Kind(row) == "CBond"
        continue
    end
    activeAtomIDs(end+1, 1) = interactions.A(row); %#ok<AGROW>
    if ~isnan(interactions.B(row))
        activeAtomIDs(end+1, 1) = interactions.B(row); %#ok<AGROW>
    end
end
activeAtomIDs = unique(activeAtomIDs(~isnan(activeAtomIDs)));
keepAtoms = ismember(atoms.ID, activeAtomIDs);
removedAtomIDs = atoms.ID(~keepAtoms);
atoms = atoms(keepAtoms, :);
oldAtomIDs = atoms.ID;
newAtomIDs = (1:height(atoms)).';
atomIDMap = table(oldAtomIDs, newAtomIDs, 'VariableNames', {'OriginalID','NewID'});

validInteractions = true(height(interactions), 1);
for row = 1:height(interactions)
    ids = interactions.A(row);
    if ~isnan(interactions.B(row))
        ids = [ids, interactions.B(row)]; %#ok<AGROW>
    end
    if any(~ismember(ids(~isnan(ids)), oldAtomIDs))
        validInteractions(row) = false;
    end
end
removedInteractionIDs = interactions.ID(~validInteractions);
interactions = interactions(validInteractions, :);

for atomIdx = 1:numel(oldAtomIDs)
    atomRowsA = interactions.A == oldAtomIDs(atomIdx);
    atomRowsB = interactions.B == oldAtomIDs(atomIdx);
    interactions.A(atomRowsA) = newAtomIDs(atomIdx);
    interactions.B(atomRowsB) = newAtomIDs(atomIdx);
end
atoms.ID = newAtomIDs;
end

function [interactions, idMap] = compactInteractionIDs(interactions)
originalIDs = interactions.ID;
newIDs = zeros(height(interactions), 1);
positiveID = 1;
negativeID = -1;
for row = 1:height(interactions)
    if interactions.Kind(row) == "CBond"
        newIDs(row) = negativeID;
        negativeID = negativeID - 1;
    else
        newIDs(row) = positiveID;
        positiveID = positiveID + 1;
    end
end
interactions.ID = newIDs;
idMap = table(originalIDs, newIDs, interactions.Kind, ...
    'VariableNames', {'OriginalID','NewID','Kind'});
end

function counts = interactionCounts(originalInteractions, filteredInteractions)
kinds = spinachgui.interactionKinds().';
before = zeros(numel(kinds), 1);
after = zeros(numel(kinds), 1);
for idx = 1:numel(kinds)
    before(idx) = sum(originalInteractions.Kind == kinds(idx));
    after(idx) = sum(filteredInteractions.Kind == kinds(idx));
end
counts = table(kinds, before, before - after, after, ...
    'VariableNames', {'Kind','Before','Removed','After'});
end

function changed = idsChanged(keptOriginalInteractions, interactionIDMap)
if height(keptOriginalInteractions) ~= height(interactionIDMap)
    changed = true;
    return
end
changed = any(keptOriginalInteractions.ID ~= interactionIDMap.NewID);
end
