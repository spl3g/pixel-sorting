package pixsort

import "core:fmt"
import "core:slice"
import "core:math/rand"

Pixel :: struct {
    r, g, b: u8,
    h: int, s, v: f32,
    lum: f32,
    to_sort: bool,
}

get_lum :: proc(r, g, b: u8) -> f32 {
    return 0.2126 * cast(f32)r + 0.7152 * cast(f32)g + 0.0722 * cast(f32)b
}

rgb_to_hsv :: proc(r, g, b: u8) -> (int, f32, f32) {
    R := cast(f32)r / 255
    G := cast(f32)g / 255
    B := cast(f32)b / 255
    maxc := max(R, G, B)
    minc := min(R, G, B)
    dif := maxc - minc
    hue, val, sat: f32
    switch maxc {
    case minc:
	hue = 0
    case R:
	hue = (G-B)/(dif)
    case G:
	hue = 2 + (B-R)/(dif)
    case B:
	hue = 4 + (R-G)/(dif)
    }

    if maxc == 0 {
	sat = 0
    } else {
	sat = dif/maxc
    }

    val = maxc
    
    hue *= 60
    if hue < 0 {
        hue += 360
    }
    return cast(int)hue, val, sat
}

hsv_to_rgb :: proc(h: int, s, v: f32) -> (r, g, b: u8){
    // i don't understand this code :)
    hue := max(0, min(h, 360))
    sat := max(0, min(s, 1))
    val := max(0, min(v, 1))
    hue_ind := cast(int)h/60 % 6
    fract := cast(f32)h / 60 - cast(f32)hue_ind

    p := val * (1 - sat)
    q := val * (1 - fract * sat)
    t := val * (1 - (1 - fract) * sat)
    
    rtemp, gtemp, btemp: f32
    switch hue_ind {
    case 0:
	rtemp, gtemp, btemp = val, t, p
    case 1:
	rtemp, gtemp, btemp = q, val, p
    case 2:
	rtemp, gtemp, btemp = p, val, t
    case 3:
	rtemp, gtemp, btemp = p, q, val
    case 4:
	rtemp, gtemp, btemp = t, p, val
    case 5:
	rtemp, gtemp, btemp = val, p, q
    }
    
    return u8(rtemp*255), u8(gtemp*255), u8(btemp*255)
}

calculate_mask_lum :: proc(img: ^[]Pixel, width, height: i32, t_min, t_max: f32, inverted: bool) {
    for pixel in img {
	lum := pixel.lum 
	bw_color: bool
	if inverted {
	    if lum < t_min || lum > t_max {
		bw_color = false
	    } else {
		bw_color = true
	    }
	} else {
	    if lum < t_min || lum > t_max {
		bw_color = true
	    } else {
		bw_color = false
	    }
	}
	pixel.to_sort = bw_color
    }
}

calculate_mask_hue :: proc(img: ^[]Pixel, width, height: i32, t_min, t_max: int, inverted: bool) {
    for pixel in img {
	hue := pixel.h
	bw_color: bool
	if inverted {
	    if hue < t_min || hue > t_max {
		bw_color = false
	    } else {
		bw_color = true
	    }
	} else {
	    if hue < t_min || hue > t_max {
		bw_color = true
	    } else {
		bw_color = false
	    }
	}
	pixel.to_sort = bw_color
    }
}

color_stripes :: proc(img: ^[]Pixel, width, height: i32) {
    counter: i32 = 0
    for row in 0..<height {
	for column in 0..<width {
	    pixel := row * width + column
	    if !img[pixel].to_sort || column == width - 1 {
		rand_r: u8 = cast(u8)rand.int_max(256)
		rand_g: u8 = cast(u8)rand.int_max(256)
		rand_b: u8 = cast(u8)rand.int_max(256)
		for i in pixel-counter..<pixel {
		    img[i].r = rand_r
		    img[i].g = rand_g
		    img[i].b = rand_b
		}
		counter = 0
	    } else {
		counter += 1
	    }
	}
    }
}

compare_pixels :: proc(pixel1, pixel2: Pixel) -> bool {
    return pixel1.lum < pixel2.lum
}

generate_colors :: proc(
    buf, img: ^[]Pixel,
    pixel_offset: int,
    h_range, s_range, v_range: f32,
) {
    buf_len := len(buf)
    
    for i in 0..<buf_len {
        h := cast(int)rand.float32_range(250, 360)
        s := rand.float32_range(0.6, 1)
        v := rand.float32_range(0, 1)
        r, g, b := hsv_to_rgb(h, s, v)
        buf[i] = Pixel {
	r, g, b,
	h, s, v,
	get_lum(r, g, b),
	true
        }
    }
    
    slice.sort_by(buf, compare_pixels)
    for i in 0..<buf_len {
        px := pixel_offset-counter + i
        img[px] = buf[i]
    }
}
sort_image :: proc(img: ^[]Pixel, width, height: i32) {
    counter: i32 = 0
    /* buf := make([]Pixel, width - 1) */
    /* defer delete(buf) */
    for row in 0..<height {
	for column in 0..<width {
	    pixel := row * width + column
	    if !img[pixel].to_sort || column == width - 1 {
		slice.sort_by(img[pixel-counter:pixel], compare_pixels)
		counter = 0
	    } else {
		counter += 1
	    }
	}
    }
}

convert_to_pixels :: proc(img: [^]u8, width, height: i32) -> []Pixel {
    conv := make([]Pixel, width*height)
    for pixel := 2; pixel < cast(int)(width * height * 3); pixel += 3 {
	r := img[pixel-2]
	g := img[pixel-1]
	b := img[pixel]
	lum := get_lum(r, g, b)
	h, s, v := rgb_to_hsv(r, g, b)
	conv[pixel/3] = Pixel{
	    r, g, b,
	    h, s, v,
	    lum,
	    false,
	}
    }
    return conv
}

convert_from_pixels :: proc(img: []Pixel, width, height: i32) -> []u8 {
    out := make([]u8, width*height*3)
    for pixel, index in img {
	out[index*3] = pixel.r
	out[index*3+1] = pixel.g
	out[index*3+2] = pixel.b
    }
    return out
}

get_mask_from_pixels :: proc(img: []Pixel, width, height: i32) -> []u8 {
    out := make([]u8, width*height*3)
    for pixel, index in img {
	color: u8
	if pixel.to_sort {
	    color = 255
	} else {
	    color = 0
	}
	out[index*3] = color
	out[index*3+1] = color
	out[index*3+2] = color
    }
    return out
}

process :: proc(input: [^]u8, width, height: i32, t_min, t_max: f32, reverse: bool) -> [^]u8 {
    tmin := t_min * 255
    tmax := t_max * 255
    /* tmin := cast(int)t_min */
    /* tmax := cast(int)t_max */
    img := convert_to_pixels(input, width, height)
    calculate_mask_lum(&img, width, height, tmin, tmax, reverse)
    sort_image(&img, width, height)
    return raw_data(convert_from_pixels(img, width, height))
}
