function [bx_flow, by_flow] = estimate_backward_optical_flow(frame_list, result_path)
    
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
    
    if exist(fullfile(temp_dir,'bx_flow.mat'),'file')
        load(fullfile(temp_dir,'bx_flow.mat'));
        load(fullfile(temp_dir,'by_flow.mat'));
    else
        bx_flow = cell(length(frame_list),1);
        by_flow = cell(length(frame_list),1);

        for img_id = 2:length(frame_list)
            im1 = frame_list{img_id};
            im2 = frame_list{img_id-1};

            [vx, vy, ~] = Coarse2FineTwoFrames(im1,im2,para);

            bx_flow{img_id} = vx;
            by_flow{img_id} = vy;
        end
        
        bx_flow{1} = zeros(size(vx));
        by_flow{1} = zeros(size(vy));
        
        save(fullfile(temp_dir,'bx_flow.mat'),'bx_flow');
        save(fullfile(temp_dir,'by_flow.mat'),'by_flow');
    end
end
