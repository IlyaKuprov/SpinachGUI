function model = readSpinXML(filename)
%READSPINXML Import SpinXML/SXML into a SpinachGUI model.
%   This parser intentionally avoids Java XML dependencies so core import
%   tests can run in MATLAB -nojvm.  It covers the SpinXML structure emitted
%   by the historical SpinachGUI exporter.

text = fileread(filename);
model = spinachgui.Model();
model.SourceFile = string(filename);

frameBlocks = regexp(text, '<reference_frame\s+([^>]*)>([\s\S]*?)</reference_frame>', 'tokens');
for k = 1:numel(frameBlocks)
    attrs = parseAttrs(frameBlocks{k}{1});
    body = frameBlocks{k}{2};
    matrix = parseMatrixTag(body, 'dcm');
    if isempty(matrix), matrix = eye(3); end
    id = attrNumber(attrs, 'id', k);
    label = attrString(attrs, 'label', "");
    parent = attrNumber(attrs, 'parent_id', NaN);
    model.addReferenceFrame(matrix, label, parent, "SpinXML", id == 1, id);
end
if isempty(model.ReferenceFrames)
    model.addReferenceFrame(eye(3), "Lab", NaN, "SpinXML", true);
end

spinBlocks = regexp(text, '<spin\s+([^>]*)>([\s\S]*?)</spin>', 'tokens');
for k = 1:numel(spinBlocks)
    attrs = parseAttrs(spinBlocks{k}{1});
    body = spinBlocks{k}{2};
    isotope = attrString(attrs, 'isotope', "");
    label = attrString(attrs, 'label', "");
    coord = parseCoords(body);
    model.addAtom(isotope, coord, label);
end

interactionBlocks = regexp(text, '<interaction\s+([^>]*)>([\s\S]*?)</interaction>', 'tokens');
for k = 1:numel(interactionBlocks)
    attrs = parseAttrs(interactionBlocks{k}{1});
    body = interactionBlocks{k}{2};
    kind = attrString(attrs, 'kind', "Unknown");
    atomA = attrNumber(attrs, 'spin_a', NaN);
    atomB = attrNumber(attrs, 'spin_b', atomA);
    unitName = attrString(attrs, 'units', "Unknown");
    label = attrString(attrs, 'label', "");
    refID = attrNumber(attrs, 'reference_frame_id', NaN);
    reference = attrString(attrs, 'reference', "");
    matrix = parseMatrixTag(body, 'tensor');
    model.addInteraction(kind, atomA, atomB, matrix, unitName, label, refID, reference, "SpinXML");
end
model.Dirty = false;
end

function attrs = parseAttrs(attrText)
attrs = containers.Map('KeyType', 'char', 'ValueType', 'char');
parts = regexp(attrText, '([A-Za-z_][A-Za-z0-9_:-]*)\s*=\s*"([^"]*)"', 'tokens');
for n = 1:numel(parts)
    attrs(parts{n}{1}) = parts{n}{2};
end
end

function value = attrString(attrs, key, defaultValue)
if isKey(attrs, key)
    value = string(attrs(key));
else
    value = string(defaultValue);
end
end

function value = attrNumber(attrs, key, defaultValue)
if isKey(attrs, key)
    value = str2double(attrs(key));
    if isnan(value), value = defaultValue; end
else
    value = defaultValue;
end
end

function xyz = parseCoords(body)
coord = regexp(body, '<coordinates\s+([^>]*)/>', 'tokens', 'once');
if isempty(coord)
    xyz = [0 0 0];
    return
end
attrs = parseAttrs(coord{1});
xyz = [attrNumber(attrs, 'x', 0), attrNumber(attrs, 'y', 0), attrNumber(attrs, 'z', 0)];
end

function matrix = parseMatrixTag(body, tag)
expr = ['<' tag '\s+([^>]*)/>'];
match = regexp(body, expr, 'tokens', 'once');
if isempty(match)
    matrix = [];
    return
end
attrs = parseAttrs(match{1});
keys = {'xx','xy','xz'; 'yx','yy','yz'; 'zx','zy','zz'};
matrix = zeros(3);
for r = 1:3
    for c = 1:3
        matrix(r,c) = attrNumber(attrs, keys{r,c}, 0);
    end
end
end
