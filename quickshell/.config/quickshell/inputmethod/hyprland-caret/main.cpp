#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/desktop/view/WLSurface.hpp>
#include <cmath>
#include <sstream>
#include <locale>
#include <stdexcept>

// Read-only compositor adapter: no hooks, dispatchers, input capture or text access.
static HANDLE pluginHandle;
static SP<SHyprCtlCommand> command;

static std::string caretGeometry(eHyprCtlOutputFormat, std::string) {
    if (!g_pInputManager) return "{\"valid\":false}";
    const auto input = g_pInputManager->m_relay.getFocusedTextInput();
    if (!input || !input->isEnabled() || !input->hasCursorRectangle())
        return "{\"valid\":false}";
    const auto surface = Desktop::View::CWLSurface::fromResource(input->focusedSurface());
    if (!surface) return "{\"valid\":false}";
    const auto origin = surface->getSurfaceBoxGlobal();
    if (!origin) return "{\"valid\":false}";
    const auto cursor = input->cursorBox();
    const double x = origin->x + cursor.x, top = origin->y + cursor.y;
    const double bottom = top + cursor.h;
    if (!std::isfinite(x) || !std::isfinite(top) || !std::isfinite(bottom))
        return "{\"valid\":false}";
    std::ostringstream output;
    output.imbue(std::locale::classic());
    output << "{\"valid\":true,\"x\":" << x << ",\"top\":" << top
        << ",\"y\":" << bottom << ",\"source\":\"hyprland-text-input\"}";
    return output.str();
}

APICALL EXPORT std::string PLUGIN_API_VERSION() { return HYPRLAND_API_VERSION; }
APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    pluginHandle = handle;
    if (HyprlandAPI::getHyprlandVersion(handle).hash != GIT_COMMIT_HASH)
        throw std::runtime_error("quickshell-caret: Hyprland header/runtime version mismatch");
    command = HyprlandAPI::registerHyprCtlCommand(handle,
        SHyprCtlCommand{"quickshell-caret", true, caretGeometry});
    if (!command) throw std::runtime_error("quickshell-caret: command registration failed");
    return {"quickshell-caret", "Read-only focused text caret geometry for QML shells", "local", "0.1"};
}
APICALL EXPORT void PLUGIN_EXIT() {
    if (command) HyprlandAPI::unregisterHyprCtlCommand(pluginHandle, command);
    command.reset();
}
