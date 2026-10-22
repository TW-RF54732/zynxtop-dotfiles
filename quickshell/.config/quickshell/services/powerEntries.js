.pragma library

// Menu rows shared by the centered PowerMenu and the Dashboard flyout.
function build(capabilities, busy) {
    return [
        {key: "lock", icon: "lock", text: "Lock"},
        {key: "suspend", icon: "moon", text: "Sleep"},
        {key: "hibernate", icon: "hibernate", text: "Hibernate"},
        {key: "reboot", icon: "reboot", text: "Reboot", confirm: true},
        {key: "poweroff", icon: "power", text: "Power off", confirm: true}
    ].map(entry => Object.assign({enabled: !busy && !!capabilities[entry.key]}, entry))
}
