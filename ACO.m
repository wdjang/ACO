%% Main code of ACO
function segment_track = ACO(seq_path,result_path,param_list)
  
    %% Load frames
    [frame_list, orig_size, border_tblr] = load_frames(seq_path);
    segment_track = cell(length(frame_list),1);
    
    %% Optical flow computation
    fprintf('Optical flow estimation..\n');
    [fx_flow, fy_flow] = estimate_forward_optcial_flow(frame_list, result_path);
    [bx_flow, by_flow] = estimate_backward_optical_flow(frame_list, result_path);
    
    [fx_flow_two, fy_flow_two] = estimate_forward_optcial_flow_two(frame_list, result_path);
    [bx_flow_two, by_flow_two] = estimate_backward_optical_flow_two(frame_list, result_path);
    
    fx_flow{end} = bx_flow{end};
    fy_flow{end} = by_flow{end};
    
    bx_flow{1} = fx_flow{1};
    by_flow{1} = fy_flow{1};
    
    % Over-segmentation
    fprintf('Superpixel generation..\n');
    sp_list = generate_superpixels(frame_list, result_path, param_list.slic);

    %% Main process
    fprintf('Main process..\n');
    % Processing for the first frame
    frame_id = 1;
    fprintf('Frame %d\n',frame_id);
    conn_edge_mat = construct_edge_matrix(sp_list{frame_id},1);
    long_edge_mat = construct_edge_matrix(sp_list{frame_id},4);
    [init_aff, ~, ~, ~] = construct_affinity_matrix(frame_list{frame_id}, sp_list{frame_id}, ...
        bx_flow{frame_id}, by_flow{frame_id}, conn_edge_mat, long_edge_mat, param_list);
    % Initial probability estimation
    prev_p_list = initial_probability_estimation(sp_list{frame_id}, init_aff, param_list);
    prev_prior_list = 1./max(prev_p_list);
    prev_prior_list = prev_prior_list / sum(prev_prior_list);
    % Processing from the second to the last frames
    for frame_id = 2:length(frame_list)

        fprintf('Frame %d\n',frame_id);
        num_sp = max(sp_list{frame_id}(:));

        % Affinity and boundary restart probability
        conn_edge_mat = construct_edge_matrix(sp_list{frame_id},1);
        long_edge_mat = construct_edge_matrix(sp_list{frame_id},4);
        [init_aff, anta_aff, fg_trans, bg_trans] = construct_affinity_matrix(frame_list{frame_id}, sp_list{frame_id}, ...
            bx_flow{frame_id}, by_flow{frame_id}, conn_edge_mat, long_edge_mat, param_list);

        % Initial probability estimation
        init_list = initial_probability_estimation(sp_list{frame_id}, init_aff, param_list);
        
        % Build propagation matrix
        inter_aff = construct_propagation_matrix(by_flow{frame_id}, bx_flow{frame_id}, ...
            sp_list{frame_id-1}, sp_list{frame_id});
        if frame_id > 2
            inter_aff_two = construct_propagation_matrix(by_flow_two{frame_id}, bx_flow_two{frame_id}, ...
                sp_list{frame_id-2}, sp_list{frame_id});
        end
        
        % Prior probability
        prior_list = 1./max(prev_p_list);
        prior_list = prior_list/sum(prior_list);

        % Propagation
        [~, label_list] = max(prev_p_list*diag(prev_prior_list),[],2);
        if frame_id > 2
            [~, label_list_two] = max(pprev_p_list*diag(pprev_prior_list),[],2);
        end
        if frame_id == 2
            warp_list = [inter_aff*(label_list==1), inter_aff*(label_list==2)];
        else
            warp_list = [0.5*inter_aff*(label_list==1) + 0.5*inter_aff_two*(label_list_two==1), ...
                0.5*inter_aff*(label_list==2) + 0.5*inter_aff_two*(label_list_two==2)];
        end
        
        % Spatiotemporal distribution computation
        sptemp_list = warp_list.*init_list;
        sptemp_list = sptemp_list*diag(1./(sum(sptemp_list)+eps));    % Normalization

        % ACO
        num_node = size(init_list,1);

        col_sim = double(conn_edge_mat.*anta_aff);

        d_old = Inf;
        
        a_list = init_list(:,1) > init_list(:,2);
        oldp_list = [init_list(:,1).*a_list, init_list(:,2).*(1-a_list)];
        
        p_list = zeros(num_node,2);
        temp_list = zeros(num_node,2);
        while 1
            q = oldp_list(:,2);
            cvx_begin quiet
                cvx_solver sedumi;
                variable p(num_node);
                minimize( norm(fg_trans*p-p) + param_list.w_sptemp*norm(p-sptemp_list(:,1)) + param_list.w_anta*q'*col_sim*p );
                subject to
                    0 <= p <= 1;
                    sum(p) == 1;
            cvx_end
            temp_list(:,1) = p;
            q = oldp_list(:,1);
            cvx_begin quiet
                cvx_solver sedumi;
                variable p(num_node);
                minimize( norm(bg_trans*p-p) + param_list.w_sptemp*norm(p-sptemp_list(:,2)) + param_list.w_anta*q'*col_sim*p );
                subject to
                    0 <= p <= 1;
                    sum(p) == 1;
            cvx_end
            temp_list(:,2) = p;

            d_cur = 0;

            q = temp_list(:,2);
            d_cur = d_cur + norm(fg_trans*temp_list(:,1)-temp_list(:,1)) ...
                + param_list.w_sptemp*norm(temp_list(:,1)-sptemp_list(:,1)) ...
                + param_list.w_anta*q'*col_sim*temp_list(:,1);

            q = temp_list(:,1);
            d_cur = d_cur + norm(bg_trans*temp_list(:,2)-temp_list(:,2)) ...
                + param_list.w_sptemp*norm(temp_list(:,2)-sptemp_list(:,2)) ...
                + param_list.w_anta*q'*col_sim*temp_list(:,2);

            if d_cur >= d_old
                p_list = oldp_list;
                break;
            end

            oldp_list = temp_list;
            
            d_old = d_cur;
        end
        
        pprev_p_list = prev_p_list;
        pprev_prior_list = prev_prior_list;

        prev_p_list = p_list;
        prev_prior_list = prior_list;
    end

    
    
    %% Single object selection
    [prev_p_list, segment_map] = select_single_object(prev_p_list, prev_prior_list, sp_list{frame_id}, border_tblr, orig_size);
    
    imwrite(segment_map,fullfile(result_path,sprintf('%04d.png',frame_id)));
    segment_track{frame_id} = segment_map;

    %% Backward
    for frame_id = length(frame_list)-1:-1:1

        fprintf('Frame %d\n',frame_id);
        num_sp = max(sp_list{frame_id}(:));

        % Affinity and boundary restart probability
        conn_edge_mat = construct_edge_matrix(sp_list{frame_id},1);
        long_edge_mat = construct_edge_matrix(sp_list{frame_id},4);
        [init_aff, anta_aff, fg_trans, bg_trans] = construct_affinity_matrix(frame_list{frame_id}, sp_list{frame_id}, ...
            bx_flow{frame_id}, by_flow{frame_id}, conn_edge_mat, long_edge_mat, param_list);

        % Initial probability estimation
        init_list = initial_probability_estimation(sp_list{frame_id}, init_aff, param_list);

        % Build propagation matrix
        inter_aff = construct_propagation_matrix(fy_flow{frame_id}, fx_flow{frame_id}, ...
            sp_list{frame_id+1}, sp_list{frame_id});
        if frame_id < length(frame_list)-1
            inter_aff_two = construct_propagation_matrix(fy_flow_two{frame_id}, fx_flow_two{frame_id}, ...
                sp_list{frame_id+2}, sp_list{frame_id});
        end
        
        % Prior probability
        prior_list = 1./max(prev_p_list);
        prior_list = prior_list/sum(prior_list);
        
        % Propagation
        [~, label_list] = max(prev_p_list*diag(prev_prior_list),[],2);
        if frame_id < length(frame_list)-1
            [~, label_list_two] = max(pprev_p_list*diag(pprev_prior_list),[],2);
        end
        if frame_id == length(frame_list)-1
            warp_list = [inter_aff*(label_list==1), inter_aff*(label_list==2)];
        else
            warp_list = [0.5*inter_aff*(label_list==1) + 0.5*inter_aff_two*(label_list_two==1), ...
                0.5*inter_aff*(label_list==2) + 0.5*inter_aff_two*(label_list_two==2)];
        end
        
        % Spatiotemporal distribution computation
        sptemp_list = warp_list.*init_list;
        sptemp_list = sptemp_list*diag(1./(sum(sptemp_list)+eps));    % Normalization

        % ACO
        num_node = size(init_list,1);

        col_sim = double(conn_edge_mat.*anta_aff);

        d_old = Inf;
        
        a_list = init_list(:,1) > init_list(:,2);
        oldp_list = [init_list(:,1).*a_list, init_list(:,2).*(1-a_list)];
        
        p_list = zeros(num_node,2);
        temp_list = zeros(num_node,2);
        while 1
            q = oldp_list(:,2);
            cvx_begin quiet
                cvx_solver sedumi;
                variable p(num_node);
                minimize( norm(fg_trans*p-p) + param_list.w_sptemp*norm(p-sptemp_list(:,1)) + param_list.w_anta*q'*col_sim*p );
                subject to
                    0 <= p <= 1;
                    sum(p) == 1;
            cvx_end
            temp_list(:,1) = p;
            q = oldp_list(:,1);
            cvx_begin quiet
                cvx_solver sedumi;
                variable p(num_node);
                minimize( norm(bg_trans*p-p) + param_list.w_sptemp*norm(p-sptemp_list(:,2)) + param_list.w_anta*q'*col_sim*p );
                subject to
                    0 <= p <= 1;
                    sum(p) == 1;
            cvx_end
            temp_list(:,2) = p;

            d_cur = 0;

            q = temp_list(:,2);
            d_cur = d_cur + norm(fg_trans*temp_list(:,1)-temp_list(:,1)) ...
                + param_list.w_sptemp*norm(temp_list(:,1)-sptemp_list(:,1)) ...
                + param_list.w_anta*q'*col_sim*temp_list(:,1);

            q = temp_list(:,1);
            d_cur = d_cur + norm(bg_trans*temp_list(:,2)-temp_list(:,2)) ...
                + param_list.w_sptemp*norm(temp_list(:,2)-sptemp_list(:,2)) ...
                + param_list.w_anta*q'*col_sim*temp_list(:,2);

            if d_cur >= d_old
                p_list = oldp_list;
                break;
            end

            oldp_list = temp_list;
            
            d_old = d_cur;
        end

        % Single object selection
        [p_list, segment_map] = select_single_object(p_list, prior_list, sp_list{frame_id}, border_tblr, orig_size);

        imwrite(segment_map,fullfile(result_path,sprintf('%04d.png',frame_id)));
        segment_track{frame_id} = segment_map;
        
        pprev_p_list = prev_p_list;
        pprev_prior_list = prev_prior_list;

        prev_p_list = p_list;
        prev_prior_list = prior_list;
    end
                
end














