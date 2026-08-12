import bpy
import math
import os
from mathutils import Vector


def mat(name, color, roughness=0.68, emission=None):
    item = bpy.data.materials.new(name)
    item.diffuse_color = (*color, 1)
    item.use_nodes = True
    shader = item.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    if emission:
        shader.inputs["Emission Color"].default_value = (*emission[0], 1)
        shader.inputs["Emission Strength"].default_value = emission[1]
    return item


def fur_mat(name, color):
    item = mat(name, color, 0.8)
    nodes = item.node_tree.nodes
    links = item.node_tree.links
    shader = nodes.get("Principled BSDF")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 28
    noise.inputs["Detail"].default_value = 2.5
    noise.inputs["Roughness"].default_value = 0.72
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*[max(c * .65, .006) for c in color], 1)
    ramp.color_ramp.elements[1].color = (*[min(c * 1.16 + .02, 1) for c in color], 1)
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = .06
    bump.inputs["Distance"].default_value = .025
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], shader.inputs["Base Color"])
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    return item


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def sphere(name, loc, scale, material, bone, rotation=(0, 0, 0), segments=28):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=20, location=loc,
                                        rotation=tuple(math.radians(v) for v in rotation))
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.data.materials.append(material)
    obj["bone"] = bone
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj


def fuse(objects, name, voxel=.045):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    remesh = obj.modifiers.new("Organic_Remesh", "REMESH")
    remesh.mode = "VOXEL"
    remesh.voxel_size = voxel
    remesh.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth = obj.modifiers.new("Surface_Smooth", "SMOOTH")
    smooth.factor = .38
    smooth.iterations = 4
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    obj.select_set(False)
    return obj


def weight_rigid(obj, bone):
    group = obj.vertex_groups.new(name=bone)
    group.add(range(len(obj.data.vertices)), 1, "REPLACE")


def weight_body(obj):
    centers = {"Pelvis": .58, "Spine": 1.08, "Chest": 1.55, "Neck": 1.83, "Head": 2.18}
    widths = {"Pelvis": .55, "Spine": .58, "Chest": .5, "Neck": .27, "Head": .62}
    groups = {name: obj.vertex_groups.new(name=name) for name in centers}
    for vertex in obj.data.vertices:
        values = {name: max(0, 1 - abs(vertex.co.z - center) / widths[name]) for name, center in centers.items()}
        total = sum(values.values()) or 1
        for name, value in values.items():
            if value:
                groups[name].add([vertex.index], value / total, "REPLACE")


def weight_arm(obj, side):
    groups = {name: obj.vertex_groups.new(name=f"{name}_{side}") for name in ("Arm", "Forearm", "Hand")}
    for vertex in obj.data.vertices:
        hand = max(0, min(1, (-vertex.co.y - .3) / .32))
        upper = max(0, min(1, (vertex.co.z - 1.35) / .45))
        fore = max(.02, 1 - hand - upper)
        total = hand + upper + fore
        for name, value in (("Arm", upper), ("Forearm", fore), ("Hand", hand)):
            groups[name].add([vertex.index], value / total, "REPLACE")


def weight_leg(obj, side):
    leg = obj.vertex_groups.new(name=f"Leg_{side}")
    foot = obj.vertex_groups.new(name=f"Foot_{side}")
    for vertex in obj.data.vertices:
        foot_weight = max(0, min(1, (.34 - vertex.co.z) / .27))
        leg.add([vertex.index], 1 - foot_weight, "REPLACE")
        foot.add([vertex.index], foot_weight, "REPLACE")


def armature(rabbit=False):
    data = bpy.data.armatures.new("Character_Rig")
    rig = bpy.data.objects.new("Character_Rig", data)
    bpy.context.collection.objects.link(rig)
    rig.show_in_front = False
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    specs = [
        ("Root", (0, 0, 0), (0, 0, .2), None),
        ("Pelvis", (0, 0, .2), (0, 0, .72), "Root"),
        ("Spine", (0, 0, .72), (0, 0, 1.3), "Pelvis"),
        ("Chest", (0, 0, 1.3), (0, 0, 1.75), "Spine"),
        ("Neck", (0, 0, 1.75), (0, 0, 1.95), "Chest"),
        ("Head", (0, 0, 1.95), (0, 0, 2.48), "Neck"),
    ]
    if rabbit:
        specs += [
            ("Ear_L", (-.26, 0, 2.38), (-.38, .02, 3.12), "Head"),
            ("Ear_L_Tip", (-.38, .02, 3.12), (-.42, .03, 3.75), "Ear_L"),
            ("Ear_R", (.26, 0, 2.38), (.38, .02, 3.12), "Head"),
            ("Ear_R_Tip", (.38, .02, 3.12), (.42, .03, 3.75), "Ear_R"),
        ]
    else:
        specs += [("Ear_L", (-.28, 0, 2.38), (-.55, 0, 2.57), "Head"),
                  ("Ear_R", (.28, 0, 2.38), (.55, 0, 2.57), "Head")]
    specs += [
        ("Arm_L", (-.45, 0, 1.72), (-.68, -.05, 1.48), "Chest"),
        ("Forearm_L", (-.68, -.05, 1.48), (-.77, -.3, 1.3), "Arm_L"),
        ("Hand_L", (-.77, -.3, 1.3), (-.72, -.56, 1.25), "Forearm_L"),
        ("Arm_R", (.45, 0, 1.72), (.68, -.05, 1.48), "Chest"),
        ("Forearm_R", (.68, -.05, 1.48), (.77, -.3, 1.3), "Arm_R"),
        ("Hand_R", (.77, -.3, 1.3), (.72, -.56, 1.25), "Forearm_R"),
        ("Leg_L", (-.25, 0, .7), (-.44, 0, .24), "Pelvis"),
        ("Foot_L", (-.44, 0, .24), (-.47, -.5, .12), "Leg_L"),
        ("Leg_R", (.25, 0, .7), (.44, 0, .24), "Pelvis"),
        ("Foot_R", (.44, 0, .24), (.47, -.5, .12), "Leg_R"),
    ]
    bones = {}
    for name, head, tail, parent in specs:
        bone = data.edit_bones.new(name)
        bone.head, bone.tail = head, tail
        bone.use_deform = name != "Root"
        if parent:
            bone.parent = bones[parent]
        bones[name] = bone
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.select_set(False)
    return rig, [item[0] for item in specs]


def join_skin(parts, rig, bones):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        if not obj.vertex_groups:
            weight_rigid(obj, obj.get("bone", "Head"))
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    mesh = bpy.context.object
    mesh.name = "Character_Mesh"
    modifier = mesh.modifiers.new("Armature", "ARMATURE")
    modifier.object = rig
    mesh.parent = rig
    groups = {group.name for group in mesh.vertex_groups}
    missing = [name for name in bones if name != "Root" and name not in groups]
    for name in missing:
        mesh.vertex_groups.new(name=name)
    fallback = mesh.vertex_groups.get("Spine")
    repaired = 0
    for vertex in mesh.data.vertices:
        total = sum(item.weight for item in vertex.groups)
        if total < .999:
            fallback.add([vertex.index], 1 - total, "ADD")
            repaired += 1
    print(f"WEIGHTS_OK vertices={len(mesh.data.vertices)} polygons={len(mesh.data.polygons)} repaired={repaired}")
    mesh.select_set(False)
    return mesh


def make_eye(side, x, z, materials, scale=1):
    parts = [sphere(f"Eye_{side}", (x, -.59, z), (.15*scale, .09, .19*scale), materials["eye"], "Head")]
    parts.append(sphere(f"EyeGlow_{side}", (x, -.675, z-.01), (.08*scale, .018, .1*scale), materials["iris"], "Head", segments=20))
    parts.append(sphere(f"EyeLight_{side}", (x-.04, -.697, z+.06), (.04, .012, .048), materials["white"], "Head", segments=16))
    return parts


def build(config, script_path):
    root = os.path.dirname(os.path.dirname(os.path.abspath(script_path)))
    renders = os.path.join(root, "renders")
    os.makedirs(renders, exist_ok=True)
    clear()
    dark = fur_mat("MAT_Fur_Main", config["fur"])
    cream = fur_mat("MAT_Cream", config.get("cream", (.72, .54, .34)))
    pink = mat("MAT_Soft_Pink", (.74, .38, .34), .55)
    materials = {
        "fur": dark, "cream": cream, "pink": pink,
        "eye": mat("MAT_Eyes", (.003, .002, .001), .08),
        "iris": mat("MAT_Iris", (.2, .05, .008), .15),
        "white": mat("MAT_Highlight", (1, 1, 1), .05),
    }
    body_scale = config.get("body", (1, 1, 1))
    head_scale = config.get("head", (1, 1, 1))
    rabbit = config.get("rabbit", False)
    main = [
        sphere("Torso", (0, .08, 1.2), (.82*body_scale[0], .6*body_scale[1], .98*body_scale[2]), dark, "Spine", segments=34),
        sphere("Chest", (0, 0, 1.68), (.72*body_scale[0], .56, .58), dark, "Chest", segments=32),
        sphere("Pelvis", (0, .06, .68), (.62*body_scale[0], .48, .42), dark, "Pelvis", segments=30),
        sphere("Head", (0, -.03, 2.1), (.76*head_scale[0], .58*head_scale[1], .63*head_scale[2]), dark, "Head", segments=36),
        sphere("CheekL", (-.38*head_scale[0], -.45, 2.0), (.41, .25, .3), dark, "Head", segments=30),
        sphere("CheekR", (.38*head_scale[0], -.45, 2.0), (.41, .25, .3), dark, "Head", segments=30),
        sphere("MuzzleL", (-.18, -.65, 1.95), (.29, .19, .21), cream, "Head", segments=28),
        sphere("MuzzleR", (.18, -.65, 1.95), (.29, .19, .21), cream, "Head", segments=28),
    ]
    body_mesh = fuse(main, "Organic_Body", .04)
    body_mesh.data.materials.clear()
    body_mesh.data.materials.append(dark)
    body_mesh.data.materials.append(cream)
    for polygon in body_mesh.data.polygons:
        c = polygon.center
        if c.y < -.47 and ((c.z < 1.72 and abs(c.x) < .45) or (c.y < -.58 and 1.76 < c.z < 2.14 and abs(c.x) < .48)):
            polygon.material_index = 1
    weight_body(body_mesh)
    parts = [body_mesh]
    eye_z = 2.27
    parts += make_eye("L", -.28, eye_z, materials, config.get("eye_scale", 1))
    parts += make_eye("R", .28, eye_z, materials, config.get("eye_scale", 1))
    parts.append(sphere("Nose", (0, -.82, 2.0), (.1, .065, .07), pink, "Head", segments=22))
    if rabbit:
        ear_length = config.get("ear_length", 1)
        for side, sign in (("L", -1), ("R", 1)):
            outer = sphere(f"Ear_{side}", (sign*.34, .0, 3.0), (.25, .14, .82*ear_length), dark, f"Ear_{side}", rotation=(0, sign*9, sign*4), segments=30)
            inner = sphere(f"EarInner_{side}", (sign*.34, -.125, 3.0), (.135, .025, .63*ear_length), pink, f"Ear_{side}", rotation=(0, sign*9, sign*4), segments=24)
            parts += [outer, inner]
        parts.append(sphere("Tail", (0, .67, 1.0), (.28, .25, .28), cream, "Pelvis", segments=26))
    else:
        for side, sign in (("L", -1), ("R", 1)):
            parts += [sphere(f"Ear_{side}", (sign*.55, -.03, 2.45), (.23, .09, .14), dark, f"Ear_{side}", rotation=(8, sign*18, sign*8), segments=24),
                      sphere(f"EarInner_{side}", (sign*.55, -.115, 2.44), (.13, .025, .075), pink, f"Ear_{side}", rotation=(8, sign*18, sign*8), segments=18)]
    arm_size = config.get("arm_size", 1)
    fist_size = config.get("fist_size", 1)
    for side, sign in (("L", -1), ("R", 1)):
        lift = config.get("left_lift", .0) if side == "L" else 0
        arm_parts = [
            sphere("Upper", (sign*.66, -.02, 1.58+lift), (.24*arm_size, .23, .4*arm_size), dark, f"Arm_{side}", rotation=(5, sign*20, sign*7)),
            sphere("Fore", (sign*.75, -.27, 1.34+lift), (.21*arm_size, .2, .3*arm_size), dark, f"Forearm_{side}"),
            sphere("Fist", (sign*.72, -.5, 1.27+lift), (.22*fist_size, .18*fist_size, .2*fist_size), dark, f"Hand_{side}"),
        ]
        arm = fuse(arm_parts, f"Organic_Arm_{side}", .035)
        arm.data.materials.clear(); arm.data.materials.append(dark)
        weight_arm(arm, side)
        parts.append(arm)
    leg_length = config.get("leg_length", 1)
    for side, sign in (("L", -1), ("R", 1)):
        leg_parts = [
            sphere("Leg", (sign*.4, .02, .48*leg_length), (.36, .34, .45*leg_length), dark, f"Leg_{side}"),
            sphere("Foot", (sign*.45, -.22, .15), (.34, .46 if not rabbit else .58, .14), pink if not rabbit else dark, f"Foot_{side}"),
        ]
        leg = fuse(leg_parts, f"Organic_Leg_{side}", .035)
        leg.data.materials.clear(); leg.data.materials.append(dark if rabbit else pink)
        weight_leg(leg, side)
        parts.append(leg)
    rig, bones = armature(rabbit)
    mesh = join_skin(parts, rig, bones)
    if config.get("poncho"):
        add_poncho(materials, rig)
    if config.get("volcanic"):
        add_cracks(mesh, rig)
    floor, camera = stage(rabbit)
    name = config["name"]
    blend = os.path.join(root, f"{name}.blend")
    glb = os.path.join(root, f"{name}.glb")
    bpy.ops.wm.save_as_mainfile(filepath=blend)
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True); rig.select_set(True)
    for child in rig.children:
        child.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=True)
    render(camera, renders, rabbit)
    bpy.ops.wm.save_as_mainfile(filepath=blend)
    print(f"BUILD_OK name={name} blend={blend} glb={glb} vertices={len(mesh.data.vertices)} polygons={len(mesh.data.polygons)} materials={[m.name for m in mesh.data.materials]} bones={bones}")


def add_poncho(materials, rig):
    red = mat("MAT_Poncho_Red", (.62, .035, .025), .82)
    gold = mat("MAT_Poncho_Gold", (.95, .48, .025), .75)
    teal = mat("MAT_Poncho_Teal", (.02, .42, .48), .78)
    panels = (
        ("Poncho_Front", [(-.73,-.63,1.9),(.73,-.63,1.9),(.55,-.68,1.48),(0,-.72,1.2),(-.55,-.68,1.48)]),
        ("Poncho_Back", [(.73,.55,1.9),(-.73,.55,1.9),(-.55,.61,1.48),(0,.65,1.24),(.55,.61,1.48)]),
    )
    for name, vertices in panels:
        mesh_data=bpy.data.meshes.new(name+"_Mesh")
        mesh_data.from_pydata(vertices,[],[[0,1,2,3,4]])
        mesh_data.materials.append(red)
        panel=bpy.data.objects.new(name,mesh_data); bpy.context.collection.objects.link(panel)
        solid=panel.modifiers.new("Textile_Thickness","SOLIDIFY"); solid.thickness=.025
        bevel=panel.modifiers.new("Soft_Hem","BEVEL"); bevel.width=.018; bevel.segments=2
        weight_rigid(panel,"Chest"); modifier=panel.modifiers.new("Armature","ARMATURE"); modifier.object=rig; panel.parent=rig
    stripe_sets = (
        (gold, [(-.64,-.7,1.68),(0,-.74,1.36),(.64,-.7,1.68)]),
        (teal, [(-.58,-.715,1.58),(0,-.755,1.28),(.58,-.715,1.58)]),
        (gold, [(-.52,-.73,1.48),(0,-.77,1.22),(.52,-.73,1.48)]),
    )
    for index,(material,points) in enumerate(stripe_sets):
        curve=bpy.data.curves.new(f"Poncho_Stripe_{index}","CURVE"); curve.dimensions="3D"; curve.bevel_depth=.025; curve.bevel_resolution=3
        spline=curve.splines.new("POLY"); spline.points.add(2)
        for point,co in zip(spline.points,points): point.co=(*co,1)
        obj=bpy.data.objects.new(f"Poncho_Stripe_{index}",curve); bpy.context.collection.objects.link(obj); curve.materials.append(material)
        obj.parent=rig


def add_cracks(mesh, rig):
    glow = mat("MAT_Volcanic_Glow", (.75, .045, .003), .4, ((1, .025, 0), 2.4))
    for index, points in enumerate((
        [(-.31,-.59,2.34),(-.23,-.61,2.26),(-.28,-.615,2.18),(-.21,-.61,2.1)],
        [(.23,-.56,1.76),(.31,-.59,1.64),(.27,-.605,1.52),(.35,-.59,1.4),(.3,-.57,1.3)],
        [(-.42,-.49,.88),(-.36,-.53,.76),(-.4,-.54,.65),(-.34,-.51,.54)],
    )):
        curve = bpy.data.curves.new(f"Crack_{index}", "CURVE"); curve.dimensions="3D"; curve.bevel_depth=.005; curve.bevel_resolution=2
        spline=curve.splines.new("POLY"); spline.points.add(len(points)-1)
        for point, co in zip(spline.points, points): point.co=(*co,1)
        obj=bpy.data.objects.new(f"Crack_{index}",curve); bpy.context.collection.objects.link(obj); curve.materials.append(glow); obj.parent=rig


def point_at(obj, target):
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat("-Z","Y").to_euler()


def stage(rabbit=False):
    floor_mat=mat("MAT_Preview_Floor",(.035,.025,.055),.82)
    bpy.ops.mesh.primitive_plane_add(size=20,location=(0,0,-.005)); floor=bpy.context.object; floor.data.materials.append(floor_mat)
    world=bpy.context.scene.world or bpy.data.worlds.new("World"); bpy.context.scene.world=world; world.use_nodes=True
    bg=world.node_tree.nodes.get("Background"); bg.inputs["Color"].default_value=(.008,.006,.025,1); bg.inputs["Strength"].default_value=.25
    for name,loc,color,energy,size in (("Key",(3.8,-4.8,5.5),(1,.52,.28),850,4),("Fill",(-4,-2.5,3.5),(.22,.38,1),620,3.5),("Rim",(2.8,3,4.2),(.12,.45,1),900,3)):
        data=bpy.data.lights.new(name,"AREA"); data.energy=energy; data.color=color; data.shape="DISK"; data.size=size
        light=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(light); light.location=loc; point_at(light,(0,0,1.4))
    distance = 8.2 if rabbit else 6.8
    target_z = 1.85 if rabbit else 1.4
    bpy.ops.object.camera_add(location=(0,-distance,2.8 if rabbit else 2.55)); camera=bpy.context.object; camera.data.lens=58; point_at(camera,(0,0,target_z)); bpy.context.scene.camera=camera
    return floor,camera


def render(camera, folder, rabbit=False):
    scene=bpy.context.scene; scene.render.engine="BLENDER_EEVEE"; scene.render.resolution_x=720; scene.render.resolution_y=720; scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"; scene.view_settings.look="AgX - Medium High Contrast"
    if rabbit:
        views={"frontal":(0,-8.2,2.8),"lateral":(8.2,0,2.75),"trasera":(0,8.2,2.8),"tres_cuartos":(5.8,-5.8,3.0)}
        target=(0,0,1.85)
    else:
        views={"frontal":(0,-6.8,2.55),"lateral":(6.8,0,2.45),"trasera":(0,6.8,2.55),"tres_cuartos":(4.8,-4.8,2.75)}
        target=(0,0,1.4)
    for name,loc in views.items():
        camera.location=loc; point_at(camera,target); scene.render.filepath=os.path.join(folder,f"{name}.png"); bpy.ops.render.render(write_still=True)
