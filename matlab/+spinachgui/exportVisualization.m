function info = exportVisualization(target, filename, varargin)
%EXPORTVISUALIZATION Export a SpinachGUI graphics target to a file.
%   INFO = spinachgui.exportVisualization(TARGET, FILENAME) exports a
%   figure, axes, or UIAxes object to a bitmap or printable file.  The
%   helper deliberately uses explicit filenames, rather than desktop print
%   dialogs, so it can be validated in headless MATLAB.
%
%   Supported extensions are .bmp, .png, .jpg, .jpeg, .tif, .tiff, .pdf,
%   and .eps.  BMP output is produced by rendering a temporary PNG and
%   converting it with IMWRITE because EXPORTGRAPHICS does not write BMP
%   files directly.
%
%   Name-value options:
%     'Resolution'       positive integer bitmap resolution in DPI.
%     'BackgroundColor'  EXPORTGRAPHICS background, default 'white'.
%     'ContentType'      PDF/EPS content type: 'auto', 'vector', or 'image'.

resolution = 300;
backgroundColor = 'white';
contentType = 'auto';

if rem(numel(varargin), 2) ~= 0
    error('spinachgui:InvalidExportOptions', 'Export options must be name-value pairs.');
end
for k = 1:2:numel(varargin)
    name = validatestring(varargin{k}, {'Resolution', 'BackgroundColor', 'ContentType'}, ...
        mfilename, 'option name');
    value = varargin{k+1};
    switch name
        case 'Resolution'
            validateattributes(value, {'numeric'}, {'scalar', 'real', 'finite', 'positive'}, ...
                mfilename, 'Resolution');
            value = double(value);
            if abs(value - round(value)) > eps(value)
                error('spinachgui:InvalidExportResolution', 'Export resolution must be an integer DPI value.');
            end
            resolution = value;
        case 'BackgroundColor'
            backgroundColor = validateBackgroundColor(value);
        case 'ContentType'
            contentType = validatestring(value, {'auto', 'vector', 'image'}, mfilename, 'ContentType');
    end
end

if ~(isscalar(target) && isgraphics(target))
    error('spinachgui:InvalidExportTarget', 'Export target must be a scalar valid graphics object.');
end

validateattributes(filename, {'char', 'string'}, {'scalartext'}, mfilename, 'filename');
filename = char(filename);
[folder, ~, ext] = fileparts(filename);
if isempty(ext)
    error('spinachgui:MissingExportExtension', 'Export filename must include a supported extension.');
end
if ~isempty(folder) && ~isfolder(folder)
    mkdir(folder);
end
format = lower(ext(2:end));

bitmapFormats = {'bmp', 'png', 'jpg', 'jpeg', 'tif', 'tiff'};
printableFormats = {'pdf', 'eps'};
if any(strcmp(format, bitmapFormats))
    kind = 'bitmap';
elseif any(strcmp(format, printableFormats))
    kind = 'printable';
else
    error('spinachgui:UnsupportedExportFormat', ...
        'Unsupported export format "%s". Supported formats are BMP, PNG, JPEG, TIFF, PDF, and EPS.', ext);
end

drawnow;
if strcmp(format, 'bmp')
    exportBmp(target, filename, resolution, backgroundColor);
elseif strcmp(kind, 'bitmap')
    exportgraphics(target, filename, 'Resolution', resolution, 'BackgroundColor', backgroundColor);
else
    exportgraphics(target, filename, 'ContentType', contentType, 'BackgroundColor', backgroundColor);
end

fileInfo = dir(filename);
if isempty(fileInfo) || fileInfo.bytes == 0
    error('spinachgui:ExportFailed', 'Export did not produce a non-empty file: %s', filename);
end

info = struct('Filename', string(filename), 'Format', string(format), 'Kind', string(kind), ...
    'Bytes', fileInfo.bytes, 'TargetClass', string(class(target)), ...
    'Resolution', resolution, 'ContentType', string(contentType));
end

function color = validateBackgroundColor(value)
if isnumeric(value)
    validateattributes(value, {'numeric'}, {'real', 'finite', 'vector', 'numel', 3, '>=', 0, '<=', 1}, ...
        mfilename, 'BackgroundColor');
    color = double(value(:).');
elseif ischar(value) || (isstring(value) && isscalar(value))
    validateattributes(value, {'char', 'string'}, {'scalartext'}, mfilename, 'BackgroundColor');
    color = char(value);
else
    error('spinachgui:InvalidExportBackground', ...
        'BackgroundColor must be a colour name, ''none'', ''current'', or an RGB triplet.');
end
end

function exportBmp(target, filename, resolution, backgroundColor)
tempPng = [tempname, '.png'];
fid = fopen(tempPng, 'w');
if fid < 0
    error('spinachgui:ExportTempFileFailed', 'Could not create temporary file for BMP export.');
end
fclose(fid);
cleanup = onCleanup(@() delete(tempPng));
exportgraphics(target, tempPng, 'Resolution', resolution, 'BackgroundColor', backgroundColor);
imageData = imread(tempPng);
imwrite(imageData, filename, 'bmp');
clear cleanup
end
