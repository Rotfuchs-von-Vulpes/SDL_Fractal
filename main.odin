package main

import im "libs/"
import "libs/imgui_impl_sdl2"
import "libs/imgui_impl_opengl3"

import "core:fmt"
import "core:time"
import math "core:math/linalg"
import sdl "vendor:sdl2"
import stb "vendor:stb/image"

import "src/render"

icon_raw :: #load("assets/icon.png")

main :: proc() {
	windowWidth: i32 = 1000
	windowHeight: i32 = 700

	lastTimeTicks := time.tick_now()
	nbFrames := 0
	fps := 0

	assert(sdl.Init(sdl.INIT_EVERYTHING) == 0)
	defer sdl.Quit()

	width, height, channels: i32
	iconPixels := stb.load_from_memory(raw_data(icon_raw), cast(i32) len(icon_raw), &width, &height, &channels, 4)
	iconSurface := sdl.CreateRGBSurfaceWithFormatFrom(iconPixels, width, height, 1, width * 4, cast(u32) sdl.PixelFormatEnum.RGBA8888)

	sdl.GL_SetAttribute(.CONTEXT_FLAGS, i32(sdl.GLcontextFlag.FORWARD_COMPATIBLE_FLAG))
	sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLprofile.CORE))
	sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
	sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 2)

	window := sdl.CreateWindow(
		"Fractal vizualizer",
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		windowWidth, windowHeight,
		{.OPENGL, .RESIZABLE, .ALLOW_HIGHDPI})
	assert(window != nil)
	defer sdl.DestroyWindow(window)

	sdl.SetWindowIcon(window, iconSurface) 

	//icon: ^sdl.Surface = sdl_image.Load("assets/icon.png")

	gl_ctx := sdl.GL_CreateContext(window)
	defer sdl.GL_DeleteContext(gl_ctx)

	sdl.GL_MakeCurrent(window, gl_ctx)

	render.init(windowWidth, windowHeight)

	im.CHECKVERSION()
	im.CreateContext()
	defer im.DestroyContext()
	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
	when im.IMGUI_BRANCH == "docking" {
		io.ConfigFlags += {.DockingEnable}
		io.ConfigFlags += {.ViewportsEnable}

		style := im.GetStyle()
		style.WindowRounding = 0
		style.Colors[im.Col.WindowBg].w =1
	}

	im.StyleColorsClassic()

	imgui_impl_sdl2.InitForOpenGL(window, gl_ctx)
	defer imgui_impl_sdl2.Shutdown()
	imgui_impl_opengl3.Init(nil)
	defer imgui_impl_opengl3.Shutdown()

	running := true
	e: sdl.Event
	for running {
		for sdl.PollEvent(&e) {
			imgui_impl_sdl2.ProcessEvent(&e)
			
			//if io.WantCaptureMouse {break}

			#partial switch e.type {
				case .WINDOWEVENT:  #partial switch e.window.event {
					case .CLOSE: running = false
					case .RESIZED: render.resize(e.window.data1, e.window.data2)
				}
				case .MOUSEWHEEL: {
					render.scroll(e.wheel.y)
					x, y: i32
					sdl.GetWindowSize(window, &x, &y)
					sdl.WarpMouseInWindow(window, x / 2, y / 2)
				}
				case .MOUSEMOTION: render.move(e.motion.x, e.motion.y)
				case .MOUSEBUTTONDOWN: render.buttonPress(e.button.button)
				case .MOUSEBUTTONUP: render.buttonRelease(e.button.button)
			}
		}

		imgui_impl_opengl3.NewFrame()
		imgui_impl_sdl2.NewFrame()
		im.NewFrame()

		// im.ShowDemoWindow(nil)

		viewport := im.GetMainViewport();
		im.SetNextWindowPos(viewport.WorkPos);
		im.SetNextWindowSize(viewport.WorkSize);
		if im.Begin("Window containing a quit button", flags = im.WindowFlags_NoDecoration + {.NoMove, .NoBackground}) {
			im.Text("FPS: %d", fps)
			r, i := render.getCenterPostion()
			im.Text("Position in the center: %f %c %fi", r, i > 0 ? '-' : '+', math.abs(i))
		}
		im.End()

		currentTime := time.duration_microseconds(time.tick_since(time.tick_now()))
		im.Render()
		render.loop()
		imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

		nbFrames += 1
		if time.duration_seconds(time.tick_since(lastTimeTicks)) >= 1.0 {
			fps = nbFrames
			nbFrames = 0
			lastTimeTicks = time.tick_now()
		}

		when im.IMGUI_BRANCH == "docking" {
			backup_current_window := sdl.GL_GetCurrentWindow()
			backup_current_context := sdl.GL_GetCurrentContext()
			im.UpdatePlatformWindows()
			im.RenderPlatformWindowsDefault()
			sdl.GL_MakeCurrent(backup_current_window, backup_current_context);
		}

		sdl.GL_SwapWindow(window)
	}
}

