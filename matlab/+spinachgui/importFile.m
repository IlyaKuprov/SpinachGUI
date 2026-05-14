function model = importFile(filename)
%IMPORTFILE Dispatch supported import formats to MATLAB SpinachGUI readers.

[~,~,ext] = fileparts(filename);
switch lower(ext)
    case '.xyz'
        model = spinachgui.readXYZ(filename);
    case {'.sxml', '.xml'}
        model = spinachgui.readSpinXML(filename);
    case '.mol'
        model = spinachgui.readMOL(filename);
    case {'.log', '.out'}
        model = importTextOutput(filename);
    case '.magres'
        model = spinachgui.readCastep(filename);
    otherwise
        error('spinachgui:UnsupportedImport', 'Import for "%s" is not implemented in the MATLAB port yet.', ext);
end
end

function model = importTextOutput(filename)
text = fileread(filename);
if contains(text, 'CARTESIAN COORDINATES (A.U.)') || contains(text, 'The g-matrix:') || ...
        contains(text, 'ZERO-FIELD-SPLITTING TENSOR') || contains(text, 'CHEMICAL SHIFTS') || ...
        contains(text, 'ELECTRIC AND MAGNETIC HYPERFINE STRUCTURE')
    model = spinachgui.readOrca(filename);
elseif contains(text, 'Standard orientation:') || contains(text, 'Input orientation:') || contains(text, 'SCF GIAO Magnetic shielding tensor')
    model = spinachgui.readGaussian(filename);
elseif contains(text, 'Amsterdam Density Functional') || ...
        contains(text, 'G E O M E T R Y  ***  3D  Molecule  ***') || ...
        contains(text, 'Stephen K. Wolff & Georg Schreckenbach') || ...
        contains(text, '*  NMR spin spin coupling tensor calculation  *')
    model = spinachgui.readADF(filename);
elseif contains(text, '***** EQUILIBRIUM GEOMETRY LOCATED *****')
    model = spinachgui.readGAMESS(filename);
else
    error('spinachgui:UnsupportedImport', 'Could not recognise Gaussian, ORCA, ADF, or GAMESS content in %s.', filename);
end
end
