classdef App < handle
    %APP MATLAB R2026a uifigure shell for the SpinachGUI rewrite.

    properties
        Model spinachgui.Model = spinachgui.Model()
        Figure matlab.ui.Figure
        TabGroup matlab.ui.container.TabGroup
        HomeTab matlab.ui.container.Tab
        VisualizationTab matlab.ui.container.Tab
        Axes matlab.ui.control.UIAxes
        AtomsTable matlab.ui.control.Table
        InteractionsTable matlab.ui.control.Table
        VisualizationInteractionsTable matlab.ui.control.Table
        StatusLabel matlab.ui.control.Label
        FileLabel matlab.ui.control.Label
        VisibilityControls struct = struct()
        CurrentView double = [-37.5 30]
        SavePath string = ""
    end

    methods
        function app = App(filename)
            app.buildUI();
            if nargin >= 1 && strlength(string(filename)) > 0
                app.openFile(filename);
            else
                app.refresh();
            end
        end

        function openFile(app, filename)
            if ~app.confirmDiscardChanges('open another file')
                return
            end
            app.Model = spinachgui.importFile(filename);
            [~,~,ext] = fileparts(filename);
            if ismember(lower(ext), {'.sxml', '.xml'})
                app.SavePath = string(filename);
            else
                app.SavePath = "";
            end
            app.refresh();
        end

        function info = exportVisualization(app, filename, varargin)
            info = spinachgui.exportVisualization(app.Axes, filename, varargin{:});
            if ~isempty(app.StatusLabel) && isvalid(app.StatusLabel)
                app.StatusLabel.Text = "Exported " + string(info.Filename);
            end
        end

        function exportModel(app, filename, kind, options)
            if nargin < 4 || isempty(options)
                options = struct();
            end

            switch string(kind)
                case "SpinXML"
                    spinachgui.writeSpinXML(app.Model, filename);
                    app.Model.Dirty = false;
                    app.Model.SourceFile = string(filename);
                    app.SavePath = string(filename);
                case "Spinach"
                    spinachgui.writeSpinach(app.Model, filename);
                case "EasySpin"
                    spinachgui.writeEasySpin(app.Model, filename, options);
                case "SIMPSON"
                    spinachgui.writeSimpson(app.Model, filename, options);
                case "SpinEvolution"
                    spinachgui.writeSpinEvolution(app.Model, filename, options);
                otherwise
                    error('spinachgui:UnsupportedExportKind', ...
                        'Unsupported export kind "%s".', kind);
            end

            if ~isempty(app.StatusLabel) && isvalid(app.StatusLabel)
                app.StatusLabel.Text = "Exported " + string(filename);
            end
        end
    end

    methods (Access = private)
        function buildUI(app)
            app.Figure = uifigure('Name', 'SpinachGUI', 'Position', [100 100 1200 760]);
            app.Figure.CloseRequestFcn = @(~,~) app.closeApp();
            app.TabGroup = uitabgroup(app.Figure, 'Position', [1 1 1200 760]);
            app.HomeTab = uitab(app.TabGroup, 'Title', 'Home');
            app.VisualizationTab = uitab(app.TabGroup, 'Title', 'Visualization');
            app.buildHomeTab();
            app.buildVisualizationTab();
        end

        function buildHomeTab(app)
            root = uigridlayout(app.HomeTab, [2 3]);
            root.ColumnWidth = {190, '1x', 420};
            root.RowHeight = {'1x', 215};
            root.Padding = [8 8 8 8];
            root.RowSpacing = 8;
            root.ColumnSpacing = 8;

            controls = uigridlayout(root, [5 1]);
            controls.Layout.Row = [1 2];
            controls.Layout.Column = 1;
            controls.RowHeight = {205, 170, 150, 120, '1x'};

            app.makeFilePanel(controls);
            app.makeExportPanel(controls);
            app.makeViewPanel(controls);
            app.makePlanePanel(controls);
            app.makeStatusPanel(controls);

            app.Axes = uiaxes(root);
            app.Axes.Layout.Row = 1;
            app.Axes.Layout.Column = 2;
            title(app.Axes, '3D view');
            xlabel(app.Axes, 'X'); ylabel(app.Axes, 'Y'); zlabel(app.Axes, 'Z');
            grid(app.Axes, 'on');
            view(app.Axes, 3);

            right = uigridlayout(root, [2 1]);
            right.Layout.Row = 1;
            right.Layout.Column = 3;
            right.RowHeight = {24, '1x'};
            uilabel(right, 'Text', 'Atoms', 'FontWeight', 'bold');
            app.AtomsTable = uitable(right);
            app.AtomsTable.Layout.Row = 2;
            app.AtomsTable.Layout.Column = 1;

            bottom = uigridlayout(root, [2 1]);
            bottom.Layout.Row = 2;
            bottom.Layout.Column = [2 3];
            bottom.RowHeight = {24, '1x'};
            uilabel(bottom, 'Text', 'Interactions', 'FontWeight', 'bold');
            app.InteractionsTable = uitable(bottom);
            app.InteractionsTable.Layout.Row = 2;
        end

        function makeFilePanel(app, parent)
            panel = uipanel(parent, 'Title', 'File');
            grid = uigridlayout(panel, [6 2]);
            grid.RowHeight = repmat({28}, 1, 6);
            grid.ColumnWidth = {'1x', '1x'};
            uibutton(grid, 'Text', 'New', 'ButtonPushedFcn', @(~,~) app.newModel());
            uibutton(grid, 'Text', 'Open', 'ButtonPushedFcn', @(~,~) app.openDialog());
            uibutton(grid, 'Text', 'Save', 'ButtonPushedFcn', @(~,~) app.saveCurrent());
            uibutton(grid, 'Text', 'Save As', 'ButtonPushedFcn', @(~,~) app.saveDialog());
            uibutton(grid, 'Text', 'Import', 'ButtonPushedFcn', @(~,~) app.openDialog());
            uibutton(grid, 'Text', 'Filter...', 'ButtonPushedFcn', @(~,~) app.showFilterDialog());
            uibutton(grid, 'Text', 'Print', 'ButtonPushedFcn', @(~,~) app.printVisualizationDialog());
            uibutton(grid, 'Text', 'About', 'ButtonPushedFcn', @(~,~) app.aboutDialog());
            uibutton(grid, 'Text', 'Exit', 'ButtonPushedFcn', @(~,~) app.closeApp());
            app.FileLabel = uilabel(grid, 'Text', 'Imported File: (None)');
            app.FileLabel.Layout.Row = 6;
            app.FileLabel.Layout.Column = [1 2];
        end

        function makeExportPanel(app, parent)
            panel = uipanel(parent, 'Title', 'Export');
            grid = uigridlayout(panel, [6 1]);
            grid.RowHeight = repmat({23}, 1, 6);
            grid.Padding = [4 4 4 4];
            grid.RowSpacing = 4;
            uibutton(grid, 'Text', 'SpinXML', 'ButtonPushedFcn', @(~,~) app.exportDialog('SpinXML'));
            uibutton(grid, 'Text', 'Spinach', 'ButtonPushedFcn', @(~,~) app.exportDialog('Spinach'));
            uibutton(grid, 'Text', 'Bitmap', 'ButtonPushedFcn', @(~,~) app.exportDialog('Bitmap'));
            uibutton(grid, 'Text', 'EasySpin', 'ButtonPushedFcn', @(~,~) app.exportDialog('EasySpin'));
            uibutton(grid, 'Text', 'SIMPSON', 'ButtonPushedFcn', @(~,~) app.exportDialog('SIMPSON'));
            uibutton(grid, 'Text', 'SpinEvolution', 'ButtonPushedFcn', @(~,~) app.exportDialog('SpinEvolution'));
        end

        function makeViewPanel(app, parent)
            panel = uipanel(parent, 'Title', '3D View Properties');
            grid = uigridlayout(panel, [5 1]);
            grid.RowHeight = repmat({24}, 1, 5);
            app.VisibilityControls.AtomIDs = uicheckbox(grid, 'Text', 'Atom IDs', ...
                'ValueChangedFcn', @(~,~) app.refresh());
            app.VisibilityControls.Axes = uicheckbox(grid, 'Text', 'Axes', 'Value', true, ...
                'ValueChangedFcn', @(~,~) app.refresh());
            uicheckbox(grid, 'Text', 'Fullscreen', 'ValueChangedFcn', @(src,~) app.setFullscreen(src.Value));
            app.VisibilityControls.SelectedAtomInteractions = uicheckbox(grid, ...
                'Text', 'Show Interactions in selected atoms', 'Enable', 'off', ...
                'Tooltip', 'Selected-atom interaction overlay is not yet ported.', ...
                'ValueChangedFcn', @(~,~) app.refresh());
            uibutton(grid, 'Text', 'Isotopes', 'ButtonPushedFcn', @(~,~) app.showIsotopes());
        end

        function makePlanePanel(app, parent)
            panel = uipanel(parent, 'Title', 'View Planes');
            grid = uigridlayout(panel, [2 3]);
            labels = {'XY','XZ','YZ','YX','ZX','ZY'};
            for k = 1:numel(labels)
                uibutton(grid, 'Text', labels{k}, 'ButtonPushedFcn', @(~,~) app.setViewPlane(labels{k}));
            end
        end

        function makeStatusPanel(app, parent)
            panel = uipanel(parent, 'Title', 'Status');
            grid = uigridlayout(panel, [1 1]);
            app.StatusLabel = uilabel(grid, 'Text', 'SpinachGUI');
        end

        function buildVisualizationTab(app)
            root = uigridlayout(app.VisualizationTab, [1 2]);
            root.ColumnWidth = {360, '1x'};
            tensorPanel = uipanel(root, 'Title', 'Tensor');
            tensorGrid = uigridlayout(tensorPanel, [17 2]);
            tensorGrid.RowHeight = repmat({24}, 1, 17);
            names = {'BOND  < 1.60 Ang', 'CHEMICAL SHIFT', 'HYPERFINE COUPLING', ...
                'J-COUPLING  > 0.50 Hz', 'G-TENSOR', 'CHI-TENSOR', ...
                'QUADRUPOLAR COUPLING', 'EXCHANGE COUPL. > 0.50 MHz', 'ZERO-FIELD SPLITTING'};
            for k = 1:numel(names)
                uicheckbox(tensorGrid, 'Text', names{k}, 'Value', true, 'Enable', 'off', ...
                    'Tooltip', 'Tensor visibility filters are not yet ported.', ...
                    'ValueChangedFcn', @(~,~) app.refresh());
                uislider(tensorGrid, 'Limits', [0 1], 'Value', 0.5, 'Enable', 'off', ...
                    'Tooltip', 'Tensor visibility thresholds are not yet ported.', ...
                    'ValueChangedFcn', @(~,~) app.refresh());
            end
            uicheckbox(tensorGrid, 'Text', 'Interaction Tensor Ellipsoids', 'Enable', 'off', ...
                'Tooltip', 'Tensor ellipsoid rendering is not yet ported.', 'ValueChangedFcn', @(~,~) app.refresh());
            uicheckbox(tensorGrid, 'Text', 'Interaction Tensor Axes', 'Enable', 'off', ...
                'Tooltip', 'Tensor-axis rendering is not yet ported.', 'ValueChangedFcn', @(~,~) app.refresh());
            uicheckbox(tensorGrid, 'Text', 'NMR', 'Value', true, 'Enable', 'off', ...
                'Tooltip', 'NMR tensor filtering is not yet ported.', 'ValueChangedFcn', @(~,~) app.refresh());
            viewLabel = uilabel(tensorGrid, 'Text', 'Selected interaction actions', 'FontWeight', 'bold');
            viewLabel.Layout.Row = 13;
            viewLabel.Layout.Column = [1 2];
            orientationButton = uibutton(tensorGrid, 'Text', 'Orientation export...', ...
                'ButtonPushedFcn', @(~,~) app.showSelectedOrientation());
            orientationButton.Layout.Row = 14;
            orientationButton.Layout.Column = [1 2];
            referenceFrameButton = uibutton(tensorGrid, 'Text', 'Reference frame...', ...
                'ButtonPushedFcn', @(~,~) app.showSelectedReferenceFrame());
            referenceFrameButton.Layout.Row = 15;
            referenceFrameButton.Layout.Column = [1 2];
            removeAnisotropyButton = uibutton(tensorGrid, 'Text', 'Remove anisotropy', ...
                'ButtonPushedFcn', @(~,~) app.removeSelectedAnisotropy());
            removeAnisotropyButton.Layout.Row = 16;
            removeAnisotropyButton.Layout.Column = [1 2];
            alignLabButton = uibutton(tensorGrid, 'Text', 'Align lab frame', ...
                'ButtonPushedFcn', @(~,~) app.alignLabFrameToSelectedInteraction());
            alignLabButton.Layout.Row = 17;
            alignLabButton.Layout.Column = [1 2];

            app.VisualizationInteractionsTable = uitable(root);
        end

        function refresh(app)
            if isempty(app.AtomsTable) || ~isvalid(app.AtomsTable)
                return
            end
            app.AtomsTable.Data = app.Model.Atoms;
            interactionData = app.Model.positiveInteractions();
            interactionData = interactionData(:, {'ID','Kind','A','B','Label','Unit','ReferenceFrameID','Reference'});
            if ~isempty(app.InteractionsTable) && isvalid(app.InteractionsTable)
                app.InteractionsTable.Data = interactionData;
            end
            if ~isempty(app.VisualizationInteractionsTable) && isvalid(app.VisualizationInteractionsTable)
                app.VisualizationInteractionsTable.Data = interactionData;
            end
            if strlength(app.Model.SourceFile) == 0
                app.FileLabel.Text = 'Imported File: (None)';
            else
                app.FileLabel.Text = "Imported File: " + app.Model.SourceFile;
            end
            app.renderModel();
            app.StatusLabel.Text = sprintf('SpinachGUI: %d atoms, %d interactions', height(app.Model.Atoms), height(app.Model.Interactions));
        end

        function renderModel(app)
            cla(app.Axes);
            if isempty(app.Model.Atoms)
                title(app.Axes, '3D view');
                app.applyAxesVisibility();
                return
            end
            atoms = app.Model.Atoms;
            colors = [atoms.Red atoms.Green atoms.Blue];
            scatter3(app.Axes, atoms.X, atoms.Y, atoms.Z, max(24, atoms.Radius), colors, 'filled');
            hold(app.Axes, 'on');
            if app.controlValue('AtomIDs', false)
                for atomIdx = 1:height(atoms)
                    text(app.Axes, atoms.X(atomIdx), atoms.Y(atomIdx), atoms.Z(atomIdx), ...
                        sprintf(' %d', atoms.ID(atomIdx)), 'FontSize', 8, ...
                        'Color', [0.1 0.1 0.1], 'Interpreter', 'none');
                end
            end
            pairs = app.Model.bondPairs(1.60);
            for k = 1:size(pairs, 1)
                a = pairs(k, 1); b = pairs(k, 2);
                plot3(app.Axes, [atoms.X(a) atoms.X(b)], [atoms.Y(a) atoms.Y(b)], [atoms.Z(a) atoms.Z(b)], '-', 'Color', [0.35 0.35 0.35]);
            end
            hold(app.Axes, 'off');
            axis(app.Axes, 'equal');
            grid(app.Axes, 'on');
            view(app.Axes, app.CurrentView(1), app.CurrentView(2));
            title(app.Axes, '3D view');
            app.applyAxesVisibility();
        end

        function openDialog(app)
            [file, path] = uigetfile({'*.sxml;*.xml;*.xyz;*.mol;*.log;*.out;*.magres;*.coo', ...
                'Supported files (*.sxml, *.xml, *.xyz, *.mol, *.log, *.out, *.magres, *.coo)'; ...
                '*.*', 'All files'}, 'Open or import spin system');
            if isequal(file, 0), return, end
            app.openFile(fullfile(path, file));
        end

        function saveDialog(app)
            [file, path] = uiputfile({'*.sxml', 'SpinXML (*.sxml)'}, 'Save SpinXML');
            if isequal(file, 0), return, end
            app.exportModel(fullfile(path, file), 'SpinXML');
            app.StatusLabel.Text = "Saved " + string(fullfile(path, file));
        end

        function saveCurrent(app)
            if strlength(app.SavePath) == 0
                app.saveDialog();
                return
            end
            app.exportModel(app.SavePath, 'SpinXML');
            app.StatusLabel.Text = "Saved " + app.SavePath;
        end

        function exportDialog(app, kind)
            switch kind
                case 'SpinXML'
                    app.saveDialog();
                case 'Spinach'
                    [file, path] = uiputfile({'*.m', 'MATLAB (*.m)'}, 'Export Spinach MATLAB file');
                    if isequal(file, 0), return, end
                    app.exportModel(fullfile(path, file), 'Spinach');
                case 'EasySpin'
                    [file, path] = uiputfile({'*.m', 'MATLAB (*.m)'}, ...
                        'Export EasySpin MATLAB file', 'easyspin_system.m');
                    if isequal(file, 0), return, end
                    app.exportModel(fullfile(path, file), 'EasySpin');
                case 'SIMPSON'
                    [file, path] = uiputfile({'*.in', 'SIMPSON input (*.in)'}, ...
                        'Export SIMPSON input file', 'simpson_system.in');
                    if isequal(file, 0), return, end
                    app.exportModel(fullfile(path, file), 'SIMPSON');
                case 'SpinEvolution'
                    [file, path] = uiputfile({'*.in', 'SpinEvolution input (*.in)'}, ...
                        'Export SpinEvolution input file', 'spinevolution_system.in');
                    if isequal(file, 0), return, end
                    app.exportModel(fullfile(path, file), 'SpinEvolution');
                case 'Bitmap'
                    [file, path] = uiputfile({'*.bmp', 'Bitmap (*.bmp)'; '*.png', 'PNG (*.png)'; ...
                        '*.tif;*.tiff', 'TIFF (*.tif, *.tiff)'; '*.jpg;*.jpeg', 'JPEG (*.jpg, *.jpeg)'}, ...
                        'Export bitmap image', 'spinachgui_view.bmp');
                    if isequal(file, 0), return, end
                    app.exportVisualization(fullfile(path, file), 'Resolution', 300, 'ContentType', 'image');
            end
        end

        function printVisualizationDialog(app)
            [file, path] = uiputfile({'*.pdf', 'PDF (*.pdf)'; '*.eps', 'EPS (*.eps)'}, ...
                'Print visualization to file', 'spinachgui_view.pdf');
            if isequal(file, 0), return, end
            app.exportVisualization(fullfile(path, file), 'ContentType', 'image');
        end

        function newModel(app)
            if ~app.confirmDiscardChanges('start a new model')
                return
            end
            app.Model = spinachgui.Model();
            app.SavePath = "";
            app.refresh();
        end

        function showIsotopes(~)
            spinachgui.isotopeBrowser();
        end

        function showFilterDialog(app)
            spinachgui.filterDialog(app.Model, 'ApplyFcn', @applyFilteredModel, ...
                'CloseOnApply', true, 'CloseOnCancel', true);

            function applyFilteredModel(~, filteredModel, summary)
                app.Model = filteredModel;
                app.refresh();
                app.StatusLabel.Text = sprintf(['Filtered model: %d -> %d atoms, ' ...
                    '%d -> %d interactions'], summary.OriginalAtomCount, ...
                    summary.FilteredAtomCount, summary.OriginalInteractionCount, ...
                    summary.FilteredInteractionCount);
            end
        end

        function showSelectedOrientation(app)
            [interactionID, idx] = app.selectedPositiveInteraction();
            if isempty(idx)
                return
            end
            titleText = sprintf('Interaction %d tensor/orientation editor', interactionID);
            frameToRoot = app.Model.referenceFrameToRootMatrix(app.Model.Interactions.ReferenceFrameID(idx));
            localDcm = frameToRoot \ app.Model.Interactions.DCM{idx};
            spinachgui.orientationEditor(localDcm, 'Title', titleText, ...
                'Editable', true, 'InteractionMatrix', app.Model.Interactions.Matrix{idx}, ...
                'Eigenvalues', app.Model.Interactions.Eigenvalues{idx}, ...
                'ValueChangedFcn', @applyInteractionOrientation);

            function applyInteractionOrientation(editor, ~)
                currentIdx = find(app.Model.Interactions.ID == interactionID, 1);
                if isempty(currentIdx)
                    return
                end
                currentFrameToRoot = app.Model.referenceFrameToRootMatrix(app.Model.Interactions.ReferenceFrameID(currentIdx));
                rootDcm = currentFrameToRoot * editor.CurrentDcm();
                app.Model.setInteractionEigenSystem(interactionID, editor.CurrentEigenvalues(), rootDcm);
                app.refresh();
                app.StatusLabel.Text = sprintf('Updated tensor/orientation for interaction %d', interactionID);
            end
        end

        function showSelectedReferenceFrame(app)
            [~, idx] = app.selectedPositiveInteraction();
            if isempty(idx)
                return
            end
            frameID = app.Model.Interactions.ReferenceFrameID(idx);
            frameIdx = find(app.Model.ReferenceFrames.ID == frameID, 1);
            if isempty(frameIdx)
                uialert(app.Figure, 'The selected interaction references a missing frame.', ...
                    'Reference frame unavailable', 'Icon', 'warning');
                return
            end
            titleText = sprintf('Reference frame %d orientation editor', frameID);
            spinachgui.orientationEditor(app.Model.ReferenceFrames.Matrix{frameIdx}, 'Title', titleText, ...
                'Editable', true, 'ValueChangedFcn', @applyReferenceFrameOrientation);

            function applyReferenceFrameOrientation(editor, ~)
                app.Model.setReferenceFrameMatrix(frameID, editor.CurrentDcm());
                app.refresh();
                app.StatusLabel.Text = sprintf('Updated reference frame %d', frameID);
            end
        end

        function removeSelectedAnisotropy(app)
            [interactionID, idx] = app.selectedPositiveInteraction();
            if isempty(idx)
                return
            end
            app.Model.removeInteractionAnisotropy(interactionID);
            app.refresh();
            app.StatusLabel.Text = sprintf('Removed anisotropy from interaction %d', interactionID);
        end

        function alignLabFrameToSelectedInteraction(app)
            [interactionID, idx] = app.selectedPositiveInteraction();
            if isempty(idx)
                return
            end
            app.Model.alignLabFrameToInteraction(interactionID);
            app.refresh();
            app.StatusLabel.Text = sprintf('Aligned lab frame to interaction %d', interactionID);
        end

        function aboutDialog(app)
            uialert(app.Figure, sprintf('SpinachGUI MATLAB rewrite\nOriginal WinForms GUI by the Spinach project.'), 'About SpinachGUI');
        end

        function [interactionID, idx] = selectedPositiveInteraction(app)
            interactionID = [];
            idx = [];
            if isempty(app.VisualizationInteractionsTable) || ~isvalid(app.VisualizationInteractionsTable)
                return
            end
            data = app.VisualizationInteractionsTable.Data;
            if isempty(data) || height(data) == 0
                uialert(app.Figure, 'No positive interactions are available.', ...
                    'No interaction selected', 'Icon', 'warning');
                return
            end
            selection = [];
            if isprop(app.VisualizationInteractionsTable, 'Selection')
                selection = app.VisualizationInteractionsTable.Selection;
            end
            if isempty(selection)
                uialert(app.Figure, 'Please select one positive interaction first.', ...
                    'No interaction selected', 'Icon', 'warning');
                return
            end
            selectedRows = unique(selection(:, 1));
            if numel(selectedRows) ~= 1
                uialert(app.Figure, 'Please select exactly one positive interaction.', ...
                    'Multiple interactions selected', 'Icon', 'warning');
                return
            end
            row = selectedRows(1);
            row = max(1, min(row, height(data)));
            interactionID = data.ID(row);
            idx = find(app.Model.Interactions.ID == interactionID, 1);
            if isempty(idx)
                uialert(app.Figure, 'The selected interaction is no longer present in the model.', ...
                    'Interaction unavailable', 'Icon', 'warning');
            end
        end

        function setFullscreen(app, value)
            if value
                app.Figure.WindowState = 'fullscreen';
            else
                app.Figure.WindowState = 'normal';
            end
        end

        function setViewPlane(app, plane)
            switch string(plane)
                case "XY"
                    app.CurrentView = [0 90];
                case "YX"
                    app.CurrentView = [180 -90];
                case "XZ"
                    app.CurrentView = [0 0];
                case "ZX"
                    app.CurrentView = [180 0];
                case "YZ"
                    app.CurrentView = [90 0];
                case "ZY"
                    app.CurrentView = [-90 0];
                otherwise
                    error('spinachgui:InvalidViewPlane', 'Unknown view plane "%s".', plane);
            end
            app.renderModel();
        end

        function applyAxesVisibility(app)
            if app.controlValue('Axes', true)
                axis(app.Axes, 'on');
            else
                axis(app.Axes, 'off');
            end
        end

        function value = controlValue(app, name, defaultValue)
            value = defaultValue;
            if isfield(app.VisibilityControls, name)
                control = app.VisibilityControls.(name);
                if ~isempty(control) && isvalid(control)
                    value = logical(control.Value);
                end
            end
        end

        function closeApp(app)
            if app.confirmDiscardChanges('exit') && ~isempty(app.Figure) && isvalid(app.Figure)
                delete(app.Figure);
            end
        end

        function confirmed = confirmDiscardChanges(app, actionText)
            confirmed = true;
            if isempty(app.Model) || ~app.Model.Dirty
                return
            end
            if isempty(app.Figure) || ~isvalid(app.Figure)
                return
            end
            choice = uiconfirm(app.Figure, ...
                sprintf('The current model has unsaved changes. Discard them and %s?', actionText), ...
                'Unsaved changes', 'Options', {'Discard changes', 'Cancel'}, ...
                'DefaultOption', 'Cancel', 'CancelOption', 'Cancel', 'Icon', 'warning');
            confirmed = strcmp(choice, 'Discard changes');
        end
    end
end
