// repos.swift — herdr-inspired cmux sidebar.
//
// Two levels of navigation:
//   1. "spaces" lists workspaces in true cmd+N order, with repository name,
//      PR badge, agent count, aggregate state, and git branch.
//   2. "agents" lists recognized agent surfaces/tabs. Selecting a row focuses
//      that surface. Its second line shows reliable per-surface activity when
//      available; otherwise it shows idle state or the selected workspace diff.
//
// cmux exposes progress/latestMessage per workspace rather than per surface.
// The Pi cmux-feed extension therefore prefixes its surface title with an owned
// working/completed/error/cancelled marker. Never infer agent state from focus:
// focus is navigation, not activity. Selected rows use the purple rail.

// repoKey groups Lovable worktrees together. Standalone repositories keep the
// workspace title as their key.
func repoKey(_ dir: String, _ title: String) -> String {
    if dir.contains("/lovablelabs/") { return "lovable" }
    if title.hasPrefix("lovable") { return "lovable" }
    return title
}

func prColor(_ status: String, _ stale: Bool) -> String {
    if stale { return "#6E7681" }
    if status == "open" { return "#3FB950" }
    if status == "merged" { return "#A371F7" }
    if status == "closed" { return "#F85149" }
    return "#8E8E93"
}

func isSpinner(_ title: String) -> Bool {
    return title.hasPrefix("⠁") || title.hasPrefix("⠂") || title.hasPrefix("⠄") || title.hasPrefix("⡀") || title.hasPrefix("⢀") || title.hasPrefix("⠠") || title.hasPrefix("⠐") || title.hasPrefix("⠈") || title.hasPrefix("⠋") || title.hasPrefix("⠙") || title.hasPrefix("⠹") || title.hasPrefix("⠸") || title.hasPrefix("⠼") || title.hasPrefix("⠴") || title.hasPrefix("⠦") || title.hasPrefix("⠧")
}

// U+2063 separates cmux-feed's state marker from the original title. It is
// invisible in cmux's native tab bar; hide the owned prefix in this list too.
func markerState(_ title: String) -> String {
    if title.hasPrefix("⠋⁣") { return "working" }
    if title.hasPrefix("✓⁣") { return "completed" }
    if title.hasPrefix("!⁣") { return "error" }
    if title.hasPrefix("×⁣") { return "cancelled" }
    return ""
}

func isOwnedMarker(_ title: String) -> Bool {
    return markerState(title) != ""
}

func visibleTabTitle(_ title: String) -> String {
    let parts = title.split(separator: "⁣")
    if isOwnedMarker(title) && parts.count > 1 { return "\(parts[1])" }
    return title
}

func spin(_ second: Int) -> String {
    let frame = second % 8
    if frame == 0 { return "⠋" }
    if frame == 1 { return "⠙" }
    if frame == 2 { return "⠹" }
    if frame == 3 { return "⠸" }
    if frame == 4 { return "⠼" }
    if frame == 5 { return "⠴" }
    if frame == 6 { return "⠦" }
    return "⠧"
}

func hasProgress(_ workspace) -> Bool {
    return workspace.progress.value >= 0.0
}

func isWorking(_ workspace) -> Bool {
    return (hasProgress(workspace) && workspace.progress.value < 1.0) || (workspace.tabs.contains { isSpinner($0.title) })
}

func hasLatestMessage(_ workspace) -> Bool {
    return workspace.latestMessage != ""
}

func hasDescription(_ workspace) -> Bool {
    return workspace.description != ""
}

func hasFailed(_ workspace) -> Bool {
    return hasProgress(workspace) && workspace.progress.label.lowercased().contains("error")
}

func hasCancelled(_ workspace) -> Bool {
    return hasProgress(workspace) && workspace.progress.label.lowercased().contains("cancelled")
}

func workspaceGlyph(_ workspace, _ second: Int) -> String {
    if isWorking(workspace) { return spin(second) }
    if hasFailed(workspace) || hasCancelled(workspace) { return "!" }
    if hasProgress(workspace) || workspace.unread > 0 { return "●" }
    return "○"
}

func workspaceTint(_ workspace) -> String {
    if isWorking(workspace) { return "#58A6FF" }
    if hasFailed(workspace) { return "#F85149" }
    if hasCancelled(workspace) { return "#D29922" }
    if hasProgress(workspace) || workspace.unread > 0 { return "#D29922" }
    return "#5A5A5E"
}

// Surface title markers are per-agent. Workspace progress is aggregate and
// must never be assigned to whichever tab happens to be focused.
func tabState(_ workspace, _ tab) -> String {
    let state = markerState(tab.title)
    if state != "" { return state }
    if isSpinner(tab.title) { return "working" }

    // Compatibility for runs completed before per-surface markers existed.
    // Workspace latestMessage is safe to attribute only when there is one agent.
    if agentCount(workspace) == 1 && isAgentTab(tab) && hasLatestMessage(workspace) { return "completed" }
    return "idle"
}

func tabGlyph(_ workspace, _ tab, _ second: Int) -> String {
    let state = tabState(workspace, tab)
    if state == "working" { return spin(second) }
    if state == "error" || state == "cancelled" { return "!" }
    if state == "completed" { return "●" }
    return "○"
}

func tabTint(_ workspace, _ tab) -> String {
    let state = tabState(workspace, tab)
    if state == "working" { return "#58A6FF" }
    if state == "error" { return "#F85149" }
    if state == "cancelled" || state == "completed" { return "#D29922" }
    return "#5A5A5E"
}

func agentKind(_ title: String) -> String {
    let lower = title.lowercased()
    if isOwnedMarker(title) || title.contains("π") || lower.contains(" pi") || lower.hasPrefix("pi") { return "pi" }
    if lower.contains("codex") { return "codex" }
    if lower.contains("claude") { return "claude" }
    if lower.contains("opencode") { return "opencode" }
    if lower.contains("gemini") { return "gemini" }
    if lower.contains("agent") { return "agent" }
    return "shell"
}

func isAgentTab(_ tab) -> Bool {
    return isSpinner(tab.title) || agentKind(tab.title) != "shell"
}

func agentCount(_ workspace) -> Int {
    return workspace.tabs.count { isAgentTab($0) }
}

func tabShowsDiff(_ workspace, _ tab) -> Bool {
    return tab.focused && hasDescription(workspace) && tabState(workspace, tab) == "idle"
}

func diffTokenTint(_ token: String) -> String {
    if token.hasPrefix("+") { return "#3FB950" }
    if token.hasPrefix("-") { return "#F85149" }
    if token.hasPrefix("↑") { return "#58A6FF" }
    if token.hasPrefix("↓") { return "#D29922" }
    return "#8E8E93"
}

func stateLabel(_ state: String) -> String {
    if state == "working" { return "Working" }
    if state == "completed" { return "Completed" }
    if state == "error" { return "Error" }
    if state == "cancelled" { return "Cancelled" }
    return "Idle"
}

func tabDetail(_ workspace, _ tab) -> String {
    let state = tabState(workspace, tab)
    if state != "idle" {
        if agentCount(workspace) == 1 {
            if state == "working" && hasProgress(workspace) { return workspace.progress.label }
            if state != "working" && hasLatestMessage(workspace) { return "\(stateLabel(state)) · \(workspace.latestMessage)" }
        }
        return "\(stateLabel(state)) · \(agentKind(tab.title))"
    }
    if tab.focused && hasDescription(workspace) { return workspace.description }
    return "Idle · \(agentKind(tab.title))"
}

VStack(alignment: .leading, spacing: 2) {
    // Compact repository/workspace navigator.
    HStack {
        Text("spaces").font(.headline).bold()
        Spacer()
        if (workspaces.count { $0.unread > 0 }) > 0 {
            Text("● \(workspaces.count { $0.unread > 0 }) ready")
                .font(.caption).foregroundColor("#D29922")
        }
    }
    .frame(height: 24)
    Divider()

    // Flat list: visual order exactly matches cmd+1, cmd+2, cmd+3, …
    for workspace in workspaces {
        let key = repoKey(workspace.directory, workspace.title)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(workspace.selected ? "▌" : " ")
                    .font(.caption).foregroundColor("#7A4FD8")
                Text("\(workspace.index + 1)").font(.caption).foregroundColor("#5A5A5E")
                Text(key).font(.body).bold().lineLimit(1).truncationMode(.tail)
                Spacer()
                if workspace.pr.number > 0 {
                    Text("#\(workspace.pr.number)")
                        .font(.caption).foregroundColor(prColor(workspace.pr.status, workspace.pr.stale))
                        .onTapGesture { openURL(workspace.pr.url) }
                }
                Text("×\(agentCount(workspace))").font(.caption).foregroundColor("#8E8E93")
                Text(workspaceGlyph(workspace, clock.second))
                    .font(.body).foregroundColor(workspaceTint(workspace))
            }
            Text(workspace.branch != "" ? workspace.branch : workspace.title)
                .font(.system(size: 12)).foregroundColor("#8E8E93")
                .lineLimit(1).truncationMode(.tail)
                .padding(.leading, 29)
        }
        .frame(height: 38)
        .padding(.horizontal, 3)
        .background(workspace.selected ? "#30283D" : "#00000000")
        .cornerRadius(4)
        .onTapGesture { cmux("workspace.select", workspace_id: workspace.id) }
    }

    Divider().padding(.top, 2)

    // Compact agent list. Shell/editor/browser surfaces stay in cmux's tab bar;
    // this section only shows recognized agent tabs and spinner-titled work.
    Text("agents").font(.headline).bold().frame(height: 24)
    Divider()

    for workspace in workspaces {
        for tab in workspace.tabs {
            if isAgentTab(tab) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Text(workspace.selected && tab.focused ? "▌" : " ")
                            .font(.caption).foregroundColor("#7A4FD8")
                        Text(tabGlyph(workspace, tab, clock.second))
                            .font(.body).foregroundColor(tabTint(workspace, tab))
                        Text(visibleTabTitle(tab.title)).font(.body).bold().lineLimit(1).truncationMode(.tail)
                        Spacer()
                    }
                    if tabShowsDiff(workspace, tab) {
                        HStack(spacing: 4) {
                            for token in workspace.description.split(separator: " ") {
                                Text("\(token)").font(.caption).foregroundColor(diffTokenTint(token))
                            }
                        }
                        .padding(.leading, 28)
                    } else {
                        Text(tabDetail(workspace, tab))
                            .font(.caption)
                            .foregroundColor(tabTint(workspace, tab))
                            .lineLimit(1).truncationMode(.tail)
                            .padding(.leading, 28)
                    }
                }
                .frame(height: 38)
                .padding(.horizontal, 3)
                .background(workspace.selected && tab.focused ? "#30283D" : "#00000000")
                .cornerRadius(4)
                .onTapGesture { cmux("surface.focus", surface_id: tab.id) }
            }
        }
    }
}
