package ui

import "core:c/libc"
import "core:fmt"

import mu "shared:microui"

import SDL "vendor:sdl2"

state := struct {
	mu_ctx:          mu.Context,
	log_buf:         [1 << 16]byte,
	log_buf_len:     int,
	log_buf_updated: bool,
	bg:              mu.Color,
	atlas_texture:   ^SDL.Texture,
} {
	bg = {90, 95, 100, 255},
}

main :: proc() {
	if err := SDL.Init({.VIDEO}); err != 0 {
		fmt.eprintln(err)
		return
	}
	defer SDL.Quit()

	window := SDL.CreateWindow(
		"microui-odin",
		SDL.WINDOWPOS_UNDEFINED,
		SDL.WINDOWPOS_UNDEFINED,
		1280,
		720,
		{.HIDDEN, .RESIZABLE},
	)
	if window == nil {
		fmt.eprintln(SDL.GetError())
		return
	}
	defer SDL.DestroyWindow(window)

	backend_idx: i32 = -1
	if n := SDL.GetNumRenderDrivers(); n <= 0 {
		fmt.eprintln("No render drivers available")
		return
	} else {
		for i in 0 ..< n {
			info: SDL.RendererInfo
			if err := SDL.GetRenderDriverInfo(i, &info); err == 0 {
				// NOTE(bill): "direct3d" seems to not work correctly
				if info.name == "opengl" {
					backend_idx = i
					break
				}
			}
		}
	}

	renderer := SDL.CreateRenderer(window, backend_idx, {.ACCELERATED, .PRESENTVSYNC})
	if renderer == nil {
		fmt.eprintln("SDL.CreateRenderer:", SDL.GetError())
		return
	}
	defer SDL.DestroyRenderer(renderer)

	state.atlas_texture = SDL.CreateTexture(
		renderer,
		u32(SDL.PixelFormatEnum.RGBA32),
		.TARGET,
		mu.DEFAULT_ATLAS_WIDTH,
		mu.DEFAULT_ATLAS_HEIGHT,
	)
	assert(state.atlas_texture != nil)
	if err := SDL.SetTextureBlendMode(state.atlas_texture, .BLEND); err != 0 {
		fmt.eprintln("SDL.SetTextureBlendMode:", err)
		return
	}

	pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT)
	for alpha, i in mu.default_atlas_alpha {
		pixels[i].rgb = 0xff
		pixels[i].a = alpha
	}

	if err := SDL.UpdateTexture(
		state.atlas_texture,
		nil,
		raw_data(pixels),
		4 * mu.DEFAULT_ATLAS_WIDTH,
	); err != 0 {
		fmt.eprintln("SDL.UpdateTexture:", err)
		return
	}

	ctx := &state.mu_ctx
	mu.init(ctx)

	ctx._style = {
		font = nil,
		size = {68, 10},
		padding = 5,
		spacing = 4,
		indent = 24,
		title_height = 24,
		footer_height = 20,
		scrollbar_size = 12,
		thumb_size = 8,
		colors = {
			.TEXT = {230, 230, 230, 255},
			.BORDER = {255, 255, 255, 0},
			.WINDOW_BG = {255, 255, 255, 255},
			.TITLE_BG = {255, 255, 255, 0},
			.TITLE_TEXT = {255, 255, 255, 0},
			.PANEL_BG = {0, 0, 0, 0},
			.BUTTON = {75, 75, 75, 255},
			.BUTTON_HOVER = {95, 95, 95, 255},
			.BUTTON_FOCUS = {115, 115, 115, 255},
			.BASE = {30, 30, 30, 255},
			.BASE_HOVER = {35, 35, 35, 255},
			.BASE_FOCUS = {40, 40, 40, 255},
			.SCROLL_BASE = {43, 43, 43, 255},
			.SCROLL_THUMB = {30, 30, 30, 255},
		},
	}


	ctx.text_width = mu.default_atlas_text_width
	ctx.text_height = mu.default_atlas_text_height

	SDL.ShowWindow(window)

	main_loop: for {
		// ddpi, hdpi, vdpi: f32
		// display_index := SDL.GetWindowDisplayIndex(window)

		// Wayland: 0: 163.42549 162.56 166.25455
		// Wayland: 1: 92.615456 92.01509 94.5931
		// X11: 0: 81.712746 81.279999 83.12727
		// X11: 1: 92.615456 92.01509 94.5931
		// SDL.GetDisplayDPI(display_index, &ddpi, &hdpi, &vdpi)
		// fmt.println(ddpi, hdpi, vdpi)

		for e: SDL.Event; SDL.PollEvent(&e);  /**/{
			#partial switch e.type {
			case .QUIT:
				break main_loop
			case .MOUSEMOTION:
				mu.input_mouse_move(ctx, e.motion.x, e.motion.y)
			case .MOUSEWHEEL:
				mu.input_scroll(ctx, e.wheel.x * 30, e.wheel.y * -30)
			case .TEXTINPUT:
				mu.input_text(ctx, string(cstring(&e.text.text[0])))

			case .MOUSEBUTTONDOWN, .MOUSEBUTTONUP:
				fn := mu.input_mouse_down if e.type == .MOUSEBUTTONDOWN else mu.input_mouse_up
				switch e.button.button {
				case SDL.BUTTON_LEFT:
					fn(ctx, e.button.x, e.button.y, .LEFT)
				case SDL.BUTTON_MIDDLE:
					fn(ctx, e.button.x, e.button.y, .MIDDLE)
				case SDL.BUTTON_RIGHT:
					fn(ctx, e.button.x, e.button.y, .RIGHT)
				}

			case .KEYDOWN, .KEYUP:
				if e.type == .KEYUP && e.key.keysym.sym == .ESCAPE {
					SDL.PushEvent(&SDL.Event{type = .QUIT})
				}

				fn := mu.input_key_down if e.type == .KEYDOWN else mu.input_key_up

				#partial switch e.key.keysym.sym {
				case .LSHIFT:
					fn(ctx, .SHIFT)
				case .RSHIFT:
					fn(ctx, .SHIFT)
				case .LCTRL:
					fn(ctx, .CTRL)
				case .RCTRL:
					fn(ctx, .CTRL)
				case .LALT:
					fn(ctx, .ALT)
				case .RALT:
					fn(ctx, .ALT)
				case .RETURN:
					fn(ctx, .RETURN)
				case .KP_ENTER:
					fn(ctx, .RETURN)
				case .BACKSPACE:
					fn(ctx, .BACKSPACE)
				}
			}
		}

		mu.begin(ctx)
		@(static)
		opts := mu.Options{.NO_CLOSE}

		if mu.window(ctx, "[1] Window", {40, 40, 300, 450}, opts) {
		}
		if mu.window(ctx, "[2] Window", {40, 40, 300, 450}, opts) {
		}
		if mu.window(ctx, "[3] Window", {40, 40, 300, 450}, opts) {
		}
		mu.end(ctx)

		render(ctx, renderer)
	}
}

render :: proc(ctx: ^mu.Context, renderer: ^SDL.Renderer) {
	render_texture :: proc(
		renderer: ^SDL.Renderer,
		dst: ^SDL.Rect,
		src: mu.Rect,
		color: mu.Color,
	) {
		dst.w = src.w
		dst.h = src.h

		SDL.SetTextureAlphaMod(state.atlas_texture, color.a)
		SDL.SetTextureColorMod(state.atlas_texture, color.r, color.g, color.b)
		SDL.RenderCopy(renderer, state.atlas_texture, &SDL.Rect{src.x, src.y, src.w, src.h}, dst)
	}

	viewport_rect := &SDL.Rect{}
	SDL.GetRendererOutputSize(renderer, &viewport_rect.w, &viewport_rect.h)
	SDL.RenderSetViewport(renderer, viewport_rect)
	SDL.RenderSetClipRect(renderer, viewport_rect)
	SDL.SetRenderDrawColor(renderer, 204, 210, 217, 255)
	SDL.RenderClear(renderer)

	command_backing: ^mu.Command
	for variant in mu.next_command_iterator(ctx, &command_backing) {
		switch cmd in variant {
		case ^mu.Command_Text:
			dst := SDL.Rect{cmd.pos.x, cmd.pos.y, 0, 0}
			for ch in cmd.str do if ch & 0xc0 != 0x80 {
				r := min(int(ch), 127)
				src := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
				render_texture(renderer, &dst, src, cmd.color)
				dst.x += dst.w
			}
		case ^mu.Command_Rect:
			SDL.SetRenderDrawColor(renderer, cmd.color.r, cmd.color.g, cmd.color.b, cmd.color.a)
			SDL.RenderFillRect(renderer, &SDL.Rect{cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h})
		case ^mu.Command_Icon:
			src := mu.default_atlas[cmd.id]
			x := cmd.rect.x + (cmd.rect.w - src.w) / 2
			y := cmd.rect.y + (cmd.rect.h - src.h) / 2
			render_texture(renderer, &SDL.Rect{x, y, 0, 0}, src, cmd.color)
		case ^mu.Command_Clip:
			SDL.RenderSetClipRect(
				renderer,
				&SDL.Rect{cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h},
			)
		case ^mu.Command_Jump:
			unreachable()
		}
	}

	SDL.RenderPresent(renderer)
}

// SDL2_gfx

draw_line :: proc(renderer: ^SDL.Renderer, x1, x2, y: i32, r, g, b, a: u8) -> (res: i32) {
	res |= SDL.SetRenderDrawBlendMode(renderer, (a == 255) ? .NONE : .BLEND)
	res |= SDL.SetRenderDrawColor(renderer, r, g, b, a)
	res |= SDL.RenderDrawLine(renderer, x1, y, x2, y)
	return
}

draw_rectangle :: proc(renderer: ^SDL.Renderer, x1, y1, x2, y2, rad: i32, r, g, b, a: u8) {
	/* Check valid radius */
	if rad < 0 {
		return
	}

	/* Draw corners */
	xx1 := x1 + rad
	xx2 := x2 - rad
	yy1 := y1 + rad
	yy2 := y2 - rad
	// arcRGBA(renderer, xx1, yy1, rad, 180, 270, r, g, b, a)
	// arcRGBA(renderer, xx2, yy1, rad, 270, 360, r, g, b, a)
	// arcRGBA(renderer, xx1, yy2, rad,  90, 180, r, g, b, a)
	// arcRGBA(renderer, xx2, yy2, rad,   0,  90, r, g, b, a)

	/* Draw lines */
	if xx1 <= xx2 {
		draw_line(renderer, xx1, xx2, y1, r, g, b, a)
		draw_line(renderer, xx1, xx2, y2, r, g, b, a)
	}
	if yy1 <= yy2 {
		draw_line(renderer, x1, yy1, yy2, r, g, b, a)
		draw_line(renderer, x2, yy1, yy2, r, g, b, a)
	}
}
