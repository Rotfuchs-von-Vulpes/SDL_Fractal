package render

import "core:fmt"
import math "core:math/linalg"

import sdl "vendor:sdl2"
import gl "vendor:OpenGL"

Vec2 :: [2]f32

Mouse :: struct {
	position: Vec2,
	wherePressed: Vec2,
	target: Vec2,
	canDrag: bool,
}

Modes :: enum{Mandelbrot, View, Julia}

Camera :: struct {
	position: Vec2,
	zoom: f32,
    width: i32,
    height: i32,
	mode: Modes
}

shaderProgram: u32
VAO, VBO: u32

mouse := Mouse{{0, 0}, {0, 0}, {0, 0}, false}
camera := Camera{{0, 0}, 184, 0, 0, Modes.Mandelbrot}

init :: proc(width: i32, height: i32) {
	gl.load_up_to(3, 2, proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = sdl.GL_GetProcAddress(name)
	})

	camera.width = width
	camera.height = height

    gl.GenVertexArrays(1, &VAO)
    gl.BindVertexArray(VAO)

	vertices := [?]f32{
        -1.0, -1.0,
         1.0, -1.0,
        -1.0,  1.0,
         1.0,  1.0,
    }
	
	gl.GenBuffers(1, &VBO)

    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)

	zero:uintptr = 0
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 0, zero)

	gl.ClearColor(0.2, 0.3, 0.3, 1.0)

	shader_success: bool
	shaderProgram, shader_success = gl.load_shaders("shaders/shader_lines.vert", "shaders/shader_lines.frag")

	gl.UseProgram(shaderProgram)
	vertexLocation := gl.GetUniformLocation(shaderProgram, "iMove")
	gl.Uniform2f(vertexLocation, 0, 0)
	vertexLocation = gl.GetUniformLocation(shaderProgram, "iZoom")
	gl.Uniform1f(vertexLocation, f32(1 / camera.zoom))
	vertexLocation = gl.GetUniformLocation(shaderProgram, "iMouse")
	gl.Uniform2f(vertexLocation, 0, 0)
	vertexLocation = gl.GetUniformLocation(shaderProgram, "iScreen")
	gl.Uniform2f(vertexLocation, f32(camera.width), f32(camera.height))
}

loop :: proc() {
	p:uintptr = 0
	zero:rawptr = &p

	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.UseProgram(shaderProgram)

	gl.BindVertexArray(VAO)
	gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)
}

convertGrid :: proc(vec: Vec2) -> Vec2 {
	return (vec + camera.position - {f32(camera.width), f32(camera.height)} / 2) / camera.zoom
}

changeMode :: proc(toMode: Modes) {
	camera.mode = toMode
	vertexLocation := gl.GetUniformLocation(shaderProgram, "iMode")
	gl.Uniform1i(vertexLocation, i32(toMode))
}

reset :: proc() {
	camera.zoom = 184
	camera.position = {0, 0}

	vertexLocation := gl.GetUniformLocation(shaderProgram, "iMove")
	gl.Uniform2f(vertexLocation, -camera.position[0], camera.position[1])
	vertexLocation = gl.GetUniformLocation(shaderProgram, "iZoom")
	gl.Uniform1f(vertexLocation, f32(1 / camera.zoom))
}

resize :: proc(width: i32, height: i32) {
	camera.width = width
	camera.height = height
	gl.Viewport(0, 0, camera.width, camera.height)
	vertexLocation := gl.GetUniformLocation(shaderProgram, "iScreen")
	gl.Uniform2f(vertexLocation, f32(camera.width), f32(camera.height))
}

move :: proc(x: i32, y: i32) {
	mouse.position = Vec2{f32(x), f32(y)}

	if mouse.canDrag {
		camera.position = mouse.target - mouse.position + mouse.wherePressed

		vertexLocation := gl.GetUniformLocation(shaderProgram, "iMove")
		gl.Uniform2f(vertexLocation, -camera.position[0], camera.position[1])
	}
	
	if (camera.mode == .View) {
		vertexLocation := gl.GetUniformLocation(shaderProgram, "iMouse");
		position := convertGrid(mouse.position)
		gl.Uniform2f(vertexLocation, position[0], position[1])
	}
}

scroll :: proc(yoffset: i32) {
	toZoom := camera.zoom * (0.5 * f32(yoffset) + 1)
	if toZoom > 0 {
		screen: Vec2 = {f32(camera.width / 2), f32(camera.height / 2)}
		camera.position = mouse.position + camera.position - screen
		camera.position = camera.position * f32(toZoom / camera.zoom)
		camera.zoom = toZoom
		
		vertexLocation := gl.GetUniformLocation(shaderProgram, "iZoom")
		gl.Uniform1f(vertexLocation, f32(1 / camera.zoom))
		vertexLocation = gl.GetUniformLocation(shaderProgram, "iMove")
		gl.Uniform2f(vertexLocation, -camera.position[0], camera.position[1])
	}
}

buttonPress :: proc(button: u8) {
	if button == 1 {
		mouse.target = mouse.position
		mouse.wherePressed = camera.position
		mouse.canDrag = true
	} else if button == 3 {
		if camera.mode == .Mandelbrot {
			changeMode(.View)
		} else {
			changeMode(.Mandelbrot)
			reset()
		}
	}
}

buttonRelease :: proc(button: u8) {
	if button == 1 {
		mouse.canDrag = false
	} else if button == 2 {
		reset()
	} else if button == 3 && camera.mode == .View {
		changeMode(.Julia)
		vertexLocation := gl.GetUniformLocation(shaderProgram, "iPosition")
		position := convertGrid(mouse.position)
		gl.Uniform2f(vertexLocation, position[0], position[1])
		reset()
	}
}

getCenterPostion :: proc() -> (f32, f32) {
	vec := camera.position / camera.zoom

	return vec[0], vec[1]
}
