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
            app.Model = spinachgui.importFile(filename);
            app.refresh();
        end
    end

    methods (Access = private)
        function buildUI(app)
            app.Figure = uifigure('Name', 'SpinachGUI', 'Position', [100 100 1200 760]);
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
            controls.RowHeight = {170, 170, 150, 120, '1x'};

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
            grid = uigridlayout(panel, [5 2]);
            grid.RowHeight = repmat({28}, 1, 5);
            grid.ColumnWidth = {'1x', '1x'};
            uibutton(grid, 'Text', 'New', 'ButtonPushedFcn', @(~,~) app.newModel());
            uibutton(grid, 'Text', 'Open', 'ButtonPushedFcn', @(~,~) app.openDialog());
            uibutton(grid, 'Text', 'Save', 'ButtonPushedFcn', @(~,~) app.saveDialog());
            uibutton(grid, 'Text', 'Save As', 'ButtonPushedFcn', @(~,~) app.saveDialog());
            uibutton(grid, 'Text', 'Import', 'ButtonPushedFcn', @(~,~) app.openDialog());
            uibutton(grid, 'Text', 'Print', 'ButtonPushedFcn', @(~,~) print(app.Figure));
            uibutton(grid, 'Text', 'About', 'ButtonPushedFcn', @(~,~) app.aboutDialog());
            uibutton(grid, 'Text', 'Exit', 'ButtonPushedFcn', @(~,~) delete(app.Figure));
            app.FileLabel = uilabel(grid, 'Text', 'Imported File: (None)');
            app.FileLabel.Layout.Column = [1 2];
        end

        function makeExportPanel(app, parent)
            panel = uipanel(parent, 'Title', 'Export');
            grid = uigridlayout(panel, [5 1]);
            grid.RowHeight = repmat({28}, 1, 5);
            uibutton(grid, 'Text', 'SpinXML', 'ButtonPushedFcn', @(~,~) app.exportDialog('SpinXML'));
            uibutton(grid, 'Text', 'Spinach', 'ButtonPushedFcn', @(~,~) app.exportDialog('Spinach'));
            uibutton(grid, 'Text', 'EasySpin', 'ButtonPushedFcn', @(~,~) app.notYet('EasySpin export'));
            uibutton(grid, 'Text', 'SIMPSON', 'ButtonPushedFcn', @(~,~) app.notYet('SIMPSON export'));
            uibutton(grid, 'Text', 'SpinEvolution', 'ButtonPushedFcn', @(~,~) app.notYet('SpinEvolution export'));
        end

        function makeViewPanel(app, parent)
            panel = uipanel(parent, 'Title', '3D View Properties');
            grid = uigridlayout(panel, [5 1]);
            grid.RowHeight = repmat({24}, 1, 5);
            uicheckbox(grid, 'Text', 'Atom IDs', 'ValueChangedFcn', @(~,~) app.refresh());
            uicheckbox(grid, 'Text', 'Axes', 'Value', true, 'ValueChangedFcn', @(~,~) app.refresh());
            uicheckbox(grid, 'Text', 'Fullscreen', 'ValueChangedFcn', @(src,~) app.setFullscreen(src.Value));
            uicheckbox(grid, 'Text', 'Show Interactions in selected atoms', 'ValueChangedFcn', @(~,~) app.refresh());
            uibutton(grid, 'Text', 'Isotopes', 'ButtonPushedFcn', @(~,~) app.showIsotopes());
        end

        function makePlanePanel(~, parent)
            panel = uipanel(parent, 'Title', 'View Planes');
            grid = uigridlayout(panel, [2 3]);
            labels = {'XY','XZ','YZ','YX','ZX','ZY'};
            for k = 1:numel(labels)
                uibutton(grid, 'Text', labels{k});
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
            tensorGrid = uigridlayout(tensorPanel, [12 2]);
            tensorGrid.RowHeight = repmat({24}, 1, 12);
            names = {'BOND  < 1.60 Ang', 'CHEMICAL SHIFT', 'HYPERFINE COUPLING', ...
                'J-COUPLING  > 0.50 Hz', 'G-TENSOR', 'CHI-TENSOR', ...
                'QUADRUPOLAR COUPLING', 'EXCHANGE COUPL. > 0.50 MHz', 'ZERO-FIELD SPLITTING'};
            for k = 1:numel(names)
                uicheckbox(tensorGrid, 'Text', names{k}, 'Value', true, 'ValueChangedFcn', @(~,~) app.refresh());
                uislider(tensorGrid, 'Limits', [0 1], 'Value', 0.5, 'ValueChangedFcn', @(~,~) app.refresh());
            end
            uicheckbox(tensorGrid, 'Text', 'Interaction Tensor Ellipsoids', 'ValueChangedFcn', @(~,~) app.refresh());
            uicheckbox(tensorGrid, 'Text', 'Interaction Tensor Axes', 'ValueChangedFcn', @(~,~) app.refresh());
            uicheckbox(tensorGrid, 'Text', 'NMR', 'Value', true, 'ValueChangedFcn', @(~,~) app.refresh());
            uilabel(tensorGrid, 'Text', 'View');

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
                return
            end
            atoms = app.Model.Atoms;
            colors = [atoms.Red atoms.Green atoms.Blue];
            scatter3(app.Axes, atoms.X, atoms.Y, atoms.Z, max(24, atoms.Radius), colors, 'filled');
            hold(app.Axes, 'on');
            pairs = app.Model.bondPairs(1.60);
            for k = 1:size(pairs, 1)
                a = pairs(k, 1); b = pairs(k, 2);
                plot3(app.Axes, [atoms.X(a) atoms.X(b)], [atoms.Y(a) atoms.Y(b)], [atoms.Z(a) atoms.Z(b)], '-', 'Color', [0.35 0.35 0.35]);
            end
            hold(app.Axes, 'off');
            axis(app.Axes, 'equal');
            grid(app.Axes, 'on');
            view(app.Axes, 3);
            title(app.Axes, '3D view');
        end

        function openDialog(app)
            [file, path] = uigetfile({'*.sxml;*.xml;*.xyz;*.mol;*.log;*.out', 'Supported files (*.sxml, *.xml, *.xyz, *.mol, *.log, *.out)'; '*.*', 'All files'}, 'Open or import spin system');
            if isequal(file, 0), return, end
            app.openFile(fullfile(path, file));
        end

        function saveDialog(app)
            [file, path] = uiputfile({'*.sxml', 'SpinXML (*.sxml)'}, 'Save SpinXML');
            if isequal(file, 0), return, end
            spinachgui.writeSpinXML(app.Model, fullfile(path, file));
            app.Model.Dirty = false;
            app.StatusLabel.Text = "Saved " + string(fullfile(path, file));
        end

        function exportDialog(app, kind)
            switch kind
                case 'SpinXML'
                    app.saveDialog();
                case 'Spinach'
                    [file, path] = uiputfile({'*.m', 'MATLAB (*.m)'}, 'Export Spinach MATLAB file');
                    if isequal(file, 0), return, end
                    spinachgui.writeSpinach(app.Model, fullfile(path, file));
                    app.StatusLabel.Text = "Exported " + string(fullfile(path, file));
            end
        end

        function newModel(app)
            app.Model = spinachgui.Model();
            app.refresh();
        end

        function showIsotopes(~)
            f = uifigure('Name', 'Isotopes', 'Position', [120 120 850 600]);
            uitable(f, 'Data', spinachgui.isotopeTable(), 'Position', [1 1 848 598]);
        end

        function aboutDialog(app)
            uialert(app.Figure, sprintf('SpinachGUI MATLAB rewrite\nOriginal WinForms GUI by the Spinach project.'), 'About SpinachGUI');
        end

        function notYet(app, feature)
            uialert(app.Figure, feature + " is queued for a later parity slice.", 'Parity slice pending', 'Icon', 'warning');
        end

        function setFullscreen(app, value)
            if value
                app.Figure.WindowState = 'fullscreen';
            else
                app.Figure.WindowState = 'normal';
            end
        end
    end
end
