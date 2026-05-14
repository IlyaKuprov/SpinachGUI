function validate_readCOSMOS_importer()
%VALIDATE_READCOSMOS_IMPORTER Deterministic checks for COSMOS COO import.

matlabDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(matlabDir);
addpath(matlabDir);

fixtureText = syntheticCOSMOSFixture();
cooFixture = [tempname, '.coo'];
outFixture = [tempname, '.out'];
writeFixture(cooFixture, fixtureText);
writeFixture(outFixture, fixtureText);

model = spinachgui.readCOSMOS(cooFixture);
assert(model.SourceFile == string(cooFixture), 'COSMOS SourceFile was not preserved.');
assert(~model.Dirty, 'COSMOS import should leave a clean model.');
assert(height(model.Atoms) == 2, 'Synthetic COSMOS fixture should import two atoms.');
assert(isequal(model.Atoms.Element, ["C"; "H"]), 'Unexpected COSMOS atom elements.');
assert(isequal(model.Atoms.Mass, [13; 1]), 'Unexpected COSMOS isotope masses.');
assert(all(model.Atoms.Label == ""), 'Legacy COSMOS atom names should not become SpinachGUI labels.');
assertClose([model.Atoms.X(1), model.Atoms.Y(1), model.Atoms.Z(1)], [1, 2, 3], 1e-12, 'atom 1 coordinates');
assertClose([model.Atoms.X(2), model.Atoms.Y(2), model.Atoms.Z(2)], [-1, -2, -3], 1e-12, 'atom 2 coordinates');

assertKindCount(model, 'CShielding', 2, 'synthetic COSMOS');
assertKindCount(model, 'Jcoupling', 1, 'synthetic COSMOS');
positive = model.positiveInteractions();
assert(all(positive.Unit == "ppm" | positive.Unit == "Hz"), 'Unexpected COSMOS units.');
expectedShielding1 = [1, 4.5, 2.5; 4.5, 2, 0; 2.5, 0, 3];
assertClose(findInteraction(model, 'CShielding', 1, 1).Matrix{1}, expectedShielding1, 1e-12, 'legacy COSMOS shielding layout');
assertClose(findInteraction(model, 'Jcoupling', 1, 2).Matrix{1}, 7.5 * eye(3), 1e-12, 'COSMOS J-coupling');

cooDispatched = spinachgui.importFile(cooFixture);
assert(height(cooDispatched.Atoms) == 2, 'COSMOS .coo dispatch should preserve atom count.');
assertKindCount(cooDispatched, 'CShielding', 2, 'COSMOS .coo dispatch');

textDispatched = spinachgui.importFile(outFixture);
assert(height(textDispatched.Atoms) == 2, 'COSMOS content dispatch should preserve atom count.');
assertKindCount(textDispatched, 'Jcoupling', 1, 'COSMOS content dispatch');

delete(cooFixture);
delete(outFixture);

example = fullfile(repoRoot, 'examples', 'COSMOS', 'AspAlaFUMTAI_6_Mol_1H_3J.coo');
if isfile(example)
    exampleModel = spinachgui.readCOSMOS(example);
    assert(height(exampleModel.Atoms) == 72, 'COSMOS example atom count changed.');
    assertKindCount(exampleModel, 'CShielding', 67, 'COSMOS example');
    assertKindCount(exampleModel, 'Jcoupling', 16, 'COSMOS example');
    assertClose([exampleModel.Atoms.X(1), exampleModel.Atoms.Y(1), exampleModel.Atoms.Z(1)], ...
        [0.82629, 7.03135, 4.14038], 1e-12, 'COSMOS example atom 1 coordinates');
end

fprintf('COSMOS_IMPORTER_VALIDATION_OK\n');
end

function lines = syntheticCOSMOSFixture()
lines = { ...
    '$COO001'; ...
    'ATOMS 2'; ...
    'C1 6 1.0 2.0 3.0 csmb 0.0 0 0 0 0 0 0 0 0 0 0 0'; ...
    'H1 1 -1.0 -2.0 -3.0 csmb 0.0 0 0 0 0 0 0 0 0 0 0 0'; ...
    'CALCULATED_PROPERTIES'; ...
    '1 C1 CS-ISO 2.0'; ...
    '  CS-TENSOR 1 2 3 4 5 6'; ...
    '  J-COUPLINGS 2 7.5'; ...
    '  DISTANCES 1 2 1.0'; ...
    '2 H1 CS-ISO 20.0'; ...
    '  CS-TENSOR 10 20 30 40 50 60'; ...
    'END_CALCULATED_PROPERTIES'};
end

function writeFixture(filename, lines)
fid = fopen(filename, 'w');
assert(fid > 0, 'Could not write temporary COSMOS fixture %s.', filename);
for k = 1:numel(lines)
    fprintf(fid, '%s\n', lines{k});
end
fclose(fid);
end

function assertKindCount(model, kind, expected, context)
rows = model.positiveInteractions();
actual = sum(rows.Kind == string(kind));
assert(actual == expected, '%s %s count changed: expected %d, got %d.', context, kind, expected, actual);
end

function row = findInteraction(model, kind, atomA, atomB)
rows = model.positiveInteractions();
idx = find(rows.Kind == string(kind) & rows.A == atomA & rows.B == atomB, 1);
assert(~isempty(idx), 'Missing %s interaction for atoms %d/%d.', kind, atomA, atomB);
row = rows(idx, :);
end

function assertClose(actual, expected, tolerance, context)
assert(all(abs(actual - expected) <= tolerance, 'all'), 'Unexpected value for %s.', context);
end
