%% ===================================================
%  Primary video object segmentation
%  Code written by Won-Dong Jang (wdjang@mcl.korea.ac.kr)
%  ===================================================

clear all

%% System setting
addpath('others');
addpath('core');
addpath(genpath('Optical Flow'));

%% Parameter setting
param_list = set_param;

%% DB setting
data_dir = './dataset';
result_dir = './results';

seq_name = 'longJump';

%% Set sequence directory
fprintf('=============================================\n');
fprintf('%s\n',seq_name);
fprintf('=============================================\n');
seq_path = fullfile(data_dir,seq_name);
result_path = fullfile(result_dir,seq_name);

%% Perform ACO
segment_track = ACO(seq_path,result_path,param_list);

%% Visualize segmentation result
figure;
for frame_id = 1:length(segment_track)
    imshow(segment_track{frame_id}==1);
    pause(0.1);
end