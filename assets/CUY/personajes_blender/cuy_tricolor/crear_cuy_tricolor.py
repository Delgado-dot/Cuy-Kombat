import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.dirname(os.path.abspath(__file__))
SOURCE_DIR = ROOT
MODELS_DIR = ROOT
RENDERS_DIR = os.path.join(ROOT, "renders_v2")
BLEND_PATH = os.path.join(SOURCE_DIR, "cuy_tricolor_v2.blend")
GLB_PATH = os.path.join(MODELS_DIR, "cuy_tricolor_v2.glb")


def ensure_directories():
    for path in (
        SOURCE_DIR,
        MODELS_DIR,
        RENDERS_DIR,
    ):
        os.makedirs(path, exist_ok=True)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.materials):
        for datablock in list(collection):
            if datablock.users == 0:
                collection.remove(datablock)


def create_material(name, color, roughness=0.62, metallic=0.0, coat=0.0):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Coat Weight"].default_value = coat
    return material


def create_fur_material(name, color):
    material = create_material(name, color, roughness=0.78)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    shader = nodes.get("Principled BSDF")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 32.0
    noise.inputs["Detail"].default_value = 3.0
    noise.inputs["Roughness"].default_value = 0.72
    noise.inputs["Distortion"].default_value = 0.12
    ramp = nodes.new("ShaderNodeValToRGB")
    dark = tuple(max(channel * 0.68, 0.008) for channel in color)
    light = tuple(min(channel * 1.15 + 0.025, 1.0) for channel in color)
    ramp.color_ramp.elements[0].color = (*dark, 1.0)
    ramp.color_ramp.elements[1].color = (*light, 1.0)
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.075
    bump.inputs["Distance"].default_value = 0.035
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], shader.inputs["Base Color"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    return material


def smooth_mesh(obj):
    for polygon in obj.data.polygons:
        polygon.use_smooth = True


def apply_transforms(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.select_set(False)


def apply_modifiers(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    for modifier in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.select_set(False)


def fuse_meshes(objects, name, voxel_size=0.065):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        apply_modifiers(obj)
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    fused = bpy.context.object
    fused.name = name
    remesh = fused.modifiers.new("Organic_Voxel_Remesh", "REMESH")
    remesh.mode = "VOXEL"
    remesh.voxel_size = voxel_size
    remesh.use_smooth_shade = True
    bpy.context.view_layer.objects.active = fused
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth = fused.modifiers.new("Organic_Smoothing", "SMOOTH")
    smooth.factor = 0.42
    smooth.iterations = 5
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    smooth_mesh(fused)
    fused.select_set(False)
    return fused


def set_materials(obj, ordered_materials):
    obj.data.materials.clear()
    for item in ordered_materials:
        obj.data.materials.append(item)


def assign_body_materials(obj, materials):
    set_materials(obj, [materials["dark_brown"], materials["orange_brown"], materials["cream"]])
    for polygon in obj.data.polygons:
        center = polygon.center
        cream_face = center.y < -0.47 and (
            (center.z < 1.75 and abs(center.x) < 0.47)
            or (center.z >= 1.75 and abs(center.x) < 0.2)
            or (center.y < -0.58 and 1.78 < center.z < 2.16 and abs(center.x) < 0.48)
        )
        if cream_face:
            polygon.material_index = 2
        elif center.x > 0.015:
            polygon.material_index = 1
        else:
            polygon.material_index = 0


def add_weight(obj, bone_name, vertex_index, weight):
    group = obj.vertex_groups.get(bone_name) or obj.vertex_groups.new(name=bone_name)
    group.add([vertex_index], max(0.0, min(1.0, weight)), "REPLACE")


def normalized_weights(values):
    total = sum(values.values())
    if total <= 0.0:
        return {next(iter(values)): 1.0}
    filtered = {name: value for name, value in values.items() if value > 0.001}
    filtered_total = sum(filtered.values())
    return {name: value / filtered_total for name, value in filtered.items()}


def weight_body(obj):
    for vertex in obj.data.vertices:
        z = vertex.co.z
        values = {
            "Pelvis": max(0.0, 1.0 - abs(z - 0.62) / 0.62),
            "Spine": max(0.0, 1.0 - abs(z - 1.15) / 0.58),
            "Chest": max(0.0, 1.0 - abs(z - 1.67) / 0.5),
            "Neck": max(0.0, 1.0 - abs(z - 1.88) / 0.25),
            "Head": max(0.0, 1.0 - abs(z - 2.2) / 0.55),
        }
        for bone_name, weight in normalized_weights(values).items():
            add_weight(obj, bone_name, vertex.index, weight)


def weight_arm(obj, side):
    for vertex in obj.data.vertices:
        y = vertex.co.y
        z = vertex.co.z
        hand = max(0.0, min(1.0, (-y - 0.32) / 0.28))
        forearm = max(0.0, 1.0 - abs(y + 0.28) / 0.34)
        upper = max(0.0, min(1.0, (z - 1.34) / 0.4))
        values = {f"Arm_{side}": upper, f"Forearm_{side}": forearm, f"Hand_{side}": hand}
        for bone_name, weight in normalized_weights(values).items():
            add_weight(obj, bone_name, vertex.index, weight)


def weight_leg(obj, side):
    for vertex in obj.data.vertices:
        foot = max(0.0, min(1.0, (0.36 - vertex.co.z) / 0.28))
        values = {f"Leg_{side}": 1.0 - foot, f"Foot_{side}": foot}
        for bone_name, weight in normalized_weights(values).items():
            add_weight(obj, bone_name, vertex.index, weight)


def assign_limb_materials(obj, fur_material, pink_material, hand=False):
    set_materials(obj, [fur_material, pink_material])
    for polygon in obj.data.polygons:
        if hand:
            polygon.material_index = 1 if polygon.center.y < -0.43 else 0
        else:
            polygon.material_index = 1 if polygon.center.z < 0.27 else 0


def uv_part(name, location, scale, material, bone, rotation=(0.0, 0.0, 0.0), segments=32, rings=24):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        location=location,
        rotation=tuple(math.radians(value) for value in rotation),
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    apply_transforms(obj)
    smooth_mesh(obj)
    obj.data.materials.append(material)
    obj["deform_bone"] = bone
    bevel = obj.modifiers.new("Soft_Edges", "BEVEL")
    bevel.width = 0.015
    bevel.segments = 2
    return obj


def create_body(materials):
    body = uv_part(
        "Body",
        (0.0, 0.08, 1.23),
        (0.88, 0.62, 0.99),
        materials["dark_brown"],
        "Spine",
        segments=40,
        rings=28,
    )
    body.data.materials.append(materials["orange_brown"])
    body.data.materials.append(materials["cream"])
    for polygon in body.data.polygons:
        center = body.data.vertices[polygon.vertices[0]].co
        average_x = sum(body.data.vertices[index].co.x for index in polygon.vertices) / len(polygon.vertices)
        average_y = sum(body.data.vertices[index].co.y for index in polygon.vertices) / len(polygon.vertices)
        average_z = sum(body.data.vertices[index].co.z for index in polygon.vertices) / len(polygon.vertices)
        if average_y < -0.42 and abs(average_x) < 0.48 and 0.48 < average_z < 1.88:
            polygon.material_index = 2
        elif average_x > 0.04:
            polygon.material_index = 1
    chest = uv_part(
        "Chest_Shape",
        (0.0, -0.03, 1.72),
        (0.78, 0.58, 0.62),
        materials["dark_brown"],
        "Chest",
        segments=36,
        rings=24,
    )
    chest.data.materials.append(materials["orange_brown"])
    for polygon in chest.data.polygons:
        average_x = sum(chest.data.vertices[index].co.x for index in polygon.vertices) / len(polygon.vertices)
        if average_x > 0.03:
            polygon.material_index = 1
    pelvis = uv_part(
        "Pelvis_Transition",
        (0.0, 0.07, 0.73),
        (0.64, 0.5, 0.46),
        materials["dark_brown"],
        "Pelvis",
        segments=32,
        rings=20,
    )
    pelvis.data.materials.append(materials["orange_brown"])
    for polygon in pelvis.data.polygons:
        average_x = sum(pelvis.data.vertices[index].co.x for index in polygon.vertices) / len(polygon.vertices)
        if average_x > 0.03:
            polygon.material_index = 1
    return [body, chest, pelvis]


def create_head(materials):
    parts = []
    head = uv_part(
        "Head",
        (0.0, -0.03, 2.1),
        (0.78, 0.59, 0.63),
        materials["dark_brown"],
        "Head",
        segments=40,
        rings=28,
    )
    head.data.materials.append(materials["orange_brown"])
    head.data.materials.append(materials["cream"])
    for polygon in head.data.polygons:
        average_x = sum(head.data.vertices[index].co.x for index in polygon.vertices) / len(polygon.vertices)
        average_y = sum(head.data.vertices[index].co.y for index in polygon.vertices) / len(polygon.vertices)
        average_z = sum(head.data.vertices[index].co.z for index in polygon.vertices) / len(polygon.vertices)
        if average_y < -0.35 and abs(average_x) < 0.18 and average_z > 2.12:
            polygon.material_index = 2
        elif average_x > 0.06:
            polygon.material_index = 1
    parts.append(head)
    neck = uv_part(
        "Neck_Transition",
        (0.0, 0.0, 1.88),
        (0.47, 0.43, 0.31),
        materials["dark_brown"],
        "Neck",
        segments=32,
        rings=20,
    )
    neck.data.materials.append(materials["orange_brown"])
    for polygon in neck.data.polygons:
        average_x = sum(neck.data.vertices[index].co.x for index in polygon.vertices) / len(polygon.vertices)
        if average_x > 0.03:
            polygon.material_index = 1
    parts.append(neck)
    parts.extend([
        uv_part("Cheek_L", (-0.42, -0.46, 1.99), (0.43, 0.25, 0.31), materials["dark_brown"], "Head", rotation=(8, -8, -8)),
        uv_part("Cheek_R", (0.42, -0.46, 1.99), (0.43, 0.25, 0.31), materials["orange_brown"], "Head", rotation=(8, 8, 8)),
        uv_part("Muzzle_L", (-0.19, -0.64, 1.94), (0.29, 0.18, 0.21), materials["cream"], "Head", rotation=(5, 0, -5)),
        uv_part("Muzzle_R", (0.19, -0.64, 1.94), (0.29, 0.18, 0.21), materials["cream"], "Head", rotation=(5, 0, 5)),
        uv_part("Nose", (0.0, -0.815, 2.01), (0.1, 0.065, 0.07), materials["pink"], "Head", rotation=(10, 0, 0), segments=24, rings=16),
    ])
    return parts


def create_eyes(materials):
    parts = []
    for side, x in (("L", -0.285), ("R", 0.285)):
        eye = uv_part(f"Eye_{side}", (x, -0.555, 2.27), (0.155, 0.1, 0.19), materials["eyes"], "Head", segments=32, rings=24)
        iris = uv_part(f"Eye_Warmth_{side}", (x, -0.648, 2.255), (0.087, 0.025, 0.11), materials["eye_brown"], "Head", segments=24, rings=16)
        highlight = uv_part(f"Eye_Highlight_{side}", (x - 0.04, -0.676, 2.33), (0.043, 0.018, 0.05), materials["white"], "Head", segments=20, rings=12)
        small_highlight = uv_part(f"Eye_Highlight_Small_{side}", (x + 0.045, -0.674, 2.22), (0.02, 0.011, 0.024), materials["white"], "Head", segments=16, rings=10)
        parts.extend([eye, iris, highlight, small_highlight])
    return parts


def create_ears(materials):
    parts = []
    ear_specs = (
        ("L", -0.55, materials["dark_brown"], -18),
        ("R", 0.55, materials["orange_brown"], 18),
    )
    for side, x, fur_material, angle in ear_specs:
        ear = uv_part(
            f"Ear_{side}_Mesh",
            (x, -0.04, 2.45),
            (0.24, 0.095, 0.14),
            fur_material,
            f"Ear_{side}",
            rotation=(8, angle, angle * 0.4),
            segments=28,
            rings=18,
        )
        inner = uv_part(
            f"Ear_{side}_Inner",
            (x, -0.125, 2.44),
            (0.135, 0.025, 0.075),
            materials["pink"],
            f"Ear_{side}",
            rotation=(8, angle, angle * 0.4),
            segments=20,
            rings=12,
        )
        parts.extend([ear, inner])
    return parts


def create_limbs(materials):
    parts = []
    for side, sign, material in (("L", -1, materials["dark_brown"]), ("R", 1, materials["orange_brown"])):
        upper = uv_part(
            f"UpperArm_{side}",
            (sign * 0.69, -0.02, 1.62),
            (0.25, 0.24, 0.42),
            material,
            f"Arm_{side}",
            rotation=(5, sign * 20, sign * 8),
            segments=28,
            rings=18,
        )
        forearm = uv_part(
            f"Forearm_{side}",
            (sign * 0.78, -0.28, 1.36),
            (0.22, 0.21, 0.32),
            material,
            f"Forearm_{side}",
            rotation=(sign * 14, sign * 8, sign * 6),
            segments=28,
            rings=18,
        )
        hand = uv_part(
            f"Fist_{side}",
            (sign * 0.75, -0.5, 1.28),
            (0.22, 0.18, 0.2),
            materials["pink"],
            f"Hand_{side}",
            rotation=(10, 0, sign * 8),
            segments=28,
            rings=18,
        )
        parts.extend([upper, forearm, hand])
        for finger_index, offset in enumerate((-0.11, 0.0, 0.11)):
            knuckle = uv_part(
                f"Knuckle_{side}_{finger_index}",
                (sign * (0.77 + offset * 0.15), -0.675, 1.3 + offset * 0.24),
                (0.07, 0.045, 0.065),
                materials["pink_light"],
                f"Hand_{side}",
                segments=16,
                rings=10,
            )
            parts.append(knuckle)
    for side, sign, material in (("L", -1, materials["dark_brown"]), ("R", 1, materials["orange_brown"])):
        leg = uv_part(
            f"Leg_{side}_Mesh",
            (sign * 0.43, 0.02, 0.48),
            (0.38, 0.36, 0.47),
            material,
            f"Leg_{side}",
            rotation=(0, sign * 4, sign * 6),
            segments=32,
            rings=20,
        )
        foot = uv_part(
            f"Foot_{side}_Mesh",
            (sign * 0.48, -0.2, 0.17),
            (0.35, 0.46, 0.15),
            materials["pink"],
            f"Foot_{side}",
            rotation=(0, 0, sign * 5),
            segments=32,
            rings=20,
        )
        parts.extend([leg, foot])
        for toe_index, offset in enumerate((-0.14, 0.0, 0.14)):
            toe = uv_part(
                f"Toe_{side}_{toe_index}",
                (sign * 0.48 + offset, -0.675, 0.145),
                (0.09, 0.11, 0.055),
                materials["pink_light"],
                f"Foot_{side}",
                segments=16,
                rings=10,
            )
            parts.append(toe)
    return parts


def add_whiskers(materials):
    whiskers = []
    for side, sign in (("L", -1), ("R", 1)):
        for index, height in enumerate((1.94, 2.02, 2.1)):
            curve_data = bpy.data.curves.new(f"Whisker_{side}_{index}", "CURVE")
            curve_data.dimensions = "3D"
            curve_data.resolution_u = 2
            curve_data.bevel_depth = 0.006
            curve_data.bevel_resolution = 2
            spline = curve_data.splines.new("BEZIER")
            spline.bezier_points.add(2)
            points = (
                (sign * 0.25, -0.78, height),
                (sign * 0.56, -0.86, height + (index - 1) * 0.025),
                (sign * 0.86, -0.79, height + (index - 1) * 0.06),
            )
            for point, coordinate in zip(spline.bezier_points, points):
                point.co = coordinate
                point.handle_left_type = "AUTO"
                point.handle_right_type = "AUTO"
            obj = bpy.data.objects.new(f"Whisker_{side}_{index}", curve_data)
            bpy.context.collection.objects.link(obj)
            curve_data.materials.append(materials["whisker"])
            obj["deform_bone"] = "Head"
            whiskers.append(obj)
    return whiskers


def create_armature():
    armature_data = bpy.data.armatures.new("CuyTricolor_Rig")
    armature = bpy.data.objects.new("CuyTricolor_Rig", armature_data)
    bpy.context.collection.objects.link(armature)
    armature.show_in_front = True
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    specs = {
        "Root": ((0, 0, 0), (0, 0, 0.22), None),
        "Pelvis": ((0, 0, 0.22), (0, 0, 0.75), "Root"),
        "Spine": ((0, 0, 0.75), (0, 0, 1.35), "Pelvis"),
        "Chest": ((0, 0, 1.35), (0, 0, 1.85), "Spine"),
        "Neck": ((0, 0, 1.85), (0, 0, 2.02), "Chest"),
        "Head": ((0, 0, 2.02), (0, 0, 2.5), "Neck"),
        "Ear_L": ((-0.32, 0, 2.42), (-0.55, 0, 2.7), "Head"),
        "Ear_R": ((0.32, 0, 2.42), (0.55, 0, 2.7), "Head"),
        "Arm_L": ((-0.5, 0, 1.82), (-0.68, -0.04, 1.57), "Chest"),
        "Forearm_L": ((-0.68, -0.04, 1.57), (-0.78, -0.3, 1.38), "Arm_L"),
        "Hand_L": ((-0.78, -0.3, 1.38), (-0.75, -0.55, 1.25), "Forearm_L"),
        "Arm_R": ((0.5, 0, 1.82), (0.68, -0.04, 1.57), "Chest"),
        "Forearm_R": ((0.68, -0.04, 1.57), (0.78, -0.3, 1.38), "Arm_R"),
        "Hand_R": ((0.78, -0.3, 1.38), (0.75, -0.55, 1.25), "Forearm_R"),
        "Leg_L": ((-0.27, 0, 0.72), (-0.45, 0, 0.25), "Pelvis"),
        "Foot_L": ((-0.45, 0, 0.25), (-0.48, -0.48, 0.14), "Leg_L"),
        "Leg_R": ((0.27, 0, 0.72), (0.45, 0, 0.25), "Pelvis"),
        "Foot_R": ((0.45, 0, 0.25), (0.48, -0.48, 0.14), "Leg_R"),
    }
    edit_bones = {}
    for name, (head, tail, parent_name) in specs.items():
        bone = armature_data.edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        bone.use_deform = name != "Root"
        edit_bones[name] = bone
        if parent_name:
            bone.parent = edit_bones[parent_name]
    bpy.ops.object.mode_set(mode="OBJECT")
    armature.select_set(False)
    return armature


def convert_curves(curves):
    converted = []
    for curve in curves:
        bone_name = curve.get("deform_bone", "Head")
        bpy.context.view_layer.objects.active = curve
        curve.select_set(True)
        bpy.ops.object.convert(target="MESH")
        curve["deform_bone"] = bone_name
        converted.append(curve)
        curve.select_set(False)
    return converted


def join_and_skin(parts, armature):
    for part in parts:
        bpy.context.view_layer.objects.active = part
        part.select_set(True)
        if len(part.vertex_groups) == 0:
            bone_name = part.get("deform_bone", "Spine")
            group = part.vertex_groups.new(name=bone_name)
            group.add(range(len(part.data.vertices)), 1.0, "REPLACE")
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    mesh = bpy.context.object
    mesh.name = "CuyTricolor_Mesh"
    modifier = mesh.modifiers.new("Armature", "ARMATURE")
    modifier.object = armature
    mesh.parent = armature
    mesh.select_set(False)
    return mesh


def validate_weights(mesh, required_bones):
    group_names = {group.name for group in mesh.vertex_groups}
    missing_groups = [name for name in required_bones if name != "Root" and name not in group_names]
    fallback_group = mesh.vertex_groups.get("Spine") or mesh.vertex_groups.new(name="Spine")
    repaired = 0
    for vertex in mesh.data.vertices:
        total = sum(group.weight for group in vertex.groups)
        if total < 0.999:
            fallback_group.add([vertex.index], 1.0 - total, "ADD")
            repaired += 1
    unweighted = 0
    for vertex in mesh.data.vertices:
        total = sum(group.weight for group in vertex.groups)
        if total < 0.999:
            unweighted += 1
    if missing_groups or unweighted:
        raise RuntimeError(f"Weight validation failed: missing={missing_groups}, unweighted={unweighted}")
    print(f"WEIGHTS_OK vertices={len(mesh.data.vertices)} groups={len(mesh.vertex_groups)} repaired={repaired}")


def create_stage(materials):
    floor_material = create_material("Preview_Floor", (0.035, 0.025, 0.055), roughness=0.82)
    bpy.ops.mesh.primitive_plane_add(size=20, location=(0, 0, -0.005))
    floor = bpy.context.object
    floor.name = "Preview_Floor"
    floor.data.materials.append(floor_material)
    bevel = floor.modifiers.new("Floor_Bevel", "BEVEL")
    bevel.width = 0.04
    bevel.segments = 3

    world = bpy.context.scene.world or bpy.data.worlds.new("Preview_World")
    bpy.context.scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.008, 0.006, 0.025, 1.0)
    background.inputs["Strength"].default_value = 0.28

    light_specs = (
        ("Key_Light", (3.8, -4.8, 5.5), (1.0, 0.52, 0.28), 850.0, 4.0),
        ("Fill_Light", (-4.0, -2.5, 3.5), (0.22, 0.38, 1.0), 620.0, 3.5),
        ("Rim_Light", (2.8, 3.0, 4.2), (0.12, 0.45, 1.0), 900.0, 3.0),
    )
    for name, location, color, energy, size in light_specs:
        data = bpy.data.lights.new(name, "AREA")
        data.energy = energy
        data.color = color
        data.shape = "DISK"
        data.size = size
        light = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(light)
        light.location = location
        point_at(light, (0, 0, 1.35))

    bpy.ops.object.camera_add(location=(0, -6.5, 2.5))
    camera = bpy.context.object
    camera.name = "Preview_Camera"
    camera.data.lens = 58
    camera.data.sensor_width = 36
    point_at(camera, (0, 0, 1.35))
    bpy.context.scene.camera = camera
    return floor, camera


def point_at(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render_views(camera):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 720
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.render.resolution_percentage = 100
    views = {
        "frontal": (0.0, -6.5, 2.45),
        "lateral": (6.5, 0.0, 2.35),
        "trasera": (0.0, 6.5, 2.45),
        "tres_cuartos": (4.6, -4.6, 2.7),
    }
    for name, location in views.items():
        camera.location = location
        point_at(camera, (0, 0, 1.35))
        scene.render.filepath = os.path.join(RENDERS_DIR, f"{name}.png")
        bpy.ops.render.render(write_still=True)
        print(f"RENDER_OK {name} {scene.render.filepath}")


def export_character(mesh, armature):
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.export_scene.gltf(
        filepath=GLB_PATH,
        export_format="GLB",
        use_selection=True,
        export_animations=True,
    )
    if not os.path.isfile(GLB_PATH) or os.path.getsize(GLB_PATH) < 1024:
        raise RuntimeError("GLB export failed")
    print(f"GLB_OK {GLB_PATH} bytes={os.path.getsize(GLB_PATH)}")


def main():
    ensure_directories()
    clear_scene()
    materials = {
        "dark_brown": create_fur_material("MAT_Dark_Brown", (0.105, 0.032, 0.018)),
        "cream": create_fur_material("MAT_Cream", (0.82, 0.61, 0.39)),
        "orange_brown": create_fur_material("MAT_Orange_Brown", (0.61, 0.18, 0.035)),
        "pink": create_material("MAT_Soft_Pink", (0.72, 0.36, 0.31), roughness=0.56),
        "pink_light": create_material("MAT_Pink_Highlight", (0.92, 0.59, 0.52), roughness=0.48),
        "eyes": create_material("MAT_Eyes", (0.004, 0.002, 0.001), roughness=0.08, coat=0.7),
        "eye_brown": create_material("MAT_Eye_Warmth", (0.21, 0.055, 0.01), roughness=0.18, coat=0.35),
        "white": create_material("MAT_Eye_Highlight", (1.0, 1.0, 1.0), roughness=0.05),
        "whisker": create_material("MAT_Whiskers", (0.035, 0.025, 0.02), roughness=0.5),
    }
    generated = []
    generated.extend(create_body(materials))
    generated.extend(create_head(materials))
    generated.extend(create_eyes(materials))
    generated.extend(create_ears(materials))
    generated.extend(create_limbs(materials))

    main_names = {
        "Body", "Chest_Shape", "Pelvis_Transition", "Neck_Transition", "Head",
        "Cheek_L", "Cheek_R", "Muzzle_L", "Muzzle_R",
    }
    main_parts = [obj for obj in generated if obj.name in main_names]
    limb_prefixes = (
        "UpperArm_", "Forearm_", "Fist_", "Knuckle_",
        "Leg_L_Mesh", "Leg_R_Mesh", "Foot_", "Toe_",
    )
    detail_parts = [obj for obj in generated if obj.name not in main_names and not obj.name.startswith(limb_prefixes)]
    arm_groups = {
        side: [obj for obj in generated if obj.name.startswith((f"UpperArm_{side}", f"Forearm_{side}", f"Fist_{side}", f"Knuckle_{side}_"))]
        for side in ("L", "R")
    }
    leg_groups = {
        side: [obj for obj in generated if obj.name.startswith((f"Leg_{side}_Mesh", f"Foot_{side}_Mesh", f"Toe_{side}_"))]
        for side in ("L", "R")
    }
    body_mesh = fuse_meshes(main_parts, "CuyTricolor_Body", voxel_size=0.035)
    assign_body_materials(body_mesh, materials)
    weight_body(body_mesh)

    arm_meshes = []
    leg_meshes = []
    consumed_names = set(main_names)
    for side, fur_material in (("L", materials["dark_brown"]), ("R", materials["orange_brown"])):
        arm_parts = arm_groups[side]
        consumed_names.update(obj.name for obj in arm_parts)
        arm = fuse_meshes(arm_parts, f"Arm_{side}_Organic", voxel_size=0.032)
        assign_limb_materials(arm, fur_material, materials["pink"], hand=True)
        weight_arm(arm, side)
        arm_meshes.append(arm)
        leg_parts = leg_groups[side]
        consumed_names.update(obj.name for obj in leg_parts)
        leg = fuse_meshes(leg_parts, f"Leg_{side}_Organic", voxel_size=0.032)
        assign_limb_materials(leg, fur_material, materials["pink"], hand=False)
        weight_leg(leg, side)
        leg_meshes.append(leg)
    parts = [body_mesh, *arm_meshes, *leg_meshes, *detail_parts]
    armature = create_armature()
    mesh = join_and_skin(parts, armature)
    required_bones = [
        "Root", "Pelvis", "Spine", "Chest", "Neck", "Head", "Ear_L", "Ear_R",
        "Arm_L", "Forearm_L", "Hand_L", "Arm_R", "Forearm_R", "Hand_R",
        "Leg_L", "Foot_L", "Leg_R", "Foot_R",
    ]
    validate_weights(mesh, required_bones)
    floor, camera = create_stage(materials)
    bpy.context.scene["character"] = "Cuy Tricolor"
    bpy.context.scene["origin_standard"] = "Root and object origins centered between feet at world origin"
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    if not os.path.isfile(BLEND_PATH):
        raise RuntimeError("Blend save failed")
    print(f"BLEND_OK {BLEND_PATH} bytes={os.path.getsize(BLEND_PATH)}")
    export_character(mesh, armature)
    render_views(camera)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    print("CUY_TRICOLOR_BUILD_COMPLETE")


if __name__ == "__main__":
    main()
