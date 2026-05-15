function model = readSpinXML(filename)
%READSPINXML Import SpinXML/SXML into a SpinachGUI model.
%   This parser intentionally avoids Java XML dependencies so core import
%   tests can run in MATLAB -nojvm. It covers the SpinXML structure emitted
%   by the historical SpinachGUI exporter, including legacy zero-based spin
%   IDs, XML entities, scalar/eigenvalue tensor forms, and simple orientation
%   blocks.

text = fileread(filename);
model = spinachgui.Model();
model.SourceFile = string(filename);

frameBlocks = regexp(text, '<reference_frame\s+([^>]*)>([\s\S]*?)</reference_frame>', 'tokens');
frameSpecs = struct('ID', {}, 'Label', {}, 'ParentID', {}, 'Matrix', {});
for k = 1:numel(frameBlocks)
    attrs = parseAttrs(frameBlocks{k}{1});
    body = frameBlocks{k}{2};
    matrix = parseMatrixTag(body, 'dcm');
    if isempty(matrix)
        matrix = parseOrientationMatrix(body, false);
    end
    if isempty(matrix), matrix = eye(3); end
    frameSpecs(k).ID = attrNumberAny(attrs, {'id', 'number'}, k);
    frameSpecs(k).Label = attrStringAny(attrs, {'label', 'name'}, "");
    frameSpecs(k).ParentID = attrNumberAny(attrs, {'parent_reference_frame_id', 'parent_id'}, NaN);
    frameSpecs(k).Matrix = matrix;
end
addReferenceFrames(model, frameSpecs);

spinBlocks = regexp(text, '<spin\s+([^>]*)>([\s\S]*?)</spin>', 'tokens');
spinIDMap = containers.Map('KeyType', 'char', 'ValueType', 'double');
for k = 1:numel(spinBlocks)
    attrs = parseAttrs(spinBlocks{k}{1});
    body = spinBlocks{k}{2};
    isotope = attrString(attrs, 'isotope', "");
    label = attrString(attrs, 'label', "");
    externalID = attrNumberOptionalAny(attrs, {'id', 'number'});
    coord = parseCoords(body);
    atomID = model.addAtom(isotope, coord, label);
    if ~isempty(externalID)
        key = externalIDKey(externalID);
        if isKey(spinIDMap, key)
            error('spinachgui:DuplicateSpinXMLAtomID', 'Duplicate SpinXML spin id %s.', key);
        end
        spinIDMap(key) = atomID;
    end
end

interactionBlocks = regexp(text, '<interaction\s+([^>]*)>([\s\S]*?)</interaction>', 'tokens');
for k = 1:numel(interactionBlocks)
    attrs = parseAttrs(interactionBlocks{k}{1});
    body = interactionBlocks{k}{2};
    kind = attrStringAny(attrs, {'kind', 'type'}, "Unknown");
    externalAtomA = attrNumberAny(attrs, {'spin_a', 'spin_1'}, NaN);
    externalAtomB = attrNumberAny(attrs, {'spin_b', 'spin_2'}, externalAtomA);
    atomA = mappedSpinID(spinIDMap, externalAtomA);
    atomB = mappedSpinID(spinIDMap, externalAtomB);
    unitName = attrString(attrs, 'units', "Unknown");
    label = attrString(attrs, 'label', "");
    refID = attrNumber(attrs, 'reference_frame_id', 1);
    reference = attrString(attrs, 'reference', "");
    matrix = parseInteractionMatrix(body);
    model.addInteraction(kind, atomA, atomB, matrix, unitName, label, refID, reference, "SpinXML");
end
model.Dirty = false;
end

function attrs = parseAttrs(attrText)
attrs = containers.Map('KeyType', 'char', 'ValueType', 'char');
parts = [regexp(attrText, '([A-Za-z_][A-Za-z0-9_:-]*)\s*=\s*"([^"]*)"', 'tokens'), ...
    regexp(attrText, '([A-Za-z_][A-Za-z0-9_:-]*)\s*=\s*''([^'']*)''', 'tokens')];
for n = 1:numel(parts)
    attrs(parts{n}{1}) = parts{n}{2};
end
end

function addReferenceFrames(model, frameSpecs)
if isempty(frameSpecs)
    return
end
pending = true(1, numel(frameSpecs));
while any(pending)
    progressed = false;
    for idx = find(pending)
        parentID = frameSpecs(idx).ParentID;
        if isnan(parentID) || ismember(parentID, model.ReferenceFrames.ID)
            frameID = frameSpecs(idx).ID;
            model.addReferenceFrame(frameSpecs(idx).Matrix, frameSpecs(idx).Label, parentID, ...
                "SpinXML", frameID == 1, frameID);
            pending(idx) = false;
            progressed = true;
        end
    end
    if ~progressed
        pendingIDs = [frameSpecs(pending).ID];
        pendingParents = [frameSpecs(pending).ParentID];
        pendingParents = pendingParents(~isnan(pendingParents));
        knownOrPendingIDs = [model.ReferenceFrames.ID(:).', pendingIDs];
        missingParents = pendingParents(~ismember(pendingParents, knownOrPendingIDs));
        if ~isempty(missingParents)
            error('spinachgui:MissingReferenceFrame', ...
                'Reference frame parent ID %d is not present.', missingParents(1));
        end
        error('spinachgui:ReferenceFrameCycle', ...
            'SpinXML reference-frame hierarchy contains an unresolved parent cycle.');
    end
end
end

function attrs = parseTagAttrs(body, tag)
attrs = containers.Map('KeyType', 'char', 'ValueType', 'char');
match = regexp(body, ['<' tag '\s+([^>]*)/?\s*>'], 'tokens', 'once');
if ~isempty(match)
    attrs = parseAttrs(match{1});
end
end

function value = attrString(attrs, key, defaultValue)
if isKey(attrs, key)
    value = string(xmlUnescape(attrs(key)));
else
    value = string(defaultValue);
end
end

function value = attrStringAny(attrs, keys, defaultValue)
value = string(defaultValue);
for k = 1:numel(keys)
    if isKey(attrs, keys{k})
        value = attrString(attrs, keys{k}, defaultValue);
        return
    end
end
end

function value = attrNumber(attrs, key, defaultValue)
if isKey(attrs, key)
    value = str2double(xmlUnescape(attrs(key)));
    if isnan(value), value = defaultValue; end
else
    value = defaultValue;
end
end

function value = attrNumberAny(attrs, keys, defaultValue)
value = defaultValue;
for k = 1:numel(keys)
    if isKey(attrs, keys{k})
        value = attrNumber(attrs, keys{k}, defaultValue);
        return
    end
end
end

function value = attrNumberOptionalAny(attrs, keys)
value = [];
for k = 1:numel(keys)
    if isKey(attrs, keys{k})
        value = str2double(xmlUnescape(attrs(keys{k})));
        if isnan(value), value = []; end
        return
    end
end
end

function value = attrNumberCaseInsensitive(attrs, keyNames, defaultValue)
value = defaultValue;
attrKeys = keys(attrs);
for k = 1:numel(keyNames)
    idx = find(strcmpi(attrKeys, keyNames{k}), 1);
    if ~isempty(idx)
        value = str2double(xmlUnescape(attrs(attrKeys{idx})));
        if isnan(value), value = defaultValue; end
        return
    end
end
end

function value = elementNumber(body, tag, defaultValue)
expr = ['<' tag '[^>]*>([^<]*)</' tag '>'];
match = regexp(body, expr, 'tokens', 'once', 'ignorecase');
if isempty(match)
    value = defaultValue;
else
    value = str2double(xmlUnescape(strtrim(match{1})));
    if isnan(value), value = defaultValue; end
end
end

function key = externalIDKey(value)
key = sprintf('%.15g', value);
end

function atomID = mappedSpinID(spinIDMap, externalID)
if isempty(externalID) || isnan(externalID)
    atomID = NaN;
    return
end
key = externalIDKey(externalID);
if isKey(spinIDMap, key)
    atomID = spinIDMap(key);
else
    atomID = externalID;
end
end

function out = xmlUnescape(value)
out = char(value);
out = strrep(out, '&quot;', '"');
out = strrep(out, '&apos;', '''');
out = strrep(out, '&lt;', '<');
out = strrep(out, '&gt;', '>');
out = strrep(out, '&amp;', '&');
end

function xyz = parseCoords(body)
coord = regexp(body, '<coordinates\s+([^>]*)/>', 'tokens', 'once');
if ~isempty(coord)
    attrs = parseAttrs(coord{1});
    xyz = [attrNumber(attrs, 'x', 0), attrNumber(attrs, 'y', 0), attrNumber(attrs, 'z', 0)];
    return
end
coordBlock = tagBlock(body, 'coordinates');
if isempty(coordBlock)
    xyz = [0 0 0];
    return
end
elements = regexp(coordBlock, '<element[^>]*>([^<]*)</element>', 'tokens', 'ignorecase');
if numel(elements) >= 3
    xyz = zeros(1, 3);
    for k = 1:3
        xyz(k) = str2double(xmlUnescape(strtrim(elements{k}{1})));
    end
    if all(isfinite(xyz))
        return
    end
end
xyz = [elementNumber(coordBlock, 'x', NaN), elementNumber(coordBlock, 'y', NaN), ...
    elementNumber(coordBlock, 'z', NaN)];
if all(isfinite(xyz))
    return
end
error('spinachgui:UnsupportedSpinXMLCoordinates', 'Unsupported SpinXML coordinates block.');
end

function matrix = parseInteractionMatrix(body)
matrix = parseMatrixTag(body, 'tensor');
if ~isempty(matrix)
    return
end
scalar = parseScalar(body);
if ~isempty(scalar)
    matrix = scalar * eye(3);
    return
end
[eigenvalues, hasEigenvalues] = parseEigenvalueForm(body);
if hasEigenvalues
    dcm = parseOrientationMatrix(body, true);
    matrix = spinachgui.symmetrizeTensor(dcm * diag(eigenvalues) * dcm.');
    return
end
error('spinachgui:UnsupportedSpinXMLTensor', ...
    'SpinXML interaction does not contain a supported tensor, scalar, eigenvalues, span/skew, or axiality/rhombicity representation.');
end

function value = parseScalar(body)
value = [];
match = regexp(body, '<scalar\s*([^>]*)/>', 'tokens', 'once');
if ~isempty(match)
    attrs = parseAttrs(match{1});
    value = attrNumberAny(attrs, {'value', 'scalar'}, NaN);
    if ~isnan(value), return, end
end
match = regexp(body, '<scalar[^>]*>([^<]+)</scalar>', 'tokens', 'once');
if ~isempty(match)
    value = str2double(xmlUnescape(strtrim(match{1})));
    if isnan(value), value = []; end
end
end

function [eigenvalues, hasEigenvalues] = parseEigenvalueForm(body)
eigenvalues = [0 0 0];
hasEigenvalues = false;
attrs = parseTagAttrs(body, 'eigenvalues');
if ~isempty(attrs)
    eigenvalues = [attrNumberCaseInsensitive(attrs, {'xx', 'x'}, NaN), ...
        attrNumberCaseInsensitive(attrs, {'yy', 'y'}, NaN), ...
        attrNumberCaseInsensitive(attrs, {'zz', 'z'}, NaN)];
    hasEigenvalues = all(~isnan(eigenvalues));
    if hasEigenvalues, return, end
end
block = tagBlock(body, 'eigenvalues');
if ~isempty(block)
    eigenvalues = [elementNumber(block, 'xx', elementNumber(block, 'x', NaN)), ...
        elementNumber(block, 'yy', elementNumber(block, 'y', NaN)), ...
        elementNumber(block, 'zz', elementNumber(block, 'z', NaN))];
    hasEigenvalues = all(~isnan(eigenvalues));
    if hasEigenvalues, return, end
end
attrs = parseTagAttrs(body, 'span_skew');
block = tagBlock(body, 'span_skew');
if ~isempty(attrs) || ~isempty(block)
    iso = valueFromAttrsOrElements(attrs, block, {'iso'}, NaN);
    span = valueFromAttrsOrElements(attrs, block, {'span'}, NaN);
    skew = valueFromAttrsOrElements(attrs, block, {'skew'}, NaN);
    if all(~isnan([iso span skew]))
        eigenvalues = [iso + span * (3 - skew) / 6, iso + skew * span / 3, ...
            iso - span * (3 + skew) / 6];
        hasEigenvalues = true;
        return
    end
end
attrs = parseTagAttrs(body, 'axiality_rhombicity');
block = tagBlock(body, 'axiality_rhombicity');
if ~isempty(attrs) || ~isempty(block)
    iso = valueFromAttrsOrElements(attrs, block, {'iso'}, NaN);
    axiality = valueFromAttrsOrElements(attrs, block, {'ax', 'axiality'}, NaN);
    rhombicity = valueFromAttrsOrElements(attrs, block, {'rh', 'rhombicity'}, NaN);
    if all(~isnan([iso axiality rhombicity]))
        eigenvalues = [iso - axiality / 3 + rhombicity / 2, ...
            iso - axiality / 3 - rhombicity / 2, iso + 2 * axiality / 3];
        hasEigenvalues = true;
    end
end
end

function value = valueFromAttrsOrElements(attrs, block, keys, defaultValue)
value = defaultValue;
if ~isempty(attrs)
    value = attrNumberCaseInsensitive(attrs, keys, defaultValue);
    if ~isnan(value), return, end
end
if ~isempty(block)
    for k = 1:numel(keys)
        value = elementNumber(block, keys{k}, defaultValue);
        if ~isnan(value), return, end
    end
end
end

function block = tagBlock(body, tag)
match = regexp(body, ['<' tag '[^>]*>([\s\S]*?)</' tag '>'], 'tokens', 'once', 'ignorecase');
if isempty(match)
    block = '';
else
    block = match{1};
end
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

function matrix = parseOrientationMatrix(body, requiredIfPresent)
if nargin < 2, requiredIfPresent = false; end
orientationBody = tagBlock(body, 'orientation');
if isempty(orientationBody)
    orientationBody = tagBlock(body, 'inter_orientation');
end
if isempty(orientationBody)
    if requiredIfPresent && containsOrientationMarker(body)
        error('spinachgui:UnsupportedSpinXMLOrientation', 'Unsupported SpinXML orientation block.');
    end
    matrix = eye(3);
    return
end
matrix = parseMatrixTag(orientationBody, 'dcm');
if ~isempty(matrix)
    matrix = spinachgui.normalizeDcm(matrix);
    return
end
eulerBlock = tagBlock(orientationBody, 'euler_angles');
eulerAttrs = parseTagAttrs(orientationBody, 'euler_angles');
if ~isempty(eulerAttrs) || ~isempty(eulerBlock)
    alpha = valueFromAttrsOrElements(eulerAttrs, eulerBlock, {'alpha'}, NaN);
    beta = valueFromAttrsOrElements(eulerAttrs, eulerBlock, {'beta'}, NaN);
    gamma = valueFromAttrsOrElements(eulerAttrs, eulerBlock, {'gamma'}, NaN);
    if all(~isnan([alpha beta gamma]))
        matrix = spinachgui.eulerToDcm(deg2rad(alpha), deg2rad(beta), deg2rad(gamma));
        return
    end
end
quatBlock = tagBlock(orientationBody, 'quaternion');
if isempty(quatBlock)
    quatBlock = tagBlock(orientationBody, 'quartenion');
end
if ~isempty(quatBlock)
    w = elementNumber(quatBlock, 'w', elementNumber(quatBlock, 're', NaN));
    x = elementNumber(quatBlock, 'x', elementNumber(quatBlock, 'i', NaN));
    y = elementNumber(quatBlock, 'y', elementNumber(quatBlock, 'j', NaN));
    z = elementNumber(quatBlock, 'z', elementNumber(quatBlock, 'k', NaN));
    if all(~isnan([w x y z]))
        matrix = quaternionToDcm([w x y z]);
        return
    end
end
if requiredIfPresent || containsOrientationMarker(orientationBody)
    error('spinachgui:UnsupportedSpinXMLOrientation', 'Unsupported SpinXML orientation block.');
end
matrix = eye(3);
end

function tf = containsOrientationMarker(body)
tf = contains(body, '<orientation') || contains(body, '<inter_orientation') || ...
    contains(body, '<angle_axis') || contains(body, '<quaternion') || contains(body, '<quartenion');
end

function matrix = quaternionToDcm(q)
q = double(q(:).');
q = q / norm(q);
w = q(1); x = q(2); y = q(3); z = q(4);
matrix = [1 - 2*(y*y + z*z), 2*(x*y - z*w), 2*(x*z + y*w); ...
    2*(x*y + z*w), 1 - 2*(x*x + z*z), 2*(y*z - x*w); ...
    2*(x*z - y*w), 2*(y*z + x*w), 1 - 2*(x*x + y*y)];
matrix = spinachgui.normalizeDcm(matrix);
end
