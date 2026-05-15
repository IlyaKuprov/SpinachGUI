function outputText = writeSpinEvolution(model, filename, options)
%WRITESPINEVOLUTION Export a legacy-parity SpinEvolution input file.
%   WRITESPINEVOLUTION(MODEL, FILENAME) writes the subset supported by the
%   original SpinachGUI SpinEvolution exporter: chemical shifts,
%   J-couplings, quadrupolar couplings, enabled-channel filtering, and the
%   fixed legacy pulse-sequence scaffold. OPTIONS accepts EnabledChannels or
%   DisabledChannels using SpinEvolution channel labels such as "H1" and
%   "C13".

if nargin < 3 || isempty(options)
    options = struct();
end
if ~isstruct(options)
    error('spinachgui:InvalidOptions', 'SpinEvolution export options must be a scalar struct.');
end
if nargin < 2 || strlength(strtrim(string(filename))) == 0
    error('spinachgui:MissingFilename', 'SpinEvolution export requires an output filename.');
end

atoms = sortrows(model.Atoms, 'ID');
validateAtoms(atoms);
interactions = sortrows(model.Interactions, 'ID');
validateInteractionKinds(interactions);

channelLabels = uniqueChannelLabels(atoms);
enabledChannelLabels = enabledChannels(channelLabels, options);
if isempty(enabledChannelLabels)
    error('spinachgui:NoEnabledChannels', 'SpinEvolution export requires at least one enabled channel.');
end

atomLabels = isotopeLabels(atoms);
enabledAtoms = atoms(ismember(atomLabels, enabledChannelLabels), :);
if isempty(enabledAtoms)
    error('spinachgui:NoEnabledAtoms', 'SpinEvolution export requires at least one enabled atom.');
end
atomIndex = atomIndexMap(enabledAtoms);
systemName = systemNameOption(options, filename);

[csIsotropic, csaLines, jLines, quadrupoleLines] = interactionLines(interactions, atomIndex, atoms, enabledChannelLabels);

lines = strings(0, 1);
lines = appendLine(lines, '* Produced by Spinach GUI MATLAB port ');
lines = appendLine(lines, '*--------------------------------------------------------------------');
lines = appendLine(lines, sprintf('*System Name:%s ', systemName));
lines = appendLine(lines, '**A basic SpinEvolution simulation route is appended after ');
lines = appendLine(lines, '**''The System'' section with random values.');
lines = appendLine(lines, '**Please edit as appropriate for your specific case.');
lines = appendLine(lines, '*--------------------------------------------------------------------');
lines = appendLine(lines, '****** The System *******');
lines = appendLine(lines, 'spectrometer(MHz)  500');
lines = appendLine(lines, 'spinning_freq(kHz) 10.0');
lines = appendLine(lines, sprintf('channels          %s', paddedLabels(enabledChannelLabels)));
lines = appendLine(lines, sprintf('nuclei            %s', paddedLabels(isotopeLabels(enabledAtoms))));
lines = appendLine(lines, sprintf('atomic_coords      %s', atomicCoordinates(atoms)));
lines = appendLine(lines, csIsotropicLine(csIsotropic));
lines = appendInteractionSection(lines, csaLines, 'csa_parameters     * ');
lines = appendInteractionSection(lines, jLines, 'j_coupling         * ');
lines = appendInteractionSection(lines, quadrupoleLines, 'quadrupole         * ');
lines = appendSystemPlaceholders(lines);
lines = appendPulseSequence(lines, enabledChannelLabels);
lines = appendVariablesAndOptions(lines);

outputText = strjoin(lines, string(newline)) + string(newline);

fid = fopen(char(filename), 'w');
if fid < 0
    error('spinachgui:OpenFailed', 'Could not open %s for writing.', char(filename));
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', char(outputText));
end

function validateAtoms(atoms)
if isempty(atoms) || height(atoms) == 0
    error('spinachgui:SpinEvolutionNoAtoms', 'SpinEvolution export requires at least one atom.');
end
ids = atoms.ID(:).';
if any(~isfinite(ids)) || any(ids <= 0) || any(ids ~= fix(ids))
    error('spinachgui:InvalidAtomID', 'SpinEvolution export requires positive integer atom IDs.');
end
if numel(unique(ids)) ~= numel(ids)
    error('spinachgui:DuplicateAtomID', 'SpinEvolution export requires unique atom IDs.');
end
if any(lower(string(atoms.Element)) == "e")
    error('spinachgui:SpinEvolutionElectronUnsupported', 'SpinEvolution export does not support electron spins.');
end
if any(lower(string(atoms.Element)) == "chi")
    error('spinachgui:SpinEvolutionPseudoAtomUnsupported', 'SpinEvolution export does not support chi pseudo-atoms.');
end
if any(strlength(strtrim(string(atoms.Element))) == 0) || any(~isfinite(atoms.Mass)) || any(atoms.Mass <= 0)
    error('spinachgui:InvalidIsotope', 'SpinEvolution export requires ordinary isotope labels with positive mass numbers.');
end
end

function validateInteractionKinds(interactions)
knownKinds = spinachgui.interactionKinds();
actualKinds = unique(string(interactions.Kind));
unknownKinds = setdiff(actualKinds, knownKinds, 'stable');
if ~isempty(unknownKinds)
    error('spinachgui:UnknownInteractionKind', 'Unknown interaction kind "%s" cannot be exported to SpinEvolution.', unknownKinds(1));
end
end

function labels = uniqueChannelLabels(atoms)
labels = strings(1, 0);
allLabels = isotopeLabels(atoms);
for k = 1:numel(allLabels)
    if ~ismember(allLabels(k), labels)
        labels(end+1) = allLabels(k); %#ok<AGROW>
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
label = sprintf('%s%d', char(string(element)), mass);
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

function atomIndex = atomIndexMap(atoms)
atomIndex = containers.Map('KeyType', 'double', 'ValueType', 'double');
for k = 1:height(atoms)
    atomIndex(atoms.ID(k)) = k;
end
end

function [csIsotropic, csaLines, jLines, quadrupoleLines] = interactionLines(interactions, atomIndex, atoms, enabledChannelLabels)
csIsotropic = strings(1, 0);
csaLines = strings(0, 1);
jLines = strings(0, 1);
quadrupoleLines = strings(0, 1);
for k = 1:height(interactions)
    inter = interactions(k, :);
    if ~ismember(inter.Kind, ["Shift", "Jcoupling", "Quadrupolar"])
        continue
    end
    rowA = atomRow(atoms, inter.A, inter.ID, 'A');
    if inter.Kind == "Jcoupling"
        rowB = atomRow(atoms, inter.B, inter.ID, 'B');
    else
        rowB = [];
    end
    if ~ismember(isotopeLabel(atoms.Mass(rowA), atoms.Element(rowA)), enabledChannelLabels)
        continue
    end
    [iso, aniso, eta, angles] = tensorParameters(inter);
    switch inter.Kind
        case "Shift"
            atomA = exportAtomIndex(atomIndex, inter.A, inter.ID, 'A');
            csIsotropic(end+1) = string(fixed4(iso)); %#ok<AGROW>
            csaLines(end+1, 1) = sprintf('csa_parameters     %d %s %s %s %s %s ppm ', atomA, ...
                fixed4(aniso), fixed4(eta), fixed4(angles(1)), fixed4(angles(2)), fixed4(angles(3))); %#ok<AGROW>
        case "Jcoupling"
            if ~ismember(isotopeLabel(atoms.Mass(rowB), atoms.Element(rowB)), enabledChannelLabels)
                continue
            end
            atomA = exportAtomIndex(atomIndex, inter.A, inter.ID, 'A');
            atomB = exportAtomIndex(atomIndex, inter.B, inter.ID, 'B');
            jLines(end+1, 1) = sprintf('j_coupling         %d %d %s %s %s %s %s %s ', atomA, atomB, ...
                fixed4(iso), fixed4(aniso), fixed4(eta), fixed4(angles(1)), fixed4(angles(2)), fixed4(angles(3))); %#ok<AGROW>
        case "Quadrupolar"
            atomA = exportAtomIndex(atomIndex, inter.A, inter.ID, 'A');
            quadrupoleLines(end+1, 1) = sprintf('quadrupole         %d %s %s %s %s %s ', atomA, ...
                fixed4(aniso), fixed4(eta), fixed4(angles(1)), fixed4(angles(2)), fixed4(angles(3))); %#ok<AGROW>
    end
end
end

function row = atomRow(atoms, atomID, interactionID, endpointName)
if isempty(atomID) || ~isscalar(atomID) || ~isfinite(atomID)
    error('spinachgui:InvalidInteractionAtom', ...
        'Interaction %d references invalid atom %s ID %g.', interactionID, endpointName, atomID);
end
row = find(atoms.ID == atomID, 1);
if isempty(row)
    error('spinachgui:InvalidInteractionAtom', ...
        'Interaction %d references missing atom %s ID %g.', interactionID, endpointName, atomID);
end
end

function idx = exportAtomIndex(atomIndex, atomID, interactionID, endpointName)
if isempty(atomID) || ~isscalar(atomID) || ~isfinite(atomID) || ~isKey(atomIndex, atomID)
    error('spinachgui:InvalidInteractionAtom', ...
        'Interaction %d references disabled or missing atom %s ID %g.', interactionID, endpointName, atomID);
end
idx = atomIndex(atomID);
end

function [iso, aniso, eta, angles] = tensorParameters(inter)
eigenvalues = inter.Eigenvalues{1};
eigenvalues = eigenvalues(:).';
if numel(eigenvalues) ~= 3 || any(~isfinite(eigenvalues))
    error('spinachgui:InvalidInteractionEigenvalues', ...
        'Interaction %d has invalid eigenvalues for SpinEvolution export.', inter.ID);
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

function line = csIsotropicLine(values)
if isempty(values)
    line = 'cs_isotropic       * ';
else
    line = sprintf('cs_isotropic       %s ppm ', char(strjoin(values, " ")));
end
end

function lines = appendInteractionSection(lines, sectionLines, placeholder)
if isempty(sectionLines)
    lines = appendLine(lines, placeholder);
else
    for k = 1:numel(sectionLines)
        lines = appendLine(lines, sectionLines(k));
    end
end
end

function lines = appendSystemPlaceholders(lines)
lines = appendLine(lines, 'dip_switchboard    *');
lines = appendLine(lines, 'csa_switchboard    *');
lines = appendLine(lines, 'exchange_nuclei    *');
lines = appendLine(lines, 'bond_len_nuclei    *');
lines = appendLine(lines, 'bond_ang_nuclei    *');
lines = appendLine(lines, 'tors_ang_nuclei    *');
lines = appendLine(lines, 'groups_nuclei      *');
end

function lines = appendPulseSequence(lines, enabledChannelLabels)
lines = appendLine(lines, '******* Pulse Sequence ******************************');
for k = 1:numel(enabledChannelLabels)
    lines = appendLine(lines, sprintf('CHN %d', k));
    lines = appendLine(lines, 'timing(usec)       (4   4)');
    lines = appendLine(lines, 'power(kHz)         125 125');
    lines = appendLine(lines, 'phase(deg)         0   15');
    lines = appendLine(lines, 'freq_offs(kHz)     0   0');
end
end

function lines = appendVariablesAndOptions(lines)
lines = appendLine(lines, '******* Variables ***********************************');
lines = appendLine(lines, '******* Options *************************************');
lines = appendLine(lines, 'rho0               F1x');
lines = appendLine(lines, 'observables        F1p');
lines = appendLine(lines, 'EulerAngles        *');
lines = appendLine(lines, 'n_gamma            *');
lines = appendLine(lines, 'line_broaden(Hz)   *');
lines = appendLine(lines, 'zerofill           *');
lines = appendLine(lines, 'FFT_dimensions     *');
lines = appendLine(lines, 'options            *');
lines = appendLine(lines, '******************************************************');
end

function text = paddedLabels(labels)
labels = string(labels(:).');
if isempty(labels)
    text = '';
else
    text = char(strjoin(" " + labels, ""));
end
end

function text = atomicCoordinates(atoms)
if height(atoms) == 1
    text = '*';
    return
end
parts = strings(1, 3 * height(atoms));
idx = 1;
for k = 1:height(atoms)
    parts(idx) = string(formatGeneral(atoms.X(k)));
    parts(idx + 1) = string(formatGeneral(atoms.Y(k)));
    parts(idx + 2) = string(formatGeneral(atoms.Z(k)));
    idx = idx + 3;
end
text = char(strjoin(parts, " "));
end

function text = fixed4(value)
text = sprintf('%.4f', value);
end

function text = formatGeneral(value)
if abs(value) < eps
    value = 0;
end
text = sprintf('%.15g', value);
end

function name = systemNameOption(options, filename)
[~, base, ext] = fileparts(char(filename));
name = string([base ext]);
raw = optionValue(options, ["SystemName", "Title", "SourceTitle"], []);
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

function lines = appendLine(lines, line)
lines(end+1, 1) = string(line);
end
