classdef Model < handle
    %MODEL Spin system model used by the MATLAB SpinachGUI rewrite.
    %   This is the MATLAB counterpart of GUI/System Core/Model.h.  It keeps
    %   atoms, interactions, and reference frames in MATLAB tables so the GUI
    %   and import/export layers share one mutable state object.

    properties
        Atoms table
        Interactions table
        ReferenceFrames table
        SourceFile string = ""
        Dirty logical = false
    end

    methods
        function obj = Model()
            obj.clear();
        end

        function clear(obj)
            obj.Atoms = table('Size', [0 13], ...
                'VariableTypes', {'double','string','double','string','double','double','double','double','double','double','double','double','double'}, ...
                'VariableNames', {'ID','Element','Mass','Label','X','Y','Z','Radius','Red','Green','Blue','Spin','Magnetogyric'});
            obj.Interactions = table('Size', [0 12], ...
                'VariableTypes', {'double','string','double','double','string','string','cell','cell','cell','double','string','string'}, ...
                'VariableNames', {'ID','Kind','A','B','Label','Unit','Matrix','Eigenvalues','DCM','ReferenceFrameID','Reference','Source'});
            obj.ReferenceFrames = table('Size', [0 6], ...
                'VariableTypes', {'double','string','cell','double','string','double'}, ...
                'VariableNames', {'ID','Label','Matrix','ParentID','Source','IsLabFrame'});
            obj.SourceFile = "";
            obj.Dirty = false;
        end

        function id = addAtom(obj, isotopeName, xyz, label)
            if nargin < 4
                label = "";
            end
            isotope = spinachgui.findIsotope(isotopeName);
            id = height(obj.Atoms) + 1;
            obj.Atoms(end+1, :) = {id, string(isotope.Element), isotope.Mass, string(label), ...
                xyz(1), xyz(2), xyz(3), isotope.Radius, isotope.Red, isotope.Green, isotope.Blue, ...
                isotope.Spin, isotope.Magnetogyric};
            obj.Dirty = true;
        end

        function id = addInteraction(obj, kind, atomA, atomB, matrix, unitName, label, referenceFrameID, reference, source)
            if nargin < 6 || strlength(string(unitName)) == 0, unitName = "Unknown"; end
            if nargin < 7, label = ""; end
            if nargin < 8 || isempty(referenceFrameID), referenceFrameID = NaN; end
            if nargin < 9, reference = ""; end
            if nargin < 10, source = ""; end
            if isempty(matrix), matrix = zeros(3); end
            [vec, val] = eig((matrix + matrix.')/2);
            id = height(obj.Interactions) + 1;
            obj.Interactions(end+1, :) = {id, string(kind), atomA, atomB, string(label), string(unitName), ...
                {matrix}, {diag(val).'}, {vec}, referenceFrameID, string(reference), string(source)};
            obj.Dirty = true;
        end

        function id = addReferenceFrame(obj, matrix, label, parentID, source, isLabFrame)
            if nargin < 3, label = ""; end
            if nargin < 4 || isempty(parentID), parentID = NaN; end
            if nargin < 5, source = ""; end
            if nargin < 6, isLabFrame = false; end
            if isempty(matrix), matrix = eye(3); end
            id = height(obj.ReferenceFrames) + 1;
            obj.ReferenceFrames(end+1, :) = {id, string(label), {matrix}, parentID, string(source), double(isLabFrame)};
            obj.Dirty = true;
        end

        function pairs = bondPairs(obj, cutoffAngstrom)
            if nargin < 2, cutoffAngstrom = 1.60; end
            pairs = spinachgui.bondPairs(obj.Atoms, cutoffAngstrom);
        end

        function b = bounds(obj)
            if isempty(obj.Atoms)
                b = [0 1; 0 1; 0 1];
                return
            end
            xyz = [obj.Atoms.X, obj.Atoms.Y, obj.Atoms.Z];
            b = [min(xyz, [], 1); max(xyz, [], 1)].';
        end
    end
end
