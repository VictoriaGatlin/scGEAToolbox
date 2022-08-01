function [p]=CooccurrenceAffinity(X)

isdebug=false;
oldpth=pwd();
[isok,msg]=commoncheck_R('R_CooccurrenceAffinity');
if ~isok, error(msg); return; end

tmpfilelist={'input.h5','output.h5'};

if ~isdebug, pkg.i_deletefiles(tmpfilelist); end
X=uint8(X>0);

% if exist("input.h5",'file'), delete("input.h5"); end
% if exist("output.h5",'file'), delete("output.h5"); end
h5create('input.h5', '/X', size(X));
h5write('input.h5', '/X', X);

pkg.RunRcode('script.R');
p=h5read('output.h5','/p');
if isstring(p), p=str2double(p); end

if ~isdebug, pkg.i_deletefiles(tmpfilelist); end
cd(oldpth);

end