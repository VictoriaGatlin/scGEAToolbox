function [thisc, clable] = i_select1class(sce, allowunique)

if nargin < 2, allowunique = true; end
thisc = [];
clable = '';

listitems = {'Current Class (C)'};
if ~isempty(sce.c_cluster_id)
    if allowunique
        listitems = [listitems, 'Cluster ID'];
    else
        if numel(unique(sce.c_cluster_id)) > 1
            listitems = [listitems, 'Cluster ID'];
        end
    end
end
if ~isempty(sce.c_cell_type_tx)
    if allowunique
        listitems = [listitems, 'Cell Type'];
    else
        if numel(unique(sce.c_cell_type_tx)) > 1
            listitems = [listitems, 'Cell Type'];
        end
    end
end

if ~isempty(sce.c_cell_cycle_tx)
    if allowunique
        listitems = [listitems, 'Cell Cycle Phase'];
    else
        if numel(unique(sce.c_cell_cycle_tx)) > 1
            listitems = [listitems, 'Cell Cycle Phase'];
        end
    end
end
if ~isempty(sce.c_batch_id)
    if allowunique
        listitems = [listitems, 'Batch ID'];
    else
        if numel(unique(sce.c_batch_id)) > 1
            listitems = [listitems, 'Batch ID'];
        end
    end
end

a = evalin('base', 'whos');
b = struct2cell(a);
v = false(length(a), 1);
for k = 1:length(a)
    if max(a(k).size) == sce.NumCells && min(a(k).size) == 1
        v(k) = true;
    end
end
if any(v)
    a = a(v);
    b = b(:, v);
    listitems = [listitems, 'Workspace Variable...'];
end

% listitems={'Current Class (C)','Cluster ID','Batch ID',...
%            'Cell Type','Cell Cycle Phase'};
[indx2, tf2] = listdlg('PromptString', ...
    {'Select grouping variable:'}, ...
    'SelectionMode', 'single', 'ListString', listitems);
if tf2 == 1
    clable = listitems{indx2};
    switch clable
        case 'Current Class (C)'
            thisc = sce.c;
        case 'Cluster ID' % cluster id
            thisc = sce.c_cluster_id;
        case 'Batch ID' % batch id
            thisc = sce.c_batch_id;
        case 'Cell Type' % cell type
            thisc = sce.c_cell_type_tx;
        case 'Cell Cycle Phase' % cell cycle
            thisc = sce.c_cell_cycle_tx;
        case 'Workspace Variable...'
            thisc = i_pickvariable;
    end
end


    function [c] = i_pickvariable
        c = [];
        %     a=evalin('base','whos');
        %     b=struct2cell(a);
        %     v=false(length(a),1);
        %     for k=1:length(a)
        %         if max(a(k).size)==sce.NumCells && min(a(k).size)==1
        %             v(k)=true;
        %         end
        %     end
        %     if any(v)
        %valididx=ismember(b(4,:),'double');
        %a=a(valididx);
        [indx, tf] = listdlg('PromptString', {'Select variable:'}, ...
            'liststring', b(1, :), 'SelectionMode', 'single');
        if tf == 1
            c = evalin('base', a(indx).name);
        end
        %    end
end
    % if isempty(thisc)
    %     errordlg('Undefined');
    %     return;
    % end
    % if numel(unique(thisc))==1
    %     warndlg("Cannot compare with an unique group");
    %     return;
    % end
end
