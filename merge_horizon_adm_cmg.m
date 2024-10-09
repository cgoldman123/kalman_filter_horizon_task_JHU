function [all_data, subj_mapping] = merge_horizon_adm_cmg(record_ids)        
    dir_name = 'L:\NPC\DataSink\StimTool_Online\johns_hopkins_arch';
    directory = dir(dir_name);
    subj_mapping = struct();
    all_data = {};
    n = 0;
    for i = 1:length(directory)
        file_name = directory(i).name;
        tokens = regexp(file_name, 'horizon_(\d+)_', 'tokens');
        tokens_with_2104 = regexp(file_name, 'horizon_2104(\d+)_', 'tokens');
        tokens_with_2104_dash = regexp(file_name, 'horizon_2104-(\d+)_', 'tokens');
        if ~isempty(tokens)
            if ~isempty(tokens_with_2104_dash)
                file_record_id = str2double(tokens_with_2104_dash{1}{1});
            elseif ~isempty(tokens_with_2104)
                file_record_id = str2double(tokens_with_2104{1}{1});
            else
                file_record_id = str2double(tokens{1}{1});
            end
            if ismember(file_record_id, record_ids)
                full_file_name = fullfile(dir_name, file_name);
                data = parse_horizon_adm_cmg(full_file_name);  
                % Check if the file contains valid data
                %if (ismember(size(data, 1), 80) && (ismember(sum(data.gameLength), 600)))
                % make sure at least 40 trials present
                if (size(data,1)> 40)
                    n = n + 1;
                    % Append to subj_mapping table with index n and subject(1) from all_data
                    subj_mapping(n).n = n;
                    subj_mapping(n).id = data.subjectID(1,:);
                    % Add subjectID to the all_data
                    all_data{n} = data;
                    all_data{n}.subjectID = repmat(n, size(all_data{n}, 1), 1);
                end
            end
        end
    end
    
    
    all_data = vertcat(all_data{:});    
end


%% test

% mean differences of 4, 8, 12, 20, 30
% data.mean_diff = abs(data.m1 - data.m2);
% sum(data.mean_diff(1:40) == 4)
% sum(data.mean_diff(1:40) == 8)
% sum(data.mean_diff(1:40) == 12)
% sum(data.mean_diff(1:40) == 20)
% sum(data.mean_diff(1:40) == 30)
% sum(data.uc(1:40) == 2)
% sum(data.uc(1:40)==3 | data.uc(1:40)==1 )
% sum(data.gameLength(1:40)==10)


