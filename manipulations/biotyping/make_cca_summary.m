function [outpath] = make_cca_summary(varpath_list, varargin)
outpath = '/scratch/janine.bijsterbosch/WAPIAW_2/heterogeneity/CCAsummFI.csv';
if nargin > 1
	outpath = varargin{1}
end

flist = readcell(varpath_list,'Delimiter',',');
n_cv = length(flist);

corrs_cell= cell(n_cv,1);
pfwer_cell= cell(n_cv,1);

for i=1:n_cv
	[corrs_cell{i},pfwer_cell{i}] = loadvars(flist{i});
end
corrs_mtx = cell2mat(corrs_cell);
pfwer_mtx = cell2mat(pfwer_cell);

corrs_sum = summarize(corrs_mtx);
pfwer_sum = summarize(pfwer_mtx);

writematrix([corrs_sum; pfwer_sum],outpath);
end

function [summ] = summarize(mtx)
summ = [mean(mtx,1); std(mtx,1)]
end


function [corrs,pfwer] = loadvars(varpath)
vars = load(varpath);
corrs = vars.r;
pfwer = vars.pfwer;
end
