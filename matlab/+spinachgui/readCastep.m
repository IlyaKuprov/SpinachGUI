function model = readCastep(filename)
%READCASTEP Import legacy CASTEP and MAGRES files into a SpinachGUI model.
%   The importer preserves the historical SpinachGUI CASTEP adapter semantics:
%   legacy text CASTEP shielding/EFG blocks and MAGRES atom, ms, efg, and total
%   isc records are imported; component-resolved MAGRES isc_* records are left
%   ignored as in the C++ reader.

lines = readlines(filename, 'EmptyLineRule', 'read');
model = spinachgui.Model();
model.SourceFile = string(filename);

if any(contains(lines, '<atoms>')) || any(contains(lines, '#$magres-abinitio-v1.0'))
    importMagres(model, lines, filename);
else
    importLegacyCastep(model, lines, filename);
end

if height(model.Atoms) == 0 && height(model.positiveInteractions()) == 0
    error('spinachgui:UnsupportedCastep', 'No recognized CASTEP/MAGRES content was found in %s.', filename);
end

if height(model.Atoms) > 0
    model.rebuildAutoBonds();
end
model.Dirty = false;
end

function importMagres(model, lines, filename)
atomIDs = containers.Map('KeyType', 'char', 'ValueType', 'double');
inAtoms = false;
inMagres = false;
readAny = false;

for k = 1:numel(lines)
    line = strtrim(char(lines(k)));
    if line == "" || startsWith(line, '#')
        continue
    end
    if contains(line, '<atoms>')
        inAtoms = true;
        inMagres = false;
        readAny = true;
        continue
    elseif contains(line, '</atoms>')
        inAtoms = false;
        continue
    elseif contains(line, '<magres>')
        inMagres = true;
        inAtoms = false;
        readAny = true;
        continue
    elseif contains(line, '</magres>')
        inMagres = false;
        continue
    end

    fields = splitFields(line);
    if isempty(fields)
        continue
    end
    if inAtoms
        if strcmp(fields{1}, 'atom')
            if numel(fields) ~= 7
                error('spinachgui:InvalidCastep', 'Invalid MAGRES atom record at line %d in %s.', k, filename);
            end
            xyz = parseNumber(fields(5:7));
            if any(isnan(xyz))
                error('spinachgui:InvalidCastep', 'Invalid MAGRES atom coordinates at line %d in %s.', k, filename);
            end
            key = atomKey(fields{3}, fields{4});
            if isKey(atomIDs, key)
                error('spinachgui:InvalidCastep', 'Duplicate MAGRES atom label %s at line %d in %s.', key, k, filename);
            end
            atomIDs(key) = model.addAtom(canonicalElement(fields{2}), xyz, string(key));
            readAny = true;
        end
    elseif inMagres
        if strcmp(fields{1}, 'units')
            continue
        end
        switch fields{1}
            case 'ms'
                if numel(fields) ~= 12
                    error('spinachgui:InvalidCastep', 'Invalid MAGRES ms record at line %d in %s.', k, filename);
                end
                atomID = requireAtomKey(atomIDs, fields{2}, fields{3}, filename, k, 'MAGRES ms');
                matrix = matrixFromFlat(fields(4:12), filename, k, 'MAGRES ms tensor');
                model.addInteraction('CShielding', atomID, atomID, matrix, 'ppm', '', 1, '', 'CASTEP MAGRES shielding');
                readAny = true;
            case 'efg'
                if numel(fields) ~= 12
                    error('spinachgui:InvalidCastep', 'Invalid MAGRES efg record at line %d in %s.', k, filename);
                end
                atomID = requireAtomKey(atomIDs, fields{2}, fields{3}, filename, k, 'MAGRES efg');
                isotope = isotopeForQuadrupole(model, atomID);
                if ~isempty(isotope) && isotope.Spin > 0.5
                    matrix = matrixFromFlat(fields(4:12), filename, k, 'MAGRES efg tensor');
                    if norm(matrix, 'fro') > 0
                        setAtomIsotope(model, atomID, isotope);
                        model.addInteraction('Quadrupolar', atomID, atomID, matrix, 'MHz', '', 1, '', 'CASTEP MAGRES EFG');
                    end
                end
                readAny = true;
            case 'isc'
                if numel(fields) ~= 14
                    error('spinachgui:InvalidCastep', 'Invalid MAGRES isc record at line %d in %s.', k, filename);
                end
                atomID1 = requireAtomKey(atomIDs, fields{2}, fields{3}, filename, k, 'MAGRES isc');
                atomID2 = requireAtomKey(atomIDs, fields{4}, fields{5}, filename, k, 'MAGRES isc');
                if atomID1 ~= atomID2
                    matrix = matrixFromFlat(fields(6:14), filename, k, 'MAGRES isc tensor');
                    scalar = trace(matrix) / 3;
                    model.addInteraction('Jcoupling', atomID1, atomID2, scalar * eye(3), 'ppm', '', 1, '', 'CASTEP MAGRES J coupling');
                end
                readAny = true;
        end
    end
end

if ~readAny
    error('spinachgui:UnsupportedCastep', 'No recognized MAGRES section was found in %s.', filename);
end
end

function importLegacyCastep(model, lines, filename)
quadrupoleMoments = readLegacyQuadrupoleMoments(lines, filename);
atomIDs = containers.Map('KeyType', 'char', 'ValueType', 'double');
readAny = false;

k = 1;
while k <= numel(lines)
    line = strtrim(char(lines(k)));
    atomMatch = regexp(line, '^Atom:\s*([A-Za-z][a-z]?)\s+(\S+)', 'tokens', 'once');
    if isempty(atomMatch)
        k = k + 1;
        continue
    end

    blockEnd = numel(lines) + 1;
    for j = k + 1:numel(lines)
        if ~isempty(regexp(strtrim(char(lines(j))), '^Atom:\s*([A-Za-z][a-z]?)\s+(\S+)', 'once'))
            blockEnd = j;
            break
        end
    end

    coordinateLine = [];
    totalLine = [];
    for j = k + 1:blockEnd - 1
        current = char(lines(j));
        if isempty(coordinateLine) && contains(current, 'Coordinates')
            coordinateLine = j;
        end
        if isempty(totalLine) && contains(current, 'TOTAL')
            totalLine = j;
        end
    end

    if ~isempty(coordinateLine) && ~isempty(totalLine)
        [atomID, element] = addLegacyAtom(model, atomIDs, char(lines(coordinateLine)), filename, coordinateLine);
        totalText = char(lines(totalLine));
        if contains(totalText, 'Shielding') && contains(totalText, 'Tensor')
            [matrix, ~] = readFirstNumeric3x3(lines, totalLine + 1, blockEnd - 1, filename, 'legacy CASTEP shielding tensor');
            model.addInteraction('CShielding', atomID, atomID, matrix, 'ppm', '', 1, '', 'CASTEP shielding');
            readAny = true;
        elseif ~isempty(regexpi(totalText, 'TOTAL\s+tensor', 'once'))
            if ~isKey(quadrupoleMoments, char(element))
                error('spinachgui:InvalidCastep', 'Quadrupole moment for %s was not declared before line %d in %s.', element, totalLine, filename);
            end
            isotope = isotopeForQuadrupole(model, atomID);
            if ~isempty(isotope) && isotope.Spin > 0.5
                [rawMatrix, ~] = readFirstNumeric3x3(lines, totalLine + 1, blockEnd - 1, filename, 'legacy CASTEP quadrupolar tensor');
                denominator = 2 * isotope.Spin * (2 * isotope.Spin - 1);
                if denominator > 0
                    factor = 2.3496e+02 * quadrupoleMoments(char(element)) / denominator;
                    matrix = rawMatrix * factor;
                    if norm(matrix, 'fro') > 0
                        setAtomIsotope(model, atomID, isotope);
                        model.addInteraction('Quadrupolar', atomID, atomID, matrix, 'MHz', '', 1, '', 'CASTEP quadrupolar');
                    end
                end
            end
            readAny = true;
        end
    end
    k = blockEnd;
end

if ~readAny
    error('spinachgui:UnsupportedCastep', 'No recognized legacy CASTEP section was found in %s.', filename);
end
end

function moments = readLegacyQuadrupoleMoments(lines, filename)
moments = containers.Map('KeyType', 'char', 'ValueType', 'double');
for k = 1:numel(lines)
    if ~contains(char(lines(k)), 'electric quadrupole moment')
        continue
    end
    for j = k + 1:numel(lines)
        line = char(lines(j));
        if contains(line, '============')
            return
        end
        fields = splitFields(line);
        if isempty(fields)
            continue
        end
        if numel(fields) ~= 7
            error('spinachgui:InvalidCastep', 'Invalid quadrupole-moment record at line %d in %s.', j, filename);
        end
        moments(char(canonicalElement(fields{1}))) = parseNumber(fields(6));
    end
end
end

function [atomID, element] = addLegacyAtom(model, atomIDs, line, filename, lineNumber)
fields = splitFields(line);
if numel(fields) ~= 7 || ~strcmp(fields{3}, 'Coordinates')
    error('spinachgui:InvalidCastep', 'Invalid legacy CASTEP coordinate record at line %d in %s.', lineNumber, filename);
end
element = canonicalElement(fields{1});
key = atomKey(element, fields{2});
if isKey(atomIDs, key)
    atomID = atomIDs(key);
else
    xyz = parseNumber(fields(4:6));
    if any(isnan(xyz))
        error('spinachgui:InvalidCastep', 'Invalid legacy CASTEP coordinates at line %d in %s.', lineNumber, filename);
    end
    atomID = model.addAtom(element, xyz, string(key));
    atomIDs(key) = atomID; %#ok<NASGU>
end
end

function [matrix, lastLine] = readFirstNumeric3x3(lines, startLine, endLine, filename, context)
firstLine = [];
for j = startLine:endLine
    fields = splitFields(char(lines(j)));
    if numel(fields) == 3
        values = parseNumber(fields);
        if all(~isnan(values))
            firstLine = j;
            break
        end
    end
end
if isempty(firstLine) || firstLine + 2 > endLine
    error('spinachgui:InvalidCastep', 'Truncated %s near line %d in %s.', context, startLine, filename);
end
matrix = zeros(3);
for r = 1:3
    lineNumber = firstLine + r - 1;
    fields = splitFields(char(lines(lineNumber)));
    if numel(fields) ~= 3
        error('spinachgui:InvalidCastep', 'Expected three fields in %s row at line %d in %s.', context, lineNumber, filename);
    end
    values = parseNumber(fields);
    if any(isnan(values))
        error('spinachgui:InvalidCastep', 'Invalid numeric value in %s row at line %d in %s.', context, lineNumber, filename);
    end
    matrix(r, :) = values;
end
lastLine = firstLine + 2;
end

function matrix = matrixFromFlat(tokens, filename, lineNumber, context)
values = parseNumber(tokens);
if numel(values) ~= 9 || any(isnan(values))
    error('spinachgui:InvalidCastep', 'Invalid numeric value in %s at line %d in %s.', context, lineNumber, filename);
end
matrix = reshape(values, [3 3]).';
end

function atomID = requireAtomKey(atomIDs, label, index, filename, lineNumber, context)
key = atomKey(label, index);
if ~isKey(atomIDs, key)
    error('spinachgui:InvalidCastep', '%s refers to missing atom %s at line %d in %s.', context, key, lineNumber, filename);
end
atomID = atomIDs(key);
end

function key = atomKey(label, index)
key = char(string(strtrim(char(label))) + string(strtrim(char(index))));
end

function fields = splitFields(line)
fields = regexp(strtrim(line), '[\s,]+', 'split');
fields = fields(~cellfun('isempty', fields));
end

function numbers = parseNumber(tokens)
if ischar(tokens) || isstring(tokens)
    tokens = cellstr(tokens);
end
numbers = zeros(1, numel(tokens));
for k = 1:numel(tokens)
    token = regexprep(char(tokens{k}), '[dD]', 'E');
    numbers(k) = spinachgui.parseNumber(token);
end
end

function element = canonicalElement(token)
token = char(string(token));
if isempty(token)
    element = "";
elseif isscalar(token)
    element = string(upper(token));
else
    element = string([upper(token(1)), lower(token(2:end))]);
end
end

function isotope = isotopeForQuadrupole(model, atomID)
row = find(model.Atoms.ID == atomID, 1);
if isempty(row)
    isotope = [];
    return
end
label = isotopeLabelFromAtomRow(model.Atoms(row, :));
try
    isotope = spinachgui.findIsotope(label);
catch
    isotope = [];
end
if isempty(isotope)
    return
end
if isotope.Spin <= 0.5
    isotope = firstHigherSpinIsotope(string(isotope.Element));
end
end

function isotope = firstHigherSpinIsotope(element)
t = spinachgui.isotopeTable();
idx = find(string(t.Element) == string(element) & t.Spin > 0.5, 1);
if isempty(idx)
    isotope = [];
else
    isotope = t(idx, :);
end
end

function label = isotopeLabelFromAtomRow(row)
if row.Mass > 0
    label = string(row.Mass) + string(row.Element);
else
    label = string(row.Element);
end
end

function setAtomIsotope(model, atomID, isotope)
row = find(model.Atoms.ID == atomID, 1);
if isempty(row)
    return
end
model.Atoms.Element(row) = string(isotope.Element);
model.Atoms.Mass(row) = isotope.Mass;
model.Atoms.Radius(row) = isotope.Radius;
model.Atoms.Red(row) = isotope.Red;
model.Atoms.Green(row) = isotope.Green;
model.Atoms.Blue(row) = isotope.Blue;
model.Atoms.Spin(row) = isotope.Spin;
model.Atoms.Magnetogyric(row) = isotope.Magnetogyric;
end
