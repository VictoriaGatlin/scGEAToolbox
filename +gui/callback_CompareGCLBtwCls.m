function callback_CompareGCLBtwCls(src,~)
    answer = questdlg('This function compares GCL of genes to show differences between cell groups. Continue?','');
    if ~strcmp(answer,'Yes'), return; end    

    FigureHandle=src.Parent.Parent;
    sce=guidata(FigureHandle);

    [thisc,clable]=gui.i_select1class(sce);
    if isempty(thisc), return; end
    n=length(unique(thisc));
    if n==1
        answer=questdlg("All cells are in the same group. Continue?","");
        switch answer
            case 'Yes'
            otherwise
                return;
        end
    end

%'Global Coordination Level (GCL) [PMID: 33139959]'
[c,cL]=grp2idx(thisc);

N=50;

t=zeros(N*n,1);
V=zeros(N*n,1);
for k=1:n
    fprintf('Working on %s: %s ... %d of %d\n',clable,cL{k},k,n);
    idx=(k-1)*N+1:k*N;
    [v]=run.GCL(sce.X(:,k==c),N);
    t(idx,:)=k;
    V(idx,:)=v;
end
y=V;
thisc=cL(t);
ttxt='GCL';
    gui.i_violinplot(y,thisc,ttxt);
