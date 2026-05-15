function model = readOrca(filename)
%READORCA Import ORCA output into a SpinachGUI model.
%   This reader preserves legacy last-frame-wins coordinate semantics and the
%   historical SpinachGUI treatment of ORCA direct tensor sections.

lines = readlines(filename, 'EmptyLineRule', 'read');
frames = {};
shiftSections = {};
hfcSections = {};
quadrupolarSections = {};
gTensor = [];
zfsTensor = [];
hfcSectionSeen = false;
readAnySection = false;

for k = 1:numel(lines)
    marker = strtrim(char(lines(k)));
    if strcmp(marker, 'CARTESIAN COORDINATES (A.U.)')
        atoms = readCoordinateFrame(lines, k, filename);
        if ~isempty(atoms)
            frames{end+1} = atoms; %#ok<AGROW>
        end
        readAnySection = true;
    elseif strcmp(marker, 'The g-matrix:')
        [gTensor, ~] = readFirstNumeric3x3(lines, k + 1, filename, 'ORCA g tensor');
        readAnySection = true;
    elseif strcmp(marker, 'ZERO-FIELD-SPLITTING TENSOR')
        zfsTensor = readZeroFieldTensor(lines, k, filename);
        readAnySection = true;
    elseif strcmp(marker, 'CHEMICAL SHIFTS')
        shiftSections{end+1} = readChemicalShiftSection(lines, k, filename); %#ok<AGROW>
        readAnySection = true;
    elseif strcmp(marker, 'ELECTRIC AND MAGNETIC HYPERFINE STRUCTURE')
        [hfcs, quads] = readHfcQuadrupolarSection(lines, k, filename);
        hfcSections{end+1} = hfcs; %#ok<AGROW>
        quadrupolarSections{end+1} = quads; %#ok<AGROW>
        hfcSectionSeen = true;
        readAnySection = true;
    end
end

if ~readAnySection
    error('spinachgui:UnsupportedOrca', 'No recognized ORCA section was found in %s.', filename);
end

model = spinachgui.Model();
model.SourceFile = string(filename);
if ~isempty(frames)
    atoms = frames{end};
    for k = 1:numel(atoms)
        model.addAtom(atoms(k).Isotope, atoms(k).XYZ, "");
    end
    model.rebuildAutoBonds();
end

if ~isempty(gTensor)
    electronID = ensurePseudoAtom(model, "e");
    model.addInteraction("GTensor", electronID, electronID, gTensor, ...
        "Unitless", "", 1, "", "ORCA g tensor");
end
if ~isempty(zfsTensor)
    electronID = ensurePseudoAtom(model, "e");
    model.addInteraction("ZFS", electronID, electronID, zfsTensor, ...
        "cm^-1", "", 1, "", "ORCA zero-field splitting");
end
if ~isempty(shiftSections)
    addChemicalShiftInteractions(model, shiftSections{end});
end
if hfcSectionSeen
    electronID = ensureHfcElectron(model);
    if ~isempty(quadrupolarSections)
        addQuadrupolarInteractions(model, quadrupolarSections{end});
    end
    if ~isempty(hfcSections)
        addHfcInteractions(model, hfcSections{end}, electronID);
    end
end

model.Dirty = false;
end

function atoms = readCoordinateFrame(lines, markerLine, filename)
bohrToAngstrom = 0.529177249;
atoms = struct('Isotope', {}, 'XYZ', {});
for j = markerLine + 3:numel(lines)
    line = strtrim(char(lines(j)));
    if line == "" || contains(line, '--------')
        if ~isempty(atoms)
            return
        end
        continue
    end
    fields = regexp(line, '\s+', 'split');
    if numel(fields) ~= 8
        if isempty(atoms)
            continue
        end
        return
    end
    xyzAu = parseNumber(fields(6:8));
    mass = round(parseNumber(fields(5)));
    if any(isnan(xyzAu)) || isnan(mass)
        error('spinachgui:InvalidOrca', 'Invalid ORCA coordinates near line %d in %s.', j, filename);
    end
    atoms(end+1).Isotope = isotopeLabelForOrca(fields{2}, mass); %#ok<AGROW>
    atoms(end).XYZ = xyzAu * bohrToAngstrom;
end
end

function shifts = readChemicalShiftSection(lines, markerLine, filename)
shifts = struct('AtomID', {}, 'Matrix', {});
j = markerLine + 1;
while j <= numel(lines)
    line = char(lines(j));
    if contains(line, '****ORCA TERMINATED NORMALLY****') || ...
            contains(line, '-----------------------------------------')
        break
    end
    if ~contains(line, 'Nucleus')
        j = j + 1;
        continue
    end
    atomID = parseOrcaAtomID(line, filename, j);
    rawLine = findNextContaining(lines, j + 1, 'Raw-matrix :', 5);
    if isempty(rawLine)
        j = j + 1;
        continue
    end
    [matrix, lastLine] = readFirstNumeric3x3(lines, rawLine + 1, filename, ...
        sprintf('ORCA chemical shift tensor for atom %d', atomID));
    shifts(end+1).AtomID = atomID; %#ok<AGROW>
    shifts(end).Matrix = matrix;
    j = lastLine + 1;
end
end

function tensor = readZeroFieldTensor(lines, markerLine, filename)
rawLine = findNextContaining(lines, markerLine + 1, 'raw-matrix :', 8);
if isempty(rawLine)
    error('spinachgui:InvalidOrca', 'Missing ORCA ZFS raw matrix after line %d in %s.', markerLine, filename);
end
[tensor, ~] = readFirstNumeric3x3(lines, rawLine + 1, filename, 'ORCA zero-field splitting tensor');
end

function [hfcs, quads] = readHfcQuadrupolarSection(lines, markerLine, filename)
hfcs = struct('AtomID', {}, 'Matrix', {});
quads = struct('AtomID', {}, 'RawMatrix', {}, 'Qbarn', {});
j = markerLine + 1;
while j <= numel(lines)
    line = char(lines(j));
    if contains(line, '****ORCA TERMINATED NORMALLY****')
        break
    end
    if ~contains(line, 'Nucleus')
        j = j + 1;
        continue
    end
    atomID = parseOrcaAtomID(line, filename, j);
    if j + 1 > numel(lines)
        error('spinachgui:InvalidOrca', 'Truncated ORCA HFC/quadrupolar metadata after line %d in %s.', j, filename);
    end
    qFields = splitFields(char(lines(j + 1)));
    if numel(qFields) ~= 7
        error('spinachgui:InvalidOrca', 'Expected seven fields in ORCA quadrupolar metadata at line %d in %s.', j + 1, filename);
    end
    qbarn = parseNumber(qFields(6));
    if isnan(qbarn)
        error('spinachgui:InvalidOrca', 'Invalid ORCA quadrupolar factor at line %d in %s.', j + 1, filename);
    end
    j = j + 2;
    if j <= numel(lines) && strcmp(strtrim(char(lines(j))), '-----------------------------------------------------------')
        j = j + 1;
    end
    while j <= numel(lines)
        line = char(lines(j));
        if contains(line, '****ORCA TERMINATED NORMALLY****')
            return
        end
        if strcmp(strtrim(line), '-----------------------------------------------------------')
            j = j + 1;
            break
        end
        if contains(line, 'Raw HFC matrix (all values in MHz):')
            [matrix, lastLine] = readFirstNumeric3x3(lines, j + 1, filename, ...
                sprintf('ORCA HFC tensor for atom %d', atomID));
            hfcs(end+1).AtomID = atomID; %#ok<AGROW>
            hfcs(end).Matrix = matrix;
            j = lastLine + 1;
        elseif contains(line, 'Raw EFG matrix (all values in a.u.**-3):')
            [matrix, lastLine] = readFirstNumeric3x3(lines, j + 1, filename, ...
                sprintf('ORCA EFG tensor for atom %d', atomID));
            quads(end+1).AtomID = atomID; %#ok<AGROW>
            quads(end).RawMatrix = matrix;
            quads(end).Qbarn = qbarn;
            j = lastLine + 1;
        else
            j = j + 1;
        end
    end
end
end

function addChemicalShiftInteractions(model, shifts)
for k = 1:numel(shifts)
    atomID = shifts(k).AtomID;
    requireAtom(model, atomID, 'ORCA chemical shift');
    model.addInteraction("Shift", atomID, atomID, shifts(k).Matrix, ...
        "MHz", "", 1, "", "ORCA chemical shift");
end
end

function addHfcInteractions(model, hfcs, electronID)
for k = 1:numel(hfcs)
    atomID = hfcs(k).AtomID;
    requireAtom(model, atomID, 'ORCA HFC');
    model.addInteraction("HFC", atomID, electronID, hfcs(k).Matrix, ...
        "Gauss", "", 1, "", "ORCA raw HFC");
end
end

function addQuadrupolarInteractions(model, quads)
factor = 2.3496e+02;
for k = 1:numel(quads)
    atomID = quads(k).AtomID;
    if ~hasAtom(model, atomID)
        warning('spinachgui:InvalidOrcaQuadrupole', ...
            'Skipping ORCA quadrupolar tensor for missing atom %d.', atomID);
        continue
    end
    if abs(quads(k).Qbarn) == 0 || norm(quads(k).RawMatrix, 'fro') == 0
        continue
    end
    isotope = isotopeForQuadrupole(model, atomID);
    if isempty(isotope) || isotope.Spin <= 0.5
        warning('spinachgui:InvalidOrcaQuadrupole', ...
            'Skipping ORCA quadrupolar tensor for atom %d: no spin > 1/2 isotope is available.', atomID);
        continue
    end
    denominator = 2 * isotope.Spin * (2 * isotope.Spin - 1);
    if denominator <= 0
        continue
    end
    matrix = quads(k).RawMatrix * factor * quads(k).Qbarn / denominator;
    if all(isfinite(matrix), 'all') && norm(matrix, 'fro') > 0
        setAtomIsotope(model, atomID, isotope);
        model.addInteraction("Quadrupolar", atomID, atomID, matrix, ...
            "MHz", "", 1, "", "ORCA EFG quadrupolar");
    end
end
end

function [matrix, lastLine] = readFirstNumeric3x3(lines, startLine, filename, context)
firstLine = [];
for j = startLine:min(numel(lines), startLine + 8)
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
    error('spinachgui:InvalidOrca', 'Truncated %s near line %d in %s.', context, startLine, filename);
end
matrix = zeros(3);
for r = 1:3
    lineNumber = firstLine + r - 1;
    fields = splitFields(char(lines(lineNumber)));
    if numel(fields) ~= 3
        error('spinachgui:InvalidOrca', 'Expected three fields in %s row at line %d in %s.', context, lineNumber, filename);
    end
    values = parseNumber(fields);
    if any(isnan(values))
        error('spinachgui:InvalidOrca', 'Invalid numeric value in %s row at line %d in %s.', context, lineNumber, filename);
    end
    matrix(r, :) = values;
end
lastLine = firstLine + 2;
end

function lineNumber = findNextContaining(lines, startLine, marker, maxLookahead)
lineNumber = [];
for j = startLine:min(numel(lines), startLine + maxLookahead)
    if contains(char(lines(j)), marker)
        lineNumber = j;
        return
    end
end
end

function atomID = parseOrcaAtomID(line, filename, lineNumber)
match = regexp(line, 'Nucleus\s+(\d+)[A-Za-z]*', 'tokens', 'once');
if isempty(match)
    error('spinachgui:InvalidOrca', 'Could not parse ORCA atom index at line %d in %s.', lineNumber, filename);
end
atomID = spinachgui.parseNumber(match{1}) + 1;
if isnan(atomID)
    error('spinachgui:InvalidOrca', 'Invalid ORCA atom index at line %d in %s.', lineNumber, filename);
end
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

function isotope = isotopeLabelForOrca(elementToken, mass)
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

function element = canonicalElement(token)
token = char(string(token));
if isscalar(token)
    element = string(upper(token));
else
    element = string([upper(token(1)), lower(token(2:end))]);
end
end

function id = ensurePseudoAtom(model, isotopeName)
rows = find(model.Atoms.Element == isotopeName);
if ~isempty(rows)
    id = model.Atoms.ID(rows(1));
    model.Atoms.X(rows(1)) = 0;
    model.Atoms.Y(rows(1)) = 0;
    model.Atoms.Z(rows(1)) = 0;
    return
end
id = model.addAtom(isotopeName, [0 0 0], "");
end

function electronID = ensureHfcElectron(model)
electronID = ensurePseudoAtom(model, "e");
if ~any(model.Interactions.Kind == "GTensor")
    model.addInteraction("GTensor", electronID, electronID, ...
        diag([2.0023 2.0023 2.0023]), "Unitless", "", 1, "", ...
        "ORCA default electron g tensor");
end
end

function requireAtom(model, atomID, context)
if ~hasAtom(model, atomID)
    error('spinachgui:InvalidOrca', '%s refers to missing atom %d.', context, atomID);
end
end

function present = hasAtom(model, atomID)
present = any(model.Atoms.ID == atomID);
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
    upgraded = firstHigherSpinIsotope(string(isotope.Element));
    if isempty(upgraded)
        isotope = [];
    else
        isotope = upgraded;
    end
end
end

function isotope = firstHigherSpinIsotope(element)
t = spinachgui.isotopeTable();
elements = string(t.Element);
idx = find(elements == string(element) & t.Spin > 0.5, 1);
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
