#include "CocoaOpenGLApplication.h"
#include "OpenGL/OpenGLConfig.hpp"
#include "DebugManager.hpp"

namespace My {
    extern GfxConfiguration config;
    IApplication* g_pApp                = static_cast<IApplication*>(new CocoaOpenGLApplication(config));
    IMemoryManager*   g_pMemoryManager   = static_cast<IMemoryManager*>(new MemoryManager);
    AssetLoader*     g_pAssetLoader     = static_cast<AssetLoader*>(new AssetLoader);
    SceneManager*    g_pSceneManager    = static_cast<SceneManager*>(new SceneManager);
    InputManager*    g_pInputManager    = static_cast<InputManager*>(new InputManager);
    AnimationManager* g_pAnimationManager = static_cast<AnimationManager*>(new AnimationManager);
#ifdef DEBUG
    DebugManager*    g_pDebugManager    = static_cast<DebugManager*>(new DebugManager);
#endif
}
