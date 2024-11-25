function [fits, model_output] = fit_extended_model_VB(formatted_file, result_dir, MDP)
    fundir      = pwd;%[maindir 'TMS_code/'];
    currdir     = pwd;
    addpath(fundir);
%     addpath('~/Documents/MATLAB/MatJAGS/');
    cd(fundir);

%     sub = load_TMS_v1([datadir '/EIT_HorizonTaskOutput_HierarchicalModelFormat_v2.csv']);
    sub = load_TMS_v1(formatted_file);

    disp(sub);
    
    %% ========================================================================
    %% HIERARCHICAL MODEL FIT ON FIRST FREE CHOICE %%
    %% HIERARCHICAL MODEL FIT ON FIRST FREE CHOICE %%
    %% HIERARCHICAL MODEL FIT ON FIRST FREE CHOICE %%
    %% ========================================================================

    %% prep data structure 
    clear a
    L = unique(sub(1).gameLength);
    NS = length(sub);   % number of subjects
    T = 4;              % number of forced choices
    
    NUM_GAMES = max(vertcat(sub.game), [], 'all');

    a  = zeros(NS, NUM_GAMES, T);
    c5 = nan(NS,   NUM_GAMES);
    r  = zeros(NS, NUM_GAMES, T);
    UC = nan(NS,   NUM_GAMES); % equal or unequal info; 2 is unequal info
    GL = nan(NS,   NUM_GAMES);

    for sn = 1:length(sub)

        % choices on forced trials
        dum = sub(sn).a(:,1:4);
        a(sn,1:size(dum,1),:) = dum;

        % choices on free trial
        % note a slight hacky feel here - a is 1 or 2, c5 is 0 or 1.
        dum = sub(sn).a(:,5) == 2;
        L(sn) = length(dum);
        c5(sn,1:size(dum,1)) = dum;

        % rewards
        dum = sub(sn).r(:,1:4);
        r(sn,1:size(dum,1),:) = dum;

        % game length
        dum = sub(sn).gameLength;
        GL(sn,1:size(dum,1)) = dum;

        G(sn) = length(dum);

        % uncertainty condition 
        dum = abs(sub(sn).uc - 2) + 1;
        UC(sn, 1:size(dum,1)) = dum;

        % difference in information; right informativeness
        dum = sub(sn).uc - 2;
        dI(sn, 1:size(dum,1)) = -dum;

        % TMS flag
        dum = strcmp(sub(sn).expt_name, 'RFPC');
        TMS(sn,1:size(dum,1)) = dum;

    end

    dum = GL(:); dum(dum==0) = [];
    H = length(unique(dum));
    dum = UC(:); dum(dum==0) = [];
    U = length(unique(dum));
    GL(GL==5) = 1;
    GL(GL==10) = 2;

    C1 = (GL-1)*2+UC; % h1_equal = 1; h1_unequal = 2; h6_equal = 3; h6_unequal = 4
    C2 = TMS + 1;
    nC1 = 4;
    nC2 = 1;

    % meaning of condition 1
    % gl uc c1
    %  1  1  1 - horizon 1, [2 2]
    %  1  2  2 - horizon 6, [1 3]
    %  2  1  3 - horizon 1, [2 2]
    %  2  2  4 - horizon 6, [1 3]

    % meaning of condition 1 (SMT FIXED)
    % gl uc c1
    %  1  1  1 - horizon 1, [2 2]
    %  1  2  2 - horizon 1, [1 3]
    %  2  1  3 - horizon 6, [2 2]
    %  2  2  4 - horizon 6, [1 3]



    datastruct = struct(...
        'C1', C1, 'nC1', nC1, ...
        'NS', NS, 'G',  G,  'T',   T, ...
        'dI', dI, 'a',  a,  'c5',  c5, 'r', r);

    

    if ispc
        root = 'L:/';
    elseif ismac
        root = '/Volumes/labs/';
    elseif isunix 
        root = '/media/labs/';
    end
    
    fprintf( 'Running Newton Function to fit\n' );
    MDP.datastruct = datastruct;
    MDP.params.info_bonus_h1 = 0;
    MDP.params.info_bonus_h6 = 0; 
    MDP.params.dec_noise_h1_22 = 1;
    MDP.params.dec_noise_h1_13 = 1;
    MDP.params.dec_noise_h6_22 = 1; 
    MDP.params.dec_noise_h6_13 = 1; 
    MDP.params.spatial_bias_h1_22 = 0;
    MDP.params.spatial_bias_h1_13 = 0;
    MDP.params.spatial_bias_h6_22 = 0; 
    MDP.params.spatial_bias_h6_13 = 0; 
    MDP.params.alpha_inf = .5; 
    MDP.params.alpha_start = .5; 
    MDP.field = fieldnames(MDP.params);

    for k = 1:NS
        MDP.datastruct = datastruct;
        MDP.datastruct.C1 = datastruct.C1(k,:);
        MDP.datastruct.G = datastruct.G(k);
        MDP.datastruct.dI = datastruct.dI(k,:);
        MDP.datastruct.forced_choices = squeeze(datastruct.a(k,:,:))';
        MDP.datastruct.c5 = datastruct.c5(k,:);
        MDP.datastruct.r = squeeze(datastruct.r(k,:,:))';
        DCM = horizon_inversion(MDP);
        
        field = DCM.field;
        % get fitted and fixed params
        fits(k).id = k;
        fits(k).num_games_played = MDP.datastruct.G;
        for i = 1:length(field)
            if ismember(field{i},{'alpha_start', 'alpha_inf'})
                fits(k).(field{i}) = 1/(1+exp(-DCM.Ep.(field{i})));
                params.(field{i}) = fits(k).(field{i});
            elseif ismember(field{i}, {'dec_noise_h1_22', 'dec_noise_h1_13', 'dec_noise_h6_22', 'dec_noise_h6_13' })
                fits(k).(field{i}) = exp(DCM.Ep.(field{i}));
                params.(field{i}) = fits(k).(field{i});
            elseif ismember(field{i},{'info_bonus_h1', 'info_bonus_h6', 'spatial_bias_h1_22', 'spatial_bias_h1_13', 'spatial_bias_h6_22', 'spatial_bias_h6_13'})
                fits(k).(field{i}) = DCM.Ep.(field{i});
                params.(field{i}) = fits(k).(field{i});
            else
                disp(field{i});
                error("Param not propertly transformed");
            end
        end
        model_output = model_KFcond_v2_SMT_CMG(params,MDP.datastruct.c5, MDP.datastruct.r,MDP.datastruct);
        fits(k).directed_exploration = fits(k).info_bonus_h6 - fits(k).info_bonus_h1;
        fits(k).random_exploration = fits(k).dec_noise_h6_22 - fits(k).dec_noise_h1_22;
        fits(k).average_action_prob = mean(model_output.action_probs(~isnan(model_output.action_probs)), 'all');
        fits(k).model_acc = sum(model_output.action_probs(~isnan(model_output.action_probs)) > 0.5) / numel(model_output.action_probs(~isnan(model_output.action_probs)));
        
        
    end
   

    

%     
%     
%     actions = datastruct.actions;
%     rewards = datastruct.rewards;
% 
%     mdp = datastruct;
%     % note that mu2 == right bandit ==  c=2 == free choice = 1
% 
% 
%     %model_output(si).results = model_KFcond_v2_SMT_CMG(params,free_choices, rewards,mdp);    
%     model_output = model_SM_KF_all_choices(fits,actions, rewards,mdp);    
%     fits.average_action_prob = mean(model_output.action_probs(~isnan(model_output.action_probs)), 'all');
%     fits.model_acc = sum(model_output.action_probs(~isnan(model_output.action_probs)) > 0.5) / numel(model_output.action_probs(~isnan(model_output.action_probs)));
%         
%     
%                 
%     
%     datastruct.actions = model_output.simmed_free_choices;
%     datastruct.rewards = model_output.simmed_rewards;
%     MDP.datastruct = datastruct;
%     % note old social media model model_KFcond_v2_SMT
%     fprintf( 'Running VB to fit simulated behavior! \n' );
% 
%     simfit_DCM = SM_inversion(MDP);
% 
%     for i = 1:length(field)
%         if ismember(field{i},{'alpha_start', 'alpha_inf'})
%             fits.(['simfit_' field{i}]) = 1/(1+exp(-simfit_DCM.Ep.(field{i})));
%         elseif ismember(field{i},{'dec_noise_h1_13', 'dec_noise_h5_13', 'info_bonus', 'outcome_informativeness', 'sigma_d', 'info_bonus', 'random_exp'})
%             fits.(['simfit_' field{i}]) = exp(simfit_DCM.Ep.(field{i}));
%         elseif ismember(field{i},{'info_bonus_h1', 'info_bonus_h5','side_bias_h1', 'side_bias_h5','side_bias'})
%             fits.(['simfit_' field{i}]) = simfit_DCM.Ep.(field{i});
%         else
%             disp(field{i});
%             error("Param not propertly transformed");
%         end
%     end
    
    
 end