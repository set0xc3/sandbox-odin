package sandbox

import "core:fmt"
import "core:os"
import "core:strings"

shader_get_program :: proc(data: string, pattern: string) -> (res: string, found: bool) {
	begin, end: int
	offset: int

	for c, i in data {
		if c == '\n' {
			line := string(data[offset:i])
			if line == pattern {
				begin = offset + len(pattern) + 1
				found = true
				break
			}
			offset = i + 1
		}
	}

	if found {
		for c, i in data[begin:] {
			if c == '}' {
				end = begin + i + 1
				res = string(data[begin:end])
				break
			}
		}
	}

	return
}

main :: proc() {
	fmt.println("Hi Odin!")

	data, ok := os.read_entire_file("shader.glsl")
	shader_source, found := shader_get_program(string(data), "#vertex")
	fmt.println(shader_source)
	// fmt.println(shader_get_program(string(data), "#geometry"))
	// fmt.println(shader_get_program(string(data), "#fragment"))
}
