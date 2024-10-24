function [X, contamination] = r_decontX(X)
%Run decontX decontamination
%
% see also: run.r_SoupX
% https://cran.r-project.org/web/packages/SoupX/vignettes/pbmcTutorial.html

isdebug = false;
oldpth = pwd();
[isok, msg] = commoncheck_R('R_decontX');
if ~isok
    error(msg);
    X = [];
    contamination = [];
    return;
end

if isa(X, 'SingleCellExperiment')
    X = X.X;
end

tmpfilelist = {'input.mat', 'output.h5'};
if ~isdebug, pkg.i_deletefiles(tmpfilelist); end

save('input.mat', 'X', '-v7.3');
Rpath = getpref('scgeatoolbox', 'rexecutablepath');
pkg.RunRcode('script.R', Rpath);
if exist('./output.h5', 'file')
    X = h5read('output.h5', '/X');
    contamination = h5read('output.h5', '/contamination');
    % load('output.mat','X','contamination')
end

if ~isdebug, pkg.i_deletefiles(tmpfilelist); end
cd(oldpth);
end
