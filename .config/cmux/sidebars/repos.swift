// repos.swift — custom cmux sidebar: a static, numbered workspace list.
// Workspaces render in cmux native order (row number == cmd+N), grouped into
// repo "folders" (a header is printed when the repo changes). Selection is a
// subtle row-background highlight. The right-side slot shows AGENT state: a green
// braille spinner = working (read from the surface-title glyph), green ● =
// output/unread, grey ○ = idle. Line 2 is the branch. The #PR pill opens the PR
// in the DEFAULT browser via openURL(url) (github.com is routed externally by
// browser.urlsToAlwaysOpenExternally in cmux.json).

func repoDirOf(_ path: String) -> String {
    let parts = path.split(separator: "/")
    for i in 0..<parts.count {
        if parts[i] == "github.com" && i + 2 < parts.count {
            return "\(parts[i + 2])"
        }
    }
    return parts.isEmpty ? path : "\(parts[parts.count - 1])"
}

func repoLabelOf(_ path: String) -> String {
    let d = repoDirOf(path)
    let segs = d.split(separator: ".")
    if segs.count >= 2 && "\(segs[1])".hasPrefix("ms-") {
        return "\(segs[0])"
    }
    return d
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
        let prevSame = j > 0 ? (repoLabelOf(w.directory) == repoLabelOf(workspaces[j - 1].directory)) : false
        VStack(alignment: .leading, spacing: 1) {
            if !prevSame {
                Text("▎ \(repoLabelOf(w.directory))")
                    .font(.title2).fontWeight(.bold).foregroundColor("#8E8E93")
            }
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Button(action: { cmux("workspace.select", workspace_id: w.id) }) {
                        HStack(spacing: 6) {
                            Text("\(j + 1)").font(.body).foregroundColor("#5A5A5E")
                            Text(w.title).font(.title3).lineLimit(1)
                        }
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
                HStack(spacing: 6) {
                    Text("    \(branchShort(w.branch, w.title))")
                        .font(.body).foregroundColor(.secondary).lineLimit(1)
                    Spacer()
                }
            }
            .padding(4)
            .background(w.selected ? "#2C2C2E" : "#00000000")
            .cornerRadius(6)
        }
    }
}
