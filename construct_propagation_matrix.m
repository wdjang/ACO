function inter_aff = construct_propagation_matrix(back_yflow, back_xflow, sp_img1, sp_img2)

    sp_num1 = max(sp_img1(:));
    sp_num2 = max(sp_img2(:));
    [h_size, w_size] = size(sp_img1);
    conn_edge = zeros(sp_num2, sp_num1);
    
    for y_id = 1:h_size
        for x_id = 1:w_size
            % From Img2 to Img1
            warp_y = min(max(round(y_id+back_yflow(y_id,x_id)),1),h_size);
            warp_x = min(max(round(x_id+back_xflow(y_id,x_id)),1),w_size);
            conn_edge(sp_img2(y_id,x_id),sp_img1(warp_y,warp_x)) = ...
                conn_edge(sp_img2(y_id,x_id),sp_img1(warp_y,warp_x)) + 1;
        end
    end
    
    inter_aff = conn_edge;
end