function [c]=run_garnett(X)
%Assigne cell type using Garnett/Monocle3 R package
%
% https://cole-trapnell-lab.github.io/garnett/docs_m3/#installing-garnett

if isempty(FindRpath)
    error('Rscript.exe is not found.');
end
oldpth=pwd;
pw1=fileparts(which(mfilename));
pth=fullfile(pw1,'thirdparty/R_Garnett');
cd(pth);
fprintf('CURRENTWDIR = "%s"\n',pth);

[~,cmdout]=RunRcode('require.R');
if strfind(cmdout,'there is no package')>0
    cd(oldpth);
    error(cmdout);
end
websave('mmBrain_20191017.RDS','https://cole-trapnell-lab.github.io/garnett/classifiers/mmBrain_20191017.RDS');
if exist('output.csv','file')
    delete('output.csv');
end
if issparse(X), X=full(X); end
csvwrite('input.csv',X);
% Rpath = 'C:\Program Files\R\R-3.6.0\bin';
% RscriptFileName = 'Z:\Cailab\mouse_neurons\adult_P10_cortex_SRR6061129\monocleMatlab.R';
% RunRcode('monocleMatlab_3d.R');
RunRcode('script.R');
if exist('output.csv','file')
    dat = csvread('output.csv',1,1);
    t=dat(:,1);
    s=dat(:,2:end);
else
    t=[];
    s=[];
end
if exist('input.csv','file')
    delete('input.csv');
end
if exist('output.csv','file')
    delete('output.csv');
end
cd(oldpth);



