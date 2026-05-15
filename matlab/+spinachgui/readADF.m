function model = readADF(filename)
%READADF Import ADF output into a SpinachGUI model.
%   This reader preserves the legacy ADF importer scope: Cartesian geometry,
%   total NMR shielding tensors, and scalar total J-couplings.

lines = readlines(filename, 'EmptyLineRule', 'read');
coordinateFrames = {};
shieldingSections = {};
jCouplingSections = {};
readAnySection = false;

for k = 1:numel(lines)
    line = char(lines(k));
    if contains(line, 'G E O M E T R Y  ***  3D  Molecule  ***')
        atoms = readCoordinateFrame(lines, k, filename);
        if ~isempty(atoms)
            coordinateFrames{end+1} = atoms; %#ok<AGROW>
        end
        readAnySection = true;
    elseif contains(line, 'Stephen K. Wolff & Georg Schreckenbach')
        shieldingSections{end+1} = readChemicalShieldingSection(lines, k, filename); %#ok<AGROW>
        readAnySection = true;
    elseif contains(line, '*  NMR spin spin coupling tensor calculation  *')
        jCouplingSections{end+1} = readJCouplingSection(lines, k, filename); %#ok<AGROW>
        readAnySection = true;
    end
end

if ~readAnySection
    error('spinachgui:UnsupportedADF', 'No recognized ADF section was found in %s.', filename);
end
if isempty(coordinateFrames) && (~isempty(shieldingSections) || ~isempty(jCouplingSections))
    error('spinachgui:InvalidADF', ...
        'ADF tensor sections requiring nuclei were found, but no coordinate section was found in %s.', filename);
end

model = spinachgui.Model();
model.SourceFile = string(filename);
if ~isempty(coordinateFrames)
    atoms = coordinateFrames{end};
    for k = 1:numel(atoms)
        model.addAtom(atoms(k).Isotope, atoms(k).XYZ, "");
    end
    model.rebuildAutoBonds();
end

if ~isempty(shieldingSections)
    addShieldingInteractions(model, shieldingSections{end});
end
if ~isempty(jCouplingSections)
    addJCouplingInteractions(model, jCouplingSections{end});
end

model.Dirty = false;
end

function atoms = readCoordinateFrame(lines, markerLine, filename)
atoms = struct('Isotope', {}, 'XYZ', {});
headerLine = [];
for j = markerLine+1:min(numel(lines), markerLine+24)
    line = char(lines(j));
    if contains(line, '--------------------------') && contains(line, '-------')
        headerLine = j;
        break
    end
end
if isempty(headerLine)
    error('spinachgui:InvalidADF', 'Missing ADF coordinate table after line %d in %s.', markerLine, filename);
end

for j = headerLine+1:numel(lines)
    line = char(lines(j));
    if isempty(strtrim(line))
        if ~isempty(atoms)
            return
        end
        continue
    end
    fields = splitFields(line);
    if numel(fields) ~= 8
        if isempty(atoms)
            error('spinachgui:InvalidADF', 'Malformed ADF coordinate row at line %d in %s.', j, filename);
        end
        return
    end
    atomIndex = str2double(fields{1});
    xyz = parseNumber(fields(3:5));
    mass = round(parseNumber(fields(8)));
    if isnan(atomIndex) || any(isnan(xyz)) || isnan(mass)
        error('spinachgui:InvalidADF', 'Invalid ADF coordinate value at line %d in %s.', j, filename);
    end
    atoms(end+1).Isotope = isotopeLabelForADF(fields{2}, mass); %#ok<AGROW>
    atoms(end).XYZ = xyz;
end
if isempty(atoms)
    error('spinachgui:InvalidADF', 'No ADF coordinates found after line %d in %s.', markerLine, filename);
end
end

function tensors = readChemicalShieldingSection(lines, markerLine, filename)
tensors = struct('AtomID', {}, 'Matrix', {});
j = markerLine + 1;
while j <= numel(lines)
    line = char(lines(j));
    if contains(line, 'NORMAL TERMINATION')
        break
    end
    if ~contains(line, '****  N U C L E U S :')
        j = j + 1;
        continue
    end

    [atomID, j] = readADFAtomID(lines, j, filename);
    while j <= numel(lines)
        line = char(lines(j));
        if contains(line, 'NORMAL TERMINATION') || contains(line, '********************************************************************************')
            break
        end
        if contains(line, '===  TOTAL NMR SHIELDING TENSOR (ppm)')
            [matrix, lastLine] = readFirstNumeric3x3(lines, j + 1, filename, ...
                sprintf('ADF total shielding tensor for atom %d', atomID));
            tensors(end+1).AtomID = atomID; %#ok<AGROW>
            tensors(end).Matrix = matrix;
            j = lastLine + 1;
            continue
        end
        j = j + 1;
    end
    j = j + 1;
end
if isempty(tensors)
    error('spinachgui:InvalidADF', 'No ADF total shielding tensors found after line %d in %s.', markerLine, filename);
end
end

function couplings = readJCouplingSection(lines, markerLine, filename)
couplings = struct('A', {}, 'B', {}, 'Value', {});
seenPairs = zeros(0, 2);
j = markerLine + 1;
while j <= numel(lines)
    line = char(lines(j));
    if contains(line, 'NORMAL TERMINATION')
        break
    end
    pair = parseJPair(line);
    if isempty(pair)
        j = j + 1;
        continue
    end

    sortedPair = sort(pair);
    shouldImport = ~ismember(sortedPair, seenPairs, 'rows');
    if shouldImport
        seenPairs(end+1, :) = sortedPair; %#ok<AGROW>
    end
    while j <= numel(lines)
        line = char(lines(j));
        if contains(line, 'NORMAL TERMINATION') || contains(line, 'Principal Axis Representation')
            break
        end
        if shouldImport && contains(line, 'total calculated spin-spin coupling:')
            if j + 1 > numel(lines)
                error('spinachgui:InvalidADF', 'Truncated ADF J-coupling value after line %d in %s.', j, filename);
            end
            value = parseJValue(char(lines(j + 1)));
            if isnan(value)
                error('spinachgui:InvalidADF', 'Invalid ADF J-coupling value at line %d in %s.', j + 1, filename);
            end
            couplings(end+1).A = pair(1); %#ok<AGROW>
            couplings(end).B = pair(2);
            couplings(end).Value = value;
            shouldImport = false;
        end
        j = j + 1;
    end
    j = j + 1;
end
if isempty(couplings)
    error('spinachgui:InvalidADF', 'No ADF total J-couplings found after line %d in %s.', markerLine, filename);
end
end

function addShieldingInteractions(model, tensors)
for k = 1:numel(tensors)
    atomID = tensors(k).AtomID;
    requireAtom(model, atomID, 'ADF shielding tensor');
    model.addInteraction("CShielding", atomID, atomID, tensors(k).Matrix, "ppm", "", 1, "", "ADF shielding");
end
end

function addJCouplingInteractions(model, couplings)
for k = 1:numel(couplings)
    atomA = couplings(k).A;
    atomB = couplings(k).B;
    requireAtom(model, atomA, 'ADF J-coupling');
    requireAtom(model, atomB, 'ADF J-coupling');
    model.addInteraction("Jcoupling", atomA, atomB, couplings(k).Value * eye(3), "Hz", "", 1, "", "ADF J coupling");
end
end

function [atomID, nextLine] = readADFAtomID(lines, nucleusLine, filename)
atomID = parseADFAtomID(char(lines(nucleusLine)));
nextLine = nucleusLine + 1;
for j = nucleusLine+1:min(numel(lines), nucleusLine+6)
    candidate = parseADFAtomID(char(lines(j)));
    if ~isnan(candidate) && contains(char(lines(j)), 'ADF-GUI atom:')
        atomID = candidate;
        nextLine = j + 1;
        break
    end
end
if isnan(atomID)
    error('spinachgui:InvalidADF', 'Could not parse ADF atom index near line %d in %s.', nucleusLine, filename);
end
end

function atomID = parseADFAtomID(line)
match = regexp(line, '[A-Za-z][a-z]?\((\d+)\)', 'tokens', 'once');
if isempty(match)
    atomID = NaN;
else
    atomID = str2double(match{1});
end
end

function pair = parseJPair(line)
match = regexp(line, 'Nucleus\s+(\d+)\s+\([^)]*\)\s+perturbing\s+nucleus\s+(\d+)\s+\([^)]*\)', 'tokens', 'once');
if isempty(match)
    pair = [];
else
    pair = [str2double(match{1}), str2double(match{2})];
end
end

function value = parseJValue(line)
match = regexp(line, 'j\s*=\s*([-+]?(?:\d+\.?\d*|\.\d+)(?:[dDeE][-+]?\d+)?)', 'tokens', 'once');
if isempty(match)
    value = NaN;
else
    value = parseNumber(match(1));
end
end

function [matrix, lastLine] = readFirstNumeric3x3(lines, startLine, filename, context)
firstLine = [];
for j = startLine:min(numel(lines), startLine+14)
    fields = splitFields(char(lines(j)));
    if numel(fields) == 3
        values = parseNumber(fields);
        if all(~isnan(values))
            firstLine = j;
            break
        end
    end
end
if isempty(firstLine) || firstLine + 2 > numel(lines)
    error('spinachgui:InvalidADF', 'Truncated %s near line %d in %s.', context, startLine, filename);
end
matrix = zeros(3);
for r = 1:3
    lineNumber = firstLine + r - 1;
    fields = splitFields(char(lines(lineNumber)));
    if numel(fields) ~= 3
        error('spinachgui:InvalidADF', 'Expected three fields in %s row at line %d in %s.', context, lineNumber, filename);
    end
    values = parseNumber(fields);
    if any(isnan(values))
        error('spinachgui:InvalidADF', 'Invalid numeric value in %s row at line %d in %s.', context, lineNumber, filename);
    end
    matrix(r, :) = values;
end
lastLine = firstLine + 2;
end

function isotope = isotopeLabelForADF(elementToken, mass)
element = canonicalElement(elementToken);
if mass > 0 && isExactKnownIsotope(element, mass)
    isotope = string(mass) + element;
    return
end
isotope = element;
end

function tf = isExactKnownIsotope(element, mass)
tableOut = spinachgui.isotopeTable();
tf = any(tableOut.Element == element & tableOut.Mass == mass);
end

function requireAtom(model, atomID, context)
if ~any(model.Atoms.ID == atomID)
    error('spinachgui:InvalidADF', '%s refers to missing atom %d.', context, atomID);
end
end

function fields = splitFields(line)
fields = regexp(strtrim(line), '[\s,=]+', 'split');
fields = fields(~cellfun('isempty', fields));
end

function numbers = parseNumber(tokens)
if ischar(tokens) || isstring(tokens)
    tokens = cellstr(tokens);
end
numbers = zeros(1, numel(tokens));
for k = 1:numel(tokens)
    token = regexprep(char(tokens{k}), '[dD]', 'E');
    numbers(k) = str2double(token);
end
end

function element = canonicalElement(token)
token = char(string(token));
if isscalar(token)
    element = string(upper(token));
else
    element = string([upper(token(1)), lower(token(2:end))]);
end
end
