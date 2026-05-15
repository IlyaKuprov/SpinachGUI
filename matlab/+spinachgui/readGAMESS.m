function model = readGAMESS(filename)
%READGAMESS Import GAMESS coordinates into a SpinachGUI model.
%   The legacy GAMESS importer scope is Cartesian geometry only. Optimised
%   Angstrom coordinate frames following "***** EQUILIBRIUM GEOMETRY LOCATED
%   *****" are preferred; old single-point/hessian outputs fall back to the
%   initial "COORDINATES (BOHR)" atom table.

lines = readlines(filename, 'EmptyLineRule', 'read');
coordinateFrames = {};

for k = 1:numel(lines)
    if contains(char(lines(k)), '***** EQUILIBRIUM GEOMETRY LOCATED *****')
        coordinateFrames{end+1} = readCoordinateFrame(lines, k, filename); %#ok<AGROW>
    end
end

if isempty(coordinateFrames)
    for k = 1:numel(lines)
        if contains(char(lines(k)), 'ATOM') && contains(char(lines(k)), 'COORDINATES (BOHR)')
            coordinateFrames{end+1} = readBohrCoordinateFrame(lines, k, filename); %#ok<AGROW>
        end
    end
end

if isempty(coordinateFrames)
    error('spinachgui:UnsupportedGAMESS', 'No recognized GAMESS coordinate section was found in %s.', filename);
end

atoms = coordinateFrames{end};
if isempty(atoms)
    error('spinachgui:InvalidGAMESS', 'No GAMESS coordinates were found in the last coordinate section in %s.', filename);
end

model = spinachgui.Model();
model.SourceFile = string(filename);
for k = 1:numel(atoms)
    model.addAtom(atoms(k).Isotope, atoms(k).XYZ, "");
end
model.rebuildAutoBonds();
model.Dirty = false;
end

function atoms = readCoordinateFrame(lines, markerLine, filename)
atoms = struct('Isotope', {}, 'XYZ', {});
startLine = markerLine + 4; % legacy reader skips three fixed header/dash lines
if startLine > numel(lines)
    error('spinachgui:InvalidGAMESS', 'Truncated GAMESS coordinate section after line %d in %s.', markerLine, filename);
end

for j = startLine:numel(lines)
    line = char(lines(j));
    if numel(line) <= 2
        return
    end
    fields = splitFields(line);
    if numel(fields) ~= 5
        error('spinachgui:InvalidGAMESS', 'Expected five fields in GAMESS coordinate row at line %d in %s.', j, filename);
    end
    xyz = parseNumber(fields(3:5));
    if any(isnan(xyz))
        error('spinachgui:InvalidGAMESS', 'Invalid GAMESS coordinate value at line %d in %s.', j, filename);
    end
    atoms(end+1).Isotope = canonicalElement(fields{1}); %#ok<AGROW>
    atoms(end).XYZ = xyz;
end
end

function atoms = readBohrCoordinateFrame(lines, markerLine, filename)
bohrToAngstrom = 0.529177210903;
atoms = struct('Isotope', {}, 'XYZ', {});
startLine = markerLine + 2;
if startLine > numel(lines)
    error('spinachgui:InvalidGAMESS', 'Truncated GAMESS Bohr coordinate section after line %d in %s.', markerLine, filename);
end

for j = startLine:numel(lines)
    line = char(lines(j));
    if isempty(strtrim(line))
        if ~isempty(atoms), return, end
        continue
    end
    fields = splitFields(line);
    if numel(fields) < 5 || isempty(regexp(fields{1}, '^[A-Za-z]+$', 'once'))
        if ~isempty(atoms), return, end
        continue
    end
    xyz = parseNumber(fields(3:5)) * bohrToAngstrom;
    if any(isnan(xyz))
        error('spinachgui:InvalidGAMESS', 'Invalid GAMESS Bohr coordinate value at line %d in %s.', j, filename);
    end
    atoms(end+1).Isotope = canonicalElement(fields{1}); %#ok<AGROW>
    atoms(end).XYZ = xyz;
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
    numbers(k) = spinachgui.parseNumber(tokens{k});
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
