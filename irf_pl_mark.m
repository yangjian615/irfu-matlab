function [outhandle colr]=irf_pl_mark(varargin)
%IRF_PL_MARK   Mark time intervals or instants
% Marks time intervals with transparent rectangle or time instants with line
%
%   IRF_PL_MARK(tlim) mark time interval
%
%   IRF_PL_MARK(AX,tlim) mark in the specified axis (default gca)
%
%   IRF_PL_MARK(AX,tlim,color) mark with the specified color
%
%   IRF_PL_MARK(AX,tlim,color,'Property1',PropertyValue1,..) specify properties
%
%   [H,COLOR]=IRF_PL_MARK(...) returns handle to patch or line and the color table
%
% tlim - time interval or array of intervals to mark, or column vector of time instants
% color - string, rgb 1x3, nx3, or 1xnx3 specifying color(s);
%         if omitted colors are chosen randomly.
%
%
% WARNING!!! IRF_PL_MARK has changed (2011-03-30) the order of input parameters
%  now more compliant to MATLAB

% $Id$

[ax,args,nargs] = axescheck(varargin{:});

if nargs == 0, % show only help
    help irf_pl_mark;
    return
end

if isempty(ax),
    if any(ishandle(args{1})), % first argument is axis handles
        ax=args{1};
        args=args(2:end);
        nargs=nargs-1;
    else
        % call irf_pl_mark recursively with GCA as handle
        [H,COLOR]= irf_pl_mark(gca,varargin{:});
        if nargout > 0, outhandle = H; end
        if nargout > 1, colr = COLOR; end
        return;
    end
end

tlim=args{1};
% if mark time instants instead of time intervals (only one time given)
if size(tlim,2) == 1, tlim(:,2)=tlim(:,1); end

if nargs == 1, % if only time intervals given, specify color
    if size(tlim,1) == 1
        color='yellow';
    else % choose random colors
        color=rand(size(tlim,1),3);
    end
end

if nargs >= 2, % color i specified
    color = args{2};
end

if nargs > 2 && (rem(nargs,2) ~= 0)
    error('IRFU_MATLAB:irf_pl_mark:InvalidNumberOfInputs','Incorrect number of input arguments')
end

% properties specified
pvpairs = args(3:end);


% create 1 x n x 3 color matrix
if ischar(color),
    color = repmat(color, size(tlim,1), 1);
end


ud=get(gcf,'userdata');
if isfield(ud,'t_start_epoch'),  tlim=tlim-ud.t_start_epoch;end


tpoints = [tlim(:,1) tlim(:,2) tlim(:,2) tlim(:,1)];

%tlim = reshape( tlim, 1, prod(size(tlim)) );

h = reshape( ax, 1, numel(ax) );
hp=zeros(length(h),size(tlim,1)); % predefine patch handles
for j=1:length(h)
    ylim=get(h(j),'ylim');
    ypoints=zeros(size(tpoints));
    ypoints(:,1:2) = ylim(1);
    ypoints(:,3:4) = ylim(2);
    zpoints = zeros(size(ypoints,1),4); % to put patches under all plots
    for jj=1:size(tpoints,1),
        if tlim(jj,1)==tlim(jj,2) % draw line instead of patch (in this case draw line above everything, therefore "+2" in the next line)
            hp(j,jj)=line(tpoints(jj,1:2), ypoints(jj,[1 3]), zpoints(jj,[1 3])+1,'color',color(jj,:),'parent',h(j),pvpairs{:});
        else % make patch
            %          hp(j,jj)=patch(tpoints(jj,:)', ypoints(jj,:)', zpoints(jj,:)', color(jj,:),'edgecolor','none','parent',h(j),varargin{:});
            hp(j,jj)=patch(tpoints(jj,:)', ypoints(jj,:)', zpoints(jj,:)', color(jj,:),'edgecolor','none','parent',h(j),'facealpha',.3,pvpairs{:});
            %          fc=get(hp(j,jj),'facecolor');
            %          fc=[1 1 1]-([1 1 1]-fc)/3; % make facecolor lighter
            %          set(hp(j,jj),'facecolor',fc);
        end
    end
    set(h(j),'layer','top');
end

if nargout > 0
    outhandle = hp;
end

if nargout > 1
    colr = color;
end



