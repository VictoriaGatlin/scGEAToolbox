function [T, iscomplete] = py_scTenifoldXct2(sce1, sce2, celltype1, celltype2, ...
    A1s, A1t, A2s, A2t)

iscomplete = false;
T = [];
if nargin < 8, A2t = []; end
if nargin < 7, A2s = []; end
if nargin < 6, A1t = []; end
if nargin < 5, A1s = []; end


oldpth = pwd();
pw1 = fileparts(mfilename('fullpath'));
wrkpth = fullfile(pw1, 'external', 'py_scTenifoldXct2');
cd(wrkpth);

isdebug = true;
useexist = true;

fw = gui.gui_waitbar([], [], 'Checking Python environment...');

x = pyenv;
try
    pkg.i_add_conda_python_path;
catch
end
cmdlinestr = sprintf('"%s" "%s%srequire.py"', ...
    x.Executable, wrkpth, filesep);
disp(cmdlinestr)
[status, cmdout] = system(cmdlinestr, '-echo');
if status ~= 0
    cd(oldpth);
    waitfor(errordlg(sprintf('%s', cmdout)));
    error('Python scTenifoldXct has not been installed properly.');
end


tmpfilelist = {'X1.mat', 'X2.mat', 'g1.txt', 'c1.txt', 'g2.txt', 'c2.txt', 'output.txt', ...
    '1/gene_name_Source.tsv', '1/gene_name_Target.tsv', ...
    '2/gene_name_Source.tsv', '2/gene_name_Target.tsv', ...
    '1/pcnet_Source.mat', '1/pcnet_Target.mat', ...
    '2/pcnet_Source.mat', '2/pcnet_Target.mat'};

if ~isdebug, pkg.i_deletefiles(tmpfilelist); end

% load(fullfile(pw1,'..','resources','Ligand_Receptor.mat'), ...
%     'ligand','receptor');
% validg=unique([ligand receptor]);
% [y]=ismember(upper(sce.g),validg);
% X=sce.X(y,:);
% g=sce.g(y);
% writematrix(sce.X,'X.txt');

i_prepareX(sce1, 1);
i_prepareX(sce2, 2);

if isvalid(fw)
    gui.gui_waitbar(fw, [], 'Checking Python environment is complete');
end

    function i_prepareX(sce, id)
        if ~exist(sprintf('%d', id), 'dir')
            mkdir(sprintf('%d', id));
        end
        idx = sce.c_cell_type_tx == celltype1 | sce.c_cell_type_tx == celltype2;
        sce = sce.selectcells(idx);
        sce.c_batch_id = sce.c_cell_type_tx;
        sce.c_batch_id(sce.c_cell_type_tx == celltype1) = "Source";
        sce.c_batch_id(sce.c_cell_type_tx == celltype2) = "Target";
        % sce=sce.qcfilter;
        X = sce.X;
        save(sprintf('X%d.mat', id), '-v7.3', 'X');
        writematrix(sce.g, sprintf('g%d.txt', id));
        writematrix(sce.c_batch_id, sprintf('c%d.txt', id));
        fprintf('Input X%d g%d c%d written.\n', id, id, id);
        t = table(sce.g, sce.g, 'VariableNames', {' ', 'gene_name'});
        writetable(t, sprintf('%d/gene_name_Source.tsv', id), ...
            'filetype', 'text', 'Delimiter', '\t');
        writetable(t, sprintf('%d/gene_name_Target.tsv', id), ...
            'filetype', 'text', 'Delimiter', '\t');
        disp('Input gene_names written.');
end

    fw = gui.gui_waitbar([], [], 'Step 2 of 4: Building S1 networks...');
    try
        i_prepareA(sce1, A1s, A1t, 1);
    catch ME
        if isvalid(fw)
            gui.gui_waitbar(fw, [], 'Building S1 networks is incomplete');
        end
        errordlg(ME.message);
        return;
    end
    gui.gui_waitbar(fw, [], 'Building S1 networks is complete');


    fw = gui.gui_waitbar([], [], 'Step 3 of 4: Building S2 networks...');
    try
        i_prepareA(sce2, A2s, A2t, 2);
    catch ME
        if isvalid(fw)
            gui.gui_waitbar(fw, [], 'Building S2 network is incomplete');
        end
        errordlg(ME.message);
        return;
    end
    gui.gui_waitbar(fw, [], 'Building S2 network is complete');


        function i_prepareA(sce, A1, A2, id)

            if isempty(A1)
                if useexist && exist(sprintf('%d/usr_Source.mat', id), 'file')
                    disp('Loading existing A1 network...');
                    load(sprintf('%d/usr_Source.mat', id), 'A');
                    A1 = A;
                else
                    disp('Building A1 network...')
                    A1 = sc_pcnetpar(sce.X(:, sce.c_cell_type_tx == celltype1));
                    disp('A1 network built.')
                end
            else
                disp('Using A1 provided.')
            end
            A1 = A1 ./ max(abs(A1(:)));
            % A=0.5*(A1+A1.');
            A = ten.e_filtadjc(A1, 0.75, false);
            save(sprintf('%d/pcnet_Source.mat', id), 'A', '-v7.3');


            if isempty(A2)
                if useexist && exist(sprintf('%d/usr_Target.mat', id), 'file')
                    disp('Loading existing A2 network...');
                    load(sprintf('%d/usr_Target.mat', id), 'A');
                    A2 = A;
                else
                    disp('Building A2 network...');
                    A2 = sc_pcnetpar(sce.X(:, sce.c_cell_type_tx == celltype2));
                    disp('A2 network built.');
                end
            else
                disp('Using A2 provided.');
            end
            A2 = A2 ./ max(abs(A2(:)));
            % A=0.5*(A2+A2.');
            A = ten.e_filtadjc(A2, 0.75, false);
            save(sprintf('%d/pcnet_Target.mat', id), 'A', '-v7.3');

            clear A A1 A2
    end


        fw = gui.gui_waitbar([], [], 'Step 4 of 4: Running scTenifoldXct.py...');


        cmdlinestr = sprintf('"%s" "%s%sscript.py"', ...
            x.Executable, wrkpth, filesep);
        disp(cmdlinestr)

        try
            [status] = system(cmdlinestr, '-echo');
            % https://www.mathworks.com/matlabcentral/answers/334076-why-does-externally-called-exe-using-the-system-command-freeze-on-the-third-call
        catch ME
            if isvalid(fw)
                gui.gui_waitbar(fw, [], 'Running scTenifoldXct.py is incomplete.');
            end
            errordlg(ME.message);
            return;
        end
        % rt=java.lang.Runtime.getRuntime();
        % pr = rt.exec(cmdlinestr);
        % [status]=pr.waitFor();

        if isvalid(fw)
            gui.gui_waitbar(fw, [], 'Running scTenifoldXct.py is complete');
        end

        if status == 0 && exist('output.txt', 'file')
            T = readtable('output.txt');
            iscomplete = true;
        end

        if ~isdebug, pkg.i_deletefiles(tmpfilelist); end
        cd(oldpth);
    end
