classdef compareAoAUI
properties
    % 1 or 2, monitor to display plot on
    mon_num;
    selection;
    index;
    % force and moment axes labels used in dropdown box
    axes_labels;
    range;
    angles;
    speeds;
    freqs;

    norm;
    shift;
    drift;
    regress;
    aero_model;

    file_list;
    uniq_list;
    uniq_norm_list;
    norm_list;
    shift_list;
    drift_list;
end

methods
    function obj = compareAoAUI(mon_num)
        obj.mon_num = mon_num;
        obj.selection = strings(0);
        obj.index = 0;
        obj.axes_labels = ["All", "Drag", "Transverse Lift", "Lift",...
            "Roll Moment", "Pitch Moment", "Yaw Moment"];
        obj.range = [-16 16];
        obj.angles = [-16:1.5:-13 -12:1:-9 -8:0.5:8 9:1:12 13:1.5:16];
        obj.speeds = [3, 4, 5, 6];
        obj.freqs = [0, 0.1, 2, 2.5, 3, 3.5, 3.75, 4, 4.5, 5];
        
        obj.norm = false;
        obj.regress = false;
        obj.shift = false;
        obj.drift = false;
        obj.aero_model = false;

        obj.file_list = [];
        obj.uniq_list = [];
        obj.norm_list = [];
        obj.shift_list = [];
        obj.drift_list = [];

        data_path = "../plot data/";
        % Get a list of all files in the folder with the desired file name pattern.
        filePattern = fullfile(data_path, '*.mat');
        theFiles = dir(filePattern);
        
        % Grab each file and process the data from that file, storing the results
        for k = 1 : length(theFiles)
            baseFileName = convertCharsToStrings(theFiles(k).name);
            parsed_name = extractBefore(baseFileName, "_saved");

            [data_struct] = compareAoAUI.get_file_structure(baseFileName, parsed_name);
            obj.file_list = [obj.file_list data_struct];

            case_name = extractBefore(baseFileName, "._");

            % Add to list if not already on list
            if (isempty(obj.uniq_list) || sum([obj.uniq_list.dir_name] == case_name) == 0)
                [data_struct] = compareAoAUI.get_file_structure(baseFileName, case_name);
                data_struct.file_name = [];
                obj.uniq_list = [obj.uniq_list data_struct];
            end

            if (contains(parsed_name, "norm"))
                data_struct = compareAoAUI.get_file_structure(baseFileName, parsed_name);
                obj.norm_list = [obj.norm_list data_struct];
            end
            if (contains(parsed_name, "shift"))
                data_struct = compareAoAUI.get_file_structure(baseFileName, parsed_name);
                obj.shift_list = [obj.shift_list data_struct];
            end
            if (contains(parsed_name, "drift"))
                data_struct = compareAoAUI.get_file_structure(baseFileName, parsed_name);
                obj.drift_list = [obj.drift_list data_struct];
            end
        end
        uniq_norm_list_str = setdiff(setdiff([obj.norm_list.file_name], [obj.shift_list.file_name]), [obj.drift_list.file_name]);
        for j = 1:length(obj.file_list)
            if (sum(uniq_norm_list_str == obj.file_list(j).file_name) > 0)
                struct_match = obj.file_list(j);
                struct_match.dir_name = extractBefore(struct_match.dir_name, "_norm");
                obj.uniq_norm_list = [obj.uniq_norm_list struct_match];
            end
        end
    end

    function dynamic_plotting(obj)

        % Create a GUI figure with a grid layout
        [option_panel, plot_panel, screen_size] = setupFig(obj.mon_num);
       
        screen_height = screen_size(4);
        unit_height = round(0.03*screen_height);
        unit_spacing = round(0.005*screen_height);

        tree_y = screen_height - round(0.5*screen_height);
        tree_h = round(0.47*screen_height);
        t = uitree(option_panel,'checkbox');
        t.Position = [10 tree_y 180 tree_h];
        % Assign callback in response to node selection
        t.CheckedNodesChangedFcn = @(src, event) select(src, event, plot_panel);
        for i = 1:length(obj.uniq_list)
            data_struct = obj.uniq_list(i);
            parent = uitreenode(t, 'Text', data_struct.dir_name);

            for j = 1:length(data_struct.trial_names)
                child = uitreenode(parent, 'Text', data_struct.trial_names(j));
            end
        end

        drop_y = tree_y - (unit_height + unit_spacing);
        d1 = uidropdown(option_panel);
        d1.Position = [10 drop_y 180 unit_height];
        d1.Items = obj.axes_labels;
        d1.ValueChangedFcn = @(src, event) index_change(src, event, plot_panel);

        button1_y = drop_y - (unit_height + unit_spacing);
        b1 = uibutton(option_panel,"state");
        b1.Text = "Normalize";
        b1.Position = [20 button1_y 160 unit_height];
        b1.BackgroundColor = [1 1 1];
        b1.ValueChangedFcn = @(src, event) norm_change(src, event, plot_panel, t);

        button2_y = button1_y - (unit_height + unit_spacing);
        b2 = uibutton(option_panel,"state");
        b2.Text = "Regression";
        b2.Position = [20 button2_y 160 unit_height];
        b2.BackgroundColor = [1 1 1];
        b2.ValueChangedFcn = @(src, event) regress_change(src, event, plot_panel);

        button3_y = button2_y - (unit_height + unit_spacing);
        b3 = uibutton(option_panel,"state");
        b3.Text = "Shift Pitch Moment";
        b3.Position = [20 button3_y 160 unit_height];
        b3.BackgroundColor = [1 1 1];
        b3.ValueChangedFcn = @(src, event) shift_change(src, event, plot_panel, d1);

        button4_y = button3_y - (unit_height + unit_spacing);
        b4 = uibutton(option_panel,"state");
        b4.Text = "Drift Correction";
        b4.Position = [20 button4_y 160 unit_height];
        b4.BackgroundColor = [1 1 1];
        b4.ValueChangedFcn = @(src, event) drift_change(src, event, plot_panel);

        button5_y = button4_y - (unit_height + unit_spacing);
        b5 = uibutton(option_panel,"state");
        b5.Text = "Aerodynamics Model";
        b5.Position = [20 button5_y 160 unit_height];
        b5.BackgroundColor = [1 1 1];
        b5.ValueChangedFcn = @(src, event) model_change(src, event, plot_panel);

        AoA_y = 0.05*screen_height;
        s = uislider(option_panel,"range");
        s.Position = [10 AoA_y 180 3];
        s.Limits = obj.range;
        s.Value = obj.range;
        s.MajorTicks = [-16 -12 -8 -4 0 4 8 12 16];
        s.MinorTicks = [-14.5 -13 -11:1:-9 -7.5:0.5:-4.5 -3.5:0.5:-0.5 0.5:0.5:3.5 4.5:0.5:7.5 9:1:11 13 14.5];
        s.ValueChangedFcn = @(src, event) AoA_change(src, event, plot_panel);

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

        function select(~, event, plot_panel)
            % event.SelectedNodes.Text
            % event.Source.CheckedNodes
            
            % Get the selected nodes
            selectedNodes = event.CheckedNodes;

            obj.selection = strings(0);
                
            for i = 1:length(selectedNodes)
                % Get the parent node
                parentNode = selectedNodes(i).Parent;

                cur_node_str = convertCharsToStrings(selectedNodes(i).Text);
                full_str = parentNode.Text + "/" + cur_node_str;
                obj.selection = [obj.selection full_str];
            end
    
            obj.update_plot(plot_panel);
        end
    
        function index_change(src, ~, plot_panel)
            obj.index = find(obj.axes_labels == src.Value) - 1;
            obj.update_plot(plot_panel);
        end

        function norm_change(src, ~, plot_panel, t)
            if (src.Value)
                obj.norm = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                compareAoAUI.update_tree(t, obj.uniq_norm_list);
            else
                obj.norm = false;
                src.BackgroundColor = [1 1 1];
                compareAoAUI.update_tree(t, obj.uniq_list);
            end

            % update selected nodes
            selectedNodes = t.CheckedNodes;

            obj.selection = strings(0);
                
            for i = 1:length(selectedNodes)
                % Get the parent node
                parentNode = selectedNodes(i).Parent;

                cur_node_str = convertCharsToStrings(selectedNodes(i).Text);
                full_str = parentNode.Text + "/" + cur_node_str;
                obj.selection = [obj.selection full_str];
            end

            obj.update_plot(plot_panel);
        end

        function regress_change(src, ~, plot_panel)
            if (src.Value)
                obj.regress = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.regress = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function shift_change(src, ~, plot_panel, dropdown)
            if (src.Value)
                obj.shift = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
                obj.axes_labels(6) = "Pitch Moment (LE)";
            else
                obj.shift = false;
                src.BackgroundColor = [1 1 1];
                obj.axes_labels(6) = "Pitch Moment";
            end
            dropdown.Items = obj.axes_labels;

            obj.update_plot(plot_panel);
        end

        function drift_change(src, ~, plot_panel)
            if (src.Value)
                obj.drift = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.drift = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end

        function model_change(src, ~, plot_panel)
            if (src.Value)
                obj.aero_model = true;
                src.BackgroundColor = [0.3010 0.7450 0.9330];
            else
                obj.aero_model = false;
                src.BackgroundColor = [1 1 1];
            end

            obj.update_plot(plot_panel);
        end
    
        function AoA_change(src, ~, plot_panel)
            % ensure that slider can only be moved to discrete
            % acceptable locations where a measurement was
            % recorded
            AoA = obj.angles;
            [M, I] = min(abs(AoA - src.Value(1)));
            AoA_min = AoA(I);
            [M, I] = min(abs(AoA - src.Value(2)));
            AoA_max = AoA(I);
            src.Value = [AoA_min AoA_max];
    
            % update range property
            obj.range = src.Value;
    
            obj.update_plot(plot_panel);
        end
        %-----------------------------------------------------%
        %-----------------------------------------------------%
        
    end
end

methods(Static, Access = private)

    function data_struct = get_file_structure(baseFileName, parsed_name)
        load("../plot data/" + baseFileName, "names");
        data_struct.file_name = baseFileName;
        data_struct.dir_name = parsed_name;

        for j = 1:length(names)
        % distinguish repeat trials with unique name
        if(sum(names == names(j)) > 1)
            ind = find(names == names(j), 1, 'last');
            names(ind) = names(ind) + " v2";
        end
        end

        data_struct.trial_names = names;
    end

    function update_tree(t, uniq_list)
        for i = 1:length(uniq_list)
            data_struct = uniq_list(i);
            parent = t.Children(i);

            for j = 1:length(t.Children(i).Children)
                child = parent.Children(j);
                child.Text = data_struct.trial_names(j);
            end
        end
    end

    function [abbr_sel] = get_abbr_names(sel)
        if ~(length(sel) == 1)
        all_parts = regexp(convertStringsToChars(sel),'[_/]','split');
        all_parts = string(vertcat(all_parts{:}));
        abbr_sel = [];
        for i = 1:length(sel)
            cur_abbr_sel = [];
            cur_str = convertStringsToChars(sel(i));
            cur_str_parts = string(regexp(cur_str,'[_/]','split'));
            for j = 1:length(cur_str_parts)
                % this word only matches with itself in the list
                if (sum(cur_str_parts(j) == all_parts(:,j)) < length(sel))
                    cur_abbr_sel = [cur_abbr_sel cur_str_parts(j)];
                end
            end
            cur_abbr_sel = strjoin(cur_abbr_sel);
            abbr_sel = [abbr_sel cur_abbr_sel];
        end
        
        else
            abbr_sel = string(regexp(sel,'[_/]','split'));
            abbr_sel = strjoin(abbr_sel);
        end
    end

    function aero_force = get_model(AoA_list, freq, speed)
        C_L_vals = zeros(1, length(AoA_list));
        C_D_vals = zeros(1, length(AoA_list));
        C_N_vals = zeros(1, length(AoA_list));
        C_M_vals = zeros(1, length(AoA_list));
        aero_force = zeros(6, length(AoA_list));

        for i = 1:length(AoA_list)
            AoA = AoA_list(i);

            [time, ang_disp, ang_vel, ang_acc] = get_kinematics(freq, true);
    
            [center_to_LE, chord, COM_span, ...
                wing_length, arm_length] = getWingMeasurements();
            
            full_length = wing_length + arm_length;
            r = arm_length:0.001:full_length;
            lin_vel = deg2rad(ang_vel) * r;
            
            [eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, speed);
            
            thinAirfoil = true;
            [C_L, C_D, C_N, C_M] = get_aero(eff_AoA, u_rel, speed, wing_length, thinAirfoil);
            
            C_L_vals(i) = mean(C_L);
            C_D_vals(i) = mean(C_D);
            C_N_vals(i) = mean(C_N);
            C_M_vals(i) = mean(C_M);
        end

        aero_force(1,:) = C_D_vals;
        aero_force(3,:) = C_L_vals;
        aero_force(5,:) = C_M_vals;
    end

end

methods (Access = private)
    function update_plot(obj, plot_panel)
        delete(plot_panel.Children)
        
        struct_matches = [];
        for i = 1:length(obj.selection)
            dir_name = extractBefore(obj.selection(i), "/");
            if (obj.norm)
                if (obj.shift)
                    if (obj.drift)
                        shortened_list = intersect(intersect([obj.norm_list.file_name], [obj.shift_list.file_name]), [obj.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    else
                        shortened_list = setdiff(intersect([obj.norm_list.file_name], [obj.shift_list.file_name]), [obj.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    end
                else
                    if (obj.drift)
                        shortened_list = intersect(setdiff([obj.norm_list.file_name], [obj.shift_list.file_name]), [obj.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    else
                        shortened_list = setdiff(setdiff([obj.norm_list.file_name], [obj.shift_list.file_name]), [obj.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    end
                end
            else
                if (obj.shift)
                    if (obj.drift)
                        shortened_list = intersect(intersect(setdiff([obj.file_list.file_name], [obj.norm_list.file_name]),...
                        [obj.shift_list.file_name]), [obj.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    else
                        shortened_list = setdiff(intersect(setdiff([obj.file_list.file_name], [obj.norm_list.file_name]),...
                        [obj.shift_list.file_name]), [obj.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    end
                else
                    if (obj.drift)
                        shortened_list = intersect(setdiff(setdiff([obj.file_list.file_name], [obj.norm_list.file_name]),...
                        [obj.shift_list.file_name]), [obj.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    else
                        shortened_list = setdiff(setdiff(setdiff([obj.file_list.file_name], [obj.norm_list.file_name]),...
                        [obj.shift_list.file_name]), [obj.drift_list.file_name]);
                        name_match = shortened_list(contains(shortened_list, dir_name));
                    end
                end
            end

            for j = 1:length(obj.file_list)
                if (obj.file_list(j).file_name == name_match)
                    struct_match = obj.file_list(j);
                end
            end

            % check for repeat files to load
            if (length(struct_matches) == 0 || sum(contains([struct_matches.dir_name], struct_match.dir_name)) == 0)
                struct_matches = [struct_matches struct_match];
            end
        end
        disp("Found following matches:")
        disp(struct_matches)

        x_label = "Angle of Attack (deg)";
        if (obj.norm)
            y_label_F = "Cycle Average Force Coefficient";
            y_label_M = "Cycle Average Moment Coefficient";
        else
            y_label_F = "Cycle Average Force (N)";
            y_label_M = "Cycle Average Moment (N*m)";
        end
        y_labels = [y_label_F, y_label_F, y_label_F, y_label_M, y_label_M, y_label_M];
        titles = obj.axes_labels(2:7);

        if (~isempty(obj.selection))
        unique_dir = [];
        num_dir = 0; % number of unique selected directories
        freq_count_arr = [];
        for j = 1:length(obj.selection)
            dir_name = extractBefore(obj.selection(j), "/");
            trial_name = extractAfter(obj.selection(j), "/");

            if(isempty(unique_dir) || sum([unique_dir.dir_names] == dir_name) == 0)
                data_struct.dir_names = dir_name;
                data_struct.trial_names = [];
                unique_dir = [unique_dir data_struct];
                num_dir = num_dir + 1;
                freq_count_arr(num_dir) = 0;
            end
            if(isempty(unique_dir(num_dir).trial_names) || sum(unique_dir(num_dir).trial_names == trial_name) == 0)
                unique_dir(num_dir).trial_names = [unique_dir(num_dir).trial_names trial_name];
                freq_count_arr(num_dir) = freq_count_arr(num_dir) + 1;
            end
        end

        num_freq = max(freq_count_arr);

        uniq_counts = [num_dir, num_freq];
        [B, I] = sort(uniq_counts);

        % count is number of type + speed combos
        colors = getColors(1, num_dir, num_freq, length(obj.selection));

        [abbr_sel] = compareAoAUI.get_abbr_names(obj.selection);
        end

        % but what if we have 2 hz and 2 hz v2, I don't them to
        % have a color range, I'd rather they have unique colors
        % for each unique dir, there can be a separate list of
        % unique freqs

        lim_AoA_sel = obj.angles(obj.angles >= obj.range(1) & obj.angles <= obj.range(2));

        % -----------------------------------------------------
        % ---- Plotting all six axes (3 forces, 3 moments) ----
        % -----------------------------------------------------
        if (obj.index == 0)
            % Initialize tiled layout for plots
            tcl = tiledlayout(plot_panel, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

            tiles = [];
            for idx = 1:6
                ax = nexttile(tcl, idx);
                title(ax, titles(idx));
                xlabel(ax, x_label);
                ylabel(ax, y_labels(idx))
                grid(ax, 'on');
                legend(ax);
                tiles = [tiles ax];
            end

            if (obj.regress)
                error("No point doing regression on all axes")
            end

            last_f_ind = 0;
            last_s_ind = 0;
            for i = 1:length(struct_matches)
                disp("Loading " + "../plot data/" + struct_matches(i).file_name)
                load("../plot data/" + struct_matches(i).file_name, "avg_forces", "err_forces")
                lim_avg_forces = avg_forces(:,obj.angles >= obj.range(1) & obj.angles <= obj.range(2),:);
                lim_err_forces = err_forces(:,obj.angles >= obj.range(1) & obj.angles <= obj.range(2),:);

                for j = 1:length(obj.selection)
                    dir_name = extractBefore(obj.selection(j), "/");
                    trial_name = extractAfter(obj.selection(j), "/");

                    dir_parts = split(dir_name, '_');
                    wind_speed = sscanf(dir_parts(end), '%g', 1);
                    s_ind = find(obj.speeds == wind_speed);

                    % if current trial selection is in file we
                    % just loaded in
                    if (contains(struct_matches(i).dir_name, dir_name))
                        ind_c_dir = find([unique_dir.dir_names] == dir_name);
                        ind_c_trial = find(unique_dir(ind_c_dir).trial_names == trial_name);
                        freq_index = find(struct_matches(i).trial_names == trial_name);

                        % Get Quasi-Steady Model Force
                        % Predictions
                        wing_freq = obj.freqs(freq_index);
                        aero_force = compareAoAUI.get_model(lim_AoA_sel, wing_freq, wind_speed);

                        for idx = 1:6
                        ax = tiles(idx);
                        hold(ax, 'on');
                        e = errorbar(ax, lim_AoA_sel, lim_avg_forces(idx,:,freq_index), lim_err_forces(idx,:,freq_index),'.');
                        e.MarkerSize = 25;
                        e.Color = colors(ind_c_trial, ind_c_dir);
                        e.MarkerFaceColor = colors(ind_c_trial, ind_c_dir);
                        e.DisplayName = strrep(strrep(obj.selection(j), "_", " "), "/", " ");
                        % e.Marker = markers(m);
                        

                        % ---------Plotting model-----------
                        % aerodynamics model is nondimensionalized, so
                        % data should also be nondimensionalized when
                        % comparing the two. Also only occurs if
                        % frequency or wind speed have changed
                        if (obj.norm && obj.aero_model && (last_f_ind ~= freq_index || last_s_ind ~= s_ind))
                        
                        % if index is odd
                        if (mod(idx, 2) ~= 0)
                            line = plot(ax, lim_AoA_sel, aero_force(idx, :));
                            line.Color = colors(ind_c_trial, ind_c_dir);
                            line.LineStyle = "--";
                            line.LineWidth = 2;
                            line.DisplayName = "Aero Model - " + abbr_sel(j);
                        end
        
                        if (idx == 5)
                        last_f_ind = freq_index;
                        last_s_ind = s_ind;
                        end
                        end

                        hold(ax, 'off');
                        end
                    end
                end
           end

        % -----------------------------------------------------
        % ---- Plotting a single axes defined by obj.index ----
        % -----------------------------------------------------
        else
            ax = axes(plot_panel);
            idx = obj.index;


            last_f_ind = 0;
            last_s_ind = 0;
            for i = 1:length(struct_matches)
                disp("Loading " + "../plot data/" + struct_matches(i).file_name)
                load("../plot data/" + struct_matches(i).file_name, "avg_forces", "err_forces")
                lim_avg_forces = avg_forces(:,obj.angles >= obj.range(1) & obj.angles <= obj.range(2),:);
                lim_err_forces = err_forces(:,obj.angles >= obj.range(1) & obj.angles <= obj.range(2),:);

                % Loop through all selections to find one that
                % matches the file that we just loaded
                for j = 1:length(obj.selection)
                    dir_name = extractBefore(obj.selection(j), "/");
                    trial_name = extractAfter(obj.selection(j), "/");

                    dir_parts = split(dir_name, '_');
                    wind_speed = sscanf(dir_parts(end), '%g', 1);
                    s_ind = find(obj.speeds == wind_speed);

                    if (contains(struct_matches(i).dir_name, dir_name))
                        ind_c_dir = find([unique_dir.dir_names] == dir_name);
                        ind_c_trial = find(unique_dir(ind_c_dir).trial_names == trial_name);
                        freq_index = find(struct_matches(i).trial_names == trial_name);

                        % Get Quasi-Steady Model Force
                        % Predictions
                        wing_freq = obj.freqs(freq_index);
                        aero_force = compareAoAUI.get_model(lim_AoA_sel, wing_freq, wind_speed);

                        hold(ax, 'on');
                        if (obj.regress)
                            x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
                            y = lim_avg_forces(idx,:,freq_index)';
                            b = x\y;
                            model = x*b;
                            Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
                            label = "y = " + round(b(2),3) + "x + " + round(b(1),3) + ", R^2 = " + round(Rsq,3);
                            p = plot(ax, lim_AoA_sel, model);
                            p.DisplayName = label;
                            p.Color = colors(ind_c_trial, ind_c_dir);
                            p.LineWidth = 2;
                        end
                        e = errorbar(ax, lim_AoA_sel, lim_avg_forces(idx,:,freq_index), lim_err_forces(idx,:,freq_index),'.');
                        e.MarkerSize = 25;
                        e.Color = colors(ind_c_trial, ind_c_dir);
                        e.MarkerFaceColor = colors(ind_c_trial, ind_c_dir);
                        e.DisplayName = abbr_sel(j);
                        
                        % ---------Plotting model-----------
                        % aerodynamics model is nondimensionalized, so
                        % data should also be nondimensionalized when
                        % comparing the two. Also only occurs if
                        % frequency or wind speed have changed
                        if (obj.norm && obj.aero_model && (last_f_ind ~= freq_index || last_s_ind ~= s_ind))
                        
                        % if index is odd
                        if (mod(idx, 2) ~= 0)
                            line = plot(ax, lim_AoA_sel, aero_force(idx, :));
                            line.Color = colors(ind_c_trial, ind_c_dir);
                            line.LineStyle = "--";
                            line.LineWidth = 2;
                            line.DisplayName = "Aero Model - " + abbr_sel(j);
                        end
        
                        last_f_ind = freq_index;
                        last_s_ind = s_ind;
                        end
                    end

                end
            end

            title(ax, titles(idx));
            xlabel(ax, x_label);
            ylabel(ax, y_labels(idx))
            grid(ax, 'on');
            legend(ax, Location="best");
            ax.FontSize = 18;
        end
    end
end
end