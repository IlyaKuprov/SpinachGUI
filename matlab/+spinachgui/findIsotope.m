function isotope = findIsotope(isotopeName, allowUnknownMass)
%FINDISOTOPE Match an isotope label using the original SpinachGUI rules.
%   Labels may be plain element symbols (C) or mass-prefixed symbols (13C).
%   If no mass is supplied, the first isotope for that element in the
%   historical table is returned, matching Isotopes::FindIsotope.
%   Unknown mass-labelled isotopes are rejected unless allowUnknownMass is
%   true; that fallback is reserved for structural SpinXML display atoms.

if nargin < 2
    allowUnknownMass = false;
end

t = spinachgui.isotopeTable();
name = string(strtrim(char(isotopeName)));
if name == "E"
    name = "e";
end
if name == ""
    error('spinachgui:UnknownIsotope', 'Empty isotope label.');
end
m = regexp(char(name), '^(\d+)([A-Za-z][A-Za-z]?|chi|e)$', 'tokens', 'once');
if isempty(m)
    element = name;
    mass = 0;
else
    mass = spinachgui.parseNumber(m{1});
    element = string(m{2});
end
idx = find(t.Element == element);
if isempty(idx) && strcmpi(element, "E")
    idx = find(t.Element == "e");
end
if isempty(idx)
    error('spinachgui:UnknownIsotope', 'Unknown isotope "%s".', isotopeName);
end
if mass ~= 0
    massIdx = idx(t.Mass(idx) == mass);
    if isempty(massIdx)
        if ~allowUnknownMass
            error('spinachgui:UnknownIsotopeMass', 'Unknown isotope mass "%s".', isotopeName);
        end
        isotope = t(idx(1), :);
        isotope.Mass = mass;
        isotope.Spin = 0;
        isotope.QuadrupoleMoment = 0;
        isotope.Magnetogyric = 0;
        return
    end
    idx = massIdx(1);
else
    idx = idx(1);
end
isotope = t(idx, :);
end
