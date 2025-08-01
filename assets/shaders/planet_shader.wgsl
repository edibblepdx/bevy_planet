// Fragment Shader

#import bevy_pbr::{
    forward_io::VertexOutput,
    mesh_view_bindings::view,
}

// Sun Direction
@group(2) @binding(0) var<uniform> sun_dir: vec3<f32>;

// Day Texture
@group(2) @binding(1) var base_color_day_texture: texture_2d<f32>;
@group(2) @binding(2) var base_color_day_sampler: sampler;

// Night Texture
@group(2) @binding(3) var base_color_night_texture: texture_2d<f32>;
@group(2) @binding(4) var base_color_night_sampler: sampler;

// Cloud Texture
@group(2) @binding(5) var cloud_color_texture: texture_2d<f32>;
@group(2) @binding(6) var cloud_color_sampler: sampler;

// Normal Map
@group(2) @binding(7) var normal_map_texture: texture_2d<f32>;
@group(2) @binding(8) var normal_map_sampler: sampler;

// Specular Map
@group(2) @binding(9) var specular_map_texture: texture_2d<f32>;
@group(2) @binding(10) var specular_map_sampler: sampler;

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    // Base and Cloud Textures
    let day = textureSample(base_color_day_texture, base_color_day_sampler, in.uv).rgb;
    let night = textureSample(base_color_night_texture, base_color_night_sampler, in.uv).rgb;
    let clouds = textureSample(cloud_color_texture, cloud_color_sampler, in.uv).rgb;

    // Doing lighting in world space because I don't understand Bevy :)

    // Diffuse lighting on the planet surface is sampled from the day/night textures
    // but must still be applied to the clouds.
    let diffuse = saturate(dot(in.world_normal, sun_dir));

    // Specular
    let view_dir = normalize(view.world_position - in.world_position.xyz);
    let half_dir = normalize(view_dir + sun_dir);

    var specular = textureSample(specular_map_texture, specular_map_sampler, in.uv).rgb;
    let specular_strength = pow(saturate(dot(in.world_normal, half_dir)), 32.0);
    specular = specular * specular_strength;

    // Color
    var color = vec3<f32>(0);
    let light = diffuse + specular;
    color = mix(night, day, light);
    color = mix(color, clouds, clouds.r * light);

    return vec4<f32>(color, 1.0);
}
