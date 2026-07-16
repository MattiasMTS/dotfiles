// repos.swift — herdr-inspired cmux sidebar.
//
// Two levels of navigation:
//   1. "spaces" lists workspaces in true cmd+N order, with repository name,
//      PR badge, agent count, aggregate state, and git branch.
//   2. "agents" lists recognized agent surfaces/tabs. Selecting a row focuses
//      that surface. Its second line preserves cmux's live progress
//      label, latest agent output, failure, cancellation, or git diff summary.
//
// cmux currently exposes progress/latestMessage per workspace rather than per
// surface. Spinner-prefixed tab titles are therefore the strongest per-agent
// working signal; otherwise workspace state is assigned to its focused tab.
// Selected workspace + selected surface use the purple rail.

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

// A spinner title identifies a background working agent. For progress-only
// integrations, attribute the workspace signal to the focused surface.
func tabIsWorking(_ workspace, _ tab) -> Bool {
    return isSpinner(tab.title) || (isWorking(workspace) && tab.focused)
}

func tabHasFailed(_ workspace, _ tab) -> Bool {
    return hasFailed(workspace) && tab.focused
}

func tabHasCancelled(_ workspace, _ tab) -> Bool {
    return hasCancelled(workspace) && tab.focused
}

func tabIsReady(_ workspace, _ tab) -> Bool {
    return !tabIsWorking(workspace, tab) && !tabHasFailed(workspace, tab) && !tabHasCancelled(workspace, tab) && tab.focused && (hasProgress(workspace) || workspace.unread > 0)
}

func tabGlyph(_ workspace, _ tab, _ second: Int) -> String {
    if tabIsWorking(workspace, tab) { return spin(second) }
    if tabHasFailed(workspace, tab) || tabHasCancelled(workspace, tab) { return "!" }
    if tabIsReady(workspace, tab) { return "●" }
    return "○"
}

func tabTint(_ workspace, _ tab) -> String {
    if tabIsWorking(workspace, tab) { return "#58A6FF" }
    if tabHasFailed(workspace, tab) { return "#F85149" }
    if tabHasCancelled(workspace, tab) { return "#D29922" }
    if tabIsReady(workspace, tab) { return "#D29922" }
    return "#5A5A5E"
}

func agentKind(_ title: String) -> String {
    let lower = title.lowercased()
    if title.contains("π") || lower.contains(" pi") || lower.hasPrefix("pi") { return "pi" }
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
    if !tab.focused || !hasDescription(workspace) { return false }
    if tabIsWorking(workspace, tab) && hasProgress(workspace) { return false }
    if (tabHasFailed(workspace, tab) || tabHasCancelled(workspace, tab)) && hasProgress(workspace) { return false }
    if tabIsReady(workspace, tab) && hasLatestMessage(workspace) { return false }
    return true
}

func diffTokenTint(_ token: String) -> String {
    if token.hasPrefix("+") { return "#3FB950" }
    if token.hasPrefix("-") { return "#F85149" }
    if token.hasPrefix("↑") { return "#58A6FF" }
    if token.hasPrefix("↓") { return "#D29922" }
    return "#8E8E93"
}

func tabDetail(_ workspace, _ tab) -> String {
    if tabIsWorking(workspace, tab) && hasProgress(workspace) { return workspace.progress.label }
    if (tabHasFailed(workspace, tab) || tabHasCancelled(workspace, tab)) && hasProgress(workspace) { return workspace.progress.label }
    if tabIsReady(workspace, tab) && hasLatestMessage(workspace) { return workspace.latestMessage }
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
                        Text(tab.title).font(.body).bold().lineLimit(1).truncationMode(.tail)
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
