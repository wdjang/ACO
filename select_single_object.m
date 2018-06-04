function [new_p_list, segment_map] = select_single_object(p_list, prior_list, sp_map, border_tblr, orig_size)

[h_size, w_size] = size(sp_map);
num_sp = max(sp_map(:));

post_all = p_list*diag(prior_list);
[~, label_list] = max(post_all,[],2);

if length(unique(label_list)) == 1
    new_p_list = p_list;

    label_list = ( label_list == 1 );
    segment_map = zeros(h_size,w_size);
    for sp_id = 1:num_sp
        segment_map(sp_map==sp_id) = label_list(sp_id);
    end
    segment_map = padarray(segment_map,[border_tblr(1), border_tblr(3)],0,'pre');
    segment_map = padarray(segment_map,[border_tblr(2), border_tblr(4)],0,'post');
    segment_map = imresize(segment_map,[orig_size(1), orig_size(2)],'nearest');
    
    return;
end

bnry_img = zeros(h_size,w_size);
for sp_id = 1:num_sp
    bnry_img(sp_map==sp_id) = double(label_list(sp_id)==1);
end
p_img = zeros(h_size,w_size);
for sp_id = 1:num_sp
    p_img(sp_map==sp_id) = p_list(sp_id,1);
end
conn_comp = bwconncomp(bnry_img,8);
conn_p = zeros(conn_comp.NumObjects,1);
fg_map = zeros(h_size, w_size);
for comp_id = 1:conn_comp.NumObjects
    conn_p(comp_id) = sum(p_img(conn_comp.PixelIdxList{comp_id}));
end

[~, max_id] = max(conn_p);
fg_map(conn_comp.PixelIdxList{max_id}) = 1;

single_mask = zeros(num_sp,1);
for sp_id = 1:num_sp
    single_mask(sp_id) = sum(fg_map(sp_map==sp_id))>0;
end

new_p_list = p_list;
new_p_list(:,1) = single_mask.*new_p_list(:,1);
new_p_list(:,1) = new_p_list(:,1)/(sum(new_p_list(:,1))+eps);    % Normalization

[~, label_list] = max(new_p_list*diag(prior_list),[],2);
label_list = ( label_list == 1 );
segment_map = zeros(h_size,w_size);
for sp_id = 1:num_sp
    segment_map(sp_map==sp_id) = label_list(sp_id);
end
segment_map = padarray(segment_map,[border_tblr(1), border_tblr(3)],0,'pre');
segment_map = padarray(segment_map,[border_tblr(2), border_tblr(4)],0,'post');
segment_map = imresize(segment_map,[orig_size(1), orig_size(2)],'nearest');

end