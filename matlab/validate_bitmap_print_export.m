function validate_bitmap_print_export()
%VALIDATE_BITMAP_PRINT_EXPORT Headless graphics export smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

tmpDir = tempname;
mkdir(tmpDir);
cleanup = onCleanup(@() cleanupTempDir(tmpDir));

fig = figure('Visible', 'off', 'Position', [100 100 320 240], 'Color', 'white');
figureCleanup = onCleanup(@() deleteFigureIfValid(fig));
ax = axes(fig);
scatter3(ax, [0 1 0], [0 0 1], [0 0 0.5], 48, [1 0 0; 0 0.5 1; 0.2 0.7 0.2], 'filled');
hold(ax, 'on');
plot3(ax, [0 1], [0 0], [0 0], '-', 'Color', [0.35 0.35 0.35]);
plot3(ax, [0 0], [0 1], [0 0.5], '-', 'Color', [0.35 0.35 0.35]);
hold(ax, 'off');
axis(ax, 'equal');
grid(ax, 'on');
title(ax, 'SpinachGUI export validation');
view(ax, 3);
drawnow;

pngFile = fullfile(tmpDir, 'spinachgui_view.png');
bmpFile = fullfile(tmpDir, 'spinachgui_view.bmp');
pdfFile = fullfile(tmpDir, 'spinachgui_view.pdf');

pngInfo = spinachgui.exportVisualization(ax, pngFile, 'Resolution', 96);
bmpInfo = spinachgui.exportVisualization(ax, bmpFile, 'Resolution', 96);
pdfInfo = spinachgui.exportVisualization(ax, pdfFile, 'ContentType', 'image');

assertExportInfo(pngInfo, pngFile, 'png', 'bitmap');
assertExportInfo(bmpInfo, bmpFile, 'bmp', 'bitmap');
assertExportInfo(pdfInfo, pdfFile, 'pdf', 'printable');
assert(imfinfo(pngFile).Width > 0, 'PNG artifact was not readable.');
assert(imfinfo(bmpFile).Width > 0, 'BMP artifact was not readable.');
assert(pdfInfo.Bytes > 1000, 'PDF artifact is unexpectedly small.');
assertThrows(@() spinachgui.exportVisualization(ax, fullfile(tmpDir, 'bad.xyz')), ...
    'spinachgui:UnsupportedExportFormat');

app = spinachgui.App();
appCleanup = onCleanup(@() deleteFigureIfValid(app.Figure));
bitmapButton = findall(app.Figure, 'Text', 'Bitmap');
printButton = findall(app.Figure, 'Text', 'Print');
assert(isscalar(bitmapButton), 'App should expose exactly one Bitmap export button.');
assert(isscalar(printButton), 'App should expose exactly one Print button.');
assert(isa(bitmapButton.ButtonPushedFcn, 'function_handle'), 'Bitmap export callback missing.');
assert(isa(printButton.ButtonPushedFcn, 'function_handle'), 'Print callback missing.');
appPngFile = fullfile(tmpDir, 'app_view.png');
appPngInfo = app.exportVisualization(appPngFile, 'Resolution', 96);
assertExportInfo(appPngInfo, appPngFile, 'png', 'bitmap');
assert(contains(string(app.StatusLabel.Text), "Exported"), 'App status label should report export completion.');

fprintf('BITMAP_PRINT_EXPORT_VALIDATION_OK\n');
end

function assertExportInfo(info, filename, format, kind)
assert(isfile(filename), 'Expected artifact missing: %s', filename);
fileInfo = dir(filename);
assert(fileInfo.bytes > 0, 'Expected artifact is empty: %s', filename);
assert(info.Filename == string(filename), 'Returned filename does not match.');
assert(info.Format == string(format), 'Returned format does not match.');
assert(info.Kind == string(kind), 'Returned kind does not match.');
assert(info.Bytes == fileInfo.bytes, 'Returned byte count does not match.');
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

function deleteFigureIfValid(fig)
if ~isempty(fig) && isvalid(fig)
    delete(fig);
end
end

function cleanupTempDir(tmpDir)
if isfolder(tmpDir)
    rmdir(tmpDir, 's');
end
end
