function [glist, setname, Col, ctag] = i_selectMSigDBGeneSets(species, colnoly)

if nargin < 1, species = 'human'; end
if nargin < 2, colnoly = false; end

glist = [];
setname = [];
Col = [];
ctag = [];

switch lower(species)
    case {'human', 'hs'}
        listitems = {'H: hallmark gene sets', 'C1: positional gene sets', ...
            'C2: curated gene sets', ...
            'C3: regulatory target gene sets', ...
            'C4: computational gene sets', ...
            'C5: ontology gene sets', ...
            'C6: oncogenic signature gene sets', ...
            'C7: immunologic signature gene sets', ...
            'C8: cell type signature gene sets'};
        % urllist={'http://www.gsea-msigdb.org/gsea/msigdb/download_file.jsp?filePath=/msigdb/release/2022.1.Hs/h.all.v2023.2.Hs.json',...
        %     'http://www.gsea-msigdb.org/gsea/msigdb/download_file.jsp?filePath=/msigdb/release/2022.1.Hs/c1.all.v2023.2.Hs.json',...
        %     'http://www.gsea-msigdb.org/gsea/msigdb/download_file.jsp?filePath=/msigdb/release/2022.1.Hs/c2.all.v2023.2.Hs.json',...
        %     'http://www.gsea-msigdb.org/gsea/msigdb/download_file.jsp?filePath=/msigdb/release/2022.1.Hs/c3.all.v2023.2.Hs.json'};

        urllist = {'https://scgeatool.github.io/data/msigdb/h.all.v2023.2.Hs.json', ...
            'https://scgeatool.github.io/data/msigdb/c1.all.v2023.2.Hs.json', ...
            'https://scgeatool.github.io/data/msigdb/c2.all.v2023.2.Hs.json', ...
            'https://scgeatool.github.io/data/msigdb/c3.all.v2023.2.Hs.json', ...
            'https://scgeatool.github.io/data/msigdb/c4.all.v2023.2.Hs.json', ...
            'https://scgeatool.github.io/data/msigdb/c5.all.v2023.2.Hs.json', ...
            'https://scgeatool.github.io/data/msigdb/c6.all.v2023.2.Hs.json', ...
            'https://scgeatool.github.io/data/msigdb/c7.all.v2023.2.Hs.json', ...
            'https://scgeatool.github.io/data/msigdb/c8.all.v2023.2.Hs.json'};
    case {'mouse', 'mm'}
        listitems = {'MH: hallmark gene sets', 'M1: positional gene sets', ...
            'M2: curated gene sets', ...
            'M3: regulatory target gene sets', ...
            'M5: ontology gene sets', ...
            'M8: cell type signature gene sets'};
        urllist = {'https://scgeatool.github.io/data/msigdb/mh.all.v2023.2.Mm.json', ...
            'https://scgeatool.github.io/data/msigdb/m1.all.v2023.2.Mm.json', ...
            'https://scgeatool.github.io/data/msigdb/m2.all.v2023.2.Mm.json', ...
            'https://scgeatool.github.io/data/msigdb/m3.all.v2023.2.Mm.json', ...
            'https://scgeatool.github.io/data/msigdb/m5.all.v2023.2.Mm.json', ...
            'https://scgeatool.github.io/data/msigdb/m8.all.v2023.2.Mm.json'};
end

[indx1, tf1] = listdlg('PromptString', ...
    {'Select MSigDB Collection:'}, ...
    'SelectionMode', 'single', 'ListString', listitems, ...
    'ListSize', [220, 300]);

if tf1 ~= 1, return; end
if pkg.isnetavl ~= 1
    errordlg('This function requires internet access to retrieve information needed.');
    return;
end


    % tmpf=tempname;
    % websave(tmpf,urllist{indx1},weboptions('ContentType','json'));
    % fid = fopen(tmpf);
    % raw = fread(fid,inf);
    % str = char(raw');
    % fclose(fid);
    % val = jsondecode(str);

    %fw = gui.gui_waitbar;
    Col = webread(urllist{indx1});
    ctag = listitems{indx1};
    ctag = extractBefore(ctag, strfind(ctag,':'));
    setnames = fields(Col);
    %gui.gui_waitbar(fw);

    if colnoly
        return;
    end

    %idx=gui.i_selmultidlg(a);
    %string(val.(a{idx}).geneSymbols);

    %%
    [idx, tf] = listdlg('PromptString', ...
        {'Select gene set:'}, ...
        'SelectionMode', 'multiple', ...
        'ListString', setnames, ...
        'ListSize', [260, 300]);
    if tf == 1
        setname = setnames(idx);
        glist = cell(length(idx), 1);
        for k=1:length(idx)
            glist{k} = string(Col.(setnames{idx(k)}).geneSymbols);
        end
    end