function [idx,xr,yr]=gui_setranges(x,y,xr,yr)
% https://www.mathworks.com/matlabcentral/answers/143306-how-to-move-a-plotted-line-vertically-with-mouse-in-a-gui
if nargin<1, x=randn(300,1); end
if nargin<2, y=randn(300,1); end
if nargin<3, xr=[.3 .7]; end
if nargin<4, yr=[.3 .7]; end

fh=figure();
sh=scatter(x,y);
lh1=xline(xr(1),'r-');
lh2=xline(xr(2),'r-');
lh3=yline(yr(1),'r-');
lh4=yline(yr(2),'r-');
idx=true(length(x),1);
guidata(fh,[x y]);

set(fh,'WindowButtonDownFcn', @mouseDownCallback);
 

function mouseDownCallback(figHandle,varargin)

    % get the handles structure
      xydata = guidata(figHandle);
%     lh1=handles{1}; lh2=handles{2};
%     lh3=handles{3}; lh4=handles{4};
    
    % get the position where the mouse button was pressed (not released)
    % within the GUI
    currentPoint = get(figHandle, 'CurrentPoint');
    x1            = currentPoint(1,1);
    y1            = currentPoint(1,2);
    
    % get the position of the axes within the GUI
    % allAxesInFigure = findall(figHandle,'type','axes');
    axes1 = get(figHandle, 'CurrentAxes');
    set(axes1,'Units','pixels');
    axesPos = get(axes1,'Position');
    minx    = axesPos(1);
    miny    = axesPos(2);
    maxx    = minx + axesPos(3);
    maxy    = miny + axesPos(4);
   
    % is the mouse down event within the axes?
    if x1>=minx && x1<=maxx && y1>=miny && y1<=maxy 

        % do we have graphics objects?
        % if isfield(handles,'plotHandles')
            
            % get the position of the mouse down event within the axes
            currentPoint = get(axes1, 'CurrentPoint');
            xx            = currentPoint(2,1);
            yy            = currentPoint(2,2);
            
            % b=findall(axes1.Children,'type','ConstantLine');
            % b(1).InterceptAxis
    if min(abs(xx-axes1.XLim)) < min(abs(yy-axes1.YLim)) 
            if abs(xx-lh1.Value) < abs(xx-lh2.Value)
                if ~isempty(lh1), delete(lh1); end
                lh1=xline(xx,'r-');
            else
                if ~isempty(lh2), delete(lh2); end
                lh2=xline(xx,'r-');
            end
    else
            if abs(yy-lh3.Value) < abs(yy-lh4.Value)
                if ~isempty(lh3), delete(lh3); end
                lh3=yline(yy,'r-');
            else
                if ~isempty(lh4), delete(lh4); end
                lh4=yline(yy,'r-');
            end
    end
    i=(xydata(:,1)>lh1.Value) & (xydata(:,1)<lh2.Value);
    j=(xydata(:,2)>lh3.Value) & (xydata(:,2)<lh4.Value);
    idx=i&j;
    xr=[lh1.Value lh2.Value];
    yr=[lh3.Value lh4.Value];
    axes1.Title.String=sprintf('%d out of %d (%.2f%%)',...
        sum(i&j),length(i),100*sum(idx)./length(i));
    end
end

end