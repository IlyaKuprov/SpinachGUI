function matrix = symmetrizeTensor(matrix)
%SYMMETRIZETENSOR Legacy tensor construction symmetrisation.
%   Tensor::Tensor keeps diagonal elements and averages off-diagonal pairs.

if isempty(matrix)
    matrix = zeros(3);
end
validateattributes(matrix, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'matrix');
matrix = (matrix + matrix.') / 2;
end
