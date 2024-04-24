function i_scattertabs(y, tabnamelist, thisx, xlabelv, parentfig)
%see also: gui.i_violinplot, gui.i_violintabs

%assignin('base',"y",y)
%assignin('base',"thisx",thisx)

if nargin<4, parentfig = []; end
tabnamelist = string(tabnamelist);

%[~, cLorder]=grp2idx(thisx);
xlabelv = strrep(xlabelv, '_', '\_');

fw = gui.gui_waitbar;
% isdescend = false;

% thisx = strrep(string(thisx), '_', '\_');
% colorit = true;


import mlreportgen.ppt.*;
pw1 = fileparts(mfilename('fullpath'));
pth = fullfile(pw1, '..', 'resources', 'myTemplate.pptx');

hFig = figure("Visible","off",'MenuBar','none', ...
    'ToolBar','figure', 'DockControls', 'off');
hFig.Position(3) = hFig.Position(3) * 1.8;

delete(findall(hFig, 'Tag', 'FigureToolBar'));

% if ~isempty(cx)
%     px = hFig.Position;
%     px_new = [cx(1)-px(3)/2 cx(2)-px(4)/2];
% else
%     px_new = [];
% end

n = length(tabnamelist);

tabgp = uitabgroup();

idx = 1;
focalg = tabnamelist(idx);
tab=cell(n,1);
ax0=cell(n,1);

OldTitle = cell(n,1);
for k=1:n
    tab{k} = uitab(tabgp, 'Title', sprintf('%s',tabnamelist(k)));
    ax0{k} = axes('parent',tab{k});
    scatter(ax0{k}, thisx(:), y{k}(:));
    xlabel(ax0{k}, xlabelv);
    ylabel(ax0{k}, strrep(tabnamelist(k), '_', '\_'));
    % pkg.i_violinplot(y{k}, thisx, true, cLorder);
    title(ax0{k}, strrep(tabnamelist(k), '_', '\_'));
    % subtitle(ax0{k}, gui.i_getsubtitle(c));
    % gui.i_setautumncolor(c, a, true, any(c==0));
end
  
tabgp.SelectionChangedFcn=@displaySelection;

% tb = findall(hFig, 'Tag', 'FigureToolBar'); % get the figure's toolbar handle
% uipushtool(tb, 'Separator', 'off');
tb = uitoolbar(hFig);
% pkg.i_addbutton2fig(tb, 'off',  @i_genecards, 'fvtool_fdalinkbutton.gif', 'GeneCards...');
% pkg.i_addbutton2fig(tb, 'on', {@i_PickColorMap, c}, 'plotpicker-compass.gif', 'Pick new color map...');

pkg.i_addbutton2fig(tb, 'off', @in_savedata, 'export.gif', 'Export data...');
pkg.i_addbutton2fig(tb, 'off', @in_testdata, 'icon-fa-stack-exchange-10.gif', 'ANOVA/T-test...');
% pkg.i_addbutton2fig(tb, 'off', @i_addsamplesize, "icon-mat-blur-linear-10.gif", 'Add Sample Size');
pkg.i_addbutton2fig(tb, 'off', @i_savemainfig, "powerpoint.gif", 'Save Figure to PowerPoint File...');
pkg.i_addbutton2fig(tb, 'off', @i_savemainfigx, "xpowerpoint.gif", 'Save Figure as Graphic File...');

%pkg.i_addbutton2fig(tb, 'off', @i_invertcolor, "plotpicker-pie.gif", 'Switch BW/Color');
%pkg.i_addbutton2fig(tb, 'off', @i_reordersamples, "plotpicker-errorbar.gif", 'Reorder Samples');

%pkg.i_addbutton2fig(tb, 'off', @i_selectsamples, "plotpicker-errorbarx.gif", 'Select Samples');
%pkg.i_addbutton2fig(tb, 'off', @i_sortbymean, "plotpicker-cra.gif", 'Sort Samples by Median');

pkg.i_addbutton2fig(tb, 'off', @gui.i_renametitle, "icon-mat-touch-app-10.gif", 'Change Plot Title');
%pkg.i_addbutton2fig(tb, 'on', @i_viewgenenames, 'HDF_point.gif', 'Show Gene Names');
pkg.i_addbutton2fig(tb, 'on', {@gui.i_resizewin, hFig}, 'HDF_pointx.gif', 'Resize Plot Window');

if ~(ismcc || isdeployed)
    if ~isempty(which('curveFitter'))
        pkg.i_addbutton2fig(tb, 'on', @in_curvefitter, 'HDF_pointxx.gif', 'Invoke curveFitter');
    end
end

gui.i_movegui2parent(hFig, parentfig);

% drawnow;
gui.gui_waitbar(fw);
hFig.Visible=true;


     function in_curvefitter(~, ~)
         if ~(ismcc || isdeployed)
            [~,tabidx]=ismember(focalg, tabnamelist);            
            thisy = y{tabidx};
            curveFitter(thisx(:), thisy(:));
         end
     end
         
    %     delete(ax0{idx});
    %     ax0{idx} = axes('parent',tab{idx});
    %     pkg.i_violinplot(y{idx}, thisx, colorit, cLorder);
    %     title(ax0{idx}, strrep(tabnamelist(idx), '_', '\_'));
    %     tabgp.SelectedTab=tab{idx};
    %     drawnow;
    %     if length(tab)==1, return; end
    %     answer = questdlg('Apply to other genes?','');
    %     if ~strcmp(answer,'Yes'), return; end
    %     i_updatealltab(idx);
    % end


    function i_savemainfigx(~,~)
        [~,idx]=ismember(focalg, tabnamelist);     
        filter = {'*.jpg'; '*.png'; '*.tif'; '*.pdf'; '*.eps'};
        [filename, filepath] = uiputfile(filter,'Save Violin Plot', ...
            sprintf('ViolinPlot_%s',focalg));
        if ischar(filename)
            exportgraphics(ax0{idx}, [filepath, filename]);
        end
    end

    function i_savemainfig(~,~)
        answer = questdlg('Export to PowerPoint?');
        if ~strcmp(answer,'Yes'), return; end

        fw=gui.gui_waitbar_adv;
            OUTppt = [tempname, '.pptx'];
            ppt = Presentation(OUTppt, pth);
            open(ppt);
            images=cell(n,1);
            warning off
        for kx=1:n
            gui.gui_waitbar_adv(fw,kx./n,"Processing "+tabnamelist(kx)+" ...");
            images{kx} = [tempname, '.png'];
            tabgp.SelectedTab=tab{kx};
            saveas(tab{kx},images{kx});
            slide3 = add(ppt, 'Small Title and Content');
            replace(slide3, 'Title', tabnamelist(kx));
            replace(slide3, 'Content', Picture(images{kx}));        
        end
            close(ppt);
            rptview(ppt);      
            gui.gui_waitbar_adv(fw);
    end

    function displaySelection(~,event)
        t = event.NewValue;
        txt = t.Title;
        % disp("Viewing gene " + txt);
        [~,idx]=ismember(txt,tabnamelist);
        focalg = tabnamelist(idx);
    end

    function in_testdata(~, ~)
        for tabidx=1:n
            tabgp.SelectedTab=tab{tabidx};
            thisax = ax0{tabidx};
            thisy = y{tabidx};
            %a = hFig.get("CurrentAxes");
            if isempty(OldTitle{tabidx})
                OldTitle{tabidx} = thisax.Title.String;
                if size(thisy, 2) ~= length(thisx)
                    thisy = thisy.';
                end
                % tbl = pkg.e_grptest(thisy, thisx);
                A  = fitlm(thisx(:), thisy(:));
                b = sprintf('Coeff. = %.2f; Adj. R^2 = %.2f; p-value = %.2e',...
                    A.Coefficients.Estimate(2), A.Rsquared.Adjusted, A.coefTest);
                % tbl = A.anova;
                % if ~isempty(tbl) && istable(tbl)
                %     b = sprintf('p_{anova} = %.2e', tbl.pValue);
                % else
                %         b='p_{anova} = N.A.';
                % end

                DM = [thisx(:), ones(size(thisx(:)))];
                B = DM \ thisy(:);
                y1 = DM * B;

                % p = polyfit(thisx(:), thisy(:), 2);
                % y_fit = polyval(p,thisx(:));

                hold(thisax,"on");
                [sortedx, idxx]=sort(thisx(:));
                plot(thisax, sortedx, y1(idxx), '-', 'LineWidth', 1);                
               % plot(thisax, sortedx, y_fit(idxx), '-','LineWidth', 1); 
                hold(thisax,"off");

                if iscell(OldTitle{tabidx})
                    newtitle = OldTitle{tabidx};
                else
                    newtitle = OldTitle(tabidx);
                end
                newtitle{2} = b;
                thisax.Title.String = newtitle;
            else
                thisax.Title.String = OldTitle{tabidx};
                OldTitle{tabidx} = [];
            end
        end
        [~,tabidx]=ismember(focalg, tabnamelist);
        tabgp.SelectedTab=tab{tabidx};
    end
        
    % function i_testdataone(~,~)
    %     [~,idx]=ismember(focalg, tabnamelist);
    %     %delete(ax0{idx});
    %     %ax0{idx} = axes('parent',tab{idx});
    %     tabgp.SelectedTab=tab{idx};
    %     a = ax0{idx};
    %     thisy = y{idx};
    %     %a = hFig.get("CurrentAxes");
    %     if isempty(OldTitle{idx})
    %         OldTitle{idx} = a.Title.String;
    %         if size(thisy, 2) ~= length(thisc)
    %             thisy = thisy.';
    %         end
    %         tbl = pkg.e_grptest(thisy, thisc);
    %         %h1=gca;
    %         %titre=string(h1.Title.String);
    % 
    %         %     a=sprintf('%s\n%s=%.2e; %s=%.2e', ...
    %         %         strrep(string(ttxt),'_','\_'), ...
    %         %         strrep(tbl.Properties.VariableNames{1},'_','\_'), ...
    %         %         tbl.(tbl.Properties.VariableNames{1}), ...
    %         %         strrep(tbl.Properties.VariableNames{2},'_','\_'), ...
    %         %         tbl.(tbl.Properties.VariableNames{2}));
    %         %     title(a);
    %         if ~isempty(tbl) && istable(tbl)
    %             b = sprintf('%s=%.2e; %s=%.2e', ...
    %                 tbl.Properties.VariableNames{1}, ...
    %                 tbl.(tbl.Properties.VariableNames{1}), ...
    %                 tbl.Properties.VariableNames{2}, ...
    %                 tbl.(tbl.Properties.VariableNames{2}));
    % 
    %             % b = sprintf('%s=%.2e; %s=%.2e', ...
    %             %     strrep(tbl.Properties.VariableNames{1}, '_', '_'), ...
    %             %     tbl.(tbl.Properties.VariableNames{1}), ...
    %             %     strrep(tbl.Properties.VariableNames{2}, '_', '\_'), ...
    %             %     tbl.(tbl.Properties.VariableNames{2}));
    %         else
    %             if length(unique(thisc)) == 2
    %                 b='p_{ttest}=N.A.; p_{wilcoxon}=N.A.';
    %             else
    %                 b='p_{anova}=N.A.; p_{kruskalwallis}=N.A.';
    %             end
    %         end
    % 
    %         if iscell(OldTitle{idx})
    %             newtitle = OldTitle{idx};
    %         else
    %             newtitle = OldTitle(idx);
    %         end
    %         newtitle{2} = b;
    %         a.Title.String = newtitle;
    %     else
    %         a.Title.String = OldTitle{idx};
    %         OldTitle{idx} = [];
    %     end
    % end

    % function i_savedata(~, ~)
    %     [~,idx]=ismember(focalg, tabnamelist);
    %     thisy = y{idx};
    % 
    %     T = table(thisy(:), thisc(:));
    %     T.Properties.VariableNames = {'ScoreLevel', 'GroupID'};
    %     %T=sortrows(T,'ScoreLevel','descend');
    %     %T=sortrows(T,'GroupID');
    %     gui.i_exporttable(T, true, 'Tviolindata','ViolinPlotTable');
    % end

    function in_savedata(~, ~)        
        T=table(thisx);
        T.Properties.VariableNames = matlab.lang.makeValidName({xlabelv});
        for tabidx=1:n            
            thisy = y{tabidx};
            t = table(thisy(:));            
            t.Properties.VariableNames = matlab.lang.makeValidName(tabnamelist(tabidx));
            T = [T, t];
        end        
        gui.i_exporttable(T, true, 'Tscatterdata','ScatterPlotTable');
    end
end
