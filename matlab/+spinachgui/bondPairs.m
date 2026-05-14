function pairs = bondPairs(atoms, cutoffAngstrom)
%BONDPAIRS Return atom index pairs closer than cutoffAngstrom.

if isempty(atoms)
    pairs = zeros(0, 3);
    return
end
xyz = [atoms.X, atoms.Y, atoms.Z];
n = size(xyz, 1);
rows = zeros(0, 3);
for a = 1:n-1
    delta = xyz(a+1:n, :) - xyz(a, :);
    dist = sqrt(sum(delta.^2, 2));
    keep = find(dist <= cutoffAngstrom);
    rows = [rows; [repmat(a, numel(keep), 1), a + keep, dist(keep)]]; %#ok<AGROW>
end
pairs = rows;
end
