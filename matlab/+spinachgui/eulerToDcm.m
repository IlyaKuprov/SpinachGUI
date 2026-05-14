function matrix = eulerToDcm(alpha, beta, gamma)
%EULERTODCM Legacy SpinachGUI Z-Y-Z Euler angles to direction-cosine matrix.
%   Matches orientation.cpp: q = Rz(alpha) * Ry(beta) * Rz(gamma).

ca = cos(alpha); sa = sin(alpha);
cb = cos(beta);  sb = sin(beta);
cg = cos(gamma); sg = sin(gamma);

rzAlpha = [ca, -sa, 0; sa, ca, 0; 0, 0, 1];
ryBeta = [cb, 0, sb; 0, 1, 0; -sb, 0, cb];
rzGamma = [cg, -sg, 0; sg, cg, 0; 0, 0, 1];

matrix = rzAlpha * ryBeta * rzGamma;
end
