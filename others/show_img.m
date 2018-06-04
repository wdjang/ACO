function show_img(low_num, col_num, plot_id, sp2p_trans, sp_p, h_size, w_size)

%% Show image
p_p = sp2p_trans*sp_p;
subplot(low_num,col_num,plot_id);
p_img = reshape(p_p,h_size,w_size);
imshow((p_img-min(p_img(:)))/(max(p_img(:))-min(p_img(:))));

end