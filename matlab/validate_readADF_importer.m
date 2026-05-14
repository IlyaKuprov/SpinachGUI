function validate_readADF_importer()
%VALIDATE_READADF_IMPORTER Deterministic ADF importer smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);
fixture = fullfile(thisDir, '..', 'examples', 'ADF', 'adf_example.out');

model = spinachgui.readADF(fixture);
assert(model.SourceFile == string(fixture), 'ADF SourceFile was not preserved.');
assert(~model.Dirty, 'ADF import should leave a clean model.');
assert(height(model.Atoms) == 8, 'ADF fixture should import eight atoms.');

expectedElements = ["C"; "C"; "H"; "H"; "H"; "H"; "H"; "H"];
expectedMasses = [13; 13; 1; 1; 1; 1; 1; 1];
assert(isequal(model.Atoms.Element, expectedElements), 'Unexpected ADF atom elements.');
assert(isequal(model.Atoms.Mass, expectedMasses), 'Unexpected ADF isotope masses.');
assertClose([model.Atoms.X(1), model.Atoms.Y(1), model.Atoms.Z(1)], [-1.0749, -0.7258, 0.0000], 1e-10, 'atom 1 coordinates');
assertClose([model.Atoms.X(8), model.Atoms.Y(8), model.Atoms.Z(8)], [0.4465, 0.1825, -1.0182], 1e-10, 'atom 8 coordinates');

positive = model.positiveInteractions();
shieldings = positive(positive.Kind == "CShielding", :);
jCouplings = positive(positive.Kind == "Jcoupling", :);
assert(height(shieldings) == 8, 'ADF fixture should import eight shielding tensors.');
assert(height(jCouplings) == 28, 'ADF fixture should import each unordered J-coupling once.');
assert(all(shieldings.Unit == "ppm"), 'ADF shielding tensors should be in ppm.');
assert(all(jCouplings.Unit == "Hz"), 'ADF J-couplings should be in Hz.');

shielding1 = interactionMatrix(shieldings, "CShielding", 1, 1);
expectedShielding1 = [200.458, 5.740, 0.622; 5.740, 194.280, 0.370; 0.622, 0.370, 188.665];
assertClose(shielding1, expectedShielding1, 1e-12, 'atom 1 shielding tensor');
assertClose(interactionMatrix(jCouplings, "Jcoupling", 1, 2), 137.514 * eye(3), 1e-12, '1-2 J-coupling');
assertClose(interactionMatrix(jCouplings, "Jcoupling", 1, 3), 106.799 * eye(3), 1e-12, '1-3 J-coupling');
assertClose(interactionMatrix(jCouplings, "Jcoupling", 3, 4), -13.771 * eye(3), 1e-12, '3-4 J-coupling');

imported = spinachgui.importFile(fixture);
assert(height(imported.Atoms) == 8, 'ADF dispatch should preserve atom count.');
assert(height(imported.positiveInteractions()) == 36, 'ADF dispatch should preserve positive interaction count.');

fprintf('ADF_IMPORTER_VALIDATION_OK\n');
end

function matrix = interactionMatrix(rows, kind, atomA, atomB)
idx = find(rows.Kind == kind & rows.A == atomA & rows.B == atomB, 1);
assert(~isempty(idx), 'Missing %s interaction for atoms %d-%d.', kind, atomA, atomB);
matrix = rows.Matrix{idx};
end

function assertClose(actual, expected, tolerance, context)
assert(all(abs(actual - expected) <= tolerance, 'all'), 'Unexpected value for %s.', context);
end
