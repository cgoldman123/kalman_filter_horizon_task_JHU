% Horizon Model Free

clear all

% gather info for horizon_fit_adm_meth script to fit old model and get
% model free behavior

dbstop if error

if ispc
    root = 'L:/';
elseif ismac
    root = '/Volumes/labs/';
elseif isunix 
    root = '/media/labs/';
end

study = 'METH'; % ADM or METH
my_REDCap_URL = 'https://redcap.laureateinstitute.org/redcap/api/';
session = 0;
run = 2;
results_dir = './horizon';

    if strcmp(study,"ADM")
        datadir = [root 'rsmith/adm-common/data/raw'];
        my_REDCap_token = '4D0BC015CE4E2B3E0495D9EEC66A0B3D'; %token will need to change if you're not CAL
        REDCap_response = REDCap('init', 'url', my_REDCap_URL, 'token', my_REDCap_token);
        report_number = '7012';

        dashboard_report = REDCap('report', report_number);
        group_list = cell2table(dashboard_report, "VariableNames",["record_id" "redcap_event_name" "redcap_repeat_instrument" "redcap_repeat_instance" "gif_tx_group" ...
            "dshbrd_studyday1" "dshbrd_studyday2" "dshbrd_ld10stat" "dshbrd_ld20stat" "dshbrd_ld40stat" "dshbrd_ld60stat" "dshbrd_ld80stat" ...
            "dshbrd_hrznrun1stat" "dshbrd_hrznrun2stat" "dshbrd_planpracticestat" "dshbrd_plantskrun1stat" "dshbrd_plantskrun2stat" "dshbrd_planposttststat" "dshbrd_sex_birth" "dshbrd_age" ...
            "dshbrd_meds" "dshbrd_meds_1" "dshbrd_meds_2" "dshbrd_meds_3" "dshbrd_meds_4" "dshbrd_meds_5"]);
        completers = group_list.dshbrd_hrznrun2stat==1;
        group_list = group_list(completers,:);

        IGNORE = {'sub-AJ826'}; % Horizon data lost in the ether
        
    else 
        datadir = [root 'rsmith/adm-meth-pilot-common/data/raw'];
        my_REDCap_token = '2D59F067BE12A3F7216BB22DDEC7DB10'; %token will need to change if you're not CAL
        REDCap_response = REDCap('init', 'url', my_REDCap_URL, 'token', my_REDCap_token);
        report_number = '7006';

        dashboard_report = REDCap('report', report_number);
        group_list = cell2table(dashboard_report, "VariableNames",["record_id" "redcap_event_name" "dshbrd_sex_birth" "dshbrd_age"  ...
            "dshbrd_studydate" "dshbrd_ld10stat" "dshbrd_ld20stat" "dshbrd_ld40stat" "dshbrd_ld60stat" "dshbrd_ld80stat" ...
            "dshbrd_hrznrun1stat" "dshbrd_hrznrun2stat" "dshbrd_planpracticestat" "dshbrd_plantskrun1stat" "dshbrd_plantskrun2stat" "dshbrd_planposttststat"]);
        completers = group_list.dshbrd_hrznrun2stat==1;
        group_list = group_list(completers,:);

    end 

    subjects = dir([datadir '/sub-*']);
 
    tablesubs = struct2table(subjects); 
    tablesubs = extractAfter(tablesubs.name, 4);
    tablesubs = cell2table(tablesubs); 
    group_subs = ismember(tablesubs.tablesubs, group_list.record_id);

    subjects = subjects(group_subs, :);
    subjects = {subjects.name};


data = table;
for i=1:numel(subjects)
    
    subj = extractAfter(subjects{i},4);
    if subj == "AJ826"
        continue
    elseif subj == "BR795"
        continue
    else
        try
        data(i,:) = horizon_fit_adm(subj, session, run, study);
        catch
            continue
        end
    end
end


 writetable(data, [results_dir '/meth_mf_run-' num2str(run) '_' date '.csv'])
beep