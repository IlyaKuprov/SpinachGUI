function outputText = writeEasySpin(model, filename, options)
%WRITEEASYSPIN Export a legacy-parity EasySpin MATLAB file.
%   WRITEEASYSPIN(MODEL, FILENAME) writes the supported SpinachGUI
%   EasySpin exporter subset for one-electron systems. The writer preserves
%   the legacy dialog defaults for garlic/chili/pepper experiment and option
%   blocks, emits HFC, g tensor, and ZFS interactions, ignores the interaction
%   kinds ignored by the C++ exporter, and fails explicitly for cases where
%   the legacy exporter would silently overwrite or emit malformed code.

if nargin < 3 || isempty(options)
    options = struct();
end
if ~isstruct(options)
    error('spinachgui:InvalidOptions', 'EasySpin export options must be a scalar struct.');
end
if nargin < 2 || strlength(strtrim(string(filename))) == 0
    error('spinachgui:MissingFilename', 'EasySpin export requires an output filename.');
end

atoms = sortrows(model.Atoms, 'ID');
atomIDs = validateAtomIDs(atoms.ID);
validateEasySpinAtoms(atoms);
interactions = sortrows(model.positiveInteractions(), 'ID');
validateInteractionKinds(interactions);

spinFunction = lowerToken(optionValue(options, ["Function", "EasySpinFunction", "SimulationFunction"], "garlic"));
if ~ismember(spinFunction, ["garlic", "chili", "pepper"])
    error('spinachgui:UnsupportedEasySpinFunction', 'Unsupported EasySpin function "%s".', spinFunction);
end

lines = strings(0, 1);
lines = appendLine(lines, 'clear Sys Exp Opt;');
lines = appendLine(lines, 'Sys.S=1/2;');
lines = appendLine(lines, '');
lines = appendSystemLines(lines, model, atoms, atomIDs, interactions);
lines = appendLine(lines, '');
lines = appendExperimentLines(lines, options, spinFunction);
lines = appendOptionLines(lines, options, spinFunction);
lines = appendBroadeningLines(lines, options, spinFunction);
lines = appendDynamicsLines(lines, options, spinFunction);
lines = appendLine(lines, sprintf('%s(Sys,Exp,Opt);', spinFunction));

outputText = strjoin(lines, string(newline)) + string(newline);

fid = fopen(char(filename), 'w');
if fid < 0
    error('spinachgui:OpenFailed', 'Could not open %s for writing.', char(filename));
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', char(outputText));
end

function lines = appendSystemLines(lines, model, atoms, atomIDs, interactions)
hfcRows = interactions(interactions.Kind == "HFC", :);
if isempty(hfcRows)
    labels = strings(0, 1);
    for k = 1:height(atoms)
        if atoms.Element(k) ~= "e"
            labels(end+1, 1) = isotopeLabel(atoms.Mass(k), atoms.Element(k)); %#ok<AGROW>
        end
    end
    lines = appendLine(lines, sprintf("Sys.Nucs= '%s';", strjoin(labels, ', ')));
else
    for k = 1:height(hfcRows)
        inter = hfcRows(k, :);
        atomA = primaryAtomID(inter, atomIDs);
        rowA = atomRow(atoms, atomA);
        atomB = secondaryAtomID(inter, atomIDs, atomA);
        rowB = atomRow(atoms, atomB);
        if atoms.Element(rowA) == "e"
            error('spinachgui:InvalidHFCAtom', 'HFC interaction %d uses an electron as the nucleus atom.', inter.ID);
        end
        if atoms.Element(rowB) ~= "e"
            error('spinachgui:InvalidHFCAtom', 'HFC interaction %d must reference an electron as the second atom.', inter.ID);
        end
        matrixText = matrixLiteralFixed6(labMatrix(model, inter));
        lines = appendLine(lines, sprintf("Sys = nucspinadd(Sys, '%s', mt2mhz(%s/10));", ...
            isotopeLabel(atoms.Mass(rowA), atoms.Element(rowA)), matrixText));
    end
end

gTensorRows = interactions(interactions.Kind == "GTensor", :);
if height(gTensorRows) > 1
    error('spinachgui:MultipleGTensors', 'Legacy EasySpin export supports only one GTensor; found %d.', height(gTensorRows));
end
if height(gTensorRows) == 1
    assertElectronCentred(gTensorRows(1, :), atoms, atomIDs, 'GTensor');
    lines = appendLine(lines, sprintf('Sys.g = %s;', matrixLiteralFixed6(labMatrix(model, gTensorRows(1, :)))));
end

zfsRows = interactions(interactions.Kind == "ZFS", :);
if height(zfsRows) > 1
    error('spinachgui:MultipleZFS', 'Legacy EasySpin export supports only one ZFS interaction; found %d.', height(zfsRows));
end
if height(zfsRows) == 1
    assertElectronCentred(zfsRows(1, :), atoms, atomIDs, 'ZFS');
    matrix = convertEasySpinUnit(labMatrix(model, zfsRows(1, :)), zfsRows.Unit(1), "MHz");
    lines = appendLine(lines, sprintf('Sys.D = %s;', matrixLiteralFixed6(matrix)));
end
end

function lines = appendExperimentLines(lines, options, spinFunction)
fieldUnits = optionValue(options, ["FieldUnits", "FieldUnit", "ExpUnits"], "mTesla");
center = optionValue(options, ["Center", "Centre", "CenterField", "CentreField"], []);
sweep = optionValue(options, ["Sweep", "SweepWidth"], []);
minimum = optionValue(options, ["Minimum", "Min", "MinimumField", "MinField"], []);
maximum = optionValue(options, ["Maximum", "Max", "MaximumField", "MaxField"], []);
if ~isEmptyOption(center) || ~isEmptyOption(sweep)
    requireNonEmpty(center, 'Center');
    requireNonEmpty(sweep, 'Sweep');
    lines = appendLine(lines, sprintf('Exp.CenterSweep = [%s %s];', ...
        formatGeneral(convertEasySpinUnit(numericScalar(center, 'Center'), fieldUnits, "mTesla")), ...
        formatGeneral(convertEasySpinUnit(numericScalar(sweep, 'Sweep'), fieldUnits, "mTesla"))));
elseif ~isEmptyOption(minimum) || ~isEmptyOption(maximum)
    requireNonEmpty(minimum, 'Minimum');
    requireNonEmpty(maximum, 'Maximum');
    lines = appendLine(lines, sprintf('Exp.Range = [%s %s];', ...
        formatGeneral(convertEasySpinUnit(numericScalar(minimum, 'Minimum'), fieldUnits, "mTesla")), ...
        formatGeneral(convertEasySpinUnit(numericScalar(maximum, 'Maximum'), fieldUnits, "mTesla"))));
end

lines = appendLine(lines, sprintf('Exp.mwFreq = %s;', formatOptionText(optionValue(options, ["mwFreq", "MwFreq", "MicrowaveFrequency", "Frequency"], "9.5"), 'mwFreq')));
lines = appendLine(lines, sprintf('Exp.mwPhase = %s;', formatOptionText(optionValue(options, ["mwPhase", "MwPhase", "Phase"], "0.0"), 'mwPhase')));

if logicalOption(optionValue(options, ["ModAmpEnabled", "UseModAmp", "ModulationEnabled", "UseModulation"], false), 'ModAmpEnabled')
    modAmp = optionValue(options, ["ModAmp", "ModulationAmplitude"], []);
    requireNonEmpty(modAmp, 'ModAmp');
    modUnits = optionValue(options, ["ModAmpUnits", "ModulationUnits"], "mTesla");
    lines = appendLine(lines, sprintf('Exp.ModAmp = %s;', formatGeneral(convertEasySpinUnit(numericScalar(modAmp, 'ModAmp'), modUnits, "mTesla"))));
end

if spinFunction == "pepper"
    mode = lowerToken(optionValue(options, ["Mode", "PepperMode"], "perpendicular"));
    if ~ismember(mode, ["parallel", "perpendicular"])
        error('spinachgui:UnsupportedPepperMode', 'Unsupported pepper mode "%s".', mode);
    end
    lines = appendLine(lines, sprintf("Exp.Mode = '%s' ;", mode));
end

lines = appendLine(lines, sprintf('Exp.Harmonic = %s;', formatOptionText(optionValue(options, "Harmonic", "1"), 'Harmonic')));
lines = appendLine(lines, sprintf('Exp.nPoints = %s;', formatOptionText(optionValue(options, ["nPoints", "NPoints", "Points"], "1024"), 'nPoints')));

if logicalOption(optionValue(options, ["TemperatureEnabled", "UseTemperature"], false), 'TemperatureEnabled')
    temperature = optionValue(options, "Temperature", "0");
    lines = appendLine(lines, sprintf('Exp.Temperature = %s;', formatOptionText(temperature, 'Temperature')));
end

if spinFunction == "pepper"
    crystalSymmetry = optionValue(options, "CrystalSymmetry", "1");
    lines = appendLine(lines, sprintf('Exp.CrystalSymmetry = %s;', crystalSymmetryText(crystalSymmetry)));
end
end

function lines = appendOptionLines(lines, options, spinFunction)
switch spinFunction
    case "garlic"
        method = lowerToken(optionValue(options, ["GarlicMethod", "Method"], "exact"));
        allowed = ["exact", "perturb1", "perturb2", "perturb3", "perturb4", "perturb5"];
        if ~ismember(method, allowed)
            error('spinachgui:UnsupportedGarlicMethod', 'Unsupported garlic method "%s".', method);
        end
        lines = appendLine(lines, sprintf("Opt.Method = '%s' ;", method));
    case "chili"
        output = lowerToken(optionValue(options, ["ChiliOutput", "Output"], "summed"));
        if ~ismember(output, ["summed", "seperate"])
            error('spinachgui:UnsupportedChiliOutput', 'Unsupported chili output "%s".', output);
        end
        lines = appendLine(lines, sprintf("Opt.Output = '%s' ;", output));
        lines = appendLine(lines, sprintf('Opt.Verbosity = %d ;', verbosityIndex(optionValue(options, ["ChiliVerbosity", "Verbosity"], "No Print"), 1)));
        lines = appendChiliOptionalLines(lines, options);
    case "pepper"
        method = lowerToken(optionValue(options, ["PepperMethod", "Method"], "matrix"));
        if ~ismember(method, ["matrix", "perturb1", "perturb2", "hybrid"])
            error('spinachgui:UnsupportedPepperMethod', 'Unsupported pepper method "%s".', method);
        end
        output = lowerToken(optionValue(options, ["PepperOutput", "Output"], "summed"));
        if ~ismember(output, ["summed", "seperate"])
            error('spinachgui:UnsupportedPepperOutput', 'Unsupported pepper output "%s".', output);
        end
        symmetry = optionValue(options, ["Symmetry", "PepperSymmetry"], "auto");
        lines = appendLine(lines, sprintf("Opt.Method = '%s' ;", method));
        lines = appendLine(lines, sprintf("Opt.Output = '%s' ;", output));
        lines = appendLine(lines, sprintf("Opt.Symmetry = '%s' ;", escapeMatlabString(strtrim(char(string(symmetry))))));
        lines = appendLine(lines, sprintf('Opt.Verbosity = %d ;', verbosityIndex(optionValue(options, ["PepperVerbosity", "Verbosity"], "No Print"), 2)));
        knots = numericScalar(optionValue(options, ["PepperKnots", "nKnots", "Knots"], 0), 'PepperKnots');
        if logicalOption(optionValue(options, ["Interpolate", "InterpolationEnabled"], false), 'Interpolate')
            interp = numericScalar(optionValue(options, ["InterpolatePoints", "InterpolationPoints"], 0), 'InterpolatePoints');
        else
            interp = 0;
        end
        lines = appendLine(lines, sprintf('Opt.nKnots = [%s %s];', formatGeneral(knots), formatGeneral(interp)));
        logThreshold = numericScalar(optionValue(options, ["LogThreshold", "ThresholdLog"], -4), 'LogThreshold');
        logIsoCutoff = numericScalar(optionValue(options, ["LogIsoCutoff", "IsoCutoffLog"], -4), 'LogIsoCutoff');
        lines = appendLine(lines, sprintf('Opt.Threshold = %s;', formatGeneral(10^logThreshold)));
        lines = appendLine(lines, sprintf('Opt.IsoCutoff = %s;', formatGeneral(10^logIsoCutoff)));
        intensity = logicalOption(optionValue(options, "Intensity", true), 'Intensity');
        lines = appendLine(lines, sprintf("Opt.Intensity = '%s';", ternary(intensity, 'on', 'off')));
end
end

function lines = appendChiliOptionalLines(lines, options)
if optionPresent(options, ["MOMD", "MOMDEnabled", "nKnots", "ChiliKnots", "Psi", "DirectorTilt"])
    momd = logicalOption(optionValue(options, ["MOMD", "MOMDEnabled"], false), 'MOMD');
    lines = appendLine(lines, sprintf('Exp.MOMD = %d;', double(momd)));
    if momd
        knots = numericScalar(optionValue(options, ["ChiliKnots", "nKnots", "Knots"], 5), 'ChiliKnots');
        lines = appendLine(lines, sprintf('Opt.nKnots = %s;', formatGeneral(knots)));
    else
        psi = optionValue(options, ["Psi", "DirectorTilt"], []);
        if ~isEmptyOption(psi)
            lines = appendLine(lines, sprintf('Exp.psi = %s;', formatOptionText(psi, 'Psi')));
        end
    end
end
if optionPresent(options, "LLKM")
    llkm = numericVector(optionValue(options, "LLKM", []), 'LLKM');
    if numel(llkm) ~= 4
        error('spinachgui:InvalidLLKM', 'LLKM must contain four values: even Lmax, odd Lmax, even Kmax, odd Mmax.');
    end
    lines = appendLine(lines, sprintf('Opt.LLKM = [%s %s %s %s];', formatGeneral(llkm(1)), formatGeneral(llkm(2)), formatGeneral(llkm(3)), formatGeneral(llkm(4))));
end
end

function lines = appendBroadeningLines(lines, options, spinFunction)
broadeningUnits = optionValue(options, ["BroadeningUnits", "BroadUnits"], "Gauss");
gaussianPP = broadeningPP(options, ["GaussianPP", "GaussianPeakToPeak"], ["GaussianFWHM", "GaussianFullWidthHalfMaximum"], sqrt(2 * log(2)), 0);
lorentzianPP = broadeningPP(options, ["LorentzianPP", "LorentzianPeakToPeak"], ["LorentzianFWHM", "LorentzianFullWidthHalfMaximum"], sqrt(3), 0);
gaussianPP = convertEasySpinUnit(gaussianPP, broadeningUnits, "Gauss");
lorentzianPP = convertEasySpinUnit(lorentzianPP, broadeningUnits, "Gauss");
if ~isnan(lorentzianPP)
    lines = appendLine(lines, sprintf('Sys.lwpp = [%s %s];', formatGeneral(gaussianPP), formatGeneral(lorentzianPP)));
elseif ~isnan(gaussianPP)
    lines = appendLine(lines, sprintf('Sys.lwpp = %s;', formatGeneral(gaussianPP)));
end

if spinFunction ~= "pepper"
    return
end
lines = appendStrainLine(lines, options, "HStrain", 3);
lines = appendStrainLine(lines, options, "gStrain", 3);
lines = appendStrainLine(lines, options, "AStrain", 3);
if optionPresent(options, "DStrain")
    values = numericVector(optionValue(options, "DStrain", []), 'DStrain');
    if numel(values) ~= 2 && numel(values) ~= 3
        error('spinachgui:InvalidDStrain', 'DStrain must contain two or three values.');
    end
    if numel(values) == 2
        lines = appendLine(lines, sprintf('Sys.DStrain = [%s %s];', formatGeneral(values(1)), formatGeneral(values(2))));
    else
        lines = appendLine(lines, sprintf('Sys.DStrain = [%s %s %s];', formatGeneral(values(1)), formatGeneral(values(2)), formatGeneral(values(3))));
    end
end
end

function lines = appendDynamicsLines(lines, options, spinFunction)
if spinFunction == "pepper"
    if optionPresent(options, ["CorrelationTime", "tcorr", "Diffusion", "DiffusionTensor"])
        error('spinachgui:PepperDynamicsUnsupported', 'Legacy EasySpin pepper export disables dynamics controls.');
    end
    return
end

mode = lowerToken(optionValue(options, ["DynamicsMode", "RotationalMode"], "isotropic"));
if spinFunction == "garlic" && mode ~= "isotropic"
    error('spinachgui:GarlicDynamicsUnsupported', 'Legacy EasySpin garlic export only supports isotropic dynamics.');
end
if ~ismember(mode, ["isotropic", "axial", "rhombic"])
    error('spinachgui:UnsupportedDynamicsMode', 'Unsupported EasySpin dynamics mode "%s".', mode);
end

switch mode
    case "isotropic"
        tcorr = tcorrSeconds(options, ["CorrelationTime", "tcorr", "Tcorr"], ["Diffusion", "DiffusionTensor"], 1, 0);
        lines = appendLine(lines, sprintf('Sys.tcorr = %s;', formatGeneral(tcorr)));
    case "axial"
        tcorr = tcorrSeconds(options, ["AxialCorrelationTime", "CorrelationTime", "tcorr", "Tcorr"], ["AxialDiffusion", "Diffusion", "DiffusionTensor"], 2, [0 0]);
        lines = appendLine(lines, sprintf('Sys.tcorr = [%s %s];', formatGeneral(tcorr(1)), formatGeneral(tcorr(2))));
    case "rhombic"
        tcorr = tcorrSeconds(options, ["RhombicCorrelationTime", "CorrelationTime", "tcorr", "Tcorr"], ["RhombicDiffusion", "Diffusion", "DiffusionTensor"], 3, [0 0 0]);
        lines = appendLine(lines, sprintf('Sys.tcorr = [%s %s %s];', formatGeneral(tcorr(1)), formatGeneral(tcorr(2)), formatGeneral(tcorr(3))));
end

if spinFunction == "chili"
    if optionPresent(options, ["Ordering", "OrderingPotential", "labda", "Lambda"])
        ordering = numericVector(optionValue(options, ["Ordering", "OrderingPotential", "labda", "Lambda"], []), 'Ordering');
        if numel(ordering) ~= 5
            error('spinachgui:InvalidOrderingPotential', 'Ordering potential must contain five values: l20, l22, l40, l42, l44.');
        end
        lines = appendLine(lines, sprintf('Sys.labda = [%s %s %s %s %s];', formatGeneral(ordering(1)), formatGeneral(ordering(2)), formatGeneral(ordering(3)), formatGeneral(ordering(4)), formatGeneral(ordering(5))));
    end
    if optionPresent(options, ["Exchange", "HeisenbergExchange"])
        exchange = optionValue(options, ["Exchange", "HeisenbergExchange"], []);
        if ~isEmptyOption(exchange)
            lines = appendLine(lines, sprintf('Sys.Exchange = %s;', formatOptionText(exchange, 'Exchange')));
        end
    end
end
end

function value = tcorrSeconds(options, timeFields, diffusionFields, requiredCount, defaultValue)
if optionPresent(options, diffusionFields) && ~optionPresent(options, timeFields)
    diffusion = numericVector(optionValue(options, diffusionFields, []), 'Diffusion');
    if isscalar(diffusion) && requiredCount > 1
        diffusion = repmat(diffusion, 1, requiredCount);
    end
    if numel(diffusion) ~= requiredCount
        error('spinachgui:InvalidDiffusionTensor', 'Diffusion tensor must contain %d value(s).', requiredCount);
    end
    if any(diffusion <= 0)
        error('spinachgui:InvalidDiffusionTensor', 'Diffusion values must be positive when converting to correlation times.');
    end
    diffusionUnits = optionValue(options, ["DiffusionUnits", "DiffUnits"], "GHz");
    diffusionHz = convertEasySpinUnit(diffusion, diffusionUnits, "Hz");
    value = 1 ./ (6 .* diffusionHz);
    return
end

value = numericVector(optionValue(options, timeFields, defaultValue), 'CorrelationTime');
if isscalar(value) && requiredCount > 1
    value = repmat(value, 1, requiredCount);
end
if numel(value) ~= requiredCount
    error('spinachgui:InvalidCorrelationTime', 'Correlation time must contain %d value(s).', requiredCount);
end
if logicalOption(optionValue(options, ["LogDynamics", "Log10Dynamics", "DynamicsLog10"], false), 'LogDynamics')
    value = 10 .^ value;
end
timeUnits = optionValue(options, ["CorrelationTimeUnits", "TimeUnits", "TcorrUnits"], "ns");
value = convertEasySpinUnit(value, timeUnits, "Seconds");
end

function value = broadeningPP(options, ppFields, fwhmFields, divisor, defaultValue)
if optionPresent(options, ppFields)
    value = numericScalar(optionValue(options, ppFields, []), char(ppFields(1)));
elseif optionPresent(options, fwhmFields)
    value = numericScalar(optionValue(options, fwhmFields, []), char(fwhmFields(1))) / divisor;
else
    value = defaultValue;
end
end

function lines = appendStrainLine(lines, options, fieldName, nValues)
if ~optionPresent(options, fieldName)
    return
end
values = numericVector(optionValue(options, fieldName, []), char(fieldName));
if isscalar(values)
    values = repmat(values, 1, nValues);
end
if numel(values) ~= nValues
    error('spinachgui:InvalidStrain', '%s must contain %d values.', char(fieldName), nValues);
end
lines = appendLine(lines, sprintf('Sys.%s = [%s %s %s];', char(fieldName), formatGeneral(values(1)), formatGeneral(values(2)), formatGeneral(values(3))));
end

function validateEasySpinAtoms(atoms)
if ~any(atoms.Element == "e")
    error('spinachgui:EasySpinRequiresElectron', 'EasySpin export requires at least one electron atom.');
end
if any(atoms.Element == "chi")
    error('spinachgui:EasySpinChiAtomUnsupported', 'EasySpin export does not support chi pseudo-atoms.');
end
end

function validateInteractionKinds(interactions)
allowedKinds = ["HFC", "GTensor", "ZFS", "Quadrupolar", "Shift", "Jcoupling", "Exchange", ...
    "CHITensor", "CBond", "Dipolar", "CShielding", "spinrotation"];
badKinds = setdiff(unique(interactions.Kind), allowedKinds);
if ~isempty(badKinds)
    error('spinachgui:UnsupportedEasySpinInteraction', 'Unsupported EasySpin interaction kind(s): %s.', strjoin(badKinds, ', '));
end
if any(interactions.Kind == "Quadrupolar")
    error('spinachgui:EasySpinQuadrupolarUnsupported', ...
        ['Quadrupolar EasySpin export is deliberately disabled: the legacy C++ string construction ', ...
        'is malformed when quadrupolar data are present, and corrected parity has not been specified.']);
end
end

function atomIDs = validateAtomIDs(atomIDs)
atomIDs = atomIDs(:).';
if isempty(atomIDs)
    error('spinachgui:NoAtoms', 'EasySpin export requires at least one atom.');
end
if any(~isfinite(atomIDs)) || any(atomIDs <= 0) || any(atomIDs ~= fix(atomIDs))
    error('spinachgui:InvalidAtomID', 'EasySpin export requires positive integer atom IDs.');
end
if numel(unique(atomIDs)) ~= numel(atomIDs)
    error('spinachgui:DuplicateAtomID', 'EasySpin export requires unique atom IDs.');
end
if ~isequal(atomIDs, 1:max(atomIDs))
    error('spinachgui:NonContiguousAtomIDs', 'EasySpin export requires contiguous atom IDs for legacy dictionary-order output.');
end
end

function assertElectronCentred(inter, atoms, atomIDs, kindName)
atomA = primaryAtomID(inter, atomIDs);
rowA = atomRow(atoms, atomA);
if atoms.Element(rowA) ~= "e"
    error('spinachgui:InvalidElectronInteractionAtom', '%s interaction %d must be centred on an electron atom.', kindName, inter.ID);
end
end

function atomB = secondaryAtomID(inter, atomIDs, defaultID)
atomB = inter.B;
if isempty(atomB) || isnan(atomB) || atomB <= 0
    atomB = defaultID;
end
if ~ismember(atomB, atomIDs)
    error('spinachgui:InvalidInteractionAtom', 'Interaction %d references missing atom ID %g.', inter.ID, atomB);
end
end

function atomA = primaryAtomID(inter, atomIDs)
atomA = inter.A;
if isempty(atomA) || isnan(atomA) || atomA <= 0 || ~ismember(atomA, atomIDs)
    error('spinachgui:InvalidInteractionAtom', 'Interaction %d references missing atom ID %g.', inter.ID, atomA);
end
end

function row = atomRow(atoms, atomID)
row = find(atoms.ID == atomID, 1);
if isempty(row)
    error('spinachgui:InvalidInteractionAtom', 'Interaction references missing atom ID %g.', atomID);
end
end

function matrix = labMatrix(model, inter)
matrix = inter.Matrix{1};
if ~isequal(size(matrix), [3 3]) || ~isnumeric(matrix) || any(~isfinite(matrix), 'all')
    error('spinachgui:InvalidInteractionMatrix', 'Interaction %d must contain a finite 3x3 numeric matrix.', inter.ID);
end
frameID = inter.ReferenceFrameID;
if isempty(frameID) || isnan(frameID)
    rotation = eye(3);
else
    if ~ismember(frameID, model.ReferenceFrames.ID)
        error('spinachgui:MissingReferenceFrame', 'Interaction %d references missing frame ID %g.', inter.ID, frameID);
    end
    rotation = model.referenceFrameToRootMatrix(frameID);
end
matrix = rotation * matrix * rotation.';
end

function out = isotopeLabel(mass, element)
if mass <= 0 || element == "e" || element == "chi"
    error('spinachgui:InvalidEasySpinNucleus', 'EasySpin nucleus labels require a non-electron isotope with positive mass.');
end
out = sprintf('%d%s', mass, element);
end

function text = matrixLiteralFixed6(matrix)
rows = strings(1, 3);
for r = 1:3
    rows(r) = sprintf('%s, %s, %s', formatFixed6(matrix(r, 1)), formatFixed6(matrix(r, 2)), formatFixed6(matrix(r, 3)));
end
text = char("[" + strjoin(rows, "; ") + "]");
end

function valueOut = convertEasySpinUnit(valueIn, fromUnit, toUnit)
valueOut = spinachgui.convertUnit(valueIn, canonicalUnitName(fromUnit), canonicalUnitName(toUnit));
end

function unit = canonicalUnitName(unitName)
unit = strtrim(string(unitName));
unit = replace(unit, "µ", "μ");
switch lower(char(unit))
    case {"gauss", "g"}
        unit = "Gauss";
    case {"mt", "mtesla", "millitesla"}
        unit = "mTesla";
    case {"hz"}
        unit = "Hz";
    case {"khz", "kHz"}
        unit = "KHz";
    case {"mhz"}
        unit = "MHz";
    case {"ghz"}
        unit = "GHz";
    case {"seconds", "second", "sec", "s"}
        unit = "Seconds";
    case {"ns", "nsec", "nanosecond", "nanoseconds"}
        unit = "nsec";
    case {"mi_sec", "μs", "us", "usec", "microsecond", "microseconds"}
        unit = "mi_sec";
    otherwise
        unit = string(unitName);
end
end

function value = optionValue(options, names, defaultValue)
fields = fieldnames(options);
for n = string(names)
    idx = find(strcmpi(fields, char(n)), 1);
    if ~isempty(idx)
        value = options.(fields{idx});
        return
    end
end
value = defaultValue;
end

function present = optionPresent(options, names)
fields = fieldnames(options);
present = false;
for n = string(names)
    if any(strcmpi(fields, char(n)))
        present = true;
        return
    end
end
end

function out = lowerToken(value)
out = lower(strtrim(string(value)));
if numel(out) ~= 1 || strlength(out) == 0
    error('spinachgui:InvalidOptionValue', 'Expected a non-empty scalar text option.');
end
end

function value = numericScalar(raw, name)
value = numericVector(raw, name);
if ~isscalar(value)
    error('spinachgui:InvalidNumericOption', '%s must be a scalar numeric value.', name);
end
end

function value = numericVector(raw, name)
if isstring(raw) || ischar(raw)
    text = strtrim(char(string(raw)));
    if isempty(text)
        value = [];
        return
    end
    value = sscanf(text, '%f').';
    if isempty(value)
        error('spinachgui:InvalidNumericOption', '%s must contain numeric value(s).', name);
    end
elseif isnumeric(raw)
    value = raw(:).';
elseif islogical(raw)
    value = double(raw(:).');
else
    error('spinachgui:InvalidNumericOption', '%s must contain numeric value(s).', name);
end
if any(~isfinite(value))
    error('spinachgui:InvalidNumericOption', '%s contains non-finite value(s).', name);
end
end

function value = logicalOption(raw, name)
if islogical(raw)
    if ~isscalar(raw)
        error('spinachgui:InvalidLogicalOption', '%s must be a scalar logical value.', name);
    end
    value = raw;
elseif isnumeric(raw)
    if ~isscalar(raw)
        error('spinachgui:InvalidLogicalOption', '%s must be a scalar logical value.', name);
    end
    value = raw ~= 0;
elseif isstring(raw) || ischar(raw)
    text = lower(strtrim(char(string(raw))));
    switch text
        case {"true", "on", "yes", "1"}
            value = true;
        case {"false", "off", "no", "0", ""}
            value = false;
        otherwise
            error('spinachgui:InvalidLogicalOption', '%s must be true or false.', name);
    end
else
    error('spinachgui:InvalidLogicalOption', '%s must be true or false.', name);
end
end

function requireNonEmpty(value, name)
if isEmptyOption(value)
    error('spinachgui:MissingEasySpinOption', '%s must be supplied for this EasySpin export option.', name);
end
end

function tf = isEmptyOption(value)
if isempty(value)
    tf = true;
elseif isstring(value) || ischar(value)
    tf = strlength(strtrim(string(value))) == 0;
else
    tf = false;
end
end

function text = formatOptionText(value, name)
if isEmptyOption(value)
    error('spinachgui:MissingEasySpinOption', '%s must not be empty.', name);
end
if isnumeric(value)
    if ~isscalar(value) || ~isfinite(value)
        error('spinachgui:InvalidNumericOption', '%s must be a finite scalar numeric value.', name);
    end
    text = formatGeneral(value);
elseif islogical(value)
    text = formatGeneral(double(value));
elseif isstring(value) || ischar(value)
    text = strtrim(char(string(value)));
else
    error('spinachgui:InvalidOptionValue', '%s has an unsupported value type.', name);
end
end

function text = crystalSymmetryText(value)
raw = strtrim(char(string(value)));
if isempty(raw)
    error('spinachgui:MissingEasySpinOption', 'CrystalSymmetry must not be empty.');
end
parsed = sscanf(raw, '%d');
if isscalar(parsed) && strcmp(raw, sprintf('%d', parsed))
    text = raw;
else
    text = sprintf("'%s'", escapeMatlabString(raw));
end
end

function idx = verbosityIndex(value, maxIndex)
if isnumeric(value)
    idx = numericScalar(value, 'Verbosity');
    if idx < 0 || idx > maxIndex || idx ~= fix(idx)
        error('spinachgui:InvalidVerbosity', 'Verbosity index must be an integer between 0 and %d.', maxIndex);
    end
    return
end
text = lowerToken(value);
switch text
    case {"no print", "noprint", "none"}
        idx = 0;
    case {"print"}
        idx = 1;
    case {"detailed print", "detailed"}
        idx = 2;
    otherwise
        error('spinachgui:InvalidVerbosity', 'Unsupported verbosity value "%s".', text);
end
if idx > maxIndex
    error('spinachgui:InvalidVerbosity', 'Verbosity "%s" is not available for this EasySpin function.', text);
end
end

function lines = appendLine(lines, line)
lines(end+1, 1) = string(line);
end

function text = formatFixed6(value)
if abs(value) < 0.5e-12
    value = 0;
end
text = sprintf('%.6f', value);
end

function text = formatGeneral(value)
if abs(value) < 0.5e-15
    value = 0;
end
text = sprintf('%.12g', value);
end

function text = escapeMatlabString(value)
text = strrep(char(value), '''', '''''');
end

function out = ternary(condition, trueValue, falseValue)
if condition
    out = trueValue;
else
    out = falseValue;
end
end
