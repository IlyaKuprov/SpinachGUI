function validate_filter_dialog()
%VALIDATE_FILTER_DIALOG Deterministic SpinachGUI filter-dialog smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

model = buildFilterModel();
model.Dirty = false;
callbackCount = 0;
callbackSummary = [];
callbackModel = [];

dialog = spinachgui.filterDialog(model, 'Visible', 'off', 'Title', 'Validation filtering', ...
    'Thresholds', [0.50 5.0 5.0], 'RemoveOrphanAtoms', true, ...
    'ApplyFcn', @recordApply, 'CloseOnApply', false, 'CloseOnCancel', false);
assert(isstruct(dialog), 'Filter dialog should return a struct.');
assert(isvalid(dialog.Figure), 'Filter dialog figure was not constructed.');
assert(isequal(dialog.Figure.Visible, 'off'), 'Headless filter dialog should be invisible.');
assert(isvalid(dialog.ThresholdFields.Jcoupling), 'J threshold control missing.');
assert(isvalid(dialog.ThresholdFields.HFC), 'HFC threshold control missing.');
assert(isvalid(dialog.ThresholdFields.Quadrupolar), 'Quadrupolar threshold control missing.');
assert(isvalid(dialog.StatsTable), 'Filter statistics table missing.');
assert(isvalid(dialog.SummaryTable), 'Filter summary table missing.');
assert(isvalid(dialog.Axes.Jcoupling) && isvalid(dialog.Axes.HFC) && ...
    isvalid(dialog.Axes.Quadrupolar), 'Histogram axes missing.');
assert(dialog.RemoveOrphanAtoms(), 'Initial orphan-atom option was not preserved.');

summary = dialog.Summary();
assert(summary.FilteredAtomCount == 4, 'Preview should remove one orphan atom.');
assert(summary.FilteredInteractionCount == 5, 'Preview filtered interaction count changed.');
assert(numel(summary.RemovedInteractionIDsThreshold) == 3, ...
    'Preview threshold removal count changed.');
assert(isscalar(summary.RemovedInteractionIDsOrphanAtoms), ...
    'Preview orphan-interaction removal count changed.');
assert(height(dialog.StatsTable.Data) == 3, 'Stats table should show the three filterable kinds.');
assert(height(dialog.SummaryTable.Data) == numel(spinachgui.interactionKinds()), ...
    'Summary table should show legacy interaction-kind counts.');
assert(sum(summary.ThresholdStatistics.Histogram{summary.ThresholdStatistics.Kind == "Jcoupling"}) == 2, ...
    'J histogram should account for both source J-couplings.');
assert(model.Dirty == false && height(model.Atoms) == 5 && height(model.Interactions) == 9, ...
    'Dialog preview must not mutate the source model.');

thresholds = dialog.Thresholds();
assert(thresholds.Jcoupling == 0.50 && thresholds.HFC == 5.0 && ...
    thresholds.Quadrupolar == 5.0, 'Initial thresholds were not normalised into the dialog.');

dialog.SetThresholds(struct('Jcoupling', 0.0, 'HFC', 0.0, 'Quadrupolar', 0.0));
looseSummary = dialog.Summary();
assert(looseSummary.FilteredInteractionCount == 9, 'Loose filter preview should retain all thresholded interactions.');
assert(looseSummary.FilteredAtomCount == 5, 'Loose filter preview should retain all atoms.');
assert(dialog.LastAction() == "preview", 'SetThresholds should leave the dialog in preview state.');

dialog.SetThresholds([0.50 5.0 5.0]);
[appliedModel, appliedSummary] = dialog.Apply();
assert(callbackCount == 1, 'Apply callback should run exactly once.');
assert(dialog.LastAction() == "apply", 'Apply should update LastAction.');
assert(height(appliedModel.Interactions) == 5, 'Applied filtered model interaction count changed.');
assert(appliedSummary.FilteredAtomCount == 4, 'Applied summary atom count changed.');
assert(isequal(callbackSummary.FilteredInteractionCount, appliedSummary.FilteredInteractionCount), ...
    'Apply callback summary does not match returned summary.');
assert(height(callbackModel.Interactions) == height(appliedModel.Interactions), ...
    'Apply callback model does not match returned model.');
assert(model.Dirty == false && height(model.Atoms) == 5 && height(model.Interactions) == 9, ...
    'Dialog apply must not mutate the source model directly.');

dialog.Cancel();
assert(dialog.LastAction() == "cancel", 'Cancel should update LastAction.');
delete(dialog.Figure);

app = spinachgui.App();
assert(isvalid(app.Figure), 'App construction failed after filter-dialog integration.');
button = findall(app.Figure, 'Text', 'Filter...');
assert(isscalar(button), 'App should expose exactly one Filter button.');
assert(isa(button.ButtonPushedFcn, 'function_handle'), 'Filter button callback missing.');
delete(app.Figure);

fprintf('FILTER_DIALOG_VALIDATION_OK\n');

    function recordApply(~, filteredModel, filterSummary)
        callbackCount = callbackCount + 1;
        callbackModel = filteredModel;
        callbackSummary = filterSummary;
    end
end

function model = buildFilterModel()
model = spinachgui.Model();
h1 = model.addAtom('1H', [0 0 0], "H1");
h2 = model.addAtom('1H', [1 0 0], "H2");
n1 = model.addAtom('14N', [0 1 0], "N1");
e1 = model.addAtom('E', [0 0 0], "e1");
c1 = model.addAtom('13C', [0 0 1], "C1");

model.addInteraction("Jcoupling", h1, h2, 0.50 * eye(3), ...
    "Hz", "remove at equality", 1, "", "validation");
model.addInteraction("Jcoupling", h1, n1, 0.51 * eye(3), ...
    "Hz", "keep above", 1, "", "validation");
model.addInteraction("HFC", c1, e1, diag([1 1 1]), ...
    "Gauss", "remove weak HFC", 1, "", "validation");
model.addInteraction("HFC", h1, e1, diag([3 4 0]), ...
    "Gauss", "keep equal HFC", 1, "", "validation");
model.addInteraction("Quadrupolar", c1, c1, diag([1 1 0]), ...
    "MHz", "remove weak QC", 1, "", "validation");
model.addInteraction("Quadrupolar", n1, n1, diag([0 0 6]), ...
    "MHz", "keep strong QC", 1, "", "validation");
model.addInteraction("Shift", h2, h2, diag([10 11 12]), ...
    "ppm", "always keep", 1, "", "validation");
model.addInteraction("CBond", c1, h2, eye(3), ...
    "Angstroms", "drop with orphan", 1, "", "validation");
model.addInteraction("CBond", h1, h2, 2 * eye(3), ...
    "Angstroms", "keep bond", 1, "", "validation");
end
