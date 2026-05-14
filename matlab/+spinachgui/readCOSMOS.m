function model = readCOSMOS(filename)
%READCOSMOS Import legacy COSMOS COO files into a SpinachGUI model.
%   This reader preserves the historical SpinachGUI COSMOS adapter scope:
%   ATOMS records, CS-TENSOR shielding tensors, and scalar J-COUPLINGS.
%   Legacy-recognized RDC, order, quadrupolar, dipolar, and distance records are
%   recognized but ignored, as in the C++ reader.

lines = readlines(filename, 'EmptyLineRule', 'read');
atomSectionLine = findAtomSection(lines);
if isempty(atomSectionLine)
    error('spinachgui:UnsupportedCOSMOS', 'No COSMOS ATOMS section was found in %s.', filename);
end

model = spinachgui.Model();
model.SourceFile = string(filename);
addAtoms(model, lines, atomSectionLine, filename);
model.rebuildAutoBonds();

propertySectionLine = findPropertySection(lines);
if ~isempty(propertySectionLine)
    addCalculatedProperties(model, lines, propertySectionLine, filename);
end

model.Dirty = false;
end

function lineNumber = findAtomSection(lines)
lineNumber = [];
for k = 1:numel(lines)
    if ~isempty(parseAtomCount(char(lines(k))))
        lineNumber = k;
        return
    end
end
end

function lineNumber = findPropertySection(lines)
lineNumber = [];
for k = 1:numel(lines)
    if strcmp(strtrim(char(lines(k))), 'CALCULATED_PROPERTIES')
        lineNumber = k;
        return
    end
end
end

function addAtoms(model, lines, atomSectionLine, filename)
atomCount = parseAtomCount(char(lines(atomSectionLine)));
if isempty(atomCount) || isnan(atomCount) || atomCount < 0 || fix(atomCount) ~= atomCount
    error('spinachgui:InvalidCOSMOS', 'Invalid COSMOS atom count at line %d in %s.', atomSectionLine, filename);
end
if atomSectionLine + atomCount > numel(lines)
    error('spinachgui:InvalidCOSMOS', 'COSMOS ATOMS section at line %d is truncated in %s.', atomSectionLine, filename);
end

for k = 1:atomCount
    lineNumber = atomSectionLine + k;
    fields = splitFields(char(lines(lineNumber)));
    if numel(fields) < 5
        error('spinachgui:InvalidCOSMOS', 'Invalid COSMOS atom record at line %d in %s.', lineNumber, filename);
    end
    atomicNumber = parseInteger(fields{2});
    xyz = parseNumber(fields(3:5));
    if isnan(atomicNumber) || any(isnan(xyz))
        error('spinachgui:InvalidCOSMOS', 'Invalid COSMOS atom value at line %d in %s.', lineNumber, filename);
    end
    isotopeName = isotopeNameForCOSMOS(fields{1}, atomicNumber, filename, lineNumber);
    model.addAtom(isotopeName, xyz, "");
end
end

function addCalculatedProperties(model, lines, propertySectionLine, filename)
k = propertySectionLine + 1;
while k <= numel(lines)
    line = strtrim(char(lines(k)));
    if strcmp(line, 'END_CALCULATED_PROPERTIES')
        return
    end

    fields = splitFields(line);
    if ~isPropertyAtomHeader(fields)
        k = k + 1;
        continue
    end

    atomID = parseInteger(fields{1});
    requireAtom(model, atomID, filename, k, 'COSMOS calculated property');
    k = k + 1;
    while k <= numel(lines)
        line = strtrim(char(lines(k)));
        fields = splitFields(line);
        if strcmp(line, 'END_CALCULATED_PROPERTIES') || isPropertyAtomHeader(fields)
            break
        end
        if contains(line, 'CS-TENSOR')
            addShielding(model, fields, atomID, filename, k);
        elseif contains(line, 'J-COUPLINGS')
            addJCouplings(model, fields, atomID, filename, k);
        elseif contains(line, 'RDC-TENSOR') || contains(line, 'ORDER-TENSOR') || ...
                contains(line, 'QC-TENSOR') || contains(line, 'DD-TENSOR') || ...
                contains(line, 'DISTANCES') || isempty(line)
            % Legacy reader recognized these records but did not import them.
        else
            break
        end
        k = k + 1;
    end
end
end

function addShielding(model, fields, atomID, filename, lineNumber)
if numel(fields) ~= 7
    error('spinachgui:InvalidCOSMOS', 'Invalid COSMOS CS-TENSOR record at line %d in %s.', lineNumber, filename);
end
values = parseNumber(fields(2:7));
if any(isnan(values))
    error('spinachgui:InvalidCOSMOS', 'Invalid COSMOS CS-TENSOR value at line %d in %s.', lineNumber, filename);
end
xx = values(1);
yy = values(2);
zz = values(3);
xy = values(4);
xz = values(5);

% Preserve the historical COSMOS adapter's raw tensor layout. Model.addInteraction
% applies the same symmetrization as the legacy Tensor constructor.
matrix = [xx, xy, xz; xz, yy, 0; 0, 0, zz];
model.addInteraction('CShielding', atomID, atomID, matrix, 'ppm', '', 1, '', 'COSMOS shielding');
end

function addJCouplings(model, fields, atomID, filename, lineNumber)
for j = 1:floor((numel(fields) - 1) / 2)
    coupledAtomID = parseInteger(fields{2*j});
    value = parseNumber(fields(2*j + 1));
    if isnan(coupledAtomID) || isnan(value)
        error('spinachgui:InvalidCOSMOS', 'Invalid COSMOS J-COUPLINGS value at line %d in %s.', lineNumber, filename);
    end
    requireAtom(model, coupledAtomID, filename, lineNumber, 'COSMOS J-coupling');
    model.addInteraction('Jcoupling', atomID, coupledAtomID, value * eye(3), 'Hz', '', 1, '', 'COSMOS J coupling');
end
end

function count = parseAtomCount(line)
match = regexp(line, '^\s*ATOMS\s+([0-9]+)', 'tokens', 'once');
if isempty(match)
    count = [];
else
    count = str2double(match{1});
end
end

function tf = isPropertyAtomHeader(fields)
tf = numel(fields) >= 2 && ~isnan(parseInteger(fields{1})) && ...
    ~strcmp(fields{1}, 'J-COUPLINGS') && ~strcmp(fields{1}, 'CS-TENSOR');
end

function isotopeName = isotopeNameForCOSMOS(label, atomicNumber, filename, lineNumber)
element = elementFromCOSMOSLabel(label);
try
    spinachgui.findIsotope(element);
    isotopeName = element;
catch
    isotopeName = isotopeNameFromAtomNumber(atomicNumber, filename, lineNumber);
end
end

function element = elementFromCOSMOSLabel(label)
label = char(label);
if numel(label) >= 2 && isstrprop(label(2), 'lower')
    element = string(label(1:2));
elseif ~isempty(label)
    element = string(label(1));
else
    element = "";
end
end

function isotopeName = isotopeNameFromAtomNumber(atomicNumber, filename, lineNumber)
tableData = spinachgui.isotopeTable();
idx = find(tableData.AtomNumber == atomicNumber, 1);
if isempty(idx)
    error('spinachgui:InvalidCOSMOS', 'Unknown COSMOS atomic number %.15g at line %d in %s.', atomicNumber, lineNumber, filename);
end
isotopeName = tableData.Element(idx);
end

function requireAtom(model, atomID, filename, lineNumber, context)
if isnan(atomID) || ~ismember(atomID, model.Atoms.ID)
    error('spinachgui:InvalidCOSMOS', '%s refers to missing atom %d at line %d in %s.', context, atomID, lineNumber, filename);
end
end

function fields = splitFields(line)
fields = regexp(strtrim(line), '[\s,]+', 'split');
fields = fields(~cellfun('isempty', fields));
end

function number = parseNumber(tokens)
if ischar(tokens) || isstring(tokens)
    tokens = cellstr(tokens);
end
number = zeros(1, numel(tokens));
for k = 1:numel(tokens)
    token = regexprep(char(tokens{k}), '[dD]', 'E');
    number(k) = str2double(token);
end
end

function number = parseInteger(token)
number = str2double(char(token));
if isnan(number) || fix(number) ~= number
    number = NaN;
end
end
