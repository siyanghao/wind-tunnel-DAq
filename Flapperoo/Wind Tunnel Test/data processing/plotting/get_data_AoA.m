function [avg_forces, err_forces, names, sub_title, norm_factors_arr] = ...
    get_data_AoA(selected_vars, processed_data_path, offsets_path, nondimensional, sub_strings, shift_bool)

sub_drift = true;

if (sub_strings(1) == "")
    body_subtraction = false;
else
    body_subtraction = true;
end

AoA_sel = selected_vars.AoA;
wing_freq_sel = selected_vars.freq;
wind_speed_sel = selected_vars.wind;
type_sel = selected_vars.type;

% produces array of same size as wing_freq_sel but with the
% frequency of each value in its place, ex:
% [0, 2, 4, 2, 4] -> [1, 2, 2, 2, 2]
wing_freq_sel_count = wing_freq_sel;
for i = 1:length(wing_freq_sel)
    wing_freq_sel_count(i) = sum(wing_freq_sel == wing_freq_sel(i));
end

% Initialize variables
avg_forces = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
% avg_forces_body = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel));
err_forces = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
cases_final = strings(length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
names = strings(length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
norm_factors_arr = zeros(2, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel));
% really only the windspeed matters here but let's include all
% the variables include the normalization routine changes in the
% future

sub_title = "";

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

% Go through each file, grab its data, take the mean over all results to
% produce a "dot" (i.e. a single point value) for each force and moment
for i = 1 : length(theFiles)
    baseFileName = theFiles(i).name;
    [case_name, time_stamp, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
    
    type = convertCharsToStrings(type);
    
%     pitch = deg2rad(-AoA);
%     yaw = deg2rad(205);
%     dcm_F = angle2dcm(yaw, pitch, 0,'ZYX');
%     dcm_M = angle2dcm(yaw, 0, 0, 'ZYX');
    
    if (ismember(wing_freq, wing_freq_sel) ...
    && ismember(AoA, AoA_sel) ...
    && ismember(wind_speed, wind_speed_sel) ...
    && ismember(type, type_sel))

        wing_freq_ind = wing_freq_sel == wing_freq;

        modFileName = baseFileName;

        % Check if any other files were recorded for the same set
        % of parameters but at a different time
        count = 0;
        timestamps_str = {};
        timestamps_val = [];
        for m = 1 : length(theFiles)
            baseFileName = theFiles(m).name;
            if (contains(baseFileName, case_name))
                count = count + 1;
                time_str = extractBefore(extractAfter(baseFileName, case_name), ".mat");
                split_time_str = split(time_str);
                h_m_s = split_time_str(2);
                split_h_m_s = str2double(split(h_m_s, "-"));
                if (split_h_m_s(1) < 6)
                    split_h_m_s(1) = split_h_m_s(1) + 12;
                end
                time_val = split_h_m_s(1)*3600 + split_h_m_s(2)*60 + split_h_m_s(3);

                timestamps_str = [timestamps_str; time_str];
                timestamps_val = [timestamps_val; time_val];
            end
        end

        [B,I] = sort(timestamps_val);
        timestamps_str_sorted = timestamps_str(I);
        cur_time_index = find(timestamps_str_sorted == time_stamp);

        num_repeat_freqs = wing_freq_sel_count(find(wing_freq_sel == wing_freq, 1, 'first'));

        disp("Obtaining data for " + type + " " + wing_freq + " Hz " + wind_speed + " m/s "  + AoA + " deg trial")
        if (count > 1) % counted multiple repeats in datastream
        if (num_repeat_freqs == count)
            % num_repeat_freqs > 1 && cur_time_index > length(timestamps_str) - num_repeat_freqs
            wing_freq_ind = find(wing_freq_sel == wing_freq);
            wing_freq_ind = wing_freq_ind(cur_time_index);

            disp("Found " + count + " files, timestamps: " + timestamps_str)
            disp("    Using current timestamp: " + time_stamp)
            disp(" ")
        else
            disp("Extra files found and current file too old, moving on...")
            continue
            % wing_freq_ind = wing_freq_sel == wing_freq;
            % 
            % modFileName = case_name + string(timestamps_str_sorted(end)) + ".mat";
            % 
            % disp("Found " + count + " files, timestamps: " + timestamps_str)
            % disp("    Using last timestamp: " + timestamps_str_sorted(end))
            % disp(" ")
        end
        end

        load(processed_data_path + modFileName);

        if (sub_drift)
            [drift] = get_drift(modFileName, offsets_path);
        end

        if (shift_bool)
        [mod_filtered_data] = shiftPitchMoment(filtered_data, AoA);
        filtered_data = mod_filtered_data;
        end

        plot_data = filtered_data;
        norm_plot_data = dimensionless(filtered_data, norm_factors);
        % plot_data = force_data;
        % norm_plot_data = dimensionless(force_data, norm_factors);
        
        norm_factors_arr(:, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed) = norm_factors;

        sub_term = zeros(1,6);
        if (body_subtraction)
            forces_body_list = zeros(length(sub_strings),6);
            sub_bools = ones(length(sub_strings));
            for j = 1:length(sub_strings)
                sub_string = sub_strings(j);
                case_parts = strtrim(split(sub_string));
                if (case_parts(1) == "-")
                    sub_bools(j) = false;
                    sub_string = strjoin(case_parts(2:end));
                end
                forces_body = getBody(wing_freq, AoA, wind_speed, nondimensional, ...
                    theFiles, processed_data_path, sub_string, sub_bools(j), shift_bool);
                forces_body_list(j,:) = mean(forces_body,2);
                
                if (sub_bools(j) == true)
                    sub_term = sub_term + forces_body_list(j,:);
                else
                    sub_term = sub_term - forces_body_list(j,:);
                end
            end
        end

        if (nondimensional)
            forces = norm_plot_data;
        else
            forces = plot_data;
        end

        for k = 1:6
            if (body_subtraction)
                % if (length(forces_body) > length(forces))
                %     wing_forces = forces - forces_body(:,1:length(forces));
                % else
                %     wing_forces = forces(:,1:length(forces_body)) - forces_body;
                % end
                % avg_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                %         = mean(wing_forces);

                avg_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                            = mean(forces(k,:)) - sub_term(k);
            elseif (sub_drift)
                avg_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                            = mean(forces(k,:)) - drift(k);
            else
                avg_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                    = mean(forces(k,:));
            end

            if (wing_freq == 0)
                if (nondimensional)
                    % err_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                    %     = std(norm_plot_data(k,:));
                    cycle_avg_norm = dimensionless(squeeze(cycle_avg_forces), norm_factors);
                    err_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                        = std(cycle_avg_norm(k, :));
                else
                    % err_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                    %     = std(plot_data(k, :));
                    cycle_avg = squeeze(cycle_avg_forces);
                    err_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                        = std(cycle_avg(k, :));
                end
            else
                if (nondimensional)
                    % wingbeat_std_forces_norm = dimensionless(wingbeat_std_forces, norm_factors);
                    % err_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                    %     = mean(wingbeat_std_forces_norm(k, :));
                    cycle_avg_forces_norm = dimensionless(cycle_avg_forces, norm_factors);
                    err_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                        = std(cycle_avg_forces_norm(k, :));
                else
                    % err_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                    %     = mean(wingbeat_std_forces(k, :));
                    err_forces(k, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type)...
                        = std(cycle_avg_forces(k, :));
                end
            end
        end

%         avg_forces(1:3, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) ...
%                     = (dcm_F * avg_forces_temp(1:3, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type));
%         avg_forces(4:6, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) ...
%                     = (1 * dcm_M * avg_forces_temp(4:6, AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type));
        
        cases_final(AoA_sel == AoA, wing_freq_ind, wind_speed_sel == wind_speed, type_sel == type) = modFileName;
        

        [names, sub_title] = get_labels(names, selected_vars, wing_freq_ind, wing_freq, wind_speed, type, Re, St, nondimensional, body_subtraction);

    end
    percent_done = round((i / length(theFiles))*100, 2);
    disp(percent_done + "% Done")
end   

end

function [forces_body] = getBody(wing_freq_sel, AoA_sel, wind_speed_sel, ...
    nondimensional, theFiles, processed_data_path, sub_string, sub_bool, shift_bool)

    % Parse relevant information from subtraction string
    case_parts = strtrim(split(sub_string));
    sub_type = "";
    sub_wing_freq = wing_freq_sel;
    sub_wind_speed = wind_speed_sel;
    index = length(case_parts) + 1;
    for j=1:length(case_parts)
        if (contains(case_parts(j), "Hz"))
            sub_wing_freq = str2double(erase(case_parts(j), "Hz"));
            if index ~= -1
                index = j;
            end
        elseif (contains(case_parts(j), "m.s"))
            sub_wind_speed = str2double(erase(case_parts(j), "m.s"));
            if index ~= -1
                index = j;
            end
        end
    end
    sub_type = strjoin(case_parts(1:index-1)); % speed is first thing after type

    if (sub_bool)
        sub_state = "Subtracting";
    else
        sub_state = "Adding";
    end

    disp(sub_state + " data from " + sub_type + " " + sub_wing_freq + " Hz " + sub_wind_speed + " m/s "  + AoA_sel + " deg trial")

    for j = 1 : length(theFiles)
        baseFileName = theFiles(j).name;
        [case_name, time_stamp, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
        
        type = convertCharsToStrings(type);

        if (type == sub_type ...
        && wing_freq == sub_wing_freq ...
        && AoA == AoA_sel ...
        && wind_speed == sub_wind_speed)

        load(processed_data_path + baseFileName);

        if (shift_bool)
        [mod_filtered_data] = shiftPitchMoment(filtered_data, AoA);
        filtered_data = mod_filtered_data;
        end

        norm_filtered_data = dimensionless(filtered_data, norm_factors);

        if (nondimensional)
            forces_body = norm_filtered_data;
        else
            forces_body = filtered_data;
        end

        end
    end

end