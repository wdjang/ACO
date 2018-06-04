function [init_aff, anta_aff, fg_trans, bg_trans] = construct_affinity_matrix(in_img, sp_map, bx_flow, by_flow, ...
    conn_edge_mat, long_edge_mat, param)

    sp_num = max(sp_map(:));    % The number of superpixels
    [h_size, w_size] = size(sp_map);
    p_num = h_size*w_size;  % The number of pixels

    % Per-pixel flow to per-superpixel flow
    flow_sp = zeros(sp_num, 2);
    for sp_id = 1:sp_num
        flow_sp(sp_id,1) = mean(bx_flow(sp_map==sp_id));
        flow_sp(sp_id,2) = mean(by_flow(sp_map==sp_id));
    end

    % Per-superpixel feature extraction
    rgb_p = reshape(in_img,p_num,3);
    rgb_sp = zeros(sp_num,3);
    for sp_id = 1:sp_num
        find_list = (sp_map==sp_id);
        rgb_sp(sp_id,:) = mean(rgb_p(find_list,:),1);
    end
    lab_sp = colorspace('Lab<-', rgb_sp); 

    % Distance between superpixels            
    % L*a*b distance
    lab_dist = dist(lab_sp');
    lab_dist = (lab_dist - min(lab_dist(:))) / (max(lab_dist(:) - min(lab_dist(:))));
    % Optical flow distance
    flow_dist = dist(flow_sp');
    flow_dist = (flow_dist - min(flow_dist(:))) / (max(flow_dist(:) - min(flow_dist(:))));
    
    % Affinity matrix for the initial processes
    mix_dist = param.dist_w(1)*lab_dist + param.dist_w(2)*flow_dist;
    mix_dist(logical(1-long_edge_mat)) = Inf;  % Exclude un-connected edge
    init_aff = exp(-(mix_dist.^2)/param.init.sigsqr);

    % Affinity matrix for the antagonistic energy
    anta_dist = lab_dist;
    anta_dist(logical(1-conn_edge_mat)) = Inf;
    anta_aff = exp(-(anta_dist.^2)/param.anta.sigsqr);
    anta_aff = anta_aff + eye(length(anta_aff));   % Include self similarity
    
    % Transition matrix for the Markov energy
    fg_dist = lab_dist;
    fg_dist(logical(1-conn_edge_mat)) = Inf;
    fg_aff = exp(-(fg_dist.^2)/param.fg.sigsqr);
    self_list = eye(size(fg_aff));
    fg_aff(self_list>0) = 2.0;
    fg_trans = fg_aff*diag(1./(sum(fg_aff)+eps));    % Normalization

    % Lab based background affinity matrix
    bg_dist = lab_dist;
    bg_dist(logical(1-long_edge_mat)) = Inf;  % Exclude un-connected edge
    bg_aff = exp(-(bg_dist.^2)/param.bg.sigsqr);
    bg_trans = bg_aff*diag(1./(sum(bg_aff)+eps));    % Normalization


end