   newoption {
      trigger = "shared",
      description = "Build NVRHI as shared library (DLL/.so)"
   }

   newoption {
      trigger = "with_validation",
      description = "Enable validation layer",
      value = "BOOL",
      default = "on"
   }

   newoption {
      trigger = "with_vulkan",
      description = "Enable Vulkan backend",
      value = "BOOL",
      default = "off"
   }

   newoption {
      trigger = "with_dx11",
      description = "Enable D3D11 backend (Win32 only)",
      value = "BOOL",
      default = "off"
   }

   newoption {
      trigger = "with_dx12",
      description = "Enable D3D12 backend (Win32 only)",
      value = "BOOL",
      default = "on"
   }

   newoption {
      trigger = "with_rtxmu",
      description = "Enable RTXMU",
      value = "BOOL",
      default = "off"
   }

   newoption {
      trigger = "with_nvapi",
      description = "Enable NVAPI (Win32 only)",
      value = "BOOL",
      default = "off"
   }

   newoption {
      trigger = "with_aftermath",
      description = "Enable Aftermath support",
      value = "BOOL",
      default = "off"
   }

   -- Common file lists
   local inc = { "include/nvrhi/**.h", "include/nvrhi/common/**.h" }
   local src = { "src/common/**.cpp", "src/common/**.h" }
   local misc = {}
   if os.istarget("windows") then table.insert(misc, "tools/nvrhi.natvis") end

   function add_backend(name, incs, srcs, libs, defs)
      if _OPTIONS["shared"] then
         project("nvrhi")
         targetname("nvrhi")
         kind "SharedLib"
      else
         project("nvrhi_" .. name)
         kind "StaticLib"
      end

      language "C++"
      cppdialect "C++17"
      staticruntime "on"
      includedirs { "include", "include/nvrhi", "include/nvrhi/common" }
      files { inc, src, misc, incs, srcs }
      removefiles { "src/vulkan/**" }  -- avoid pulling in other backends by default

      filter "system:windows"
         systemversion "latest"
      filter {}

      if _OPTIONS["shared"] then
         defines { "NVRHI_SHARED_LIBRARY_BUILD=1" }
         if name == "vulkan" and _OPTIONS["shared"] == "yes" then
            defines { "VULKAN_HPP_STORAGE_SHARED", "VULKAN_HPP_STORAGE_SHARED_EXPORT" }
         end
      end

      if name == "d3d11" then
         links { "d3d11", "dxguid" }
         defines 
         { 
             "NVRHI_WITH_DX11",
             "NVRHI_D3D11_WITH_NVAPI=" .. (_OPTIONS["with_nvapi"]=="on" and "1" or "0") 
         }
         if _OPTIONS["with_nvapi"] == "on" then links { "nvapi" } end
      elseif name == "d3d12" then
         links { "d3d12" }
         if _OPTIONS["with_rtxmu"] == "on" then
            defines 
            { 
                "NVRHI_WITH_RTXMU=1" 
            }
            links { "rtxmu" }
         end
         defines 
         {
             "NVRHI_WITH_D3D12",
             "NVRHI_D3D12_WITH_NVAPI=" .. (_OPTIONS["with_nvapi"]=="on" and "1" or "0") 
         }
         includedirs
         {
             "thirdparty/DirectX-Headers/include"
         }
         files
         {
             "thirdparty/DirectX-Headers/include/**.h",
             "thirdparty/DirectX-Headers/include/**.cpp"
         }
         if _OPTIONS["with_nvapi"] == "on" then links { "nvapi" } end
      elseif name == "vulkan" then
         if os.istarget("windows") then
            defines 
            { 
                "VK_USE_PLATFORM_WIN32_KHR", 
                "NOMINMAX" 
            }
         end
         if _OPTIONS["with_rtxmu"] == "on" then
            defines { "NVRHI_WITH_RTXMU=1" }
            links { "rtxmu" }
         end
         defines
         {
             "NVRHI_WITH_VULKAN"
         }
         links { "Vulkan-Headers" }
      end

      if _OPTIONS["with_aftermath"] == "on" then
         defines { "NVRHI_WITH_AFTERMATH=1" }
         links { "aftermath" }
      else
         defines { "NVRHI_WITH_AFTERMATH=0" }
      end

      if _OPTIONS["with_validation"] == "on" then
         files {
            "include/nvrhi/validation.h",
            "src/validation/**.cpp",
            "src/validation/**.h"
         }
         defines
         {
             "NVRHI_WITH_VALIDATION"
         }
      end

      filter "configurations:Debug"
         runtime "Debug"
         symbols "On"
      filter "configurations:Release"
         runtime "Release"
         optimize "On"
      filter {}
   end

-- Generate projects
if _OPTIONS["with_dx11"] == "on" and os.istarget("windows") then
   add_backend("d3d11",
      { "include/nvrhi/d3d11.h" },
      { "src/d3d11/**.cpp", "src/common/dxgi-format.*" }
   )
end

if _OPTIONS["with_dx12"] == "on" and os.istarget("windows") then
   add_backend("d3d12",
      { "include/nvrhi/d3d12.h" },
      { "src/d3d12/**.h", "src/d3d12/**.cpp", "src/common/dxgi-format.*", "src/common/versioning.h" }
   )
end

if _OPTIONS["with_vulkan"] == "on" then
   add_backend("vulkan",
      { "include/nvrhi/vulkan.h" },
      { "src/vulkan/**.cpp", "src/common/versioning.h" }
   )
end
