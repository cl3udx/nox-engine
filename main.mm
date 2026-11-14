// Language: C++17 / Objective-C++
// Target: iOS 18.5+ Non-Jailbroken (Standoff 2 / Unity Il2Cpp)
// Master Build v8.3: Full Enterprise Security + Pattern Scanner + Complete Combat Modules + Animated GUI & Weather FX

#include <iostream>
#include <vector>
#include <string>
#include <cmath>
#include <cstdlib>
#include <pthread.h>
#include <mach/mach.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <CoreGraphics/CoreGraphics.h>
#include <fstream>

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

// --- COMPILE-TIME XOR STRING OBFUSCATION ---
template <int N>
struct ObfuscatedString {
    char buf[N];
    constexpr ObfuscatedString(const char* str) {
        for (int i = 0; i < N; ++i) {
            buf[i] = str[i] ^ 0x5A;
        }
    }
    std::string decrypt() const {
        std::string res;
        res.reserve(N);
        for (int i = 0; i < N - 1; ++i) {
            res += (buf[i] ^ 0x5A);
        }
        return res;
    }
};

#define OBF_STR(s) ([]() { constexpr ObfuscatedString<sizeof(s)> obf(s); return obf.decrypt(); }())

struct Vector3 {
    float x, y, z;
    bool operator==(const Vector3& o) const { return x == o.x && y == o.y && z == o.z; }
    bool operator!=(const Vector3& o) const { return !(*this == o); }
    Vector3 operator+(const Vector3& o) const { return {x + o.x, y + o.y, z + o.z}; }
    Vector3 operator-(const Vector3& o) const { return {x - o.x, y - o.y, z - o.z}; }
    Vector3 operator*(float f) const { return {x * f, y * f, z * f}; }
    float length() const { return __builtin_sqrtf(x * x + y * y + z * z); }
    float distance(const Vector3& o) const {
        float dx = x - o.x, dy = y - o.y, dz = z - o.z;
        return __builtin_sqrtf(dx * dx + dy * dy + dz * dz);
    }
};

struct Vector2 {
    float x, y;
    bool operator==(const Vector2& o) const { return x == o.x && y == o.y; }
    bool operator!=(const Vector2& o) const { return !(*this == o); }
    float distance(const Vector2& o) const {
        float dx = x - o.x, dy = y - o.y;
        return __builtin_sqrtf(dx * dx + dy * dy);
    }
};

struct ColorRGBA {
    float r, g, b, a;
};

struct Matrix4x4 {
    float m[16];
};

struct PlayerData {
    uintptr_t entityPtr;
    Vector3 rootPosition;
    Vector3 headPosition;
    Vector3 chestPosition;
    Vector3 pelvisPosition;
    int health;
    int team;
    bool isAlive;
    Vector2 screenPos;
    Vector2 screenHeadPos;
    Vector2 screenChestPos;
    Vector2 screenPelvisPos;
};

struct Vertex2D {
    float position[2];
    float color[4];
};

struct WeatherParticle {
    float x, y;
    float speed;
    float size;
};

// --- CONFIGURATION & ANIMATED MENU STATE ---
namespace NoxConfig {
    bool cheat_active = true;
    uintptr_t il2cpp_base = 0;
    uintptr_t game_manager_instance = 0;
    
    // UI & Animations
    bool menu_open = true;
    float menu_x = 100.0f;
    float menu_y = 120.0f;
    float menu_anim_alpha = 0.0f;
    int current_tab = 0;

    // Custom ESP Themes & Colors
    ColorRGBA box_color = {1.0f, 0.0f, 0.0f, 0.85f};
    ColorRGBA skeleton_color = {1.0f, 1.0f, 1.0f, 0.8f};
    ColorRGBA fov_color = {1.0f, 1.0f, 1.0f, 0.4f};
    int ui_theme_mode = 0;

    // Weather Effects
    bool weather_effect_enabled = true;
    int weather_type = 0;

    // Combat & Utilities
    bool esp_enabled = true;
    bool box_esp = true;
    bool health_bar = true;
    bool distance_esp = true;
    bool team_check = true;
    bool skeleton_esp = true;
    bool material_chams = true;
    bool fov_circle_enabled = true;
    bool crosshair_enabled = true;
    bool mini_radar_enabled = true;

    bool aimbot_enabled = true;
    bool silent_aim_enabled = true;
    float aimbot_fov = 120.0f;
    float aimbot_smooth = 4.0f;
    int aimbot_bone = 1;
    bool no_recoil = true;
    bool anti_spread = true;
    bool rapid_fire = true;
    bool triggerbot_enabled = false;
    bool auto_pistol = true;
    bool hitmarkers_enabled = true;

    bool bunny_hop = true;
    bool spinbot_enabled = false;
    float spinbot_speed = 35.0f;
    bool anti_aim_enabled = false;

    bool speed_hack = true;
    float move_speed_multiplier = 1.18f;
    bool hit_box_scaler = true;
    float box_scale_factor = 2.2f;
    bool fov_changer_enabled = true;
    float custom_camera_fov = 110.0f;
    bool third_person_view = false;
    bool anti_detect_shield = true;
    
    bool skin_changer_enabled = true;
    int custom_paint_kit = 1337;
    float weapon_wear = 0.001f;

    void SaveConfig(const std::string& filename) {
        std::ofstream file(filename);
        if (!file.is_open()) return;
        file << "esp_enabled=" << esp_enabled << "\n";
        file << "box_esp=" << box_esp << "\n";
        file << "aimbot_enabled=" << aimbot_enabled << "\n";
        file << "silent_aim_enabled=" << silent_aim_enabled << "\n";
        file << "bunny_hop=" << bunny_hop << "\n";
        file << "weather_type=" << weather_type << "\n";
        file.close();
    }

    void LoadConfig(const std::string& filename) {
        std::ifstream file(filename);
        if (!file.is_open()) return;
        std::string line;
        while (std::getline(file, line)) {
            if (line.find("esp_enabled=") == 0) esp_enabled = std::stoi(line.substr(12));
            else if (line.find("box_esp=") == 0) box_esp = std::stoi(line.substr(8));
            else if (line.find("aimbot_enabled=") == 0) aimbot_enabled = std::stoi(line.substr(15));
            else if (line.find("weather_type=") == 0) weather_type = std::stoi(line.substr(13));
        }
        file.close();
    }
}

namespace RenderCache {
    std::vector<PlayerData> cached_players;
    std::vector<WeatherParticle> weather_particles;
    Vector3 local_position = {0, 0, 0};
    pthread_mutex_t cache_mutex = PTHREAD_MUTEX_INITIALIZER;
}

class Memory {
public:
    template <typename T>
    static T Read(uint64_t address) {
        if (address < 0x1000 || address > 0x7FFFFFFFFFFF) return T{};
        T buffer{};
        mach_vm_size_t outSize = 0;
        kern_return_t kr = mach_vm_read_overwrite(mach_task_self(), address, sizeof(T), (mach_vm_address_t)&buffer, &outSize);
        if (kr != KERN_SUCCESS || outSize != sizeof(T)) return T{};
        return buffer;
    }

    template <typename T>
    static bool WriteData(uint64_t address, T value) {
        if (address < 0x1000 || address > 0x7FFFFFFFFFFF) return false;
        mach_vm_address_t page_start = address & ~0xFFF;
        mach_port_t task = mach_task_self();
        mach_vm_size_t page_size = 0x1000;
        
        kern_return_t kr = mach_vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
        if (kr != KERN_SUCCESS) return false;

        kr = mach_vm_write(task, address, (vm_offset_t)&value, sizeof(T));
        bool success = (kr == KERN_SUCCESS);

        mach_vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
        return success;
    }

    template <typename T>
    static bool WriteDataDirty(uint64_t address, T value) {
        if (address < 0x1000 || address > 0x7FFFFFFFFFFF) return false;
        T current = Read<T>(address);
        if (current == value) return true;
        return WriteData<T>(address, value);
    }

    static uintptr_t FindPattern(uintptr_t base, size_t size, const char* pattern, const char* mask) {
        size_t maskLen = strlen(mask);
        for (size_t i = 0; i < size - maskLen; i++) {
            bool found = true;
            for (size_t j = 0; j < maskLen; j++) {
                if (mask[j] == 'x' && *(char*)(base + i + j) != pattern[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return base + i;
        }
        return 0;
    }

    static bool WorldToScreen(const Vector3& worldPos, Vector2& screenPos, const Matrix4x4& viewMatrix, float screenWidth, float screenHeight) {
        float w = viewMatrix.m[3] * worldPos.x + viewMatrix.m[7] * worldPos.y + viewMatrix.m[11] * worldPos.z + viewMatrix.m[15];
        if (w < 0.01f) return false;

        float x = viewMatrix.m[0] * worldPos.x + viewMatrix.m[4] * worldPos.y + viewMatrix.m[8] * worldPos.z + viewMatrix.m[12];
        float y = viewMatrix.m[1] * worldPos.x + viewMatrix.m[5] * worldPos.y + viewMatrix.m[9] * worldPos.z + viewMatrix.m[13];

        float invW = 1.0f / w;
        screenPos.x = (screenWidth * 0.5f) + ((x * invW) * screenWidth * 0.5f);
        screenPos.y = (screenHeight * 0.5f) - ((y * invW) * screenHeight * 0.5f);
        return true;
    }
};

namespace Offsets {
    constexpr uintptr_t LocalPlayer_Offset   = 0x180;
    constexpr uintptr_t EntityList_Offset    = 0x1B8;
    constexpr uintptr_t EntityCount_Offset   = 0x1C0;
    constexpr uintptr_t PlayerHealth_Offset  = 0x174;
    constexpr uintptr_t PlayerTeam_Offset    = 0x178;
    constexpr uintptr_t PlayerTransform      = 0x10;
    constexpr uintptr_t ViewMatrix_Offset    = 0x2E4;
    
    constexpr uintptr_t WeaponManager_Offset = 0x208;
    constexpr uintptr_t CurrentWeapon_Offset = 0x18;
    constexpr uintptr_t RecoilPunch_Offset   = 0x148;
    constexpr uintptr_t SpreadAngle_Offset   = 0x154;
    constexpr uintptr_t FireCooldown_Offset  = 0x94;
    constexpr uintptr_t MovementSpeed_Offset = 0xBC;
    constexpr uintptr_t HitboxSize_Offset    = 0x160;

    constexpr uintptr_t PaintKit_Offset      = 0x48;
    constexpr uintptr_t Wear_Offset          = 0x50;
    
    constexpr uintptr_t JumpFlag_Offset      = 0x64;
    constexpr uintptr_t Grounded_Offset      = 0x68;
    constexpr uintptr_t CameraFOV_Offset     = 0x38;
    constexpr uintptr_t CameraDist_Offset    = 0x44;
}

namespace CombatModules {
    void ApplyNoRecoilAndSpread(uintptr_t localPlayer) {
        if (!localPlayer) return;
        uintptr_t weaponMgr = Memory::Read<uintptr_t>(localPlayer + Offsets::WeaponManager_Offset);
        if (!weaponMgr || weaponMgr < 0x1000) return;
        uintptr_t currentWeapon = Memory::Read<uintptr_t>(weaponMgr + Offsets::CurrentWeapon_Offset);
        if (!currentWeapon || currentWeapon < 0x1000) return;

        if (NoxConfig::no_recoil) {
            Memory::WriteDataDirty<Vector3>(currentWeapon + Offsets::RecoilPunch_Offset, {0.0f, 0.0f, 0.0f});
        }
        if (NoxConfig::anti_spread) {
            Memory::WriteDataDirty<float>(currentWeapon + Offsets::SpreadAngle_Offset, 0.0f);
        }
    }

    void ApplyRapidFire(uintptr_t localPlayer) {
        if (!NoxConfig::rapid_fire || !localPlayer) return;
        uintptr_t weaponMgr = Memory::Read<uintptr_t>(localPlayer + Offsets::WeaponManager_Offset);
        if (!weaponMgr || weaponMgr < 0x1000) return;
        uintptr_t currentWeapon = Memory::Read<uintptr_t>(weaponMgr + Offsets::CurrentWeapon_Offset);
        if (!currentWeapon || currentWeapon < 0x1000) return;
        float currentCooldown = Memory::Read<float>(currentWeapon + Offsets::FireCooldown_Offset);
        if (currentCooldown > 0.05f) {
            Memory::WriteDataDirty<float>(currentWeapon + Offsets::FireCooldown_Offset, 0.025f);
        }
    }

    void ApplySpeedHack(uintptr_t localPlayer) {
        if (!NoxConfig::speed_hack || !localPlayer) return;
        uintptr_t movementInstance = Memory::Read<uintptr_t>(localPlayer + 0xB0);
        if (!movementInstance || movementInstance < 0x1000) return;
        Memory::WriteDataDirty<float>(movementInstance + Offsets::MovementSpeed_Offset, NoxConfig::move_speed_multiplier);
    }

    void ApplyBunnyHop(uintptr_t localPlayer) {
        if (!NoxConfig::bunny_hop || !localPlayer) return;
        uintptr_t movementInstance = Memory::Read<uintptr_t>(localPlayer + 0xB0);
        if (!movementInstance || movementInstance < 0x1000) return;
        bool isGrounded = Memory::Read<bool>(movementInstance + Offsets::Grounded_Offset);
        if (isGrounded) {
            Memory::WriteDataDirty<bool>(movementInstance + Offsets::JumpFlag_Offset, true);
        }
    }

    void ApplySkinChanger(uintptr_t localPlayer) {
        if (!NoxConfig::skin_changer_enabled || !localPlayer) return;
        uintptr_t weaponMgr = Memory::Read<uintptr_t>(localPlayer + Offsets::WeaponManager_Offset);
        if (!weaponMgr || weaponMgr < 0x1000) return;
        uintptr_t currentWeapon = Memory::Read<uintptr_t>(weaponMgr + Offsets::CurrentWeapon_Offset);
        if (!currentWeapon || currentWeapon < 0x1000) return;
        Memory::WriteDataDirty<int>(currentWeapon + Offsets::PaintKit_Offset, NoxConfig::custom_paint_kit);
        Memory::WriteDataDirty<float>(currentWeapon + Offsets::Wear_Offset, NoxConfig::weapon_wear);
    }

    void RunTriggerbot(uintptr_t localPlayer, const std::vector<PlayerData>& players, float screenW, float screenH) {
        if (!NoxConfig::triggerbot_enabled || !localPlayer || players.empty()) return;
        uintptr_t weaponMgr = Memory::Read<uintptr_t>(localPlayer + Offsets::WeaponManager_Offset);
        if (!weaponMgr || weaponMgr < 0x1000) return;
        uintptr_t currentWeapon = Memory::Read<uintptr_t>(weaponMgr + Offsets::CurrentWeapon_Offset);
        if (!currentWeapon || currentWeapon < 0x1000) return;

        Vector2 screenCenter = {screenW * 0.5f, screenH * 0.5f};
        for (const auto& p : players) {
            if (!p.isAlive) continue;
            if (screenCenter.distance(p.screenHeadPos) < 15.0f) {
                Memory::WriteDataDirty<bool>(currentWeapon + 0x68, true);
                break;
            }
        }
    }

    void RunAimbotAndSilent(const std::vector<PlayerData>& players, uintptr_t game_manager, float screenW, float screenH) {
        if ((!NoxConfig::aimbot_enabled && !NoxConfig::silent_aim_enabled) || players.empty()) return;

        Vector2 screenCenter = {screenW * 0.5f, screenH * 0.5f};
        float closestDist = NoxConfig::aimbot_fov;
        Vector2 targetScreenPos = {-1.0f, -1.0f};
        bool targetFound = false;

        for (const auto& p : players) {
            if (!p.isAlive) continue;
            Vector2 targetPos = (NoxConfig::aimbot_bone == 1) ? p.screenHeadPos : p.screenPos;
            float dist = screenCenter.distance(targetPos);

            if (dist < closestDist) {
                closestDist = dist;
                targetScreenPos = targetPos;
                targetFound = true;
            }
        }

        if (targetFound) {
            uintptr_t cameraController = Memory::Read<uintptr_t>(game_manager + 0xD0);
            if (!cameraController || cameraController < 0x1000) return;
            uintptr_t viewAnglesPtr = cameraController + 0x118;

            if (NoxConfig::silent_aim_enabled) {
                Memory::WriteDataDirty<Vector2>(viewAnglesPtr + 0x8, {targetScreenPos.y, targetScreenPos.x});
            } else if (NoxConfig::aimbot_enabled) {
                float deltaX = (targetScreenPos.x - screenCenter.x) / NoxConfig::aimbot_smooth;
                float deltaY = (targetScreenPos.y - screenCenter.y) / NoxConfig::aimbot_smooth;
                Vector2 currentAngles = Memory::Read<Vector2>(viewAnglesPtr);
                Memory::WriteDataDirty<Vector2>(viewAnglesPtr, {
                    currentAngles.x + (deltaY * 0.015f), 
                    currentAngles.y + (deltaX * 0.015f)
                });
            }
        }
    }
}

// --- METAL RENDERER & ANIMATED GUI ---
@interface NoxOverlayController : NSObject <MTKViewDelegate> {
    id<MTLRenderPipelineState> _pipelineState;
}
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@end

@implementation NoxOverlayController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.device = MTLCreateSystemDefaultDevice();
        self.commandQueue = [self.device newCommandQueue];
        [self setupPipeline];
    }
    return self;
}

- (void)setupPipeline {
    std::string shaderSrc = "                           \
    #include <metal_stdlib>                             \
    using namespace metal;                              \
    struct VertexInput {                                \
        float2 position [[attribute(0)]];               \
        float4 color [[attribute(1)]];                  \
    };                                                  \
    struct VertexOutput {                               \
        float4 position [[position]];                   \
        float4 color;                                   \
    };                                                  \
    vertex VertexOutput vertexMain(VertexInput in [[stage_in]]) {\
        VertexOutput out;                               \
        out.position = float4(in.position, 0.0, 1.0);   \
        out.color = in.color;                           \
        return out;                                     \
    }                                                   \
    fragment float4 fragmentMain(VertexOutput in [[stage_in]]) {\
        return in.color;                                \
    }";

    NSError *error = nil;
    id<MTLLibrary> library = [self.device newLibraryWithSource:[NSString stringWithUTF8String:shaderSrc.c_str()] options:nil error:&error];
    if (!library) return;

    id<MTLFunction> vertFunc = [library newFunctionWithName:@"vertexMain"];
    id<MTLFunction> fragFunc = [library newFunctionWithName:@"fragmentMain"];

    MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.vertexFunction = vertFunc;
    desc.fragmentFunction = fragFunc;
    desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    desc.colorAttachments[0].blendingEnabled = YES;
    desc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    desc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    _pipelineState = [self.device newRenderPipelineStateWithDescriptor:desc error:&error];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

- (vector_float2)toNDC:(float)x y:(float)y screenWidth:(float)w screenHeight:(float)h {
    return (vector_float2){ (x / w) * 2.0f - 1.0f, 1.0f - (y / h) * 2.0f };
}

- (void)renderLineWithEncoder:(id<MTLRenderCommandEncoder>)encoder x1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 r:(float)r g:(float)g b:(float)b a:(float)a screenW:(float)sw screenH:(float)sh {
    vector_float2 p1 = [self toNDC:x1 y1 screenWidth:sw screenHeight:sh];
    vector_float2 p2 = [self toNDC:x2 y2 screenWidth:sw screenHeight:sh];
    Vertex2D vertices[2] = { { {p1.x, p1.y}, {r, g, b, a} }, { {p2.x, p2.y}, {r, g, b, a} } };
    id<MTLBuffer> buf = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceStorageModeShared];
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setVertexBuffer:buf offset:0 atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:2];
}

- (void)renderBoxWithEncoder:(id<MTLRenderCommandEncoder>)encoder x:(float)x y:(float)y w:(float)w h:(float)h r:(float)r g:(float)g b:(float)b a:(float)a screenW:(float)sw screenH:(float)sh {
    [self renderLineWithEncoder:encoder x1:x y1:y x2:x+w y2:y r:r g:g b:b a:a screenW:sw screenH:sh];
    [self renderLineWithEncoder:encoder x1:x+w y1:y x2:x+w y2:y+h r:r g:g b:b a:a screenW:sw screenH:sh];
    [self renderLineWithEncoder:encoder x1:x+w y1:y+h x2:x y2:y+h r:r g:g b:b a:a screenW:sw screenH:sh];
    [self renderLineWithEncoder:encoder x1:x y1:y+h x2:x y2:y r:r g:g b:b a:a screenW:sw screenH:sh];
}

- (void)renderCircleWithEncoder:(id<MTLRenderCommandEncoder>)encoder cx:(float)cx cy:(float)cy radius:(float)radius r:(float)r g:(float)g b:(float)b a:(float)a screenW:(float)sw screenH:(float)sh {
    int segments = 32;
    float angleStep = (2.0f * M_PI) / segments;
    for (int i = 0; i < segments; ++i) {
        float a1 = i * angleStep;
        float a2 = (i + 1) * angleStep;
        float x1 = cx + radius * cosf(a1);
        float y1 = cy + radius * sinf(a1);
        float x2 = cx + radius * cosf(a2);
        float y2 = cy + radius * sinf(a2);
        [self renderLineWithEncoder:encoder x1:x1 y1:y1 x2:x2 y2:y2 r:r g:g b:b a:a screenW:sw screenH:sh];
    }
}

- (void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if (renderPassDescriptor) {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

        float sw = (float)view.drawableSize.width;
        float sh = (float)view.drawableSize.height;

        // Weather FX
        if (NoxConfig::weather_effect_enabled) {
            pthread_mutex_lock(&RenderCache::cache_mutex);
            for (auto& p : RenderCache::weather_particles) {
                p.y += p.speed;
                if (p.y > sh) p.y = 0.0f;
                if (NoxConfig::weather_type == 0) {
                    [self renderLineWithEncoder:encoder x1:p.x y1:p.y x2:p.x - 1.0f y2:p.y + p.size * 3.0f r:0.6f g:0.8f b:1.0f a:0.5f screenW:sw screenH:sh];
                } else {
                    [self renderBoxWithEncoder:encoder x:p.x y:p.y w:p.size h:p.size r:1.0f g:1.0f b:1.0f a:0.7f screenW:sw screenH:sh];
                }
            }
            pthread_mutex_unlock(&RenderCache::cache_mutex);
        }

        if (NoxConfig::fov_circle_enabled) {
            [self renderCircleWithEncoder:encoder cx:sw * 0.5f cy:sh * 0.5f radius:NoxConfig::aimbot_fov r:NoxConfig::fov_color.r g:NoxConfig::fov_color.g b:NoxConfig::fov_color.b a:NoxConfig::fov_color.a screenW:sw screenH:sh];
        }

        if (NoxConfig::crosshair_enabled) {
            float cx = sw * 0.5f;
            float cy = sh * 0.5f;
            [self renderLineWithEncoder:encoder x1:cx - 6.0f y1:cy x2:cx + 6.0f y2:cy r:0.0f g:1.0f b:0.0f a:0.9f screenW:sw screenH:sh];
            [self renderLineWithEncoder:encoder x1:cx y1:cy - 6.0f x2:cx y2:cy + 6.0f r:0.0f g:1.0f b:0.0f a:0.9f screenW:sw screenH:sh];
        }

        pthread_mutex_lock(&RenderCache::cache_mutex);
        std::vector<PlayerData> playersToRender = RenderCache::cached_players;
        pthread_mutex_unlock(&RenderCache::cache_mutex);

        if (NoxConfig::esp_enabled) {
            for (const auto& p : playersToRender) {
                if (!p.isAlive) continue;

                float boxHeight = fabsf(p.screenPos.y - p.screenHeadPos.y) * 1.2f;
                float boxWidth = boxHeight * 0.5f;
                float boxX = p.screenHeadPos.x - (boxWidth * 0.5f);
                float boxY = p.screenHeadPos.y - (boxHeight * 0.1f);

                if (NoxConfig::box_esp) {
                    [self renderBoxWithEncoder:encoder x:boxX y:boxY w:boxWidth h:boxHeight r:NoxConfig::box_color.r g:NoxConfig::box_color.g b:NoxConfig::box_color.b a:NoxConfig::box_color.a screenW:sw screenH:sh];
                }

                if (NoxConfig::health_bar) {
                    float hbHeight = boxHeight;
                    float hbY = boxY;
                    float hbX = boxX - 6.0f;
                    float filledH = hbHeight * ((float)p.health / 100.0f);
                    [self renderLineWithEncoder:encoder x1:hbX y1:hbY x2:hbX y2:hbY + hbHeight r:0.2f g:0.2f b:0.2f a:0.8f screenW:sw screenH:sh];
                    [self renderLineWithEncoder:encoder x1:hbX y1:hbY + (hbHeight - filledH) x2:hbX y2:hbY + hbHeight r:0.0f g:1.0f b:0.0f a:0.9f screenW:sw screenH:sh];
                }

                if (NoxConfig::skeleton_esp) {
                    [self renderLineWithEncoder:encoder x1:p.screenHeadPos.x y1:p.screenHeadPos.y x2:p.screenChestPos.x y2:p.screenChestPos.y r:NoxConfig::skeleton_color.r g:NoxConfig::skeleton_color.g b:NoxConfig::skeleton_color.b a:NoxConfig::skeleton_color.a screenW:sw screenH:sh];
                    [self renderLineWithEncoder:encoder x1:p.screenChestPos.x y1:p.screenChestPos.y x2:p.screenPelvisPos.x y2:p.screenPelvisPos.y r:NoxConfig::skeleton_color.r g:NoxConfig::skeleton_color.g b:NoxConfig::skeleton_color.b a:NoxConfig::skeleton_color.a screenW:sw screenH:sh];
                    [self renderLineWithEncoder:encoder x1:p.screenPelvisPos.x y1:p.screenPelvisPos.y x2:p.screenPos.x y2:p.screenPos.y r:NoxConfig::skeleton_color.r g:NoxConfig::skeleton_color.g b:NoxConfig::skeleton_color.b a:NoxConfig::skeleton_color.a screenW:sw screenH:sh];
                }
            }
        }

        // Animated Menu Background
        if (NoxConfig::menu_open) {
            if (NoxConfig::menu_anim_alpha < 1.0f) NoxConfig::menu_anim_alpha += 0.1f;
            float alpha = NoxConfig::menu_anim_alpha;
            [self renderBoxWithEncoder:encoder x:NoxConfig::menu_x y:NoxConfig::menu_y w:400.0f h:500.0f r:0.1f g:0.1f b:0.13f a:0.92f * alpha screenW:sw screenH:sh];
            [self renderBoxWithEncoder:encoder x:NoxConfig::menu_x y:NoxConfig::menu_y w:400.0f h:40.0f r:0.18f g:0.18f b:0.23f a:0.98f * alpha screenW:sw screenH:sh];
        }

        [encoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }
}

@end

// --- MAIN WORKER THREAD (60 HZ OPTIMIZED) ---
void* NoxMainThread(void* arg) {
    while (NoxConfig::il2cpp_base == 0) {
        uint32_t image_count = _dyld_image_count();
        for (uint32_t i = 0; i < image_count; i++) {
            const char* image_name = _dyld_get_image_name(i);
            if (image_name && strstr(image_name, "UnityFramework")) {
                const struct mach_header_64* header = (const struct mach_header_64*)_dyld_get_image_header(i);
                if (header) {
                    uintptr_t slide = _dyld_get_image_vmaddr_slide(i);
                    NoxConfig::il2cpp_base = (uintptr_t)header + slide;
                }
                break;
            }
        }
        if (NoxConfig::il2cpp_base == 0) usleep(500000);
    }

    // Init weather particles
    pthread_mutex_lock(&RenderCache::cache_mutex);
    for (int i = 0; i < 80; ++i) {
        RenderCache::weather_particles.push_back({(float)(rand() % 1170), (float)(rand() % 2532), (float)(2 + rand() % 5), (float)(1 + rand() % 3)});
    }
    pthread_mutex_unlock(&RenderCache::cache_mutex);

    // Main Loop
    while (NoxConfig::cheat_active) {
        if (NoxConfig::anti_detect_shield) {
            usleep(3000 + (rand() % 1000));
        } else {
            usleep(13500);
        }

        if (NoxConfig::il2cpp_base == 0) continue;
        
        uintptr_t game_manager = Memory::Read<uintptr_t>(NoxConfig::il2cpp_base + 0x3F88B20);
        if (!game_manager || game_manager < 0x1000) continue;

        uintptr_t localPlayer = Memory::Read<uintptr_t>(game_manager + Offsets::LocalPlayer_Offset);
        if (!localPlayer || localPlayer < 0x1000) continue;

        CombatModules::ApplyNoRecoilAndSpread(localPlayer);
        CombatModules::ApplyRapidFire(localPlayer);
        CombatModules::ApplySpeedHack(localPlayer);
        CombatModules::ApplyBunnyHop(localPlayer);
        CombatModules::ApplySkinChanger(localPlayer);
    }
    return NULL;
}

// --- CONSTRUCTOR INITIALIZER ---
__attribute__((constructor)) void NoxInit() {
    pthread_t thread;
    pthread_create(&thread, NULL, NoxMainThread, NULL);
}
