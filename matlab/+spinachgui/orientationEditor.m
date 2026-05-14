function editor = orientationEditor(dcm, varargin)
%ORIENTATIONEDITOR Open a compact SpinachGUI DCM/Euler orientation editor.
%   EDITOR = spinachgui.orientationEditor(DCM) opens a uifigure that displays
%   a 3x3 direction-cosine matrix, the corresponding legacy SpinachGUI Z-Y-Z
%   Euler angles in degrees, and a MATLAB export preview.
%
%   Name-value options:
%     'Visible'            'on' or 'off' for headless validation.
%     'Editable'           true to allow DCM/Euler table edits, false to view.
%     'InteractionMatrix'  optional 3x3 tensor for the export preview.
%     'Eigenvalues'        optional 1x3 eigenvalue vector for the preview.
%     'ValueChangedFcn'    function handle called as f(EDITOR, DCM).

visible = 'on';
position = [140 140 760 560];
titleText = 'SpinachGUI orientation';
editable = true;
interactionMatrix = [];
eigenvalues = [];
valueChangedFcn = [];

if rem(nargin - 1, 2) ~= 0
    error('spinachgui:OrientationEditorOptions', 'Options must be name-value pairs.');
end
for k = 1:2:numel(varargin)
    name = validatestring(varargin{k}, {'Visible', 'Position', 'Title', 'Editable', ...
        'InteractionMatrix', 'Eigenvalues', 'ValueChangedFcn'}, mfilename, 'option name');
    value = varargin{k+1};
    switch name
        case 'Visible'
            visible = validatestring(value, {'on', 'off'}, mfilename, 'Visible');
        case 'Position'
            validateattributes(value, {'numeric'}, {'real', 'finite', 'vector', 'numel', 4}, mfilename, 'Position');
            position = double(value(:).');
        case 'Title'
            validateattributes(value, {'char', 'string'}, {'scalartext'}, mfilename, 'Title');
            titleText = char(value);
        case 'Editable'
            validateattributes(value, {'logical'}, {'scalar'}, mfilename, 'Editable');
            editable = value;
        case 'InteractionMatrix'
            validateattributes(value, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'InteractionMatrix');
            interactionMatrix = double(value);
        case 'Eigenvalues'
            validateattributes(value, {'numeric'}, {'vector', 'numel', 3, 'finite', 'real'}, mfilename, 'Eigenvalues');
            eigenvalues = double(value(:).');
        case 'ValueChangedFcn'
            if ~isempty(value) && ~isa(value, 'function_handle')
                error('spinachgui:InvalidOrientationCallback', 'ValueChangedFcn must be a function handle or empty.');
            end
            valueChangedFcn = value;
    end
end

validateattributes(dcm, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'dcm');
currentDcm = double(dcm);
currentEulerDegrees = rad2deg(spinachgui.dcmToEuler(currentDcm));

figureHandle = uifigure('Name', titleText, 'Position', position, 'Visible', visible);
root = uigridlayout(figureHandle, [6 1]);
root.RowHeight = {24, 118, 24, 58, 24, '1x'};
root.ColumnWidth = {'1x'};
root.Padding = [8 8 8 8];
root.RowSpacing = 6;

uilabel(root, 'Text', 'Direction-cosine matrix', 'FontWeight', 'bold');
dcmTable = uitable(root, 'Data', currentDcm, 'ColumnName', {'x', 'y', 'z'}, ...
    'RowName', {'x', 'y', 'z'}, 'ColumnEditable', repmat(editable, 1, 3), ...
    'CellEditCallback', @dcmEdited);
dcmTable.Layout.Row = 2;
dcmTable.Layout.Column = 1;

uilabel(root, 'Text', 'Legacy Z-Y-Z Euler angles, degrees', 'FontWeight', 'bold');
eulerTable = uitable(root, 'Data', currentEulerDegrees, 'ColumnName', {'alpha', 'beta', 'gamma'}, ...
    'RowName', {}, 'ColumnEditable', repmat(editable, 1, 3), 'CellEditCallback', @eulerEdited);
eulerTable.Layout.Row = 4;
eulerTable.Layout.Column = 1;
eulerTable.ColumnWidth = {'1x', '1x', '1x'};

statusLabel = uilabel(root, 'Text', 'Ready');
statusLabel.Layout.Row = 5;
statusLabel.Layout.Column = 1;

exportTextArea = uitextarea(root, 'Editable', 'off');
exportTextArea.Layout.Row = 6;
exportTextArea.Layout.Column = 1;

editor = struct('Figure', figureHandle, 'DcmTable', dcmTable, 'EulerTable', eulerTable, ...
    'ExportTextArea', exportTextArea, 'StatusLabel', statusLabel, 'SetDcm', @setDcm, ...
    'SetEulerDegrees', @setEulerDegrees, 'CurrentDcm', @getDcm, ...
    'CurrentEulerDegrees', @getEulerDegrees, 'ExportText', @getExportText);
refreshControls();

    function setDcm(newDcm)
        validateattributes(newDcm, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'dcm');
        currentDcm = double(newDcm);
        currentEulerDegrees = rad2deg(spinachgui.dcmToEuler(currentDcm));
        refreshControls();
        notifyValueChanged();
    end

    function setEulerDegrees(newEulerDegrees)
        validateattributes(newEulerDegrees, {'numeric'}, {'vector', 'numel', 3, 'finite', 'real'}, ...
            mfilename, 'Euler angles');
        currentEulerDegrees = double(newEulerDegrees(:).');
        currentDcm = spinachgui.eulerToDcm(deg2rad(currentEulerDegrees(1)), ...
            deg2rad(currentEulerDegrees(2)), deg2rad(currentEulerDegrees(3)));
        refreshControls();
        notifyValueChanged();
    end

    function dcmValue = getDcm()
        dcmValue = currentDcm;
    end

    function eulerDegrees = getEulerDegrees()
        eulerDegrees = currentEulerDegrees;
    end

    function text = getExportText()
        text = buildExportText();
    end

    function dcmEdited(source, ~)
        try
            setDcm(source.Data);
            statusLabel.Text = 'Direction-cosine matrix updated';
        catch err
            source.Data = currentDcm;
            statusLabel.Text = "Invalid DCM: " + err.message;
        end
    end

    function eulerEdited(source, ~)
        try
            setEulerDegrees(source.Data);
            statusLabel.Text = 'Euler angles updated';
        catch err
            source.Data = currentEulerDegrees;
            statusLabel.Text = "Invalid Euler angles: " + err.message;
        end
    end

    function refreshControls()
        if isvalid(dcmTable)
            dcmTable.Data = currentDcm;
        end
        if isvalid(eulerTable)
            eulerTable.Data = currentEulerDegrees;
        end
        if isvalid(exportTextArea)
            exportTextArea.Value = splitlines(buildExportText());
        end
    end

    function text = buildExportText()
        if isempty(interactionMatrix) && isempty(eigenvalues)
            text = spinachgui.orientationExportText(currentDcm);
        elseif isempty(interactionMatrix)
            text = spinachgui.orientationExportText(currentDcm, 'Eigenvalues', eigenvalues, ...
                'DcmVariableName', 'eigenvectors');
        elseif isempty(eigenvalues)
            text = spinachgui.orientationExportText(currentDcm, 'InteractionMatrix', interactionMatrix, ...
                'DcmVariableName', 'eigenvectors');
        else
            text = spinachgui.orientationExportText(currentDcm, 'InteractionMatrix', interactionMatrix, ...
                'Eigenvalues', eigenvalues, 'DcmVariableName', 'eigenvectors');
        end
    end

    function notifyValueChanged()
        if ~isempty(valueChangedFcn)
            valueChangedFcn(editor, currentDcm);
        end
    end
end
