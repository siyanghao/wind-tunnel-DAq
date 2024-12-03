function eff_wind_plot(time, u_rel, eff_AoA, case_title)
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, u_rel(:,51), DisplayName="Near Wing Root") % "b = 0.05"
    % plot(time, u_rel(:,151), DisplayName="b = 0.15")
    plot(time, u_rel(:,251), DisplayName="Wing Tip") % "b = 0.25"
    set(gca,'DefaultLineLineWidth',2)
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Effective Wind Speed (m/s)")
    title(["Effective Wind Speed during Flapping" case_title])
    legend(Location="northeast")

    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, eff_AoA(:,51), DisplayName="Near Wing Root") 
    % plot(time, eff_AoA(:,151), DisplayName="b = 0.15")
    plot(time, eff_AoA(:,251), DisplayName="Wing Tip")
    set(gca,'DefaultLineLineWidth',2)
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Effective Angle of Attack (deg)")
    title(["Effective Angle of Attack during Flapping" case_title])
    legend(Location="northeast")


    % Animation showing effective wind vector moving relative to wing
    p1 = [-u_rel(:,251).*cosd(eff_AoA(:,251)) -u_rel(:,251).*sind(eff_AoA(:,251))];                         % First Point
    p2 = zeros(size(p1));                         % Second Point
    dp = p2 - p1;                         % Difference

    wingbeats_animation = struct('cdata', cell(1,length(time)), 'colormap', cell(1,length(time)));
    for i = 1:length(time)
        % Open a new figure.
        fig = figure;
        fig.Visible = "off";
        hold on
        yline(0, LineWidth=2, Color='black')
        quiver(p1(i, 1),p1(i, 2),dp(i, 1),dp(i, 2),0, LineWidth=2)
        xlim([-ceil(min(u_rel(:,251)) + 0.5) 5])
        ylim([-ceil(max(u_rel(:,251))) ceil(max(u_rel(:,251)))])
        set(gca,'XTick',[], 'YTick', [])
        % alpha(1)

        F = getframe(fig);
        
        % Add plot to array of plots to serve animation
        wingbeats_animation(i) = F;

        percent_complete = (i / length(time))*100;
        disp(round(percent_complete) + "% done with movie")
    end

    % Save movie
    video_name = 'eff_wind.mp4';
    v = VideoWriter(video_name, 'MPEG-4');
    v.FrameRate = 10; % fps
    v.Quality = 100; % [0 - 100]
    open(v);
    writeVideo(v,wingbeats_animation);
    close(v);
end