function model = readXYZ(filename)
%READXYZ Import XYZ coordinates into a SpinachGUI model.

text = readTextFile(filename);
lines = regexp(text, '\r\n|\n|\r', 'split');
first = 1;
while first <= numel(lines) && isempty(strtrim(lines{first}))
    first = first + 1;
end
if first > numel(lines)
    error('spinachgui:XYZEmpty', 'XYZ file is empty.');
end
countTok = regexp(strtrim(lines{first}), '^(\d+)$', 'tokens', 'once');
if isempty(countTok)
    error('spinachgui:XYZAtomCount', 'Could not read XYZ atom count from %s.', filename);
end
nAtoms = spinachgui.parseNumber(countTok{1});
if ~isfinite(nAtoms) || nAtoms ~= fix(nAtoms)
    error('spinachgui:XYZAtomCount', 'XYZ atom count must be a non-negative integer in %s.', filename);
end
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
    xyz = spinachgui.parseNumber(fields(2:4));
    if any(isnan(xyz))
        error('spinachgui:XYZBadCoordinates', 'Bad XYZ coordinates on line %d.', lineIndex);
    end
    model.addAtom(element, xyz, "");
end
model.Dirty = false;
end

function text = readTextFile(filename)
fid = fopen(filename, 'r');
if fid < 0
    error('spinachgui:XYZOpenFailed', 'Could not open %s.', filename);
end
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, '*uint8').';
if numel(bytes) >= 2 && isequal(bytes(1:2), uint8([255 254]))
    text = native2unicode(bytes(3:end), 'UTF-16LE');
elseif numel(bytes) >= 2 && isequal(bytes(1:2), uint8([254 255]))
    text = native2unicode(bytes(3:end), 'UTF-16BE');
elseif numel(bytes) >= 3 && isequal(bytes(1:3), uint8([239 187 191]))
    text = native2unicode(bytes(4:end), 'UTF-8');
else
    text = native2unicode(bytes, 'UTF-8');
end
end
