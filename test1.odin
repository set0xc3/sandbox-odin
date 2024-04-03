package test1

import "core:fmt"
import "core:testing"

Entity :: struct {
	id:      u64,
	name:    string,
	variant: union {
		^Frog,
	},
}

Frog :: struct {
	using entity: Entity,
	volume:       f32,
	jump_height:  i32,
}


new_entity :: proc($T: typeid) -> ^T {
	e := new(T)
	e.variant = e
	return e
}


@(deferred_none = close)
open :: proc() {
	fmt.println("open")
}

close :: proc() {
	fmt.println("close")
}

@(test)
test1 :: proc(_: ^testing.T) {
	entity: ^Entity = new_entity(Frog)
	switch e in entity.variant {
	case ^Frog:
		fmt.println("Ribbit:", e.volume)
	}
}
