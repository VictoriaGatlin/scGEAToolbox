% Author: Modified package by Van Hoan Do
function label = LSC_eigen_fast(data,k,opts, Sigma)
% label = LSC(data,k,opts): Landmark-based Spectral Clustering
% Input:
%       - data: the data matrix of size nSmp x nFea, where each row is a sample
%               point
%       - k: the number of clusters
%       opts: options for this algorithm
%           - p: the number of landmarks picked (default 1000)
%           - r: the number of nearest landmarks for representation (default 5)
%           - numRep: the number of replicates for the final kmeans (default 10)
%           - maxIter: the maximum number of iterations for final kmeans (default 100)
%           - mode: landmark selection method, currently support
%               - 'kmeans': use centers of clusters generated by kmeans (default)
%               - 'random': use randomly sampled points from the original
%                           data set 
%           The following parameters are effective ONLY in mode 'kmeans'
%           - kmNumRep: the number of replicates for initial kmeans (default 1)
%           - kmMaxIter: the maximum number of iterations for initial kmeans (default 5)
% Output:
%       - label: the cluster assignment for each point
% Requre:
%       litekmeans.m
% Usage:
%       data = rand([100,50]);
%       label = LSC(data,10);

% select subsample
[m, n] = size(data);
baseCL = randperm(m);
n_samples = round(m/10);
cl = baseCL(1:n_samples);
unlabel_cl = baseCL(n_samples+1:m);
trainData = data(cl,:);

% Set and parse parameters
if (~exist('opts','var'))
   opts = [];
end

p = 1000;
if isfield(opts,'p')
    p = opts.p;
end
r = 5;
if isfield(opts,'r')
    r = opts.r;
end
maxIter = 100;
if isfield(opts,'maxIter')
    maxIter = opts.maxIter;
end
numRep = 10;
if isfield(opts,'numRep')
    numRep = opts.numRep;
end
mode = 'kmeans';
if isfield(opts,'mode')
    mode = opts.mode;
end

nSmp=size(trainData,1);

% Landmark selection
% fprintf('Landmark selection\n');
% tic;
if strcmp(mode,'kmeans')
    kmMaxIter = 5;
    if isfield(opts,'kmMaxIter')
        kmMaxIter = opts.kmMaxIter;
    end
    kmNumRep = 1;
    if isfield(opts,'kmNumRep')
        kmNumRep = opts.kmNumRep;
    end
    % [dump,marks]=litekmeans(data,p,'MaxIter',kmMaxIter,'Replicates',kmNumRep);
    % clear kmMaxIter kmNumRep
    marks = getRepresentativesByHybridSelection(trainData, p);
elseif strcmp(mode,'random')
    indSmp = randperm(nSmp);
    marks = trainData(indSmp(1:p),:);
    clear indSmp
else
    error('mode does not support!');
end
% toc;

% Z construction
% % tic;
D = EuDist2(trainData,marks,0);
% toc;
if isfield(opts,'sigma')
    sigma = Sigma;
else
    sigma = Sigma;
end
% fprintf('prepare features for SVD\n');
% tic;
dump = zeros(nSmp,r);
idx = dump;
for i = 1:r
    [dump(:,i),idx(:,i)] = min(D,[],2);
    temp = (idx(:,i)-1)*nSmp+[1:nSmp]';
    D(temp) = 1e100; 
end
% fprintf("sigma equals to mean of min distance\n");
% sigma = sigma*mean(mean(dump));
sigma = sigma*mean(max(dump'));
% fprintf('%.2f\t',sigma);
% dump = exp(-dump/(2*sigma^2)); TODO
dump = exp(-dump/(sigma));
sumD = sum(dump,2);
Gsdx = bsxfun(@rdivide,dump,sumD);
Gidx = repmat([1:nSmp]',1,r);
Gjdx = idx;
Z=sparse(Gidx(:),Gjdx(:),Gsdx(:),nSmp,p);

% Graph decomposition
feaSum = full(sqrt(sum(Z,1)));
feaSum = max(feaSum, 1e-12);
Z = Z./feaSum(ones(size(Z,1),1),:);
% toc;
% tic;
U = mySVD(Z,k+2);%TODO: use more than one eigenvectors, remove the first one too
U(:,1) = [];
% toc;
%U=U./repmat(sqrt(sum(U.^2,2)),1,k);

% Final kmeans
% tic;
% fprintf('Kmeans\n');
trainClass=litekmeans(U,k,'MaxIter',maxIter,'Replicates',numRep);
testData = data(unlabel_cl, :);
model = fitcknn(trainData,trainClass,'NumNeighbors', 5);
prediction = predict(model,testData);
ensemble = [trainClass; prediction];
ensemble = sortrows([baseCL' ensemble], [1]);
clear trainData testData;
label = ensemble(:,2);
% toc;


function RpFea = getRepresentativesByHybridSelection(fea, pSize, cntTimes)
    % Select $pSize$ representatives by hybrid selection.
    % First, randomly select $pSize * cntTimes$ candidate representatives.
    % Then, partition the candidates into $pSize$ clusters by k-means, and get
    % the $pSize$ cluster centers as the final representatives.
    if nargin < 3
        cntTimes = 10;
    end
    N = size(fea,1);
    bigPSize = cntTimes*pSize;
    if pSize>N
        pSize = N;
    end
    if bigPSize>N
        bigPSize = N;
    end
    rand('state',sum(100*clock)*rand(1));% 7.7009e+04
    bigRpFea = getRepresentivesByRandomSelection(fea, bigPSize);

    % [~, RpFea] = kmeans(bigRpFea,pSize,'MaxIter',20);
    [~, RpFea] = litekmeans(bigRpFea,pSize,'MaxIter',40);%orgin: MaxIter 40, no Replicates attribute

function [RpFea,selectIdxs] = getRepresentivesByRandomSelection(fea, pSize)
    % Randomly select pSize rows from fea.
    N = size(fea,1);
    if pSize>N
        pSize = N;
    end
    selectIdxs = randperm(N,pSize);
    RpFea = fea(selectIdxs,:);


