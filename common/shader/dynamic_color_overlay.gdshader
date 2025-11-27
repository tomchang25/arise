shader_type canvas_item;

// The amount (from 0.0 to 1.0) of the Overlay Color to mix in.
// 0.0 means 100% original color. 1.0 means 100% overlay color.
uniform float overlay_amount : hint_range(0.0, 1.0) = 0.0; 

// The color that will be mixed over the original texture color.
uniform vec4 overlay_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Default to Red

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Check if the original color is transparent. 
    // We usually don't want to overlay color on fully transparent areas.
    if (texture_color.a == 0.0) {
        COLOR = texture_color;
    }
    else {
        // Mix the RGB channels of the texture color with the RGB of the overlay color, 
        // based on the overlay_amount. We preserve the original alpha channel (texture_color.a).
        vec3 final_rgb = mix(texture_color.rgb, overlay_color.rgb, overlay_amount);
        
        COLOR = vec4(final_rgb, texture_color.a);  
    }
}