function editor = orientationEditor(dcm, varargin)
%ORIENTATIONEDITOR Open a compact SpinachGUI tensor/orientation editor.
%   EDITOR = spinachgui.orientationEditor(DCM) opens a uifigure that displays
%   a 3x3 direction-cosine matrix, the corresponding legacy SpinachGUI Z-Y-Z
%   Euler angles in degrees, and a MATLAB export preview.
%
%   EDITOR = spinachgui.orientationEditor(..., 'InteractionMatrix', M,
%   'Eigenvalues', V) also displays editable tensor-matrix and principal-value
%   tables. Editing the tensor, principal values, DCM, or Euler angles keeps the
%   four representations synchronized.
%
%   Name-value options:
%     'Visible'            'on' or 'off' for headless validation.
%     'Editable'           true to allow table edits, false to view.
%     'InteractionMatrix'  optional 3x3 tensor for the export preview/editor.
%     'Eigenvalues'        optional 1x3 eigenvalue vector for the preview/editor.
%     'ValueChangedFcn'    function handle called as f(EDITOR, DCM).

visible = 'on';
position = [140 140 820 720];
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

currentDcm = spinachgui.normalizeDcm(dcm);
currentEulerDegrees = rad2deg(spinachgui.dcmToEuler(currentDcm));
hasTensor = ~isempty(interactionMatrix) || ~isempty(eigenvalues);
if hasTensor
    if isempty(eigenvalues)
        currentInteractionMatrix = spinachgui.symmetrizeTensor(interactionMatrix);
        [vectors, values] = eig(currentInteractionMatrix);
        currentEigenvalues = diag(values).';
        currentDcm = spinachgui.normalizeDcm(vectors);
        currentEulerDegrees = rad2deg(spinachgui.dcmToEuler(currentDcm));
    else
        currentEigenvalues = double(eigenvalues(:).');
        if isempty(interactionMatrix)
            currentInteractionMatrix = currentDcm * diag(currentEigenvalues) * currentDcm.';
        else
            currentInteractionMatrix = spinachgui.symmetrizeTensor(interactionMatrix);
        end
    end
else
    currentInteractionMatrix = [];
    currentEigenvalues = [];
end

figureHandle = uifigure('Name', titleText, 'Position', position, 'Visible', visible);
if hasTensor
    root = uigridlayout(figureHandle, [10 1]);
    root.RowHeight = {24, 98, 24, 52, 24, 98, 24, 52, 24, '1x'};
else
    root = uigridlayout(figureHandle, [6 1]);
    root.RowHeight = {24, 118, 24, 58, 24, '1x'};
end
root.ColumnWidth = {'1x'};
root.Padding = [8 8 8 8];
root.RowSpacing = 6;

matrixTable = [];
eigenvaluesTable = [];
if hasTensor
    uilabel(root, 'Text', 'Interaction tensor matrix', 'FontWeight', 'bold');
    matrixTable = uitable(root, 'Data', currentInteractionMatrix, 'ColumnName', {'x', 'y', 'z'}, ...
        'RowName', {'x', 'y', 'z'}, 'ColumnEditable', repmat(editable, 1, 3), ...
        'CellEditCallback', @matrixEdited);
    matrixTable.Layout.Row = 2;
    matrixTable.Layout.Column = 1;

    uilabel(root, 'Text', 'Principal values', 'FontWeight', 'bold');
    eigenvaluesTable = uitable(root, 'Data', currentEigenvalues, 'ColumnName', {'1', '2', '3'}, ...
        'RowName', {}, 'ColumnEditable', repmat(editable, 1, 3), 'CellEditCallback', @eigenvaluesEdited);
    eigenvaluesTable.Layout.Row = 4;
    eigenvaluesTable.Layout.Column = 1;
    eigenvaluesTable.ColumnWidth = {'1x', '1x', '1x'};
    dcmLabelRow = 5;
    dcmRow = 6;
    eulerLabelRow = 7;
    eulerRow = 8;
    statusRow = 9;
    exportRow = 10;
else
    dcmLabelRow = 1;
    dcmRow = 2;
    eulerLabelRow = 3;
    eulerRow = 4;
    statusRow = 5;
    exportRow = 6;
end

dcmLabel = uilabel(root, 'Text', 'Direction-cosine matrix', 'FontWeight', 'bold');
dcmLabel.Layout.Row = dcmLabelRow;
dcmLabel.Layout.Column = 1;
dcmTable = uitable(root, 'Data', currentDcm, 'ColumnName', {'x', 'y', 'z'}, ...
    'RowName', {'x', 'y', 'z'}, 'ColumnEditable', repmat(editable, 1, 3), ...
    'CellEditCallback', @dcmEdited);
dcmTable.Layout.Row = dcmRow;
dcmTable.Layout.Column = 1;

eulerLabel = uilabel(root, 'Text', 'Legacy Z-Y-Z Euler angles, degrees', 'FontWeight', 'bold');
eulerLabel.Layout.Row = eulerLabelRow;
eulerLabel.Layout.Column = 1;
eulerTable = uitable(root, 'Data', currentEulerDegrees, 'ColumnName', {'alpha', 'beta', 'gamma'}, ...
    'RowName', {}, 'ColumnEditable', repmat(editable, 1, 3), 'CellEditCallback', @eulerEdited);
eulerTable.Layout.Row = eulerRow;
eulerTable.Layout.Column = 1;
eulerTable.ColumnWidth = {'1x', '1x', '1x'};

statusLabel = uilabel(root, 'Text', 'Ready');
statusLabel.Layout.Row = statusRow;
statusLabel.Layout.Column = 1;

exportTextArea = uitextarea(root, 'Editable', 'off');
exportTextArea.Layout.Row = exportRow;
exportTextArea.Layout.Column = 1;

editor = struct('Figure', figureHandle, 'MatrixTable', matrixTable, 'EigenvaluesTable', eigenvaluesTable, ...
    'DcmTable', dcmTable, 'EulerTable', eulerTable, 'ExportTextArea', exportTextArea, ...
    'StatusLabel', statusLabel, 'SetInteractionMatrix', @setInteractionMatrix, ...
    'SetEigenvalues', @setEigenvalues, 'SetDcm', @setDcm, 'SetEulerDegrees', @setEulerDegrees, ...
    'CurrentInteractionMatrix', @getInteractionMatrix, 'CurrentEigenvalues', @getEigenvalues, ...
    'CurrentDcm', @getDcm, 'CurrentEulerDegrees', @getEulerDegrees, 'ExportText', @getExportText);
refreshControls();

    function setInteractionMatrix(newMatrix)
        if ~hasTensor
            error('spinachgui:OrientationEditorNoTensor', 'This editor was not initialised with tensor data.');
        end
        validateattributes(newMatrix, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'InteractionMatrix');
        currentInteractionMatrix = spinachgui.symmetrizeTensor(newMatrix);
        [vectors, values] = eig(currentInteractionMatrix);
        currentEigenvalues = diag(values).';
        currentDcm = spinachgui.normalizeDcm(vectors);
        currentEulerDegrees = rad2deg(spinachgui.dcmToEuler(currentDcm));
        refreshControls();
        notifyValueChanged();
    end

    function setEigenvalues(newEigenvalues)
        if ~hasTensor
            error('spinachgui:OrientationEditorNoTensor', 'This editor was not initialised with tensor data.');
        end
        validateattributes(newEigenvalues, {'numeric'}, {'vector', 'numel', 3, 'finite', 'real'}, ...
            mfilename, 'Eigenvalues');
        currentEigenvalues = double(newEigenvalues(:).');
        updateMatrixFromEigenSystem();
        refreshControls();
        notifyValueChanged();
    end

    function setDcm(newDcm)
        currentDcm = spinachgui.normalizeDcm(newDcm);
        currentEulerDegrees = rad2deg(spinachgui.dcmToEuler(currentDcm));
        updateMatrixFromEigenSystem();
        refreshControls();
        notifyValueChanged();
    end

    function setEulerDegrees(newEulerDegrees)
        validateattributes(newEulerDegrees, {'numeric'}, {'vector', 'numel', 3, 'finite', 'real'}, ...
            mfilename, 'Euler angles');
        currentEulerDegrees = double(newEulerDegrees(:).');
        currentDcm = spinachgui.eulerToDcm(deg2rad(currentEulerDegrees(1)), ...
            deg2rad(currentEulerDegrees(2)), deg2rad(currentEulerDegrees(3)));
        updateMatrixFromEigenSystem();
        refreshControls();
        notifyValueChanged();
    end

    function matrix = getInteractionMatrix()
        matrix = currentInteractionMatrix;
    end

    function values = getEigenvalues()
        values = currentEigenvalues;
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

    function matrixEdited(source, ~)
        try
            setInteractionMatrix(source.Data);
            statusLabel.Text = 'Interaction matrix updated';
        catch err
            source.Data = currentInteractionMatrix;
            statusLabel.Text = "Invalid interaction matrix: " + err.message;
        end
    end

    function eigenvaluesEdited(source, ~)
        try
            setEigenvalues(source.Data);
            statusLabel.Text = 'Principal values updated';
        catch err
            source.Data = currentEigenvalues;
            statusLabel.Text = "Invalid principal values: " + err.message;
        end
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
        if ~isempty(matrixTable) && isvalid(matrixTable)
            matrixTable.Data = currentInteractionMatrix;
        end
        if ~isempty(eigenvaluesTable) && isvalid(eigenvaluesTable)
            eigenvaluesTable.Data = currentEigenvalues;
        end
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

    function updateMatrixFromEigenSystem()
        if hasTensor
            currentInteractionMatrix = spinachgui.symmetrizeTensor(currentDcm * diag(currentEigenvalues) * currentDcm.');
        end
    end

    function text = buildExportText()
        if ~hasTensor
            text = spinachgui.orientationExportText(currentDcm);
        else
            text = spinachgui.orientationExportText(currentDcm, 'InteractionMatrix', currentInteractionMatrix, ...
                'Eigenvalues', currentEigenvalues, 'DcmVariableName', 'eigenvectors');
        end
    end

    function notifyValueChanged()
        if ~isempty(valueChangedFcn)
            valueChangedFcn(editor, currentDcm);
        end
    end
end
