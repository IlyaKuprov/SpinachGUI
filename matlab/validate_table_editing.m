function validate_table_editing()
%VALIDATE_TABLE_EDITING Validate editable SpinachGUI app tables.

validateModelTableMutators();
validateAppTableWiring();
fprintf('TABLE_EDITING_VALIDATION_OK\n');
end

function validateModelTableMutators()
model = tableFixture();
model.setAtomID(1, 10);
assert(all(model.Interactions.A(model.Interactions.A == 10) == 10), ...
    'Atom ID edits should update interaction A references.');
assert(any(model.Interactions.B == 10), 'Atom ID edits should update interaction B references.');
model.setAtomLabel(10, "edited proton");
assert(model.Atoms.Label(model.Atoms.ID == 10) == "edited proton", 'Atom label edit was not stored.');
model.setAtomIsotope(2, "N", []);
assert(model.Atoms.Element(model.Atoms.ID == 2) == "N", 'Atom element edit was not stored.');
model.setAtomIsotope(2, "N", 15);
assert(model.Atoms.Mass(model.Atoms.ID == 2) == 15, 'Atom mass edit was not stored.');
model.setAtomCoordinates(2, [1 2 3]);
assert(isequal([model.Atoms.X(model.Atoms.ID == 2), model.Atoms.Y(model.Atoms.ID == 2), ...
    model.Atoms.Z(model.Atoms.ID == 2)], [1 2 3]), 'Atom coordinate edit was not stored.');
model.setInteractionLabel(1, "edited shift");
assert(model.Interactions.Label(model.Interactions.ID == 1) == "edited shift", ...
    'Interaction label edit was not stored.');
model.setInteractionReferenceFrame(1, 2);
assert(model.Interactions.ReferenceFrameID(model.Interactions.ID == 1) == 2, ...
    'Reference-frame edit was not stored.');
model.setInteractionReference(1, "edited reference");
assert(model.Interactions.Reference(model.Interactions.ID == 1) == "edited reference", ...
    'Interaction reference edit was not stored.');
model.setInteractionUnit(1, "Hz");
assert(model.Interactions.Unit(model.Interactions.ID == 1) == "Hz", 'Interaction unit edit was not stored.');
model.setInteractionKind(1, "Jcoupling");
assert(model.Interactions.Kind(model.Interactions.ID == 1) == "Jcoupling", ...
    'Interaction kind edit was not stored.');
assert(model.Interactions.B(model.Interactions.ID == 1) == 2, ...
    'Interaction kind edit should choose a valid coupled atom.');
model.setInteractionAtomA(1, 2);
assert(model.Interactions.A(model.Interactions.ID == 1) == 2, 'Interaction A atom edit was not stored.');
model.setInteractionAtomB(1, 10);
assert(model.Interactions.B(model.Interactions.ID == 1) == 10, 'Interaction B atom edit was not stored.');
model.setInteractionID(1, 99);
assert(any(model.Interactions.ID == 99), 'Interaction ID edit was not stored.');
end

function validateAppTableWiring()
app = spinachgui.App();
cleanup = onCleanup(@() deleteAllSpinachGuiFigures(app));
app.Model = tableFixture();
app.VisibilityControls.AtomIDs.ValueChangedFcn(app.VisibilityControls.AtomIDs, []);

removedColumns = {'Radius','Red','Green','Blue','Magnetogyric'};
assert(~any(ismember(removedColumns, app.AtomsTable.ColumnName)), ...
    'Hidden atom metadata leaked into the atoms table.');
assert(isequal(app.AtomsTable.ColumnEditable, true(1, 7)), 'Atoms table should be editable.');
assert(isequal(app.AtomsTable.Parent.Parent.ColumnWidth, {190, '2x', '1x'}), ...
    'Atoms table column should be dynamically sized with the 3D view.');
assert(isa(app.TabGroup.Parent, 'matlab.ui.container.GridLayout'), ...
    'Tab group should be layout-managed so it resizes with the main window.');

expectedInteractionColumns = ["ID","Label","Atom ID","Inter. Type","Coupled Atom ID", ...
    "Unit","Ref. Frame ID","Reference","Magnitude Orientation"];
assert(isequal(string(app.InteractionsTable.ColumnName(:)).', expectedInteractionColumns), ...
    'Interactions table columns do not match the editable legacy layout.');
assert(isequal(app.InteractionsTable.ColumnEditable, [true true true true true true true true false]), ...
    'Interactions table values should be editable while the Edit action remains a click target.');
assert(all(string(app.InteractionsTable.Data(:, end)) == "Edit"), 'Interactions table should expose Edit actions.');

atomData = app.AtomsTable.Data;
atomData{1, 2} = 'callback label';
app.AtomsTable.Data = atomData;
app.AtomsTable.CellEditCallback(app.AtomsTable, ...
    struct('Indices', [1 2], 'PreviousData', "H1", 'NewData', "callback label"));
assert(app.Model.Atoms.Label(app.Model.Atoms.ID == 1) == "callback label", ...
    'Atoms table edit callback did not update the model.');

atomData = app.AtomsTable.Data;
atomData{1, 1} = 10;
app.AtomsTable.Data = atomData;
app.AtomsTable.CellEditCallback(app.AtomsTable, ...
    struct('Indices', [1 1], 'PreviousData', 1, 'NewData', 10));
assert(any(app.Model.Interactions.A == 10), 'Atom ID callback did not update interaction references.');

interactionData = app.InteractionsTable.Data;
row = find(cell2mat(interactionData(:, 1)) == 1, 1);
interactionData{row, 2} = 'callback interaction';
app.InteractionsTable.Data = interactionData;
app.InteractionsTable.CellEditCallback(app.InteractionsTable, ...
    struct('Indices', [row 2], 'PreviousData', "shift", 'NewData', "callback interaction"));
assert(app.Model.Interactions.Label(app.Model.Interactions.ID == 1) == "callback interaction", ...
    'Interactions table edit callback did not update the model.');

interactionData = app.InteractionsTable.Data;
row = find(cell2mat(interactionData(:, 1)) == 1, 1);
interactionData{row, 4} = 'Jcoupling';
app.InteractionsTable.Data = interactionData;
app.InteractionsTable.CellEditCallback(app.InteractionsTable, ...
    struct('Indices', [row 4], 'PreviousData', "Shift", 'NewData', "Jcoupling"));
assert(app.Model.Interactions.Kind(app.Model.Interactions.ID == 1) == "Jcoupling", ...
    'Interaction kind callback did not update the model.');

interactionData = app.InteractionsTable.Data;
row = find(cell2mat(interactionData(:, 1)) == 1, 1);
editorTitle = sprintf('Interaction %d tensor/orientation editor', interactionData{row, 1});
app.InteractionsTable.CellSelectionCallback(app.InteractionsTable, ...
    struct('Indices', [row size(interactionData, 2)]));
assert(~isempty(findall(groot, 'Name', editorTitle)), ...
    'Edit action should open the interaction tensor/orientation editor.');
end

function model = tableFixture()
model = spinachgui.Model();
model.addAtom("1H", [0 0 0], "H1", false);
model.addAtom("13C", [1 0 0], "C1", false);
model.addAtom("e", [0 1 0], "E1", false);
model.addReferenceFrame(eye(3), "Frame 2", 1, "validation", false, 2);
model.addInteraction("Shift", 1, 1, diag([1 2 3]), "ppm", "shift", 1, "ref", "validation");
model.addInteraction("HFC", 1, 3, diag([4 5 6]), "Gauss", "hfc", 2, "href", "validation");
model.Dirty = false;
end

function deleteAllSpinachGuiFigures(app)
if exist('app', 'var') && ~isempty(app) && ~isempty(app.Figure) && isvalid(app.Figure)
    delete(app.Figure);
end
figures = findall(groot, 'Type', 'figure');
for idx = 1:numel(figures)
    if isvalid(figures(idx)) && startsWith(string(figures(idx).Name), "Interaction ")
        delete(figures(idx));
    end
end
end
