%%%%%RUN ON 2500
sublist = table2array(readtable('/scratch/janine.bijsterbosch/WAPIAW_2/subj_lists/sub_list.csv'));

%%load data
addpath(genpath('/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity/src_matlab'))

D = readtable('/scratch/janine.bijsterbosch/WAPIAW_2/phenotypes/WAPIAW2_clean.tsv','FileType','text');
[~, iD] = intersect(D.eid, sublist);
D = D(iD, :);
Neuroticism_12 = [D.x1920_0_0, D.x1930_0_0, D.x1940_0_0, D.x1950_0_0, D.x1960_0_0, D.x1970_0_0, D.x1980_0_0, D.x1990_0_0, D.x2000_0_0, D.x2010_0_0, D.x2020_0_0, D.x2020_0_0];
D = readNPY('/scratch/janine.bijsterbosch/WAPIAW_2/imaging/resting_state_separate_proj.npy');
rfMRI_data = D(iD, :);

Neuroticism_12_nanless = Neuroticism_12(all(~isnan(Neuroticism_12),2),:);
rfMRI_data_nanless = rfMRI_data(all(~isnan(Neuroticism_12),2),:);


%% feature selection
% cross validation
for i=1:100
    index{i} = randperm(size(rfMRI_data_nanless, 1), floor(size(rfMRI_data_nanless, 1)*.9));
    rdata = rfMRI_data_nanless(index{i}, :); ndata = Neuroticism_12_nanless(index{i},:);
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
    U_keep = U(:,keep);
    V_keep = V(:,keep);
    UV_keep = [U_keep, V_keep];
    %%select optimal number of clusters
    for it = 1:1000
        ix = randi(length(UV_keep), [length(UV_keep),1]);
        data = UV_keep(ix,:);
        [~, ka{it}] = clusk(data, 10); 
    end
    optimaln{i} = mode(cell2mat(ka));
    kms_its{i} = kmeans(top25_rdata, optimaln);
end

dlmwrite('/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity/clusterassignment100.csv', kms_its)
dlmwrite('/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity/optimaln100.csv', optimaln)

%%
% addpath('/Users/kayla/Box Sync/ThesisLab_April2021')
 %%%ARI %%gotta find 
%      for i = 1:folds
%          for j = i+1:folds
%         ARI_val(i,j) = rand_index(total{i},total{j}, 'adjusted');
%          end  
%      end
% ARI_distM = mean(ARI_val(find(~tril(ones(size(ARI_val))))));

% dlmwrite('/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity/average_ARI.csv', ARI_distM)

%% functions
function [ARI_dist] = pairwise_ARI(list_of_iters,data_per_iter)

% list_of_iters = ix;
% data_per_iter = spc_TNM_boot;


n_iters = length(list_of_iters);

ARI_mtx = zeros(n_iters);

for n = 1:7
for i = 1:n_iters
	idx_1 = list_of_iters{i,n};
	data_1 = data_per_iter{i,n};

	for j = (i+1):n_iters
		idx_2 = list_of_iters{j,n};
		data_2 = data_per_iter{i,n};
		[idx_3, ia,ib] = intersect(idx_1,idx_2);
        %clusplot(data_3(ib), data_2(ib), 'K-means Bootstrap Iteration', group{n})

		ARI_val = rand_index(data_1(ia),data_2(ib), 'adjusted');
		ARI_mtx(i,j) = ARI_val;
	end
end

ARI_dist{n} = triu(ARI_mtx,1);
end
end

function [idx_kms, a] = clusk(Z, varargin)
for n = 1:varargin{1}
    kms(:,n) = kmeans(Z, n);
    kms_sil(:,n) = mean(silhouette(Z, kms(:,n)));
end
[~, a] = max(kms_sil);
idx_kms = kms(:,a);
end
