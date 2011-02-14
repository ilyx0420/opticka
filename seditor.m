classdef seditor < handle
	%UNTITLED Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		handles
		fn
		stim
		cprop
		ckind
	end
	
	methods
		function obj = seditor(stimin)
			if exist('stimin','var')
				obj.stim = stimin;
			end
			obj.handles = struct();
			obj.buildgui;
			if ~isempty(obj.stim)
				obj.fn = fieldnames(obj.stim);
				set(obj.handles.StimEditorPropertyList,'String',obj.fn);
			end
			obj.StimEditorPropertyList_Callback;
		end
		
		function buildgui(obj)
			% Creation of all uicontrols
			
			% --- FIGURE -------------------------------------
			obj.handles.figure1 = figure( ...
				'Tag', 'figure1', ...
				'Units', 'pixels', ...
				'Position', [727 663 285 161], ...
				'Name', 'seditor', ...
				'MenuBar', 'none', ...
				'NumberTitle', 'off', ...
				'Color', [0.85 0.85 0.85]);
			
			% --- PUSHBUTTONS -------------------------------------
			obj.handles.StimEditorCancel = uicontrol( ...
				'Parent', obj.handles.figure1, ...
				'Tag', 'StimEditorCancel', ...
				'Style', 'pushbutton', ...
				'Units', 'pixels', ...
				'Position', [165 11 70 29], ...
				'FontName', 'Helvetica', ...
				'FontSize', 10, ...
				'String', 'Cancel', ...
				'Callback', @obj.StimEditorCancel_Callback);
			
			obj.handles.StimEditorOK = uicontrol( ...
				'Parent', obj.handles.figure1, ...
				'Tag', 'StimEditorOK', ...
				'Style', 'pushbutton', ...
				'Units', 'pixels', ...
				'Position', [30 11 70 29], ...
				'FontName', 'Helvetica', ...
				'FontSize', 10, ...
				'String', 'OK', ...
				'Callback', @obj.StimEditorOK_Callback);
			
			% --- EDIT TEXTS -------------------------------------
			obj.handles.StimEditorEdit = uicontrol( ...
				'Parent', obj.handles.figure1, ...
				'Tag', 'StimEditorEdit', ...
				'Style', 'edit', ...
				'Units', 'pixels', ...
				'Position', [15 72 251 44], ...
				'FontName', 'Helvetica', ...
				'FontSize', 14, ...
				'BackgroundColor', [0.941 0.941 0.941], ...
				'String', '0', ...
				'Callback', @obj.StimEditorEdit_Callback);
			
			% --- POPUP MENU -------------------------------------
			obj.handles.StimEditorPropertyList = uicontrol( ...
				'Parent', obj.handles.figure1, ...
				'Tag', 'StimEditorPropertyList', ...
				'Style', 'popupmenu', ...
				'Units', 'pixels', ...
				'Position', [3 118 277 35], ...
				'FontName', 'Helvetica', ...
				'FontSize', 10, ...
				'BackgroundColor', [1 1 1], ...
				'String', '0', ...
				'Callback', @obj.StimEditorPropertyList_Callback);
			
			% --- EDIT TEXTS -------------------------------------
			obj.handles.StimEditorText = uicontrol( ...
				'Parent', obj.handles.figure1, ...
				'Tag', 'StimEditorText', ...
				'Style', 'text', ...
				'Units', 'pixels', ...
				'Position', [15 44 251 20], ...
				'FontName', 'Helvetica', ...
				'FontSize', 10, ...
				'BackgroundColor', [0.85 0.85 0.85], ...
				'String', 'Number');
			
		end
	
		%% ---------------------------------------------------------------------------
		function StimEditorCancel_Callback(obj,hObject,evendata) %#ok<INUSD>
			close(obj.handles.figure1)
		end
		
		%% ---------------------------------------------------------------------------
		function StimEditorOK_Callback(obj,hObject,evendata) %#ok<INUSD>
			close(obj.handles.figure1)
		end
		
		%% ---------------------------------------------------------------------------
		function StimEditorEdit_Callback(obj,hObject,evendata) %#ok<INUSD>
			s=get(hObject,'String');
			switch obj.ckind
				case 'number'
					s=str2num(s);
					obj.stim.(obj.cprop) = s;
				case 'logical'
					s=str2num(s);
					if s > 0
						s=true;
					else
						s=false;
					end
					obj.stim.(obj.cprop) = s;
				case 'string'
					obj.stim.(obj.cprop) = s;
			end
			if isappdata(0,'o')
				o = getappdata(0,'o');
				o.modifyStimulus;
			end
		end
		
		%% ---------------------------------------------------------------------------
		function StimEditorPropertyList_Callback(obj,hObject,evendata) %#ok<INUSD>
			v=get(obj.handles.StimEditorPropertyList,'Value');
			s=get(obj.handles.StimEditorPropertyList,'String');
			obj.cprop=s{v};
			editvalue = obj.stim.(obj.cprop);
			if isnumeric(editvalue)
				obj.ckind='number';
				editvalue = num2str(editvalue);
				set(obj.handles.StimEditorText,'String','Number')
			elseif islogical(editvalue)
				obj.ckind='logical';
				editvalue = num2str(editvalue);
				set(obj.handles.StimEditorText,'String','Logical')
			else
				obj.ckind = 'string';
				set(obj.handles.StimEditorText,'String','String')
			end
			set(obj.handles.StimEditorEdit,'String',editvalue);
		end
		
	end
	
end

