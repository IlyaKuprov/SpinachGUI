function rotation = normalizeDcm(matrix)
%NORMALIZEDCM Return the nearest proper direction-cosine matrix.
%   ROTATION = spinachgui.normalizeDcm(MATRIX) validates a finite real 3x3
%   matrix and projects it onto the nearest proper orthonormal rotation using
%   the Kabsch/SVD construction. This mirrors the historical GUI's habit of
%   treating edited orientation matrices as rotations while forcing a positive
%   handedness.

validateattributes(matrix, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'matrix');
[u, ~, v] = svd(double(matrix));
rotation = u * diag([1 1 sign(det(u * v.'))]) * v.';
if det(rotation) < 0
    rotation(:, 3) = -rotation(:, 3);
end
end
