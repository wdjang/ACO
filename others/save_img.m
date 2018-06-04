%% Save image function
% sp2p_trans, sp_p, h_size, w_size, save_name
function save_img(sp2p_trans, sp_p, h_size, w_size, save_name)

%% Save image
p_p = sp2p_trans*sp_p;
p_img = reshape(p_p,h_size,w_size);
imwrite((p_img-min(p_img(:)))/(max(p_img(:))-min(p_img(:))+eps),save_name);

end