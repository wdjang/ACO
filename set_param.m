function param_list = set_param

% Parameter for border elimination
param_list.slic.area = 1000;
param_list.slic.edge = 20;

param_list.init.alpha_b = 0.98;
param_list.init.alpha_f = 0.83;
param_list.init.sigsqr = 0.01;

param_list.anta.sigsqr = 0.01;

param_list.fg.sigsqr = 0.01;
param_list.bg.sigsqr = 0.01;

% Feature distance weight [Mean L*a*b, Mean optical flow]
param_list.dist_w = [0.2 0.8];

% Spatiotemporal energy weight
param_list.w_sptemp = 0.15;
% Antagonistic energy weight
param_list.w_anta = 0.5;

end