function dialog = filterDialog(model, varargin)
%FILTERDIALOG Open the SpinachGUI interaction-filter dialog.
%   DIALOG = spinachgui.filterDialog(MODEL) opens a uifigure that previews
%   the legacy FilterFile threshold filter for J-couplings, hyperfine
%   couplings, and quadrupolar couplings. The source MODEL is not modified.
%
%   DIALOG = spinachgui.filterDialog(..., 'Visible', 'off') builds the same
%   dialog without showing it, for headless validation. Apply callbacks
%   receive the filtered copy and deterministic summary as
%   f(DIALOG, FILTEREDMODEL, SUMMARY).
%
%   Name-value options:
%     'Visible'             'on' or 'off'.
%     'Position'            Figure position vector.
%     'Title'               Dialog title.
%     'Thresholds'          Initial thresholds struct or [J HFC QC] vector.
%     'RemoveOrphanAtoms'   Initial orphan-atom removal flag.
%     'ApplyFcn'            Function handle called on Apply.
%     'CancelFcn'           Function handle called on No Filtering.
%     'CloseOnApply'        Close the dialog after Apply.
%     'CloseOnCancel'       Close the dialog after No Filtering.

if ~isa(model, 'spinachgui.Model')
    error('spinachgui:InvalidModel', 'Input must be a spinachgui.Model object.');
end

visible = 'on';
position = [160 120 980 720];
titleText = 'SpinachGUI filtering';
thresholdsInput = struct();
removeOrphanAtoms = false;
applyFcn = [];
cancelFcn = [];
closeOnApply = true;
closeOnCancel = true;

if rem(nargin - 1, 2) ~= 0
    error('spinachgui:FilterDialogOptions', 'Options must be name-value pairs.');
end
for k = 1:2:numel(varargin)
    name = validatestring(varargin{k}, {'Visible', 'Position', 'Title', 'Thresholds', ...
        'RemoveOrphanAtoms', 'ApplyFcn', 'CancelFcn', 'CloseOnApply', 'CloseOnCancel'}, ...
        mfilename, 'option name');
    value = varargin{k+1};
    switch name
        case 'Visible'
            visible = validatestring(value, {'on', 'off'}, mfilename, 'Visible');
        case 'Position'
            validateattributes(value, {'numeric'}, {'real', 'finite', 'vector', 'numel', 4}, ...
                mfilename, 'Position');
            position = double(value(:).');
        case 'Title'
            validateattributes(value, {'char', 'string'}, {'scalartext'}, mfilename, 'Title');
            titleText = char(value);
        case 'Thresholds'
            thresholdsInput = value;
        case 'RemoveOrphanAtoms'
            removeOrphanAtoms = value;
        case 'ApplyFcn'
            if ~isempty(value) && ~isa(value, 'function_handle')
                error('spinachgui:InvalidFilterCallback', ...
                    'ApplyFcn must be a function handle or empty.');
            end
            applyFcn = value;
        case 'CancelFcn'
            if ~isempty(value) && ~isa(value, 'function_handle')
                error('spinachgui:InvalidFilterCallback', ...
                    'CancelFcn must be a function handle or empty.');
            end
            cancelFcn = value;
        case 'CloseOnApply'
            closeOnApply = normalizeLogicalScalar(value, 'CloseOnApply');
        case 'CloseOnCancel'
            closeOnCancel = normalizeLogicalScalar(value, 'CloseOnCancel');
    end
end

sourceModel = model;
[latestFilteredModel, latestSummary] = spinachgui.filterInteractions(sourceModel, ...
    thresholdsInput, removeOrphanAtoms);
currentThresholds = table2struct(latestSummary.Thresholds);
removeOrphanAtoms = latestSummary.RemoveOrphanAtoms;
lastAction = "preview";

figureHandle = uifigure('Name', titleText, 'Position', position, 'Visible', visible);
root = uigridlayout(figureHandle, [5 1]);
root.RowHeight = {52, 260, 122, '1x', 36};
root.ColumnWidth = {'1x'};
root.Padding = [8 8 8 8];
root.RowSpacing = 8;

headerGrid = uigridlayout(root, [2 3]);
headerGrid.Layout.Row = 1;
headerGrid.ColumnWidth = {'1x', '1x', 190};
headerGrid.RowHeight = {22, 22};
headerGrid.Padding = [0 0 0 0];
uilabel(headerGrid, 'Text', 'Remove interactions below these thresholds', ...
    'FontWeight', 'bold');
infoLabel = uilabel(headerGrid, 'Text', ...
    'J-couplings are removed at equality; HFC and quadrupolar tensors are kept at equality.');
infoLabel.Layout.Row = 2;
infoLabel.Layout.Column = [1 2];
removeOrphansCheckBox = uicheckbox(headerGrid, 'Text', 'Remove orphaned atoms', ...
    'Value', removeOrphanAtoms, 'ValueChangedFcn', @removeOrphansChanged);
removeOrphansCheckBox.Layout.Row = [1 2];
removeOrphansCheckBox.Layout.Column = 3;

histGrid = uigridlayout(root, [1 3]);
histGrid.Layout.Row = 2;
histGrid.ColumnWidth = {'1x', '1x', '1x'};
histGrid.RowHeight = {'1x'};
histGrid.Padding = [0 0 0 0];
histGrid.ColumnSpacing = 8;

thresholdFields = struct();
axesHandles = struct();
statLabels = struct();
filterNames = ["Jcoupling", "HFC", "Quadrupolar"];
displayNames = ["J-coupling |J(1,1)|", "HFC Frobenius norm", "Quadrupolar Frobenius norm"];
for idx = 1:numel(filterNames)
    panel = uipanel(histGrid, 'Title', char(displayNames(idx)));
    panelGrid = uigridlayout(panel, [4 2]);
    panelGrid.RowHeight = {22, 28, '1x', 22};
    panelGrid.ColumnWidth = {78, '1x'};
    panelGrid.Padding = [6 4 6 4];
    panelGrid.RowSpacing = 5;
    uilabel(panelGrid, 'Text', 'Threshold');
    thresholdFields.(filterNames(idx)) = uieditfield(panelGrid, 'numeric', ...
        'ValueChangedFcn', @thresholdChanged, 'Limits', [0 Inf], 'LowerLimitInclusive', 'on');
    thresholdFields.(filterNames(idx)).Layout.Row = 1;
    thresholdFields.(filterNames(idx)).Layout.Column = 2;
    statLabels.(filterNames(idx)) = uilabel(panelGrid, 'Text', '');
    statLabels.(filterNames(idx)).Layout.Row = 2;
    statLabels.(filterNames(idx)).Layout.Column = [1 2];
    axesHandles.(filterNames(idx)) = uiaxes(panelGrid);
    axesHandles.(filterNames(idx)).Layout.Row = 3;
    axesHandles.(filterNames(idx)).Layout.Column = [1 2];
    axesHandles.(filterNames(idx)).Toolbar.Visible = 'off';
    summaryLabel = uilabel(panelGrid, 'Text', '20 legacy bins');
    summaryLabel.Layout.Row = 4;
    summaryLabel.Layout.Column = [1 2];
end

statsTable = uitable(root, 'ColumnEditable', false(1, 6), 'RowName', {});
statsTable.Layout.Row = 3;
summaryTable = uitable(root, 'ColumnEditable', false(1, 4), 'RowName', {});
summaryTable.Layout.Row = 4;

buttonGrid = uigridlayout(root, [1 4]);
buttonGrid.Layout.Row = 5;
buttonGrid.ColumnWidth = {'1x', 120, 120, 120};
buttonGrid.RowHeight = {28};
buttonGrid.Padding = [0 0 0 0];
statusLabel = uilabel(buttonGrid, 'Text', 'Preview ready');
statusLabel.Layout.Column = 1;
previewButton = uibutton(buttonGrid, 'Text', 'Refresh', 'ButtonPushedFcn', @refreshButtonPushed);
previewButton.Layout.Column = 2;
applyButton = uibutton(buttonGrid, 'Text', 'Apply filter', 'ButtonPushedFcn', @applyButtonPushed);
applyButton.Layout.Column = 3;
cancelButton = uibutton(buttonGrid, 'Text', 'No Filtering', 'ButtonPushedFcn', @cancelButtonPushed);
cancelButton.Layout.Column = 4;

dialog = struct('Figure', figureHandle, 'ThresholdFields', thresholdFields, ...
    'RemoveOrphansCheckBox', removeOrphansCheckBox, 'Axes', axesHandles, ...
    'StatsTable', statsTable, 'SummaryTable', summaryTable, 'StatusLabel', statusLabel, ...
    'PreviewButton', previewButton, 'ApplyButton', applyButton, 'CancelButton', cancelButton, ...
    'SetThresholds', @setThresholds, 'Thresholds', @getThresholds, ...
    'SetRemoveOrphanAtoms', @setRemoveOrphanAtoms, 'RemoveOrphanAtoms', @getRemoveOrphanAtoms, ...
    'Preview', @previewFilter, 'Apply', @applyFilter, 'Cancel', @cancelFilter, ...
    'FilteredModel', @getFilteredModel, 'Summary', @getSummary, 'LastAction', @getLastAction);

refreshControls();

    function setThresholds(newThresholds)
        [testFilteredModel, testSummary] = spinachgui.filterInteractions(sourceModel, ...
            newThresholds, removeOrphanAtoms);
        currentThresholds = table2struct(testSummary.Thresholds);
        latestFilteredModel = testFilteredModel;
        latestSummary = testSummary;
        lastAction = "preview";
        refreshControls();
    end

    function thresholds = getThresholds()
        thresholds = currentThresholds;
    end

    function setRemoveOrphanAtoms(value)
        removeOrphanAtoms = normalizeLogicalScalar(value, 'RemoveOrphanAtoms');
        removeOrphansCheckBox.Value = removeOrphanAtoms;
        previewFilter();
    end

    function value = getRemoveOrphanAtoms()
        value = removeOrphanAtoms;
    end

    function [filteredModel, summary] = previewFilter()
        [filteredModel, summary] = spinachgui.filterInteractions(sourceModel, ...
            currentThresholds, removeOrphanAtoms);
        latestFilteredModel = filteredModel;
        latestSummary = summary;
        lastAction = "preview";
        refreshControls();
    end

    function [filteredModel, summary] = applyFilter()
        [filteredModel, summary] = previewFilter();
        lastAction = "apply";
        statusLabel.Text = statusText(summary, "Filter applied to returned copy");
        if ~isempty(applyFcn)
            applyFcn(dialog, filteredModel, summary);
        end
        if closeOnApply && isvalid(figureHandle)
            delete(figureHandle);
        end
    end

    function cancelFilter()
        lastAction = "cancel";
        statusLabel.Text = 'No filtering applied';
        if ~isempty(cancelFcn)
            cancelFcn(dialog);
        end
        if closeOnCancel && isvalid(figureHandle)
            delete(figureHandle);
        end
    end

    function filteredModel = getFilteredModel()
        filteredModel = latestFilteredModel;
    end

    function summary = getSummary()
        summary = latestSummary;
    end

    function action = getLastAction()
        action = lastAction;
    end

    function thresholdChanged(~, ~)
        try
            currentThresholds = thresholdsFromFields();
            previewFilter();
        catch err
            restoreThresholdFields();
            statusLabel.Text = "Invalid threshold: " + string(err.message);
        end
    end

    function removeOrphansChanged(source, ~)
        removeOrphanAtoms = source.Value;
        previewFilter();
    end

    function refreshButtonPushed(~, ~)
        previewFilter();
    end

    function applyButtonPushed(~, ~)
        applyFilter();
    end

    function cancelButtonPushed(~, ~)
        cancelFilter();
    end

    function thresholds = thresholdsFromFields()
        thresholds = struct('Jcoupling', thresholdFields.Jcoupling.Value, ...
            'HFC', thresholdFields.HFC.Value, 'Quadrupolar', thresholdFields.Quadrupolar.Value);
        [~, normalizedSummary] = spinachgui.filterInteractions(sourceModel, ...
            thresholds, removeOrphanAtoms);
        thresholds = table2struct(normalizedSummary.Thresholds);
    end

    function refreshControls()
        restoreThresholdFields();
        removeOrphansCheckBox.Value = removeOrphanAtoms;
        updateStatsTable();
        updateSummaryTable();
        updateHistograms();
        statusLabel.Text = statusText(latestSummary, "Preview");
    end

    function restoreThresholdFields()
        thresholdFields.Jcoupling.Value = currentThresholds.Jcoupling;
        thresholdFields.HFC.Value = currentThresholds.HFC;
        thresholdFields.Quadrupolar.Value = currentThresholds.Quadrupolar;
    end

    function updateStatsTable()
        stats = latestSummary.ThresholdStatistics;
        thresholds = [currentThresholds.Jcoupling; currentThresholds.HFC; currentThresholds.Quadrupolar];
        displayStats = table(stats.Kind, thresholds, stats.Count, stats.MinMeasure, ...
            stats.MaxMeasure, stats.MaxHistogramCount, 'VariableNames', ...
            {'Kind', 'Threshold', 'Count', 'MinMeasure', 'MaxMeasure', 'MaxHistogramCount'});
        statsTable.Data = displayStats;
        statsTable.ColumnName = {'Kind', 'Threshold', 'Count', 'Min', 'Max', 'Max bin'};
    end

    function updateSummaryTable()
        summaryTable.Data = latestSummary.InteractionCounts;
        summaryTable.ColumnName = {'Kind', 'Before', 'Removed', 'After'};
    end

    function updateHistograms()
        for kindIdx = 1:numel(filterNames)
            kind = filterNames(kindIdx);
            stats = latestSummary.ThresholdStatistics(latestSummary.ThresholdStatistics.Kind == kind, :);
            ax = axesHandles.(kind);
            cla(ax);
            if isempty(stats) || stats.Count == 0
                title(ax, 'No interactions');
                ax.XTick = [];
                ax.YTick = [];
                statLabels.(kind).Text = 'Count 0; no active threshold control';
                thresholdFields.(kind).Enable = 'off';
                thresholdFields.(kind).Limits = [0 Inf];
                continue
            end
            thresholdFields.(kind).Enable = 'on';
            upperLimit = max(double(stats.MaxMeasure) + 1.0e-5, thresholdValue(kind));
            thresholdFields.(kind).Limits = [0 upperLimit];
            histogram = double(stats.Histogram{1});
            barHandle = bar(ax, 1:20, histogram, 0.85, 'FaceColor', 'flat', ...
                'EdgeColor', [0.2 0.2 0.2]);
            colors = repmat([0.25 0.45 0.85], 20, 1);
            removedBins = numberOfRemovedBins(kind, stats);
            if removedBins > 0
                colors(1:removedBins, :) = repmat([0.85 0.35 0.25], removedBins, 1);
            end
            barHandle.CData = colors;
            thresholdX = thresholdBinPosition(kind, stats);
            hold(ax, 'on');
            yMax = max([1, histogram(:).']);
            plot(ax, [thresholdX thresholdX], [0 yMax], '--k', 'LineWidth', 1.0);
            hold(ax, 'off');
            xlim(ax, [0.5 20.5]);
            ylim(ax, [0 yMax * 1.12]);
            ax.XTick = [1 10 20];
            ax.YTickMode = 'auto';
            title(ax, sprintf('%s threshold %.6g', char(kind), thresholdValue(kind)));
            statLabels.(kind).Text = sprintf('Count %d; min %.6g; max %.6g; max bin %d', ...
                stats.Count, stats.MinMeasure, stats.MaxMeasure, stats.MaxHistogramCount);
        end
    end

    function count = numberOfRemovedBins(kind, stats)
        count = floor(20 * (thresholdValue(kind) - stats.MinMeasure) / ...
            (stats.MaxMeasure - stats.MinMeasure + 1.0e-5) + 1.0e-5);
        count = min(max(count, 0), 20);
    end

    function positionValue = thresholdBinPosition(kind, stats)
        fraction = (thresholdValue(kind) - stats.MinMeasure) / ...
            (stats.MaxMeasure - stats.MinMeasure + 1.0e-5);
        positionValue = 1 + 19 * min(max(fraction, 0), 1);
    end

    function value = thresholdValue(kind)
        switch string(kind)
            case "Jcoupling"
                value = currentThresholds.Jcoupling;
            case "HFC"
                value = currentThresholds.HFC;
            case "Quadrupolar"
                value = currentThresholds.Quadrupolar;
        end
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

function text = statusText(summary, prefix)
text = sprintf('%s: %d -> %d atoms, %d -> %d interactions; %d threshold removals, %d orphan atoms removed', ...
    prefix, summary.OriginalAtomCount, summary.FilteredAtomCount, ...
    summary.OriginalInteractionCount, summary.FilteredInteractionCount, ...
    numel(summary.RemovedInteractionIDsThreshold), numel(summary.RemovedAtomIDs));
end
