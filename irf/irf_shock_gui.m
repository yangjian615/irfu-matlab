function [out] = irf_shock_gui(scd,varName)
%IRF_SHOCK_GUI GUI for determining shock parameters.
%
%   THIS FUNCTION IS IN DEVELOPMENT AND HAS NOT BEEN PROPERLY TESTED!
%
%   IRF_SHOCK_GUI(scd) Starts a GUI. scd is a struct with fields containing
%   TSeries objects of spacecraft data. Select up- and downstream intervals
%   of the shock by clicking in the plot. Then select methods to calculate
%   shock normal and shock speed. The methods are described in
%   irf_shock_normal. Click "Calculate" to display the results.
%
%   scd field names:
%       B       -   3D magnetic field (nT)
%       V       -   3D ion or electron bulk velocity (km/s)
%       n       -   ion or electron number density (cm^-3)
%       Ti/Te   -   ion/electron temperature (eV) (optional)
%       R       -   Spacecraft position as given by R =
%                   mms.get_data('R_gse',tint) (optional)
%   
%   Results displayed:
%       n       -   Shock normal vector
%       Vsh     -   Shock speed along normal vector 
%       thBn    -   Angle between normal and upstream magnetic field
%       thVn    -   Angle between normal and upstream flow
%       nd/nu   -   Density compression rate
%       Bd/Bu   -   Magnetic compression rate, norm(Bd)/norm(Bu)
%       Ma      -   Alfven Mach #, sc frame or NIF
%       Mf      -   Fast Magnetosonic Mach #, sc frame or NIF
%       Ms      -   Sonic Mach #, sc frame or NIF
%       beta_i  -   Upstream ion beta
%       beta_e  -   Upstream electron beta
%
%   IRF_SHOCK_GUI(scd,varName) Also saves a variable, containing normal
%   vectors and plasma parameters, to the Workspace. Variable contains:
%       nvec    -   As returned by irf_shock_normal
%       par     -   As returned by irf_shock_parameters
%       data    -   Up- and downstream values used
% 
%   See also: 
%       IRF_SHOCK_NORMAL, IRF_SHOCK_PARAMETERS, IRF_4_V_GUI, IRF_MINVAR_GUI
%
%   Written by: Andreas Johlander, andreasj@irfu.se
% 
%   TODO: Add legends for components in plot
%       Remove time axis in all but last panel
%       Fix velocity methods
%       Replace uicontrols with text objects



%% Structure of ud:
%   Nin             -   Number of data inputs
%   uih             -   Handles in panels:
%       up  - Upstream panel
%           panel - The panel
%           pb - Push-button
%       dw  - Downstream panel
%           panel - The panel
%           pb - Push-button
%       mt  - Method panel
%           panel - The panel
%           ntx - Normal text
%           npu - Normal pop-up menu
%           vtx - Velocity text
%           vpu - Normal pop-up menu
%       cl  - Shock parameter panel
%           panel - The panel
%           pb - Push-button
%           nvec
%           Vsh
%           thBn
%           thVn
%           r_n
%           r_b
%           Ma
%           Mms
%           Ms
%           beta_i
%           beta_e
% 
%   ax              -   Axis handles, 1xNin array
%   params          -   Parameters to plot (maybe more)
%           Bd
%           Bu
%           Vd
%           Vu
%           nd
%           nu
%   scd             -   Structure containing data, can also be string for
%                       internal use
%   tu              -   Upstream time, interval 1x2 array
%   td              -   Downstream time, interval 1x2 array
%   varName         -   Name of variable in workspace
%   shp             -   Dunno
%   normal_method   -   Method for normal vector
%   vel_method      -   Method for shock velocity
%   mach_method     -   Method for Mach numbers
%   use_omni        -   Boolean for if omni data is used as upstream
%
%   %Others
%   t_start_epoch
%   zoomStack

%% handle input
if ischar(scd)
    % not first call
    ud = get(gcf,'userdata');
    % switch for action
    switch scd
        case 'clu' % click upstream
            ud = clickt(ud,{'u'});
            ud = mark_times(ud);
            ud = get_avg_field(ud,ud.scd,{'u'});
            % Initiate ugly fields to replace omni if needed
            fn = fieldnames(ud.scd);
            for k = 1:length(fn)
                ud.sc_up.([fn{k},'u']) = ud.params.([fn{k},'u']);
            end
            ud = set_omni(ud); % to ensure omni is used if chosen
            ud = display_vals(ud);
            set(gcf,'userdata',ud)
        case 'cld' % click downstream
            ud = clickt(ud,{'d'});
            ud = get_avg_field(ud,ud.scd,{'d'});
            ud = mark_times(ud);
            ud = display_vals(ud);
            set(gcf,'userdata',ud)
        case 'set_met' % click calculate
            ud = set_methods(ud);
            set(gcf,'userdata',ud)
        case 'set_omni'
            ud = set_omni(ud);
            ud = display_vals(ud);
            set(gcf,'userdata',ud)
        case 'plot_omni'
            plot_omni(ud)
        case 'calc' % click calculate
            % time is set between up- and downstream intervals
            ud.params.t = irf_time(mean([ud.tu(2),ud.td(1)]),'epoch>epochtt');
            % set temperatures to NaN if not set
            
            ud.shp.nvec = irf_shock_normal(ud.params);
            ud.shp.par = irf_shock_parameters(ud.params);
            ud.shp.data = ud.params;
            ud = display_prop(ud);
            set(gcf,'userdata',ud)
    end
else
    
    % input names
    fn = fieldnames(scd);
    % sc position is moved
    if ismember('R',fn)
        R = scd.R;
        scd = rmfield(scd,'R');
        fn = fieldnames(scd);
        inpR = 1;
    else
        inpR = 0;
    end
    % number of data inputs
    Nin = numel(fn);
    
    % possible inputs
    poss_inp = {'B','V','n','Ti','Te','R'};
    for k = 1:Nin % remove all fields that are not allowed
        if ~ismember(fn{k},poss_inp)
            irf.log('w',['Removes field ',fn{k},'.']);
            scd = rmfield(scd,fn{k});
            Nin = Nin-1;
        end
    end
    
    % User data that is used everywhere
    ud = [];
    % number of inputs
    ud.Nin = Nin;
    % spacecraft data
    ud.scd = scd;
    % handles to UI elements
    ud.uih = [];

    if nargin == 1 % do not write to workspace if no filename given
        ud.doSave = 0;
    else % if filename is given, save to workspace
        ud.doSave = 1;
        ud.varName = varName;
    end
    % parameters used in calculation
    ud.params = [];
    if inpR
        ud.params.R = R;
    end
    % initiate parameters
    ud.params.Bu = NaN*ones(1,3); ud.params.Bd = NaN*ones(1,3);
    ud.params.nu = NaN; ud.params.nd = NaN;
    ud.params.Vu = NaN*ones(1,3); ud.params.Vd = NaN*ones(1,3);
    ud.params.Tiu = NaN; ud.params.Tid = NaN;
    ud.params.Teu = NaN; ud.params.Ted = NaN;
    % to make omni stuff work
    ud.sc_up.Bu = ud.params.Bu;
    ud.sc_up.nu = ud.params.nu;
    ud.sc_up.Vu = ud.params.Vu;
    ud.sc_up.Tiu = ud.params.Tiu;

    % initiate GUI
    ud = init_gui(ud);
    % set default to not use OMNI, must change in GUI as well if changed
    ud.use_omni.B = 0;
    ud.use_omni.n = 0;
    ud.use_omni.V = 0;
    ud.use_omni.Ti = 0;
    % plot data in panels
    ud = get_avg_field(ud,scd,[]);
    % fix labels
    ud = set_labels(ud);
    % t_start_epoch
    gfud = get(gcf,'userdata');
    ud.t_start_epoch = gfud.t_start_epoch;
    % up/downstream time intervals
    ud.tu = ud.scd.B.time([1,end]).epochUnix;
    ud.td = [ud.tu(1);ud.tu(1)]; % so no interval is shown first
    % normal vector struct
    ud.shp.nvec = [];
    % parameter struct
    ud.shp.par = [];
    % default normal method (if changed, must also change in pop-up menu)
    ud.normal_method = 'mx3';
    % default velocity method (if changed, must also change in pop-up menu)
    ud.vel_method = 'mf';
    % set figure userdata
    set(gcf,'userdata',ud)
end

if ud.doSave % if filename is given, save to workspace
    assignin('base',ud.varName, ud.shp)
end

if nargout == 1 % output
    out = ud.shp;
end

end


function [ud] = init_gui(ud)

% initiate figure
ax = irf_plot(ud.Nin,'newfigure');

ax(1).Position(3) = 0.45;
for k = 1:ud.Nin
    ax(k).Position(1) = 0.1;
end
pause(0.001)
irf_plot_axis_align(ax);
% axis handle array
ud.ax = ax;

%% Upstream panel
% panel
ud.uih.up.panel = uipanel('Units', 'normalized',...
    'position',[0.56 0.91 0.22 0.075],...
    'fontsize',14,...
    'Title','Upstream');
% push button for time 
ud.uih.up.pb = uicontrol('style','push',...
    'Units', 'normalized',...
    'Parent',ud.uih.up.panel,...
    'position',[0.05 0.2 0.8 0.6],...
    'fontsize',14,...
    'string','Click times',...
    'callback','irf_shock_gui(''clu'')');

%% Downstream panel
% panel
ud.uih.dw.panel = uipanel('Units', 'normalized',...
    'position',[0.78 0.91 0.22 0.075],...
    'fontsize',14,...
    'Title','Downstream');
% push button for time 
ud.uih.dw.pb = uicontrol('style','push',...
    'Units', 'normalized',...
    'Parent',ud.uih.dw.panel,...
    'position',[0.05 0.2 0.8 0.6],...
    'fontsize',14,...
    'string','Click times',...
    'callback','irf_shock_gui(''cld'')');

%% OMNI panel
% panel
ud.uih.omni.panel = uipanel('Units', 'normalized',...
    'position',[0.56 0.8 0.44 0.11],...
    'fontsize',14,...
    'Title','Use OMNI as upstream');

% B-field checkbox
ud.uih.omni.pbB = uicontrol('style','checkbox',...
    'Units', 'normalized',...
    'Parent',ud.uih.omni.panel,...
    'position',[0.05 0.7 0.8 0.3],...
    'fontsize',14,...
    'string','B',...
    'callback','irf_shock_gui(''set_omni'')');
% density checkbox
ud.uih.omni.pbN = uicontrol('style','checkbox',...
    'Units', 'normalized',...
    'Parent',ud.uih.omni.panel,...
    'position',[0.25 0.7 0.8 0.3],...
    'fontsize',14,...
    'string','n',...
    'callback','irf_shock_gui(''set_omni'')');
% velocity checkbox
ud.uih.omni.pbV = uicontrol('style','checkbox',...
    'Units', 'normalized',...
    'Parent',ud.uih.omni.panel,...
    'position',[0.50 0.7 0.8 0.3],...
    'fontsize',14,...
    'string','V',...
    'callback','irf_shock_gui(''set_omni'')');
% temperature checkbox
ud.uih.omni.pbTi = uicontrol('style','checkbox',...
    'Units', 'normalized',...
    'Parent',ud.uih.omni.panel,...
    'position',[0.75 0.7 0.8 0.3],...
    'fontsize',14,...
    'string','Ti',...
    'callback','irf_shock_gui(''set_omni'')');

% push button to plot omni data
ud.uih.dw.pb = uicontrol('style','push',...
    'Units', 'normalized',...
    'Parent',ud.uih.omni.panel,...
    'position',[0.05 0.15 0.8 0.5],...
    'fontsize',14,...
    'string','Plot OMNI data',...
    'callback','irf_shock_gui(''plot_omni'')');

%% Method panel
% panel
ud.uih.mt.panel = uipanel('Units', 'normalized',...
    'position',[0.56 0.64 0.44 0.16],...
    'fontsize',14,...
    'Title','Methods');

% normal text
ud.uih.mt.ntx = uicontrol('style','text',...
    'Units', 'normalized',...
    'Parent',ud.uih.mt.panel,...
    'position',[0.05 0.7 0.3 0.2],...
    'fontsize',14,...
    'HorizontalAlignment','left',...
    'string','Normal: ');
% pop-up menu for normal method
ud.uih.mt.npu = uicontrol('style','popupmenu',...
    'Units', 'normalized',...
    'Parent',ud.uih.mt.panel,...
    'position',[0.3 0.7 0.65 0.2],...
    'fontsize',14,...
    'string',{'Magnetic coplanarity','Velocity coplanarity',...
    'Mixed mode 1','Mixed mode 2','Mixed mode 3',...
    '-------','Farris et al.','Slavin & Holzer mean',...
    'Fairfield Meridian 4o','Fairfield Meridian No 4o',...
    'Formisano Unnorm. z = 0'},...
    'Value',5,...
    'Callback','irf_shock_gui(''set_met'')');

% velocity text
ud.uih.mt.vtx = uicontrol('style','text',...
    'Units', 'normalized',...
    'Parent',ud.uih.mt.panel,...
    'position',[0.05 0.4 0.6 0.2],...
    'fontsize',14,...
    'HorizontalAlignment','left',...
    'string','Velocity: ');
% pop-up menu for velocity method
ud.uih.mt.vpu = uicontrol('style','popupmenu',...
    'Units', 'normalized',...
    'Parent',ud.uih.mt.panel,...
    'position',[0.3 0.4 0.65 0.2],...
    'fontsize',14,...
    'string',{'Gosling & Thomsen (Experimental)','Mass flux','Smith & Burton (Experimental)','Moses et al. (Experimental)'},...
    'Value',2,...
    'Callback','irf_shock_gui(''set_met'')');

% velocity text
ud.uih.mt.mtx = uicontrol('style','text',...
    'Units', 'normalized',...
    'Parent',ud.uih.mt.panel,...
    'position',[0.05 0.1 0.6 0.2],...
    'fontsize',14,...
    'HorizontalAlignment','left',...
    'string','Mach #: ');
% pop-up menu for velocity method
ud.uih.mt.mpu = uicontrol('style','popupmenu',...
    'Units', 'normalized',...
    'Parent',ud.uih.mt.panel,...
    'position',[0.3 0.1 0.65 0.2],...
    'fontsize',14,...
    'string',{'Spacecraft','NIF','NIF, Vsh = 0'},...
    'Value',1,...
    'Callback','irf_shock_gui(''set_met'')');

%% Parameter values panel
% panel
ud.uih.par.panel = uipanel('Units', 'normalized',...
    'position',[0.56 0.37 0.44 0.27],...
    'fontsize',14,...
    'Title','Up/downstream values');

% parameters to show
par_name = {'Bu','nu','Vu','Teu','Tiu','Bd','nd','Vd','Ted','Tid'};
par_str = par_name;

% positions of text boxes
nt = length(par_name);
post = zeros(nt,4);
% width
post(:,3) = 0.4;
% height
post(:,4) = 0.15;
% first column left
post(1:ceil(nt/2),1) = 0.05;
% second column left
post(ceil(nt/2)+1:end,1) = 0.505;
% first column up
post(1:ceil(nt/2),2) = fliplr(linspace(0.05,0.8,ceil(nt/2)));
% second column up
post(ceil(nt/2)+1:end,2) = fliplr(linspace(0.05,0.8,nt-ceil(nt/2)));

% make the text boxes
for k = 1:nt
ud.uih.cl.(par_name{k}) = uicontrol('style','text',...
    'Units', 'normalized',...
    'position',post(k,:),...
    'fontsize',14,...
    'Parent',ud.uih.par.panel,...
    'HorizontalAlignment','left',...
    'string',[par_str{k},' = ']);
end

%% Calculate panel
% panel
ud.uih.cl.panel = uipanel('Units', 'normalized',...
    'position',[0.56 0.02 0.44 0.35],...
    'fontsize',14,...
    'Title','Shock & upstream parameters');

% push button
ud.uih.cl.pb = uicontrol('style','push',...
    'Units', 'normalized',...
    'position',[0.2 0.9 0.6 0.1],...
    'fontsize',14,...
    'BackgroundColor',[.85,1,.9],...
    'Parent',ud.uih.cl.panel,...
    'HorizontalAlignment','left',...
    'string','Calculate',...
    'callback','irf_shock_gui(''calc'')');

% parameters to show
par_name = {'n','Vsh','thBn','thVn','r_n','r_b','Ma','Mf','Ms','beta_i','beta_e'};
par_str = par_name;
% "/" is not allowed in variable name
par_str{5} = 'nd/nu'; par_str{6} = 'Bd/Bu';

% positions of text boxes
nt = length(par_name);
post = zeros(nt,4);
% width
post(:,3) = 0.45;
% height
post(:,4) = 0.15;
% first column left
post(1:ceil(nt/2),1) = 0.05;
% second column left
post(ceil(nt/2)+1:end,1) = 0.555;
% first column up
post(1:ceil(nt/2),2) = fliplr(linspace(0.05,0.7,ceil(nt/2)));
% second column up
post(ceil(nt/2)+1:end,2) = fliplr(linspace(0.05,0.7,nt-ceil(nt/2)));

% make the text boxes
for k = 1:nt
ud.uih.cl.(par_name{k}) = uicontrol('style','text',...
    'Units', 'normalized',...
    'position',post(k,:),...
    'fontsize',14,...
    'Parent',ud.uih.cl.panel,...
    'HorizontalAlignment','left',...
    'string',[par_str{k},' = ']);
end

%ud.params = [];

end


function ud = set_labels(ud)
% set ylabels and legends in panels
for k = 1:ud.Nin
    ud.ax(k).YLabel.Interpreter = 'tex';
    switch ud.ax(k).Tag
        case 'B'
            ud.ax(k).YLabel.String = 'B (nT)';
            irf_legend(ud.ax(k),{'B_x','B_y','B_z'},[0.98,0.98])
        case 'V'
            ud.ax(k).YLabel.String = 'V (km/s)';
            irf_legend(ud.ax(k),{'V_x','V_y','V_z'},[0.98,0.98])
        case 'n'
            ud.ax(k).YLabel.String = 'n (cm^{-3})';
        case 'Ti'
            ud.ax(k).YLabel.String = 'Ti (eV)';
        case 'Te'
            ud.ax(k).YLabel.String = 'Te (eV)';
        otherwise
            ud.ax(k).YLabel.String = ':P';
    end
end
end


function [ud] = clickt(ud,str) % click time, str is "u" or "d"
% Give some log, should probably be "mark upstream/downstream"
irf.log('w',['Mark ',num2str(nargout), ' time interval for averaging.'])
% Click times
[t,~] = ginput(2);
t = sort(t);
fig = gcf;
t = t+fig.UserData.t_start_epoch;
ud.(['t',str{1}]) = t;
end


function [ud] = mark_times(ud) % mark times, str is 'u' or 'd'

ucol = [0.7,0.7,0];
dcol = [0,0.7,0.7];
for k = 1:ud.Nin
    delete(findall(ud.ax(k).Children,'Tag','irf_pl_mark'));
end
pause(0.001)

for k = 1:ud.Nin % new feature in axescheck, does not allow handle arrays
    irf_pl_mark(ud.ax(k),ud.tu',ucol)
    irf_pl_mark(ud.ax(k),ud.td',dcol)
end
end


function [ud] = set_methods(ud)
% '--' will crash the program, the order is very important
nmet = {'mc','vc','mx1','mx2','mx3','--',...
    'farris','slho','fa4o','fan4o','foun'};
vmet = {'gt','mf','sb','mo'};

if ud.uih.mt.npu.Value <= 5 || isfield(ud.params,'R') % not a model or with position
    ud.normal_method = nmet{ud.uih.mt.npu.Value};
    ud.vel_method = vmet{ud.uih.mt.vpu.Value};
elseif ud.uih.mt.npu.Value == 6  % -- is not actually a method
    msgbox('Not a method')
else  % if no position and model give error
    msgbox('Model not applicable whith no spacecraft position data in input.',...
            'No position')
end

% special for mach method
if ud.uih.mt.mpu.Value == 1 % spacecraft frame
    ud.params.ref_sys = 'sc';
else% nif
    ud.params.ref_sys = 'nif';
    ud.params.nvec = ud.shp.nvec.n.(ud.normal_method);
    if ud.uih.mt.mpu.Value == 2% Vsh is determined from velocity method
        ud.params.Vsh = ud.shp.nvec.Vsh.(ud.vel_method).(ud.normal_method);
    else % Vsh = 0
        ud.params.Vsh = 0;
    end
end
end


function [ud] = display_vals(ud) % print up/downstream values
% Now displays norm of vectors because it is shorter.

% norm of magnetic field vector
ud.uih.cl.Bu.String = ['Bu = ',num2str(round(norm(ud.params.Bu),2)),' nT'];
ud.uih.cl.Bd.String = ['Bd = ',num2str(round(norm(ud.params.Bd),2)),' nT'];
% destiny
ud.uih.cl.nu.String = ['nu = ',num2str(round(ud.params.nu,2)),' /cc'];
ud.uih.cl.nd.String = ['nd = ',num2str(round(ud.params.nd,2)),' /cc'];
% velocity
ud.uih.cl.Vu.String = ['Vu = ',num2str(round(norm(ud.params.Vu),2)),' km/s'];
ud.uih.cl.Vd.String = ['Vd = ',num2str(round(norm(ud.params.Vd),2)),' km/s'];
% electron temperature
ud.uih.cl.Teu.String = ['Teu = ',num2str(round(ud.params.Teu,2)),' eV'];
ud.uih.cl.Ted.String = ['Ted = ',num2str(round(ud.params.Ted,2)),' eV'];
% ion temperature
ud.uih.cl.Tiu.String = ['Tiu = ',num2str(round(ud.params.Tiu,2)),' eV'];
ud.uih.cl.Tid.String = ['Tid = ',num2str(round(ud.params.Tid,2)),' eV'];
end


function [ud] = display_prop(ud) % write out results

% normal vector
nstr = ['[',num2str(round(ud.shp.nvec.n.(ud.normal_method)(1),2)),',',...
    num2str(round(ud.shp.nvec.n.(ud.normal_method)(2),2)),',',...
    num2str(round(ud.shp.nvec.n.(ud.normal_method)(3),2)),']'];
ud.uih.cl.n.String = ['n = ',nstr];
% shock angle
ud.uih.cl.thBn.String = ['thBn = ',num2str(round(ud.shp.nvec.thBn.(ud.normal_method),2))];
% flow incidence angle
ud.uih.cl.thVn.String = ['thVn = ',num2str(round(ud.shp.nvec.thVn.(ud.normal_method),2))];
% flow incidence angle
ud.uih.cl.thVn.String = ['thVn = ',num2str(round(ud.shp.nvec.thVn.(ud.normal_method),2))];
% density compression ratio
ud.uih.cl.r_n.String = ['nd/nu = ',num2str(round(ud.shp.data.nd/ud.shp.data.nu,2))];
% magnetic compression ratio
ud.uih.cl.r_b.String = ['Bd/Bu = ',num2str(round(norm(ud.shp.data.Bd)/norm(ud.shp.data.Bu),2))];
% Alfven mach
if isfield(ud.shp.par,'Mau')
    ud.uih.cl.Ma.String = ['Ma = ',num2str(round(ud.shp.par.Mau,2))];
end
% MS mach
if isfield(ud.shp.par,'Mfu')
    ud.uih.cl.Mf.String = ['Mf = ',num2str(round(ud.shp.par.Mfu,2))];
end
% sound mach
if isfield(ud.shp.par,'Mfu')
    ud.uih.cl.Ms.String = ['Ms = ',num2str(round(ud.shp.par.Msu,2))];
end
% ion beta
if isfield(ud.shp.par,'biu')
    ud.uih.cl.beta_i.String = ['beta_i = ',num2str(round(ud.shp.par.biu,2))];
end
% electron beta
if isfield(ud.shp.par,'beu')
    ud.uih.cl.beta_e.String = ['beta_e = ',num2str(round(ud.shp.par.beu,2))];
end
% shock speed
ud.uih.cl.Vsh.String = ['Vsh = ',num2str(round(ud.shp.nvec.Vsh.(ud.vel_method).(ud.normal_method),0)),' km/s'];
end


function [ud] = get_avg_field(ud,par,fin)
%AVG_FIELD Calculates average value in a time interval
%   out = AVG_FIELD(ud,par,fin)
%
%   Examples:
%           par =
%               B: [1x1 TSeries]
%
%       >> avg = avg_field(ud,par,{'avg'});
%           out =
%               Bavg: [1.52,2.53,-0.22]
%
% -------------------------------------
%           par =
%               B: [1x1 TSeries]
%               V: [1x1 TSeries]
%
%       >> avg = avg_field(ud,par,{'u','d'});
%           out =
%               Bu: ...
%               Bd: ...
%               Vu: ...
%               Vd: ...

% number of parameter inputs
fnp = fieldnames(par);
nin = numel(fnp);


N = numel(fin);


% Plot all inputs only first time
if isempty(ud.ax(1).Tag)
    for k = 1:nin
        if ~strcmpi(fnp{k},'r')
        irf_plot(ud.ax(k),par.(fnp{k}));
        ud.ax(k).Tag = fnp{k};
        end
    end
end

% align time axis
tint = par.(fnp{1}).time([1,end]); % not optimal
irf_zoom(ud.ax,'x',tint)

% Set color order (this is done twice for some reason)
color_order = zeros(nargout*3,3);
for i = 1:3:nargout*3
    color_order(i:i+2,:) = [0,0,0; 0,0,1; 1,0,0];
end
for k = 1:nin % hack color order 
    ud.ax(k).ColorOrder = color_order;
end

% Nested loop for calculating averages
for i = 1:N
    for k = 1:nin
        % variable
        X = par.(fnp{k});
        % find time indicies
        idt = interp1(X.time.epochUnix,1:length(X.time.epochUnix),ud.(['t',fin{i}]),'nearest');
        % handle out-of-panel clicks
        if isnan(idt(1)) && t(1) < X.time(1).epochUnix
            idt(1) = 1; 
        end
        if isnan(idt(2)) && t(2) > X.time(end).epochUnix
            idt(2) = length(X.time.epochUnix); 
        end
        tinti = X.time(idt).epochUnix';
        hold(ud.ax(k),'on')
        % Calculate average
        x_avg = double(nanmean(X.data(idt(1):idt(2),:)));
        % Plot average as solid lines lines
        delete(findall(ud.ax(k).Children,'Tag',['avg_mark',fin{i}]))
        irf_plot(ud.ax(k),[tinti',[x_avg;x_avg]],'Tag',['avg_mark',fin{i}])
        ud.ax(k).ColorOrder = color_order;
        ud.params.([fnp{k},fin{i}]) = x_avg;
    end
end
if ~isempty(ud.params)
    ud.params = orderfields(ud.params);
end
end


function [ud] = set_omni(ud)
% sets OMNI-valu as the average value in the upstream time interval (entire
% interval if not set)
ud.use_omni.B = ud.uih.omni.pbB.Value;
ud.use_omni.n = ud.uih.omni.pbN.Value;
ud.use_omni.V = ud.uih.omni.pbV.Value;
ud.use_omni.Ti = ud.uih.omni.pbTi.Value;


% Read omni data if not already done and if a box is checked
if ~isfield(ud,'omnidata') && (ud.use_omni.B || ud.use_omni.n || ud.use_omni.V || ud.use_omni.Ti)
    irf.log('w','Reading OMNI data from internet...')
    ud.omnidata = [];
    tint = ud.scd.B.time([1,end])+[-60,60]*5; % set time interval +- 5 mins
    ud.omnidata = irf_get_data(tint,'bx,by,bz,n,vx,vy,vz,t','omni_min');
    % Re-correct Vy for abberation
    ud.omnidata(:,6) = ud.omnidata(:,6)+29.8; 
    % change temperature units from K to eV
    u = irf_units;
    ud.omnidata(:,9) = ud.omnidata(:,9)*u.kB/u.e; 
    irf.log('w','Done reading OMNI data.')
end

if ud.use_omni.B
    Bomni = mean(irf_resamp(ud.omnidata(:,1:4),ud.tu),1);
    ud.params.Bu = Bomni(2:4); 
else; ud.params.Bu = ud.sc_up.Bu; 
end
if ud.use_omni.n
    nomni = mean(irf_resamp(ud.omnidata(:,[1,5]),ud.tu),1);
    ud.params.nu = nomni(2); 
else; ud.params.nu = ud.sc_up.nu; 
end
if ud.use_omni.V
    Vomni = mean(irf_resamp(ud.omnidata(:,[1,6:8]),ud.tu),1);
    ud.params.Vu = Vomni(2:4); 
else; ud.params.Vu = ud.sc_up.Vu; 
end
if ud.use_omni.Ti
    Tomni = mean(irf_resamp(ud.omnidata(:,[1,9]),ud.tu),1);
    ud.params.Tiu = Tomni(2);
else; ud.params.Tiu = ud.sc_up.Tiu; 
end
end


function [] = plot_omni(ud)
h = irf_plot(4,'newfigure');

hca = irf_panel(h,'B');
irf_plot(hca,ud.omnidata(:,1:4))
ylabel(hca,'B (nT)')
irf_legend(hca,{'B_x','B_y','B_z'},[0.98,0.98])
hold(hca,'on')
irf_plot(hca,[ud.tu,[ud.params.Bu;ud.params.Bu]])

hca = irf_panel(h,'n_i');
irf_plot(hca,ud.omnidata(:,[1,5]))
ylabel(hca,'n (cm^{-3})')
hold(hca,'on')
irf_plot(hca,[ud.tu,[ud.params.nu;ud.params.nu]])

hca = irf_panel(h,'V');
irf_plot(hca,ud.omnidata(:,[1,6:8])) 
ylabel(hca,'V (km/s)')
irf_legend(hca,{'V_x','V_y','V_z'},[0.98,0.98])
hold(hca,'on')
irf_plot(hca,[ud.tu,[ud.params.Vu;ud.params.Vu]])

hca = irf_panel(h,'T');
irf_plot(hca,ud.omnidata(:,[1,9]))% needs SI
ylabel(hca,'Ti (eV)')
hold(hca,'on')
irf_plot(hca,[ud.tu,[ud.params.Tiu;ud.params.Tiu]])

for i = 1:4
    irf_pl_mark(h(i),ud.tu',[0.7,0.7,0])
end

end
