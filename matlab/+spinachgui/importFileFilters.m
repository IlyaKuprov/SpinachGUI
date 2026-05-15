function filters = importFileFilters()
%IMPORTFILEFILTERS File-open filters used by the SpinachGUI import dialog.
%   Keeping the specification in one place makes the App wiring testable
%   without scraping callback source text.

filters = {'*.sxml;*.xml;*.xyz;*.mol;*.log;*.out;*.magres;*.coo', ...
    'Supported files (*.sxml, *.xml, *.xyz, *.mol, *.log, *.out, *.magres, *.coo)'; ...
    '*.*', 'All files'};
end
