// repos.swift — compact cmux workspace and agent navigator (~230 pt).
//
// cmux 0.64.22 does not expose tabs[].agent. Pi rows use the exact U+2063
// compatibility marker owned by cmux-feed. The spinner list is the only native
// fallback; unmarked shells and broad title guesses are intentionally omitted.

func prColor(_ status: String, _ stale: Bool) -> String {
    if stale { return "#7F8794" }
    if status == "open" { return "#55D98A" }
    if status == "merged" { return "#A78BFA" }
    if status == "closed" { return "#FF6B6B" }
    return "#AEB6C2"
}

func isNativeWorkingMarker(_ title: String) -> Bool {
    return title.hasPrefix("⠁") || title.hasPrefix("⠂") || title.hasPrefix("⠄") || title.hasPrefix("⡀") || title.hasPrefix("⢀") || title.hasPrefix("⠠") || title.hasPrefix("⠐") || title.hasPrefix("⠈") || title.hasPrefix("⠋") || title.hasPrefix("⠙") || title.hasPrefix("⠹") || title.hasPrefix("⠸") || title.hasPrefix("⠼") || title.hasPrefix("⠴") || title.hasPrefix("⠦") || title.hasPrefix("⠧")
}

// Exact owned protocol: state glyph + U+2063. New markers add an invisible
// automatic/manual discriminator segment; legacy one/two-separator markers remain.
func markerState(_ title: String) -> String {
    if title.hasPrefix("⠋⁣") { return "working" }
    if title.hasPrefix("✓⁣") { return "completed" }
    if title.hasPrefix("!⁣") { return "error" }
    if title.hasPrefix("×⁣") { return "cancelled" }
    if title.hasPrefix("○⁣") { return "idle" }
    return ""
}

func isOwnedPi(_ title: String) -> Bool {
    return markerState(title) != ""
}

func isLegacyPiTitle(_ title: String) -> Bool {
    let lower = title.lowercased()
    return lower == "pi" || lower.hasPrefix("pi - ") || title == "π" || title.hasPrefix("π - ")
}

// Installed cmux 0.64.22 supports split/dropFirst/joined. Keep empty segments
// so new and legacy manual codecs, plus embedded U+2063 base text, round-trip.
func visibleTabTitle(_ title: String) -> String {
    if !isOwnedPi(title) { return title }
    let parts = title.split(separator: "⁣", omittingEmptySubsequences: false)
    if parts.count < 2 { return title }
    let discriminator = "\(parts[1])"
    if parts.count > 2 && (discriminator == "⁤" || discriminator == "⁢" || discriminator == "") {
        return parts.dropFirst(2).joined(separator: "⁣")
    }
    return parts.dropFirst(1).joined(separator: "⁣")
}

func workspaceBasename(_ workspace) -> String {
    let parts = workspace.directory.split(separator: "/")
    if parts.count > 0 { return "\(parts[parts.count - 1])" }
    return workspace.title
}

func hasProgress(_ workspace) -> Bool {
    if let progress = workspace.progress { return progress.value >= 0.0 }
    return false
}

func progressState(_ workspace) -> String {
    if let progress = workspace.progress {
        if progress.value < 0.0 { return "" }
        if progress.label.hasPrefix("Error ·") { return "error" }
        if progress.label.hasPrefix("Cancelled ·") { return "cancelled" }
        if progress.value < 1.0 { return "working" }
        if progress.label.hasPrefix("Done ·") { return "completed" }
    }
    return ""
}

func tabState(_ tab) -> String {
    let owned = markerState(tab.title)
    if owned != "" { return owned }
    if isNativeWorkingMarker(tab.title) { return "working" }
    return "idle"
}

func isAgentTab(_ tab) -> Bool {
    return isOwnedPi(tab.title) || isLegacyPiTitle(tab.title) || isNativeWorkingMarker(tab.title)
}

func agentCount(_ workspace) -> Int {
    return workspace.tabs.count { isAgentTab($0) }
}

func workspaceState(_ workspace) -> String {
    // cmux 0.64.22 reliably interprets trailing-closure collection methods;
    // parenthesized closure arguments validate but silently return no match.
    if workspace.tabs.contains { markerState($0.title) == "error" } { return "error" }
    if workspace.tabs.contains { markerState($0.title) == "cancelled" } { return "cancelled" }
    let progress = progressState(workspace)
    if progress == "error" || progress == "cancelled" { return progress }
    if workspace.tabs.contains { tabState($0) == "working" } || progress == "working" { return "working" }
    if workspace.tabs.contains { markerState($0.title) == "completed" } || progress == "completed" { return "completed" }
    return "idle"
}

func stateGlyph(_ state: String) -> String {
    if state == "error" { return "!" }
    if state == "cancelled" { return "×" }
    if state == "completed" { return "✓" }
    return "○"
}

func stateTint(_ state: String) -> String {
    if state == "working" { return "#70B7FF" }
    if state == "error" { return "#FF6B6B" }
    if state == "cancelled" { return "#F0B45A" }
    if state == "completed" { return "#55D98A" }
    return "#7F8794"
}

func detailTint(_ state: String) -> String {
    if state == "working" || state == "error" || state == "cancelled" { return stateTint(state) }
    return "#AEB6C2"
}

func stateLabel(_ state: String) -> String {
    if state == "working" { return "Working" }
    if state == "completed" { return "Completed" }
    if state == "error" { return "Error" }
    if state == "cancelled" { return "Cancelled" }
    return "Idle"
}

func tabDetail(_ workspace, _ tab) -> String {
    let state = tabState(tab)
    if state == "working" && agentCount(workspace) == 1 && progressState(workspace) == "working" {
        if let progress = workspace.progress { return progress.label }
    }
    if state == "completed" || state == "idle" { return "" }
    return stateLabel(state)
}

VStack(alignment: .leading, spacing: 2) {
    HStack {
        Text("SPACES").font(.system(size: 11, weight: .semibold)).foregroundColor("#F2F4F8")
        Spacer()
        let unreadCount = workspaces.count { $0.unread > 0 }
        if unreadCount > 0 {
            Text("\(unreadCount) unread").font(.system(size: 11)).foregroundColor("#F0B45A")
        }
    }
    .frame(height: 24)
    Divider()

    // Source order is cmux's stable Cmd+N order; drag to reorder (persisted).
    Reorderable(workspaces, move: "workspace.reorder") { workspace in
        let lifecycle = workspaceState(workspace)
        let count = agentCount(workspace)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Text(workspace.selected ? "▌" : " ")
                    .font(.system(size: 12)).foregroundColor("#A78BFA")
                Text("\(workspace.index + 1)").font(.system(size: 11)).foregroundColor("#AEB6C2")
                Text(workspaceBasename(workspace))
                    .font(.system(size: 14, weight: .semibold)).foregroundColor("#F2F4F8")
                    .lineLimit(1).truncationMode(.tail)
                Spacer()
                if let pr = workspace.pr {
                    if pr.number > 0 {
                        Text("#\(pr.number)")
                            .font(.system(size: 11)).foregroundColor(prColor(pr.status, pr.stale))
                            .onTapGesture { openURL(pr.url) }
                    }
                }
                if count > 0 {
                    Text("×\(count)").font(.system(size: 11)).foregroundColor("#AEB6C2")
                }
                if workspace.unread > 0 {
                    Text("●\(workspace.unread)").font(.system(size: 11)).foregroundColor("#F0B45A")
                }
                if lifecycle == "working" {
                    ProgressView().scaleEffect(0.46).frame(width: 12, height: 12).tint("#70B7FF")
                } else {
                    Text(stateGlyph(lifecycle)).font(.system(size: 14)).foregroundColor(stateTint(lifecycle))
                }
            }
            if let branch = workspace.branch {
                Text("\(branch)\(workspace.dirty ? " *" : "")")
                    .font(.system(size: 12)).foregroundColor("#AEB6C2")
                    .lineLimit(1).truncationMode(.tail).padding(.leading, 29)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 2)
        .background(workspace.selected ? "#382E4D" : "#00000000")
        .cornerRadius(4)
        .onTapGesture { cmux("workspace.select", workspace_id: workspace.id) }
    }

    Divider().padding(.top, 2)
    Text("AGENTS").font(.system(size: 11, weight: .semibold)).foregroundColor("#F2F4F8")
        .frame(height: 24)
    Divider()

    // Spaces already identifies repository ownership. Keep this section focused
    // on sessions, preserving workspace/tab order without repeated repo labels.
    for workspace in workspaces {
        if agentCount(workspace) > 0 {
            for tab in workspace.tabs {
                if isAgentTab(tab) {
                    let lifecycle = tabState(tab)
                    let detail = tabDetail(workspace, tab)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 5) {
                            Text(workspace.selected && tab.focused ? "▌" : " ")
                                .font(.system(size: 12)).foregroundColor("#A78BFA")
                            if lifecycle == "working" {
                                ProgressView().scaleEffect(0.46).frame(width: 12, height: 12).tint("#70B7FF")
                            } else {
                                Text(stateGlyph(lifecycle)).font(.system(size: 14)).foregroundColor(stateTint(lifecycle))
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                Text(visibleTabTitle(tab.title))
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor("#F2F4F8")
                                    .lineLimit(1).truncationMode(.tail)
                                HStack(spacing: 3) {
                                    Text(workspaceBasename(workspace))
                                        .font(.system(size: 11)).foregroundColor("#7F8794")
                                    if detail != "" {
                                        Text("· \(detail)")
                                            .font(.system(size: 11)).foregroundColor(detailTint(lifecycle))
                                            .lineLimit(1).truncationMode(.tail)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(height: 44)
                    .padding(.horizontal, 2)
                    .background(workspace.selected && tab.focused ? "#382E4D" : "#00000000")
                    .cornerRadius(4)
                    .onTapGesture { cmux("surface.focus", surface_id: tab.id) }
                }
            }
        }
    }
}
