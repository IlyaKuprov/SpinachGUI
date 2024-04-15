%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% This Matlab file is generated by Spinach GUI 1.0.400 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

function anthraquinone_disulphonate_anion3() 

% Magnet induction 
sys.magnet=18.100;

% Isotopes 
sys.isotopes={'13C', '13C', '13C', '13C', '13C', '13C', '1H', '1H', '1H', '13C', '13C', '17O', '17O', '13C', '13C', '13C', '13C', '13C', '1H', '13C', '1H', '1H', '33S', '33S', '17O', '17O', '17O', '17O', '17O', '17O', 'E'};  


% Coordinates 
inter.coordinates={[-3.763671 0.270694 0];
                   [-2.78222 -0.715317 -1E-06];
                   [-1.399361 -0.375475 -2E-06];
                   [-1.019217 1.009225 -1E-06];
                   [-2.046969 1.990302 0];
                   [-3.392127 1.641171 0];
                   [-3.047888 -1.767181 -2E-06];
                   [-1.737315 3.032201 0];
                   [-4.179221 2.388642 3E-06];
                   [0.387691 1.44569 -3E-06];
                   [-0.387691 -1.445688 -3E-06];
                   [0.702831 2.672597 -5E-06];
                   [-0.702831 -2.672595 -4E-06];
                   [1.399361 0.375476 -2E-06];
                   [1.019217 -1.009224 -2E-06];
                   [2.78222 0.715317 -1E-06];
                   [2.046968 -1.990301 -1E-06];
                   [3.763671 -0.270694 0];
                   [3.047889 1.767182 -2E-06];
                   [3.392126 -1.641171 0];
                   [1.737314 -3.0322 -1E-06];
                   [4.17922 -2.388642 2E-06];
                   [5.551552 0.168357 2E-06];
                   [-5.551552 -0.168358 2E-06];
                   [6.288019 -1.160351 2E-06];
                   [5.785304 0.971516 1.2634];
                   [5.785306 0.971517 -1.263396];
                   [-6.28802 1.160349 7E-06];
                   [-5.785306 -0.971514 -1.263398];
                   [-5.785303 -0.971522 1.263397];
                   [ ]};  



 
% Coupling Matrices
inter.coupling.matrix=cell(31);  
inter.coupling.matrix{1, 31}=1e6*gauss2mhz([-2.890e-001 4.119e-003 0.000e+000; 4.119e-003 -3.860e-001 0.000e+000; 0.000e+000 0.000e+000 2.493e+000]); 
inter.coupling.matrix{2, 31}=1e6*gauss2mhz([-9.460e-001 -1.202e-001 0.000e+000; -1.202e-001 -1.241e+000 0.000e+000; 0.000e+000 0.000e+000 -1.069e+000]); 
inter.coupling.matrix{3, 31}=1e6*gauss2mhz([-2.557e+000 -9.246e-002 0.000e+000; -9.246e-002 -2.563e+000 3.171e-004; 0.000e+000 3.171e-004 2.197e+000]); 
inter.coupling.matrix{4, 31}=1e6*gauss2mhz([-2.330e+000 4.774e-002 5.739e-004; 4.774e-002 -2.494e+000 4.868e-005; 5.739e-004 4.868e-005 3.486e+000]); 
inter.coupling.matrix{5, 31}=1e6*gauss2mhz([-1.139e+000 -7.844e-002 1.491e-005; -7.844e-002 -1.543e+000 -2.737e-005; 1.491e-005 -2.737e-005 -1.319e+000]); 
inter.coupling.matrix{6, 31}=1e6*gauss2mhz([-3.850e-001 -3.865e-002 0.000e+000; -3.865e-002 -4.750e-001 0.000e+000; 0.000e+000 0.000e+000 3.128e+000]); 
inter.coupling.matrix{7, 31}=1e6*gauss2mhz([5.640e-001 -1.483e-001 0.000e+000; -1.483e-001 -2.960e-001 0.000e+000; 0.000e+000 0.000e+000 -8.740e-001]); 
inter.coupling.matrix{8, 31}=1e6*gauss2mhz([5.130e-001 -2.963e-001 0.000e+000; -2.963e-001 -2.310e-001 0.000e+000; 0.000e+000 0.000e+000 -9.170e-001]); 
inter.coupling.matrix{9, 31}=1e6*gauss2mhz([-7.640e-001 -8.070e-001 0.000e+000; -8.070e-001 -1.420e+000 0.000e+000; 0.000e+000 0.000e+000 -1.455e+000]); 
inter.coupling.matrix{10, 31}=1e6*gauss2mhz([-4.772e+000 2.636e-001 0.000e+000; 2.636e-001 -3.849e+000 0.000e+000; 0.000e+000 0.000e+000 6.727e+000]); 
inter.coupling.matrix{11, 31}=1e6*gauss2mhz([-4.772e+000 2.636e-001 0.000e+000; 2.636e-001 -3.849e+000 0.000e+000; 0.000e+000 0.000e+000 6.728e+000]); 
inter.coupling.matrix{12, 31}=1e6*gauss2mhz([5.046e+000 5.414e-002 3.273e-003; 5.414e-002 5.250e+000 -2.642e-004; 3.273e-003 -2.642e-004 -2.803e+001]); 
inter.coupling.matrix{13, 31}=1e6*gauss2mhz([5.046e+000 5.414e-002 -3.273e-003; 5.414e-002 5.250e+000 2.642e-004; -3.273e-003 2.642e-004 -2.803e+001]); 
inter.coupling.matrix{14, 31}=1e6*gauss2mhz([-2.556e+000 -9.246e-002 0.000e+000; -9.246e-002 -2.562e+000 0.000e+000; 0.000e+000 0.000e+000 2.198e+000]); 
inter.coupling.matrix{15, 31}=1e6*gauss2mhz([-2.330e+000 4.773e-002 -1.806e-004; 4.773e-002 -2.494e+000 -4.868e-005; -1.806e-004 -4.868e-005 3.486e+000]); 
inter.coupling.matrix{16, 31}=1e6*gauss2mhz([-9.460e-001 -1.202e-001 -1.395e-005; -1.202e-001 -1.242e+000 6.092e-006; -1.395e-005 6.092e-006 -1.069e+000]); 
inter.coupling.matrix{17, 31}=1e6*gauss2mhz([-1.140e+000 -7.826e-002 -1.482e-005; -7.826e-002 -1.543e+000 2.735e-005; -1.482e-005 2.735e-005 -1.319e+000]); 
inter.coupling.matrix{18, 31}=1e6*gauss2mhz([-2.890e-001 4.128e-003 0.000e+000; 4.128e-003 -3.860e-001 0.000e+000; 0.000e+000 0.000e+000 2.493e+000]); 
inter.coupling.matrix{19, 31}=1e6*gauss2mhz([5.640e-001 -1.483e-001 0.000e+000; -1.483e-001 -2.960e-001 0.000e+000; 0.000e+000 0.000e+000 -8.730e-001]); 
inter.coupling.matrix{20, 31}=1e6*gauss2mhz([-3.860e-001 -3.864e-002 0.000e+000; -3.864e-002 -4.750e-001 0.000e+000; 0.000e+000 0.000e+000 3.128e+000]); 
inter.coupling.matrix{21, 31}=1e6*gauss2mhz([5.130e-001 -2.963e-001 0.000e+000; -2.963e-001 -2.310e-001 0.000e+000; 0.000e+000 0.000e+000 -9.180e-001]); 
inter.coupling.matrix{22, 31}=1e6*gauss2mhz([-7.640e-001 -8.070e-001 0.000e+000; -8.070e-001 -1.420e+000 0.000e+000; 0.000e+000 0.000e+000 -1.455e+000]); 
inter.coupling.matrix{23, 31}=1e6*gauss2mhz([-2.950e-001 -1.527e-002 5.276e-007; -1.527e-002 -2.540e-001 2.660e-008; 5.276e-007 2.660e-008 -2.500e-001]); 
inter.coupling.matrix{24, 31}=1e6*gauss2mhz([-2.950e-001 -1.527e-002 -1.064e-006; -1.527e-002 -2.540e-001 -1.330e-008; -1.064e-006 -1.330e-008 -2.500e-001]); 
inter.coupling.matrix{25, 31}=1e6*gauss2mhz([3.200e-002 -4.438e-004 2.098e-006; -4.438e-004 3.200e-002 -3.635e-007; 2.098e-006 -3.635e-007 5.400e-002]); 
inter.coupling.matrix{26, 31}=1e6*gauss2mhz([-4.850e-001 -1.310e-001 1.925e-003; -1.310e-001 -1.580e-001 6.977e-003; 1.925e-003 6.977e-003 -1.040e-001]); 
inter.coupling.matrix{27, 31}=1e6*gauss2mhz([-4.850e-001 -1.310e-001 -1.932e-003; -1.310e-001 -1.580e-001 -6.977e-003; -1.932e-003 -6.977e-003 -1.040e-001]); 
inter.coupling.matrix{28, 31}=1e6*gauss2mhz([3.200e-002 -4.455e-004 -2.097e-006; -4.455e-004 3.200e-002 3.658e-007; -2.097e-006 3.658e-007 5.400e-002]); 
inter.coupling.matrix{29, 31}=1e6*gauss2mhz([-4.850e-001 -1.309e-001 2.038e-003; -1.309e-001 -1.580e-001 6.560e-003; 2.038e-003 6.560e-003 -1.050e-001]); 
inter.coupling.matrix{30, 31}=1e6*gauss2mhz([-4.850e-001 -1.309e-001 -2.059e-003; -1.309e-001 -1.580e-001 -6.574e-003; -2.059e-003 -6.574e-003 -1.050e-001]); 
 
% Scalar Couplings
inter.coupling.scalar=cell(31);  
 
% Zeeman Interactions 
inter.zeeman.matrix=cell(1, 31);  
inter.zeeman.matrix{1}=[2.097e+002 1.814e+001 -1.000e-004; 1.814e+001 1.852e+002 5.500e-004; -1.000e-004 5.500e-004 6.403e+001]; 
inter.zeeman.matrix{2}=[1.664e+002 2.408e+001 9.500e-004; 2.408e+001 2.004e+002 -5.000e-004; 9.500e-004 -5.000e-004 4.371e+000]; 
inter.zeeman.matrix{3}=[1.775e+002 -4.026e+000 5.500e-004; -4.026e+000 1.947e+002 3.500e-004; 5.500e-004 3.500e-004 2.154e+001]; 
inter.zeeman.matrix{4}=[1.888e+002 1.125e+001 -4.500e-004; 1.125e+001 1.876e+002 1.250e-003; -4.500e-004 1.250e-003 1.877e+001]; 
inter.zeeman.matrix{5}=[1.521e+002 1.088e+001 -2.250e-003; 1.088e+001 2.232e+002 -2.000e-004; -2.250e-003 -2.000e-004 4.837e+000]; 
inter.zeeman.matrix{6}=[1.695e+002 -3.402e+001 3.500e-004; -3.402e+001 1.853e+002 -5.000e-005; 3.500e-004 -5.000e-005 1.715e+001]; 
inter.zeeman.matrix{7}=[4.109e+000 2.887e+000 -1.000e-004; 2.887e+000 1.171e+001 0.000e+000; -1.000e-004 0.000e+000 1.621e+001]; 
inter.zeeman.matrix{8}=[4.580e+000 4.786e-001 2.000e-004; 4.786e-001 1.087e+001 -5.000e-005; 2.000e-004 -5.000e-005 1.558e+001]; 
inter.zeeman.matrix{9}=[6.271e+000 -3.856e+000 -1.000e-004; -3.856e+000 8.707e+000 -5.000e-005; -1.000e-004 -5.000e-005 1.441e+001]; 
inter.zeeman.matrix{10}=[2.284e+002 -5.779e+000 2.550e-003; -5.779e+000 2.045e+002 5.000e-005; 2.550e-003 5.000e-005 7.442e+001]; 
inter.zeeman.matrix{11}=[2.284e+002 -5.777e+000 -1.800e-003; -5.777e+000 2.045e+002 -9.000e-004; -1.800e-003 -9.000e-004 7.442e+001]; 
inter.zeeman.matrix{12}=[4.433e+002 7.484e+001 2.725e-002; 7.484e+001 7.186e+002 2.900e-003; 2.725e-002 2.900e-003 -1.098e+002]; 
inter.zeeman.matrix{13}=[4.433e+002 7.483e+001 -2.570e-002; 7.483e+001 7.186e+002 -6.800e-003; -2.570e-002 -6.800e-003 -1.098e+002]; 
inter.zeeman.matrix{14}=[1.775e+002 -4.026e+000 -3.500e-004; -4.026e+000 1.947e+002 -5.000e-005; -3.500e-004 -5.000e-005 2.154e+001]; 
inter.zeeman.matrix{15}=[1.888e+002 1.125e+001 8.500e-004; 1.125e+001 1.876e+002 -1.550e-003; 8.500e-004 -1.550e-003 1.877e+001]; 
inter.zeeman.matrix{16}=[1.664e+002 2.408e+001 -1.300e-003; 2.408e+001 2.004e+002 -4.000e-004; -1.300e-003 -4.000e-004 4.371e+000]; 
inter.zeeman.matrix{17}=[1.521e+002 1.088e+001 1.950e-003; 1.088e+001 2.232e+002 5.000e-004; 1.950e-003 5.000e-004 4.836e+000]; 
inter.zeeman.matrix{18}=[2.097e+002 1.814e+001 1.000e-004; 1.814e+001 1.852e+002 -1.200e-003; 1.000e-004 -1.200e-003 6.403e+001]; 
inter.zeeman.matrix{19}=[4.109e+000 2.887e+000 1.000e-004; 2.887e+000 1.171e+001 0.000e+000; 1.000e-004 0.000e+000 1.621e+001]; 
inter.zeeman.matrix{20}=[1.695e+002 -3.402e+001 -6.000e-004; -3.402e+001 1.853e+002 -1.000e-004; -6.000e-004 -1.000e-004 1.715e+001]; 
inter.zeeman.matrix{21}=[4.580e+000 4.786e-001 -2.000e-004; 4.786e-001 1.087e+001 5.000e-005; -2.000e-004 5.000e-005 1.558e+001]; 
inter.zeeman.matrix{22}=[6.271e+000 -3.856e+000 1.000e-004; -3.856e+000 8.707e+000 5.000e-005; 1.000e-004 5.000e-005 1.441e+001]; 
inter.zeeman.matrix{23}=[1.108e+002 5.235e+001 -7.000e-004; 5.235e+001 -6.731e+001 -4.150e-003; -7.000e-004 -4.150e-003 -6.416e+001]; 
inter.zeeman.matrix{24}=[1.108e+002 5.235e+001 1.000e-003; 5.235e+001 -6.731e+001 4.250e-003; 1.000e-003 4.250e-003 -6.416e+001]; 
inter.zeeman.matrix{25}=[2.283e+002 5.208e+001 -1.500e-003; 5.208e+001 1.461e+002 9.950e-003; -1.500e-003 9.950e-003 1.991e+002]; 
inter.zeeman.matrix{26}=[2.504e+002 -1.242e+001 -1.514e+001; -1.242e+001 2.200e+002 -4.323e+001; -1.514e+001 -4.323e+001 1.625e+002]; 
inter.zeeman.matrix{27}=[2.504e+002 -1.241e+001 1.515e+001; -1.241e+001 2.200e+002 4.323e+001; 1.515e+001 4.323e+001 1.625e+002]; 
inter.zeeman.matrix{28}=[2.283e+002 5.208e+001 1.700e-003; 5.208e+001 1.461e+002 -9.500e-003; 1.700e-003 -9.500e-003 1.991e+002]; 
inter.zeeman.matrix{29}=[2.504e+002 -1.241e+001 -1.515e+001; -1.241e+001 2.200e+002 -4.323e+001; -1.515e+001 -4.323e+001 1.625e+002]; 
inter.zeeman.matrix{30}=[2.504e+002 -1.242e+001 1.514e+001; -1.242e+001 2.200e+002 4.323e+001; 1.514e+001 4.323e+001 1.625e+002]; 
inter.zeeman.matrix{31}=[2.0052982 0.0003442 0.0000000; 0.0003442 2.0063455 0.0000000; 0.0000000 0.0000000 2.0020941]; 

% Relaxation 
inter.relaxation='none';

inter.temperature=0.000;
inter.order_matrix=[0.300 0.000 0.000 ;0.000 0.000 0.000 ;0.000 0.000 0.000];

% Chemical kinetics

% Basis set
bas.formalism='sphten-liouv';
bas.approximation='none';
bas.connectivity='scalar_couplings';
bas.longitudinals={ ' 13C', ' 1H', ' 17O', ' 33S', ' E'};

% Spinach housekeeping 
spin_system=create(sys,inter); 
spin_system=basis(spin_system,bas); 
