function writeSimpson(model, filename, options)
%WRITESIMPSON Export a legacy-parity SIMPSON input file.
%   WRITESIMPSON(MODEL, FILENAME) writes the subset supported by the
%   original SpinachGUI SIMPSON exporter: shifts, J-couplings,
%   quadrupolar couplings, and CBond-derived dipolar couplings. OPTIONS
%   accepts SortAtomsByIsotope (default false), QuadrupolarOrder (1 or 2,
%   default 1), DipolarThreshold in Angstrom (default 10.00), and
%   EnabledChannels/DisabledChannels channel labels.

if nargin < 3 || isempty(options)
    options = struct();
end

atoms = sortrows(model.Atoms, 'ID');
validateAtoms(atoms);

sortAtoms = logicalOption(options, ["SortAtomsByIsotope", "SortAtoms", "Sort"], false);
quadrupolarOrder = quadrupolarOrderOption(options);
dipolarThreshold = dipolarThresholdOption(options);
channelLabels = uniqueChannelLabels(atoms);
enabledChannelLabels = enabledChannels(channelLabels, options);
systemName = systemNameOption(options, filename);
exportAtoms = exportedAtoms(atoms, sortAtoms);
atomIndex = atomIndexMap(exportAtoms);

fid = fopen(filename, 'w');
if fid < 0
    error('spinachgui:OpenFailed', 'Could not open %s for writing.', filename);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Produced by Spinach GUI MATLAB port \n \n');
fprintf(fid, '#--------------------------------------------------------------------\n');
fprintf(fid, '#System Name:%s \n', systemName);
fprintf(fid, '#--------------------------------------------------------------------\n \n');
fprintf(fid, 'spinsys { \n');

fprintf(fid, '\tchannels%s\n', paddedLabels(enabledChannelLabels));
fprintf(fid, '\tnuclei%s\n', paddedLabels(isotopeLabels(exportAtoms)));
fprintf(fid, '# Atom Index %s\n', paddedNumberList(1:height(exportAtoms), isotopeLabels(exportAtoms)));
fprintf(fid, '# SpinachGUI %s\n', paddedNumberList(exportAtoms.ID(:).', isotopeLabels(exportAtoms)));

writeTensorLines(fid, model.Interactions, atomIndex, exportAtoms, quadrupolarOrder, dipolarThreshold);

fprintf(fid, '\n  \n } \n');
writeLegacyScaffold(fid);
end

function validateAtoms(atoms)
if isempty(atoms) || height(atoms) == 0
    error('spinachgui:SimpsonNoAtoms', 'SIMPSON export requires at least one atom.');
end
ids = atoms.ID(:).';
if any(~isfinite(ids)) || any(ids <= 0) || any(ids ~= fix(ids))
    error('spinachgui:InvalidAtomID', 'SIMPSON export requires positive integer atom IDs.');
end
if numel(unique(ids)) ~= numel(ids)
    error('spinachgui:DuplicateAtomID', 'SIMPSON export requires unique atom IDs.');
end
if any(lower(string(atoms.Element)) == "e")
    error('spinachgui:SimpsonElectronUnsupported', 'SIMPSON export does not support electron spins.');
end
end

function exportAtoms = exportedAtoms(atoms, sortAtoms)
exportAtoms = atoms;
if sortAtoms
    [~, order] = sort(lower(string(exportAtoms.Element)));
    exportAtoms = exportAtoms(order, :);
end
end

function atomIndex = atomIndexMap(atoms)
atomIndex = containers.Map('KeyType', 'double', 'ValueType', 'double');
for k = 1:height(atoms)
    atomIndex(atoms.ID(k)) = k;
end
end

function labels = uniqueChannelLabels(atoms)
labels = strings(1, 0);
for k = 1:height(atoms)
    label = isotopeLabel(atoms.Mass(k), atoms.Element(k));
    if ~ismember(label, labels)
        labels(end+1) = label; %#ok<AGROW>
    end
end
end

function labels = isotopeLabels(atoms)
labels = strings(1, height(atoms));
for k = 1:height(atoms)
    labels(k) = isotopeLabel(atoms.Mass(k), atoms.Element(k));
end
end

function label = isotopeLabel(mass, element)
label = sprintf('%d%s', mass, char(string(element)));
end

function text = paddedLabels(labels)
labels = string(labels(:).');
if isempty(labels)
    text = '';
else
    text = char(strjoin(" " + labels, ""));
end
end

function text = paddedNumberList(numbers, labels)
numbers = numbers(:).';
labels = string(labels(:).');
segments = strings(1, numel(numbers));
for k = 1:numel(numbers)
    width = strlength(" " + labels(k));
    segment = sprintf(' %d', numbers(k));
    if numel(segment) < width
        segment = [segment repmat(' ', 1, width - numel(segment))]; %#ok<AGROW>
    elseif numel(segment) > width
        segment = segment(1:width);
    end
    segments(k) = string(segment);
end
text = char(strjoin(segments, ""));
end

function writeTensorLines(fid, interactions, atomIndex, atoms, quadrupolarOrder, dipolarThreshold)
for k = 1:height(interactions)
    inter = interactions(k, :);
    if inter.Kind == "Shift"
        [iso, aniso, eta, angles] = tensorParameters(inter);
        atomA = exportAtomIndex(atomIndex, inter.A, inter.ID, 'A');
        fprintf(fid, '\tshift %d %sp %sp %s %s %s %s \n', atomA, ...
            fixed4(iso), fixed4(aniso), fixed4(eta), fixed4(angles(1)), fixed4(angles(2)), fixed4(angles(3)));
    end
end

for k = 1:height(interactions)
    inter = interactions(k, :);
    if inter.Kind == "Jcoupling"
        [iso, aniso, eta, angles] = tensorParameters(inter);
        atomA = exportAtomIndex(atomIndex, inter.A, inter.ID, 'A');
        atomB = exportAtomIndex(atomIndex, inter.B, inter.ID, 'B');
        fprintf(fid, '\tjcoupling %d %d %s %s %s %s %s %s \n', atomA, atomB, ...
            fixed4(iso), fixed4(aniso), fixed4(eta), fixed4(angles(1)), fixed4(angles(2)), fixed4(angles(3)));
    end
end

for k = 1:height(interactions)
    inter = interactions(k, :);
    if inter.Kind == "Quadrupolar"
        [~, ~, eta, angles] = tensorParameters(inter);
        atomA = exportAtomIndex(atomIndex, inter.A, inter.ID, 'A');
        matrix = interactionMatrix(inter);
        spin = atomSpin(atoms, inter.A, inter.ID);
        cq = matrix(3, 3) * (2 * spin * (2 * spin - 1)) * 1e-6;
        fprintf(fid, '\tquadrupole %d %d %s %s %s %s %s \n', atomA, quadrupolarOrder, ...
            fixed4(cq), fixed4(eta), fixed4(angles(1)), fixed4(angles(2)), fixed4(angles(3)));
    end
end

for k = 1:height(interactions)
    inter = interactions(k, :);
    if inter.Kind == "CBond"
        matrix = interactionMatrix(inter);
        distance = matrix(1, 1);
        if distance <= dipolarThreshold
            writeDipoleLine(fid, inter, atomIndex, atoms, distance);
        end
    end
end
end

function [iso, aniso, eta, angles] = tensorParameters(inter)
eigenvalues = inter.Eigenvalues{1};
eigenvalues = eigenvalues(:).';
if numel(eigenvalues) ~= 3 || any(~isfinite(eigenvalues))
    error('spinachgui:InvalidInteractionEigenvalues', ...
        'Interaction %d has invalid eigenvalues for SIMPSON export.', inter.ID);
end
iso = mean(eigenvalues);
delta = abs(eigenvalues - iso);
[~, zzIdx] = maxLast(delta);
[~, yyIdx] = minLast(delta);
aniso = eigenvalues(zzIdx) - iso;
if abs(aniso) < 1e-10
    aniso = 0;
    eta = 0;
else
    xxCandidates = setdiff(1:3, [zzIdx yyIdx], 'stable');
    if isempty(xxCandidates)
        error('spinachgui:DegenerateTensorOrdering', ...
            'Interaction %d has degenerate tensor ordering that cannot define eta.', inter.ID);
    end
    xx = eigenvalues(xxCandidates(1));
    yy = eigenvalues(yyIdx);
    eta = (yy - xx) / aniso;
end
angles = legacyEulerDegrees(inter.DCM{1});
end

function [value, idx] = maxLast(values)
value = max(values);
idx = find(values == value, 1, 'last');
end

function [value, idx] = minLast(values)
value = min(values);
idx = find(values == value, 1, 'last');
end

function angles = legacyEulerDegrees(dcm)
validateattributes(dcm, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'DCM');
dcm = det(dcm) * dcm;
value = max(-1, min(1, dcm(3, 3)));
beta = atan2(hypot(dcm(3, 1), dcm(3, 2)), value);
if abs(sin(beta)) > 10 * eps(class(beta))
    alpha = atan2(dcm(2, 3), dcm(1, 3));
    gamma = atan2(dcm(3, 2), -dcm(3, 1));
else
    alpha = atan2(dcm(2, 1), dcm(1, 1));
    gamma = 0;
end
angles = [wrapLegacyAngle(alpha), wrapLegacyBeta(beta), wrapLegacyAngle(gamma)] * 180 / pi;
end

function angle = wrapLegacyAngle(angle)
if angle < 0 || angle >= 2*pi
    angle = angle - 2*pi*floor(angle/(2*pi));
end
if angle >= 2*pi
    angle = 0;
end
end

function beta = wrapLegacyBeta(beta)
if beta < 0 || beta >= pi
    beta = beta - pi*floor(beta/pi);
end
end

function matrix = interactionMatrix(inter)
matrix = inter.Matrix{1};
validateattributes(matrix, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'Matrix');
end

function writeDipoleLine(fid, inter, atomIndex, atoms, distance)
if ~isfinite(distance) || distance <= eps
    error('spinachgui:InvalidBondDistance', ...
        'CBond interaction %d has zero or invalid distance for SIMPSON dipolar export.', inter.ID);
end
atomA = exportAtomIndex(atomIndex, inter.A, inter.ID, 'A');
atomB = exportAtomIndex(atomIndex, inter.B, inter.ID, 'B');
rowA = atomRow(atoms, inter.A, inter.ID);
rowB = atomRow(atoms, inter.B, inter.ID);
xyzA = [atoms.X(rowA), atoms.Y(rowA), atoms.Z(rowA)];
xyzB = [atoms.X(rowB), atoms.Y(rowB), atoms.Z(rowB)];
dxyz = xyzA - xyzB;
cosBeta = dxyz(3) / distance;
if abs(cosBeta) > 1 + 1e-10
    error('spinachgui:InconsistentBondDistance', ...
        'CBond interaction %d distance is inconsistent with atom coordinates.', inter.ID);
end
cosBeta = max(-1, min(1, cosBeta));
alpha = 0;
beta = acos(cosBeta) * 180 / pi;
gamma = atan2(dxyz(2), dxyz(1)) * 180 / pi;
bij = -1.054571726e-11 * atoms.Magnetogyric(rowA) * atoms.Magnetogyric(rowB) / (2*pi*distance^3);
fprintf(fid, '\tdipole %d %d %s %s %s %s \n', atomA, atomB, fixed4(bij), fixed4(alpha), fixed4(beta), fixed4(gamma));
end

function idx = exportAtomIndex(atomIndex, atomID, interactionID, endpointName)
if isempty(atomID) || isnan(atomID) || ~isKey(atomIndex, atomID)
    error('spinachgui:InvalidInteractionAtom', ...
        'Interaction %d references missing atom %s ID %g.', interactionID, endpointName, atomID);
end
idx = atomIndex(atomID);
end

function spin = atomSpin(atoms, atomID, interactionID)
row = atomRow(atoms, atomID, interactionID);
spin = atoms.Spin(row);
if ~isfinite(spin)
    error('spinachgui:InvalidAtomSpin', 'Interaction %d references an atom with invalid spin.', interactionID);
end
end

function row = atomRow(atoms, atomID, interactionID)
row = find(atoms.ID == atomID, 1);
if isempty(row)
    error('spinachgui:InvalidInteractionAtom', 'Interaction %d references missing atom ID %g.', interactionID, atomID);
end
end

function text = fixed4(value)
text = sprintf('%.4f', value);
end

function value = quadrupolarOrderOption(options)
raw = optionValue(options, ["QuadrupolarOrder", "QuadOrder", "Order"], 1);
if isstring(raw) || ischar(raw)
    raw = lower(strtrim(string(raw)));
    if raw == "1" || raw == "1st" || raw == "first"
        value = 1;
    elseif raw == "2" || raw == "2nd" || raw == "second"
        value = 2;
    else
        error('spinachgui:InvalidQuadrupolarOrder', 'QuadrupolarOrder must be 1/1st or 2/2nd.');
    end
elseif isnumeric(raw) && isscalar(raw) && isfinite(raw) && (raw == 1 || raw == 2)
    value = raw;
else
    error('spinachgui:InvalidQuadrupolarOrder', 'QuadrupolarOrder must be 1 or 2.');
end
end

function value = dipolarThresholdOption(options)
value = optionValue(options, ["DipolarThreshold", "DipolarThresholdAngstrom", "BondThreshold"], 10.00);
if ~(isnumeric(value) && isscalar(value) && isfinite(value))
    error('spinachgui:InvalidDipolarThreshold', 'DipolarThreshold must be a finite numeric scalar.');
end
if value < 1.00 || value > 1000.00
    error('spinachgui:InvalidDipolarThreshold', 'DipolarThreshold must be between 1.00 and 1000.00 Angstrom.');
end
end

function value = logicalOption(options, names, defaultValue)
raw = optionValue(options, names, defaultValue);
if islogical(raw) && isscalar(raw)
    value = raw;
elseif isnumeric(raw) && isscalar(raw) && isfinite(raw)
    value = raw ~= 0;
elseif isstring(raw) || ischar(raw)
    raw = lower(strtrim(string(raw)));
    if ismember(raw, ["true", "yes", "on", "1"])
        value = true;
    elseif ismember(raw, ["false", "no", "off", "0", ""])
        value = false;
    else
        error('spinachgui:InvalidLogicalOption', 'Option %s must be logical.', names(1));
    end
else
    error('spinachgui:InvalidLogicalOption', 'Option %s must be logical.', names(1));
end
end

function labels = enabledChannels(channelLabels, options)
labels = channelLabels;
raw = optionValue(options, ["EnabledChannels", "Channels"], []);
if ~isempty(raw)
    labels = channelSelection(channelLabels, raw, 'EnabledChannels');
end
raw = optionValue(options, "DisabledChannels", []);
if ~isempty(raw)
    disabled = channelSelection(channelLabels, raw, 'DisabledChannels');
    labels = labels(~ismember(labels, disabled));
end
end

function labels = channelSelection(channelLabels, raw, optionName)
if (islogical(raw) || isnumeric(raw)) && numel(raw) == numel(channelLabels)
    labels = channelLabels(logical(raw(:).'));
    return
end
labels = normalizedLabelList(raw);
unknown = setdiff(labels, channelLabels, 'stable');
if ~isempty(unknown)
    error('spinachgui:UnknownChannel', '%s contains unknown channel label %s.', optionName, unknown(1));
end
labels = channelLabels(ismember(channelLabels, labels));
end

function labels = normalizedLabelList(raw)
if ischar(raw) || (isstring(raw) && isscalar(raw))
    text = strtrim(string(raw));
    if strlength(text) == 0
        labels = strings(1, 0);
    else
        labels = string(regexp(char(text), '\s+', 'split'));
    end
else
    labels = string(raw(:).');
end
labels = strtrim(labels);
labels(labels == "") = [];
end

function name = systemNameOption(options, filename)
[~, base, ext] = fileparts(filename);
name = string([base ext]);
raw = optionValue(options, "SystemName", []);
if ~isempty(raw)
    raw = string(raw);
    if isscalar(raw) && strlength(strtrim(raw)) > 0
        name = strtrim(raw);
    end
end
name = char(name);
end

function value = optionValue(options, names, defaultValue)
value = defaultValue;
if ~isstruct(options)
    return
end
fields = fieldnames(options);
for k = 1:numel(names)
    idx = find(strcmpi(fields, char(names(k))), 1);
    if ~isempty(idx)
        value = options.(fields{idx});
        return
    end
end
end

function writeLegacyScaffold(fid)
fprintf(fid, '#--------------------------------------------------------------------\n');
fprintf(fid, '# A basic SIMPSON simulation route is appended below,\n');
fprintf(fid, '# please edit as appropriate for your specific case.\n');
fprintf(fid, '#--------------------------------------------------------------------\n');
fprintf(fid, '\n');
fprintf(fid, 'par {\n');
fprintf(fid, 'proton_frequency 600e6 \n');
fprintf(fid, 'spin_rate        0 \n');
fprintf(fid, 'sw               20000 \n');
fprintf(fid, 'start_operator   I1x \n');
fprintf(fid, 'detect_operator  I1p \n');
fprintf(fid, 'gamma_angles     1 \n');
fprintf(fid, 'verbose          1101 \n');
fprintf(fid, 'np               256 \n');
fprintf(fid, 'crystal_file     zcw4180 \n');
fprintf(fid, '} \n');
fprintf(fid, '\n');
fprintf(fid, 'proc pulseq {} {\n');
fprintf(fid, '     acq_block { \n');
fprintf(fid, '         delay 20 \n');
fprintf(fid, '     } \n');
fprintf(fid, '} \n');
fprintf(fid, '\n');
fprintf(fid, 'proc main {} {\n');
fprintf(fid, 'global par \n');
fprintf(fid, 'set f [fsimpson] \n');
fprintf(fid, 'fsave $f $par(name).fid \n');
fprintf(fid, 'faddlb $f 50 0 \n');
fprintf(fid, 'fzerofill $f 4096 \n');
fprintf(fid, 'fft $f \n');
fprintf(fid, 'fsave $f $par(name).spe \n');
fprintf(fid, 'funload $f \n');
fprintf(fid, '} \n');
end
