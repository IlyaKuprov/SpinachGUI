function model = readOrca(filename)
%READORCA Import ORCA coordinates into a SpinachGUI model.
%   This slice implements legacy last-frame-wins A.U. coordinate import.
%   Quantum tensor sections are added in later parity slices.

lines = readlines(filename, 'EmptyLineRule', 'read');
frames = {};
for k = 1:numel(lines)
    if strcmp(strtrim(char(lines(k))), 'CARTESIAN COORDINATES (A.U.)')
        atoms = readCoordinateFrame(lines, k, filename);
        if ~isempty(atoms)
            frames{end+1} = atoms; %#ok<AGROW>
        end
    end
end

if isempty(frames)
    error('spinachgui:UnsupportedOrca', 'No ORCA coordinate section was found in %s.', filename);
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
    xyzAu = str2double(fields(6:8));
    if any(isnan(xyzAu))
        error('spinachgui:InvalidOrca', 'Invalid ORCA coordinates near line %d in %s.', j, filename);
    end
    atoms(end+1).Isotope = string(fields{2}); %#ok<AGROW>
    atoms(end).XYZ = xyzAu * bohrToAngstrom;
end
end
