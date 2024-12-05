classdef compareKinematicsUI
properties
    % 1 or 2, monitor to display plot on
    mon_num;

    data_path;

    selection;

    % force and moment axes labels used in dropdown box
    range;

    Flapperoo;
    MetaBird;
    sel_bird;

    sel_angle;
    sel_freq;
    sel_speed;

    % booleans
    st;
end

methods
    function obj = compareKinematicsUI(mon_num, data_path)
        obj.mon_num = mon_num;
        obj.data_path = data_path;

        obj.selection = strings(0);
        obj.range = [-16 16];
        obj.Flapperoo = flapper("Flapperoo");
        obj.MetaBird = flapper("MetaBird");
        
        obj.sel_bird = obj.Flapperoo;
        obj.sel_freq = obj.sel_bird.freqs(1);
        obj.sel_speed = obj.sel_bird.speeds(1);
        obj.sel_angle = obj.sel_bird.angles(1);

        obj.st = false;
    end

    function dynamic_plotting(obj)

        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);
       
        screen_height = screen_size(4);
        unit_height = round(0.03*screen_height);
        unit_spacing = round(0.005*screen_height);

        % Dropdown box for flapper selection
        drop_y1 = screen_height - round(0.06*screen_height);
        d1 = uidropdown(option_panel);
        d1.Position = [10 drop_y1 180 30];
        d1.Items = ["Flapperoo", "MetaBird"];

        % Dropdown box for angle of attack selection
        drop_y2 = drop_y1 - (unit_height + unit_spacing);
        d2 = uidropdown(option_panel);
        d2.Position = [10 drop_y2 180 30];
        d2.Items = obj.sel_bird.angles + " deg";
        d2.ValueChangedFcn = @(src, event) angle_change(src, event);

        % Dropdown box for wingbeat frequency selection
        drop_y3 = drop_y2 - (unit_height + unit_spacing);
        d3 = uidropdown(option_panel);
        d3.Position = [10 drop_y3 180 unit_height];
        d3.Items = obj.sel_bird.freqs;
        d3.ValueChangedFcn = @(src, event) freq_change(src, event);

        % Dropdown box for wind speed selection
        drop_y4 = drop_y3 - (unit_height + unit_spacing);
        d4 = uidropdown(option_panel);
        d4.Position = [10 drop_y4 180 unit_height];
        d4.Items = obj.sel_bird.speeds + " m/s";
        d4.ValueChangedFcn = @(src, event) speed_change(src, event);

        % FIX THIS LINE
        d1.ValueChangedFcn = @(src, event) flapper_change(src, event, d2, d3);

        % Button to add entry defined by selected type,
        % frequency, angle, and speed to list of plotted cases
        button2_y = drop_y4 - (unit_height + unit_spacing);
        b2 = uibutton(option_panel);
        b2.Position = [15 button2_y 80 unit_height];
        b2.Text = "Add entry";

        % Button to remove entry defined by selected type,
        % frequency, angle, and speed from list of plotted cases
        b3 = uibutton(option_panel);
        b3.Position = [105 button2_y 80 unit_height];
        b3.Text = "Delete entry";

        % List of cases currently displayed on the plots
        list_y = button2_y - (4*(unit_height + unit_spacing) + unit_spacing);
        lbox = uilistbox(option_panel);
        lbox.Items = strings(0);
        lbox.Position = [10 list_y 180 4*(unit_height + unit_spacing)];

        b2.ButtonPushedFcn = @(src, event) addToList(src, event, plot_panel, lbox);
        b3.ButtonPushedFcn = @(src, event) removeFromList(src, event, plot_panel, lbox);

        button3_y = list_y - (unit_height + unit_spacing);
        b4 = uibutton(option_panel,"state");
        b4.Text = "St Scaling";
        b4.Position = [20 button3_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ValueChangedFcn = @(src, event) st_change(src, event, plot_panel);

        obj.update_plot(plot_panel);

        %-----------------------------------------------------%
        %-----------------------------------------------------%
        % Callback functions to respond to user inputs. These
        % functions must be nested inside this function otherwise
        % they will reference the object snapshot at the time the
        % callback function was defined rather than updating with
        % the object
        %-----------------------------------------------------%
        %-----------------------------------------------------%

        % update type variable with new value selected by user
        function flapper_change(src, ~, type_box, speed_box)
            if (src.Value == "Flapperoo")
                obj.sel_bird = obj.Flapperoo;
            elseif (src.Value == "MetaBird")
                obj.sel_bird = obj.MetaBird;
            else
                error("This bird selection is not recognized.")
            end
            type_box.Items = obj.sel_bird.types;
            speed_box.Items = obj.sel_bird.speeds + " m/s";

            obj.sel_type = nameToType(obj.sel_bird.name, obj.sel_bird.types(1));
            obj.sel_speed = obj.sel_bird.speeds(1);

            type_box.Value = obj.sel_bird.types(1);
            speed_box.Value = obj.sel_bird.speeds(1) + " m/s";
        end

        % update angle variable with new value selected by user
        function angle_change(src, ~)
            obj.sel_angle = str2double(extractBefore(src.Value, " deg"));
        end

        % update frequency variable with new value selected by user
        function freq_change(src, ~)
            obj.sel_freq = src.Value;
        end

        % update speed variable with new value selected by user
        function speed_change(src, ~)
            speed = str2double(extractBefore(src.Value, " m/s"));
            obj.sel_speed = speed;
        end
    
        function addToList(~, ~, plot_panel, lbox)
            sel_name = compareStabilityUI.typeToSel(obj.sel_bird.name, obj.sel_type);
            speed = obj.sel_speed + "m.s";
            folder = sel_name + " " + speed;
            case_name = obj.sel_bird.name + "/" + strrep(folder, " ", "_");

            if (sum(strcmp(string(lbox.Items), case_name)) == 0)
                lbox.Items = [lbox.Items, case_name];
                obj.selection = [obj.selection, case_name];
            end
            obj.update_plot(plot_panel);
        end

        function removeFromList(~, ~, plot_panel, lbox)
            case_name = lbox.Value;
            % removing value from list that's displayed
            new_list_indices = string(lbox.Items) ~= case_name;
            lbox.Items = lbox.Items(new_list_indices);

            % removing value from object's list
            new_list_indices = obj.selection ~= case_name;
            obj.selection = obj.selection(new_list_indices);
            obj.update_plot(plot_panel);
        end

        function st_change(src, ~, plot_panel)
            if (src.Value)
                obj.st = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.st = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        %-----------------------------------------------------%
        %-----------------------------------------------------%
        
    end
end

methods(Static, Access = private)

    function [sub_title, abbr_sel] = get_abbr_names(sel)
        sub_title = "";
        abbr_sel = "";
        if (isscalar(sel))
            abbr_sel = strrep(strrep(sel, "_", " "), "/", " ");
        elseif (length(sel) > 1)
        flappers = [];
        types = [];
        speeds = [];
        freqs = [];

        for i = 1:length(sel)
            flapper_name = string(extractBefore(sel(i), "/"));
            dir_name = string(extractAfter(sel(i), "/"));
            
            dir_parts = split(dir_name, '_');
            type = strjoin(dir_parts(1:end-1));
            wind_speed = sscanf(dir_parts(end), '%g', 1);

            flappers = [flappers flapper_name];
            types = [types type];
            speeds = [speeds wind_speed];
        end

        num_uniq_flappers = length(unique(flappers));
        num_uniq_types = length(unique(types));
        num_uniq_speeds = length(unique(speeds));

        % For attributes shared by all cases, add to sub_title
        if (num_uniq_flappers == 1)
            sub_title = sub_title + flapper_name + " ";
        end
        if (num_uniq_types == 1)
            sub_title = sub_title + type + " ";
        end
        if (num_uniq_speeds == 1)
            sub_title = sub_title + wind_speed + " m/s ";
        end

        for i = 1:length(sel)
            flapper_name = string(extractBefore(sel(i), "/"));
            dir_name = string(extractAfter(sel(i), "/"));
            
            dir_parts = split(dir_name, '_');
            type = strjoin(dir_parts(1:end-1)) + " ";
            wind_speed = dir_parts(end) + " ";

            if (num_uniq_flappers == 1)
                flapper_name = "";
            end
            if (num_uniq_types == 1)
                type = "";
            end
            if (num_uniq_speeds == 1)
                wind_speed = "";
            end

            cur_abbr_sel = flapper_name + type + wind_speed;
            abbr_sel(i) = cur_abbr_sel;
        end
        end
    end

    function idx = findClosestStString(strToMatch, strList)
        cur_St = str2double(extractAfter(strToMatch, "St: ")); % fails for v2 cases
        available_Sts = [];
        for k = 1:length(strList)
            St_num = str2double(extractAfter(strList(k), "St: "));
            if (~isnan(St_num))
                available_Sts = [available_Sts St_num];
            end
        end
        [M, I] = min(abs(available_Sts - cur_St));
        idx = I;
        disp("Closest match to St: " + cur_St + " is St: " + available_Sts(I))
    end
end

methods (Access = private)
    function update_plot(obj, plot_panel)
        delete(plot_panel.Children)
        
        struct_matches = get_file_matches(obj.selection, obj.norm, obj.shift, obj.drift, obj.sub, obj.Flapperoo, obj.MetaBird);
        disp("Found following matches:")
        disp(struct_matches)

        if (length(struct_matches) ~= length(obj.selection))
            disp("--------------------------------------------")
            disp("Oops looks like a data file is missing")
            disp("--------------------------------------------")
        end

        if (obj.plot_type == 1 || obj.plot_type == 2)
            if (obj.st)
                x_label = "Strouhal Number";
            else
                x_label = "Wingbeat Frequency (Hz)";
            end
        else
            if (obj.plot_type == 3)
                x_label = "COM Position (% chord)";
            elseif (obj.plot_type == 4)
                x_label = "Static Margin (% chord)";
            end
        end

        if (obj.plot_type == 1 || obj.plot_type == 3 || obj.plot_type == 4)
            if (obj.norm)
                y_label = "Normalized Pitch Stability Slope";
            else
                y_label = "Pitch Stability Slope";
            end
        elseif (obj.plot_type == 2)
            if (obj.norm)
                y_label = "Normalized Equilibrium Angle (deg)";
            else
                y_label = "Equilibrium Angle (deg)";
            end
        end

        if (~isempty(obj.selection))
        unique_dir = [];
        unique_speeds = [];
        unique_types = [];
        for j = 1:length(obj.selection)
            flapper_name = string(extractBefore(obj.selection(j), "/"));
            dir_name = string(extractAfter(obj.selection(j), "/"));

            if (obj.sub)
                dir_parts = split(dir_name, '_');
                dir_parts(2) = "Sub";
                dir_name = strjoin(dir_parts, "_");
            end

            dir_parts = split(dir_name, '_');
            wind_speed = sscanf(dir_parts(end), '%g', 1);
            type = strjoin(dir_parts(1:end-1));

            if(isempty(unique_speeds) || sum(unique_speeds == wind_speed) == 0)
                unique_speeds = [unique_speeds wind_speed];
            end
            if(isempty(unique_types) || sum(unique_types == type) == 0)
                unique_types = [unique_types type];
            end
            if(isempty(unique_dir) || sum([unique_dir.dir_name] == dir_name) == 0)
                data_struct.dir_name = dir_name;
                unique_dir = [unique_dir data_struct];
            end
        end

        colors = getColors(1, length(unique_types), length(unique_speeds), length(obj.selection));
        end
        [sub_title, abbr_sel] = compareStabilityUI.get_abbr_names(obj.selection);

        % -----------------------------------------------------
        % -------------------- Plotting -----------------------
        % -----------------------------------------------------
        ax = axes(plot_panel);
        hold(ax, 'on');

        if (obj.plot_type == 3 || obj.plot_type == 4)
            % sequential colors
            map = ["#ccebc5"; "#a8ddb5"; "#7bccc4"; "#43a2ca"; "#0868ac"];
            % map = ["#fef0d9"; "#fdcc8a"; "#fc8d59"; "#e34a33"; "#b30000"];
            % diverging colors
            % map = ["#d7191c"; "#fdae61"; "#ffffbf"; "#abdda4"; "#2b83ba"];
            map = hex2rgb(map);
            xquery = linspace(0,1,128);
            numColors = size(map);
            numColors = numColors(1);
            map = interp1(linspace(0,1,numColors), map, xquery,'pchip');
            cmap = colormap(ax, map);

            if (obj.st)
                minSt = 0;
                maxSt = 0.5;
                zmap = linspace(minSt, maxSt, length(cmap));
                clim(ax, [minSt, maxSt])
                cb = colorbar(ax);
                ylabel(cb,'Strouhal Number','FontSize',16,'Rotation',270)
            else
                minFreq = 0;
                maxFreq = 5;
                zmap = linspace(minFreq, maxFreq, length(cmap));
                clim(ax, [minFreq, maxFreq])
                cb = colorbar(ax);
                ylabel(cb,'Wingbeat Frequency','FontSize',16,'Rotation',270)
            end
        end

        last_t_ind = 0;
        last_s_ind = 0;
        for i = 1:length(obj.selection)
            for j = 1:length(struct_matches)
                if (obj.selection(i) == struct_matches(j).selector)
                    cur_struct_match = struct_matches(j);
                    break;
                end
            end

            flapper_name = string(extractBefore(obj.selection(i), "/"));
            dir_name = string(extractAfter(obj.selection(i), "/"));

            cur_bird = getBirdFromName(flapper_name, obj.Flapperoo, obj.MetaBird);

            dir_parts = split(dir_name, '_');

            if (obj.sub)
                dir_parts = split(dir_name, '_');
                dir_parts(2) = "Sub";
                dir_name = strjoin(dir_parts, "_");
            end

            dir_parts = split(dir_name, '_');
            wind_speed = sscanf(dir_parts(end), '%g', 1);
            s_ind = find(unique_speeds == wind_speed);

            type = strjoin(dir_parts(1:end-1));
            t_ind = find(unique_types == type);

            lim_AoA_sel = cur_bird.angles(cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2));
            
            % Load associated norm_factors file, used for COM
            % plot where normalization can only be done after
            % shifting pitch moment
            if (obj.plot_type == 3 || obj.plot_type == 4)
            norm_factors_path = obj.data_path + "/plot data/" + cur_bird.name + "/norm_factors/";
            norm_factors_filename = compareStabilityUI.get_norm_factors_name(norm_factors_path, cur_struct_match.dir_name);

            cur_file = norm_factors_path + norm_factors_filename;
            disp("Loading " + cur_file)
            load(cur_file, "norm_factors")

            % Also strip norm from filename as we want to hand
            % findCOMrange the non-normalized data
            if (obj.norm)
                parsed_name = erase(extractBefore(cur_struct_match.file_name, "_saved"), "_norm");
                for k = 1:length(cur_bird.file_list)
                    cur_struct = cur_bird.file_list(k);
                    if (cur_struct.dir_name == parsed_name)
                        cur_struct_match.file_name = cur_struct.file_name;
                    end
                end
            end
            end

            cur_file = obj.data_path + "/plot data/" + cur_bird.name + "/" + cur_struct_match.file_name;
            disp("Loading " + cur_file)
            load(cur_file, "avg_forces", "err_forces")
            lim_avg_forces = avg_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);
            lim_err_forces = err_forces(:,cur_bird.angles >= obj.range(1) & cur_bird.angles <= obj.range(2),:);

            if cur_bird.name == "Flapperoo"
                if (wind_speed == 6)
                    wing_freqs_str = cur_bird.freqs(1:end-4);
                else
                    wing_freqs_str = cur_bird.freqs(1:end-2);
                end
            elseif cur_bird.name == "MetaBird"
                wing_freqs_str = cur_bird.freqs;
            end
            wing_freqs = str2double(extractBefore(wing_freqs_str, " Hz"));

            % Skip gliding case
            % wing_freqs = wing_freqs(wing_freqs ~= 0);
            % wing_freqs = wing_freqs(wing_freqs ~= 0.1);

            slopes = [];
            x_intercepts = [];
            err_slopes = [];
            for k = 1:length(wing_freqs)
                idx = 5; % pitch moment
                x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
                y = lim_avg_forces(idx,:,k)';
                b = x\y;
                model = x*b;
                % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
                SE_slope = (sum((y - model).^2) / (sum((lim_AoA_sel - mean(lim_AoA_sel)).^2)*(length(lim_AoA_sel) - 2)) ).^(1/2);
                x_int = - b(1) / b(2);

                slopes = [slopes b(2)];
                err_slopes = [err_slopes SE_slope];
                x_intercepts = [x_intercepts x_int];

                if (obj.plot_type == 3 || obj.plot_type == 4)
                    [center_to_LE, chord, ~, ~, ~] = getWingMeasurements(cur_bird.name);
                    [distance_vals_chord, static_margin, slopes_pos] = ...
                        findCOMrange(lim_avg_forces(:,:,k), lim_AoA_sel, center_to_LE, chord, obj.norm, norm_factors);
                    
                    if (obj.plot_type == 3)
                        x_vals = distance_vals_chord;
                    elseif (obj.plot_type == 4)
                        x_vals = static_margin;
                    end

                    if (obj.st)
                    St = freqToSt(cur_bird.name, wing_freqs(k), wind_speed, obj.data_path, -1);
                    line_color = interp1(zmap, cmap, St);
                    % slopes_pos = slopes_pos / (wing_freqs(k));
                    else
                    line_color = interp1(zmap, cmap, wing_freqs(k));
                    end

                    line = plot(ax, x_vals, slopes_pos);
                    line.LineWidth = 2;
                    line.HandleVisibility = 'off';
                    line.Color = line_color;
                end
            end
            
            % Get Quasi-Steady Model Force
            % Predictions
            mod_slopes = [];
            mod_x_intercepts = [];
            if (obj.aero_model)
                if (obj.amplitudes)
                    amplitude_list = [pi/12, pi/6, pi/4, pi/3];
                else
                    amplitude_list = -1;
                end

                mod_slopes = zeros(length(amplitude_list), length(wing_freqs));
                mod_x_intercepts = zeros(length(amplitude_list), length(wing_freqs));

                AR = 2*cur_bird.AR;

                if obj.thinAirfoil
                    lift_slope = ((2*pi) / (1 + 2/AR));
                    pitch_slope = -lift_slope / 4;
                else
                    % Find slopes for all wind speeds and average
                    path = obj.data_path + "/plot data/" + cur_bird.name;
                    [lift_slope, pitch_slope] = getGlideSlopes(path, cur_bird, cur_struct_match.dir_name, obj.range);
                end

                for j = 1:length(amplitude_list)
                amp = amplitude_list(j);

                for k = 1:length(wing_freqs)
                wing_freq = wing_freqs(k);

                aero_force = get_model(cur_bird.name, obj.data_path, lim_AoA_sel, wing_freq, wind_speed, lift_slope, pitch_slope, AR, amp);

                idx = 5; % pitch moment
                x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
                y = aero_force(idx,:)';
                b = x\y;
                % model = x*b;
                % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
                x_int = - b(1) / b(2);

                mod_slopes(j,k) = b(2);
                mod_x_intercepts(j,k) = x_int;
                end
                end
            end

            if (obj.plot_type == 1 || obj.plot_type == 2)

            if (obj.st)
                x_vals = zeros(1,length(wing_freqs));
                for k = 1:length(wing_freqs)
                    x_vals(k) = freqToSt(cur_bird.name, wing_freqs(k), wind_speed, obj.data_path, -1);
                end

                if (obj.aero_model)
                x_vals_mod = zeros(length(amplitude_list),length(wing_freqs));
                for j = 1:length(amplitude_list)
                    for k = 1:length(wing_freqs)
                        x_vals_mod(j,k) = freqToSt(cur_bird.name, wing_freqs(k), wind_speed, obj.data_path, amplitude_list(j));
                    end
                end
                end
            else
                x_vals = wing_freqs;
                if (obj.aero_model)
                x_vals_mod = zeros(length(amplitude_list),length(wing_freqs));
                for j = 1:length(amplitude_list)
                    x_vals_mod(j,:) = x_vals;
                end
                end
            end

            if (obj.plot_type == 1)
                y_vals = slopes;
                err_vals = err_slopes;
                y_mod_vals = mod_slopes;
            elseif (obj.plot_type == 2)
                y_vals = x_intercepts;
                err_vals = zeros(1,length(x_intercepts));
                y_mod_vals = mod_x_intercepts;
            end
            
            e = errorbar(ax, x_vals, y_vals, err_vals, '.');
            e.MarkerSize = 25;
            e.Color = colors(s_ind, t_ind);
            e.MarkerFaceColor = colors(s_ind, t_ind);
            e.DisplayName = abbr_sel(i);
            
            % ---------Plotting model-----------
            % aerodynamics model is nondimensionalized, so
            % data should also be nondimensionalized when
            % comparing the two. Also only occurs if
            % frequency or wind speed have changed
            if (obj.norm && obj.aero_model)
                marker_list = ["o", "square", "^", "v"];
                if (obj.amplitudes)
                for j = 1:length(amplitude_list)
                    s = scatter(ax, x_vals_mod(j,:), y_mod_vals(j,:), 40);
                    s.MarkerEdgeColor = colors(s_ind, t_ind);
                    s.LineWidth = 2;
                    s.DisplayName = "A = " + rad2deg(amplitude_list(j)) + ", Model: " + abbr_sel(i);
                    s.Marker = marker_list(j);
                end
                else
                    s = scatter(ax, x_vals_mod, y_mod_vals, 40);
                    s.MarkerEdgeColor = colors(s_ind, t_ind);
                    s.LineWidth = 2;
                    s.DisplayName = "Model: " + abbr_sel(i);
                end
            end
            end

        end

        title(ax, sub_title);
        xlabel(ax, x_label);
        ylabel(ax, y_label)
        grid(ax, 'on');
        if ~(obj.plot_type == 3 || obj.plot_type == 4)
            l = legend(ax, Location="best");
        end
        ax.FontSize = 18;

        if (obj.saveFig)
            filename = "saved_figure.fig";
            fignew = figure('Visible','off'); % Invisible figure
            if (exist("l", "var"))
                copyobj([l ax], fignew); % Copy the appropriate axes
            elseif (exist("cb", "var"))
                copyobj([ax cb], fignew); % Copy the appropriate axes
            else
                copyobj(ax, fignew); % Copy the appropriate axes
            end

            % set(fignew, 'Position', [200 200 800 600])
            set(fignew,'CreateFcn','set(gcbf,''Visible'',''on'')'); % Make it visible upon loading
            savefig(fignew,filename);
            delete(fignew);
        end
    end
end
end