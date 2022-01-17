function callback_SingleRCellType(src,~)
% ----
    FigureHandle=src.Parent.Parent;
    sce=guidata(FigureHandle);
    speciestag = gui.i_selectspecies;
    if isempty(speciestag), return; end
    cx=[];
    fw=gui.gui_waitbar;
    try
    cx=run.SingleR(sce.X,sce.g,speciestag);
    catch

        gui.gui_waitbar(fw);
        errordlg("SingleR runtime error.");
        retrun;
    end
    gui.gui_waitbar(fw);
    if ~isempty(cx) && length(cx)==sce.NumCells
        sce.c_cell_type_tx=cx;
        [c,~]=grp2idx(cx);
        sce.c=c;
        guidata(FigureHandle,sce);
    else
        errordlg("SingleR runtime error.");
    end
end
