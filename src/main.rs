use bevy::{
    color::palettes::css::*,
    image::ImageLoaderSettings,
    pbr::{MaterialPipeline, MaterialPipelineKey},
    prelude::*,
    reflect::TypePath,
    render::{
        mesh::MeshVertexBufferLayoutRef,
        render_resource::{
            AsBindGroup, Face, RenderPipelineDescriptor, ShaderRef, SpecializedMeshPipelineError,
        },
    },
};

const PLANET_SHADER_ASSET_PATH: &str = "shaders/planet_shader.wgsl";
const SPACE_SHADER_ASSET_PATH: &str = "shaders/space_shader.wgsl";

fn main() {
    App::new()
        .add_plugins((
            DefaultPlugins,
            MaterialPlugin::<PlanetMaterial>::default(),
            MaterialPlugin::<SpaceMaterial>::default(),
        ))
        .insert_resource(SunDir(Dir3::from_xyz(1.0, 1.0, 0.0).unwrap()))
        .add_systems(Startup, setup)
        .run();
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut planet_materials: ResMut<Assets<PlanetMaterial>>,
    mut space_materials: ResMut<Assets<SpaceMaterial>>,
    //mut standard_materials: ResMut<Assets<StandardMaterial>>,
    sun_dir: Res<SunDir>,
    asset_server: Res<AssetServer>,
) {
    // planet
    commands.spawn((
        Name::new("Planet"),
        Mesh3d(meshes.add({
            let mut mesh = Sphere::new(10.).mesh().ico(4).unwrap();
            mesh.generate_tangents()
                .expect("Failed to generate tangents.");
            mesh
        })),
        MeshMaterial3d(planet_materials.add(PlanetMaterial {
            sun_dir: sun_dir.0.as_vec3(),
            surface_texture_day: Some(asset_server.load("textures/8k_earth_daymap.jpg")),
            surface_texture_night: Some(asset_server.load("textures/8k_earth_nightmap.jpg")),
            cloud_texture: Some(asset_server.load("textures/8k_earth_clouds.jpg")),
            normal_texture: Some(asset_server.load_with_settings(
                "textures/8k_earth_normal_map.tif",
                |settings: &mut ImageLoaderSettings| settings.is_srgb = false,
            )),
            specular_texture: Some(asset_server.load_with_settings(
                "textures/8k_earth_specular_map.tif",
                |settings: &mut ImageLoaderSettings| settings.is_srgb = false,
            )),
            alpha_mode: AlphaMode::Blend,
        })),
    ));

    // space
    commands.spawn((
        Name::new("Space"),
        Mesh3d(meshes.add(Sphere::new(200.).mesh().ico(2).unwrap())),
        MeshMaterial3d(space_materials.add(SpaceMaterial {
            surface_texture: Some(asset_server.load("textures/8k_stars_milky_way.jpg")),
            alpha_mode: AlphaMode::Blend,
        })),
    ));

    // sun direction
    /*
    commands.spawn((
        Name::new("sun_dir"),
        children![(
            Mesh3d(meshes.add(Sphere::new(0.1).mesh().uv(32, 18))),
            MeshMaterial3d(standard_materials.add(StandardMaterial {
                base_color: ORANGE.into(),
                emissive: LinearRgba::new(4.0, 0.0, 0.0, 0.0),
                ..default()
            })),
            Transform::from_xyz(20.0, 20.0, 0.0),
        )],
    ));
    */

    // camera
    commands.spawn((
        Name::new("Camera"),
        Camera3d::default(),
        Transform::from_xyz(0., 0., 50.).looking_at(Vec3::ZERO, Vec3::Y),
    ));
}

#[derive(Resource, Debug, Clone)]
struct SunDir(Dir3);

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone)]
struct PlanetMaterial {
    #[uniform(0)]
    sun_dir: Vec3,
    #[texture(1)]
    #[sampler(2)]
    surface_texture_day: Option<Handle<Image>>,
    #[texture(3)]
    #[sampler(4)]
    surface_texture_night: Option<Handle<Image>>,
    #[texture(5)]
    #[sampler(6)]
    cloud_texture: Option<Handle<Image>>,
    #[texture(7)]
    #[sampler(8)]
    normal_texture: Option<Handle<Image>>,
    #[texture(9)]
    #[sampler(10)]
    specular_texture: Option<Handle<Image>>,
    alpha_mode: AlphaMode,
}

impl Material for PlanetMaterial {
    fn fragment_shader() -> ShaderRef {
        PLANET_SHADER_ASSET_PATH.into()
    }

    fn alpha_mode(&self) -> AlphaMode {
        self.alpha_mode
    }
}

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone)]
struct SpaceMaterial {
    #[texture(0)]
    #[sampler(1)]
    surface_texture: Option<Handle<Image>>,
    alpha_mode: AlphaMode,
}

impl Material for SpaceMaterial {
    fn fragment_shader() -> ShaderRef {
        SPACE_SHADER_ASSET_PATH.into()
    }

    fn alpha_mode(&self) -> AlphaMode {
        self.alpha_mode
    }

    fn specialize(
        _pipeline: &MaterialPipeline<Self>,
        descriptor: &mut RenderPipelineDescriptor,
        _layout: &MeshVertexBufferLayoutRef,
        _key: MaterialPipelineKey<Self>,
    ) -> Result<(), SpecializedMeshPipelineError> {
        descriptor.primitive.cull_mode = Some(Face::Front);

        Ok(())
    }
}
