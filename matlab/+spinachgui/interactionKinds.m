function names = interactionKinds()
%INTERACTIONKINDS Legacy SpinachGUI interaction kind order.
%   The order matches GUI/System Core/Model.h InteractionKind exactly.

names = ["CBond", "HFC", "CShielding", "Shift", "GTensor", ...
    "CHITensor", "ZFS", "Exchange", "Quadrupolar", "Dipolar", ...
    "Jcoupling", "spinrotation"];
end
