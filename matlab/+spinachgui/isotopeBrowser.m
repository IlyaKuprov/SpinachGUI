function browser = isotopeBrowser(varargin)
%ISOTOPEBROWSER Open the read-only SpinachGUI isotope browser.
%   BROWSER = spinachgui.isotopeBrowser() opens a uifigure containing the
%   isotope database used by the MATLAB SpinachGUI rewrite. The returned
%   struct contains the figure handle, table handle, and displayed data.
%
%   BROWSER = spinachgui.isotopeBrowser('Visible','off') constructs the same
%   browser without showing it, which is useful for headless validation.

visible = 'on';
position = [120 120 900 640];
titleText = 'SpinachGUI isotopes';
if rem(nargin, 2) ~= 0
    error('spinachgui:IsotopeBrowserOptions', 'Options must be name-value pairs.');
end
for k = 1:2:nargin
    name = validatestring(varargin{k}, {'Visible', 'Position', 'Title'}, mfilename, 'option name');
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
    end
end

isotopes = spinachgui.isotopeTable();
rgb = round(255 * [isotopes.Red, isotopes.Green, isotopes.Blue]);
colorText = compose('%d,%d,%d', rgb(:, 1), rgb(:, 2), rgb(:, 3));
data = table((0:height(isotopes)-1).', string(isotopes.Element), isotopes.AtomNumber, ...
    isotopes.Mass, colorText, isotopes.Radius, isotopes.Spin, isotopes.QuadrupoleMoment, ...
    isotopes.Magnetogyric, 'VariableNames', {'Index', 'Element', 'AtomicNumber', ...
    'MassNumber', 'Color', 'Radius', 'Spin', 'QuadrupoleMoment', 'Magnetogyric'});

figureHandle = uifigure('Name', titleText, 'Position', position, 'Visible', visible);
layout = uigridlayout(figureHandle, [1 1]);
layout.Padding = [2 2 2 2];
layout.RowHeight = {'1x'};
layout.ColumnWidth = {'1x'};
tableHandle = uitable(layout, 'Data', data, 'ColumnEditable', false(1, width(data)), ...
    'ColumnName', {'#', 'Element', 'Atomic Number', 'Mass Number', 'Color (RGB)', ...
    'Radius', 'Spin', 'Quadrupole Moment', 'Magnetogyric'}, 'RowName', {});
tableHandle.Layout.Row = 1;
tableHandle.Layout.Column = 1;
tableHandle.ColumnWidth = {42, 70, 95, 90, 92, 70, 60, 135, 105};

for row = 1:height(data)
    style = uistyle('BackgroundColor', [isotopes.Red(row), isotopes.Green(row), isotopes.Blue(row)]);
    addStyle(tableHandle, style, 'cell', [row 5]);
end

browser = struct('Figure', figureHandle, 'Table', tableHandle, 'Data', data);
end
