// Fragment Shader

#import bevy_pbr::{
    pbr_functions::calculate_tbn_mikktspace,
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

fn srgb_to_linear(in: vec3<f32>) -> vec3<f32> {
    // approximation
    return pow(in, vec3<f32>(2.2));
}

fn linear_to_srgb(in: vec3<f32>) -> vec3<f32> {
    // approximation
    return pow(in, vec3<f32>(1.0 / 2.2));
}

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    // Base and Cloud Textures
    var day = srgb_to_linear(textureSample(base_color_day_texture, base_color_day_sampler, in.uv).rgb);
    var night = srgb_to_linear(textureSample(base_color_night_texture, base_color_night_sampler, in.uv).rgb);
    var clouds = srgb_to_linear(textureSample(cloud_color_texture, cloud_color_sampler, in.uv).rgb);

    // Normal Mapping
    let TBN = calculate_tbn_mikktspace(in.world_normal, in.world_tangent);
    let nt = textureSample(normal_map_texture, normal_map_sampler, in.uv).rgb * 2.0 - 1.0;
    let normal = normalize(TBN * nt);

    // Diffuse lighting on the planet surface is sampled from the day/night textures
    var diffuse = saturate(dot(normal, sun_dir));
    diffuse = smoothstep(0.0, 0.4, diffuse);

    // Specular Mapping
    let view_dir = normalize(view.world_position - in.world_position.xyz);
    let half_dir = normalize(view_dir + sun_dir);

    var specular = textureSample(specular_map_texture, specular_map_sampler, in.uv).r;
    let specular_strength = pow(saturate(dot(normal, half_dir)), 32.0);
    specular = specular * specular_strength * 0.02;

    // Color Mixing
    var color = vec3<f32>(0);
    color = mix(night, day, diffuse);
    color = mix(color, vec3<f32>(1.0), clouds.r * diffuse);
    color += specular;

    // Gamma Correction
    color = linear_to_srgb(color);

    return vec4<f32>(color, 1.0);
}
