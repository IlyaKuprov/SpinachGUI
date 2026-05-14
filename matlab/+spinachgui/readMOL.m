function model = readMOL(filename)
%READMOL Import an MDL MOL V2000 atom block into a SpinachGUI model.
%   Mirrors the legacy MOL importer: comments/counts are read, atom
%   coordinates and element symbols are imported, and explicit MOL bond
%   records are ignored because SpinachGUI creates display bonds itself.

lines = readlines(filename, 'EmptyLineRule', 'read');
if numel(lines) < 4
    error('spinachgui:InvalidMOL', 'MOL file is too short: %s', filename);
end
counts = regexp(char(lines(4)), '\S+', 'match');
if numel(counts) < 2
    error('spinachgui:InvalidMOL', 'Missing MOL counts line in %s.', filename);
end
atomCount = str2double(counts{1});
bondCount = str2double(counts{2});
if isnan(atomCount) || isnan(bondCount)
    error('spinachgui:InvalidMOL', 'Invalid MOL counts line in %s.', filename);
end
if numel(lines) < 4 + atomCount + bondCount
    error('spinachgui:InvalidMOL', 'Unexpected end of MOL file: %s', filename);
end

model = spinachgui.Model();
model.SourceFile = string(filename);
for k = 1:atomCount
    fields = regexp(char(lines(4+k)), '\S+', 'match');
    if numel(fields) < 4
        error('spinachgui:InvalidMOL', 'Invalid MOL atom line %d in %s.', 4+k, filename);
    end
    xyz = [str2double(fields{1}), str2double(fields{2}), str2double(fields{3})];
    if any(isnan(xyz))
        error('spinachgui:InvalidMOL', 'Invalid MOL coordinates on line %d in %s.', 4+k, filename);
    end
    model.addAtom(fields{4}, xyz, "");
end
model.rebuildAutoBonds();
model.Dirty = false;
end
