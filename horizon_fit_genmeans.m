function ff = horizon_fit_genmeans(subject, ses, run, study)
%         '/Volumes/Labs/rsmith/BK_Pilot/bids_data/sub-'       ...
%         '/media/cephfs/labs/rsmith/BK_Pilot/bids_data/sub-'  ...
%         '/media/cephfs/labs/raupperle/AAC-BET/Data/bids/sub-'  ...
if strcmp(study,'ADM')
        study_folder = 'adm-common';
elseif strcmp(study, 'METH')
   study_folder = 'adm-meth-pilot-common';
end
    filepath = [                                             ...
        'L:/rsmith/' study_folder '/data/raw/sub-' ...
        subject                                              ...
        '/ses-t'                                             ...
        num2str(ses)                                         ...
        '/beh/sub-'                                          ...
        subject                                              ...
        '_ses-t'                                             ...
        num2str(ses)                                         ...
        '_task-horizon_run-'                                 ...
        num2str(run)                                         ...
        '_events.tsv'                                        ...
    ];
    tab = readtable(filepath, 'FileType', 'text');
    data = parse_table(tab, subject, run);
    
    ff = fit_horizon(data);
    
    % ---------------------------------------------------------------
    
    h6 = data([data.horizon] == 6);
    h1 = data([data.horizon] == 1);
    
    h1_22 = h1(sum([vertcat(h1.forced_type)'] == 2) == 2);
    h1_13 = h1(sum([vertcat(h1.forced_type)'] == 2) ~= 2);

    h6_22 = h6(sum([vertcat(h6.forced_type)'] == 2) == 2);
    h6_13 = h6(sum([vertcat(h6.forced_type)'] == 2) ~= 2);
    
    h6_meancor = vertcat(h6.mean_correct);
    h1_meancor = vertcat(h1.mean_correct);
    
    % for Figure1C ------------------------------
    ff.h6_freec1_acc = sum(h6_meancor(:, 5))  / numel(h6);
    ff.h6_freec2_acc = sum(h6_meancor(:, 6))  / numel(h6);
    ff.h6_freec3_acc = sum(h6_meancor(:, 7))  / numel(h6);
    ff.h6_freec4_acc = sum(h6_meancor(:, 8))  / numel(h6);
    ff.h6_freec5_acc = sum(h6_meancor(:, 9))  / numel(h6);
    ff.h6_freec6_acc = sum(h6_meancor(:, 10)) / numel(h6);
    
    ff.h1_freec1_acc = sum(h1_meancor(:, 5)) / numel(h1);
    % end Figure1C ------------------------------
    
    % for Figure1D ------------------------------
    % ???
    % end Figure1D ------------------------------
    
    % for Figure2A ------------------------------
    ff.h6_more_info_30_less = pminfo(h6_13, -30);
    ff.h6_more_info_20_less = pminfo(h6_13, -20);
    ff.h6_more_info_12_less = pminfo(h6_13, -12);
    ff.h6_more_info_08_less = pminfo(h6_13, -8);
    ff.h6_more_info_04_less = pminfo(h6_13, -4);
    ff.h6_more_info_30_more = pminfo(h6_13, 30);
    ff.h6_more_info_20_more = pminfo(h6_13, 20);
    ff.h6_more_info_12_more = pminfo(h6_13, 12);
    ff.h6_more_info_08_more = pminfo(h6_13, 8);
    ff.h6_more_info_04_more = pminfo(h6_13, 4);
    
    ff.h1_more_info_30_less = pminfo(h1_13, -30);
    ff.h1_more_info_20_less = pminfo(h1_13, -20);
    ff.h1_more_info_12_less = pminfo(h1_13, -12);
    ff.h1_more_info_08_less = pminfo(h1_13, -8);
    ff.h1_more_info_04_less = pminfo(h1_13, -4);
    ff.h1_more_info_30_more = pminfo(h1_13, 30);
    ff.h1_more_info_20_more = pminfo(h1_13, 20);
    ff.h1_more_info_12_more = pminfo(h1_13, 12);
    ff.h1_more_info_08_more = pminfo(h1_13, 8);
    ff.h1_more_info_04_more = pminfo(h1_13, 4);
    
    ff.h6_right_30_less = pright(h6_22, -30);
    ff.h6_right_20_less = pright(h6_22, -20);
    ff.h6_right_12_less = pright(h6_22, -12);
    ff.h6_right_08_less = pright(h6_22, -8);
    ff.h6_right_04_less = pright(h6_22, -4);
    ff.h6_right_30_more = pright(h6_22, 30);
    ff.h6_right_20_more = pright(h6_22, 20);
    ff.h6_right_12_more = pright(h6_22, 12);
    ff.h6_right_08_more = pright(h6_22, 8);
    ff.h6_right_04_more = pright(h6_22, 4);
    
    ff.h1_right_30_less = pright(h1_22, -30);
    ff.h1_right_20_less = pright(h1_22, -20);
    ff.h1_right_12_less = pright(h1_22, -12);
    ff.h1_right_08_less = pright(h1_22, -8);
    ff.h1_right_04_less = pright(h1_22, -4);
    ff.h1_right_30_more = pright(h1_22, 30);
    ff.h1_right_20_more = pright(h1_22, 20);
    ff.h1_right_12_more = pright(h1_22, 12);
    ff.h1_right_08_more = pright(h1_22, 8);
    ff.h1_right_04_more = pright(h1_22, 4);
    % end Figure2A ------------------------------
    
    
    % ---------------------------------------------------------------
    
    ff.mean_RT       = mean([data.RT]);
    ff.sub_accuracy  = mean([data.accuracy]);
    
    ff.choice5_acc_gen_mean      = mean([data.choice5_generative_correct]);
    ff.choice5_acc_obs_mean      = mean([data.choice5_observed_correct]);
    ff.choice5_acc_true_mean     = mean([data.choice5_true_correct]);
    ff.choice5_acc_gen_mean_h6   = mean([h6.choice5_generative_correct]);
    ff.choice5_acc_obs_mean_h6   = mean([h6.choice5_observed_correct]);
    ff.choice5_acc_true_mean_h6  = mean([h6.choice5_true_correct]);
    ff.choice5_acc_gen_mean_h1   = mean([h1.choice5_generative_correct]);
    ff.choice5_acc_obs_mean_h1   = mean([h1.choice5_observed_correct]);
    ff.choice5_acc_true_mean_h1  = mean([h1.choice5_true_correct]);
    
    ff.last_acc_gen_mean         = mean([data.last_generative_correct]);
    ff.last_acc_obs_mean         = mean([data.last_observed_correct]);
    ff.last_acc_true_mean        = mean([data.last_true_correct]);
    ff.last_acc_gen_mean_h6      = mean([h6.last_generative_correct]);
    ff.last_acc_obs_mean_h6      = mean([h6.last_observed_correct]);
    ff.last_acc_true_mean_h6     = mean([h6.last_true_correct]);
    ff.last_acc_gen_mean_h1      = mean([h1.last_generative_correct]);
    ff.last_acc_obs_mean_h1      = mean([h1.last_observed_correct]);
    ff.last_acc_true_mean_h1     = mean([h1.last_true_correct]);

    
    ff.mean_RT_h6                = mean([h6.RT]); 
    ff.mean_RT_h1                = mean([h1.RT]); 
    
    ff.mean_RT_choice5           = mean([data.RT_choice5]);
    ff.mean_RT_choiceLast        = mean([data.RT_choiceLast]);
    
    ff.mean_RT_choice5_h6        = mean([h6.RT_choice5]);
    ff.mean_RT_choiceLast_h6     = mean([h6.RT_choiceLast]);
    ff.mean_RT_choice5_h1        = mean([h1.RT_choice5]);
    ff.mean_RT_choiceLast_h1     = mean([h1.RT_choiceLast]);
    
    ff.true_correct_frac         = mean([data.true_correct_frac]);
    ff.true_correct_frac_h1      = mean([h1.true_correct_frac]);
    ff.true_correct_frac_h6      = mean([h6.true_correct_frac]);
    
    ff.last_acc_true_mean_h122   = mean([h1_22.last_true_correct]);
    
    ff = struct2table(ff);
    
%     writetable(ff, [
%         results_dir '/' subject '_ses' num2str(ses) '_run' num2str(run) '_fit.csv'
%     ])
end

function p = pminfo(hor, amt)
    relev = hor([hor.info_diff] == amt);
    
    if numel(relev) > 0
        minfo = [relev.more_info]';
    %     disp([relev.more_info]);
        keys = vertcat(relev.key);

        p = sum(keys(:, 5) == minfo) / numel(relev);
    else
        p = NaN;
    end
end

function p = pright(hor, amt)
    relev = hor([hor.info_diff] == amt);
    if numel(relev) > 0    
        keys = vertcat(relev.key);
        p = sum(keys(:, 5) == 2) / numel(relev);
    else
        p = NaN;
    end
end
