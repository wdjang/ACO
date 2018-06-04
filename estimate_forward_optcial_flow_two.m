function [fx_flow_two, fy_flow_two] = estimate_forward_optcial_flow_two(frame_list, result_path)
    
    % set optical flow parameters (see Coarse2FineTwoFrames.m for the definition of the parameters)
    alpha = 0.012;
    ratio = 0.75;
    minWidth = 20;
    nOuterFPIterations = 7;
    nInnerFPIterations = 1;
    nSORIterations = 30;

    para = [alpha,ratio,minWidth,nOuterFPIterations,nInnerFPIterations,nSORIterations];
    
    temp_dir = fullfile(result_path,'data'); 
    if exist(temp_dir,'dir') == 0
        mkdir(temp_dir);
    end
    
    if exist(fullfile(temp_dir,'fx_flow_two.mat'),'file')
        load(fullfile(temp_dir,'fx_flow_two.mat'));
        load(fullfile(temp_dir,'fy_flow_two.mat'));
    else
        fx_flow_two = cell(length(frame_list),1);
        fy_flow_two = cell(length(frame_list),1);

        for img_id = 1:length(frame_list)-2
            im1 = frame_list{img_id};
            im2 = frame_list{img_id+2};

            [vx, vy, ~] = Coarse2FineTwoFrames(im1,im2,para);

            fx_flow_two{img_id} = vx;
            fy_flow_two{img_id} = vy;
        end
        
        fx_flow_two{length(frame_list)} = zeros(size(vx));
        fy_flow_two{length(frame_list)} = zeros(size(vy));
        
        save(fullfile(temp_dir,'fx_flow_two.mat'),'fx_flow_two');
        save(fullfile(temp_dir,'fy_flow_two.mat'),'fy_flow_two');
    end
    
    
end
