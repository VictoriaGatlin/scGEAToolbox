function [score]=sc_cellscore(X,genelist,tgsPos,tgsNeg,nbin,ctrl)
% Compute cell scores from a list of feature genes
%
% tgsPos - positive features (negative target marker genes)
% tgsNeg - negative features (negative target marker genes)

if nargin<6, ctrl=5; end
if nargin<5, nbin=25; end
if nargin<4 || isempty(tgsNeg)
    tgsNeg=["IL2","TNF"];
end
if nargin<3
    tgsPos=["CD44","LY6C","KLRG1","CTLA","ICOS","LAG3"];
end

%genelist=upper(genelist);
%tgsPos=upper(tgsPos);
%tgsNeg=upper(tgsNeg);

idx=matches(genelist, tgsPos, 'IgnoreCase',true);
if ~any(idx)
    score=NaN(size(X,2),1);
    warning('No feature genes found in GENELIST.');
    return;
end



% Normalizing data by default in Seurat = log1p(libsize * 1e4)
%X = log(((X./nansum(X)) * 1e4) + 1);
X=sc_norm(X);
%disp('Library-size normalization...done.')
X=log(X+1);
%disp('Log(x+1) transformation...done.')

rng default
% Initial stats
cluster_lenght = size(X, 1);
data_avg = mean(X, 2);
[~, I] = sort(data_avg);

% Sorting data
data_avg = data_avg(I);
gsorted = genelist(I);
Xsorted = X(I, :);

% Assigning bins by expression
assigned_bin = diag(zeros(cluster_lenght));
bin_size = cluster_lenght/nbin;
for i = 1:nbin
    bin_match = data_avg <= data_avg(round(bin_size * i));
    pos_avail = (assigned_bin == 0);
    assigned_bin(pos_avail & bin_match) = i;
end

% Selecting bins of same expression
idx=matches(gsorted, tgsPos,'IgnoreCase',true);
selected_bins = unique(assigned_bin(idx));
samebin_genes = gsorted(ismember(assigned_bin, selected_bins));
ctrl_use = [];
for i = 1:length(tgsPos)
    ctrl_use = [ctrl_use; ...
        randsample(samebin_genes, ctrl)];
end
ctrl_use = unique(ctrl_use);

% Averaging expression
ctrl_score = mean(Xsorted(matches(gsorted, ctrl_use,'IgnoreCase',true),:),1);
features_score = mean(Xsorted(idx,:),1);

% Scoring
score = transpose(features_score - ctrl_score);
end