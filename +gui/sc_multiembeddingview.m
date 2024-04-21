function sc_multiembeddingview(sce, embeddingtags, parentfig)

if isempty(embeddingtags)
    embeddingtags = fieldnames(sce.struct_cell_embeddings);
end
    hFig = figure('Visible', 'off');
    hFig.Position(3) = hFig.Position(3) * 1.8;
    axesv = cell(length(embeddingtags),1);
    for k=1:length(embeddingtags)
        s = sce.struct_cell_embeddings.(embeddingtags{k});
        if size(s,2)>1 && size(s,1)==sce.NumCells
            axesv{k} = nexttile;
            gui.i_gscatter3(s, sce.c, 1, 1, axesv{k});
            title(axesv{k}, embeddingtags{k});
        end
    end

    gui.i_movegui2parent(hFig, parentfig);

    drawnow;
    hFig.Visible=true;
    evalin('base', 'linkprop(findobj(gcf,''type'',''axes''), {''CameraPosition'',''CameraUpVector''});');
    hBr = brush(hFig);
    hBr.ActionPostCallback = {@onBrushAction, axesv};

    tb = findall(hFig, 'Tag', 'FigureToolBar'); % get the figure's toolbar handle
    uipushtool(tb, 'Separator', 'off');
    %tb = uitoolbar(hFig);
    pkg.i_addbutton2fig(tb, 'on',  @in_showgeneexp, 'list.gif', 'Select a gene to show expression...');
    pkg.i_addbutton2fig(tb, 'off',  @in_showcellstate, 'list2.gif', 'Select a gene to show expression...');
    gui.gui_3dcamera(tb, 'AllCells');    
     
    function in_showcellstate(~, ~)
        [thisc, clabel] = gui.i_select1state(sce);
        if isempty(thisc), return; end
        [c] = grp2idx(thisc);
        for kx = 1:length(axesv)
           s = sce.struct_cell_embeddings.(embeddingtags{kx});
           gui.i_gscatter3(s, c, 1, 1, axesv{kx});
           title(axesv{kx}, string(embeddingtags{k})+" - "+string(clabel));
        end
    end

    function in_showgeneexp(~, ~)
        [gsorted] = gui.i_sortgenenames(sce);
        if isempty(gsorted), return; end
        [indx, tf] = listdlg('PromptString', 'Select a gene:', ...
            'SelectionMode', 'single', 'ListString', gsorted, 'ListSize', [220, 300]);
        if tf == 1
            c = full(sce.X(sce.g == gsorted(indx), :));
            for kx = 1:length(axesv)
               s = sce.struct_cell_embeddings.(embeddingtags{kx});
               gui.i_gscatter3(s, c, 1, 1, axesv{kx});
               title(axesv{kx}, string(embeddingtags{k})+" - "+string(gsorted(indx)));
            end
            a = getpref('scgeatoolbox', 'prefcolormapname', 'autumn');
            gui.i_setautumncolor(c, a, true, any(c==0));
        end
    end

    function onBrushAction(~, event, axv)
        for kx=1:length(axv)
            if isequal(event.Axes, axv{kx})
                idx = kx;
                continue;
            end
        end
        d = axv{idx}.Children.BrushData;
        for kx=1:length(axv)
            if kx ~= idx
                axv{kx}.Children.BrushData = d;
            end
        end
    end

end    