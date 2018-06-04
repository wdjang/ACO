function [fx_flow, fy_flow] = estimate_forward_optcial_flow(frame_list, result_path)
    
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
    
    if exist(fullfile(temp_dir,'fx_flow.mat'),'file')
        load(fullfile(temp_dir,'fx_flow.mat'));
        load(fullfile(temp_dir,'fy_flow.mat'));
    else
        fx_flow = cell(length(frame_list),1);
        fy_flow = cell(length(frame_list),1);

        for img_id = 1:length(frame_list)-1
            im1 = frame_list{img_id};
            im2 = frame_list{img_id+1};

            [vx, vy, ~] = Coarse2FineTwoFrames(im1,im2,para);

            fx_flow{img_id} = vx;
            fy_flow{img_id} = vy;
        end
        
        fx_flow{length(frame_list)} = zeros(size(vx));
        fy_flow{length(frame_list)} = zeros(size(vy));
        
        save(fullfile(temp_dir,'fx_flow.mat'),'fx_flow');
        save(fullfile(temp_dir,'fy_flow.mat'),'fy_flow');
    end
        
end
