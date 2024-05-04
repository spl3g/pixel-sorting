package main

import "core:os"
import "core:fmt"
import "core:slice"
import "core:math/rand"
import stbi "vendor:stb/image"

T_MIN: f32 : 255 * 0.25
T_MAX: f32 : 255 * 0.80

Pixel :: struct {
    hue: f32,
    r, g, b: u8,
}

get_lum :: proc(r, g, b: u8) -> f32 {
    return 0.2126 * cast(f32)r + 0.7152 * cast(f32)g + 0.0722 * cast(f32)b
}

get_hue :: proc(r, g, b: u8) -> f32 {
    R := cast(f32)r / 255
    G := cast(f32)g / 255
    B := cast(f32)b / 255
    maxc := max(R, G, B)
    minc := min(R, G, B)
    // TODO: if goes negative += 360
    hue: f32
    switch maxc {
    case R:
	hue = (G-B)/(maxc-minc)
    case G:
	hue = 2.0 + (B-R)/(maxc-minc)
    case B:
	hue = 4.0 + (R-G)/(maxc-minc)
    }
    return hue
}

calculate_lum_mask :: proc(img: [^]u8, width, height: i32, inverted: bool) -> []u8 {
    mask := make([]u8, width*height*3)
    for pixel: i32 = 2; pixel <= width * height * 3; pixel += 3 {
	R := img[pixel-2]
	G := img[pixel-1]
	B := img[pixel]
	bw_color: u8
	lum := get_lum(R, G, B)
	if inverted {
	    if lum < T_MIN || lum > T_MAX {
		bw_color = 0
	    } else {
		bw_color = 255
	    }
	} else {
	    if lum < T_MIN || lum > T_MAX {
		bw_color = 255
	    } else {
		bw_color = 0
	    }
	}
	for i in 0..=2 {
	    mask[cast(int)pixel-i] = bw_color
	}
    }
    return mask
}

color_stripes :: proc(img: [^]u8, lum_mask: []u8, width, height: i32) -> [^]u8 {
    counter: i32 = 0
    colord := new_clone(img)
    for pixel: i32 = 2; pixel <= width * height * 3; pixel += 3 {
	lum := lum_mask[pixel-2] + lum_mask[pixel-1] + lum_mask[pixel]
	if lum == 0 || pixel % (width * 3 - 1) == 0 {
	    rand_r: u8 = cast(u8)rand.int_max(256)
	    rand_g: u8 = cast(u8)rand.int_max(256)
	    rand_b: u8 = cast(u8)rand.int_max(256)
	    for i := pixel - counter; i < pixel; i += 3 {
		colord[i-2] = rand_r
		colord[i-1] = rand_g
		colord[i] = rand_b
	    }
	    counter = 0
	} else {
	    counter += 3
	}
    }
    return colord^
}

compare_pixels :: proc(pixel1, pixel2: Pixel) -> bool {
    return pixel1.hue < pixel2.hue ? true : false
}

sort_image :: proc(img: [^]u8, lum_mask: []u8, width, height: i32) -> [^]u8 {
    counter: i32 = 0
    sorted := new_clone(img)
    for pixel: i32 = 2; pixel <= width * height * 3; pixel += 3 {
	lum := lum_mask[pixel-2] + lum_mask[pixel-1] + lum_mask[pixel]
	if lum == 0 || pixel % (width * 3) == 0 {
	    // you can play with the hue_arr length
	    hue_arr := make([]Pixel, counter / 3 + 1)
	    defer delete(hue_arr)
	    for i := pixel - counter; i < pixel; i += 3 {
		r := img[i-2]
		g := img[i-1]
		b := img[i]
		hue := get_lum(r, g, b)
		hue_arr[(pixel-i)/3] = Pixel {hue, r, g, b}
	    }
	    slice.sort_by(hue_arr, compare_pixels)
	    for i := pixel - counter; i < pixel; i += 3 {
		p := hue_arr[(pixel-i)/3]
		sorted[i-2] = p.r
		sorted[i-1] = p.g
		sorted[i] = p.b
	    }
	    counter = 0
	} else {
	    counter += 3
	}
    }
    return sorted^
    
}

main :: proc() {
    width, height, channels: i32
    input := fmt.ctprintf(os.args[1])
    output := fmt.ctprintf("%s_sorted.jpg", input)
    /* input: cstring = "house.jpg" */
    /* output: cstring = "house_sorted.jpg" */
    img := stbi.load(input, &width, &height, &channels, 0)
    if img == nil {
	fmt.eprintln("ERROR: could not read the image")
	os.exit(1)
    }
    lum_mask := calculate_lum_mask(img, width, height, false)
    /* sorted := color_stripes(img, lum_mask, width, height) */
    sorted := sort_image(img, lum_mask, width, height)
    stbi.write_jpg(output, width, height, 3, sorted, 100)
}
