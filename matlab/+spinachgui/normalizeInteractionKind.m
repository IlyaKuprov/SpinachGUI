function kind = normalizeInteractionKind(kind)
%NORMALIZEINTERACTIONKIND Convert legacy/SpinXML kind spelling to enum spelling.

kind = string(kind);
if strlength(kind) == 0
    kind = "Unknown";
    return
end

keys = lower(spinachgui.interactionKinds());
values = spinachgui.interactionKinds();
idx = find(keys == lower(kind), 1);
if ~isempty(idx)
    kind = values(idx);
    return
end

switch lower(kind)
    case {"chemicalbonding", "bond", "chemical_bond", "chemical-bond"}
        kind = "CBond";
    case {"chemicalshielding", "chemical_shielding", "cshield"}
        kind = "CShielding";
    case {"chemicalshift", "chemical_shift"}
        kind = "Shift";
    case {"g-tensor", "g_tensor", "g tensor"}
        kind = "GTensor";
    case {"chi-tensor", "chi_tensor", "chi tensor"}
        kind = "CHITensor";
    case {"zero-field", "zero_field", "zero field", "zerofieldsplitting"}
        kind = "ZFS";
    case {"j-coupling", "j_coupling", "j coupling"}
        kind = "Jcoupling";
    case {"spin-rotation", "spin_rotation", "spin rotation"}
        kind = "spinrotation";
    otherwise
        kind = string(kind);
end
end
