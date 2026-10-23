.pragma library

// Menu rows shared by the Dashboard flyout.
function build(capabilities, busy) {
    return [
        {key: "lock", icon: "lock", text: "Lock"},
        {key: "suspend", icon: "moon", text: "Sleep"},
        {key: "hibernate", icon: "hibernate", text: "Hibernate"},
        {key: "reboot", icon: "reboot", text: "Reboot"},
        {key: "poweroff", icon: "power", text: "Power off"}
    ].map(entry => Object.assign({enabled: !busy && !!capabilities[entry.key]}, entry))
}
