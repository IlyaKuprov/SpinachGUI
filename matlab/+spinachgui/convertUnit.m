function valueOut = convertUnit(valueIn, fromUnit, toUnit)
%CONVERTUNIT Convert through the legacy SpinachGUI unit base.

fromFactor = spinachgui.unitFactor(fromUnit);
toFactor = spinachgui.unitFactor(toUnit);
valueOut = valueIn .* fromFactor ./ toFactor;
end
