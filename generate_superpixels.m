function sp_list = generate_superpixels(frame_list, result_path, param_slic)

    save_path = fullfile(result_path,'data'); 
    slic_path = fullfile(save_path,'superpixels/');    % the superpixel label file path

    if exist(fullfile(save_path,'sp_list.mat'),'file')
        load(fullfile(save_path,'sp_list.mat'));
    else
        mkdir(slic_path);
        sp_list = cell(length(frame_list),1);
        for img_id = 1:length(frame_list)
            img_str = sprintf('%04d',img_id);
            bmp_name = fullfile(slic_path,[img_str, '.bmp']);
            imwrite(frame_list{img_id}, bmp_name);
            slic_com = ['SLICSuperpixelSegmentation', ' ', bmp_name, ' ', int2str(param_slic.edge), ...
                ' ', int2str(param_slic.area), ' ', slic_path];  
            system(slic_com);   fprintf('\n');
            slic_img = imread(fullfile(slic_path,[img_str, '_SLIC.bmp']));
            slic_img = flip(slic_img,2);
            imwrite(slic_img, fullfile(slic_path,[img_str, '_SLIC.png']));
            delete(fullfile(slic_path,[img_str, '_SLIC.bmp']));
            sp_list{img_id} = ReadDAT([size(frame_list{img_id},1),size(frame_list{img_id},2)],...
                fullfile(slic_path,[img_str, '.dat']));
        end
        save(fullfile(save_path,'sp_list.mat'),'sp_list');
    end
end