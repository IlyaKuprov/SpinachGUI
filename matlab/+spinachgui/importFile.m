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
else
    error('spinachgui:UnsupportedImport', 'Could not recognise Gaussian or ORCA content in %s.', filename);
end
end
