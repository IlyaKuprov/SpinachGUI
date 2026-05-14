function validate_filter_interactions()
%VALIDATE_FILTER_INTERACTIONS Deterministic SpinachGUI filter parity test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

model = spinachgui.Model();
h1 = model.addAtom('1H', [0 0 0], "H1");
h2 = model.addAtom('1H', [1 0 0], "H2");
n1 = model.addAtom('14N', [0 1 0], "N1");
e1 = model.addAtom('E', [0 0 0], "e1");
c1 = model.addAtom('13C', [0 0 1], "C1");

jAtThreshold = model.addInteraction("Jcoupling", h1, h2, 0.50 * eye(3), ...
    "Hz", "remove at equality", 1, "", "validation");
jAboveThreshold = model.addInteraction("Jcoupling", h1, n1, 0.51 * eye(3), ...
    "Hz", "keep above", 1, "", "validation");
hfcBelowThreshold = model.addInteraction("HFC", c1, e1, diag([1 1 1]), ...
    "Gauss", "remove weak HFC", 1, "", "validation");
hfcAtThreshold = model.addInteraction("HFC", h1, e1, diag([3 4 0]), ...
    "Gauss", "keep equal HFC", 1, "", "validation");
qcBelowThreshold = model.addInteraction("Quadrupolar", c1, c1, diag([1 1 0]), ...
    "MHz", "remove weak QC", 1, "", "validation");
qcAboveThreshold = model.addInteraction("Quadrupolar", n1, n1, diag([0 0 6]), ...
    "MHz", "keep strong QC", 1, "", "validation");
shiftKept = model.addInteraction("Shift", h2, h2, diag([10 11 12]), ...
    "ppm", "always keep", 1, "", "validation");
bondDroppedWithCarbon = model.addInteraction("CBond", c1, h2, eye(3), ...
    "Angstroms", "drop with orphan", 1, "", "validation");
bondKept = model.addInteraction("CBond", h1, h2, 2 * eye(3), ...
    "Angstroms", "keep bond", 1, "", "validation");
model.Dirty = false;

thresholds = struct('Jcoupling', 0.50, 'HFC', 5.0, 'Quadrupolar', 5.0);
[filtered, summary] = spinachgui.filterInteractions(model, thresholds, true);

assert(model.Dirty == false, 'Filtering should not mutate the source model.');
assert(height(model.Atoms) == 5, 'Source atom table changed.');
assert(height(model.Interactions) == 9, 'Source interaction table changed.');
assert(summary.OriginalAtomCount == 5 && summary.FilteredAtomCount == 4, ...
    'Unexpected atom counts in summary.');
assert(summary.OriginalInteractionCount == 9 && summary.FilteredInteractionCount == 5, ...
    'Unexpected interaction counts in summary.');
assert(isequal(sort(summary.RemovedInteractionIDsThreshold), ...
    sort([jAtThreshold hfcBelowThreshold qcBelowThreshold])), ...
    'Threshold removal IDs do not match legacy semantics.');
assert(isequal(summary.RemovedAtomIDs, c1), 'Carbon should be the only orphan atom.');
assert(isequal(summary.RemovedInteractionIDsOrphanAtoms, bondDroppedWithCarbon), ...
    'CBond touching the removed orphan atom should be dropped.');
assert(filtered.Dirty, 'Filtered copy should be marked dirty.');
assert(height(filtered.Atoms) == 4, 'Filtered atom table has the wrong height.');
assert(isequal(filtered.Atoms.ID.', 1:4), 'Remaining atom IDs should be compacted.');
assert(all(filtered.Atoms.Label == ["H1"; "H2"; "N1"; "e1"]), ...
    'Atom row order should be preserved during compaction.');

assertHasKind(filtered, "Jcoupling", 1);
assertHasKind(filtered, "HFC", 1);
assertHasKind(filtered, "Quadrupolar", 1);
assertHasKind(filtered, "Shift", 1);
assertHasKind(filtered, "CBond", 1);
assertNoOriginalID(summary.InteractionIDMap, jAtThreshold);
assertNoOriginalID(summary.InteractionIDMap, hfcBelowThreshold);
assertNoOriginalID(summary.InteractionIDMap, qcBelowThreshold);
assertNoOriginalID(summary.InteractionIDMap, bondDroppedWithCarbon);
assertOriginalIDMapsToKind(summary.InteractionIDMap, jAboveThreshold, "Jcoupling");
assertOriginalIDMapsToKind(summary.InteractionIDMap, hfcAtThreshold, "HFC");
assertOriginalIDMapsToKind(summary.InteractionIDMap, qcAboveThreshold, "Quadrupolar");
assertOriginalIDMapsToKind(summary.InteractionIDMap, shiftKept, "Shift");
assertOriginalIDMapsToKind(summary.InteractionIDMap, bondKept, "CBond");

jStats = summary.ThresholdStatistics(summary.ThresholdStatistics.Kind == "Jcoupling", :);
hfcStats = summary.ThresholdStatistics(summary.ThresholdStatistics.Kind == "HFC", :);
qcStats = summary.ThresholdStatistics(summary.ThresholdStatistics.Kind == "Quadrupolar", :);
assert(jStats.Count == 2, 'J histogram count should include both source J-couplings.');
assertClose(jStats.MinMeasure, 0.50, 1e-12, 'J minimum measure');
assertClose(jStats.MaxMeasure, 0.51, 1e-12, 'J maximum measure');
assert(sum(jStats.Histogram{1}) == 2, 'J histogram should account for all J-couplings.');
assertClose(hfcStats.MinMeasure, sqrt(3), 1e-12, 'HFC minimum Frobenius norm');
assertClose(hfcStats.MaxMeasure, 5.0, 1e-12, 'HFC maximum Frobenius norm');
assertClose(qcStats.MinMeasure, sqrt(2), 1e-12, 'QC minimum Frobenius norm');
assertClose(qcStats.MaxMeasure, 6.0, 1e-12, 'QC maximum Frobenius norm');

[wrappedFiltered, wrappedSummary] = model.filterInteractions([0.50 5.0 5.0], true);
assert(height(wrappedFiltered.Interactions) == height(filtered.Interactions), ...
    'Model wrapper should return the same filtered interaction count.');
assert(wrappedSummary.FilteredAtomCount == summary.FilteredAtomCount, ...
    'Model wrapper should return the same atom count.');
assertThrows(@() spinachgui.filterInteractions(model, [-1 0 0], false), ...
    'spinachgui:InvalidFilterThresholds');

fprintf('FILTER_INTERACTIONS_VALIDATION_OK\n');
end

function assertHasKind(model, kind, expectedCount)
count = sum(model.Interactions.Kind == kind);
assert(count == expectedCount, 'Unexpected %s count: %d.', kind, count);
end

function assertNoOriginalID(idMap, originalID)
assert(~any(idMap.OriginalID == originalID), 'Original ID %d should be absent.', originalID);
end

function assertOriginalIDMapsToKind(idMap, originalID, kind)
row = find(idMap.OriginalID == originalID, 1);
assert(~isempty(row), 'Original ID %d should be retained.', originalID);
assert(idMap.Kind(row) == kind, 'Original ID %d mapped to the wrong kind.', originalID);
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
