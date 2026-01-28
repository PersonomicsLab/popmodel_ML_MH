%% load dependencies
addpath(genpath('/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity/src_matlab'))
basedir = '/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity';
sublist_name = 'sub_list';
target = 'x20016_2_0';  
restdata = 'resting_state_separate_proj';

disp(['base directory is ', basedir])
disp(['target = ', target])
disp(['imaging data = ', restdata])

%% goes through each file in the output directory to collect all the results in variables
Indexes = dir(sprintf('%s/output/%s_%s_%s_*_index.csv',basedir,target,sublist_name,restdata));
for i = 1:length(Indexes)
    Ii = str2num(Indexes(i).name(end-12:end-10));
    index_eid(:,i) = table2array(readtable(sprintf('%s/output/%s_%s_%s_%03d_index.csv',basedir,target,sublist_name,restdata,Ii)));
    kms_its(:,i) = table2array(readtable(sprintf('%s/output/%s_%s_%s_%03d_clusterassignment100.csv',basedir,target,sublist_name,restdata,Ii)));
    extra = load(sprintf('%s/output/%s_%s_%s_%03d_outputs.mat',basedir,target,sublist_name,restdata,Ii));
    ka(:,i) = extra.ka;
    top25(:,i) = extra.top25;
end

%% ARI for cluster assignements for all bootstraps
aaa = size(index_eid,2);
for i = 1:aaa
    for j = i+1:aaa
        [~, ia, ib] = intersect(index_eid(:,i), index_eid(:,j));
        ARI(i,j) = rand_index(kms_its(ia, i), kms_its(ib, j));
    end
end
ARI_avg = mean(ARI(find(~tril(ones(size(ARI))))));

dlmwrite(sprintf('%s/output/%s_%s_ARI_avg.csv',basedir,target,sublist_name), ARI_avg)

%% get cluster assignment for all subjects based on all bootstraps
%calculate optimal n
optimaln = mode(mode(ka)); 
dlmwrite(sprintf('%s/output/%s_%s_ka.csv',basedir,target,sublist_name), ka)
dlmwrite(sprintf('%s/output/%s_%s_optimaln.csv',basedir,target,sublist_name), optimaln)

%calculate best feature selection
top25_vec = top25(:);
[gc,grps] = groupcounts(top25_vec);
[~, ig] = sort(gc, 'descend');
grps = grps(ig);
topgrps = grps(1:371);
sublist = table2array(readtable(sprintf('/scratch/janine.bijsterbosch/WAPIAW_2/subj_lists/%s.csv',sublist_name)));
D = readtable('/scratch/janine.bijsterbosch/WAPIAW_2/phenotypes/WAPIAW2_clean_appended.tsv','FileType','text');
isempty(D)
Drest = readNPY(sprintf('/scratch/janine.bijsterbosch/WAPIAW_2/imaging/%s.npy',restdata));
isempty(Drest)
[~, iD, iS] = intersect(D.eid, sublist);
isempty(iD)
rfMRI_data = Drest(iD, topgrps);
sublist = sublist(iS);
isempty(rfMRI_data)
clear D Drest iD

%calculate the optimal cluster assignment
kms_its = kmeans(rfMRI_data, optimaln);
%apply this cluster assignemtn to subjlist to get clsuter subj list
k = max(unique(kms_its));
for i = 1:k
   cluster = sublist(kms_its == i);
   writematrix(cluster, sprintf('%s/subj_list/%s_%s_%s_cluster_%03d.csv',basedir,target,sublist_name,restdata,i))
end
