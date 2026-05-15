function validate_readGAMESS_importer()
%VALIDATE_READGAMESS_IMPORTER Deterministic GAMESS coordinate import test.

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);
fixture = [tempname(tempdir), '.out'];
cleanup = onCleanup(@() deleteIfExists(fixture));
writeSyntheticGAMESSFixture(fixture);

model = spinachgui.readGAMESS(fixture);
assert(model.SourceFile == string(fixture), 'GAMESS SourceFile was not preserved.');
assert(~model.Dirty, 'GAMESS import should leave a clean model.');
assert(height(model.Atoms) == 3, 'Synthetic GAMESS fixture should import three atoms.');
assert(isequal(model.Atoms.Element, ["O"; "H"; "H"]), 'Unexpected GAMESS atom elements.');
assert(isequal(model.Atoms.Mass, [17; 1; 1]), 'Unexpected GAMESS default isotope masses.');
assert(height(model.positiveInteractions()) == 0, 'Legacy GAMESS importer should not create scientific interactions.');

expectedXYZ = [1.00, 2.00, 3.00; 1.00, 2.00, 3.96; 1.93, 2.00, 2.76];
actualXYZ = [model.Atoms.X, model.Atoms.Y, model.Atoms.Z];
assertClose(actualXYZ, expectedXYZ, 1e-12, 'last GAMESS coordinate frame');

imported = spinachgui.importFile(fixture);
assert(height(imported.Atoms) == 3, 'GAMESS dispatch should preserve atom count.');
assertClose([imported.Atoms.X, imported.Atoms.Y, imported.Atoms.Z], expectedXYZ, 1e-12, 'GAMESS dispatch coordinates');

bohrFixture = [tempname(tempdir), '.out'];
bohrCleanup = onCleanup(@() deleteIfExists(bohrFixture));
writeSyntheticGAMESSBohrFixture(bohrFixture);
bohrModel = spinachgui.importFile(bohrFixture);
assert(height(bohrModel.Atoms) == 2, 'GAMESS Bohr fallback should import two atoms.');
assert(isequal(bohrModel.Atoms.Element, ["C"; "H"]), 'Unexpected GAMESS Bohr fallback atom elements.');
assertClose([bohrModel.Atoms.X, bohrModel.Atoms.Y, bohrModel.Atoms.Z], ...
    [0 0 0; 0.529177210903 0 0], 1e-12, 'GAMESS Bohr fallback coordinates');
clear bohrCleanup

fprintf('GAMESS_IMPORTER_VALIDATION_OK\n');
end

function writeSyntheticGAMESSFixture(filename)
fid = fopen(filename, 'w');
assert(fid > 0, 'Could not create synthetic GAMESS fixture.');
closer = onCleanup(@() fclose(fid));
fprintf(fid, [' Synthetic legacy-compatible GAMESS output\n' ...
    '1     ***** EQUILIBRIUM GEOMETRY LOCATED *****\n' ...
    ' COORDINATES OF ALL ATOMS ARE (ANGS)\n' ...
    '   ATOM   CHARGE       X              Y              Z\n' ...
    ' ------------------------------------------------------------\n' ...
    ' O           8.0   0.0000000000   0.0000000000   0.0000000000\n' ...
    ' H           1.0   0.0000000000   0.0000000000   0.9500000000\n' ...
    ' H           1.0   0.9000000000   0.0000000000  -0.2500000000\n' ...
    '\n' ...
    ' Optimization continued; the legacy reader should keep the last frame.\n' ...
    '1     ***** EQUILIBRIUM GEOMETRY LOCATED *****\n' ...
    ' COORDINATES OF ALL ATOMS ARE (ANGS)\n' ...
    '   ATOM   CHARGE       X              Y              Z\n' ...
    ' ------------------------------------------------------------\n' ...
    ' O           8.0   1.0000000000   2.0000000000   3.0000000000\n' ...
    ' H           1.0   1.0000000000   2.0000000000   3.9600000000\n' ...
    ' H           1.0   1.9300000000   2.0000000000   2.7600000000\n' ...
    '\n']);
end

function writeSyntheticGAMESSBohrFixture(filename)
fid = fopen(filename, 'w');
assert(fid > 0, 'Could not create synthetic GAMESS Bohr fixture.');
closer = onCleanup(@() fclose(fid));
fprintf(fid, ['          *            GAMESS VERSION = TEST            *\n' ...
    ' ATOM      ATOMIC                      COORDINATES (BOHR)\n' ...
    '           CHARGE         X                   Y                   Z\n' ...
    ' C           6.0     0.0000000000        0.0000000000        0.0000000000\n' ...
    ' H           1.0     1.0000000000        0.0000000000        0.0000000000\n' ...
    '\n']);
end

function assertClose(actual, expected, tolerance, context)
assert(all(abs(actual - expected) <= tolerance, 'all'), 'Unexpected value for %s.', context);
end

function deleteIfExists(filename)
if exist(filename, 'file')
    delete(filename);
end
end
