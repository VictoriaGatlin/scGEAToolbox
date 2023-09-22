function obj = estimatecellcycle(obj, forced, methodid)
if nargin < 3, methodid = 1; end
if nargin < 2, forced = false; end
if isempty(obj.c_cell_cycle_tx) || forced
    switch methodid
        case 1
            obj.c_cell_cycle_tx = sc_cellcyclescore(obj.X, obj.g);
        case 2
            obj.c_cell_cycle_tx = run.r_SeuratCellCycle(obj.X, obj.g);
    end
    disp('C_CELL_CYCLE_TX added.');
else
    disp('C_CELL_CYCLE_TX is existing.');
end
end
