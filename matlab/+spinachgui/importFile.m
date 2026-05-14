function model = importFile(filename)
%IMPORTFILE Dispatch supported import formats to MATLAB SpinachGUI readers.

[~,~,ext] = fileparts(filename);
switch lower(ext)
    case '.xyz'
        model = spinachgui.readXYZ(filename);
    case {'.sxml', '.xml'}
        model = spinachgui.readSpinXML(filename);
    otherwise
        error('spinachgui:UnsupportedImport', 'Import for "%s" is not implemented in the MATLAB port yet.', ext);
end
end
