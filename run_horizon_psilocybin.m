%% Clear workspace
clear all
current_file_path = mfilename('fullpath');
current_file_directory = fileparts(current_file_path);
cd(current_file_directory);
%% Construct the appropriate path depending on the system this is run on
% If running on the analysis cluster, some parameters will be supplied by 
% the job submission script -- read those accordingly.

dbstop if error

if ispc
    root = 'L:/';
elseif ismac
    root = '/Volumes/labs/';
elseif isunix 
    root = '/media/labs/';
end

%% Import matjags library and REDCap function
addpath([root 'rsmith/all-studies/core/matjags']);
addpath([root 'rsmith/lab-members/clavalley/MATLAB/functions']);
addpath([root '/rsmith/all-studies/util/spm12/']);
addpath([root '/rsmith/all-studies/util/spm12/toolbox/DEM/']);
addpath([root '/rsmith/all-studies/models/extended-horizon']);


%% Import model-specific fitting function
% Navigate to this directory to see the model fitting function and wrapper
% code.
% addpath([root 'rsmith/all-studies/models/extended-horizon']);

%% Set parameters
resdir = 'L:/rsmith/lab-members/cgoldman/johns_hopkins_horizon/model_output';

%% Get participant list

record_ids = [1, 5, 10, 12, 16, 17, 21, 30, 33, 35, 36, 40, 45, 46, 47, 53];


%% Get timestamp
timestamp = datestr(datetime('now'), 'mm_dd_yy_THH-MM-SS');

%% Performing merge operation on relevant dataset
% This will read all (relevant) files from the directory pointed to
[big_table, subj_mapping] = merge_horizon_adm_cmg(record_ids);
outpath_beh = sprintf([resdir '/all_subjects_data_%s.csv'], timestamp);
writetable(big_table, outpath_beh);

%% Perform model fit
% Reads in the above 'outpath_beh' file and fits on this file
fits = fit_extended_model_VB(outpath_beh); % choose fit_extended_model() or fit_extended_model_VB
fits = struct2table(fits);
fits.id = {subj_mapping.id}';
outpath_fits = sprintf([resdir '/fits_%s.csv'], timestamp);
writetable(fits, outpath_fits);

