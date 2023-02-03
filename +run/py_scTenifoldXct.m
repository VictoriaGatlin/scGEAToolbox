function [T]=py_scTenifoldXct(sce,celltype1,celltype2,twosided,A1,A2)

isdebug=false;

T=[];
if nargin<6, A2=[]; end
if nargin<5, A1=[]; end
if nargin<4, twosided=true; end

oldpth=pwd();
pw1=fileparts(mfilename('fullpath'));
wrkpth=fullfile(pw1,'external','py_scTenifoldXct');
cd(wrkpth);


fw = gui.gui_waitbar([],[],'Check Python environment...');

x=pyenv;
pkg.i_add_conda_python_path;
cmdlinestr=sprintf('"%s" "%s%srequire.py"', ...
        x.Executable,wrkpth,filesep);
disp(cmdlinestr)
[status,cmdout]=system(cmdlinestr,'-echo');
if status~=0
    cd(oldpth);
    waitfor(errordlg(sprintf('%s',cmdout)));
    error('Python scTenifoldXct has not been installed properly.');
end



tmpfilelist={'X.mat','X.txt','g.txt','c.txt','output.txt', ...
             'output1.txt','output2.txt',...
             'gene_name_Source.tsv', 'gene_name_Target.tsv',...
             'pcnet_Source.npz', 'pcnet_Target.npz',...
             'A1.mat','A2.mat','pcnet_Source.mat','pcnet_Target.mat'};

if ~isdebug, pkg.i_deletefiles(tmpfilelist); end

% load(fullfile(pw1,'..','resources','Ligand_Receptor.mat'), ...
%     'ligand','receptor');
% validg=unique([ligand receptor]);
% [y]=ismember(upper(sce.g),validg);
% X=sce.X(y,:);
% g=sce.g(y);
% writematrix(sce.X,'X.txt');

idx=sce.c_cell_type_tx==celltype1 | sce.c_cell_type_tx==celltype2;
sce=sce.selectcells(idx);
sce.c_batch_id=sce.c_cell_type_tx;
sce.c_batch_id(sce.c_cell_type_tx==celltype1)="Source";
sce.c_batch_id(sce.c_cell_type_tx==celltype2)="Target";
% sce=sce.qcfilter;

X=sce.X;
save('X.mat','-v7.3','X');
writematrix(sce.g,'g.txt');
writematrix(sce.c_batch_id,'c.txt');
disp('Input X g c written.');

t=table(sce.g,sce.g,'VariableNames',{' ','gene_name'});
writetable(t,'gene_name_Source.tsv','filetype','text','Delimiter','\t');
writetable(t,'gene_name_Target.tsv','filetype','text','Delimiter','\t');
disp('Input gene_names written.');

if isvalid(fw), gui.gui_waitbar(fw); end


if isempty(A1)
    fw = gui.gui_waitbar([],[],'Step 1 of 3: Building A1 network...');
    disp('Building A1 network...')
    A1=sc_pcnetpar(sce.X(:,sce.c_cell_type_tx==celltype1));
    disp('A1 network built.')    
else
    disp('Using A1 provided.')
end
A1=A1./max(abs(A1(:)));
% A=0.5*(A1+A1.');
A=ten.e_filtadjc(A1,0.75,false);
save('pcnet_Source.mat','A','-v7.3');
if isvalid(fw), gui.gui_waitbar(fw); end

if isempty(A2)
    fw = gui.gui_waitbar([],[],'Step 2 of 3: Building A2 network...');
    disp('Building A2 network...')
    A2=sc_pcnetpar(sce.X(:,sce.c_cell_type_tx==celltype2));
    disp('A2 network built.')    
else
    disp('Using A2 provided.');
end
A2=A2./max(abs(A2(:)));
% A=0.5*(A2+A2.');
A=ten.e_filtadjc(A2,0.75,false);
save('pcnet_Target.mat','A','-v7.3');
if isvalid(fw), gui.gui_waitbar(fw); end
clear A A1 A2

%x=pyenv;
%pkg.i_add_conda_python_path;

tag=1;
if twosided, tag=2; end

fw=gui.gui_waitbar([],[],'Step 3 of 3: run scTenifoldXct.py...');
cmdlinestr=sprintf('"%s" "%s%sscript.py" %d', ...
    x.Executable,wrkpth,filesep,tag);
disp(cmdlinestr)
[status]=system(cmdlinestr,'-echo');
% https://www.mathworks.com/matlabcentral/answers/334076-why-does-externally-called-exe-using-the-system-command-freeze-on-the-third-call
if isvalid(fw), gui.gui_waitbar(fw); end

% rt=java.lang.Runtime.getRuntime(); 
% pr = rt.exec(cmdlinestr);
% [status]=pr.waitFor();

% if twosided
%     if status==0 && exist('output1.txt','file') && exist('output2.txt','file')
%         T1=readtable('output1.txt');
%         T2=readtable('output2.txt');
%         T={T1,T2};
%     end
% else
    if status==0 && exist('output1.txt','file')
        T=readtable('output1.txt');
        if twosided && exist('output2.txt','file')
            T2=readtable('output2.txt');
            T={T,T2};
        end
    end
%end

if ~isdebug, pkg.i_deletefiles(tmpfilelist); end
cd(oldpth);
end
