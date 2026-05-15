function value = parseNumber(text)
%PARSENUMBER Parse decimal/scientific numbers including Fortran D exponents.

if isnumeric(text)
    value = double(text);
    return
end
normalised = replace(string(text), ["D", "d"], "E");
value = str2double(normalised);
end
