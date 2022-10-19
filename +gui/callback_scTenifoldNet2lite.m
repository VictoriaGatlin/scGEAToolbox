function callback_scTenifoldNet2lite(src,~)
    import ten.*
    import pkg.*

    FigureHandle=src.Parent.Parent;
    sce=guidata(FigureHandle);

    [i1,i2]=gui.i_select2grps(sce);
    if length(i1)==1 || length(i2)==1, return; end

    fw = gui.gui_waitbar;
    disp('Constructing networks (1/2) ...')    
    X=sc_norm(sce.X);
    X=log(X+1);
    X0=X(:,i1);
    X1=X(:,i2);    
    A0=sc_pcnetpar(X0);
    disp('Constructing networks (2/2) ...')
    A1=sc_pcnetpar(X1);    
    A0sym=0.5*(A0+A0');
    A1sym=0.5*(A1+A1');
    
    disp('Manifold alignment...')
    [aln0,aln1]=i_ma(A0sym,A1sym);
    disp('Differential regulation (DR) detection...')
    glist=sce.g;
    T=i_dr(aln0,aln1,glist);
    gui.gui_waitbar(fw);

    tstr=matlab.lang.makeValidName(string(datetime));
    save(sprintf('output_%s',tstr),'T');
    writetable(T,sprintf('output_%s.xlsx',tstr),'FileType','spreadsheet');
    fprintf('The result has been saved in output_%s.xlsx\n',tstr);

    %{
    figure;
    ten.e_mkqqplot(T);
    % answer223=questdlg('Run GSEA analysis?');
    answer223=gui.questdlg_timer(15,'Run GSEA analysis?');
    if ~isempty(answer223) && strcmp(answer223,'Yes')
        gseaok=true;
        try
            Tr=ten.e_fgsearun(T);
            save(sprintf('T_GSEAres_%s',tstr),'Tr');
        catch ME
            warning(ME.message);
            gseaok=false;
        end
        if gseaok
            answer323=gui.questdlg_timer(15,'Group GSEA hits?');
            if ~isempty(answer323) && strcmp(answer323,'Yes')
                ten.e_fgseanet(Tr);
            end
        end
    end
    gui.i_exporttable(T,true,'T_DRgenes');
    if gseaok
        gui.i_exporttable(Tr,true,'T_GSEAres');
    end
    %}

end