function model = readGaussian(filename)
%READGAUSSIAN Import Gaussian/GaussView output into a SpinachGUI model.
%   This reader preserves the legacy last-frame-wins coordinate semantics and
%   imports direct 3x3 Gaussian tensor sections implemented in this slice:
%   chemical shielding, electron g tensor, magnetic susceptibility, and
%   nuclear quadrupolar couplings.

lines = readlines(filename, 'EmptyLineRule', 'read');
isotopes = gaussianIsotopes(lines);
frames = {};
shieldingSections = {};
gTensor = [];
chiTensor = [];
quadrupolarSections = {};
readAnySection = false;

for k = 1:numel(lines)
    line = char(lines(k));
    if contains(line, 'Standard orientation:') || contains(line, 'Input orientation:')
        atoms = readOrientationFrame(lines, k, isotopes, filename);
        if ~isempty(atoms)
            frames{end+1} = atoms; %#ok<AGROW>
            readAnySection = true;
        end
    elseif contains(line, 'SCF GIAO Magnetic shielding tensor (ppm):')
        shieldingSections{end+1} = readShieldingSection(lines, k, filename); %#ok<AGROW>
        readAnySection = true;
    elseif contains(line, 'g tensor [g = g_e + g_RMC + g_DC + g_OZ/SOC]:')
        gTensor = readLabeled3x3(lines, k + 1, filename, 'Gaussian g tensor');
        readAnySection = true;
    elseif contains(line, 'Magnetic susceptibility (cgs-ppm)')
        chiTensor = readLabeled3x3(lines, k + 1, filename, 'Gaussian magnetic susceptibility tensor');
        readAnySection = true;
    elseif contains(line, 'Nuclear quadrupole coupling constants [Chi] (MHz):')
        quadrupolarSections{end+1} = readQuadrupolarSection(lines, k, filename); %#ok<AGROW>
        readAnySection = true;
    end
end

if ~readAnySection
    error('spinachgui:UnsupportedGaussian', 'No recognized Gaussian section was found in %s.', filename);
end
if isempty(frames) && (~isempty(shieldingSections) || ~isempty(quadrupolarSections))
    error('spinachgui:InvalidGaussian', 'Gaussian tensor sections requiring nuclei were found, but no coordinate section was found in %s.', filename);
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

if ~isempty(shieldingSections)
    addShieldingInteractions(model, shieldingSections{end});
end
if ~isempty(gTensor)
    electronID = ensurePseudoAtom(model, "e");
    model.addInteraction("GTensor", electronID, electronID, gTensor, "Bohr magneton", "", 1, "", "Gaussian g tensor");
end
if ~isempty(chiTensor)
    chiID = ensurePseudoAtom(model, "chi");
    model.addInteraction("CHITensor", chiID, chiID, chiTensor, "Bohr magneton", "", 1, "", "Gaussian magnetic susceptibility");
end
if ~isempty(quadrupolarSections)
    addQuadrupolarInteractions(model, quadrupolarSections{end});
end

model.Dirty = false;
end

function isotopes = gaussianIsotopes(lines)
isotopes = strings(0,1);
for k = 1:numel(lines)
    if ~contains(char(lines(k)), 'Multiplicity =')
        continue
    end
    j = k + 1;
    current = strings(0,1);
    while j <= numel(lines)
        line = strtrim(char(lines(j)));
        if line == ""
            if isempty(current)
                j = j + 1;
                continue
            end
            break
        end
        if contains(line, 'Symbolic') || contains(line, 'Z-Matrix') || contains(line, 'Redundant internal coordinates')
            j = j + 1;
            continue
        end
        fields = regexp(line, '[,\s]+', 'split');
        token = fields{1};
        isotope = normalizeGaussianIsotope(token);
        if isotope == ""
            if isempty(current)
                j = j + 1;
                continue
            end
            break
        end
        current(end+1,1) = isotope; %#ok<AGROW>
        j = j + 1;
    end
    if ~isempty(current)
        isotopes = mergeSpecificIsotopes(isotopes, current);
    end
end
if isempty(isotopes)
    isotopes = distanceMatrixIsotopes(lines);
end
end

function isotopes = mergeSpecificIsotopes(oldIsotopes, newIsotopes)
isotopes = newIsotopes;
if numel(oldIsotopes) ~= numel(newIsotopes)
    return
end
for k = 1:numel(newIsotopes)
    [newElement, newHasMass] = splitIsotopeLabel(newIsotopes(k));
    [oldElement, oldHasMass] = splitIsotopeLabel(oldIsotopes(k));
    if ~newHasMass && oldHasMass && newElement == oldElement
        isotopes(k) = oldIsotopes(k);
    end
end
end

function isotope = normalizeGaussianIsotope(token)
token = string(strtrim(token));
if token == ""
    isotope = "";
    return
end
mass = regexp(char(token), 'Iso\s*=\s*(\d+)', 'tokens', 'once');
if isempty(mass)
    mass = regexp(char(token), '^([A-Za-z][a-z]?)\((\d+)\)$', 'tokens', 'once');
    if ~isempty(mass)
        mass = mass(2);
    end
end
element = regexp(char(token), '^([A-Za-z][a-z]?)(?=$|\(|\d)', 'tokens', 'once');
if isempty(element)
    isotope = "";
    return
end
element = canonicalElement(element{1});
if ~isempty(mass)
    isotope = string(mass{1}) + element;
else
    isotope = element;
end
end

function isotopes = distanceMatrixIsotopes(lines)
% Compatibility repair: the old C++ branch was normally inert, but Gaussian
% distance-matrix rows provide usable element symbols when no Z-matrix list was
% found.
isotopes = strings(0,1);
for k = 1:numel(lines)
    if ~contains(char(lines(k)), 'Distance matrix (angstroms):')
        continue
    end
    current = strings(0,1);
    for j = k+1:numel(lines)
        line = strtrim(char(lines(j)));
        if line == ""
            if ~isempty(current)
                break
            end
            continue
        end
        fields = regexp(line, '\s+', 'split');
        if numel(fields) < 2
            if ~isempty(current), break, end
            continue
        end
        atomIndex = str2double(fields{1});
        isotope = normalizeGaussianIsotope(fields{2});
        if isnan(atomIndex) || isotope == ""
            if ~isempty(current), break, end
            continue
        end
        current(end+1,1) = isotope; %#ok<AGROW>
    end
    if ~isempty(current)
        warning('spinachgui:GaussianDistanceMatrixIsotopes', ...
            'Using Gaussian distance-matrix isotope fallback near line %d.', k);
        isotopes = current;
    end
end
end

function atoms = readOrientationFrame(lines, markerLine, isotopes, filename)
startLine = markerLine + 5;
atoms = struct('Isotope', {}, 'XYZ', {});
for j = startLine:numel(lines)
    line = char(lines(j));
    if contains(line, '--------')
        if isempty(atoms)
            continue
        end
        return
    end
    fields = regexp(strtrim(line), '\s+', 'split');
    if numel(fields) ~= 6
        continue
    end
    atomIndex = str2double(fields{1});
    atomicNumber = str2double(fields{2});
    xyz = parseNumber(fields(4:6));
    if isnan(atomIndex) || isnan(atomicNumber) || any(isnan(xyz))
        continue
    end
    if atomIndex <= numel(isotopes)
        isotope = isotopes(atomIndex);
    else
        isotope = elementFromAtomicNumber(atomicNumber);
    end
    atoms(end+1).Isotope = isotope; %#ok<AGROW>
    atoms(end).XYZ = xyz;
end
if isempty(atoms)
    error('spinachgui:InvalidGaussian', 'Malformed Gaussian orientation section near line %d in %s.', markerLine, filename);
end
end

function tensors = readShieldingSection(lines, markerLine, filename)
tensors = struct('AtomID', {}, 'Matrix', {});
j = markerLine + 1;
while j <= numel(lines)
    header = strtrim(char(lines(j)));
    if header == ""
        j = j + 1;
        continue
    end
    fields = regexp(header, '\s+', 'split');
    atomID = NaN;
    if ~isempty(fields)
        atomID = str2double(fields{1});
    end
    if isnan(atomID) || ~contains(header, 'Isotropic')
        break
    end
    matrix = readLabeled3x3(lines, j + 1, filename, sprintf('Gaussian shielding tensor for atom %d', atomID));
    tensors(end+1).AtomID = atomID; %#ok<AGROW>
    tensors(end).Matrix = matrix;
    j = j + 5; % header + 3 rows + Eigenvalues line
end
if isempty(tensors)
    error('spinachgui:InvalidGaussian', 'No shielding tensors found after line %d in %s.', markerLine, filename);
end
end

function addShieldingInteractions(model, tensors)
for k = 1:numel(tensors)
    atomID = tensors(k).AtomID;
    if atomID < 1 || atomID > height(model.Atoms)
        error('spinachgui:InvalidGaussian', 'Gaussian shielding tensor refers to missing atom %d.', atomID);
    end
    model.addInteraction("CShielding", atomID, atomID, tensors(k).Matrix, "ppm", "", 1, "", "Gaussian shielding");
end
end

function quads = readQuadrupolarSection(lines, markerLine, filename)
quads = struct('AtomID', {}, 'Isotope', {}, 'Matrix', {});
j = markerLine + 1;
while j <= numel(lines)
    header = strtrim(char(lines(j)));
    if header == ""
        j = j + 1;
        continue
    end
    fields = regexp(header, '\s+', 'split');
    if numel(fields) ~= 2
        break
    end
    atomID = str2double(fields{1});
    if isnan(atomID)
        break
    end
    isotope = quadrupolarHeaderIsotope(fields{2});
    matrix = readLabeled3x3(lines, j + 1, filename, sprintf('Gaussian quadrupolar tensor for atom %d', atomID));
    if norm(matrix, 'fro') > 0
        quads(end+1).AtomID = atomID; %#ok<AGROW>
        quads(end).Isotope = isotope;
        quads(end).Matrix = matrix;
    end
    j = j + 4;
end
end

function addQuadrupolarInteractions(model, quads)
for k = 1:numel(quads)
    atomID = quads(k).AtomID;
    if atomID < 1 || atomID > height(model.Atoms)
        warning('spinachgui:InvalidGaussianQuadrupole', ...
            'Skipping Gaussian quadrupolar tensor for missing atom %d.', atomID);
        continue
    end
    isotope = isotopeForQuadrupole(model, atomID, quads(k).Isotope);
    if isempty(isotope)
        warning('spinachgui:InvalidGaussianQuadrupole', ...
            'Skipping Gaussian quadrupolar tensor for atom %d: no spin > 1/2 isotope is available.', atomID);
        continue
    end
    setAtomIsotope(model, atomID, isotope);
    model.addInteraction("Quadrupolar", atomID, atomID, quads(k).Matrix, "MHz", "", 1, "", "Gaussian quadrupolar");
end
end

function isotope = isotopeForQuadrupole(model, atomID, preferredLabel)
isotope = [];
try
    if strlength(preferredLabel) > 0
        isotope = spinachgui.findIsotope(preferredLabel);
    end
catch
    isotope = [];
end
if isempty(isotope)
    row = find(model.Atoms.ID == atomID, 1);
    label = isotopeLabelFromAtomRow(model.Atoms(row, :));
    try
        isotope = spinachgui.findIsotope(label);
    catch
        isotope = [];
    end
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

function matrix = readLabeled3x3(lines, startLine, filename, context)
if startLine + 2 > numel(lines)
    error('spinachgui:InvalidGaussian', 'Truncated %s near line %d in %s.', context, startLine, filename);
end
matrix = zeros(3);
for r = 1:3
    lineNumber = startLine + r - 1;
    fields = splitFields(char(lines(lineNumber)));
    if numel(fields) ~= 6
        error('spinachgui:InvalidGaussian', 'Expected six fields in %s row at line %d in %s.', context, lineNumber, filename);
    end
    values = parseNumber(fields([2 4 6]));
    if any(isnan(values))
        error('spinachgui:InvalidGaussian', 'Invalid numeric value in %s row at line %d in %s.', context, lineNumber, filename);
    end
    matrix(r, :) = values;
end
end

function fields = splitFields(line)
fields = regexp(strtrim(line), '[\s,=]+', 'split');
fields = fields(~cellfun('isempty', fields));
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

function isotope = quadrupolarHeaderIsotope(token)
token = char(string(token));
m = regexp(token, '^([A-Za-z][a-z]?)(?:\((\d+)\)|(\d+))?$', 'tokens', 'once');
if isempty(m)
    isotope = "";
    return
end
element = canonicalElement(m{1});
mass = "";
if numel(m) >= 2 && ~isempty(m{2})
    mass = string(m{2});
elseif numel(m) >= 3 && ~isempty(m{3})
    mass = string(m{3});
end
if mass ~= ""
    isotope = mass + element;
else
    isotope = element;
end
end

function [element, hasMass] = splitIsotopeLabel(label)
label = string(label);
m = regexp(char(label), '^(\d+)?([A-Za-z][a-z]?|chi|e)$', 'tokens', 'once');
if isempty(m)
    element = "";
    hasMass = false;
    return
end
element = string(m{2});
hasMass = ~isempty(m{1});
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

function element = elementFromAtomicNumber(number)
symbols = ["", "H", "He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", ...
    "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", "K", "Ca", ...
    "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", ...
    "Ga", "Ge", "As", "Se", "Br", "Kr", "Rb", "Sr", "Y", "Zr", ...
    "Nb", "Mo", "Tc", "Ru", "Rh", "Pd", "Ag", "Cd", "In", "Sn", ...
    "Sb", "Te", "I", "Xe"];
if number > 0 && number <= numel(symbols)-1
    element = symbols(number+1);
else
    error('spinachgui:UnknownAtomicNumber', 'Unknown atomic number %g.', number);
end
end
