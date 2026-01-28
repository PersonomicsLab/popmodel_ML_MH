function bootstrap_CCA(sublist_name,target,restdata,bootstrap_index)
debug = false;
rng(bootstrap_index)

% sublist = 'sub_list_small'
% target = 'x20127_0_0'
% restdata = 'resting_state_separate_proj'
% bootstrap_index = 1

% set paths
addpath(genpath('/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity/src_matlab'))

% Load data
sublist = table2array(readtable(sprintf('/scratch/janine.bijsterbosch/WAPIAW_2/subj_lists/%s.csv',sublist_name)));
D = readtable('/scratch/janine.bijsterbosch/WAPIAW_2/phenotypes/WAPIAW2_clean_appended_KH.tsv','FileType','text');
Drest = readNPY(sprintf('/scratch/janine.bijsterbosch/WAPIAW_2/imaging/%s.npy',restdata));



% Match subjects
[~, iD] = intersect(D.eid, sublist);
D = D(iD, :);
if target == 'x20127_0_0'
	target_pheno = [D.x1920_0_0, D.x1930_0_0, D.x1940_0_0, D.x1950_0_0, D.x1960_0_0, D.x1970_0_0, D.x1980_0_0, D.x1990_0_0, D.x2000_0_0, D.x2010_0_0, D.x2020_0_0, D.x2020_0_0];
elseif target == 'x20016_2_0'
	target_pheno = [D.x4935_2_0, D.x5699_2_0, D.x5779_2_0, D.x5790_2_0, D.x5866_2_0, D.x4946_2_0, D.x4957_2_0, D.x4968_2_0, D.x4979_2_0, D.x4990_2_0, D.x5001_2_0, D.x5012_2_0, D.x5556_2_0];
else
	error(['received unallowed target phenotype ID ' target])
end
rfMRI_data = Drest(iD, :);

% Remove NaNs
target_pheno_nanless = target_pheno(all(~isnan(target_pheno),2),:);
rfMRI_data_nanless = rfMRI_data(all(~isnan(target_pheno),2),:);

index = randperm(size(rfMRI_data_nanless, 1), floor(size(rfMRI_data_nanless, 1)*.9));
index_eid = D.eid(index);
clear D Drest iD

rdata = rfMRI_data_nanless(index, :); ndata = target_pheno_nanless(index,:);
for j = 1:size(ndata, 2)
    for k = 1:size(rdata,2)
        [~, ~, ~, stats] = ttest2(rdata(ndata(:,j) == 0,k), rdata(ndata(:,j) == 1,k));
        tstat(k,j) = stats.tstat;
    end
end
tstat_abs = abs(tstat);
tstat_all = sum(tstat_abs, 2);
[~, i] = sort(tstat_all(:),'descend');
top25 = i(1:floor(size(rfMRI_data_nanless, 2))*.25); %371
top25_rdata = rdata(:,top25);
[pfwer,r,A,B,U,V] = permcca(ndata, top25_rdata, 2000);

%%select significant
keep = pfwer < 0.05;
if ~any(keep)
	fake_keep=true;
	if debug
		disp("keep is empty! selecting 3 most significant components.")
		[~, pidx] = sort(pfwer);
		keep = pidx(1:3)
	else
		disp("keep is empty! exiting before further analysis is conducted.")
		exit
	end
else
	fake_keep=false;
	disp("dimensions of keep:")
	disp(size(keep))
	keep
end
U_keep = U(:,keep);
V_keep = V(:,keep);
UV_keep = [U_keep, V_keep];
disp(size(UV_keep))
%%select optimal number of clusters
disp("selecting optimal numbers of clusters..")
ka = zeros(1000,1);
for it = 1:1000
    ix = randi(size(UV_keep,1), [size(UV_keep,1),1]);
    data = UV_keep(ix,:);
    [~, ka(it)] = clusk(data, 10);
end
optimaln = mode(ka);
kms_its = kmeans(top25_rdata, optimaln);

% Saving out results
basedir = '/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity';
writematrix(index_eid, sprintf('%s/output/%s_%s_%s_%03d_index.csv',basedir,target,sublist_name,restdata,bootstrap_index))
writematrix(kms_its, sprintf('%s/output/%s_%s_%s_%03d_clusterassignment100.csv',basedir,target,sublist_name,restdata,bootstrap_index))
save(sprintf('%s/output/%s_%s_%s_%03d_outputs.mat',basedir,target,sublist_name,restdata,bootstrap_index),'ka','pfwer','r','A','B','U','V','top25','index','fake_keep');
