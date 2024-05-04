function sc_uitabgrpfig_feaplot(feays, fealabels, sce_s, parentfig, cazcel)

if nargin < 5, cazcel = []; end
if nargin < 4, parentfig = []; end

if ~isstring(fealabels), fealabels=string(fealabels); end

if ismcc || isdeployed, makePPTCompilable(); end
import mlreportgen.ppt.*;

pw1 = fileparts(mfilename('fullpath'));
pth = fullfile(pw1, '..', 'resources', 'myTemplate.pptx');


hFig = figure("Visible","off", 'MenuBar','none', ...
    'DockControls', 'off', ...
    'ToolBar','figure');

% hFig.Position(3) = hFig.Position(3) * 1.8;

n = length(fealabels);
a = getpref('scgeatoolbox', 'prefcolormapname', 'autumn');

tabgp = uitabgroup();
tab = cell(n,1);
ax0 = cell(n,1);
ax = cell(n,2);

idx = 1;
focalg = fealabels(idx);

for k=1:n
    c = feays{k};
    if ~isnumeric(c)
        [c] = grp2idx(c);
    end
    if issparse(c), c = full(c); end
    tab{k} = uitab(tabgp, 'Title', sprintf('%s', fealabels(k)));
    
    
    ax0{k} = axes('parent',tab{k});
    %ax{k,1} = subplot(1,2,1);
    ax{k,1} = ax0{k};
    if size(sce_s,2)>2
        scatter3(sce_s(:,1), sce_s(:,2), sce_s(:,3), 5, c, 'filled');
    else
        scatter(sce_s(:,1), sce_s(:,2), 5, c, 'filled');
    end
    if ~isempty(cazcel)
        view(ax{k,1}, cazcel(1), cazcel(2));
    end

    % ax{k,2} = subplot(1,2,2);

    % scatter(sce_s(:,1), sce_s(:,2), 5, c, 'filled');
    % stem3(sce_s(:,1), sce_s(:,2), c, 'marker', 'none', 'color', 'm');
    % hold on;
    % scatter3(sce_s(:,1), sce_s(:,2), zeros(size(sce_s(:,2))), 5, c, 'filled');
    
    % title(ax{k,1}, strrep(fealabels(k),'_','\_'));
    % subtitle(ax{k,1}, gui.i_getsubtitle(c));
    % title(ax{k,2}, strrep(fealabels(k),'_','\_'));
    % subtitle(ax{k,2}, gui.i_getsubtitle(c));


    % gui.i_setautumncolor(c, a, true, any(c==0));
end
  
tabgp.SelectionChangedFcn=@displaySelection;

tb = findall(hFig, 'Tag', 'FigureToolBar'); % get the figure's toolbar handle
uipushtool(tb, 'Separator', 'off');

% b=allchild(tb0)
% tb = uitoolbar(hFig);
% copyobj(b(4),tb);
% delete(tb0);

% pkg.i_addbutton2fig(tb, 'off', [], "IMG00107.GIF", " ");
% pkg.i_addbutton2fig(tb, 'off', @i_linksubplots, 'plottypectl-rlocusplot.gif', 'Link subplots');
pkg.i_addbutton2fig(tb, 'off',  @i_genecards, 'fvtool_fdalinkbutton.gif', 'GeneCards...');
pkg.i_addbutton2fig(tb, 'on', {@i_PickColorMap, c}, 'plotpicker-compass.gif', 'Pick new color map...');
%pkg.i_addbutton2fig(tb, 'off', @i_RescaleExpr, 'IMG00074.GIF', 'Rescale expression level [log2(x+1)]');
%pkg.i_addbutton2fig(tb, 'off', @i_ResetExpr, 'plotpicker-geobubble2.gif', 'Reset expression level');
% pkg.i_addbutton2fig(tb, 'off', {@gui.i_savemainfig, 3}, "powerpoint.gif", 'Save Figure to PowerPoint File...');

pkg.i_addbutton2fig(tb, 'off', @in_savedata, "powerpointx.gif", 'Save Gene List...');
pkg.i_addbutton2fig(tb, 'off', @i_savemainfig, "powerpoint.gif", 'Save Figure to PowerPoint File...');
pkg.i_addbutton2fig(tb, 'off', @i_savemainfigx, "xpowerpoint.gif", 'Save Figure as Graphic File...');
pkg.i_addbutton2fig(tb, 'on', {@gui.i_resizewin, hFig}, 'HDF_pointx.gif', 'Resize Plot Window');

gui.i_movegui2parent(hFig, parentfig);


drawnow;
hFig.Visible=true;


    function in_savedata(~,~)
        gui.i_exporttable(table(fealabels), true, ...
            'Tmarkerlist','MarkerListTable');    
    end


    function i_savemainfigx(~,~)
        p = 1;
        % answer = questdlg('Select Sub-plot to export:','', ...
        %     'Left','Right','Cancel','Left');
        % switch answer
        %     case 'Left'
        %         p = 1;
        %     case 'Right'
        %         p = 2;
        %     otherwise
        %         return;
        % end

        [~,idx]=ismember(focalg, fealabels);     
        filter = {'*.jpg'; '*.png'; '*.tif'; '*.pdf'; '*.eps'};
        [filename, filepath] = uiputfile(filter,'Save Feature Plot', ...
            sprintf('FeaturePlot_%s', focalg));
        if ischar(filename)
            exportgraphics(ax{idx,p}, [filepath, filename]);
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
            gui.gui_waitbar_adv(fw,kx./n,"Processing "+fealabels(kx)+" ...");
            images{kx} = [tempname, '.png'];
            tabgp.SelectedTab=tab{kx};
            saveas(tab{kx},images{kx});
            slide3 = add(ppt, 'Small Title and Content');
            replace(slide3, 'Title', fealabels(kx));
            replace(slide3, 'Content', Picture(images{kx}));        
        end
            close(ppt);
            rptview(ppt);      
            gui.gui_waitbar_adv(fw);
    end

    % function i_linksubplots(~,~)        
    %     hlink = linkprop([ax{idx,1},ax{idx,2}],{'CameraPosition','CameraUpVector'});
    % end

    function displaySelection(~,event)
        t = event.NewValue;
        txt = t.Title;
        % disp("Viewing gene " + txt);
        [~,idx]=ismember(txt,fealabels);
        focalg = fealabels(idx);
    end

    function i_genecards(~, ~)
        web(sprintf('https://www.genecards.org/cgi-bin/carddisp.pl?gene=%s', focalg),'-new');
    end

end



    function i_PickColorMap(~, ~, c)
        list = {'parula', 'turbo', 'hsv', 'hot', 'cool', 'spring', ...
            'summer', 'autumn (default)', ...
            'winter', 'jet'};
        [indx, tf] = listdlg('ListString', list, 'SelectionMode', 'single', ...
            'PromptString', 'Select a colormap:', 'ListSize', [220, 300]);
        if tf == 1
            a = list{indx};
            if strcmp(a, 'autumn (default)')
                a = 'autumn';
            end
            gui.i_setautumncolor(c, a);
            setpref('scgeatoolbox', 'prefcolormapname', a);
        end
    end

