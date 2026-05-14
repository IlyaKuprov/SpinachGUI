function model = readXYZ(filename)
%READXYZ Import XYZ coordinates into a SpinachGUI model.

text = fileread(filename);
lines = regexp(text, '\r\n|\n|\r', 'split');
first = 1;
while first <= numel(lines) && isempty(strtrim(lines{first}))
    first = first + 1;
end
if first > numel(lines)
    error('spinachgui:XYZEmpty', 'XYZ file is empty.');
end
countTok = regexp(lines{first}, '(\d+)', 'tokens', 'once');
if isempty(countTok)
    error('spinachgui:XYZAtomCount', 'Could not read XYZ atom count from %s.', filename);
end
nAtoms = str2double(countTok{1});
model = spinachgui.Model();
model.SourceFile = string(filename);
startLine = first + 2;
for k = 1:nAtoms
    lineIndex = startLine + k - 1;
    if lineIndex > numel(lines)
        error('spinachgui:XYZShortFile', 'XYZ file ended before atom %d.', k);
    end
    fields = regexp(strtrim(lines{lineIndex}), '\s+', 'split');
    if numel(fields) < 4
        error('spinachgui:XYZBadAtomLine', 'Bad XYZ atom line %d.', lineIndex);
    end
    element = fields{1};
    xyz = str2double(fields(2:4));
    if any(isnan(xyz))
        error('spinachgui:XYZBadCoordinates', 'Bad XYZ coordinates on line %d.', lineIndex);
    end
    model.addAtom(element, xyz, "");
end
model.Dirty = false;
end
