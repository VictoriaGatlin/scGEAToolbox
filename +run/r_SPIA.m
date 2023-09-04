function [t]=r_SPIA(T)

isdebug=false;
oldpth=pwd();
[isok,msg]=commoncheck_R('R_SPIA');
if ~isok, error(msg); end

gid=pkg.i_symbol2ncbiid(T.gene);
T=T(gid~=0,:);
gid=gid(gid~=0);
writematrix(string(gid),'input1.txt','QuoteStrings','all');

gid=gid(T.p_val_adj<0.01);
T=T(T.p_val_adj<0.01,:);
writematrix(string(gid),'input2.txt','QuoteStrings','all');
writematrix([T.avg_log2FC],'input3.txt');




% id = pkg.i_symbol2ncbiid

if issparse(X), X=full(X); end
if issparse(Y), Y=full(Y); end

avg_1 = mean(X,2);
avg_2 = mean(Y,2);
pct_1 = sum(X>0,2)./size(X,2);
pct_2 = sum(Y>0,2)./size(Y,2);

    %T = table(gene, p_val, avg_log2FC, abs_log2FC, avg_1, avg_2, ...
    %    pct_1, pct_2, p_val_adj);

tmpfilelist={'input.csv','output.csv'};
if ~isdebug, pkg.i_deletefiles(tmpfilelist); end

save('input.mat','X','Y','-v7.3');

Rpath=getpref('scgeatoolbox','rexecutablepath');
pkg.RunRcode('script.R',Rpath);

if ~exist('output.csv','file'), return; end
warning off
T=readtable('output.csv','TreatAsMissing','NA');
T.Var1=genelist(T.Var1);
T.Properties.VariableNames{'Var1'} = 'gene';
T.Properties.VariableNames{'log2FoldChange'} = 'avg_log2FC';
abs_log2FC=abs(T.avg_log2FC);
T = addvars(T,abs_log2FC,'After','avg_log2FC');

T = addvars(T,pct_2,'After','abs_log2FC');
T = addvars(T,pct_1,'After','abs_log2FC');
T = addvars(T,avg_2,'After','abs_log2FC');
T = addvars(T,avg_1,'After','abs_log2FC');

T=sortrows(T,'abs_log2FC','descend');
T=sortrows(T,'padj','ascend');
T.Properties.VariableNames{'padj'} = 'p_val_adj';
warning on
if ~isdebug, pkg.i_deletefiles(tmpfilelist); end
cd(oldpth);
end
