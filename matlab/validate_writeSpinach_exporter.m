function validate_writeSpinach_exporter()
%VALIDATE_WRITESPINACH_EXPORTER Deterministic Spinach exporter parity smoke test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

model = spinachgui.Model();
model.addAtom("1H", [0 0 0], "alpha", false);
model.addAtom("13C", [1 0 0], "", false);
model.addAtom("E", [0 1 0], "", false);
model.addAtom("chi", [2 2 2], "", false);
model.addAtom("E", [0 0 1], "", false);

model.addInteraction("Shift", 1, 1, diag([10 20 30]), "ppm", "", 1, "", "validation");
model.addInteraction("Jcoupling", 1, 2, diag([123 4 5]), "Hz", "", 1, "", "validation");
model.addInteraction("HFC", 1, 3, [1 0.1 0.2; 0.1 2 0.3; 0.2 0.3 3], "Gauss", "", 1, "", "validation");
model.addInteraction("GTensor", 3, 3, diag([2.001 2.002 2.003]), "Unknown", "", 1, "", "validation");
model.addInteraction("ZFS", 3, 3, diag([-1 0.25 0.75]), "MHz", "", 1, "", "validation");
model.addInteraction("CHITensor", 4, 4, diag([0.1 0.2 0.3]), "Unknown", "", 1, "", "validation");
model.addInteraction("Quadrupolar", 2, 2, diag([1 2 4]), "MHz", "", 1, "", "validation");
model.addInteraction("Exchange", 3, 5, diag([0.5 0.6 0.7]), "MHz", "", 1, "", "validation");

tmpDir = tempname;
mkdir(tmpDir);
cleanup = onCleanup(@() cleanupTempDir(tmpDir));
outFile = fullfile(tmpDir, 'spinach_exporter_fixture.m');
spinachgui.writeSpinach(model, outFile);
text = fileread(outFile);

assertContains(text, 'function spinach_exporter_fixture()');
assertContains(text, 'sys.magnet=14.100;');
assertContains(text, "sys.isotopes={'1H', '13C', 'E', 'chi', 'E'};");
assertContains(text, "sys.labels{1}= 'alpha';");
assertContains(text, 'inter.coordinates={[0 0 0];');
assertContains(text, '                   [1 0 0];');
assertContains(text, '                   [];');
assertContains(text, 'inter.coupling.matrix{1,3}=1e6*gauss2mhz(');
assertContains(text, 'inter.coupling.matrix{3,5}=[5.000e-001');
assertContains(text, 'inter.coupling.matrix{2,2}=1e6*[-1.333e+000');
assertContains(text, 'inter.coupling.matrix{3,3}=[-1.000e+000');
assertContains(text, 'inter.coupling.scalar{1,2}=1.230e+002;');
assertContains(text, 'inter.suscept.chi={[0.1000000 0.0000000 0.0000000;');
assertContains(text, 'inter.suscept.xyz={[2 2 2]};');
assertContains(text, 'inter.zeeman.matrix{1}=[1.000e+001');
assertContains(text, 'inter.zeeman.matrix{3}=[2.0010000');
assert(~contains(text, 'bas.formalism'), 'Legacy parity output must not emit basis boilerplate.');
assert(~contains(text, 'spin_system=basis'), 'Legacy parity output must not call basis().');

sections = ["% Magnet induction", "% Isotopes", "% Lables", "% Coordinates", ...
    "% Coupling Matrices", "% Scalar Couplings", "% Susceptibility tensor", ...
    "% Susceptibility coordinates", "% Zeeman Interactions", "% Spinach housekeeping"];
positions = arrayfun(@(s) firstPosition(text, s), sections);
assert(all(positions > 0), 'One or more required Spinach exporter sections are missing.');
assert(issorted(positions), 'Spinach exporter sections are not in legacy order.');
assert(firstPosition(text, 'inter.zeeman.matrix{1}=') < firstPosition(text, 'inter.zeeman.matrix{3}='), ...
    'Zeeman interactions must be sorted by atom ID.');

fprintf('SPINACH_WRITE_EXPORTER_VALIDATION_OK\n');
end

function assertContains(text, snippet)
assert(contains(text, snippet), 'Expected output snippet missing: %s', char(snippet));
end

function pos = firstPosition(text, snippet)
idx = strfind(text, char(snippet));
if isempty(idx)
    pos = 0;
else
    pos = idx(1);
end
end

function cleanupTempDir(tmpDir)
if isfolder(tmpDir)
    rmdir(tmpDir, 's');
end
end
