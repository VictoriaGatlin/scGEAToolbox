function callback_ShowClustersPop(src, ~)
answer = questdlg('Select a grouping variable and show cell groups in new figures individually?');
if ~strcmp(answer, 'Yes'), return; end

FigureHandle = src.Parent.Parent;
sce = guidata(FigureHandle);
[thisc, ~] = gui.i_select1class(sce);
if isempty(thisc), return; end
% [c, cL] = grp2idx(thisc);
[c, cL, noanswer, newidx] = gui.i_reordergroups(thisc);
if noanswer, return; end

fw = gui.gui_waitbar_adv;
    SCEV=cell(max(c),1);

    try
    for k=1:max(c)
        gui.gui_waitbar_adv(fw, ...
            (k-1)/max(c), ...
            sprintf('Processing %s ...', cL{k}));
        SCEV{k}=sce.selectcells(c==k);
    end
    catch ME
        gui.gui_waitbar_adv(fw);
        errordlg(ME.message);
        return;
    end
    %cLa=getappdata(FigureHandle,'cL');
    %if ~isempty(cLa) && length(cL)==length(cLa)
    %    cL=cLa;
    %end
    cmv = 1:max(c);
    idxx = cmv;
    [cmx] = countmember(cmv, c);

gui.gui_waitbar_adv(fw);

    answer = questdlg('Sort by size of cell groups?');
    if strcmpi(answer, 'Yes')
        [~, idxx] = sort(cmx, 'descend');
        SCEV=SCEV(idxx);
        %newidx=newidx(idxx);
    end

try
    sces = sce.s;
    h = findall(FigureHandle, 'type', 'scatter');
    if isempty(h.ZData)
        sces = sce.s(:, 1:2);
    end

    [para] = gui.i_getoldsettings(src);

    totaln = max(c);
    numfig = ceil(totaln/9);
    for nf = 1:numfig
        f = figure('visible', 'off');
        for k = 1:9
            kk = (nf - 1) * 9 + k;
            if kk <= totaln
                %subplot(3, 3, k);
                nexttile;
                gui.i_gscatter3(sces, c, 3, cmv(idxx(kk)));
                set(gca, 'XTick', []);
                set(gca, 'YTick', []);
                b = cL{idxx(kk)};
                title(strrep(b, '_', "\_"));
                a = sprintf('%d cells (%.2f%%)', ...
                    cmx(idxx(kk)), ...
                    100*cmx(idxx(kk))/length(c));
                fprintf('%s in %s\n', a, b);
                subtitle(a);
                %                 title(sprintf('%s\n%d cells (%.2f%%)', ...
                %                     cL{idxx(kk)}, cmx(idxx(kk)), ...
                %                     100 * cmx(idxx(kk)) / length(c)));
                box on
            end
            colormap(para.oldColorMap(newidx,:));
        end
        P = get(f, 'Position');
        set(f, 'Position', [P(1) - 20 * nf, P(2) - 20 * nf, P(3), P(4)]);
        set(f, 'visible', 'on');
        tb = uitoolbar(f);
        pkg.i_addbutton2fig(tb, 'off', {@gui.i_savemainfig, 3}, "powerpoint.gif", 'Save Figure to PowerPoint File...');
        if nf==1
            pkg.i_addbutton2fig(tb, 'off', @in_scgeatoolsce, "icon-mat-touch-app-10.gif", 'Extract and Work on Separate SCEs...');
        end
        drawnow;
    end
catch ME
    errordlg(ME.message);
end

    function in_scgeatoolsce(~,~)
        answer1 = questdlg('Extract cells from different groups and make new SCEs?');
        if ~strcmp(answer1, 'Yes'), return; end
        [idx] = in_selectcellgrps(cL(idxx));
        if isempty(idx), return; end 
           for ik=1:length(idx)
                scev=SCEV{idx(ik)};
                sc_scatter_sce(scev);
                pause(0.5);
            end
        end
end


function [idx] = in_selectcellgrps(grpv)
    idx=[];
    [indx2, tf2] = listdlg('PromptString', ...
    {'Select Group(s):'}, ...
    'SelectionMode', 'multiple', 'ListString', grpv, ...
    'InitialValue',1:length(grpv));
    if tf2 == 1
        idx = indx2;
    end
end
