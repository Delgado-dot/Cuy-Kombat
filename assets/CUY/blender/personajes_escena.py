import bpy
import math
from mathutils import Vector


def limpiar_escena():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.materials, bpy.data.curves, bpy.data.meshes):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def material(nombre, color, metalico=0.0, rugosidad=0.55, emision=None, fuerza=0.0):
    mat = bpy.data.materials.get(nombre) or bpy.data.materials.new(nombre)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metalico
    bsdf.inputs["Roughness"].default_value = rugosidad
    if emision:
        bsdf.inputs["Emission Color"].default_value = (*emision, 1.0)
        bsdf.inputs["Emission Strength"].default_value = fuerza
    return mat


def suavizar(objeto):
    if objeto.type == "MESH":
        for poligono in objeto.data.polygons:
            poligono.use_smooth = True


def esfera(nombre, posicion, escala, mat, padre=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, location=posicion)
    objeto = bpy.context.object
    objeto.name = nombre
    objeto.scale = escala
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    objeto.data.materials.append(mat)
    suavizar(objeto)
    if padre:
        objeto.parent = padre
    return objeto


def elipsoide_rotado(nombre, posicion, escala, rotacion, mat, padre=None):
    objeto = esfera(nombre, posicion, escala, mat, padre)
    objeto.rotation_euler = tuple(math.radians(valor) for valor in rotacion)
    return objeto


def curva_tubo(nombre, puntos, grosor, mat, padre=None):
    curva = bpy.data.curves.new(nombre, "CURVE")
    curva.dimensions = "3D"
    curva.bevel_depth = grosor
    curva.bevel_resolution = 4
    spline = curva.splines.new("BEZIER")
    spline.bezier_points.add(len(puntos) - 1)
    for punto_curva, coordenada in zip(spline.bezier_points, puntos):
        punto_curva.co = coordenada
        punto_curva.handle_left_type = "AUTO"
        punto_curva.handle_right_type = "AUTO"
    objeto = bpy.data.objects.new(nombre, curva)
    bpy.context.collection.objects.link(objeto)
    objeto.data.materials.append(mat)
    if padre:
        objeto.parent = padre
    return objeto


def ojo(prefijo, posicion, escala, padre, mats):
    esfera(f"{prefijo}_ojo", posicion, escala, mats["ojo"], padre)
    brillo = (posicion[0] - 0.035, posicion[1] - 0.095, posicion[2] + 0.055)
    esfera(f"{prefijo}_brillo", brillo, (0.035, 0.022, 0.035), mats["blanco"], padre)


def pata(nombre, base, lado, mat, padre, levantada=False):
    x, y, z = base
    if levantada:
        brazo = elipsoide_rotado(f"{nombre}_brazo", (x + lado * 0.64, y - 0.04, z + 1.18),
                                 (0.22, 0.22, 0.48), (0, lado * 58, lado * 8), mat, padre)
        esfera(f"{nombre}_mano", (x + lado * 0.83, y - 0.08, z + 1.49), (0.25, 0.2, 0.23), mat, brazo)
    else:
        brazo = elipsoide_rotado(f"{nombre}_brazo", (x + lado * 0.57, y - 0.08, z + 0.92),
                                 (0.2, 0.22, 0.42), (lado * 5, lado * 28, lado * 10), mat, padre)
        esfera(f"{nombre}_mano", (x + lado * 0.68, y - 0.14, z + 0.69), (0.24, 0.2, 0.22), mat, brazo)


def pie(nombre, posicion, escala, mat, padre, angulo=0):
    return elipsoide_rotado(nombre, posicion, escala, (0, 0, angulo), mat, padre)


def cara_roedor(nombre, centro, cuerpo_mat, padre, mats, mancha=None):
    x, y, z = centro
    cabeza = esfera(f"{nombre}_cabeza", (x, y, z), (0.84, 0.68, 0.72), cuerpo_mat, padre)
    esfera(f"{nombre}_hocico", (x, y - 0.61, z - 0.13), (0.54, 0.28, 0.32), mats["crema"], cabeza)
    esfera(f"{nombre}_nariz", (x, y - 0.87, z - 0.06), (0.105, 0.07, 0.075), mats["nariz"], cabeza)
    ojo(f"{nombre}_izq", (x - 0.31, y - 0.54, z + 0.18), (0.145, 0.09, 0.18), cabeza, mats)
    ojo(f"{nombre}_der", (x + 0.31, y - 0.54, z + 0.18), (0.145, 0.09, 0.18), cabeza, mats)
    for lado in (-1, 1):
        oreja = esfera(f"{nombre}_oreja_{lado}", (x + lado * 0.58, y - 0.02, z + 0.43),
                       (0.27, 0.16, 0.24), cuerpo_mat, cabeza)
        oreja.rotation_euler.y = math.radians(lado * 22)
        esfera(f"{nombre}_oreja_interior_{lado}", (x + lado * 0.6, y - 0.17, z + 0.43),
               (0.16, 0.06, 0.14), mats["oreja"], oreja)
    if mancha:
        elipsoide_rotado(f"{nombre}_mancha", (x + mancha[0], y - 0.655, z + mancha[1]),
                         (0.38, 0.035, 0.47), (0, 0, mancha[2]), mancha[3], cabeza)
    return cabeza


def cobaya(nombre, x, escala, cuerpo_mat, mats, mancha=None, pose=(False, False)):
    raiz = bpy.data.objects.new(nombre, None)
    bpy.context.collection.objects.link(raiz)
    raiz.scale = (escala, escala, escala)
    cuerpo = esfera(f"{nombre}_cuerpo", (x, 0, 1.55), (0.92, 0.7, 1.15), cuerpo_mat, raiz)
    esfera(f"{nombre}_panza", (x, -0.65, 1.45), (0.57, 0.055, 0.76), mats["crema"], cuerpo)
    cara_roedor(nombre, (x, -0.02, 2.52), cuerpo_mat, raiz, mats, mancha)
    pata(nombre + "_izq", (x, 0, 1.2), -1, cuerpo_mat, raiz, pose[0])
    pata(nombre + "_der", (x, 0, 1.2), 1, cuerpo_mat, raiz, pose[1])
    pie(f"{nombre}_pie_izq", (x - 0.49, -0.12, 0.45), (0.42, 0.55, 0.25), cuerpo_mat, raiz, -8)
    pie(f"{nombre}_pie_der", (x + 0.49, -0.12, 0.45), (0.42, 0.55, 0.25), cuerpo_mat, raiz, 8)
    return raiz


def oreja_conejo(nombre, posicion, angulo, mat, padre, mats):
    oreja = elipsoide_rotado(nombre, posicion, (0.3, 0.18, 0.98), (0, angulo, -angulo * 0.18), mat, padre)
    interior = elipsoide_rotado(nombre + "_interior", (posicion[0], posicion[1] - 0.17, posicion[2]),
                                (0.16, 0.045, 0.72), (0, angulo, -angulo * 0.18), mats["oreja"], oreja)
    return oreja, interior


def conejo(nombre, x, cuerpo_mat, mats, lava=False):
    raiz = bpy.data.objects.new(nombre, None)
    bpy.context.collection.objects.link(raiz)
    cuerpo = esfera(f"{nombre}_cuerpo", (x, 0, 1.55), (0.78, 0.62, 1.15), cuerpo_mat, raiz)
    esfera(f"{nombre}_panza", (x, -0.58, 1.48), (0.48, 0.05, 0.76), mats["crema"], cuerpo)
    cabeza = esfera(f"{nombre}_cabeza", (x, -0.03, 2.62), (0.72, 0.59, 0.7), cuerpo_mat, raiz)
    esfera(f"{nombre}_hocico", (x, -0.55, 2.45), (0.45, 0.25, 0.29), mats["crema"], cabeza)
    esfera(f"{nombre}_nariz", (x, -0.78, 2.52), (0.1, 0.065, 0.07), mats["nariz"], cabeza)
    ojo(f"{nombre}_izq", (x - 0.28, -0.51, 2.77), (0.14, 0.085, 0.19), cabeza, mats)
    ojo(f"{nombre}_der", (x + 0.28, -0.51, 2.77), (0.14, 0.085, 0.19), cabeza, mats)
    oreja_conejo(f"{nombre}_oreja_izq", (x - 0.3, 0.02, 3.62), -12, cuerpo_mat, raiz, mats)
    oreja_conejo(f"{nombre}_oreja_der", (x + 0.31, 0.02, 3.68), 10, cuerpo_mat, raiz, mats)
    pata(nombre + "_izq", (x, 0, 1.18), -1, cuerpo_mat, raiz, True)
    pata(nombre + "_der", (x, 0, 1.18), 1, cuerpo_mat, raiz, True)
    pie(f"{nombre}_pie_izq", (x - 0.46, -0.12, 0.42), (0.42, 0.62, 0.24), cuerpo_mat, raiz, -10)
    pie(f"{nombre}_pie_der", (x + 0.46, -0.12, 0.42), (0.42, 0.62, 0.24), cuerpo_mat, raiz, 10)
    esfera(f"{nombre}_cola", (x + 0.78, 0.35, 1.18), (0.3, 0.3, 0.3), mats["blanco"], raiz)
    if lava:
        rutas = [
            [(x - 0.44, -0.58, 3.0), (x - 0.3, -0.68, 2.78), (x - 0.48, -0.64, 2.55)],
            [(x + 0.1, -0.64, 3.14), (x + 0.22, -0.7, 2.96), (x + 0.1, -0.72, 2.76)],
            [(x - 0.42, -0.64, 1.98), (x - 0.12, -0.72, 1.7), (x - 0.34, -0.68, 1.36)],
            [(x + 0.44, -0.62, 1.35), (x + 0.62, -0.58, 1.05), (x + 0.48, -0.48, 0.72)],
        ]
        for indice, ruta in enumerate(rutas):
            curva_tubo(f"{nombre}_grieta_{indice}", ruta, 0.025, mats["lava"], raiz)
    return raiz


def poncho(nombre, x, padre, mats):
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=1.0, radius2=0.48, depth=0.72,
                                    location=(x, -0.4, 1.92), rotation=(math.radians(45), 0, math.radians(45)))
    prenda = bpy.context.object
    prenda.name = nombre
    prenda.scale = (1.12, 0.28, 1.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    prenda.data.materials.append(mats["poncho"])
    prenda.parent = padre
    for nivel, color in enumerate((mats["amarillo"], mats["turquesa"], mats["rojo"])):
        curva_tubo(f"{nombre}_franja_{nivel}",
                   [(x - 0.82 + nivel * 0.09, -0.69, 2.03 - nivel * 0.16),
                    (x, -0.77, 1.64 - nivel * 0.12),
                    (x + 0.82 - nivel * 0.09, -0.69, 2.03 - nivel * 0.16)],
                   0.035, color, padre)


def escenario(mats):
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 1, 0.12))
    suelo = bpy.context.object
    suelo.name = "Suelo"
    suelo.data.materials.append(mats["suelo"])
    mundo = bpy.context.scene.world or bpy.data.worlds.new("Mundo")
    bpy.context.scene.world = mundo
    mundo.use_nodes = True
    fondo = mundo.node_tree.nodes.get("Background")
    fondo.inputs["Color"].default_value = (0.006, 0.005, 0.025, 1)
    fondo.inputs["Strength"].default_value = 0.18
    luces = [
        ("Principal", "AREA", (0, -7, 8), (1.0, 0.42, 0.2), 1700, 8),
        ("Borde", "AREA", (7, 1, 6), (0.08, 0.35, 1.0), 1300, 7),
        ("Relleno", "AREA", (-7, -1, 4), (0.4, 0.18, 1.0), 900, 6),
    ]
    for nombre, tipo, posicion, color, energia, tamano in luces:
        datos = bpy.data.lights.new(nombre, tipo)
        datos.energy = energia
        datos.color = color
        datos.shape = "DISK"
        datos.size = tamano
        objeto = bpy.data.objects.new(nombre, datos)
        bpy.context.collection.objects.link(objeto)
        objeto.location = posicion
        apuntar(objeto, (0, 0, 1.8))
    bpy.ops.object.camera_add(location=(0, -18.5, 5.1))
    camara = bpy.context.object
    camara.name = "Camara_Principal"
    camara.data.lens = 52
    apuntar(camara, (0, 0, 1.9))
    bpy.context.scene.camera = camara


def apuntar(objeto, objetivo):
    direccion = Vector(objetivo) - objeto.location
    objeto.rotation_euler = direccion.to_track_quat("-Z", "Y").to_euler()


def configurar_render():
    escena = bpy.context.scene
    escena.render.engine = "BLENDER_EEVEE_NEXT"
    escena.render.resolution_x = 1600
    escena.render.resolution_y = 900
    escena.render.resolution_percentage = 100
    escena.render.image_settings.file_format = "PNG"
    escena.render.filepath = "//personajes_render.png"
    escena.render.film_transparent = False
    escena.view_settings.look = "AgX - Medium High Contrast"


def crear_escena():
    limpiar_escena()
    mats = {
        "marron": material("Marron", (0.48, 0.16, 0.045)),
        "marron_claro": material("MarronClaro", (0.58, 0.28, 0.1)),
        "negro": material("NegroPelaje", (0.018, 0.014, 0.018), rugosidad=0.8),
        "gris": material("GrisOscuro", (0.055, 0.05, 0.055), rugosidad=0.75),
        "blanco": material("Blanco", (0.96, 0.94, 0.9)),
        "crema": material("Crema", (0.9, 0.72, 0.5)),
        "ojo": material("Ojos", (0.008, 0.004, 0.002), rugosidad=0.1),
        "nariz": material("Nariz", (0.25, 0.07, 0.055), rugosidad=0.35),
        "oreja": material("InteriorOreja", (0.58, 0.18, 0.16)),
        "poncho": material("Poncho", (0.55, 0.055, 0.035), rugosidad=0.9),
        "amarillo": material("Amarillo", (0.95, 0.55, 0.03)),
        "turquesa": material("Turquesa", (0.02, 0.55, 0.58)),
        "rojo": material("Rojo", (0.8, 0.025, 0.02)),
        "lava": material("Lava", (1.0, 0.08, 0.0), emision=(1.0, 0.035, 0.0), fuerza=14),
        "suelo": material("Suelo", (0.045, 0.025, 0.08), rugosidad=0.72),
    }
    cobaya("Cuy_Tricolor", -5.2, 0.78, mats["marron"], mats,
           mancha=(-0.22, 0.14, -18, mats["blanco"]), pose=(False, False))
    cobaya("Cuy_Negro", -3.25, 1.05, mats["negro"], mats, pose=(True, False))
    cobaya("Cuy_Blanco", -1.25, 0.72, mats["blanco"], mats, pose=(False, True))
    conejo("Conejo_Cafe", 0.85, mats["marron_claro"], mats)
    cuy_poncho = cobaya("Cuy_Poncho", 3.2, 0.88, mats["marron"], mats,
                        mancha=(0.08, 0.2, 8, mats["blanco"]), pose=(True, True))
    poncho("Poncho_Andino", 3.2, cuy_poncho, mats)
    conejo("Conejo_Lava", 5.55, mats["gris"], mats, lava=True)
    escenario(mats)
    configurar_render()
    bpy.context.scene["instruccion"] = "F12 para renderizar; resultado: personajes_render.png"


crear_escena()
