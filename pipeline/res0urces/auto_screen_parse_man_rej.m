% sed -e "11 s|SUBJECTID|${Subject}|" \
%    "${RESOURCE}/auto_screen_parse_man_rej_TEMPLATE.m" \
%    > "${Subdir}/workspace/temp.m"
% load priors;

load(fullfile(resource_dir, 'Priors.mat'));
TemplateFC = Priors.FC;

% load .json file;
%json = loadjson([data_dir '/Tedana/desc-ICA_decomposition.json']);

% EDIT HERE:
json = readtable( ...
    fullfile(data_dir, 'Tedana', 'desc-tedana_metrics.tsv'), ...
    "FileType", "delimitedtext", ...
    'Delimiter', '\t');
% json = readtable("/project/oathes_analysis2/R61/J007/func/rest/session_1/run_1/Tedana/desc-tedana_metrics.tsv", "FileType", "delimitedtext", 'Delimiter', '\t');

%disp(json)
fn = fieldnames(json);
%idx = strfind(fn,'ica');
%idx = find(not(cellfun('isempty',idx))); % so, ignore it.
idx = height(json);


% preallocate;
acc = [];
accp = 'accepted'
% sweep all of
% the components;
for ii = 1:idx
    % log manual component classifications;
    %if strcmp(json.(fn{idx(ii)}).classification,'accepted')
    comp = char(json.classification(ii));
    accp = char(accp);
    comp = string(comp);
    accp = string(accp);
    if strcmp(comp, accp)
	acc = [acc ii-1]; % note: first component is 0; so i = 1 is i -1
    end
end

disp(acc)
% generate a list of all the images;
images = dir([data_dir '/Tedana/figures/*.png']);

% these are the ICs maps;
% JAG commented out 05/28/2024: IC = ft_read_cifti_mod([data_dir '/Tedana/desc-ICA_MNI6-res2.dtseries.nii']);
IC = ft_read_cifti([data_dir '/Tedana/desc-ICA_stat-z_components.dtseries.nii']);

% calculate spatial similarity
% between the  "noise" ICs and template networks;
%rho = corr((IC.dtseries(1:59412,acc+1)),TemplateFC);
rho = corr((IC.dtseries(1:59412,acc+1)),TemplateFC, 'rows', 'pairwise');

disp("RHO")
disp(rho)
% manually reject any components with r < 0.1
% spatial correlation with network templates;
ManRej = acc(max(abs(rho),[],2) < 0.1);

% sweep the manually
% accepted components;
for ii  = 1:length(ManRej)
    system(['cp ' data_dir '/Tedana/figures/' images(ManRej(ii)+1).name ' ' data_dir '/Tedana/figures/ManuallyRejected/']);
end

% read in all components manually identifed as noise;
tmp = dir([data_dir '/Tedana/figures/ManuallyRejected/*.png']);
man_rej = []; % preallocate

% sweep the components;
for i = 1:length(tmp)
    % component number;
    str = tmp(i).name;
    str = strsplit(str,{'_','.'});
    str = str{2};
    str = strip(str,'left','0');

    % this shouldnt happen,
    % but just in case...
    if isempty(str)
        str = '0';
    end

    % log manually rejected component;
    man_rej = [ man_rej str2double(str) ];

end

% read in all components manually identifed as signal;
tmp = dir([data_dir '/Tedana/figures/ManuallyAccepted/*.png']);
man_acc = []; % preallocate

% sweep the components;
for i = 1:length(tmp)

    % component number;
    str = tmp(i).name;
    str = strsplit(str,{'_','.'});
    str = str{2};
    str = strip(str,'left','0');

    % this shouldnt happen,
    % but just in case...
    if isempty(str)
        str = '0';
    end

    % log manually rejected component;
    man_acc = [ man_acc str2double(str) ];

end


% sweep all of
% the components;
for i = 1:idx

    % log manual component classifications;
    if ~ismember((i - 1),man_rej) && ~strcmp(json.classification(i),'rejected')
        man_acc = [man_acc i-1]; % note: first component is 0; so i = 1 is i -1
    end

end

% sort components;
man_acc = sort(man_acc);

% make second tedana directory;
system(['mkdir ' data_dir '/Tedana+ManualComponentClassification']);

% preallocate;
AcceptedComponents = [];

% sweep the components ;
for i = 1:length(man_acc)
    AcceptedComponents = [AcceptedComponents ' ' num2str(man_acc(i))];
end

% sort components;
man_rej = sort(man_rej);

% preallocate;
RejectedComponents = [];

% sweep the components ;
for i = 1:length(man_rej)
    RejectedComponents = [RejectedComponents ' ' num2str(man_rej(i))];
end

% write out the lists;
system(['echo -ne ' AcceptedComponents ' >> ' data_dir '/Tedana+ManualComponentClassification/AcceptedComponents.txt']);
system(['echo -ne ' RejectedComponents ' >> ' data_dir '/Tedana+ManualComponentClassification/RejectedComponents.txt']);

try

% read in components mapped to cortical surface;
% JAG commented out 05/28/2024: C = ft_read_cifti_mod([data_dir '/Tedana/desc-ICA_MNI6-res2.dtseries.nii']);
C = ft_read_cifti([data_dir '/Tedana/desc-ICA_stat-z_components.dtseries.nii']);

Ca = C; % these are the accepted components;
Ca.data = C.data(:,man_acc+1);

% write out the Ciftis;
ft_write_cifti([data_dir '/Tedana+ManualComponentClassification/desc-ICA_stat-z_components_from_script.dtseries.nii'],C);
ft_write_cifti([data_dir '/Tedana+ManualComponentClassification/desc-ICA_Accepted.dtseries.nii'],Ca);

C.data(:,man_acc+1) = []; % now, the rejected components;
ft_write_cifti([data_dir '/Tedana+ManualComponentClassification/desc-ICA_Rejected.dtseries.nii'],C);

catch
end
