classdef arduinoManager < optickaCore
	%ARDUINOMANAGER Connects and manages arduino communication, uses matlab
	%hardware package
	properties
		port char			= ''
		board char			= ''
		silentMode logical	= false %this allows us to be called even if no arduino is attached
		verbose				= true
		openGUI	logical		= true
		mode char			= 'original' %original is built-in, otherwise needs matlab hardware package
		rewardPin double	= 2
		rewardTime double	= 150
		availablePins cell	= {2,3,4,5,6,7,8,9,10,11,12,13}; %UNO board
	end
	properties (SetAccess = private, GetAccess = public)
		ports 
		isOpen logical = false
		device = []
		deviceID = ''
	end
	properties (SetAccess = private, GetAccess = private)
		handles = []
		screen screenManager
		allowedProperties char ='mode|port|silentMode|verbose'
	end
	methods%------------------PUBLIC METHODS--------------%
		
		%==============CONSTRUCTOR============%
		function me = arduinoManager(varargin)
			if nargin>0
				me.parseArgs(varargin,me.allowedProperties);
			end
			if isempty(me.port)
				me.ports = seriallist;
				if ~isempty(me.ports)
					fprintf('--->arduinoManager: Ports available: %s\n',me.ports);
					if isempty(me.port); me.port = char(me.ports{end}); end
				else
					me.comment = 'No Serial Ports are available, going into silent mode';
					fprintf('--->arduinoManager: %s\n',me.comment);
					me.silentMode = true;
				end
			end
			switch me.mode
				case 'original'
					if ~exist('arduinoLegacy','file')
						me.comment = 'Cannot find arduinoLegacy, check opticka path!';
						warning(me.comment)
						me.silentMode = true;
					end
				otherwise
					if ~exist('arduino','file')
						me.comment = 'You need to Install Arduino Support files!';
						warning(me.comment)
						me.silentMode = true;
					end
			end
		end
		
		%===============OPEN DEVICE================%
		function open(me)
            if me.isOpen;disp('-->arduinoManager: Already open!');return;end
			close(me); me.ports = seriallist;
			if me.silentMode==false && isempty(me.device)
				try
					switch me.mode
						case 'original'
							if ~isempty(me.port)
								if IsWin && ~isempty(regexp(me.port, '^/dev/', 'once'))
									warning('--->arduinoManager: Linux/macOS port specified but running on windows!')
									me.port = '';
								elseif (IsLinux||IsOSX) && ~isempty(regexp(me.port, '^COM', 'once'))
									warning('--->arduinoManager: Windows port specified but running on Linux/macOS!')
									me.port = '';
								end
								me.device = arduinoLegacy(me.port);
								me.board = 'Generic';
								me.deviceID = me.port;
								me.availablePins = {2,3,4,5,6,7,8,9,10,11,12,13}; %UNO board
								for i = me.availablePins{1} : me.availablePins{end}
									me.device.pinMode(i,'output');
									me.device.digitalWrite(i,0);
								end
								me.isOpen = true;
							else
								warning('--->arduinoManager: Please specify the port to use, going into silent mode!')
								me.isOpen = false; me.silentMode = true;
							end
							
						otherwise
							if ~isempty(me.port)
								me.device = arduino(me.port);
							else
								me.device = arduino;
							end
							me.port = me.device.Port;
							me.board = me.device.Board;
							me.deviceID = me.device.Port;
							me.availablePins = me.device.AvailablePins;
							for i = 2:13
								configurePin(me.device,['D' num2str(i)],'unset')
								writeDigitalPin(me.device,['D' num2str(i)],0);
							end
							me.isOpen = true;
					end
					if me.openGUI; GUI(me); end
					me.silentMode = false;
				catch ME
					me.silentMode = true; me.isOpen = false;
					fprintf('\n\nCouldn''t open Arduino: %s\n',ME.message)
					getReport(ME)
				end
			elseif ~isempty(me.device)
				fprintf('--->>> arduinoManager: arduino appears open already...\n');
			else
				fprintf('--->>> arduinoManager open: silentMode engaged...\n');
			end
		end
		
		%===============ANALOG WRITE================%
		function analogWrite(me,line,value)
			if me.silentMode == false
				if ~exist('line','var') || isempty(line); line = me.rewardPin; end
				if ~exist('value','var') || isempty(value); value = 255; end
				analogWrite(me.device, line, value);
			end			
		end
		
		%===============SEND TTL (legacy)================%
		function sendTTL(me, line, time)
			timedTTL(me, line, time)
		end
		
		%===============TIMED TTL================%
		function timedTTL(me, line, time)
			if me.silentMode==false
				if ~exist('line','var') || isempty(line); line = me.rewardPin; end
				if ~exist('time','var') || isempty(time); time = me.rewardTime; end
				switch me.mode
					case 'original'
						timedTTL(me.device, line, time);
						%digitalWrite(me.device, line, 1);
						%WaitSecs(time/1e3);
						%digitalWrite(me.device, line, 0);
					otherwise
						time = time - 30; %there is an arduino 30ms delay
						if time < 0; time = 0; end
						writeDigitalPin(me.device,['D' num2str(line)],1);
						WaitSecs(time/1e3);
						writeDigitalPin(me.device,['D' num2str(line)],0);
				end	
				if me.verbose;fprintf('===>>> REWARD GIVEN: TTL pin %i for %i ms\n',line,time);end
			else
				if me.verbose;fprintf('===>>> REWARD GIVEN: Silent Mode\n');end
			end
		end
		
		%===============TIMED DOUBLE TTL================%
		function timedDoubleTTL(me, line, time)
			if me.silentMode==false
				if ~exist('line','var') || isempty(line); line = me.rewardPin; end
				if ~exist('time','var') || isempty(time); time = me.rewardTime; end
				if ~strcmp(me.mode,'original')
					time = time - 30; %there is an arduino 30ms delay
				end
				if time < 0; time = 0;end
				switch me.mode
					case 'original'
						timedTTL(me.device, line, 10);
						WaitSecs('Yieldsecs',time/1e3);
						timedTTL(me.device, line, 10);
% 						digitalWrite(me.device, line, 1);
% 						WaitSecs(0.01);
% 						digitalWrite(me.device, line, 0);
% 						WaitSecs(time/1e3);
% 						digitalWrite(me.device, line, 1);
% 						WaitSecs(0.01);
% 						digitalWrite(me.device, line, 0);
					otherwise
						writeDigitalPin(me.device,['D' num2str(line)],1);
						WaitSecs(0.03);
						writeDigitalPin(me.device,['D' num2str(line)],0);
						WaitSecs(time/1e3);
						writeDigitalPin(me.device,['D' num2str(line)],1);
						WaitSecs(0.03);
						writeDigitalPin(me.device,['D' num2str(line)],0);
				end
				
				if me.verbose;fprintf('===>>> REWARD GIVEN: double TTL pin %i for %i ms\n',line,time);end
			else
				if me.verbose;fprintf('===>>> REWARD GIVEN: Silent Mode\n');end
			end
		end
		
		%===============TEST TTL================%
		function test(me,line)
			if me.silentMode || isempty(me.device); return; end
			if ~exist('line','var') || isempty(line); line = 2; end
			switch me.mode
				case 'original'
					digitalWrite(me.device, line, 0);
					for ii = 1:20
						digitalWrite(me.device, line, mod(ii,2));
					end
				otherwise
					writeDigitalPin(me.device,['D' num2str(line)],0);
					for ii = 1:20
						writeDigitalPin(me.device,['D' num2str(line)],mod(ii,2));
					end
			end
		end
		
		%===============Manual Reward GUI================%
		function GUI(me)
			if me.silentMode; return; end
			if ~isempty(me.handles) && isfield(me.handles,'parent') && ishandle(me.handles.parent)
				disp('--->>> arduinoManager: GUI already open...\n')
				return;
			end
			
			bgcolor = [0.91 0.91 0.91];
			bgcoloredit = [0.95 0.95 0.95];
			if ismac
				SansFont = 'Avenir next';
				MonoFont = 'Menlo';
			elseif ispc
				SansFont = 'calibri';
				MonoFont = 'consolas';
			else %linux
				SansFont = 'Liberation Sans';
				MonoFont = 'Liberation Mono';
			end
			
			handles.parent = figure('Tag','aFig',...
				'Name', 'arduinoManager GUI', ...
				'MenuBar', 'none', ...
				'Color', bgcolor, ...
				'Position',[0 0 210 140],...
				'NumberTitle', 'off');
			
			handles.value = uicontrol('Style','edit',...
				'Parent',handles.parent,...
				'Tag','RewardValue',...
				'String',200,...
				'FontName',MonoFont,...
				'FontSize', 12,...
				'Position',[5 115 95 25],...
				'BackgroundColor',bgcoloredit);
			
			handles.t1 = uicontrol('Style','text',...
				'Parent',handles.parent,...
				'String','Time (ms)',...
				'FontName',SansFont,...
				'FontSize', 8,...
				'Position',[10 95 90 20],...
				'BackgroundColor',bgcolor);
			
			handles.pin = uicontrol('Style','edit',...
				'Parent',handles.parent,...
				'Tag','RewardPin',...
				'String',2,...
				'FontName',MonoFont,...
				'FontSize', 12,...
				'Position',[110 115 95 25],...
				'BackgroundColor',bgcoloredit);
			
			handles.t1 = uicontrol('Style','text',...
				'Parent',handles.parent,...
				'String','Pin',...
				'FontName',SansFont,...
				'FontSize', 8,...
				'Position',[105 95 90 20],...
				'BackgroundColor',bgcolor);
			
			handles.menu = uicontrol('Style','popupmenu',...
				'Parent',handles.parent,...
				'Tag','TTLMethod',...
				'String',{'Single TTL','Double TTL'},...
				'Value',1,...
				'Position',[5 80 195 20],...
				'BackgroundColor',bgcolor);
			
			handles.readButton = uicontrol('Style','pushbutton',...
				'Parent',handles.parent,...
				'Tag','goButton',...
				'Callback',@doReward,...
				'FontName',SansFont,...
				'ForegroundColor',[1 0 0],...
				'FontSize',18,...
				'Position',[5 5 115 60],...
				'String','REWARD!');
			
			handles.loopButton = uicontrol('Style','pushbutton',...
				'Parent',handles.parent,...
				'Tag','l1Button',...
				'Callback',@doLoop,...
				'FontName',SansFont,...
				'ForegroundColor',[1 0.5 0],...
				'FontSize',18,...
				'Position',[120 5 40 60],...
				'String','L1');
			
			handles.loop2Button = uicontrol('Style','pushbutton',...
				'Parent',handles.parent,...
				'Tag','l2Button',...
				'Callback',@doLoop2,...
				'FontName',SansFont,...
				'ForegroundColor',[1 0.5 0],...
				'FontSize',18,...
				'Position',[160 5 40 60],...
				'String','L2');
			
			me.handles = handles;
			
			function doReward(varargin)
				if me.silentMode || ~me.isOpen; disp('Not open!'); return; end
				val = str2num(get(me.handles.value,'String'));
				pin = str2num(get(me.handles.pin,'String'));
				method = get(me.handles.menu,'Value');
				if method == 1
					try
						me.timedTTL(pin,val);
					end
				elseif method == 2
					try
						me.timedDoubleTTL(pin,val);
					end
				end
			end
			
			function doLoop(varargin)
				if me.silentMode || ~me.isOpen; disp('Not open!'); return; end
				fprintf('===>>> Entering Loop mode, press 0 to exit!!!\n');
				set(handles.loopButton,'ForegroundColor',[0.2 0.7 0]);drawnow;
				pin = str2num(get(me.handles.pin,'String'));
				nl = [];
				for nn = 0:9
					nl = [nl KbName(num2str(nn))];
				end
				oldkeys=RestrictKeysForKbCheck(nl);
				doLoop = true;
				ListenChar(2);
				while doLoop
					[~, keyCode] = KbWait(-1);
					if any(keyCode)
						rchar = KbName(keyCode); if iscell(rchar);rchar=rchar{1};end
						switch lower(rchar)
							case {'0'}
								doLoop = false;
							case{'1'}
								me.timedTTL(pin,100);
							case{'2'}
								me.timedTTL(pin,200);
							case{'3'}
								me.timedTTL(pin,300);
							case{'4'}
								me.timedTTL(pin,400);
							case{'5'}
								me.timedTTL(pin,500);
							case{'6'}
								me.timedTTL(pin,600);
							case{'7'}
								me.timedTTL(pin,700);
							case{'8'}
								me.timedTTL(pin,800);
						end
					end
					WaitSecs(0.2);
				end
				ListenChar(0);
				fprintf('===>>> Exit pressed!!!\n');
				RestrictKeysForKbCheck(oldkeys);
				set(handles.loopButton,'ForegroundColor',[1 0.5 0]);
			end
			
			function doLoop2(varargin)
				if me.silentMode || ~me.isOpen; disp('Not open!'); return; end
				fprintf('===>>> Entering Loop mode, press 0 to exit!!!\n');
				set(handles.loop2Button,'ForegroundColor',[0.2 0.7 0]);drawnow;
				pin = str2num(get(me.handles.pin,'String'));
				nl = [];
				for nn = 0:9
					nl = [nl KbName(num2str(nn))];
				end
				oldkeys=RestrictKeysForKbCheck(nl);
				doLoop = true;
				ListenChar(2);
				while doLoop
					[~, keyCode] = KbWait(-1);
					if any(keyCode)
						rchar = KbName(keyCode); if iscell(rchar);rchar=rchar{1};end
						switch lower(rchar)
							case {'0'}
								doLoop = false;
							case{'1'}
								me.timedTTL(pin,100);
							case{'2'}
								me.timedTTL(pin,200);
							case{'3'}
								me.timedTTL(pin,300);
							case{'4'}
								me.timedTTL(pin,400);
							case{'5'}
								me.timedTTL(pin,500);
							case{'6'}
								me.timedTTL(pin,600);
							case{'7'}
								me.timedTTL(pin,700);
							case{'8'}
								me.timedTTL(pin,800);
						end
					end
					WaitSecs(0.2);
				end
				ListenChar(0);
				fprintf('===>>> Exit pressed!!!\n');
				RestrictKeysForKbCheck(oldkeys);
				set(handles.loop2Button,'ForegroundColor',[1 0.5 0]);
			end
		end
		
		%===============CLOSE PORT================%
		function close(me)
			try;close(me.handles.parent);me.handles=[];end
			me.device = [];
			me.deviceID = '';
			me.availablePins = '';
			me.isOpen = false;
			me.ports = seriallist;
			%me.silentMode = false;
		end
		
		%===============RESET================%
		function reset(me)
			close(me);
			me.silentMode = false;
		end
		
	end
	
	methods ( Access = private ) %----------PRIVATE METHODS---------%
		
		
		
		%===========Delete Method==========%
		function delete(me)
			fprintf('arduinoManager Delete method will automagically close connection if open...\n');
			me.close;
		end
		
	end
	
end