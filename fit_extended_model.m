function fits = fit_extended_model(formatted_file)
    fundir      = pwd;%[maindir 'TMS_code/'];
    currdir     = pwd;
    addpath(fundir);
%     addpath('~/Documents/MATLAB/MatJAGS/');
    cd(fundir);
    defaultPlotParameters

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
    
    %% run hierarchical model fits! 
    % 750s (12.5 minutes) for 1500 samples
    % 
    cd(fundir)
    nchains = 4;
    nburnin = 500;
    nsamples = 1000; 
    thin = 1;
    % MCMC parameters for JAGS


    % Initialize values all latent variables in all chains
    clear S init0
    for i=1:nchains

        S.a0(1:nC2) = 1;
        S.b0(1:nC2) = 1;
        S.a_inf(1:nC2) = 1;
        S.b_inf(1:nC2) = 1;
        S.AA(1:NS,1:nC1,1:nC2) = 0;
        S.BB(1:NS,1:nC1,1:nC2) = 100;

        init0(i) = S;
    end

    % Use JAGS to Sample
    tic

    doparallel = 1;
    % if doparallel
    %     parpool;
    % end
    
    if ispc
        root = 'L:/';
    elseif ismac
        root = '/Volumes/labs/';
    elseif isunix 
        root = '/media/labs/';
    end
    
    
    fprintf( 'Running JAGS\n' );
    [samples, stats ] = matjags( ...
        datastruct, ...
        fullfile(currdir, 'model_KFcond_v2_SMT'), ...
        init0, ...
        'doparallel' , doparallel, ...
        'nchains', nchains,...
        'nburnin', nburnin,...
        'nsamples', nsamples, ...
        'thin', thin, ...
        'monitorparams', ...
        {'a0' 'b0' 'alpha_start' 'alpha0' 'alpha_d' ...
        'a_inf' 'b_inf' 'alpha_inf' ...
        'AA_mean' 'AA_sigma' 'AA' ...
        'SB_mean' 'SB_sigma' 'SB' ...
        'BB_mean' 'BB' ...
        }, ...
        'savejagsoutput' , 1 , ...
        'verbosity' , 1 , ...
        'cleanup' , 0  );
    toc

    %% throw out first N samples
    N = 1;
    %'mu0_mean' 'mu0_sigma' 'mu0' ...
    stats.mean.SB = squeeze(mean(mean(samples.SB(:,N:end,:,:,:),2),1));
    stats.mean.BB = squeeze(mean(mean(samples.BB(:,N:end,:,:,:),2),1));
    stats.mean.AA = squeeze(mean(mean(samples.AA(:,N:end,:,:,:),2),1));

    %stats.mean.mu0 = squeeze(mean(mean(samples.mu0(:,N:end,:,:),2),1));
    stats.mean.alpha_start = squeeze(mean(mean(samples.alpha_start(:,N:end,:,:),2),1));
    stats.mean.alpha_inf = squeeze(mean(mean(samples.alpha_inf(:,N:end,:,:),2),1));
    stats.mean.alpha0= squeeze(mean(mean(samples.alpha0(:,N:end,:,:),2),1));
    stats.mean.alpha_d = squeeze(mean(mean(samples.alpha_d(:,N:end,:,:),2),1));
    
    %% Organize fits
    fits = struct();
    for si = 1:length({sub.subjectID})
        fits(si).id = {sub(si).subjectID};
        
        fits(si).info_bonus_h1 = stats.mean.AA(si, 2);
        fits(si).info_bonus_h6 = stats.mean.AA(si, 4);

        fits(si).dec_noise_h1_22 = stats.mean.BB(si, 1);
        fits(si).dec_noise_h1_13 = stats.mean.BB(si, 2);
        fits(si).dec_noise_h6_22 = stats.mean.BB(si, 3);
        fits(si).dec_noise_h6_13 = stats.mean.BB(si, 4);

        fits(si).alpha_start = stats.mean.alpha_start(si);
        fits(si).alpha_inf = stats.mean.alpha_inf(si);  

        %fits(si).mu0 = stats.mean.mu0(si); %R0 - prior over reward
    end
    
    fits = struct2table(fits);
end