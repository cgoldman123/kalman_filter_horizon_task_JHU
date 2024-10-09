function final_table = parse_horizon_adm_cmg(file)

   final_table = fulltable(file);

end

function fintab = fulltable(file)
 data = readtable(file);
 
 columnHeaders = {
    'slides_thisRepN', 'slides_thisTrialN', 'slides_thisN', 'slides_thisIndex', 'slides_ran', ...
    'instruct_slide', 'audio_path', 'participant', 'session', 'run_id', 'date', ...
    'study', 'task_schedule', 'instruct_schedule', 'expName', 'psychopyVersion', ...
    'OS', 'frameRate', 'index', 'task', 'run', 'resp_keys', 'points', 'resp_rt', ...
    'example_trials_thisRepN', 'example_trials_thisTrialN', 'example_trials_thisN', ...
    'example_trials_thisIndex', 'example_trials_ran', 'game_number', 'game_type', ...
    'trial_num', 'mean_type', 'left_reward', 'right_reward', 'force_type', 'force_pos', ...
    'trials_thisRepN', 'trials_thisTrialN', 'trials_thisN', 'trials_thisIndex', 'trials_ran', ...
    'left_mean', 'right_mean'
};

% Assign the column headers to your table
if size(data, 2) ~= 44
    gameLength = zeros(1, 1);  % Initialize gameLength with 0
    fintab = table(gameLength);  % Create a table with gameLength
    return;  % Return from the function
end
data.Properties.VariableNames = columnHeaders;

 n_games = max(data.game_number) + 1;
    
fintab = cell(1, n_games);
% ge the string after horizon_ and before the third _
sub = regexp(file, '(?<=horizon_)[^_]+_[^_]+', 'match', 'once');
sub = strrep(sub, '2104-', ''); % Remove '2104-' if present
sub = strrep(sub, '2104', '');  % Remove '2104' if present
for game_i = 1:n_games
    row = table();

    row.expt_name = 'vertex';
    row.replication_flag = 0;
    row.subjectID = sub;
    row.order = 0;
    row.age = 22;
    row.gender = 0;
    row.sessionNumber = 0;

    game = data(data.game_number == game_i - 1 & isnan(data.example_trials_ran), :);

    row.game = game_i;
    row.gameLength = size(game, 1);
    row.uc = sum(strcmp(game.force_pos, 'R'));
    row.m1 = game.left_mean(1);
    row.m2 = game.right_mean(1);

    responses = table();
    choices = table();
    reaction_times = table();

    for t = 1:10   
        if t <= row.gameLength 
            choice = convertStringsToChars(game.resp_keys(t));

            choices.(sprintf('c%d', t)) = strcmp(choice, 'right') + 1;
            responses.(sprintf('r%d', t)) = game.([choice{1} '_reward'])(t);
            reaction_times.(sprintf('rt%d', t)) = game.resp_rt(t);
        else
            responses.(sprintf('r%d', t)) = nan;
            choices.(sprintf('c%d', t)) = nan;
            reaction_times.(sprintf('rt%d', t)) = nan;
        end
    end

    for t = 1:4
        reaction_times.(sprintf('rt%d', t)) = nan;
    end        

    fintab{game_i} = [row, responses, choices, reaction_times];
end

fintab = vertcat(fintab{:});
end