function plot_trial(file, raw_data_path, processed_data_path, bools, subtraction_string, nondimensional)

if (subtraction_string == "none")
    body_subtraction = false;
else
    body_subtraction = true;
end

[case_name, type, wing_freq, AoA, wind_speed] = parse_filename(file);

if (bools.raw)
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(raw_data_path, '*.csv'); % Change to whatever pattern you need.
    theFiles = dir(filePattern);
    
    % Go through each file, grab its data, take the mean over all results to
    % produce a "dot" (i.e. a single point value) for each force and moment
    for i = 1 : length(theFiles)
        baseFileName = theFiles(i).name;
        [case_name_cur, type_cur, wing_freq_cur, AoA_cur, wind_speed_cur] = parse_filename(baseFileName);
        type_cur = convertCharsToStrings(type_cur);
        
        if (wing_freq == wing_freq_cur ...
        && AoA == AoA_cur ...
        && wind_speed == wind_speed_cur ...
        && strcmp(type, type_cur))
            data_filename = baseFileName;
        end
    end
    
    % Get raw data from file
    data = readmatrix(raw_data_path + data_filename);
    
    raw_time = data(:,1);
    raw_force = data(:,2:7);
    raw_trigger = data(:,8);
    
    % Trim off portion of data where wings are motionless or accelerating
    trimmed_results = trim_data([raw_time raw_force], raw_trigger, wing_freq);
    trimmed_time = trimmed_results(:,1)';
    trimmed_force = trimmed_results(:,2:7)';
    
    plot_raw_data(raw_time', raw_force', trimmed_time, trimmed_force, case_name, 5);
end

load(processed_data_path + file);

disp("Loading data from " + case_name + " trial")

if (bools.time_data)

if (nondimensional)

else
    x_label = "Time (s)";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    subtitle = "Trimmed, Rotated";
    axes_labels = [x_label, y_label_F, y_label_M];
    plot_forces(time_data, results_lab, case_name, subtitle, axes_labels);
    
    x_label = "Time (s)";
    y_label_F = "Force Coefficient";
    y_label_M = "Moment Coefficient";
    subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered";
    axes_labels = [x_label, y_label_F, y_label_M];
    plot_forces(time_data, filtered_data, case_name, subtitle, axes_labels, 5);
end

end

CAD_bool = true;
[time, ang_disp, ang_vel, ang_acc] = get_kinematics(wing_freq, CAD_bool);

wing_length = 0.25; % meters
arm_length = 0.016;
full_length = wing_length + arm_length;
r = arm_length:0.001:full_length;
lin_vel = deg2rad(ang_vel) * r;
lin_acc = deg2rad(ang_acc) * r;

[eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);

if (body_subtraction)
    disp("Subtraction only occurs for wingbeat_avg_forces and model")
    % Parse relevant information from subtraction string
    case_parts = strtrim(split(subtraction_string));
    sub_type = "";
    sub_wing_freq = wing_freq;
    sub_wind_speed = wind_speed;
    sub_AoA = AoA;
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
        elseif (contains(case_parts(j), "deg"))
            sub_AoA = str2double(erase(case_parts(j), "deg"));
            if index ~= -1
                index = j;
            end
        end
    end
    sub_type = strjoin(case_parts(1:index-1)); % speed is first thing after type
    
    sub_case_name = sub_type + " " + sub_wind_speed + "m.s " + sub_AoA + "deg " + sub_wing_freq + "Hz";

    wingbeat_avg_forces_old = wingbeat_avg_forces;
    wingbeat_std_forces_old = wingbeat_std_forces;

    Re_og = Re;
    St_og = St;

    vars = {'wingbeat_avg_forces', 'wingbeat_std_forces', 'Re', 'St'};
    load(processed_data_path + sub_case_name + '.mat', vars{:});

    wingbeat_avg_forces = wingbeat_avg_forces_old - wingbeat_avg_forces;
    wingbeat_std_forces = wingbeat_std_forces_old + wingbeat_std_forces;

    disp("Subtracting data from " + sub_case_name + " trial")

    if (sub_type ~= "no wings" && sub_type ~= "no wings with tail")
        disp("Subtracting model data")
        [sub_time, sub_ang_disp, sub_ang_vel, sub_ang_acc] = get_kinematics(sub_wing_freq, CAD_bool);
    
        sub_lin_vel = deg2rad(sub_ang_vel) * r;
        sub_lin_acc = deg2rad(sub_ang_acc) * r;
    
        [sub_eff_AoA, sub_u_rel] = get_eff_wind(sub_time, sub_lin_vel, sub_AoA, sub_wind_speed);
    end

    if (nondimensional)
        sub_case_title = sub_type + ", Re: " + num2str(round(Re,2,"significant")) + ...
                ", St: " + num2str(round(St,2,"significant")) + ", " + sub_AoA + " deg";
    else
        sub_case_title = sub_type + ", U: " + sub_wind_speed + ...
            " m/s, f: " + sub_wing_freq + " Hz, " + sub_AoA + " deg";
    end
end

if (bools.kinematics)
    % Just angular displacement
    fig = figure;
    fig.Position = [200 50 900 560];
    plot(time, ang_disp, DisplayName="Angular Displacement (deg)")
    xlim([0 max(time)])
    xlabel("Time (s)")
    ylabel("Angular Displacement (deg)")
    title("Angular Displacement of Wings Flapping at 1 Hz")

    % Just angular velocity
    fig = figure;
    fig.Position = [200 50 900 560];
    plot(time, ang_vel)
    xlim([0 max(time)])
    xlabel("Time (s)")
    ylabel("Angular Velocity (deg/s)")
    title("Angular Velocity of Wings Flapping at 1 Hz")

    % Both displacement and velocity
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    yyaxis left
    plot(time, ang_disp, DisplayName="Angular Displacement (deg)")
    yyaxis right
    plot(time, ang_vel, DisplayName="Angular Velocity (deg/s)")
    hold off
    xlim([0 max(time)])
    xlabel("Time (s)")
    ylabel("Angular Displacement/Velocity")
    title("Angular Motion of Wings Flapping at 1 Hz")
    legend(Location="northeast")
    
    % Linear velocity
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, lin_vel(:,51), DisplayName="r = 0.05")
    plot(time, lin_vel(:,151), DisplayName="r = 0.15")
    plot(time, lin_vel(:,251), DisplayName="r = 0.25")
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Linear Velocity (m/s)")
    title("Linear Velocity of Wings Flapping at 1 Hz")
    legend(Location="northeast")
    
    % Linear acceleration
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, lin_acc(:,51), DisplayName="r = 0.05")
    plot(time, lin_acc(:,151), DisplayName="r = 0.15")
    plot(time, lin_acc(:,251), DisplayName="r = 0.25")
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Linear Acceleration (m/s^2)")
    title("Linear Acceleration of Wings Flapping at 1 Hz")
    legend(Location="northeast")
end

if (bools.eff_wind)
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, u_rel(:,51), DisplayName="r = 0.05")
    plot(time, u_rel(:,151), DisplayName="r = 0.15")
    plot(time, u_rel(:,251), DisplayName="r = 0.25")
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Effective Wind Speed (m/s)")
    title("Effective Wind Speed during Flapping for " + case_name)
    legend(Location="northeast")

    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, eff_AoA(:,51), DisplayName="r = 0.05")
    plot(time, eff_AoA(:,151), DisplayName="r = 0.15")
    plot(time, eff_AoA(:,251), DisplayName="r = 0.25")
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Effective Angle of Attack (deg)")
    title("Effective Angle of Attack during Flapping for " + case_name)
    legend(Location="northeast")
end

if (wing_freq > 0)

if (bools.model)
    [center_to_LE, chord, COM_span] = getWingMeasurements();

    [inertial_force] = get_inertial(ang_disp, ang_acc, r, COM_span, AoA);
    
    thinAirfoil = true;
    [C_L, C_D, C_N, C_M] = get_aero(eff_AoA, u_rel, wind_speed, wing_length, thinAirfoil);

    [added_mass_force] = get_added_mass(ang_disp, ang_acc, r, wing_length, AoA);

    % lin_disp = deg2rad(ang_disp) * r;
    % lin_disp_COM = lin_disp(:, round(r,3) == round(COM_span,3));
    % wing_mass = 0.010; % kg
    % wing_to_FT_height = 0.1; % m

    % inertial_force = 2*wing_mass*lin_acc_COM.*cosd(ang_disp);
    % static_term = lin_disp_COM
    % static_mom = -2*wing_mass*wing_to_FT_height*sind(AoA);
    % static_mom = 0;

    drag_force = wingbeat_avg_forces(1,:);
    lift_force = wingbeat_avg_forces(3,:);
    pitch_moment = wingbeat_avg_forces(5,:);

    normal_force = lift_force*cosd(AoA) + drag_force*sind(AoA);
    
    shift_distance = -center_to_LE;

    % Shift pitch moment
    pitch_moment_LE = pitch_moment + normal_force * shift_distance;

    if (nondimensional)
        drag_force = wingbeat_avg_forces(1,:) / norm_factors(1);
        lift_force = wingbeat_avg_forces(3,:) / norm_factors(1);
        pitch_moment_LE = pitch_moment_LE / norm_factors(2);

        inertial_force = [inertial_force(:,1) / norm_factors(1),...
                        inertial_force(:,2) / norm_factors(1),...
                        inertial_force(:,3) / norm_factors(2)];

        added_mass_force = [added_mass_force(:,1) / norm_factors(1),...
                        added_mass_force(:,2) / norm_factors(1),...
                        added_mass_force(:,3) / norm_factors(2)];
        
        case_title = type + ", Re: " + num2str(round(Re_og,2,"significant")) + ", St: " + num2str(round(St_og,2,"significant")) + ", " + AoA + " deg";
    else
        C_D = C_D * norm_factors(1);
        C_L = C_L * norm_factors(1);
        C_M = C_M * norm_factors(2);
        
        case_title = type + ", U: " + wind_speed + " m/s, f: " + wing_freq + " Hz, " + AoA + " deg";
    end

    total_drag = C_D + inertial_force(:,1) + added_mass_force(:,1);
    total_lift = C_L + inertial_force(:,2) + added_mass_force(:,2);
    total_moment = C_M + inertial_force(:,3) + added_mass_force(:,3);

    if (body_subtraction)
        if (sub_type ~= "no wings" && sub_type ~= "no wings with tail")
        [sub_inertial_force] = get_inertial(sub_ang_disp, sub_ang_acc, r, COM_span, sub_AoA);
        
        thinAirfoil = true;
        [sub_C_L, sub_C_D, sub_C_N, sub_C_M] = get_aero(sub_eff_AoA, sub_u_rel, sub_wind_speed, wing_length, thinAirfoil);
    
        [sub_added_mass_force] = get_added_mass(sub_ang_disp, sub_ang_acc, r, wing_length, sub_AoA);
    
        if (nondimensional)
            sub_inertial_force = [sub_inertial_force(:,1) / norm_factors(1),...
                            sub_inertial_force(:,2) / norm_factors(1),...
                            sub_inertial_force(:,3) / norm_factors(2)];
    
            sub_added_mass_force = [sub_added_mass_force(:,1) / norm_factors(1),...
                            sub_added_mass_force(:,2) / norm_factors(1),...
                            sub_added_mass_force(:,3) / norm_factors(2)];
        else
            sub_C_D = sub_C_D * norm_factors(1);
            sub_C_L = sub_C_L * norm_factors(1);
            sub_C_M = sub_C_M * norm_factors(2);
        end
    
        sub_total_drag = sub_C_D + sub_inertial_force(:,1) + sub_added_mass_force(:,1);
        sub_total_lift = sub_C_L + sub_inertial_force(:,2) + sub_added_mass_force(:,2);
        sub_total_moment = sub_C_M + sub_inertial_force(:,3) + sub_added_mass_force(:,3);
    
    
        % Subtraction
        inertial_force = inertial_force - sub_inertial_force;
        C_D = C_D - sub_C_D;
        C_L = C_L - sub_C_L;
        C_M = C_M - sub_C_M;
        added_mass_force = added_mass_force - sub_added_mass_force;
    
        total_drag = C_D + inertial_force(:,1) + added_mass_force(:,1);
        total_lift = C_L + inertial_force(:,2) + added_mass_force(:,2);
        total_moment = C_M + inertial_force(:,3) + added_mass_force(:,3);
        end
    end

    % Open a new figure.
    fig = figure;
    fig.Position = [200 50 1400 500];
    tcl = tiledlayout(1,3);
    if (body_subtraction)
        sgtitle([case_title "{\color{red}{SUBTRACTION}}: " + sub_case_title]);
    else
        sgtitle(case_title);
    end
    
    colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];
    
    x_label = "Wingbeat Period (t/T)";
    if (nondimensional)
        y_label_F = "Force Coefficient";
        y_label_M = "Moment Coefficient";
    else
        y_label_F = "Force (N)";
        y_label_M = "Moment (N*m)";
    end

    nexttile
    hold on
    plot(frames, drag_force, "DisplayName", "Experiment", "LineWidth",2);
    plot(time / max(time), inertial_force(:,1), "DisplayName", "Inertial", "LineStyle","--", "LineWidth",2);
    plot(time / max(time), added_mass_force(:,1), "DisplayName", "Added Mass", "LineStyle","--", "LineWidth",2);
    plot(time / max(time), C_D, "DisplayName","Quasi-Steady", "LineStyle","--", "LineWidth",2);
    plot(time / max(time), total_drag, "DisplayName","Model", "LineWidth",2)
    legend();
    xlabel(x_label)
    ylabel(y_label_F)
    title("Drag force")

    nexttile
    hold on
    plot(frames, lift_force, "DisplayName", "Experiment", "LineWidth",2);
    plot(time / max(time), inertial_force(:,2), "DisplayName", "Inertial", "LineStyle","--", "LineWidth",2);
    plot(time / max(time), added_mass_force(:,2), "DisplayName", "Added Mass", "LineStyle","--", "LineWidth",2);
    plot(time / max(time), C_L, "DisplayName","Quasi-Steady", "LineStyle","--", "LineWidth",2);
    plot(time / max(time), total_lift, "DisplayName","Model", "LineWidth",2)
    legend();
    xlabel(x_label)
    ylabel(y_label_F)
    title("Lift force")

    nexttile
    hold on
    plot(frames, pitch_moment_LE, "DisplayName", "Experiment", "LineWidth",2);
    plot(time / max(time), inertial_force(:,3), "DisplayName", "Inertial", "LineStyle","--", "LineWidth",2);
    plot(time / max(time), added_mass_force(:,3), "DisplayName", "Added Mass", "LineStyle","--", "LineWidth",2);
    % plot(time / max(time), lin_disp_COM, "DisplayName","Static", "LineStyle","--", "LineWidth",2);
    plot(time / max(time), C_M, "DisplayName","Quasi-Steady", "LineStyle","--", "LineWidth",2);
    plot(time / max(time), total_moment, "DisplayName","Model", "LineWidth",2)
    legend();
    xlabel(x_label)
    ylabel(y_label_M)
    title("Pitch Moment LE")
end

if (nondimensional)
    x_label = "Wingbeat Period (t/T)";
    y_label_F = "Force Coefficient";
    y_label_M = "Moment Coefficient";
    axes_labels = [x_label, y_label_F, y_label_M];

    subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
    plot_forces_mean(frames, ...
        dimensionless(wingbeat_avg_forces, norm_factors), ...
        dimensionless(wingbeat_avg_forces + wingbeat_std_forces,norm_factors), ...
        dimensionless(wingbeat_avg_forces - wingbeat_std_forces, norm_factors), ...
        case_name, subtitle, axes_labels);

    subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> Range";
    plot_forces_mean(frames, ...
        dimensionless(wingbeat_avg_forces,norm_factors), ...
        dimensionless(wingbeat_max_forces,norm_factors), ...
        dimensionless(wingbeat_min_forces,norm_factors), ...
        case_name, subtitle, axes_labels);

    subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
    plot_forces_mean_subset(frames, ...
        dimensionless(wingbeat_avg_forces,norm_factors), ...
        dimensionless(wingbeat_avg_forces + wingbeat_std_forces,norm_factors), ...
        dimensionless(wingbeat_avg_forces - wingbeat_std_forces, norm_factors), ...
        case_name, subtitle, axes_labels);

    y_label_F = "RMSE";
    y_label_M = "RMSE";
    axes_labels = [x_label, y_label_F, y_label_M];
    subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat RMS'd";
    plot_forces(frames, dimensionless(wingbeat_rmse_forces,norm_factors), case_name, subtitle, axes_labels, 0);
else
    x_label = "Wingbeat Period (t/T)";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    axes_labels = [x_label, y_label_F, y_label_M];

    subtitle = "Trimmed, Rotated, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
    plot_forces_mean(frames, wingbeat_avg_forces, ...
        wingbeat_avg_forces + wingbeat_std_forces, ...
        wingbeat_avg_forces - wingbeat_std_forces, ...
        case_name, subtitle, axes_labels);

    subtitle = "Trimmed, Rotated, Filtered, Wingbeat Averaged, Shaded -> Range";
    plot_forces_mean(frames, wingbeat_avg_forces, ...
        wingbeat_max_forces, wingbeat_min_forces, ...
        case_name, subtitle, axes_labels);

    subtitle = "Trimmed, Rotated, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
    plot_forces_mean_subset(frames, wingbeat_avg_forces, ...
        wingbeat_avg_forces + wingbeat_std_forces, ...
        wingbeat_avg_forces - wingbeat_std_forces, ...
        case_name, subtitle, axes_labels);

    y_label_F = "RMSE";
    y_label_M = "RMSE";
    axes_labels = [x_label, y_label_F, y_label_M];
    subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat RMS'd";
    plot_forces(frames, wingbeat_rmse_forces, case_name, subtitle, axes_labels, 0);
end

if (bools.COP)
    COP = wingbeat_avg_forces(5,:) ./ wingbeat_avg_forces(3,:); % M_y / F_z
    % fc = 20; % cutoff frequency
    % fs = 9000;
    % [b,a] = butter(6,fc/(fs/2));
    % filtered_COP = filtfilt(b,a,COP);
    f = figure;
    f.Position = [200 50 900 560];
    plot(frames, COP)
    % plot(frames, filtered_COP)
    % plot(frames, wingbeat_COP)
    ylim([-1, 1])
    title("Movement of Center of Pressure for " + case_name)
    xlabel("Wingbeat Period (t/T)");
    ylabel("COP Location (m)");
end

end

if (bools.movie)
    y_label_F = "Force Coefficient";
    y_label_M = "Moment Coefficient";
    axes_labels = [x_label, y_label_F, y_label_M];
    subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged";
    wingbeat_movie(frames, dimensionless(wingbeat_forces, norm_factors),...
        case_name, subtitle, axes_labels);
end

if (bools.spectrum)
    subtitle = "Trimmed, Rotated, Non-dimensionalized, Power Spectrum";
    plot_spectrum(wind_speed, freq, freq_power, case_name, subtitle)
end

end