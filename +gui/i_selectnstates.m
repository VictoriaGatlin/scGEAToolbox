function [thisc, clable] = i_selectnstates(sce)

thisc = [];
clable = [];


baselistitems = {'Current Class (C)'};
i_additem(sce.c_cluster_id, 'Cluster ID');
i_additem(sce.c_cell_cycle_tx, 'Cell Cycle Phase');
i_additem(sce.c_cell_type_tx, 'Cell Type');
i_additem(sce.c_batch_id, 'Batch ID');
i_additem(full(sum(sce.X))', 'Library Size');
% i_additem(zeros(sce.NumCells,1), 'Mt-reads Ratio');


    function i_additem(itemv, itemn)
        if ~isempty(itemv) && length(unique(itemv)) >= 1
            baselistitems = [baselistitems, itemn];
        end
end

    listitems = [baselistitems, ...
        sce.list_cell_attributes(1:2:end)];
    nx = length(baselistitems);

    %     a=evalin('base','whos');
    %     b=struct2cell(a);
    %     v=false(length(a),1);
    %     for k=1:length(a)
    %         if max(a(k).size)==sce.NumCells && min(a(k).size)==1
    %             v(k)=true;
    %         end
    %     end
    %     if any(v)
    %         a=a(v);
    %         b=b(:,v);
    %         listitems=[listitems,'Customized C...'];
    %     end

    n = length(listitems);
    if n < 1
        warndlg(['This function requires at least one ', ...
                'grouping variable (e.g., BATCH_ID, ', ...
                'CLUSTER_ID, or CELL_TYPE_TXT).']);           
        return;
    end

    [indx2, tf2] = listdlg('PromptString', ...
        {'Select cell state/grouping variable:'}, ...
        'SelectionMode', 'multiple', ...
        'ListString', listitems, ...
        'InitialValue', 2:n);

    if tf2 == 1
        thisc=cell(length(indx2),1);
        clable=cell(length(indx2),1);
        for k=1:length(indx2)
            [thisc{k}, clable{k}] = i_getidx(indx2(k));
        end
    end


    function [thisc, clable] = i_getidx(indx)
        clable = listitems{indx};
        switch clable
            case 'Library Size'
                thisc = full(sum(sce.X).');
            case 'Mt-reads Ratio'
                i = startsWith(sce.g, 'mt-', 'IgnoreCase', true);
                lbsz = full(sum(sce.X, 1));
                lbsz_mt = sum(sce.X(i, :), 1);
                thisc = (lbsz_mt ./ lbsz).';
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
            otherwise % other properties
                nx = length(baselistitems);
                clable = sce.list_cell_attributes{2*(indx - nx)-1};
                thisc = sce.list_cell_attributes{2*(indx - nx)};
        end
    end
end