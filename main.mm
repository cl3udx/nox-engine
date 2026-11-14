// Language: C++17 / Objective-C++
// Target: iOS 18.5+ Non-Jailbroken (Standoff 2 / Unity Il2Cpp)
// Master Build v8.6: Final SDK Memory Functions Fix

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

namespace NoxConfig {
    bool cheat_active = true;
    uintptr_t il2cpp_base = 0;
    uintptr_t game_manager_instance = 0;
    
    bool menu_open = true;
    float menu_x = 100.0f;
    float menu_y = 120.0f;
    float menu_anim_alpha = 0.0f;
    int current_tab = 0;

    ColorRGBA box_color = {1.0f, 0.0f, 0.0f, 0.85f};
    ColorRGBA skeleton_color = {1.0f, 1.0f, 1.0f, 0.8f};
    ColorRGBA fov_color = {1.0f, 1.0f, 1.0f, 0.4f};
    int ui_theme_mode = 0;

    bool weather_effect_enabled = true;
    int weather_type = 0;

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
        vm_size_t outSize = 0;
        kern_return_t kr = vm_read_overwrite(mach_task_self(), address, sizeof(T), (vm_address_t)&buffer, &outSize);
        if (kr != KERN_SUCCESS || outSize != sizeof(T)) return T{};
        return buffer;
    }

    template <typename T>
    static bool WriteData(uint64_t address, T value) {
        if (address < 0x1000 || address > 0x7FFFFFFFFFFF) return false;
        vm_address_t page_start = address & ~0xFFF;
        mach_port_t task = mach_task_self();
        vm_size_t page_size = 0x1000;
        
        kern_return_t kr = vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
        if (kr != KERN_SUCCESS) return false;

        kr = vm_write(task, address, (vm_offset_t)&value, sizeof(T));
        bool success = (kr == KERN_SUCCESS);

        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
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
    constexpr uintptr_t WeaponManager_Offset = 0x208;
    constexpr uintptr_t CurrentWeapon_Offset = 0x18;
    constexpr uintptr_t RecoilPunch_Offset   = 0x148;
    constexpr uintptr_t SpreadAngle_Offset   = 0x154;
    constexpr uintptr_t FireCooldown_Offset  = 0x94;
    constexpr uintptr_t MovementSpeed_Offset = 0xBC;
    constexpr uintptr_t JumpFlag_Offset      = 0x64;
    constexpr uintptr_t Grounded_Offset      = 0x68;
    constexpr uintptr_t PaintKit_Offset      = 0x48;
    constexpr uintptr_t Wear_Offset          = 0x50;
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
}

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

- (void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    if (renderPassDescriptor) {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [encoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }
}

@end

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
    return NULL;
}

__attribute__((constructor)) void NoxInit() {
    pthread_t thread;
    pthread_create(&thread, NULL, NoxMainThread, NULL);
}
