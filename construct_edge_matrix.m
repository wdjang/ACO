function edge_mat = construct_edge_matrix(sp_map,k_param)

    sp_num = max(sp_map(:));
    [h_size, w_size] = size(sp_map);    
    edge_mat = zeros(sp_num,sp_num);
    
    for y_id = 1:h_size-1
        for x_id = 1:w_size-1
            if sp_map(y_id,x_id) ~= sp_map(y_id,x_id+1)
                edge_mat(sp_map(y_id,x_id),sp_map(y_id,x_id+1)) = 1;
                edge_mat(sp_map(y_id,x_id+1),sp_map(y_id,x_id)) = 1;
            end
            if sp_map(y_id,x_id) ~= sp_map(y_id+1,x_id)
                edge_mat(sp_map(y_id,x_id),sp_map(y_id+1,x_id)) = 1;
                edge_mat(sp_map(y_id+1,x_id),sp_map(y_id,x_id)) = 1;
            end
            if sp_map(y_id,x_id) ~= sp_map(y_id+1,x_id+1)
                edge_mat(sp_map(y_id,x_id),sp_map(y_id+1,x_id+1)) = 1;
                edge_mat(sp_map(y_id+1,x_id+1),sp_map(y_id,x_id)) = 1;
            end
            if sp_map(y_id+1,x_id) ~= sp_map(y_id,x_id+1)
                edge_mat(sp_map(y_id+1,x_id),sp_map(y_id,x_id+1)) = 1;
                edge_mat(sp_map(y_id,x_id+1),sp_map(y_id+1,x_id)) = 1;
            end
        end
    end
    
    % Connect neighbor's neighbors
    manifold_temp = edge_mat;
    for k_id = 1:k_param-1
        manifold_temp = manifold_temp + manifold_temp*edge_mat;
    end
    edge_mat = manifold_temp > 0;
    
end