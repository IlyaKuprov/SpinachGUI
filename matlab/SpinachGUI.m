function app = SpinachGUI(varargin)
%SPINACHGUI MATLAB R2026a front end for SpinachGUI.
%   APP = SPINACHGUI() opens the MATLAB rewrite of the historical
%   SpinachGUI WinForms application.  APP = SPINACHGUI(FILE) opens and
%   imports FILE when its format is currently supported by the MATLAB port.

app = spinachgui.App(varargin{:});
if nargout == 0
    clear app
end
end
