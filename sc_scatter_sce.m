function varargout = sc_scatter_sce(sce, varargin)

if usejava('jvm') && ~feature('ShowFigureWindows')
    error('MATLAB is in a text mode. This function requires a GUI-mode.');
end
if nargin < 1
    % error('Usage: sc_scatter_sce(sce)');
    sc_scatter;
    return;
end
if ~isa(sce, 'SingleCellExperiment')
    error('requires sce=SingleCellExperiment();');
end

import pkg.*
import gui.*

p = inputParser;
checkCS = @(x) isempty(x) | size(sce.X, 2) == length(x);
addRequired(p, 'sce', @(x) isa(x, 'SingleCellExperiment'));
addOptional(p, 'c', sce.c, checkCS);
addOptional(p, 's', [], checkCS);
addOptional(p, 'methodid', 1, @isnumeric);
parse(p, sce, varargin{:});
cin = p.Results.c;
sin = p.Results.s;
methodid = p.Results.methodid;
ax = [];
bx = [];
tmpcelltypev=cell(sce.NumCells,1);

if isempty(cin)
    sce.c = ones(size(sce.X, 2), 1);
else
    sce.c = cin;
end
if ~isempty(sin)
    sce.s = sin;
end

[c, cL] = grp2idx(sce.c);

FigureHandle = figure('Name', 'SC_SCATTER', ...
    'position', round(1.5 * [0 0 560 420]), ...
    'visible', 'off');
movegui(FigureHandle, 'center');

set(findall(FigureHandle,'ToolTipString','Link/Unlink Plot'),'Visible','Off')
set(findall(FigureHandle,'ToolTipString','Edit Plot'),'Visible','Off')
set(findall(FigureHandle,'ToolTipString','Open Property Inspector'),'Visible','Off')


%a=findall(FigureHandle,'ToolTipString','New Figure');
%a.ClickedCallback = @__;


hAx = axes('Parent', FigureHandle);
[h] = gui.i_gscatter3(sce.s, c, methodid,1,hAx);
title(hAx,sce.title);

dt = datacursormode;
dt.UpdateFcn = {@i_myupdatefcnx};






defaultToolbar = findall(FigureHandle, 'tag','FigureToolBar');  % get the figure's toolbar handle
%defaultToolbar = findall(FigureHandle, 'Type', 'uitoolbar');

% UitoolbarHandle2 = uitoolbar( 'Parent', FigureHandle ) ;
% set( UitoolbarHandle2, 'Tag' , 'FigureToolBar2' , ...
%     'HandleVisibility' , 'on' , ...
%     'Visible' , 'on' ) ;

UitoolbarHandle = uitoolbar('Parent', FigureHandle);
set(UitoolbarHandle, 'Tag', 'FigureToolBar', ...
    'HandleVisibility', 'off', ...
    'Visible', 'on');

mfolder = fileparts(mfilename('fullpath'));

% UitoolbarHandle = uitoolbar(FigureHandle);
pt3 = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'list.gif'));
ptImage = ind2rgb(img, map);
pt3.CData = ptImage;
pt3.Tooltip = 'Select a gene to show expression';
pt3.ClickedCallback = @callback_ShowGeneExpr;

pt3a = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'list2.gif'));
ptImage = ind2rgb(img, map);
pt3a.CData = ptImage;
pt3a.Tooltip = 'Show cell states';
pt3a.ClickedCallback = @ShowCellStats;

pt3a = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-pointfig.gif'));
ptImage = ind2rgb(img, map);
pt3a.CData = ptImage;
pt3a.Tooltip = 'Select cells by class';
pt3a.ClickedCallback = @callback_SelectCellsByClass;

pt3a = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-effects.gif'));
ptImage = ind2rgb(img, map);
pt3a.CData = ptImage;
pt3a.Tooltip = 'Filter genes and cells';
pt3a.ClickedCallback = @SelectCellsByQC;

% ------------------

ptlabelclusters = uitoggletool(UitoolbarHandle, 'Separator', 'on');
[img, map] = imread(fullfile(matlabroot, ...
    'toolbox', 'matlab', 'icons', 'plotpicker-scatter.gif'));
% map(map(:,1)+map(:,2)+map(:,3)==3) = NaN;  % Convert white pixels => transparent background
ptImage = ind2rgb(img, map);
ptlabelclusters.CData = ptImage;
ptlabelclusters.Tooltip = 'Label clusters';
ptlabelclusters.ClickedCallback = @LabelClusters;

% ------------------ clustering

ptaddcluster = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-glyplot-face.gif'));
ptImage = ind2rgb(img, map);
ptaddcluster.CData = ptImage;
ptaddcluster.Tooltip = 'Add brushed cells to a new cluster';
ptaddcluster.ClickedCallback = @Brushed2NewCluster;

ptmergecluster = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-pzmap.gif'));
ptImage = ind2rgb(img, map);
ptmergecluster.CData = ptImage;
ptmergecluster.Tooltip = 'Merge brushed cells to same cluster';
ptmergecluster.ClickedCallback = @Brushed2MergeClusters;

ptShowClu = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-geoscatter.gif'));
ptImage = ind2rgb(img, map);
ptShowClu.CData = ptImage;
ptShowClu.Tooltip = 'Show clusters individually';
ptShowClu.ClickedCallback = @gui.callback_ShowClustersPop;

ptcluster = uipushtool(UitoolbarHandle, 'Separator', 'on');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-dendrogram.gif'));
ptImage = ind2rgb(img, map);
ptcluster.CData = ptImage;
ptcluster.Tooltip = 'Clustering using embedding S';
ptcluster.ClickedCallback = @ClusterCellsS;

ptcluster = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-gscatter.gif'));
ptImage = ind2rgb(img, map);
ptcluster.CData = ptImage;
ptcluster.Tooltip = 'Clustering using expression matrix X';
ptcluster.ClickedCallback = @ClusterCellsX;

% -------------

pt5 = uipushtool(UitoolbarHandle, 'Separator', 'on');
[img, map] = imread(fullfile(mfolder, 'resources', 'brush.gif'));
ptImage = ind2rgb(img, map);
pt5.CData = ptImage;
pt5.Tooltip = 'Cell types of brushed cells';
pt5.ClickedCallback = @Brush4Celltypes;

ptclustertype = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(matlabroot, ...
    'toolbox', 'matlab', 'icons', 'plotpicker-contour.gif'));
ptImage = ind2rgb(img, map);
ptclustertype.CData = ptImage;
ptclustertype.Tooltip = 'Cell types of clusters';
ptclustertype.ClickedCallback = @DetermineCellTypeClusters;

ptclustertype = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, 'resources', 'cellscore.gif'));
ptImage = ind2rgb(img, map);
ptclustertype.CData = ptImage;
ptclustertype.Tooltip = 'Calculate Cell Scores from Cell Type Markers';
ptclustertype.ClickedCallback = @callback_CellTypeMarkerScores;



pt4 = uipushtool(UitoolbarHandle, 'Separator', 'off');
% [img,map] = imread(fullfile(matlabroot,...
%             'toolbox','matlab','icons','plotpicker-stairs.gif'));
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-scatterhist.gif'));
ptImage = ind2rgb(img, map);
pt4.CData = ptImage;
pt4.Tooltip = 'Rename cell type';
pt4.ClickedCallback = @RenameCellType;

pt4 = uipushtool(UitoolbarHandle, 'Separator', 'off');
% [img,map] = imread(fullfile(matlabroot,...
%             'toolbox','matlab','icons','plotpicker-stairs.gif'));
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-kagi.gif'));
ptImage = ind2rgb(img, map);
pt4.CData = ptImage;
pt4.Tooltip = 'Marker genes of brushed cells';
pt4.ClickedCallback = @callback_Brush4Markers;

pt4mrkheat = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-plotmatrix.gif'));
ptImage = ind2rgb(img, map);
pt4mrkheat.CData = ptImage;
pt4mrkheat.Tooltip = 'Marker gene heatmap';
pt4mrkheat.ClickedCallback = @callback_MarkerGeneHeatmap;

ptclustertype = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, 'resources', 'cellscore2.gif'));
ptImage = ind2rgb(img, map);
ptclustertype.CData = ptImage;
ptclustertype.Tooltip = 'Calculate Cell Scores from List of Feature Genes';
ptclustertype.ClickedCallback = @callback_CalculateCellScores;

% --------------------------



ptpseudotime = uipushtool(defaultToolbar, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'IMG00107.GIF'));    % white space
ptImage = ind2rgb(img, map);
ptpseudotime.CData = ptImage;



ptpseudotime = uipushtool(defaultToolbar, 'Separator', 'on');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'IMG00074.GIF'));
ptImage = ind2rgb(img, map);
ptpseudotime.CData = ptImage;
ptpseudotime.Tooltip = 'Check R environment';
ptpseudotime.ClickedCallback = @gui.i_setrenv;

ptpseudotime = uipushtool(defaultToolbar, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'IMG00067.GIF'));
ptImage = ind2rgb(img, map);
ptpseudotime.CData = ptImage;
ptpseudotime.Tooltip = 'Run Seurat/R Workflow (R required)';
ptpseudotime.ClickedCallback = @RunSeuratWorkflow;



ptpseudotime = uipushtool(defaultToolbar, 'Separator', 'on');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-candle.gif'));
ptImage = ind2rgb(img, map);
ptpseudotime.CData = ptImage;
ptpseudotime.Tooltip = 'Compare Differentiation Potency';
ptpseudotime.ClickedCallback = @callback_ComparePotency;

ptpseudotime = uipushtool(defaultToolbar, 'Separator', 'on');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-arxtimeseries.gif'));
ptImage = ind2rgb(img, map);
ptpseudotime.CData = ptImage;
ptpseudotime.Tooltip = 'Run pseudotime analysis (Monocle)';
ptpseudotime.ClickedCallback = @callback_TrajectoryAnalysis;

ptpseudotime = uipushtool(defaultToolbar, ...
    'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-comet.gif'));
ptImage = ind2rgb(img, map);
ptpseudotime.CData = ptImage;
ptpseudotime.Tooltip = 'Plot pseudotime trajectory';
ptpseudotime.ClickedCallback = @DrawTrajectory;

ptpseudotime = uipushtool(defaultToolbar, 'Separator', 'on');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-priceandvol.gif'));
ptImage = ind2rgb(img, map);
ptpseudotime.CData = ptImage;
ptpseudotime.Tooltip = 'Compare Gene Expression between Classes';
ptpseudotime.ClickedCallback = @callback_CompareGeneBtwCls;

pt4 = uipushtool(defaultToolbar, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-boxplot.gif'));
ptImage = ind2rgb(img, map);
pt4.CData = ptImage;
pt4.Tooltip = 'Compare 2 groups (DE analysis)';
pt4.ClickedCallback = @callback_DEGene2Groups;

ptpseudotime = uipushtool(defaultToolbar, ...
    'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-andrewsplot.gif'));
ptImage = ind2rgb(img, map);
ptpseudotime.CData = ptImage;
ptpseudotime.Tooltip = 'Function enrichment of HVG genes';
ptpseudotime.ClickedCallback = @callback_GSEA_HVGs;

ptnetwork = uipushtool(defaultToolbar, ...
    'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'noun_Network_691907.gif'));
ptImage = ind2rgb(img, map);
ptnetwork.CData = ptImage;
ptnetwork.Tooltip = 'Build gene regulatory network';
ptnetwork.ClickedCallback = @callback_BuildGeneNetwork;

ptnetwork = uipushtool(defaultToolbar, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'noun_Deep_Learning_2424485.gif'));
ptImage = ind2rgb(img, map);
ptnetwork.CData = ptImage;
ptnetwork.Tooltip = 'Compare two scGRNs';
ptnetwork.ClickedCallback = @callback_CompareGeneNetwork;


ptpseudotime = uipushtool(defaultToolbar, 'Separator', 'on');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'IMG00107.GIF'));    % white space
ptImage = ind2rgb(img, map);
ptpseudotime.CData = ptImage;

ptnetwork = uipushtool(defaultToolbar, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'noun_Pruners_2469297.gif'));
ptImage = ind2rgb(img, map);
ptnetwork.CData = ptImage;
ptnetwork.Tooltip = 'Close All Other Figures';
ptnetwork.ClickedCallback = @callback_CloseAllOthers;


pt2 = uipushtool(UitoolbarHandle, 'Separator', 'on');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-qqplot.gif'));
ptImage = ind2rgb(img, map);
pt2.CData = ptImage;
pt2.Tooltip = 'Delete selected cells';
pt2.ClickedCallback = @DeleteSelectedCells;

pt = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, 'resources', 'export.gif'));
ptImage = ind2rgb(img, map);
pt.CData = ptImage;
pt.Tooltip = 'Export & save data';
pt.ClickedCallback = @callback_SaveX;

pt5 = uipushtool(UitoolbarHandle, 'Separator', 'on');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-geobubble.gif'));
ptImage = ind2rgb(img, map);
pt5.CData = ptImage;
pt5.Tooltip = 'Embedding';
pt5.ClickedCallback = @EmbeddingAgain;

% run(fullfile(mfolder,'+gui','add_toolbar.m'))
% pt5 = uipushtool(UitoolbarHandle, 'Separator', 'off');
% [img, map] = imread(fullfile(mfolder, ...
%     'resources', 'multiscale.gif'));
% ptImage = ind2rgb(img, map);
% pt5.CData = ptImage;
% pt5.Tooltip = 'Run Seurat/R Workflow (R required)';
% pt5.ClickedCallback = @RunSeuratWorkflow;

pt5 = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-image.gif'));      % plotpicker-pie
% map(map(:,1)+map(:,2)+map(:,3)==3) = NaN;     % Convert white pixels => transparent background
ptImage = ind2rgb(img, map);
pt5.CData = ptImage;
pt5.Tooltip = 'Switch 2D/3D';
pt5.ClickedCallback = @Switch2D3D;

pt5pickmk = uipushtool(UitoolbarHandle, 'Separator', 'on');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-rose.gif'));  % plotpicker-pie
ptImage = ind2rgb(img, map);
pt5pickmk.CData = ptImage;
pt5pickmk.Tooltip = 'Switch scatter plot marker type';
pt5pickmk.ClickedCallback = @callback_PickPlotMarker;

pt5pickcl = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-compass.gif'));  % plotpicker-pie
ptImage = ind2rgb(img, map);
pt5pickcl.CData = ptImage;
pt5pickcl.Tooltip = 'Switch color maps';
pt5pickcl.ClickedCallback = {@gui.callback_PickColorMap, ...
    numel(unique(c))};

pt5 = uipushtool(UitoolbarHandle, 'Separator', 'off');
[img, map] = imread(fullfile(mfolder, ...
    'resources', 'plotpicker-geobubble2.gif'));
ptImage = ind2rgb(img, map);
pt5.CData = ptImage;
pt5.Tooltip = 'Refresh';
pt5.ClickedCallback = @RefreshAll;

gui.add_3dcamera(defaultToolbar, 'AllCells');



m = uimenu(FigureHandle,'Text','E&xperimental');
m.Accelerator = 'x';
m2 = uimenu(m,'Text','sc&Tenifold Suite','Accelerator','T');
uimenu(m2,'Text','scTenifoldNet Construction 🐢🐢 ...',...
    'Callback',@callback_scTenifoldNet1);
uimenu(m2,'Text','scTenifoldNet Comparison 🐢🐢🐢 ...',...
    'Callback',@callback_scTenifoldNet2);
% uimenu(m2,'Text','---------------------------------------');
uimenu(m2,'Text','scTenifoldKnk (Virtual KO) Single Gene 🐢 ...',...
'Separator','on',...    
'Callback',@callback_scTenifoldKnk1);
% uimenu(m2,'Text','---------------------------------------');
uimenu(m2,'Text','scTenifoldKnk (Virtual KO) All Genes 🐢🐢🐢 ...',...
    'Callback',@callback_scTenifoldKnkN);

% uimenu(m2,'Text','scTenifoldKnk',...
%     'Callback',@callback_scTenifoldNet);
% uimenu(m2,'Text','scTenifoldXct',...
%     'Callback',@callback_scTenifoldNet);
% uimenu(m2,'Text','scTenifoldDev');

uimenu(m,'Text','Multi-embedding View...',...
    'Separator','on',...
    'Callback',@gui.callback_MultiEmbeddingViewer);
uimenu(m,'Text','Multi-grouping View...',...    
    'Callback',@gui.callback_MultiGroupingViewer);
uimenu(m,'Text','Cross Tabulation...',...
    'Callback',@callback_CrossTabulation);
uimenu(m,'Text','Detect Ambient RNA Contamination (decontX/R required)...',...
'Separator','on',...        
    'Callback',@DecontX);

uimenu(m,'Text','SingleR Cell Type Annotation (SingleR/R required)...',...
    'Callback',@callback_SingleRCellType);
uimenu(m,'Text','Revelio Cell Cycle Analysis (Revelio/R required)...',...
    'Callback',@callback_RevelioCellCycle);
uimenu(m,'Text','MELD Perturbation Score (MELD/Python required)...',...
    'Separator','on',...  
    'Callback',@callback_MELDPerturbationScore); 
uimenu(m,'Text','Batch Integration (Harmony/Python required)...',...
    'Callback',@HarmonyPy);
uimenu(m,'Text','Detect Doublets (Scrublet/Python required)...',...
    'Callback',@DoubletDetection);

uimenu(m,'Text','Ligand-Receptor Mediated Intercellular Crosstalk...',...
        'Separator','on',...
    'Callback',@callback_DetectCellularCrosstalk);
uimenu(m,'Text','Extract Cells by Marker(+/-) Expression...',...
    'Callback',@callback_SelectCellsByMarker);
uimenu(m,'Text','Merge Subclusters of Same Cell Type...',...
    'Callback',@MergeSubCellTypes);
uimenu(m,'Text','Calculate Gene Expression Statistics...',...
    'Callback',@callback_CalculateGeneStats);
%mm=uimenu(m,'Text','Calculate Cell Scores');
% uimenu(mm,'Text','Calculate Cell Scores from List of Feature Genes...',...
%     'Callback',@callback_CalculateCellScores);
uimenu(m,'Text','Library Size of Cell Cycle Phases...',...
    'Callback',@callback_CellCycleLibrarySize);
uimenu(m,'Text','T Cell Exhaustion Score...',...
    'Callback',@callback_TCellExhaustionScores);



uimenu(m,'Text','Import Data Using GEO Accession...',...
    'Separator','on',...
    'Callback',@GEOAccessionToSCE);
uimenu(m,'Text','Merge SCEs...',...    
    'Callback',@MergeSCEs);
% handles = guihandles( FigureHandle ) ;
% guidata( FigureHandle, handles ) ;
set(FigureHandle, 'visible', 'on');
guidata(FigureHandle, sce);

set(FigureHandle,'CloseRequestFcn',@closeRequest);

if nargout > 0
    varargout{1} = FigureHandle;
end

% ------------------------
% Callback Functions
% ------------------------

function closeRequest(hObject,~)
ButtonName = questdlg('Save SCE before closing SC_SCATTER?');
switch ButtonName
    case 'Yes'
        labels = {'Save SCE to variable named:'}; 
        vars = {'sce'};
        sce = guidata(FigureHandle);
        values = {sce};
        [~,tf]=export2wsdlg(labels,vars,values,...
                     'Save Data to Workspace');
        if tf
            delete(hObject);
        else
            return;
        end
    case 'Cancel'
        return;
    case 'No'
        delete(hObject);
    otherwise
        return;
end
end

    function GEOAccessionToSCE(src,~)
        acc=inputdlg({'GEO accession:'},'',[1 40],{'GSM3308545'});
        % [acc]=gui.i_inputgenelist(["GSM3308545","GSM3308546","GSM3308547"]);
        if ~isempty(acc)
        acc=acc{1};
        if strlength(acc)>4 && ~isempty(regexp(acc,'G.+','once'))
            try                
                fw=gui.gui_waitbar;                
                [sce]=sc_readgeoaccession(acc);
                [c,cL]=grp2idx(sce.c);
                gui.gui_waitbar(fw);                
                guidata(FigureHandle, sce);
                RefreshAll(src, 1, false, false);
            catch ME
                gui.gui_waitbar(fw);
                errordlg(ME.message);
            end
        end
        end
    end
    
    
    function MergeSCEs(src, ~)
        [requirerefresh,s]=gui.callback_MergeSCEs(src);        
        if requirerefresh
            sce = guidata(FigureHandle);
            [c, cL] = grp2idx(sce.c_batch_id);
            RefreshAll(src, 1, true);
            msgbox(sprintf('SCEs (%s) merged.',s));
        end
    end

    function SelectCellsByQC(src, ~)
        oldn=sce.NumCells;
        oldm=sce.NumGenes;
        [requirerefresh,highlightindex]=gui.callback_SelectCellsByQC(src);
        sce = guidata(FigureHandle);
        if requirerefresh            
            [c, cL] = grp2idx(sce.c);
            RefreshAll(src, 1, true);
            newn=sce.NumCells;
            newm=sce.NumGenes;
            msgbox(sprintf('%d cells removed; %d genes removed.',...
                oldn-newn,oldm-newm));
        end
        if ~isempty(highlightindex)
            h.BrushData=highlightindex;            
        end
    end

    function RunSeuratWorkflow(src,~)
       answer = questdlg('Run Seurat standard worflow?');
       if ~strcmp(answer, 'Yes'), return; end

       [ndim]=gui.i_choose2d3d;
       if isempty(ndim), return; end       
       
	   fw = gui.gui_waitbar;
       [sce]=run.SeuratWorkflow(sce,ndim);
       [c, cL] = grp2idx(sce.c);
	   gui.gui_waitbar(fw);
       RefreshAll(src, 1, true, false);
    end

    function DecontX(~,~)
        fw = gui.gui_waitbar;
        [Xdecon,contamination]=run.decontX(sce);
        gui.gui_waitbar(fw);
        figure;
        gui.i_stemscatter(sce.s,contamination);
        % zlim([0 1]);
        zlabel('Contamination rate')
        title('Ambient RNA contamination')
        answer=questdlg("Remove contamination?");
        switch answer
            case 'Yes'
                sce.X=round(Xdecon);
                guidata(FigureHandle,sce);
                helpdlg('Contamination removed.')
       end
    end


    function HarmonyPy(src, ~)
        if gui.callback_Harmonypy(src)
            sce = guidata(FigureHandle);
            [c, cL] = grp2idx(sce.c);
            RefreshAll(src, 1, true, false);
            ButtonName = questdlg('Update Saved Embedding?', ...
                '', ...
                'tSNE','UMAP','PHATE','tSNE');
            methodtag=lower(ButtonName);
            if ismember(methodtag,{'tsne','umap','phate'})
                sce.struct_cell_embeddings.(methodtag)=sce.s;
            end
        end
        guidata(FigureHandle, sce);
    end


    function DoubletDetection(src, ~)        
        [isDoublet,doubletscore,methodtag,done]=gui.callback_DoubletDetection(src);
        if done && ~any(isDoublet)
            helpdlg('No doublet detected.');
            return;
        end
        if done && any(isDoublet) && sce.NumCells==length(doubletscore)
            tmpf_doubletdetection=figure;
            gui.i_stemscatter(sce.s,doubletscore);
            zlabel('Doublet Score')
            title(sprintf('Doublet Detection (%s)',methodtag))
            answer=questdlg(sprintf("Remove %d doublets?",sum(isDoublet)));
                switch answer
                    case 'Yes'
                        close(tmpf_doubletdetection);
                        % i_deletecells(isDoublet);
                        sce = sce.removecells(isDoublet);
                        guidata(FigureHandle,sce);
                        [c, cL] = grp2idx(sce.c);
                        RefreshAll(src, 1, true, false);
                        helpdlg('Doublets deleted.');
                end
        end
    end        


    function MergeSubCellTypes(src,~)
        if isempty(sce.c_cell_type_tx), return; end
        % [sce]=pkg.i_mergeSubCellNames(sce);        
        newtx=erase(sce.c_cell_type_tx,"_{"+digitsPattern+"}");
        if isequal(sce.c_cell_type_tx,newtx)
            helpdlg("No sub-clusters are merged.");
        else
            sce.c_cell_type_tx=newtx;
            [c,cL]=grp2idx(sce.c_cell_type_tx);
            sce.c = c;
            RefreshAll(src, 1, true, false);
            i_labelclusters;
        end
        guidata(FigureHandle, sce);
    end

% =========================
    function RefreshAll(src, ~, keepview, keepcolr)
        if nargin < 4, keepcolr = false; end
        if nargin < 3, keepview = false; end        
        if keepview || keepcolr
            [para] = i_getoldsettings(src);
        end
        % [c, cL] = grp2idx(sce.c);
%         exist('h')
%         h
%         pause
        if size(sce.s, 2) > 2 && ~isempty(h.ZData)
            
            if keepview, [ax, bx] = view(); end
            h = gui.i_gscatter3(sce.s, c, methodid, hAx);
            if keepview, view(ax, bx); end
            
        else   % otherwise 2D
            h = gui.i_gscatter3(sce.s(:, 1:2), c, methodid, hAx);
        end
        if keepview
            h.Marker = para.oldMarker;
            h.SizeData = para.oldSizeData;
        end
        if keepcolr
            colormap(para.oldColorMap);
        else
            kc = numel(unique(c));
            if kc <= 50
                colormap(lines(kc));
            else
                colormap default;
            end
        end
        title(sce.title);
        pt5pickcl.ClickedCallback = {@callback_PickColorMap, ...
            numel(unique(c))};
        ptlabelclusters.State = 'off';
        % UitoolbarHandle.Visible='off';
        % UitoolbarHandle.Visible='on';
        guidata(FigureHandle, sce);
    end

    function Switch2D3D(src, ~)
        [para] = i_getoldsettings(src);
        if isempty(h.ZData)   % current 2 D
            if ~(size(sce.s, 2) > 2)
                helpdlg('Canno swith to 3-D. SCE.S is 2-D');
                return;
            end
            h = gui.i_gscatter3(sce.s, c, methodid, hAx);
            if ~isempty(ax) && ~isempty(bx) && ~any([ax bx] == 0)
                view(ax, bx);
            else
                view(3);
            end
        else                 % current 3D do following
            [ax, bx] = view();
            answer = questdlg('Which view to be used to project cells?', '', ...
                'X-Y Plane', 'Sreen/Camera', 'PCA-rotated', 'X-Y Plane');
            switch answer
                case 'X-Y Plane'
                    sx=sce.s;
                case 'Sreen/Camera'
                    sx = pkg.i_3d2d(sce.s, ax, bx);
                case {'PCA-rotated'}
                    [~,sx]=pca(sce.s);
                otherwise
                    return;
            end
            h = gui.i_gscatter3(sx(:, 1:2), c, methodid, hAx);
            sce.s=sx;
        end
        title(sce.title);
        h.Marker = para.oldMarker;
        h.SizeData = para.oldSizeData;
        colormap(para.oldColorMap);
    end

    function RenameCellType(~, ~)
        if isempty(sce.c_cell_type_tx)
            errordlg('sce.c_cell_type_tx undefined');
            return
        end
        answer = questdlg('Rename a cell type?');
        if ~strcmp(answer, 'Yes')
            return
        end
        [ci, cLi] = grp2idx(sce.c_cell_type_tx);
        [indxx, tfx] = listdlg('PromptString',...
            {'Select cell type'},...
            'SelectionMode', 'single',...
            'ListString', string(cLi));
        if tfx == 1
            i = ismember(ci, indxx);
            newctype = inputdlg('New cell type', 'Rename', [1 50], cLi(ci(i)));
            if ~isempty(newctype)
                cLi(ci(i)) = newctype;
                sce.c_cell_type_tx = cLi(ci);
                [c, cL] = grp2idx(sce.c_cell_type_tx);
                i_labelclusters(false);
            end
        end
        guidata(FigureHandle, sce);
    end

    function EmbeddingAgain(src, ~)
        answer = questdlg('Which embedding method?', 'Select method',...
                          'tSNE', 'UMAP', 'PHATE', 'tSNE');
        if ~ismember(answer, {'tSNE', 'UMAP', 'PHATE'})
            return
        end
        if isempty(sce.struct_cell_embeddings)
            sce.struct_cell_embeddings = struct('tsne', [], 'umap', [], 'phate', []);
        end
        methodtag = lower(answer);
        usingold = false;
        if ~isempty(sce.struct_cell_embeddings.(methodtag))
            answer1 = questdlg(sprintf('Use existing %s embedding or re-compute new embedding?', ...
                upper(methodtag)), '', ...
                'Use existing', 'Re-compute', 'Cancel', 'Use existing');
            switch answer1
                case 'Use existing'
                    sce.s = sce.struct_cell_embeddings.(methodtag);
                    usingold = true;
                case 'Re-compute'
                    usingold = false;
                case {'Cancel', ''}
                    return
            end
        end
        if ~usingold
            answer2 = questdlg(sprintf('Use highly variable genes (HVGs, n=2000) or use all genes (n=%d)?', sce.NumGenes), ...
                '', '2000 HVGs', 'All Genes', 'Cancel', '2000 HVGs');
            switch answer2
                case 'All Genes'
                    usehvgs = false;
                case '2000 HVGs'
                    usehvgs = true;
                case {'Cancel', ''}
                    return;
            end
            [ndim]=gui.i_choose2d3d;
            if isempty(ndim), return; end
            fw = gui.gui_waitbar;
            try
                forced = true;
                sce = sce.embedcells(methodtag, forced, usehvgs, ndim);
            catch ME
                gui.gui_waitbar(fw);
                errordlg(ME.message);
                return
            end
            gui.gui_waitbar(fw);
        end
        RefreshAll(src, 1, true, false);
        guidata(FigureHandle, sce);
    end

    function DetermineCellTypeClusters(src, ~)
        answer = questdlg('Assign cell types to clusters automatically?',...
            '','Yes, automatically','No, manually',...
            'Cancel','Yes, automatically');
        switch answer
            case 'Yes, automatically'
                manuallyselect=false;
            case 'No, manually'
                manuallyselect=true;
            otherwise
                return;
        end
        speciestag = gui.i_selectspecies;
        if isempty(speciestag), return; end        
        organtag = "all";
        databasetag = "panglaodb";
        dtp = findobj(h,'Type','datatip');
        delete(dtp);
        cLdisp = cL;
        if ~manuallyselect, fw=gui.gui_waitbar_adv; end
        for i = 1:max(c)
            gui.gui_waitbar_adv(fw,i/max(c));
            ptsSelected = c == i;
            [Tct] = pkg.local_celltypebrushed(sce.X, sce.g, ...
                sce.s, ptsSelected, ...
                speciestag, organtag, databasetag);
            if isempty(Tct)
                ctxt={'Unknown'};
            else
                ctxt = Tct.C1_Cell_Type;
            end
            
            if manuallyselect
                [indx, tf] = listdlg('PromptString', {'Select cell type'},...
                    'SelectionMode', 'single', 'ListString', ctxt);
                if tf == 1
                    ctxt = Tct.C1_Cell_Type{indx};
                else
                    return;
                end
            else
                ctxt = Tct.C1_Cell_Type{1};
            end
            
            hold on;
            ctxtdisp = strrep(ctxt, '_', '\_');
            ctxtdisp = sprintf('%s_{%d}', ctxtdisp, i);
            cLdisp{i} = ctxtdisp;
            
            ctxt = sprintf('%s_{%d}', ctxt, i);
            cL{i} = ctxt;
            
            row = dataTipTextRow('', cLdisp(c));
            h.DataTipTemplate.DataTipRows = row;
            if size(sce.s, 2) >= 2
                siv = sce.s(ptsSelected, :);
                si = mean(siv, 1);
                idx = find(ptsSelected);
                [k] = dsearchn(siv, si);
                datatip(h, 'DataIndex', idx(k));
                % text(si(:,1),si(:,2),si(:,3),sprintf('%s',ctxt),...
                %     'fontsize',10,'FontWeight','bold','BackgroundColor','w','EdgeColor','k');
                %     elseif size(sce.s,2)==2
                %             si=mean(sce.s(ptsSelected,:));
                %             text(si(:,1),si(:,2),sprintf('%s',ctxt),...
                %                  'fontsize',10,'FontWeight','bold','BackgroundColor','w','EdgeColor','k');
            end
            hold off;
        end
        if ~manuallyselect
            gui.gui_waitbar_adv(fw);
        end
        sce.c_cell_type_tx = string(cL(c));
        
        answer = questdlg('Merge subclusters of same cell type?');
        switch answer
            case 'Yes'
                MergeSubCellTypes(src);
            case 'No'
            otherwise                
        end
        guidata(FigureHandle, sce);
    end

    function Brushed2NewCluster(~, ~)
        answer = questdlg('Make a new cluster out of brushed cells?');
        if ~strcmp(answer, 'Yes')
            return
        end
        ptsSelected = logical(h.BrushData.');
        if ~any(ptsSelected)
            warndlg("No cells are selected.");
            return
        end
        c(ptsSelected) = max(c) + 1;
        [c, cL] = grp2idx(c);
        sce.c = c;
        [ax, bx] = view();
        [h] = gui.i_gscatter3(sce.s, c, methodid, hAx);
        title(sce.title);
        view(ax, bx);
        i_labelclusters(true);
        sce.c_cluster_id = c;
        guidata(FigureHandle, sce);
    end

    function Brushed2MergeClusters(~, ~)
        answer = questdlg('Merge brushed cells into one cluster?');
        if ~strcmp(answer, 'Yes')
            return
        end
        ptsSelected = logical(h.BrushData.');
        if ~any(ptsSelected)
            warndlg("No cells are brushed");
            return
        end
        c_members = unique(c(ptsSelected));
        if numel(c_members) == 1
            warndlg("All brushed cells are in one cluster");
            return
        else
            [indx, tf] = listdlg('PromptString',...
                {'Select target cluster'}, 'SelectionMode', 'single', 'ListString', string(c_members));
            if tf == 1
                c_target = c_members(indx);
            else
                return
            end
        end
        c(ismember(c, c_members)) = c_target;
        [c, cL] = grp2idx(c);
        sce.c = c;
        [ax, bx] = view();
        [h] = gui.i_gscatter3(sce.s, c, methodid, hAx);
        title(sce.title);
        view(ax, bx);
        i_labelclusters(true);
        sce.c_cluster_id = c;
        guidata(FigureHandle, sce);
    end

    function Brush4Celltypes(~, ~)
        answer = questdlg('Label cell type of brushed cells?');
        if ~strcmp(answer, 'Yes')
            return
        end
        ptsSelected = logical(h.BrushData.');
        if ~any(ptsSelected)
            warndlg("No cells are selected.");
            return
        end
        speciestag = gui.i_selectspecies;
        if isempty(speciestag), return; end  
        fw = gui.gui_waitbar;
        [Tct] = pkg.local_celltypebrushed(sce.X, sce.g, sce.s, ptsSelected, ...
            speciestag, "all", "panglaodb");
        ctxt = Tct.C1_Cell_Type;
        gui.gui_waitbar(fw);
        
        [indx, tf] = listdlg('PromptString',...
            {'Select cell type'}, 'SelectionMode', 'single', 'ListString', ctxt);
        if tf == 1
            ctxt = Tct.C1_Cell_Type{indx};
        else
            return;
        end
        ctxt = strrep(ctxt, '_', '\_');
        delete(findall(FigureHandle,'Type','hggroup'));
        if ~exist('tmpcelltypev','var')
            tmpcelltypev=cell(sce.NumCells,1);
        end
        siv=sce.s(ptsSelected, :);
        si=mean(sce.s(ptsSelected, :));
        [k] = dsearchn(siv, si);
        idx = find(ptsSelected);
        tmpcelltypev{idx(k)}=ctxt;
        row = dataTipTextRow('', tmpcelltypev);
        h.DataTipTemplate.DataTipRows = row;        
        datatip(h, 'DataIndex', idx(k));
        
        % return;
        %{
        hold on;
        if size(sce.s, 2) >= 3
            %scatter3(sce.s(ptsSelected, 1), sce.s(ptsSelected, 2),...
            %    sce.s(ptsSelected, 3), 'x');
            si = mean(sce.s(ptsSelected, :));
            text(si(:, 1), si(:, 2), si(:, 3), sprintf('%s', ctxt), ...
                'fontsize', 10, 'FontWeight', 'bold', 'BackgroundColor',...
                'w', 'EdgeColor', 'k');
        elseif size(sce.s, 2) == 2
            % scatter(sce.s(ptsSelected, 1), sce.s(ptsSelected, 2), 'x');
            si = mean(sce.s(ptsSelected, :));
            text(si(:, 1), si(:, 2), sprintf('%s', ctxt), ...
                'fontsize', 10, 'FontWeight', 'bold',...
                'BackgroundColor', 'w', 'EdgeColor', 'k');
        end
        hold off;
        %}
    end

    function ShowCellStats(src, ~)
        % FigureHandle=src.Parent.Parent;
        sce = guidata(FigureHandle);
        listitems = {'Library Size', 'Mt-reads Ratio', ...
            'Mt-genes Expression', 'HgB-genes Expression', ...
            'Cell Cycle Phase', ...
            'Cell Type', 'Cluster ID', 'Batch ID'};
        % if ~ismember('cell potency',sce.list_cell_attributes)
        %    listitems{end+1}='Cell Potency';
        % end
        %for k = 1:2:length(sce.list_cell_attributes)
        %    listitems = [listitems, sce.list_cell_attributes{k}];
        %end
        listitems=[listitems,...
            sce.list_cell_attributes(1:2:end)];
        [indx, tf] = listdlg('PromptString',...
            {'Select statistics'},...
            'SelectionMode', 'single', 'ListString', listitems);
        if tf ~= 1
            return
        end
        switch indx
            case 1
                ci = sum(sce.X);
                ttxt = "Library Size";
                figure;
                gui.i_stemscatter(sce.s,ci);
                zlabel(ttxt);                
                return;
            case 2
                fw = gui.gui_waitbar;
                i = startsWith(sce.g, 'mt-', 'IgnoreCase', true);
                lbsz = sum(sce.X, 1);
                lbsz_mt = sum(sce.X(i, :), 1);
                ci = lbsz_mt ./ lbsz;
                ttxt = "mtDNA%";
                gui.gui_waitbar(fw);
                figure;
                gui.i_stemscatter(sce.s,ci);
                zlabel(ttxt);
                title('Mt-reads Ratio');
                return;
            case 3
                idx = startsWith(sce.g, 'mt-', 'IgnoreCase', true);
                n = sum(idx);
                if n > 0
                    [ax, bx] = view();
                    if n <= 9
                        gui.i_markergenespanel(sce.X, sce.g, sce.s, ...
                            sce.g(idx), [], 9, ax, bx, 'Mt-genes');
                    else
                        gui.i_markergenespanel(sce.X, sce.g, sce.s, ...
                            sce.g(idx), [], 16, ax, bx, 'Mt-genes');
                    end
                else
                    warndlg('No mt-genes found');
                end
                return
            case 4 % HgB-genes
                idx1 = startsWith(sce.g, 'Hba-', 'IgnoreCase', true);
                idx2 = startsWith(sce.g, 'Hbb-', 'IgnoreCase', true);
                idx3= strcmpi(sce.g,"Alas2");
                idx=idx1|idx2|idx3;
                
                if any(idx)
                    ttxt = sprintf("%s+", sce.g(idx));
                    ci = sum(sce.X(idx, :), 1);
                    figure;
                    gui.i_stemscatter(sce.s,ci);
                    title(ttxt);
                else
                    warndlg('No HgB-genes found');
                end
                return;
            case 5   % "Cell Cycle Phase";
                if isempty(sce.c_cell_cycle_tx)                    
                    fw = gui.gui_waitbar;
                    sce = sce.estimatecellcycle(true,1);
                    gui.gui_waitbar(fw);
                end
                [ci, tx] = grp2idx(sce.c_cell_cycle_tx);
                ttxt = sprintf('%s|', string(tx));
            case 6 % cell type
                ci = sce.c_cell_type_tx;
            case 7 % cluster id
                ci = sce.c_cluster_id;
            case 8 % batch id
                ci = sce.c_batch_id;
            otherwise   % other properties
                ttxt = sce.list_cell_attributes{2 * (indx - 8) - 1};
                ci = sce.list_cell_attributes{2 * (indx - 8)};
        end
        if isempty(ci)
            errordlg("Undefined classification");
            return;
        end
        [c,cL]=grp2idx(ci);
        RefreshAll(src, 1, true, false);
        guidata(FigureHandle, sce);
    end

%         sces = sce.s;
%         if isempty(h.ZData)
%             sces = sce.s(:, 1:2);
%         end        
%         [ax, bx] = view();
%         h = gui.i_gscatter3(sces, ci, 1);
%         view(ax, bx);
%         title(sce.title);
        
% -------- move to i_showstate



%     function i_showstate(ci)
%         if isempty(ci)
%             errordlg("Undefined classification");
%             return
%         end
%         sces = sce.s;
%         if isempty(h.ZData)
%             sces = sce.s(:, 1:2);
%         end        
%         [ax, bx] = view();
%         h = gui.i_gscatter3(sces, ci, 1);
%         view(ax, bx);
%         title(sce.title);        
%     end

    function DeleteSelectedCells(~, ~)
        ptsSelected = logical(h.BrushData.');
        if ~any(ptsSelected)
            warndlg("No cells are selected.");
            return
        end
        answer = questdlg('Delete cells?', '', ...
            'Selected', 'Unselected', 'Cancel', 'Selected');
        if strcmp(answer, 'Unselected')            
            i_deletecells(~ptsSelected);
        elseif strcmp(answer, 'Selected')            
            i_deletecells(ptsSelected);
        else
            return;
        end
%         answer2 = questdlg(sprintf('Delete %s cells?', ...
%             lower(answer)));
%         if ~strcmp(answer2, 'Yes')
%             return
%         end
%        i_deletecells(ptsSelected);
        guidata(FigureHandle,sce);
    end

    function i_deletecells(ptsSelected)
        sce = sce.removecells(ptsSelected);
        [c, cL] = grp2idx(sce.c);
        [ax, bx] = view();
        h = gui.i_gscatter3(sce.s, c);
        title(sce.title);
        view(ax, bx);
    end

    function DrawTrajectory(~, ~)
        answer = questdlg('Which method?', 'Select Algorithm', ...
            'splinefit (🐇)', 'princurve (🐢)', ...
            'splinefit (🐇)');
        if strcmp(answer, 'splinefit (🐇)')
            dim = 1;
            [t, xyz1] = i_pseudotime_by_splinefit(sce.s, dim, false);
        elseif strcmp(answer, 'princurve (🐢)')
            [t, xyz1] = i_pseudotime_by_princurve(sce.s, false);
        else
            errordlg('Invalid Option.');
            return;
        end
        hold on;
        if size(xyz1, 2) >= 3
            plot3(xyz1(:, 1), xyz1(:, 2), xyz1(:, 3), '-r', 'linewidth', 2);
            text(xyz1(1, 1), xyz1(1, 2), xyz1(1, 3), 'Start', ...
                'fontsize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k');
            text(xyz1(end, 1), xyz1(end, 2), xyz1(end, 3), 'End', ...
                'fontsize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k');
        elseif size(xyz1, 2) == 2
            plot(xyz1(:, 1), xyz1(:, 2), '-r', 'linewidth', 2);
            text(xyz1(1, 1), xyz1(1, 2), 'Start', ...
                'fontsize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k');
            text(xyz1(end, 1), xyz1(end, 2), 'End', ...
                'fontsize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k');
        end
        hold off;
        
        answerx = questdlg('Save/Update pseudotime T in SCE', ...
            'Save Pseudotime', ...
            'Yes', 'No', 'Yes');
        switch answerx
            case 'Yes'
                tag = sprintf('%s pseudotime', answer);
                % iscellstr(sce.list_cell_attributes(1:2:end))
                i = find(contains(sce.list_cell_attributes(1:2:end), tag));
                if ~isempty(i)
                    sce.list_cell_attributes{i + 1} = t;
                    fprintf('%s is updated.\n', tag);
                else
                    sce.list_cell_attributes{end + 1} = tag;
                    sce.list_cell_attributes{end + 1} = t;
                    fprintf('%s is saved.\n', tag);
                end
                guidata(FigureHandle, sce);
        end
        answer = questdlg('View expression of selected genes', ...
            'Pseudotime Function', ...
            'Yes', 'No', 'Yes');
        switch answer
            case 'Yes'
                r = corr(t, sce.X.', 'type', 'spearman'); % Calculate linear correlation between gene expression profile and T
                [~, idxp] = maxk(r, 4);  % Select top 4 positively correlated genes
                [~, idxn] = mink(r, 3);  % Select top 3 negatively correlated genes
                selectedg = sce.g([idxp idxn]);
                figure;
                i_plot_pseudotimeseries(log2(sce.X + 1), ...
                    sce.g, t, selectedg);
            case 'No'
                return
        end
        
    end

%     function RunTrajectoryAnalysis(~, ~)
%         answer = questdlg('Run pseudotime analysis (Monocle)?');
%         if ~strcmp(answer, 'Yes')
%             return
%         end
%         
%         fw = gui.gui_waitbar;
%         [t_mono, s_mono] = run.monocle(sce.X);
%         gui.gui_waitbar(fw);
%         
%         answer = questdlg('View Monocle DDRTree?', ...
%             'Pseudotime View', ...
%             'Yes', 'No', 'Yes');
%         switch answer
%             case 'Yes'
%                 [ax, bx] = view();
%                 cla(hAx);
%                 sce.s = s_mono;
%                 sce.c = t_mono;
%                 [c, cL] = grp2idx(sce.c);
%                 h = gui.i_gscatter3(sce.s, c);
%                 title(sce.title);
%                 view(ax, bx);
%                 hc = colorbar;
%                 hc.Label.String = 'Pseudotime';
%         end
%         
%         labels = {'Save pseudotime T to variable named:', ...
%             'Save S to variable named:'};
%         vars = {'t_mono', 's_mono'};
%         values = {t_mono, s_mono};
%         export2wsdlg(labels, vars, values);
%     end

    function ClusterCellsS(src, ~)
        answer = questdlg('Cluster cells?');
        if ~strcmp(answer, 'Yes')
            return
        end
        
        answer = questdlg('Which method?', 'Select Algorithm', ...
            'kmeans 🐇', 'snndpc 🐢', 'kmeans 🐇');
        if strcmpi(answer, 'kmeans 🐇')
            methodtag = "kmeans";
        elseif strcmpi(answer, 'snndpc 🐢')
            methodtag = "snndpc";
        else
            return
        end
        i_reclustercells(src, methodtag);
        guidata(FigureHandle, sce);
    end

%     function k = i_inputk
%         prompt = {'Enter number of clusters K=(2..50):'};
%         dlgtitle = 'Input K';
%         dims = [1 45];
%         definput = {'10'};
%         answer = inputdlg(prompt, dlgtitle, dims, definput);
%         if isempty(answer)
%             k=[];
%             return
%         end
%         k = round(str2double(cell2mat(answer)));
%     end

    function ClusterCellsX(src, ~)
        answer = questdlg('Cluster cells using X?');
        if ~strcmp(answer, 'Yes')
            return
        end
        methodtagvx = {'specter (31 secs) 🐇','sc3 (77 secs) 🐇',...
             'simlr (400 secs) 🐢',...
             'soptsc (1,182 secs) 🐢🐢', 'sinnlrr (8,307 secs) 🐢🐢🐢', };
        methodtagv = {'specter','sc3','simlr', 'soptsc', 'sinnlrr'};
        [indx, tf] = listdlg('PromptString',...
            {'Select clustering program'},...
            'SelectionMode', 'single', ...
            'ListString', methodtagvx);
        if tf == 1
            methodtag = methodtagv{indx};
        else
            return;
        end
        i_reclustercells(src, methodtag);
        guidata(FigureHandle, sce);
    end

    function i_reclustercells(src, methodtag)
        methodtag = lower(methodtag);
        usingold = false;
        if ~isempty(sce.struct_cell_clusterings.(methodtag))
            answer1 = questdlg(sprintf('Using existing %s clustering?', upper(methodtag)), ...
                '', ...
                'Yes, use existing', 'No, re-compute', 'Cancel', 'Yes, use existing');
            switch answer1
                case 'Yes, use existing'
                    sce.c_cluster_id = sce.struct_cell_clusterings.(methodtag);
                    usingold = true;
                case 'No, re-compute'
                    usingold = false;
                case 'Cancel'
                    return
            end
        end
        if ~usingold
            k = gui.i_inputnumk;
            if isempty(k), return; end
            fw = gui.gui_waitbar;
            try
                % [sce.c_cluster_id]=sc_cluster_x(sce.X,k,'type',methodtag);
                sce = sce.clustercells(k, methodtag, true);
            catch ME
                gui.gui_waitbar(fw);
                errordlg(ME.message);
                return
            end
            gui.gui_waitbar(fw);
        end
        [c, cL] = grp2idx(sce.c_cluster_id);
        sce.c = c;
        RefreshAll(src, [], true, false);
        guidata(FigureHandle, sce);
    end

    function LabelClusters(src, ~)
        state = src.State;
        if strcmp(state, 'off')
            dtp = findobj(h, 'Type', 'datatip');
            delete(dtp);
        else
            [thisc,~]=i_select1class(sce);
            if ~isempty(thisc)
                [c,cL] = grp2idx(thisc);
                sce.c = c;
                RefreshAll(src, 1, true, false);                
                if max(c)<=200
                    if i_labelclusters
                        set(src, 'State', 'on');
                    else
                        set(src, 'State', 'off');
                    end
                else
                    warndlg('Labels are not showing. Too many categories (n>200).');
                end
                guidata(FigureHandle, sce);
            end        
            % colormap(lines(min([256 numel(unique(sce.c))])));
        end
    end

%     function ShowClustersPop(src, ~)
%         answer = questdlg('Show clusters in new figures?');
%         if ~strcmp(answer, 'Yes')
%             return
%         end
%         
%         cmv = 1:max(c);
%         idxx = cmv;
%         [cmx] = countmember(cmv, c);
%         answer = questdlg('Sort by size of cell groups?');
%         if strcmpi(answer, 'Yes')
%             [~, idxx] = sort(cmx, 'descend');
%         end
%         sces = sce.s;
%         if isempty(h.ZData)
%             sces = sce.s(:, 1:2);
%         end
%         
%         [para] = i_getoldsettings(src);
%         figure;
%         for k = 1:9
%             if k <= max(c)
%                 subplot(3, 3, k);
%                 gui.i_gscatter3(sces, c, 3, cmv(idxx(k)));
%                 title(sprintf('%s\n%d cells (%.2f%%)', ...
%                     cL{idxx(k)}, cmx(idxx(k)), ...
%                     100 * cmx(idxx(k)) / length(c)));
%             end
%             colormap(para.oldColorMap);
%         end
%         
%         if ceil(max(c) / 9) == 2
%             figure;
%             for k = 1:9
%                 kk = k + 9;
%                 if kk <= max(c)
%                     subplot(3, 3, k);
%                     gui.i_gscatter3(sces, c, 3, cmv(idxx(kk)));
%                     title(sprintf('%s\n%d cells (%.2f%%)', ...
%                         cL{idxx(kk)}, cmx(idxx(kk)), ...
%                         100 * cmx(idxx(kk)) / length(c)));
%                 end
%             end
%             colormap(para.oldColorMap);
%         end
%         if ceil(max(c) / 9) > 2
%             warndlg('Group(s) #18 and above are not displayed');
%         end
%     end

    function [txt] = i_myupdatefcnx(~, event_obj)
        % pos = event_obj.Position;
        idx = event_obj.DataIndex;
        txt = cL(c(idx));        
    end

    function [isdone] = i_labelclusters(notasking)
        if nargin < 1, notasking = false; end
        isdone = false;
        if ~isempty(cL)
            if notasking
                stxtyes = c;
            else
                answer = questdlg(sprintf('Label %d groups with index or text?', numel(cL)), ...
                    'Select Format', 'Index', 'Text', 'Cancel', 'Text');
                switch answer
                    case 'Text'
                        stxtyes = cL(c);
                    case 'Index'
                        stxtyes = c;
                    otherwise
                        return
                end
            end
            dtp = findobj(h, 'Type', 'datatip');
            delete(dtp);
            
            row = dataTipTextRow('', stxtyes);
            h.DataTipTemplate.DataTipRows = row;
            % h.DataTipTemplate.FontSize = 5;
            for i = 1:max(c)
                idx = find(c == i);
                siv = sce.s(idx, :);
                si = mean(siv, 1);
                [k] = dsearchn(siv, si);
                datatip(h, 'DataIndex', idx(k));
            end
            isdone = true;
        end
    end

    function [para] = i_getoldsettings(src)
        ah = findobj(src.Parent.Parent, 'type', 'Axes');
        ha = findobj(ah.Children, 'type', 'Scatter');
        ha1 = ha(1);
        oldMarker = ha1.Marker;
        oldSizeData = ha1.SizeData;
        oldColorMap = colormap;
        para.oldMarker = oldMarker;
        para.oldSizeData = oldSizeData;
        para.oldColorMap = oldColorMap;
    end

end
