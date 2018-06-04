function init_p = initial_probability_estimation(sp_img, init_aff, param)

% Find boundary superpixels
num_node = max(sp_img(:));
spbdry_all = [sp_img(end,:)'; sp_img(1,:)'; sp_img(:,1); sp_img(:,end)];
spbdry_list = unique(spbdry_all);

dd = sum(init_aff); D = sparse(1:num_node,1:num_node,dd); clear dd;
S = sqrt(inv(D))*init_aff*sqrt(inv(D));

bdry_r = zeros(num_node,1);
for list_id = 1:length(spbdry_list)
    sp_id = spbdry_list(list_id);
    bdry_r(sp_id) = 1/max(S(:,sp_id));
end

optAff =(eye(num_node)-param.init.alpha_b*S)\eye(num_node);
bg_bdry_r = optAff*bdry_r;

bg_bdry_r = bg_bdry_r / sum(bg_bdry_r);
fg_bdry_r = exp(-5*num_node*bg_bdry_r);

optAff =(eye(num_node)-param.init.alpha_f*S)\eye(num_node);
fg_bdry_r = optAff*fg_bdry_r;

fg_bdry_r = fg_bdry_r / sum(fg_bdry_r);
bg_bdry_r = bg_bdry_r / sum(bg_bdry_r);

init_p = [fg_bdry_r, bg_bdry_r];

end