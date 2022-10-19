function [c,cL,noanswer]=i_reordergroups(thisc)
noanswer=true;
[c,cL]=grp2idx(thisc);
if numel(cL)==1
    %errordlg('Only one cell type or cluster.');
    noanswer=false;
    return;
end

[answer]=questdlg('Manually order groups?','', ...
    'Yes','No','Cancel','No');
if isempty(answer), return; end
switch answer
    case 'Yes'
        [newidx]=gui.i_selmultidlg(cL,sort(cL));
        if length(newidx)~=length(cL)
            noanswer=true;
            return;
        end
        cx=c;
        for k=1:length(newidx)
            c(cx==newidx(k))=k;
        end
        cL=cL(newidx);
        noanswer=false;
    case 'No'
        noanswer=false;
    otherwise
       
end

end