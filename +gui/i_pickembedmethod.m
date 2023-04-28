function [methodtag]=i_pickembedmethod
    
methodtag='';
        [indx2,tf2] = listdlg('PromptString',...
    {'Select embedding method:'}, ...
     'SelectionMode','single','ListString', ...
     {'tSNE', 'UMAP', 'PHATE', ...
     'MetaViz [PMID:36774377] 🐢'},'ListSize',[175 130]);
        if ~tf2, return; end
        methodopt={'tsne','umap','phate','metaviz'};
        methodtag=methodopt{indx2};