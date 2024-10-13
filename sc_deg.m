function [T, Tup, Tdn] = sc_deg(X, Y, genelist, methodid, guiwaitbar)
%SC_DEG - DEG analysis using Mann–Whitney U test or t-test
%
% Inputs:
%   X: matrix for group 1
%   Y: matrix for group 2
%   genelist: list of gene names (optional)
%   methodid: 1 for Mann–Whitney U test (default), 2 for t-test
%   guiwaitbar: true to show progress, false otherwise (default: false)
%
% Outputs:
%   T: table with DEG analysis results
%   Tup, Tdn: processed tables for up- and down-regulated genes
%
% https://satijalab.org/seurat/v3.1/de_vignette.html

arguments
    X (:,:) double           % Group 1 matrix (genes x cells)
    Y (:,:) double           % Group 2 matrix (genes x cells)
    genelist string = string(1:size(X, 1))'  % List of genes (optional)
    methodid (1,1) double {mustBeMember(methodid, [1, 2])} = 1  % Method choice (1: Mann–Whitney, 2: t-test)
    guiwaitbar (1,1) logical = false  % Show waitbar (optional)
end

ng = size(X, 1);  % Number of genes
assert(isequal(ng, size(Y, 1)), 'X and Y must have the same number of rows (genes)');

% Preallocate arrays for DEG analysis results
p_val = zeros(ng, 1);       % p-values (initialize to 0)
avg_log2FC = zeros(ng, 1);  % log fold-change (initialize to 0)
avg_1 = zeros(ng, 1);       % mean expression for group X
avg_2 = zeros(ng, 1);       % mean expression for group Y
pct_1 = zeros(ng, 1);       % percentage of cells expressing gene in group X
pct_2 = zeros(ng, 1);       % percentage of cells expressing gene in group Y
stats = zeros(ng, 1);       % statistical test statistic (ranksum or t-statistic)


nx = size(X, 2);  % Number of cells in group X
ny = size(Y, 2);  % Number of cells in group Y

% Normalize and log-transform the data
Z = log1p(sc_norm([X, Y]));
X = Z(:, 1:nx);
Y = Z(:, nx+1:end);

% Initialize waitbar if requested
if guiwaitbar
    fw = gui.gui_waitbar_adv;
end

% Loop through genes
for k = 1:ng
    if guiwaitbar
        gui.gui_waitbar_adv(fw, k / ng);
    end
    
    x = X(k, :);
    y = Y(k, :);
    
    % Perform statistical test based on methodid
    switch methodid
        case 1  % Mann–Whitney U test (Wilcoxon rank sum test)
            [px, ~, tx] = ranksum(x, y);
            p_val(k) = px;
            stats(k) = tx.ranksum;
        case 2  % Two-sample t-test
            [~, px, ~, tx] = ttest2(x, y);
            p_val(k) = px;
            stats(k) = tx.tstat;
    end
    
    % Compute average expression and log fold-change
    avg_1(k) = mean(x);
    avg_2(k) = mean(y);
    avg_log2FC(k) = log2(avg_1(k) / avg_2(k));
    
    % Calculate percentage of cells expressing the gene in both groups
    pct_1(k) = sum(x > 0) / nx;
    pct_2(k) = sum(y > 0) / ny;
end

% Adjust p-values for multiple comparisons
if exist('mafdr.m', 'file')
    p_val_adj = mafdr(p_val, 'BHFDR', true);
else
    [~, ~, ~, p_val_adj] = pkg.fdr_bh(p_val);
end

% Close waitbar if open
if guiwaitbar
    gui.gui_waitbar_adv(fw);
end

% Prepare gene names for output
if size(genelist, 2) > 1
    gene = genelist';
else
    gene = genelist;
end

% Create results table
abs_log2FC = abs(avg_log2FC);
T = table(gene, p_val, avg_log2FC, abs_log2FC, avg_1, avg_2, pct_1, pct_2, p_val_adj, stats);

% Process up- and down-regulated genes if requested
if nargout > 1
    [Tup, Tdn] = pkg.e_processDETable(T);
end

end

%{
function [T, Tup, Tdn] = sc_deg(X, Y, genelist, methodid, guiwaitbar)
%SC_DEG - DEG analysis using Mann–Whitney U test or t-test
% 
% Inputs:
%   X: matrix for group 1
%   Y: matrix for group 2
%   genelist: list of gene names (optional)
%   methodid: 1 for Mann–Whitney U test (default), 2 for t-test
%   guiwaitbar: true to show progress, false otherwise (default: false)
%
% Outputs:
%   T: table with DEG analysis results
%   Tup, Tdn: processed tables for up- and down-regulated genes
%
% https://satijalab.org/seurat/v3.1/de_vignette.html

% Default arguments
if nargin < 2
    error("USAGE: sc_deg(X, Y)\n");
end
if nargin < 3
    genelist = string(1:size(X, 1))'; 
end
if nargin < 4
    methodid = 1; 
end
if nargin < 5
    guiwaitbar = false; 
end

ng = size(X, 1);  % Number of genes
assert(isequal(ng, size(Y, 1)), 'X and Y must have the same number of rows (genes)');

% Initialize variables
p_val = ones(ng, 1);
avg_log2FC = ones(ng, 1);
avg_1 = zeros(ng, 1);
avg_2 = zeros(ng, 1);
pct_1 = ones(ng, 1);
pct_2 = ones(ng, 1);
stats = zeros(ng, 1);

nx = size(X, 2);  % Number of cells in group X
ny = size(Y, 2);  % Number of cells in group Y

% Normalize and log-transform the data
Z = log1p(sc_norm([X, Y]));
X = Z(:, 1:nx);
Y = Z(:, nx+1:end);

% Initialize waitbar if requested
if guiwaitbar
    fw = gui.gui_waitbar_adv;
end

% Loop through genes
for k = 1:ng
    if guiwaitbar
        gui.gui_waitbar_adv(fw, k / ng);
    end
    
    x = X(k, :);
    y = Y(k, :);
    
    % Perform statistical test based on methodid
    switch methodid
        case 1  % Mann–Whitney U test (Wilcoxon rank sum test)
            [px, ~, tx] = ranksum(x, y);
            p_val(k) = px;
            stats(k) = tx.ranksum;
        case 2  % Two-sample t-test
            [~, px, ~, tx] = ttest2(x, y);
            p_val(k) = px;
            stats(k) = tx.tstat;
        otherwise
            error('Unknown methodid option');
    end
    
    % Compute average expression and log fold-change
    avg_1(k) = mean(x);
    avg_2(k) = mean(y);
    avg_log2FC(k) = log2(avg_1(k) / avg_2(k));
    
    % Calculate percentage of cells expressing the gene in both groups
    pct_1(k) = sum(x > 0) / nx;
    pct_2(k) = sum(y > 0) / ny;
end

% Adjust p-values for multiple comparisons
if exist('mafdr.m', 'file')
    p_val_adj = mafdr(p_val, 'BHFDR', true);
else
    [~, ~, ~, p_val_adj] = pkg.fdr_bh(p_val);
end

% Close waitbar if open
if guiwaitbar
    gui.gui_waitbar_adv(fw);
end

% Prepare gene names for output
if size(genelist, 2) > 1
    gene = genelist';
else
    gene = genelist;
end

% Create results table
abs_log2FC = abs(avg_log2FC);
T = table(gene, p_val, avg_log2FC, abs_log2FC, avg_1, avg_2, pct_1, pct_2, p_val_adj, stats);

% Process up- and down-regulated genes if requested
if nargout > 1
    [Tup, Tdn] = pkg.e_processDETable(T);
end

end
%}