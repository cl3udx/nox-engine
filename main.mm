#include <iostream>
#include <thread>
#include <chrono>
#include <cmath>
#include <cstring>
#include <mach/mach.h>
#include <mach-dyld.h>
#include <sys/mman.h>
#include <imgui.h>

// ==========================================
// 1. CONFIG & OFFSETS (Ground Truth)
// ==========================================
namespace config {
    // Build-dependent offsets: UNKNOWN until measured on actual CounterFlame binary
    inline constexpr uintptr_t kGWorldOffset       = 0x0;
    inline constexpr uintptr_t kLocalPlayerOffset  = 0x0;
    inline constexpr uintptr_t kPlayerController   = 0x0;
    inline constexpr uintptr_t kAcknowledgedPawn   = 0x0;
    inline constexpr uintptr_t kPlayerCameraManager= 0x0;
    inline constexpr uintptr_t kActorListOffset    = 0x0;
    inline constexpr uintptr_t kRoundManagerOffset = 0x0;
    inline constexpr uintptr_t kNetworkManager     = 0x0;

    // Feature Toggles & Settings
    inline bool bMenuVisible       = false; // Изначально скрыто, открывается по тапу на плавающую кнопку
    inline bool bEspBox            = true;
    inline bool bEspSkeleton       = true;
    inline bool bEspName           = true;
    inline bool bEspHealth         = true;
    inline bool bEspDistance       = true;
    inline bool bEspLoot           = false;
    inline bool bRadar             = false;
    inline bool bChams             = false;
    
    inline bool bAimbot            = false;
    inline float fAimbotFov        = 4.5f;
    inline float fAimbotSmooth     = 6.0f;
    inline bool bShowFovCircle     = true;
    
    inline bool bNoRecoil          = true;
    inline bool bInfiniteAmmo      = false;
    inline bool bGodMode           = false;
    inline bool bSpeedhack         = false;
    inline float fSpeedMultiplier  = 1.15f;
    inline bool bBunnyhop          = false;
    inline bool bCustomFov         = false;
    inline float fCameraFov        = 100.0f;

    // Visuals & Effects
    inline bool bCustomCrosshair   = true;
    inline int  iCrosshairStyle    = 0; // 0 - Dot, 1 - Cross
    inline bool bRainbowAccent     = true;
    inline bool bHitmarker         = true;

    // Match Exploits
    inline bool bAutoWin           = false;
    inline bool bFastPlantDefuse   = false;
    inline bool bNoFlash           = false;
    inline bool bThirdPerson       = false;
    inline bool bHitboxExpander    = false;
    inline float fHitboxScale      = 1.5f;

    // Hardcore & Server Disruption
    inline bool bServerCrashFlood  = false;
    inline bool bLagSwitch         = false;
    inline bool bInvisibleMode     = false;
    inline bool bSkinChanger       = true;
    inline bool bInfiniteMoney     = true;
    inline bool bInstantKillMod    = false;
    inline float fDamageMultiplier = 10.0f;
}

// ==========================================
// 2. MEMORY & VIRTUAL MACHINE WRAPPER
// ==========================================
namespace memory {
    inline uintptr_t GetModuleBase(const char* moduleName) {
        uint32_t count = _dyld_image_count();
        for (uint32_t i = 0; i < count; ++i) {
            const char* name = _dyld_get_image_name(i);
            if (name && strstr(name, moduleName)) {
                return static_cast<uintptr_t>(_dyld_get_image_header_slide(i) + 
                       reinterpret_cast<uintptr_t>(_dyld_get_image_header(i)));
            }
        }
        return 0;
    }

    inline bool SafeRead(uintptr_t address, void* buffer, size_t size) {
        if (!address || !buffer) return false;
        vm_size_t outSize = 0;
        kern_return_t kr = vm_read_overwrite(mach_task_self(), 
                                            static_cast<vm_address_t>(address), 
                                            static_cast<vm_size_t>(size), 
                                            static_cast<vm_address_t>(reinterpret_cast<uintptr_t>(buffer)), 
                                            &outSize);
        return (kr == KERN_SUCCESS && outSize == size);
    }

    inline bool SafeWrite(uintptr_t address, const void* buffer, size_t size) {
        if (!address || !buffer) return false;
        mach_port_t task = mach_task_self();
        vm_address_t targetPage = address & ~(vm_address_t)(PAGE_SIZE - 1);
        
        kern_return_t kr = vm_protect(task, targetPage, PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
        if (kr != KERN_SUCCESS) return false;

        std::memcpy(reinterpret_cast<void*>(address), buffer, size);

        vm_protect(task, targetPage, PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
        return true;
    }

    template <typename T>
    inline T Read(uintptr_t address) {
        T val{};
        SafeRead(address, &val, sizeof(T));
        return val;
    }

    template <typename T>
    inline bool Write(uintptr_t address, const T& val) {
        return SafeWrite(address, &val, sizeof(T));
    }
}

// ==========================================
// 3. UI, FLOATING TOGGLE & IMGUI MENU
// ==========================================
namespace menu {

    // Плавающая кнопка-индикатор: её можно таскать пальцем по экрану, а по тапу открывается меню
    inline void RenderFloatingToggle() {
        ImGuiWindowFlags flags = ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | 
                                 ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_AlwaysAutoResize;

        ImGui::SetNextWindowPos(ImVec2(50, 100), ImGuiCond_FirstUseEver);
        ImGui::SetNextWindowBgAlpha(0.65f);

        ImGui::Begin("##FloatingToggleWindow", nullptr, flags);

        ImVec4 neonColor = config::bRainbowAccent ? 
            ImVec4(sinf(ImGui::GetTime() * 2.0f) * 0.3f + 0.7f, 
                   sinf(ImGui::GetTime() * 2.0f + 2.094f) * 0.3f + 0.7f, 
                   sinf(ImGui::GetTime() * 2.0f + 4.188f) * 0.3f + 0.7f, 1.0f) : 
            ImVec4(0.00f, 0.80f, 1.00f, 1.00f);

        ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.12f, 0.12f, 0.16f, 0.90f));
        ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.20f, 0.20f, 0.28f, 1.00f));
        ImGui::PushStyleColor(ImGuiCol_ButtonActive, neonColor);
        ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 25.0f);

        if (ImGui::Button(" CF ", ImVec2(48, 48))) {
            config::bMenuVisible = !config::bMenuVisible;
        }

        ImGui::PopStyleVar();
        ImGui::PopStyleColor(3);

        if (ImGui::IsItemHovered()) {
            ImGui::SetTooltip("CounterFlame Menu\nDrag to move | Tap to open");
        }

        ImGui::End();
    }

    inline void RenderImGuiMenu() {
        // Плавающая кнопка рендерится всегда
        RenderFloatingToggle();

        if (!config::bMenuVisible) return;

        ImVec4 accentColor = config::bRainbowAccent ? 
            ImVec4(sinf(ImGui::GetTime() * 1.5f) * 0.3f + 0.7f, 
                   sinf(ImGui::GetTime() * 1.5f + 2.094f) * 0.3f + 0.7f, 
                   sinf(ImGui::GetTime() * 1.5f + 4.188f) * 0.3f + 0.7f, 1.0f) : 
            ImVec4(0.00f, 0.80f, 1.00f, 1.00f);

        ImGuiStyle& style = ImGui::GetStyle();
        style.WindowRounding = 10.0f;
        style.ChildRounding = 6.0f;
        style.FrameRounding = 5.0f;
        style.GrabRounding = 5.0f;
        style.WindowPadding = ImVec2(12, 12);
        style.FramePadding = ImVec2(8, 6);
        style.ItemSpacing = ImVec2(8, 8);

        style.Colors[ImGuiCol_WindowBg]         = ImVec4(0.07f, 0.07f, 0.09f, 0.96f);
        style.Colors[ImGuiCol_ChildBg]          = ImVec4(0.10f, 0.10f, 0.13f, 1.00f);
        style.Colors[ImGuiCol_Border]           = ImVec4(0.20f, 0.20f, 0.26f, 0.80f);
        style.Colors[ImGuiCol_CheckMark]        = accentColor;
        style.Colors[ImGuiCol_SliderGrab]       = accentColor;
        style.Colors[ImGuiCol_SliderGrabActive] = accentColor;
        style.Colors[ImGuiCol_Button]           = ImVec4(0.15f, 0.15f, 0.20f, 1.00f);
        style.Colors[ImGuiCol_ButtonHovered]    = ImVec4(0.22f, 0.22f, 0.30f, 1.00f);
        style.Colors[ImGuiCol_ButtonActive]     = accentColor;
        style.Colors[ImGuiCol_Header]           = ImVec4(0.15f, 0.15f, 0.20f, 1.00f);
        style.Colors[ImGuiCol_HeaderHovered]    = ImVec4(0.22f, 0.22f, 0.30f, 1.00f);
        style.Colors[ImGuiCol_HeaderActive]     = accentColor;

        ImGui::SetNextWindowSize(ImVec2(620, 480), ImGuiCond_FirstUseEver);
        ImGui::Begin("CounterFlame // Elite Mod Menu [v3.0]", &config::bMenuVisible, 
                     ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize);

        // --- QUICK PRESETS BAR ---
        ImGui::BeginChild("PresetsBar", ImVec2(0, 36), true, ImGuiWindowFlags_NoScrollbar);
        ImGui::Text("Presets:");
        ImGui::SameLine();
        if (ImGui::Button("Legit Mode", ImVec2(90, 22))) {
            config::bAimbot = true; config::fAimbotFov = 3.0f; config::bServerCrashFlood = false;
        }
        ImGui::SameLine();
        if (ImGui::Button("Rage / HVH", ImVec2(90, 22))) {
            config::bAimbot = true; config::fAimbotFov = 25.0f; config::bInstantKillMod = true;
        }
        ImGui::SameLine();
        if (ImGui::Button("Reset All", ImVec2(80, 22))) {
            config::bAimbot = false; config::bServerCrashFlood = false; config::bLagSwitch = false;
        }
        ImGui::EndChild();

        ImGui::Spacing();

        // --- MAIN TABS ---
        if (ImGui::BeginTabBar("MenuTabs")) {
            
            // 1. VISUALS
            if (ImGui::BeginTabItem("Visuals")) {
                ImGui::Columns(2, "VisualCols", false);
                
                ImGui::BeginChild("VisLeft", ImVec2(0, 310), true);
                ImGui::TextColored(accentColor, "Player ESP");
                ImGui::Separator();
                ImGui::Checkbox("Box ESP", &config::bEspBox);
                ImGui::Checkbox("Skeleton ESP", &config::bEspSkeleton);
                ImGui::Checkbox("Name & Health", &config::bEspName);
                ImGui::Checkbox("Distance Tag", &config::bEspDistance);
                ImGui::Checkbox("Mini-Radar", &config::bRadar);
                ImGui::EndChild();

                ImGui::NextColumn();

                ImGui::BeginChild("VisRight", ImVec2(0, 310), true);
                ImGui::TextColored(accentColor, "World & Overlay");
                ImGui::Separator();
                ImGui::Checkbox("Loot / Weapon ESP", &config::bEspLoot);
                ImGui::Checkbox("Chams (Wallhack)", &config::bChams);
                ImGui::Spacing();
                ImGui::Checkbox("Custom Crosshair", &config::bCustomCrosshair);
                if (config::bCustomCrosshair) {
                    ImGui::Combo("Style", &config::iCrosshairStyle, "Dot\0Cross\0");
                }
                ImGui::Checkbox("Hitmarkers", &config::bHitmarker);
                ImGui::Checkbox("Rainbow Accent", &config::bRainbowAccent);
                ImGui::EndChild();

                ImGui::Columns(1);
                ImGui::EndTabItem();
            }

            // 2. AIMBOT
            if (ImGui::BeginTabItem("Aimbot")) {
                ImGui::BeginChild("AimChild", ImVec2(0, 310), true);
                ImGui::TextColored(accentColor, "Aim Assistance & Targeting");
                ImGui::Separator();
                ImGui::Checkbox("Enable Aimbot", &config::bAimbot);
                ImGui::SliderFloat("FOV Radius", &config::fAimbotFov, 1.0f, 30.0f, "%.1f deg");
                ImGui::Checkbox("Show FOV Circle", &config::bShowFovCircle);
                ImGui::SliderFloat("Smoothing", &config::fAimbotSmooth, 1.0f, 20.0f, "%.1f");
                ImGui::Spacing();
                ImGui::Checkbox("No Recoil", &config::bNoRecoil);
                ImGui::Checkbox("Hitbox Expander", &config::bHitboxExpander);
                if (config::bHitboxExpander) {
                    ImGui::SliderFloat("Scale", &config::fHitboxScale, 1.0f, 3.0f, "%.1fx");
                }
                ImGui::EndChild();
                ImGui::EndTabItem();
            }

            // 3. MISC
            if (ImGui::BeginTabItem("Misc")) {
                ImGui::BeginChild("MiscChild", ImVec2(0, 310), true);
                ImGui::TextColored(accentColor, "Player Tweaks & Movement");
                ImGui::Separator();
                ImGui::Checkbox("God Mode", &config::bGodMode);
                ImGui::Checkbox("Infinite Ammo", &config::bInfiniteAmmo);
                ImGui::Checkbox("No Flashbang / Smoke", &config::bNoFlash);
                ImGui::Checkbox("Third-Person View", &config::bThirdPerson);
                ImGui::Checkbox("Bunnyhop", &config::bBunnyhop);
                ImGui::Spacing();
                ImGui::Checkbox("Speedhack", &config::bSpeedhack);
                if (config::bSpeedhack) {
                    ImGui::SliderFloat("Multiplier", &config::fSpeedMultiplier, 1.0f, 3.0f, "%.2fx");
                }
                ImGui::EndChild();
                ImGui::EndTabItem();
            }

            // 4. HARDCORE
            if (ImGui::BeginTabItem("Hardcore")) {
                ImGui::BeginChild("HardcoreChild", ImVec2(0, 310), true);
                ImGui::TextColored(ImVec4(1.0f, 0.2f, 0.2f, 1.0f), "Server Disruption & Exploits");
                ImGui::Separator();
                ImGui::Checkbox("Auto-Win Round", &config::bAutoWin);
                ImGui::Checkbox("Fast Plant & Defuse", &config::bFastPlantDefuse);
                ImGui::Checkbox("Server Crash Flood", &config::bServerCrashFlood);
                ImGui::Checkbox("Lag Switch (Packet Freeze)", &config::bLagSwitch);
                ImGui::Checkbox("Invisible Mode", &config::bInvisibleMode);
                ImGui::Checkbox("Infinite Money", &config::bInfiniteMoney);
                ImGui::Checkbox("Skin Changer", &config::bSkinChanger);
                ImGui::EndChild();
                ImGui::EndTabItem();
            }

            // 5. CONFIG
            if (ImGui::BeginTabItem("Config")) {
                ImGui::BeginChild("ConfigChild", ImVec2(0, 310), true);
                ImGui::TextColored(accentColor, "Environment & Status");
                ImGui::Separator();
                ImGui::Text("Target OS: iOS (arm64)");
                ImGui::Text("Engine: Unity IL2CPP / CounterFlame");
                ImGui::Spacing();
                if (ImGui::Button("Close Menu", ImVec2(160, 36))) {
                    config::bMenuVisible = false;
                }
                ImGui::EndChild();
                ImGui::EndTabItem();
            }

            ImGui::EndTabBar();
        }

        // --- STATUS BAR ---
        ImGui::Separator();
        ImGui::TextColored(ImVec4(0.5f, 0.5f, 0.6f, 1.0f), "Status: Hook Active | Drag floating 'CF' to move");

        ImGui::End();
    }

    // ==========================================
    // 4. SCREEN VISUALS & EFFECTS RENDERER
    // ==========================================
    inline void RenderScreenVisuals() {
        ImDrawList* drawList = ImGui::GetBackgroundDrawList();
        ImVec2 screenSize = ImGui::GetIO().DisplaySize;
        ImVec2 center(screenSize.x * 0.5f, screenSize.y * 0.5f);

        // FOV Circle
        if (config::bAimbot && config::bShowFovCircle) {
            float radius = config::fAimbotFov * 18.0f;
            drawList->AddCircle(center, radius, IM_COL32(0, 220, 255, 160), 64, 1.5f);
        }

        // Custom Crosshair
        if (config::bCustomCrosshair) {
            ImU32 crossColor = IM_COL32(0, 255, 200, 230);
            if (config::iCrosshairStyle == 0) {
                drawList->AddCircleFilled(center, 2.5f, crossColor);
                drawList->AddCircle(center, 3.5f, IM_COL32(0, 0, 0, 200), 12, 1.0f);
            } else {
                float size = 8.0f;
                drawList->AddLine(ImVec2(center.x - size, center.y), ImVec2(center.x + size, center.y), crossColor, 1.5f);
                drawList->AddLine(ImVec2(center.x, center.y - size), ImVec2(center.x, center.y + size), crossColor, 1.5f);
            }
        }
    }
}

// ==========================================
// 5. MAIN LOGIC LOOP & THREAD
// ==========================================
void MainThread() {
    uintptr_t baseAddress = 0;
    while (baseAddress == 0) {
        baseAddress = memory::GetModuleBase("CounterFlame");
        if (baseAddress == 0) {
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
        }
    }

    while (true) {
        // Validation boundary per frame
        if (config::kGWorldOffset != 0) {
            uintptr_t gWorld = memory::Read<uintptr_t>(baseAddress + config::kGWorldOffset);
            if (gWorld) {
                // Auto-Win logic
                if (config::bAutoWin && config::kRoundManagerOffset != 0) {
                    uintptr_t roundMgr = memory::Read<uintptr_t>(baseAddress + config::kRoundManagerOffset);
                    if (roundMgr) {
                        memory::Write<int32_t>(roundMgr + 0x40, 1);
                    }
                }
            }
        }

        // Hardcore Lag Switch execution
        if (config::bLagSwitch) {
            std::this_thread::sleep_for(std::chrono::milliseconds(300));
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
}

__attribute__((constructor)) void Init() {
    std::thread(MainThread).detach();
}
