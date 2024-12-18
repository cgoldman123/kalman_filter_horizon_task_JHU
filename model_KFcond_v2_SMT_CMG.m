function model_output = model_KFcond_v2_SMT_CMG(params, free_choices, rewards, mdp)
%     # This model has:
%     #   Kalman filter inference
%     #   Info bonus
% 
%     #   spatial bias is in this one and it can vary by 
% 
%     # no choice kernel
%     # inference is constant across horizon and uncertainty but can vary by 
%     # "condition".  Condition can be anything e.g. TMS or losses etc ...
%     
%     # two types of condition:
%     #   * inference fixed - e.g. horizon, uncertainty - C1, nC1
%     #   * inference varies - e.g. TMS, losses - C2, nC2
% 
%     # hyperpriors =========================================================
% 
%     # inference does not vary by condition 1, but can by condition 2
%     # note, always use j to refer to condition 2
    dbstop if error;
    G = mdp.G; % num of games
    T = mdp.T; % num of forced choices
    simmed_choices = nan(1,G);

    alpha_start = params.alpha_start;
    alpha_inf = params.alpha_inf;
    mu0 = 50; % initial value. can fix to 50
    info_bonuses = [params.info_bonus_h1 params.info_bonus_h6];       
    decision_noises = [params.dec_noise_h1_22 params.dec_noise_h1_13;
                       params.dec_noise_h6_22 params.dec_noise_h6_13];
    biases = [params.spatial_bias_h1_22 params.spatial_bias_h1_13;
              params.spatial_bias_h6_22 params.spatial_bias_h6_13];

    alpha0  = alpha_start / (1 - alpha_start) - alpha_inf^2 / (1 - alpha_inf);
    alpha_d = alpha_inf^2 / (1 - alpha_inf); 

    
    
    action_probs = nan(1,G);
    
    pred_errors = nan(T+1,G);
    pred_errors_alpha = nan(T+1,G);
    exp_vals = nan(T+1,G);
    alpha = nan(T+1,G);
    
    for g=1:G  % loop over games
        % values
        mu1 = [mu0 nan nan nan nan];
        mu2 = [mu0 nan nan nan nan];

        % learning rates 
        alpha1 = [alpha0 nan nan nan nan]; 
        alpha2 = [alpha0 nan nan nan nan]; 

        % information bonus, decision noise, and side bias for this game depend on 
        % the horizon. Decision noise additionally depends on
        % information condition
        if mdp.C1(g) == 1; horizon = 1; info = 1; end;
        if mdp.C1(g) == 2; horizon = 1; info = 2; end;
        if mdp.C1(g) == 3; horizon = 2; info = 1; end;
        if mdp.C1(g) == 4; horizon = 2; info = 2; end;

        A = info_bonuses(horizon);
        sigma_g = decision_noises(horizon, info);
        bias = biases(horizon, info);

        for t=1:T  % loop over forced-choice trials

            % if the first bandit was chosen
            if (mdp.forced_choices(t,g) == 1) 
                % update LR
                alpha1(t+1) = 1/( 1/(alpha1(t) + alpha_d) + 1 );
                alpha2(t+1) = 1/( 1/(alpha2(t) + alpha_d) );
                exp_vals(t,g) = mu1(t);
                pred_errors(t,g) = (rewards(t,g) - exp_vals(t,g));
                alpha(t,g) = alpha1(t+1);
                pred_errors_alpha(t,g) = alpha1(t+1) * pred_errors(t,g); % confirm that alpha here should be t+1
                mu1(t+1) = mu1(t) + pred_errors_alpha(t,g);
                mu2(t+1) = mu2(t); 
            else
                % update LR
                alpha1(t+1) = 1/( 1/(alpha1(t) + alpha_d) ); % why does first bandit LR change
                alpha2(t+1) = 1/( 1/(alpha2(t) + alpha_d) + 1 );
                exp_vals(t,g) = mu2(t);
                mu1(t+1) = mu1(t);
                pred_errors(t,g) = (rewards(t,g) - exp_vals(t,g));
                alpha(t,g) = alpha2(t+1);
                pred_errors_alpha(t,g) = alpha2(t+1) * pred_errors(t,g);
                mu1(t+1) = mu1(t);
                mu2(t+1) = mu2(t) + pred_errors_alpha(t,g);
            end
        end
        % get last expected value and prediction error
        % for the option that was chosen
        % if (free_choices(g) == 1) 
        %     alpha1(T+2) = 1/( 1/(alpha1(T+1) + alpha_d) + 1 );
        %     exp_vals(T+1,g) = mu1(T+1);
        %     pred_errors(T+1,g) = (rewards(T+1,g) - exp_vals(T+1,g));
        %     alpha(T+1,g) = alpha1(T+2);
        %     pred_errors_alpha(T+1,g) = alpha1(T+2) * pred_errors(T+1,g); % confirm that alpha here should be t+1
        % else
        %     alpha2(T+2) = 1/( 1/(alpha2(T+1) + alpha_d) + 1 );
        %     exp_vals(T+1,g) = mu2(T+1);
        %     pred_errors(T+1,g) = (rewards(T+1,g) - exp_vals(T+1,g));
        %     alpha(T+1,g) = alpha2(T+2);
        %     pred_errors_alpha(T+1,g) = alpha2(T+2) * pred_errors(T+1,g);
        % end

        % compute difference in values
       % dQ = mu2(T+1) - mu1(T+1) + A * mdp.right_info(g) + bias;
        % dQ = mu2(T+1) - mu1(T+1) + A * mdp.right_info(g);
        dQ = mu2(T+1) - mu1(T+1) + A * mdp.dI(g) + bias;

        % probability of choosing the right bandit
        p = 1 / (1 + exp(-dQ/(sigma_g)));

        action_probabilities = free_choices(g)*p + (1-free_choices(g))*(1-p);
        action_probs(g) = action_probabilities;

        % sample simulated choice
        u = rand(1,1);
        choice = u <= p;

        % c5 
        simmed_choices(g) = choice;


        
    end
    
    model_output.action_probs = action_probs;
    % model_output.exp_vals = exp_vals;
    % model_output.pred_errors = pred_errors;
    % model_output.pred_errors_alpha = pred_errors_alpha;
    % model_output.alpha = alpha;
    model_output.simmed_choices = simmed_choices;