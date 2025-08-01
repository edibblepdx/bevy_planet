// Fragment Shader

#import bevy_pbr::forward_io::VertexOutput

@group(2) @binding(0) var base_color_texture: texture_2d<f32>;
@group(2) @binding(1) var base_color_sampler: sampler;

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    return textureSample(base_color_texture, base_color_sampler, in.uv);
}
