classdef Model < handle
    %MODEL Spin system model used by the MATLAB SpinachGUI rewrite.
    %   This is the MATLAB counterpart of GUI/System Core/Model.h. It keeps
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
            obj.ReferenceFrames = table('Size', [1 6], ...
                'VariableTypes', {'double','string','cell','double','string','double'}, ...
                'VariableNames', {'ID','Label','Matrix','ParentID','Source','IsLabFrame'});
            obj.ReferenceFrames(1, :) = {1, "Lab Frame", {eye(3)}, NaN, "Legacy default", 1};
            obj.SourceFile = "";
            obj.Dirty = false;
        end

        function id = addAtom(obj, isotopeName, xyz, label, makeAutoBonds)
            if nargin < 4
                label = "";
            end
            if nargin < 5
                makeAutoBonds = false;
            end
            isotope = spinachgui.findIsotope(isotopeName);
            id = nextPositiveID(obj.Atoms.ID);
            obj.Atoms(end+1, :) = {id, string(isotope.Element), isotope.Mass, string(label), ...
                xyz(1), xyz(2), xyz(3), isotope.Radius, isotope.Red, isotope.Green, isotope.Blue, ...
                isotope.Spin, isotope.Magnetogyric};
            if makeAutoBonds
                obj.addBondsForAtom(id);
            end
            obj.Dirty = true;
        end

        function id = addInteraction(obj, kind, atomA, atomB, matrix, unitName, label, referenceFrameID, reference, source)
            kind = spinachgui.normalizeInteractionKind(kind);
            if nargin < 6 || strlength(string(unitName)) == 0, unitName = "Unknown"; end
            if nargin < 7, label = ""; end
            if nargin < 8 || isempty(referenceFrameID) || isnan(referenceFrameID), referenceFrameID = 1; end
            if nargin < 9, reference = ""; end
            if nargin < 10, source = ""; end
            matrix = spinachgui.symmetrizeTensor(matrix);
            [vec, val] = eig(matrix);
            if kind == "CBond"
                id = nextNegativeID(obj.Interactions.ID);
            else
                id = nextPositiveID(obj.Interactions.ID(obj.Interactions.ID > 0));
            end
            dcm = obj.referenceFrameToRootMatrix(referenceFrameID) * vec;
            obj.Interactions(end+1, :) = {id, kind, atomA, atomB, string(label), string(unitName), ...
                {matrix}, {diag(val).'}, {dcm}, referenceFrameID, string(reference), string(source)};
            obj.Dirty = true;
        end

        function id = addReferenceFrame(obj, matrix, label, parentID, source, isLabFrame, requestedID)
            if nargin < 3, label = ""; end
            if nargin < 4 || isempty(parentID), parentID = NaN; end
            if nargin < 5, source = ""; end
            if nargin < 6, isLabFrame = false; end
            if nargin < 7 || isempty(requestedID) || isnan(requestedID)
                id = nextPositiveID(obj.ReferenceFrames.ID);
            else
                id = requestedID;
            end
            if isempty(matrix), matrix = eye(3); end
            if ismember(id, obj.ReferenceFrames.ID)
                obj.ReferenceFrames(obj.ReferenceFrames.ID == id, :) = {id, string(label), {matrix}, parentID, string(source), double(isLabFrame)};
            else
                obj.ReferenceFrames(end+1, :) = {id, string(label), {matrix}, parentID, string(source), double(isLabFrame)};
                obj.ReferenceFrames = sortrows(obj.ReferenceFrames, 'ID');
            end
            obj.Dirty = true;
        end

        function rebuildAutoBonds(obj)
            obj.Interactions = obj.Interactions(obj.Interactions.Kind ~= "CBond", :);
            for a = 1:height(obj.Atoms)
                for b = 1:a-1
                    if obj.Atoms.Element(a) ~= "e" && obj.Atoms.Element(b) ~= "e"
                        obj.addBondInteraction(obj.Atoms.ID(a), obj.Atoms.ID(b));
                    end
                end
            end
        end

        function rows = positiveInteractions(obj)
            rows = obj.Interactions(obj.Interactions.ID > 0, :);
        end

        function stats = interactionStats(obj)
            kinds = spinachgui.interactionKinds();
            count = zeros(numel(kinds), 1);
            maxAbsEigenvalue = zeros(numel(kinds), 1);
            minAbsEigenvalue = inf(numel(kinds), 1);
            for k = 1:numel(kinds)
                rows = obj.Interactions(obj.Interactions.Kind == kinds(k), :);
                count(k) = height(rows);
                values = [];
                for r = 1:height(rows)
                    values = [values, abs(rows.Eigenvalues{r})]; %#ok<AGROW>
                end
                if ~isempty(values)
                    maxAbsEigenvalue(k) = max(values);
                    minAbsEigenvalue(k) = min(values);
                end
            end
            minAbsEigenvalue(isinf(minAbsEigenvalue)) = 0;
            stats = table(kinds(:), count, minAbsEigenvalue, maxAbsEigenvalue, ...
                'VariableNames', {'Kind', 'Count', 'MinAbsEigenvalue', 'MaxAbsEigenvalue'});
        end

        function summary = convertShieldingToShift(obj, referenceOverrides, interactionIDs)
            if nargin < 2
                summary = spinachgui.convertShieldingToShift(obj);
            elseif nargin < 3
                summary = spinachgui.convertShieldingToShift(obj, referenceOverrides);
            else
                summary = spinachgui.convertShieldingToShift(obj, referenceOverrides, interactionIDs);
            end
        end

        function setInteractionMatrix(obj, interactionID, matrix)
            idx = obj.interactionRow(interactionID);
            [matrix, eigenvalues, dcm] = obj.interactionDerivedState(matrix, obj.Interactions.ReferenceFrameID(idx));
            obj.Interactions.Matrix{idx} = matrix;
            obj.Interactions.Eigenvalues{idx} = eigenvalues;
            obj.Interactions.DCM{idx} = dcm;
            obj.Dirty = true;
        end

        function setInteractionEigenSystem(obj, interactionID, eigenvalues, rootDcm)
            idx = obj.interactionRow(interactionID);
            validateattributes(eigenvalues, {'numeric'}, {'vector', 'numel', 3, 'finite', 'real'}, ...
                mfilename, 'eigenvalues');
            rootDcm = spinachgui.normalizeDcm(rootDcm);
            frameToRoot = obj.referenceFrameToRootMatrix(obj.Interactions.ReferenceFrameID(idx));
            localDcm = frameToRoot \ rootDcm;
            obj.Interactions.Matrix{idx} = spinachgui.symmetrizeTensor(localDcm * diag(double(eigenvalues(:))) * localDcm.');
            obj.Interactions.Eigenvalues{idx} = double(eigenvalues(:).');
            obj.Interactions.DCM{idx} = rootDcm;
            obj.Dirty = true;
        end

        function setReferenceFrameMatrix(obj, frameID, matrix)
            validateattributes(matrix, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'matrix');
            idx = find(obj.ReferenceFrames.ID == frameID, 1);
            if isempty(idx)
                error('spinachgui:MissingReferenceFrame', 'Reference frame %g is not present.', frameID);
            end
            obj.ReferenceFrames.Matrix{idx} = spinachgui.normalizeDcm(matrix);
            obj.refreshInteractionDerivedStates(obj.Interactions.ReferenceFrameID == frameID);
            obj.Dirty = true;
        end

        function removeInteractionAnisotropy(obj, interactionID)
            idx = obj.interactionRow(interactionID);
            isotropicPart = trace(obj.Interactions.Matrix{idx}) / 3;
            obj.setInteractionMatrix(interactionID, isotropicPart * eye(3));
        end

        function alignLabFrameToInteraction(obj, interactionID)
            idx = obj.interactionRow(interactionID);
            [vectors, ~] = eig(spinachgui.symmetrizeTensor(obj.Interactions.Matrix{idx}));
            rotation = spinachgui.normalizeDcm(vectors);
            inverseRotation = rotation.';

            coordinates = [obj.Atoms.X, obj.Atoms.Y, obj.Atoms.Z] * inverseRotation.';
            obj.Atoms.X = coordinates(:, 1);
            obj.Atoms.Y = coordinates(:, 2);
            obj.Atoms.Z = coordinates(:, 3);

            for row = 1:height(obj.Interactions)
                if obj.Interactions.Kind(row) == "CBond"
                    continue
                end
                matrix = obj.Interactions.Matrix{row};
                obj.Interactions.Matrix{row} = inverseRotation * matrix * rotation;
            end
            obj.refreshInteractionDerivedStates(obj.Interactions.Kind ~= "CBond");
            obj.Dirty = true;
        end

        function [filteredModel, summary] = filterInteractions(obj, thresholds, removeOrphanAtoms)
            if nargin < 2
                thresholds = struct();
            end
            if nargin < 3
                removeOrphanAtoms = false;
            end
            [filteredModel, summary] = spinachgui.filterInteractions(obj, thresholds, removeOrphanAtoms);
        end

        function pairs = bondPairs(obj, cutoffAngstrom)
            if nargin < 2, cutoffAngstrom = 1.60; end
            pairs = spinachgui.bondPairs(obj.Atoms, cutoffAngstrom);
        end

        function b = bounds(obj)
            atoms = obj.Atoms(obj.Atoms.Element ~= "e", :);
            if isempty(atoms)
                b = [0 1; 0 1; 0 1];
                return
            end
            xyz = [atoms.X, atoms.Y, atoms.Z];
            b = [min(xyz, [], 1); max(xyz, [], 1)].';
        end

        function matrix = referenceFrameToRootMatrix(obj, frameID)
            matrix = eye(3);
            if isempty(frameID) || isnan(frameID)
                return
            end
            visited = [];
            while ~isempty(frameID) && ~isnan(frameID) && ~ismember(frameID, visited)
                idx = find(obj.ReferenceFrames.ID == frameID, 1);
                if isempty(idx)
                    return
                end
                visited(end+1) = frameID; %#ok<AGROW>
                matrix = obj.ReferenceFrames.Matrix{idx} * matrix;
                frameID = obj.ReferenceFrames.ParentID(idx);
            end
        end
    end

    methods (Access = private)
        function idx = interactionRow(obj, interactionID)
            idx = find(obj.Interactions.ID == interactionID, 1);
            if isempty(idx)
                error('spinachgui:MissingInteraction', 'Interaction %g is not present.', interactionID);
            end
        end

        function refreshInteractionDerivedStates(obj, rows)
            if islogical(rows)
                rows = find(rows);
            end
            for row = rows(:).'
                [matrix, eigenvalues, dcm] = obj.interactionDerivedState(obj.Interactions.Matrix{row}, ...
                    obj.Interactions.ReferenceFrameID(row));
                obj.Interactions.Matrix{row} = matrix;
                obj.Interactions.Eigenvalues{row} = eigenvalues;
                obj.Interactions.DCM{row} = dcm;
            end
        end

        function [matrix, eigenvalues, dcm] = interactionDerivedState(obj, matrix, referenceFrameID)
            matrix = spinachgui.symmetrizeTensor(matrix);
            [vectors, values] = eig(matrix);
            eigenvalues = diag(values).';
            dcm = obj.referenceFrameToRootMatrix(referenceFrameID) * vectors;
            dcm = spinachgui.normalizeDcm(dcm);
        end

        function addBondsForAtom(obj, atomID)
            atomIndex = find(obj.Atoms.ID == atomID, 1);
            if isempty(atomIndex) || obj.Atoms.Element(atomIndex) == "e"
                return
            end
            for row = 1:height(obj.Atoms)
                otherID = obj.Atoms.ID(row);
                if otherID == atomID || obj.Atoms.Element(row) == "e"
                    continue
                end
                if ~isempty(obj.Interactions) && any(obj.Interactions.Kind == "CBond" & ...
                        ((obj.Interactions.A == atomID & obj.Interactions.B == otherID) | ...
                        (obj.Interactions.A == otherID & obj.Interactions.B == atomID)))
                    continue
                end
                obj.addBondInteraction(atomID, otherID);
            end
        end

        function addBondInteraction(obj, atomA, atomB)
            idxA = find(obj.Atoms.ID == atomA, 1);
            idxB = find(obj.Atoms.ID == atomB, 1);
            distance = norm([obj.Atoms.X(idxA) - obj.Atoms.X(idxB), ...
                obj.Atoms.Y(idxA) - obj.Atoms.Y(idxB), obj.Atoms.Z(idxA) - obj.Atoms.Z(idxB)]);
            obj.addInteraction("CBond", atomA, atomB, distance * eye(3), "Angstroms", "", 1, "", "Auto bond");
        end
    end
end

function id = nextPositiveID(ids)
ids = ids(ids > 0);
if isempty(ids)
    id = 1;
else
    id = max(ids) + 1;
end
end

function id = nextNegativeID(ids)
ids = ids(ids < 0);
if isempty(ids)
    id = -1;
else
    id = min(ids) - 1;
end
end
