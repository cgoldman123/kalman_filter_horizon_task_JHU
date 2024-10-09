%subject = getenv('SUBJECT');
%result = getenv('RESULT_DIR');
clear all
subject = 'BS637';
result = 'L:/rsmith/lab-members/clavalley/analysis/adm/horizon/trials';
% Trial by trial Horizon responses for ADM
directory = dir('L:/rsmith/adm-common/data/raw/');
idx = find(arrayfun(@(n) contains(directory(n).name, ['sub-' subject]),1:numel(directory)));

if isempty(idx)
    directory = dir('L:/rsmith/adm-meth-pilot-common/data/raw/');
    idx = find(arrayfun(@(n) contains(directory(n).name, ['sub-' subject]),1:numel(directory)));
end
folder = directory(idx).name;
for run = 1:2
    filepath = [directory(1).folder '/'                                ...
        folder                                               ...
        '/ses-t0/beh/'                                   ...
        folder                                              ...
        '_ses-t0_task-horizon_run-'                          ...
        num2str(run)                                         ...
        '_events.tsv'                                        ...
    ];

    tab = readtable(filepath, 'FileType', 'text');
    data = parse_table(tab, subject, run);

    for i = 1:size(data,2)
        choice(i) = data(i).key(5);
    end
    
    subtab(run).choice = array2table(choice);
end
final = vertcat(subtab.choice);

writetable(final, [result '/' subject '-trial_choices.csv'])