function validate_isotope_browser()
%VALIDATE_ISOTOPE_BROWSER Deterministic isotope browser smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

raw = spinachgui.isotopeTable();
expectedRawNames = {'Element', 'AtomNumber', 'Mass', 'Radius', 'Red', 'Green', 'Blue', ...
    'Spin', 'QuadrupoleMoment', 'Magnetogyric'};
assert(height(raw) == 121, 'Unexpected isotope table height.');
assert(isequal(raw.Properties.VariableNames, expectedRawNames), 'Unexpected raw isotope variables.');
assert(strcmp(raw.Element{1}, 'e') && raw.Mass(1) == 0, 'Electron pseudo-isotope row changed.');
assert(strcmp(raw.Element{2}, 'chi') && raw.Mass(2) == 0, 'Chi pseudo-isotope row changed.');
assert(strcmp(raw.Element{3}, 'H') && raw.AtomNumber(3) == 1 && raw.Mass(3) == 1, ...
    'Hydrogen isotope row changed.');
assert(abs(raw.Spin(3) - 0.5) < eps && raw.QuadrupoleMoment(3) == 0, ...
    'Hydrogen spin or quadrupole metadata changed.');
assert(abs(raw.Magnetogyric(3) - 267522205) < 1e-6, 'Hydrogen magnetogyric ratio changed.');

browser = spinachgui.isotopeBrowser('Visible', 'off', 'Title', 'Validation isotopes');
assert(isstruct(browser), 'Browser return value should be a struct.');
assert(isvalid(browser.Figure), 'Browser figure was not constructed.');
assert(isvalid(browser.Table), 'Browser table was not constructed.');
assert(isequal(browser.Figure.Visible, 'off'), 'Headless browser should be invisible.');

expectedDisplayNames = {'Index', 'Element', 'AtomicNumber', 'MassNumber', 'Color', ...
    'Radius', 'Spin', 'QuadrupoleMoment', 'Magnetogyric'};
displayData = browser.Data;
assert(height(displayData) == height(raw), 'Browser data height mismatch.');
assert(isequal(displayData.Properties.VariableNames, expectedDisplayNames), ...
    'Unexpected browser data variables.');
assert(isequal(browser.Table.Data, displayData), 'UITable data does not match returned browser data.');
assert(isequal(browser.Table.ColumnName(:).', {'#', 'Element', 'Atomic Number', ...
    'Mass Number', 'Color (RGB)', 'Radius', 'Spin', 'Quadrupole Moment', 'Magnetogyric'}), ...
    'Unexpected browser column labels.');
assert(isequal(browser.Table.ColumnEditable, false(1, width(displayData))), ...
    'Isotope browser table should be read-only.');
assert(displayData.Index(1) == 0 && displayData.Index(end) == height(raw) - 1, ...
    'Legacy isotope browser row numbering changed.');
assert(displayData.Element(3) == "H" && displayData.AtomicNumber(3) == 1 && ...
    displayData.MassNumber(3) == 1, 'Browser hydrogen display row changed.');
assert(displayData.Color(3) == "204,204,204", 'Browser RGB display row changed.');

delete(browser.Figure);

app = spinachgui.App();
assert(isvalid(app.Figure), 'App construction failed after isotope browser integration.');
button = findall(app.Figure, 'Text', 'Isotopes');
assert(isscalar(button), 'App should expose exactly one Isotopes button.');
assert(isa(button.ButtonPushedFcn, 'function_handle'), 'Isotopes button callback missing.');
delete(app.Figure);

fprintf('ISOTOPE_BROWSER_VALIDATION_OK\n');
end
