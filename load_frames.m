%% Read all frames
function [frame_list, orig_size, border_tblr] = load_frames(seq_path)
    border_param = 5;   % If you want to skip border elimination, set this parameter to 0.
    % Load sequences
    file_list = dir(fullfile(seq_path,'*.png'));
    if isempty(file_list)
        file_list = dir(fullfile(seq_path,'*.bmp'));
        if isempty(file_list)
            file_list = dir(fullfile(seq_path,'*.jpg'));
        end
    end
    % Resize frames
    temp_img = im2double(imread(fullfile(seq_path,file_list(1).name)));
    orig_size = zeros(2,1);
    [orig_size(1), orig_size(2), ~] = size(temp_img);
    num_pixel = orig_size(1)*orig_size(2);
    if num_pixel > 150000
        h_size_new = round(sqrt(150000*orig_size(1)/orig_size(2)));
        w_size_new = round(sqrt(150000*orig_size(2)/orig_size(1)));
    else
        h_size_new = orig_size(1);
        w_size_new = orig_size(2);
    end
    frame_list = cell(length(file_list),1);
    for list_id = 1:length(file_list)
        frame_list{list_id} = im2double(imread(fullfile(seq_path,file_list(list_id).name)));
        frame_list{list_id} = imresize(frame_list{list_id}, [h_size_new, w_size_new]);
    end
    % Border elimination
    col_sum = zeros(size(frame_list{1},2),1);
    row_sum = zeros(size(frame_list{1},1),1);
    for list_id = 1:length(file_list)
        col_sum = col_sum + sum(squeeze(sum(frame_list{list_id})),2);
        row_sum = row_sum + sum(squeeze(sum(frame_list{1},2)),2);
    end
    col_sum = col_sum./length(row_sum);
    row_sum = row_sum./length(col_sum);
    left_axis = 1;
    right_axis = length(col_sum);
    for col_id = 1:round(length(col_sum)/2)
        if col_sum(col_id) < border_param
            left_axis = col_id + 1;
        end
    end
    for col_id = length(col_sum):-1:round(length(col_sum)/2)+1
        if col_sum(col_id) < border_param
            right_axis = col_id - 1;
        end
    end
    top_axis = 1;
    bottom_axis = length(row_sum);
    for row_id = 1:round(length(row_sum)/2)
        if row_sum(row_id) < border_param
            top_axis = row_id + 1;
        end
    end
    for row_id = length(row_sum):-1:round(length(row_sum)/2)+1
        if row_sum(row_id) < border_param
            bottom_axis = row_id - 1;
        end
    end
    for list_id = 1:length(file_list)
        frame_list{list_id} = frame_list{list_id}(top_axis:bottom_axis,left_axis:right_axis,:);
    end
    border_tblr = [top_axis-1; h_size_new-bottom_axis; left_axis-1; w_size_new-right_axis];
end