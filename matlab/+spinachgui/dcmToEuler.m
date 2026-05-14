function euler = dcmToEuler(matrix)
%DCMTOEULER Direction-cosine matrix to legacy SpinachGUI Z-Y-Z Euler angles.
%   Returns [alpha beta gamma] for Rz(alpha)*Ry(beta)*Rz(gamma).

validateattributes(matrix, {'numeric'}, {'size', [3 3], 'finite', 'real'}, mfilename, 'matrix');
value = max(-1, min(1, matrix(3,3)));
beta = atan2(hypot(matrix(3,1), matrix(3,2)), value);

if abs(sin(beta)) > 10*eps(class(beta))
    alpha = atan2(matrix(2,3), matrix(1,3));
    gamma = atan2(matrix(3,2), -matrix(3,1));
else
    % Gimbal-lock branch.  Preserve the represented rotation with gamma=0.
    alpha = atan2(matrix(2,1), matrix(1,1));
    gamma = 0;
end

euler = [alpha, beta, gamma];
end
