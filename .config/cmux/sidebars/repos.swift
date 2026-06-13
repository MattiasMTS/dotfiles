// repos.swift — custom cmux sidebar: workspaces GROUPED BY REPO. Each repo gets
// a header row (chevron + SF Symbol icon + repo name + member count); under it,
// its workspaces as 2-line rows. A dim 1–9 index shows the cmd+N number (the
// TRUE sidebar position via w.index+1). Right-side = agent state: green braille
// spinner = working (surface-title glyph), green ● = output/unread, grey ○ =
// idle. Line 2 = branch (ms/ prefix stripped). Selection = row highlight.
// #PR opens in the DEFAULT browser via openURL(url). ACCORDION auto-fold:
// multi-workspace repos collapse to a header-only row (▸ + count) unless they
// contain the active workspace (▾, expanded); selection IS the state, no @State.
// Solo repos always stay expanded. Active repo = repoKey("", selectedTitle).

// repoKey: groups workspaces by their underlying repo. Lovable worktrees are
// sibling dirs `lovable` / `lovable.ms-<branch>` under .../lovablelabs/ — all
// collapse to "lovable". Standalone repos live under .../projects/ and their
// directory basename == title (e.g. dotfiles, manicule.nvim,
// terraform-provider-clickhouse), so the title is the key. Uses only
// render-proven primitives (contains, split("/")[..], hasPrefix).
func repoKey(_ dir: String, _ title: String) -> String {
    if dir.contains("/lovablelabs/") { return "lovable" }
    if title.hasPrefix("lovable") { return "lovable" }
    return title
}

func repoIcon(_ k: String) -> String {
    if k.contains("lovable") { return "heart.fill" }
    if k.contains("dotfiles") { return "gearshape.fill" }
    return "folder.fill"
}

func repoTint(_ k: String) -> String {
    if k.contains("lovable") { return "#FF4D6D" }
    if k.contains("dotfiles") { return "#8E8E93" }
    return "#8E8E93"
}

func branchShort(_ b: String, _ title: String) -> String {
    if b == "" { return title }
    if b.hasPrefix("ms/") { return "\(b.split(separator: "/")[1])" }
    return b
}

func isSpinner(_ t: String) -> Bool {
    return t.hasPrefix("⠁") || t.hasPrefix("⠂") || t.hasPrefix("⠄") || t.hasPrefix("⡀") || t.hasPrefix("⢀") || t.hasPrefix("⠠") || t.hasPrefix("⠐") || t.hasPrefix("⠈")
}

func spin(_ sec: Int) -> String {
    let f = sec % 8
    if f == 0 { return "⠋" }
    if f == 1 { return "⠙" }
    if f == 2 { return "⠹" }
    if f == 3 { return "⠸" }
    if f == 4 { return "⠼" }
    if f == 5 { return "⠴" }
    if f == 6 { return "⠦" }
    return "⠧"
}

VStack(alignment: .leading, spacing: 4) {
    HStack {
        Text("Workspaces").font(.title2).bold()
        Spacer()
        if (workspaces.count { $0.unread > 0 }) > 0 {
            Text("● \(workspaces.count { $0.unread > 0 }) need you")
                .font(.body).foregroundColor("#3FB950")
        }
    }
    Divider()
    for j in 0..<workspaces.count {
        let w = workspaces[j]
        let key = repoKey(w.directory, w.title)
        let cnt = workspaces.count { repoKey($0.directory, $0.title) == key }
        let activeKey = repoKey("", selectedTitle)
        let expanded = cnt == 1 || key == activeKey
        let collapsed = cnt > 1 && key != activeKey
        if j == 0 || repoKey(workspaces[j - 1].directory, workspaces[j - 1].title) != key {
            Button(action: { cmux("workspace.select", workspace_id: w.id) }) {
                HStack(spacing: 6) {
                    if cnt > 1 {
                        if expanded {
                            Text("▾").font(.title3).foregroundColor("#5A5A5E")
                        } else {
                            Text("▸").font(.title3).foregroundColor("#5A5A5E")
                        }
                    }
                    Image(systemName: repoIcon(key)).foregroundColor(repoTint(key))
                    Text(key).font(.headline).bold().lineLimit(1)
                    Spacer()
                    if collapsed {
                        if (workspaces.count { repoKey($0.directory, $0.title) == key && ($0.tabs.contains { isSpinner($0.title) }) }) > 0 {
                            Text(spin(clock.second)).font(.title3).foregroundColor("#3FB950")
                        } else {
                            if (workspaces.count { repoKey($0.directory, $0.title) == key && $0.unread > 0 }) > 0 {
                                Text("●").font(.body).foregroundColor("#3FB950")
                            } else {
                                Text("○").font(.body).foregroundColor("#5A5A5E")
                            }
                        }
                    }
                    Text("\(cnt)").font(.body).foregroundColor("#8E8E93")
                }
            }
            .padding(.top, 4)
        }
        if expanded {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("  \(w.index + 1)").font(.body).foregroundColor("#5A5A5E")
                    Text("·").font(.body).foregroundColor("#5A5A5E")
                    Button(action: { cmux("workspace.select", workspace_id: w.id) }) {
                        Text(branchShort(w.branch, w.title)).font(.title3).lineLimit(1)
                    }
                    Spacer()
                    if (w.tabs.contains { isSpinner($0.title) }) {
                        Text(spin(clock.second)).font(.title3).foregroundColor("#3FB950")
                    } else {
                        if w.unread > 0 {
                            Text("●").font(.body).foregroundColor("#3FB950")
                        } else {
                            Text("○").font(.body).foregroundColor("#5A5A5E")
                        }
                    }
                    if w.pr.number > 0 {
                        Button(action: { openURL(w.pr.url) }) {
                            Text("#\(w.pr.number)").font(.body).foregroundColor("#8E8E93")
                        }
                    }
                }
            }
            .padding(4)
            .background(w.selected ? "#2C2C2E" : "#00000000")
            .cornerRadius(6)
        }
    }
}
