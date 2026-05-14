function model = readGaussian(filename)
%READGAUSSIAN Import Gaussian/GaussView coordinates into a SpinachGUI model.
%   This slice implements the legacy last-frame-wins coordinate import and
%   isotope-symbol handling. Tensor sections are added in later parity slices.

lines = readlines(filename, 'EmptyLineRule', 'read');
isotopes = gaussianIsotopes(lines);
frames = {};
for k = 1:numel(lines)
    line = char(lines(k));
    if contains(line, 'Standard orientation:') || contains(line, 'Input orientation:')
        atoms = readOrientationFrame(lines, k, isotopes, filename);
        if ~isempty(atoms)
            frames{end+1} = atoms; %#ok<AGROW>
        end
    end
end

if isempty(frames)
    error('spinachgui:UnsupportedGaussian', 'No Gaussian coordinate section was found in %s.', filename);
end

model = spinachgui.Model();
model.SourceFile = string(filename);
atoms = frames{end};
for k = 1:numel(atoms)
    model.addAtom(atoms(k).Isotope, atoms(k).XYZ, "");
end
model.rebuildAutoBonds();
model.Dirty = false;
end

function isotopes = gaussianIsotopes(lines)
isotopes = strings(0,1);
for k = 1:numel(lines)
    if ~contains(char(lines(k)), 'Multiplicity =')
        continue
    end
    j = k + 1;
    if j <= numel(lines) && contains(char(lines(j)), 'Symbolic')
        j = j + 1;
    end
    current = strings(0,1);
    while j <= numel(lines)
        line = strtrim(char(lines(j)));
        if line == ""
            break
        end
        fields = regexp(line, '[,\s]+', 'split');
        token = fields{1};
        isotope = normalizeGaussianIsotope(token);
        if isotope == ""
            break
        end
        current(end+1,1) = isotope; %#ok<AGROW>
        j = j + 1;
    end
    if ~isempty(current)
        isotopes = current;
    end
end
end

function isotope = normalizeGaussianIsotope(token)
token = string(strtrim(token));
if token == ""
    isotope = "";
    return
end
mass = regexp(token, 'Iso\s*=\s*(\d+)', 'tokens', 'once');
element = regexp(token, '^[A-Za-z][A-Za-z]?', 'match', 'once');
if isempty(element)
    isotope = "";
    return
end
element = upper(extractBefore(string(element) + " ", 2)) + lower(extractAfter(string(element), 1));
if ~isempty(mass)
    isotope = string(mass{1}) + element;
else
    isotope = element;
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
    xyz = str2double(fields(4:6));
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
