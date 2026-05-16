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
        TensorControls struct = struct()
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
            figureGrid = uigridlayout(app.Figure, [1 1]);
            figureGrid.Padding = [0 0 0 0];
            figureGrid.RowSpacing = 0;
            figureGrid.ColumnSpacing = 0;
            app.TabGroup = uitabgroup(figureGrid);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;
            app.HomeTab = uitab(app.TabGroup, 'Title', 'Home');
            app.VisualizationTab = uitab(app.TabGroup, 'Title', 'Visualization');
            app.buildHomeTab();
            app.buildVisualizationTab();
        end

        function buildHomeTab(app)
            root = uigridlayout(app.HomeTab, [2 3]);
            root.ColumnWidth = {190, '2x', '1x'};
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
            app.configureAtomsTable();

            bottom = uigridlayout(root, [2 1]);
            bottom.Layout.Row = 2;
            bottom.Layout.Column = [2 3];
            bottom.RowHeight = {24, '1x'};
            uilabel(bottom, 'Text', 'Interactions', 'FontWeight', 'bold');
            app.InteractionsTable = uitable(bottom);
            app.InteractionsTable.Layout.Row = 2;
            app.configureInteractionsTable(app.InteractionsTable);
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
            app.TensorControls = struct();
            configs = app.tensorVisualConfigs();
            for k = 1:numel(configs)
                key = char(configs(k).Key);
                checkbox = uicheckbox(tensorGrid, 'Text', configs(k).Label, 'Value', true, ...
                    'Tag', "TensorControl_" + key, ...
                    'Tooltip', 'Show or hide this interaction tensor ellipsoid class.', ...
                    'ValueChangedFcn', @(~,~) app.refresh());
                slider = uislider(tensorGrid, 'Limits', [-30 30], 'Value', 0, ...
                    'MajorTicks', -30:15:30, 'MinorTicks', -30:5:30, ...
                    'Tag', "TensorScale_" + key, ...
                    'Tooltip', 'Logarithmic tensor-size scale, matching the legacy GUI trackbars.', ...
                    'ValueChangedFcn', @(~,~) app.refresh());
                checkbox.Layout.Row = k;
                checkbox.Layout.Column = 1;
                slider.Layout.Row = k;
                slider.Layout.Column = 2;
                app.TensorControls.(key).Checkbox = checkbox;
                app.TensorControls.(key).Slider = slider;
            end
            app.TensorControls.Ellipsoids = uicheckbox(tensorGrid, ...
                'Text', 'Interaction Tensor Ellipsoids', 'Value', true, ...
                'Tag', 'TensorControl_Ellipsoids', ...
                'Tooltip', 'Draw translucent ellipsoid surfaces scaled by tensor eigenvalue moduli.', ...
                'ValueChangedFcn', @(~,~) app.refresh());
            app.TensorControls.Ellipsoids.Layout.Row = 7;
            app.TensorControls.Ellipsoids.Layout.Column = [1 2];
            app.TensorControls.Axes = uicheckbox(tensorGrid, ...
                'Text', 'Interaction Tensor Axes', 'Value', true, ...
                'Tag', 'TensorControl_Axes', ...
                'Tooltip', 'Draw principal axes; red denotes positive eigenvalues, blue negative.', ...
                'ValueChangedFcn', @(~,~) app.refresh());
            app.TensorControls.Axes.Layout.Row = 8;
            app.TensorControls.Axes.Layout.Column = [1 2];
            modeGrid = uigridlayout(tensorGrid, [1 3]);
            modeGrid.Padding = [0 0 0 0];
            modeGrid.ColumnSpacing = 4;
            modeGrid.Layout.Row = 9;
            modeGrid.Layout.Column = [1 2];
            uibutton(modeGrid, 'Text', 'All', 'ButtonPushedFcn', @(~,~) app.setTensorMode('All'));
            uibutton(modeGrid, 'Text', 'NMR', 'ButtonPushedFcn', @(~,~) app.setTensorMode('NMR'));
            uibutton(modeGrid, 'Text', 'EPR', 'ButtonPushedFcn', @(~,~) app.setTensorMode('EPR'));
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
            app.configureInteractionsTable(app.VisualizationInteractionsTable);
        end

        function refresh(app)
            if isempty(app.AtomsTable) || ~isvalid(app.AtomsTable)
                return
            end
            app.AtomsTable.Data = app.atomTableData();
            interactionData = app.Model.positiveInteractions();
            interactionData = app.interactionTableData(interactionData);
            if ~isempty(app.InteractionsTable) && isvalid(app.InteractionsTable)
                app.InteractionsTable.Data = interactionData;
            end
            if ~isempty(app.VisualizationInteractionsTable) && isvalid(app.VisualizationInteractionsTable)
                app.VisualizationInteractionsTable.Data = interactionData;
            end
            app.updateTensorControlEnableState();
            if strlength(app.Model.SourceFile) == 0
                app.FileLabel.Text = 'Imported File: (None)';
            else
                app.FileLabel.Text = "Imported File: " + app.Model.SourceFile;
            end
            app.renderModel();
            app.StatusLabel.Text = sprintf('SpinachGUI: %d atoms, %d interactions', height(app.Model.Atoms), height(app.Model.Interactions));
        end

        function configureAtomsTable(app)
            app.AtomsTable.ColumnName = {'ID','Label','Element','Mass Number','x(Angstrom)','y(Angstrom)','z(Angstrom)'};
            app.AtomsTable.ColumnEditable = true(1, 7);
            app.AtomsTable.ColumnFormat = {'numeric','char',cellstr(app.atomElementOptions()), ...
                'numeric','numeric','numeric','numeric'};
            app.AtomsTable.RowName = {};
            app.AtomsTable.CellEditCallback = @(~,event) app.atomsTableEdited(event);
        end

        function configureInteractionsTable(app, tableHandle)
            tableHandle.ColumnName = {'ID','Label','Atom ID','Inter. Type','Coupled Atom ID', ...
                'Unit','Ref. Frame ID','Reference','Magnitude Orientation'};
            tableHandle.ColumnEditable = [true true true true true true true true false];
            tableHandle.ColumnFormat = {'numeric','char','numeric',cellstr(app.interactionKindOptions()), ...
                'numeric',cellstr(app.unitOptions()),'numeric','char','char'};
            tableHandle.RowName = {};
            tableHandle.CellEditCallback = @(src,event) app.interactionsTableEdited(src, event);
            tableHandle.CellSelectionCallback = @(src,event) app.interactionsTableSelected(src, event);
        end

        function data = atomTableData(app)
            names = {'ID','Label','Element','Mass','X','Y','Z'};
            if isempty(app.Model.Atoms)
                data = cell(0, numel(names));
                return
            end
            data = app.stringCellsToChar(table2cell(app.Model.Atoms(:, names)));
        end

        function data = interactionTableData(app, interactions)
            names = {'ID','Label','A','Kind','B','Unit','ReferenceFrameID','Reference','Edit'};
            if isempty(interactions)
                data = cell(0, numel(names));
                return
            end
            data = [app.stringCellsToChar(table2cell(interactions(:, names(1:end-1)))), ...
                repmat({'Edit'}, height(interactions), 1)];
        end

        function data = stringCellsToChar(~, data)
            for idx = 1:numel(data)
                if isstring(data{idx})
                    data{idx} = char(data{idx});
                end
            end
        end

        function atomsTableEdited(app, event)
            if isempty(event.Indices)
                return
            end
            row = event.Indices(1);
            column = event.Indices(2);
            data = app.AtomsTable.Data;
            if row > size(data, 1)
                return
            end
            atomKeys = app.atomTableKeys();
            columnName = atomKeys(column);
            atomID = data{row, 1};
            if columnName == "ID"
                atomID = event.PreviousData;
            end
            try
                switch columnName
                    case "ID"
                        app.Model.setAtomID(event.PreviousData, event.NewData);
                    case "Label"
                        app.Model.setAtomLabel(atomID, event.NewData);
                    case "Element"
                        app.Model.setAtomIsotope(atomID, event.NewData, []);
                    case "Mass"
                        app.Model.setAtomIsotope(atomID, data{row, 3}, data{row, 4});
                    case {"X","Y","Z"}
                        app.Model.setAtomCoordinates(atomID, cell2mat(data(row, 5:7)));
                end
            catch err
                app.showEditError(err);
            end
            app.refresh();
        end

        function interactionsTableEdited(app, src, event)
            if isempty(event.Indices)
                return
            end
            row = event.Indices(1);
            column = event.Indices(2);
            data = src.Data;
            if row > size(data, 1)
                return
            end
            interactionKeys = app.interactionTableKeys();
            columnName = interactionKeys(column);
            interactionID = data{row, 1};
            if columnName == "ID"
                interactionID = event.PreviousData;
            end
            try
                switch columnName
                    case "ID"
                        app.Model.setInteractionID(event.PreviousData, event.NewData);
                    case "Label"
                        app.Model.setInteractionLabel(interactionID, event.NewData);
                    case "A"
                        app.Model.setInteractionAtomA(interactionID, event.NewData);
                    case "Kind"
                        app.Model.setInteractionKind(interactionID, event.NewData);
                    case "B"
                        app.Model.setInteractionAtomB(interactionID, event.NewData);
                    case "Unit"
                        app.Model.setInteractionUnit(interactionID, event.NewData);
                    case "ReferenceFrameID"
                        app.Model.setInteractionReferenceFrame(interactionID, event.NewData);
                    case "Reference"
                        app.Model.setInteractionReference(interactionID, event.NewData);
                end
            catch err
                app.showEditError(err);
            end
            app.refresh();
        end

        function interactionsTableSelected(app, src, event)
            if isempty(event.Indices) || isempty(src.Data)
                return
            end
            row = event.Indices(1);
            column = event.Indices(2);
            if row > size(src.Data, 1) || column ~= size(src.Data, 2)
                return
            end
            app.showInteractionEditor(src.Data{row, 1});
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
            app.renderTensorEllipsoids();
            hold(app.Axes, 'off');
            axis(app.Axes, 'equal');
            grid(app.Axes, 'on');
            view(app.Axes, app.CurrentView(1), app.CurrentView(2));
            title(app.Axes, '3D view');
            app.applyAxesVisibility();
        end

        function renderTensorEllipsoids(app)
            if isempty(app.TensorControls) || isempty(app.Model.Interactions) || isempty(app.Model.Atoms)
                return
            end

            drawSurfaces = app.tensorControlValue('Ellipsoids', true);
            drawAxes = app.tensorControlValue('Axes', true);
            if ~drawSurfaces && ~drawAxes
                return
            end

            atoms = app.Model.Atoms;
            coords = [atoms.X atoms.Y atoms.Z];
            nonElectronRows = find(atoms.Element ~= "e");
            baseLength = 1.6;
            pairs = app.Model.bondPairs(1.60);
            if ~isempty(pairs)
                distances = zeros(size(pairs, 1), 1);
                for pairIdx = 1:size(pairs, 1)
                    distances(pairIdx) = norm(coords(pairs(pairIdx, 1), :) - coords(pairs(pairIdx, 2), :));
                end
                distances = distances(distances > eps & isfinite(distances));
                if ~isempty(distances)
                    baseLength = min(distances);
                end
            elseif numel(nonElectronRows) > 1
                distances = [];
                for leftIdx = 1:numel(nonElectronRows)
                    for rightIdx = 1:leftIdx-1
                        distances(end+1) = norm(coords(nonElectronRows(leftIdx), :) - coords(nonElectronRows(rightIdx), :)); %#ok<AGROW>
                    end
                end
                distances = distances(distances > eps & isfinite(distances));
                if ~isempty(distances)
                    baseLength = min(distances);
                end
            else
                span = max(max(coords, [], 1) - min(coords, [], 1));
                if isfinite(span) && span > eps
                    baseLength = max(1.0, span / 4);
                end
            end

            configs = app.tensorVisualConfigs();
            [sphereX, sphereY, sphereZ] = sphere(24);
            spherePoints = [sphereX(:).'; sphereY(:).'; sphereZ(:).'];
            interactions = app.Model.Interactions;
            for configIdx = 1:numel(configs)
                config = configs(configIdx);
                key = char(config.Key);
                if ~app.tensorControlValue(key, true)
                    continue
                end
                rowMask = interactions.ID > 0 & ismember(interactions.Kind, config.Kinds);
                rows = find(rowMask);
                if isempty(rows)
                    continue
                end

                maxAbsEigenvalue = 0;
                for row = rows(:).'
                    eigenvalues = interactions.Eigenvalues{row};
                    if isnumeric(eigenvalues) && numel(eigenvalues) == 3 && all(isfinite(eigenvalues(:)))
                        maxAbsEigenvalue = max(maxAbsEigenvalue, max(abs(eigenvalues(:))));
                    end
                end
                if ~(isfinite(maxAbsEigenvalue) && maxAbsEigenvalue > eps)
                    continue
                end

                coordinateScale = config.BaseScale * baseLength * ...
                    10.^(app.tensorSliderValue(key) / 10) / maxAbsEigenvalue;
                for row = rows(:).'
                    eigenvalues = double(interactions.Eigenvalues{row}(:).');
                    dcm = interactions.DCM{row};
                    if numel(eigenvalues) ~= 3 || any(~isfinite(eigenvalues)) || ...
                            ~isnumeric(dcm) || ~isequal(size(dcm), [3 3]) || any(~isfinite(dcm(:)))
                        matrix = interactions.Matrix{row};
                        if ~isnumeric(matrix) || ~isequal(size(matrix), [3 3]) || any(~isfinite(matrix(:)))
                            continue
                        end
                        [dcm, values] = eig(spinachgui.symmetrizeTensor(matrix));
                        eigenvalues = diag(values).';
                    end
                    dcm = spinachgui.normalizeDcm(dcm);

                    atomID = interactions.A(row);
                    atomRow = find(atoms.ID == atomID, 1);
                    if isempty(atomRow)
                        atomID = interactions.B(row);
                        atomRow = find(atoms.ID == atomID, 1);
                    end
                    if isempty(atomRow)
                        continue
                    end
                    centre = coords(atomRow, :).';
                    radii = abs(eigenvalues(:)) * coordinateScale;
                    if any(~isfinite(radii)) || all(radii <= eps)
                        continue
                    end

                    scaledPoints = [spherePoints(1, :) * radii(1); ...
                                    spherePoints(2, :) * radii(2); ...
                                    spherePoints(3, :) * radii(3)];
                    plotPoints = dcm * scaledPoints + centre;
                    xPlot = reshape(plotPoints(1, :), size(sphereX));
                    yPlot = reshape(plotPoints(2, :), size(sphereY));
                    zPlot = reshape(plotPoints(3, :), size(sphereZ));

                    if drawSurfaces
                        surf(app.Axes, xPlot, yPlot, zPlot, ...
                            'FaceColor', config.Color, 'FaceAlpha', config.Alpha, ...
                            'EdgeColor', config.Color * 0.7, 'EdgeAlpha', 0.18, ...
                            'FaceLighting', 'gouraud', ...
                            'Tag', sprintf('TensorEllipsoid_%d', interactions.ID(row)));
                    end

                    if drawAxes
                        for axisIdx = 1:3
                            principalVector = dcm(:, axisIdx) * radii(axisIdx);
                            axisColour = [1 0 0];
                            if eigenvalues(axisIdx) <= 0
                                axisColour = [0 0 1];
                            end
                            plot3(app.Axes, ...
                                [centre(1) - principalVector(1), centre(1) + principalVector(1)], ...
                                [centre(2) - principalVector(2), centre(2) + principalVector(2)], ...
                                [centre(3) - principalVector(3), centre(3) + principalVector(3)], ...
                                '-', 'Color', axisColour, 'LineWidth', 1.2, ...
                                'Tag', sprintf('TensorAxis_%d_%d', interactions.ID(row), axisIdx));
                        end
                    end
                end
            end
        end

        function configs = tensorVisualConfigs(~)
            template = struct('Key', "", 'Label', "", 'Kinds', strings(1, 0), ...
                'Color', [0 0 0], 'Alpha', 0.5, 'BaseScale', 0.35, 'Mode', "");
            configs = repmat(template, 1, 6);

            configs(1).Key = "Shift";
            configs(1).Label = "CHEMICAL SHIFT / SHIELDING";
            configs(1).Kinds = ["Shift", "CShielding"];
            configs(1).Color = [0.0 0.0 0.9];
            configs(1).Alpha = 0.40;
            configs(1).BaseScale = 0.40;
            configs(1).Mode = "NMR";

            configs(2).Key = "HFC";
            configs(2).Label = "HYPERFINE COUPLING";
            configs(2).Kinds = "HFC";
            configs(2).Color = [1.0 0.5 0.25];
            configs(2).Alpha = 0.35;
            configs(2).BaseScale = 0.35;
            configs(2).Mode = "EPR";

            configs(3).Key = "Quadrupolar";
            configs(3).Label = "QUADRUPOLAR COUPLING";
            configs(3).Kinds = "Quadrupolar";
            configs(3).Color = [0.45 0.10 0.55];
            configs(3).Alpha = 0.35;
            configs(3).BaseScale = 0.35;
            configs(3).Mode = "NMR";

            configs(4).Key = "GTensor";
            configs(4).Label = "G-TENSOR";
            configs(4).Kinds = "GTensor";
            configs(4).Color = [1.0 0.0 0.0];
            configs(4).Alpha = 0.60;
            configs(4).BaseScale = 0.60;
            configs(4).Mode = "EPR";

            configs(5).Key = "ZFS";
            configs(5).Label = "ZERO-FIELD SPLITTING";
            configs(5).Kinds = "ZFS";
            configs(5).Color = [0.0 0.5 0.25];
            configs(5).Alpha = 0.60;
            configs(5).BaseScale = 0.60;
            configs(5).Mode = "EPR";

            configs(6).Key = "CHITensor";
            configs(6).Label = "CHI-TENSOR";
            configs(6).Kinds = "CHITensor";
            configs(6).Color = [0.0 0.0 0.9];
            configs(6).Alpha = 0.60;
            configs(6).BaseScale = 0.60;
            configs(6).Mode = "EPR";
        end

        function updateTensorControlEnableState(app)
            if isempty(app.TensorControls)
                return
            end
            configs = app.tensorVisualConfigs();
            available = strings(0, 1);
            if ~isempty(app.Model.Interactions)
                available = app.Model.Interactions.Kind(app.Model.Interactions.ID > 0);
            end
            anyAvailable = false;
            for configIdx = 1:numel(configs)
                key = char(configs(configIdx).Key);
                enabled = any(ismember(available, configs(configIdx).Kinds));
                anyAvailable = anyAvailable || enabled;
                state = 'off';
                if enabled
                    state = 'on';
                end
                if isfield(app.TensorControls, key)
                    entry = app.TensorControls.(key);
                    if isfield(entry, 'Checkbox') && isvalid(entry.Checkbox)
                        entry.Checkbox.Enable = state;
                    end
                    if isfield(entry, 'Slider') && isvalid(entry.Slider)
                        entry.Slider.Enable = state;
                    end
                end
            end
            state = 'off';
            if anyAvailable
                state = 'on';
            end
            if isfield(app.TensorControls, 'Ellipsoids') && isvalid(app.TensorControls.Ellipsoids)
                app.TensorControls.Ellipsoids.Enable = state;
            end
            if isfield(app.TensorControls, 'Axes') && isvalid(app.TensorControls.Axes)
                app.TensorControls.Axes.Enable = state;
            end
        end

        function setTensorMode(app, mode)
            configs = app.tensorVisualConfigs();
            mode = string(mode);
            for configIdx = 1:numel(configs)
                key = char(configs(configIdx).Key);
                if ~isfield(app.TensorControls, key)
                    continue
                end
                entry = app.TensorControls.(key);
                if ~isfield(entry, 'Checkbox') || ~isvalid(entry.Checkbox)
                    continue
                end
                switch mode
                    case "NMR"
                        entry.Checkbox.Value = configs(configIdx).Mode == "NMR";
                    case "EPR"
                        entry.Checkbox.Value = configs(configIdx).Mode == "EPR";
                    otherwise
                        entry.Checkbox.Value = true;
                end
            end
            app.refresh();
        end

        function value = tensorControlValue(app, name, defaultValue)
            value = defaultValue;
            name = char(name);
            if ~isfield(app.TensorControls, name)
                return
            end
            entry = app.TensorControls.(name);
            if isstruct(entry) && isfield(entry, 'Checkbox')
                control = entry.Checkbox;
            else
                control = entry;
            end
            if ~isempty(control) && isvalid(control)
                value = logical(control.Value);
            end
        end

        function value = tensorSliderValue(app, name)
            value = 0;
            name = char(name);
            if ~isfield(app.TensorControls, name)
                return
            end
            entry = app.TensorControls.(name);
            if isstruct(entry) && isfield(entry, 'Slider') && ~isempty(entry.Slider) && isvalid(entry.Slider)
                value = double(entry.Slider.Value);
            end
        end

        function openDialog(app)
            [file, path] = uigetfile(spinachgui.importFileFilters(), 'Open or import spin system');
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
            app.showInteractionEditor(interactionID);
        end

        function showInteractionEditor(app, interactionID)
            idx = find(app.Model.Interactions.ID == interactionID, 1);
            if isempty(idx)
                uialert(app.Figure, 'The selected interaction is no longer present in the model.', ...
                    'Interaction unavailable', 'Icon', 'warning');
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
            if isempty(data) || size(data, 1) == 0
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
            row = max(1, min(row, size(data, 1)));
            interactionID = data{row, 1};
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

        function names = atomElementOptions(~)
            isotopes = spinachgui.isotopeTable();
            names = unique(isotopes.Element, 'stable').';
        end

        function names = atomTableKeys(~)
            names = ["ID","Label","Element","Mass","X","Y","Z"];
        end

        function names = interactionTableKeys(~)
            names = ["ID","Label","A","Kind","B","Unit","ReferenceFrameID","Reference","Edit"];
        end

        function names = interactionKindOptions(~)
            names = setdiff(spinachgui.interactionKinds(), "CBond", 'stable');
            names = names(:).';
        end

        function names = unitOptions(~)
            units = spinachgui.units();
            names = units.Name.';
        end

        function showEditError(app, err)
            if ~isempty(app.Figure) && isvalid(app.Figure)
                uialert(app.Figure, err.message, 'Table edit rejected', 'Icon', 'error');
            else
                warning(err.identifier, '%s', err.message);
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
