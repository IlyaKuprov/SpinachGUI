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
if ~contains(char(lines(4)), 'V2000')
    if contains(char(lines(4)), 'V3000')
        error('spinachgui:UnsupportedMOL', 'MOL V3000 files are not supported by this V2000 reader: %s.', filename);
    end
    error('spinachgui:InvalidMOL', 'MOL counts line must declare V2000 in %s.', filename);
end
atomCount = str2double(counts{1});
bondCount = str2double(counts{2});
if isnan(atomCount) || isnan(bondCount) || atomCount < 0 || bondCount < 0 || ...
        atomCount ~= fix(atomCount) || bondCount ~= fix(bondCount)
    error('spinachgui:InvalidMOL', 'MOL atom and bond counts must be non-negative integers in %s.', filename);
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
