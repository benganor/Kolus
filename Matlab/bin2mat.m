function bin2mat(tag)
%BIN2MAT converts binary data into matlab data for kolus data type
% tag.Rates = 250e3; %if rates not SET
f_skip = nansum(tag.Rates(:) * tag.refresh_time);
Rates = tag.Rates(:) * tag.refresh_time;

%%%%READING
f_name = tag.file_dat;
  underscores = strfind(f_name, '_');
    dots = strfind(f_name, '.');
f_dat = dir([f_name(1:underscores(end)) '*.dat']);
tag.file_dat = f_dat.name;
tag.file_mat = strrep(f_dat.name, '.dat', '.mat');
tag.Block = str2num(f_name(underscores(end)+1:dots(1)-1));
display([tag.file_dat '  ' tag.file_mat])

f_id = fopen(tag.file_dat, 'r');
f_content = fread(f_id,  'double');
fclose(f_id);
total_size = f_skip*ceil(length(f_content)/f_skip);
%%%zero-pad if data was not fully recorded
if  total_size > length(f_content)
    f_content = [f_content ; zeros(total_size-length(f_content), 1)];
end
f_content = reshape(f_content, f_skip, ceil(length(f_content)/f_skip));

start_index = 1;
data = cell(1, length(Rates));
for i = 1:length(Rates)
data{i} = f_content(start_index:(start_index - 1 + Rates(i)), :);
start_index = Rates(i) + 1;

end

%cases where only partial data at end of session
%%%%

under_write = sum(isnan(f_content(:,end)));
underRates = round(Rates * (under_write/f_skip));
if under_write
    warning('partial data at end of session - nothing guranteed');
    start_index = 1;
    for i = 1:length(Rates)
        data{i}(:, end) = [];
        data{i} = data{i}(:);
        data{i} = [data{i}; f_content(start_index: ...
            ((start_index-1) + underRates(i)), end)];
        start_index = underRates(i) + 1;
    end
end

%  %COLUMN vector with ' are more native to matlab
% for i = 1:length(Rates)
%    data{i} = data{i}(:);
% end
 
var_names = tag.Channels(logical(tag.type_Ch));

for i = 1:length(Rates)
  %generally bad to dynamically create variables, but speeds up signal load time
  %load is almost never in a for loop, as specific data needs specific processing
eval(['sig_' var_names{i}(1:4) ' = data{i}(:); '])
eval(['save(tag.file_mat, ''sig_' var_names{i}(1:4) , ''', ''-nocompression'', ''-append''); ']);
end

save(tag.file_mat, 'tag', '-append');