function text = orientationExportText(dcm, varargin)
%ORIENTATIONEXPORTTEXT Legacy-style orientation export text.
%   TEXT = spinachgui.orientationExportText(DCM) returns a MATLAB text block
%   containing a direction-cosine matrix and the corresponding legacy
%   SpinachGUI Z-Y-Z Euler angles in degrees.
%
%   TEXT = spinachgui.orientationExportText(..., 'InteractionMatrix', M,
%   'Eigenvalues', V) prepends the interaction tensor and eigenvalue blocks
%   used by the historical OrientationExport dialog. 'DcmVariableName' may
%   be used to select the exported DCM assignment name; the default is
%   'directioncosinematrix'.

interactionMatrix = [];
eigenvalues = [];
dcmVariableName = 'directioncosinematrix';
header = "";

if rem(nargin - 1, 2) ~= 0
    error('spinachgui:OrientationExportOptions', 'Options must be name-value pairs.');
end
for k = 1:2:numel(varargin)
    name = validatestring(varargin{k}, {'InteractionMatrix', 'Eigenvalues', 'DcmVariableName', 'Header'}, ...
        mfilename, 'option name');
    value = varargin{k+1};
    switch name
        case 'InteractionMatrix'
            validateattributes(value, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'InteractionMatrix');
            interactionMatrix = double(value);
        case 'Eigenvalues'
            validateattributes(value, {'numeric'}, {'vector', 'numel', 3, 'finite', 'real'}, mfilename, 'Eigenvalues');
            eigenvalues = double(value(:).');
        case 'DcmVariableName'
            validateattributes(value, {'char', 'string'}, {'scalartext'}, mfilename, 'DcmVariableName');
            dcmVariableName = char(value);
            if ~isvarname(dcmVariableName)
                error('spinachgui:InvalidOrientationVariable', 'DcmVariableName must be a valid MATLAB identifier.');
            end
        case 'Header'
            validateattributes(value, {'char', 'string'}, {'scalartext'}, mfilename, 'Header');
            header = string(value);
    end
end

validateattributes(dcm, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'dcm');
dcm = double(dcm);
eulerDegrees = rad2deg(spinachgui.dcmToEuler(dcm));

blocks = strings(0, 1);
if strlength(header) > 0
    blocks(end+1, 1) = "% " + header;
end
if ~isempty(interactionMatrix)
    blocks(end+1, 1) = formatMatrixAssignment('interactionmatrix', interactionMatrix);
end
if ~isempty(eigenvalues)
    blocks(end+1, 1) = formatVectorAssignment('eigenvalues', eigenvalues);
end
blocks(end+1, 1) = formatMatrixAssignment(dcmVariableName, dcm);
blocks(end+1, 1) = formatVectorAssignment('eulerangles', eulerDegrees);

lineBreak = newline;
text = strjoin(blocks, [lineBreak lineBreak]) + string(lineBreak);
end

function text = formatMatrixAssignment(variableName, matrix)
rows = strings(3, 1);
for row = 1:3
    rows(row) = sprintf('%.6e %.6e %.6e', matrix(row, 1), matrix(row, 2), matrix(row, 3));
end
indent = blanks(strlength(string(variableName)) + 2);
text = sprintf('%s=[ %s\n%s%s\n%s%s ];', variableName, char(rows(1)), indent, char(rows(2)), indent, char(rows(3)));
text = string(text);
end

function text = formatVectorAssignment(variableName, vector)
text = string(sprintf('%s=[ %.6e %.6e %.6e ];', variableName, vector(1), vector(2), vector(3)));
end
