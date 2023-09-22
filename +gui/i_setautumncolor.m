function [a] = i_setautumncolor(c, cmapname, rev)

if nargin < 3, rev = true; end
if nargin < 2, cmapname = 'autumn'; end
colormap default
a = colormap(cmapname);
if strcmpi(cmapname, 'autumn')
    if rev
        a = flipud(a);
    end
end
a(1, :) = [.8, .8, .8];
if numel(unique(c)) == 1
    for kk = 1:size(a, 1)
        a(kk, :) = [.8, .8, .8];
    end
end
colormap(a);
end