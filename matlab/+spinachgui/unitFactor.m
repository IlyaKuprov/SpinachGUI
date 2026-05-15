function factor = unitFactor(unitName)
%UNITFACTOR Return the legacy SpinachGUI factor to the local SI/base unit.

unitName = string(unitName);
allUnits = spinachgui.units();
idx = find(strcmpi(allUnits.Name, unitName), 1);
if isempty(idx)
    error('spinachgui:UnknownUnit', 'Unknown SpinachGUI unit: %s', unitName);
end
factor = allUnits.FactorToSI(idx);
end
