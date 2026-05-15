function validate_readCastep_importer()
%VALIDATE_READCASTEP_IMPORTER Deterministic checks for CASTEP/MAGRES import.

matlabDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(matlabDir);
addpath(matlabDir);
magresDir = fullfile(repoRoot, 'examples', 'Magres');

alanine = spinachgui.readCastep(fullfile(magresDir, 'alanine.magres'));
assert(height(alanine.Atoms) == 52, 'alanine atom count changed.');
assertKindCount(alanine, 'CShielding', 52);
assertKindCount(alanine, 'Quadrupolar', 40);

ethanolNmr = spinachgui.readCastep(fullfile(magresDir, 'ethanol-nmr.magres'));
assert(height(ethanolNmr.Atoms) == 9, 'ethanol-nmr atom count changed.');
assertKindCount(ethanolNmr, 'CShielding', 9);
assertKindCount(ethanolNmr, 'Quadrupolar', 7);
assert(all(ethanolNmr.Atoms.Mass(ethanolNmr.Atoms.Element == "H") == 2), 'MAGRES H quadrupoles should upgrade protons to 2H.');
assertApprox(findInteraction(ethanolNmr, 'CShielding', 1, 1).Matrix{1}(1, 1), 30.275414382832704, 1e-12, 'MAGRES ms tensor value changed.');
assertApprox(findInteraction(ethanolNmr, 'Quadrupolar', 1, 1).Matrix{1}(1, 1), 0.12824174928074769, 1e-12, 'MAGRES efg tensor value changed.');

ethanolJ = spinachgui.readCastep(fullfile(magresDir, 'ethanol-jc.magres'));
assert(height(ethanolJ.Atoms) == 9, 'ethanol-jc atom count changed.');
assertKindCount(ethanolJ, 'Jcoupling', 8);
assert(all(ethanolJ.positiveInteractions().Unit == "ppm"), 'Legacy MAGRES J-coupling unit should remain ppm.');
expectedJ = mean([1.8373758951855776, 0.72064084469825995, 0.32826687128850490]);
assertApprox(findInteraction(ethanolJ, 'Jcoupling', 8, 1).Matrix{1}(1, 1), expectedJ, 1e-12, 'MAGRES isc trace handling changed.');

legacy = spinachgui.readCastep(fullfile(magresDir, 'glycine.magres'));
assert(height(legacy.Atoms) == 10, 'legacy glycine atom count changed.');
assertKindCount(legacy, 'CShielding', 10);
assertKindCount(legacy, 'Quadrupolar', 8);
assert(all(legacy.Atoms.Mass(legacy.Atoms.Element == "H") == 2), 'Legacy CASTEP H quadrupoles should upgrade protons to 2H.');
expectedLegacyQ = 0.0632 * 2.3496e+02 * 0.0029 / 2;
assertApprox(findInteraction(legacy, 'Quadrupolar', 1, 1).Matrix{1}(1, 1), expectedLegacyQ, 1e-12, 'Legacy CASTEP quadrupolar scaling changed.');

dispatched = spinachgui.importFile(fullfile(magresDir, 'ethanol-jc.magres'));
assertKindCount(dispatched, 'Jcoupling', 8);

fprintf('CASTEP_MAGRES_IMPORTER_VALIDATION_OK\n');
end

function assertKindCount(model, kind, expected)
rows = model.positiveInteractions();
actual = sum(rows.Kind == string(kind));
assert(actual == expected, '%s count changed: expected %d, got %d.', kind, expected, actual);
end

function row = findInteraction(model, kind, atomA, atomB)
rows = model.positiveInteractions();
idx = find(rows.Kind == string(kind) & rows.A == atomA & rows.B == atomB, 1);
assert(~isempty(idx), 'Missing %s interaction for atoms %d/%d.', kind, atomA, atomB);
row = rows(idx, :);
end

function assertApprox(actual, expected, tolerance, message)
assert(abs(actual - expected) <= tolerance, '%s Expected %.16g, got %.16g.', message, expected, actual);
end
