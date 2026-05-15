function references = shieldingReferenceTable()
%SHIELDINGREFERENCETABLE Legacy shielding references used for shift conversion.
%   Values are the default reference shieldings from GUI/ShieldingtoShift.cpp.
%   ReferenceShielding is in ppm, matching the legacy CShielding importers.

channels = ["1H"; "2H"; "13C"; "14N"; "15N"; "17O"; "19F"; "29Si"; "31P"; "33S"];
referenceShielding = [33.440; 33.440; 186.38; -132.83; -134.42; 290.66; 192.97; 378.94; 332.07; 205.17];
referenceSubstance = ["TMS"; "TMS"; "TMS"; "CH3NO2"; "CH3NO2"; "D2O"; "CFCl3"; "TMS"; "H3PO4"; "(NH4)2SO4"];

references = table(channels, referenceShielding, referenceSubstance, ...
    'VariableNames', {'Channel', 'ReferenceShielding', 'ReferenceSubstance'});
end
