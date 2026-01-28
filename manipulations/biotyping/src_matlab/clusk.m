function [idx_kms, a] = clusk(Z, varargin)
for n = 1:varargin{1}
    kms(:,n) = kmeans(Z, n);
    kms_sil(:,n) = mean(silhouette(Z, kms(:,n)));
end
[~, a] = max(kms_sil);
idx_kms = kms(:,a);
end