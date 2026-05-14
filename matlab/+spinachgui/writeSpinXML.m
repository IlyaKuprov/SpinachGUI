function writeSpinXML(model, filename)
%WRITESPINXML Export the current model in SpinXML/SXML form.

fid = fopen(filename, 'w');
if fid < 0
    error('spinachgui:OpenFailed', 'Could not open %s for writing.', filename);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '<?xml version="1.0" encoding="utf-8"?>\n');
fprintf(fid, '<spin_system>\n');
for k = 1:height(model.Atoms)
    atom = model.Atoms(k,:);
    isotope = isotopeLabel(atom.Mass, atom.Element);
    fprintf(fid, '  <spin id="%d" isotope="%s" label="%s">\n', atom.ID, xmlEscape(isotope), xmlEscape(atom.Label));
    fprintf(fid, '    <coordinates x="%.12g" y="%.12g" z="%.12g" />\n', atom.X, atom.Y, atom.Z);
    fprintf(fid, '  </spin>\n');
end
for k = 1:height(model.ReferenceFrames)
    frame = model.ReferenceFrames(k,:);
    matrix = frame.Matrix{1};
    if isnan(frame.ParentID)
        fprintf(fid, '  <reference_frame id="%d" label="%s">\n', frame.ID, xmlEscape(frame.Label));
    else
        fprintf(fid, '  <reference_frame id="%d" label="%s" parent_id="%d">\n', frame.ID, xmlEscape(frame.Label), frame.ParentID);
    end
    fprintf(fid, '    <dcm xx="%.12g" xy="%.12g" xz="%.12g" yx="%.12g" yy="%.12g" yz="%.12g" zx="%.12g" zy="%.12g" zz="%.12g" />\n', matrix.');
    fprintf(fid, '  </reference_frame>\n');
end
interactions = model.positiveInteractions();
for k = 1:height(interactions)
    inter = interactions(k,:);
    matrix = inter.Matrix{1};
    fprintf(fid, '  <interaction kind="%s" id="%d" units="%s" spin_a="%d" spin_b="%d" reference_frame_id="%g" reference="%s">\n', ...
        xmlEscape(lower(inter.Kind)), inter.ID, xmlEscape(inter.Unit), inter.A, inter.B, inter.ReferenceFrameID, xmlEscape(inter.Reference));
    fprintf(fid, '    <tensor xx="%.12g" xy="%.12g" xz="%.12g" yx="%.12g" yy="%.12g" yz="%.12g" zx="%.12g" zy="%.12g" zz="%.12g" />\n', matrix.');
    fprintf(fid, '  </interaction>\n');
end
fprintf(fid, '</spin_system>\n');
end

function out = isotopeLabel(mass, element)
if mass > 0 && element ~= "e" && element ~= "chi"
    out = sprintf('%d%s', mass, element);
elseif element == "e"
    out = 'E';
else
    out = char(element);
end
end

function out = xmlEscape(value)
out = char(string(value));
out = strrep(out, '&', '&amp;');
out = strrep(out, '<', '&lt;');
out = strrep(out, '>', '&gt;');
out = strrep(out, '"', '&quot;');
end
