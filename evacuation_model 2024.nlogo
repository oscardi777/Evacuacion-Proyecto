patches-own [
  object               ; Define el tipo de objeto en el patche (puede ser "wall", "obstacle", etc.)
  energy               ; Energía del patche, para esparcir las distancias entre patches hacia la puerta de evacuacion
  isJumpable           ; Indica si el patche es "saltable" o no, en caso de que sea un obstáculo
  outside              ; Marca si el patche está fuera del edificio o área de interés
]

turtles-own [
  myteammateID         ; Identificador del compañero de equipo, para determinar si necesita asistencia en caso de discapacidad
  category             ; Categoría a la que pertenece la tortuga, útil para clasificaciones específicas
  speed                ; Velocidad inicial de la tortuga
  current-speed        ; Velocidad actual de la tortuga, que puede cambiar según condiciones
  travelled-distance   ; Distancia total recorrida por la tortuga durante la evacuación
  canJumpOverObstacles ; Indica si la tortuga puede saltar obstáculos
  willDie              ; Marca si la tortuga está destinada a "morir" durante la simulación
  isPanicked           ; Indica si la tortuga está en estado de pánico

  first-criterion      ; Primer criterio de decisión, basado en las condiciones de evacuación
  second-criterion     ; Segundo criterio de decisión, complementario al primero
]

globals [
  evacuation-distances          ; Lista de distancias de evacuación para todos los agentes
  average-evacuation-distance   ; Distancia promedio de evacuación
  total-evacuation-distance     ; Distancia total recorrida por todos los agentes
  evacuation-durations          ; Lista de tiempos de evacuación para todos los agentes
  average-evacuation-duration   ; Tiempo promedio de evacuación

  halls-surface                 ; Superficie del perímetro de los pasillos, útil para cálculos de densidad y flujo
]

to setup
  __clear-all-and-reset-ticks  ; Limpia la simulación y reinicia el contador de ticks

  set evacuation-distances [] ; Inicializa la lista de distancias de evacuación como vacía
  set evacuation-durations [] ; Inicializa la lista de tiempos de evacuación como vacía

  setup-patches               ; Configura los patches (por ejemplo, paredes, obstáculos, etc.)
  setup-turtles               ; Configura las tortugas (personas) en la simulación

end

to setup-turtles
  ; Asigna los maestros a sus lugares designados
  let free-teacher-seat patches with [pcolor = teacher-seat-color and count turtles-here = 0] ; Obtiene una lista de patches donde los maestros pueden sentarse
  let all-possible-teachers count patches with [pcolor = teacher-seat-color] ; Cuenta todos los posibles asientos para maestros

  ; Crea las tortugas que representan a los maestros
  create-turtles all-possible-teachers [
    ; Asigna un asiento al azar a cada maestro
    let assigned-seat one-of free-teacher-seat
    setxy [pxcor] of assigned-seat [pycor] of assigned-seat ; Ubica al maestro en el asiento asignado
    set free-teacher-seat free-teacher-seat with [self != assigned-seat] ; Elimina ese asiento de la lista de asientos disponibles

    set category "teacher"    ; Categoría de la tortuga como "maestro"
    set shape "person"        ; Forma de la tortuga como una persona
    set size 2                ; Tamaño de la tortuga
    set color white           ; Color blanco para identificar maestros
    set speed 1.2             ; Velocidad del maestro
    set myteammateID -1       ; Sin compañero asignado
    set willDie false         ; No muere durante la simulación
    set isPanicked false      ; No entra en pánico
  ]

  ; Obtiene una lista de todos los asientos disponibles para estudiantes
  let free-seat-list patches with [pcolor = blue and count turtles-here = 0]

  ; Crea tortugas que representan a los estudiantes
  create-turtles number-of-children [
    ; Asigna un asiento al azar a cada estudiante
    let assigned-seat one-of free-seat-list
    setxy [pxcor] of assigned-seat [pycor] of assigned-seat ; Ubica al estudiante en el asiento asignado
    set free-seat-list free-seat-list with [self != assigned-seat] ; Elimina ese asiento de la lista de asientos disponibles

    set category "children"   ; Categoría inicial como "niño"
    set shape "person"        ; Forma de la tortuga como una persona
    set size 2                ; Tamaño de la tortuga
    set color yellow          ; Color amarillo para identificar adolescentes
    set speed 1.02            ; Velocidad inicial del adolescente
    set myteammateID -1       ; Sin compañero asignado
    set willDie false         ; No muere durante la simulación
    set isPanicked false      ; No entra en pánico
  ]

  ; Ajusta un porcentaje de estudiantes como participantes en cursos de evacuación
  let no-of-children floor (number-of-children * %-children-evacuation-courses / 100)
  ask n-of no-of-children turtles with [category = "children"] [
    set category "teenager"   ; Cambia la categoría a "teenager" para catalogar a los estudiantes sin cursos de evacuacion realizados
    set color green           ; Color verde para distinguirlos
    set speed (1.02 + random-float 0.1) ; Velocidad ligeramente aumentada
  ]

  ; Ajusta un porcentaje de estudiantes como personas con discapacidades
  let no-of-pers-with-disabilities floor ((number-of-children * %-children-with-disabilities) / 100)
  ask n-of no-of-pers-with-disabilities turtles with [category = "children"] [
    set category "pers-with-disabilities" ; Cambia la categoría a "personas con discapacidades"
    set color red                        ; Color rojo para identificarlos
    set speed 0.42                       ; Velocidad reducida
  ]

  ; Asigna compañeros a las personas con discapacidades
  ask n-of no-of-pers-with-disabilities turtles with [category = "pers-with-disabilities"] [
    let myDisabledId who                 ; Obtiene el identificador de la tortuga con discapacidad
    ask other turtles in-radius 1 [
      if (category != "pers-with-disabilities") [ ; Encuentra tortugas cercanas que no tengan discapacidades
        set myteammateID myDisabledId   ; Asigna el ID de la persona con discapacidad como compañero
      ]
    ]
  ]

end


to setup-patches
  ; Configura los patches que representan el espacio físico del modelo.

  resize-world -63 0 -35 35
  ; Define los límites del mundo en NetLogo:
  ; El eje x va de -63 a 0, y el eje y de -35 a 35.

  ask patches [
    ; Configura cada sección del espacio físico modelado.
    setup-floor                 ; Define los patches como el piso general del edificio.
    main-hall                  ; Configura el pasillo principal.
    classroom-1-left           ; Configura el aula 1 en el lado izquierdo.
    classroom-2-left           ; Configura el aula 2 en el lado izquierdo.
    classroom-3-left           ; Configura el aula 3 en el lado izquierdo.
    classroom-1-right          ; Configura el aula 1 en el lado derecho.
    classroom-2-right          ; Configura el aula 2 en el lado derecho.
    classroom-3-right          ; Configura el aula 3 en el lado derecho.

    ; Configura los escritorios dentro de cada aula.
    desks-classroom-1-left     ; Escritorios del aula 1 izquierda.
    desks-classroom-2-left     ; Escritorios del aula 2 izquierda.
    desks-classroom-3-left     ; Escritorios del aula 3 izquierda.
    desks-classroom-1-right    ; Escritorios del aula 1 derecha.
    desks-classroom-2-right    ; Escritorios del aula 2 derecha.
    desks-classroom-3-right    ; Escritorios del aula 3 derecha.

    ; Configura las paredes, escaleras y puertas principales del edificio.
    main-wall                  ; Define las paredes principales del edificio.
    second-floor-stairs        ; Configura las escaleras al segundo piso.
    first-floor-stairs         ; Configura las escaleras al primer piso.
    second-floor-door-to-stairs; Configura la puerta de las escaleras en el segundo piso.
    first-floor-door-to-stairs ; Configura la puerta de las escaleras en el primer piso.

    ; Configura las salidas de emergencia.
    setup-backdoor-exit-medium ; Configura la salida trasera de tamaño medio.
    setup-exit-stairs          ; Configura las salidas asociadas a las escaleras.
    setup-main-upper-exit      ; Configura la salida principal en el nivel superior.
    setup-main-down-exit       ; Configura la salida principal en el nivel inferior.

    ; Configura las puertas de las aulas.
    classroom-doors            ; Configura las puertas de acceso a cada aula.

    ; Configura el área externa del edificio.
    setup-outside              ; Define los patches que representan el área exterior.
  ]

  setup-energy
  ; Configura la energía de cada patch, que se utiliza para determinar la direccion de movimiento por los agentes para evacuar eficientemente

  ask patches [
    setup-obstacles
    ; Configura los obstáculos que afectan el movimiento de los agentes en el modelo.
  ]
end



to setup-floor
  set pcolor 129             ; Color del piso
  set object "floor"         ; Objeto etiquetado como "piso"
  set energy 1000            ; Energía inicial para el piso
  set outside false          ; Indica que no es un patche exterior
end

to main-hall
  ; Configuración de los muros en el pasillo principal

  if (pxcor = -35 and (pycor >= 10 and pycor <= 15)) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 18 metros (6 patches de 3 m²)

  if (pxcor = -29 and (pycor >= 10 and pycor <= 15)) [
    set pcolor black
    set object "wall"
  ] ; Otro muro vertical de 18 metros (6 patches)

  if (pycor = -31 and (pxcor >= -42 and pxcor <= -22)) [
    set pcolor black
    set object "wall"
  ] ; Muro horizontal de 60 metros (20 patches)

  if (pycor = 16 and ((pxcor >= -37 and pxcor <= -35) or (pxcor >= -29 and pxcor <= -22))) [
    set pcolor black
    set object "wall"
  ] ; Dos segmentos de muro horizontal de 6 metros y 21 metros respectivamente

  if ((pycor > -32 and pycor <= 31) and pxcor = -42) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 189 metros (63 patches)

  if ((pycor > -32 and pycor <= 9) and pxcor = -35) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 123 metros (41 patches)

  if ((pycor > -17 and pycor <= 9) and pxcor = -29) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 78 metros (26 patches)

  if ((pycor > -32 and pycor <= 28) and pxcor = -22) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 180 metros (60 patches)

end
to classroom-doors
  ; Configura las puertas intermedias en las aulas
  if ( (pycor > 9 and pycor <= 11) and pxcor = -42 ) [
    set pcolor turquoise
    set object "intermediate-door"
  ] ; Puerta de 6 metros (2 patches)

  if ( (pycor > 6 and pycor <= 8) and pxcor = -42 ) [
    set pcolor turquoise
    set object "intermediate-door"
  ] ; Puerta de 6 metros (2 patches)

  if ( (pycor > -14 and pycor <= -12) and pxcor = -42 ) [
    set pcolor turquoise
    set object "intermediate-door"
  ] ; Puerta de 6 metros (2 patches)

  if ( (pycor > 9 and pycor <= 11) and pxcor = -22 ) [
    set pcolor turquoise
    set object "intermediate-door"
  ] ; Puerta de 6 metros (2 patches)

  if ( (pycor > 6 and pycor <= 8) and pxcor = -22 ) [
    set pcolor turquoise
    set object "intermediate-door"
  ] ; Puerta de 6 metros (2 patches)

  if ( (pycor > -14 and pycor <= -12) and pxcor = -22 ) [
    set pcolor turquoise
    set object "intermediate-door"
  ] ; Puerta de 6 metros (2 patches)
end

to classroom-1-left
  ; Configura las paredes del aula 1 izquierda
  if ( (pycor > 7 and pycor <= 28) and pxcor = -56 ) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 63 metros (21 patches)

  if ( (pycor = 9) and (pxcor >= -56 and pxcor <= -42) ) [
    set pcolor black
    set object "wall"
  ] ; Muro horizontal de 42 metros (14 patches)

  if ( (pycor = 29) and (pxcor >= -56 and pxcor < -41) ) [
    set pcolor black
    set object "wall"
  ] ; Muro horizontal de 45 metros (15 patches)

  if ( pycor = 28 and pxcor > -51 and pxcor < -46 ) [
    set pcolor gray
    set object "wall"
  ] ; Muro de detalle de 15 metros (5 patches)
end

to classroom-2-left
  ; Configura las paredes del aula 2 izquierda
  if ( (pycor > -12 and pycor <= 7) and pxcor = -56 ) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 57 metros (19 patches)

  if ( (pycor = -11) and (pxcor >= -56 and pxcor <= -42) ) [
    set pcolor black
    set object "wall"
  ] ; Muro horizontal de 42 metros (14 patches)

  if ( pycor = 8 and pxcor > -51 and pxcor < -46 ) [
    set pcolor gray
    set object "wall"
  ] ; Muro de detalle de 15 metros (5 patches)
end

to classroom-3-left
  ; Configura las paredes del aula 3 izquierda
  if ( (pycor > -31 and pycor <= -12) and pxcor = -56 ) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 57 metros (19 patches)

  if ( (pycor = -31) and (pxcor >= -56 and pxcor <= -42) ) [
    set pcolor black
    set object "wall"
  ] ; Muro horizontal de 42 metros (14 patches)

  if ( pycor = -12 and pxcor > -51 and pxcor < -46 ) [
    set pcolor gray
    set object "wall"
  ] ; Muro de detalle de 15 metros (5 patches)
end

to classroom-1-right
  ; Configura las paredes del aula 1 derecha
  if ( (pycor > 7 and pycor <= 28) and pxcor = -8 ) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 63 metros (21 patches)

  if ( (pycor = 9) and (pxcor >= -21 and pxcor <= -8) ) [
    set pcolor black
    set object "wall"
  ] ; Muro horizontal de 39 metros (13 patches)

  if ( (pycor = 29) and (pxcor >= -22 and pxcor <= -8) ) [
    set pcolor black
    set object "wall"
  ] ; Muro horizontal de 42 metros (14 patches)

  if ( pycor = 28 and pxcor > -17 and pxcor < -12 ) [
    set pcolor gray
    set object "wall"
  ] ; Muro de detalle de 15 metros (5 patches)
end

to classroom-2-right
  ; Configura las paredes del aula 2 derecha
  if ( (pycor > -12 and pycor <= 7) and pxcor = -8 ) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 57 metros (19 patches)

  if ( (pycor = -11) and (pxcor >= -22 and pxcor <= -8) ) [
    set pcolor black
    set object "wall"
  ] ; Muro horizontal de 42 metros (14 patches)

  if ( pycor = 8 and pxcor > -17 and pxcor < -12 ) [
    set pcolor gray
    set object "wall"
  ] ; Muro de detalle de 15 metros (5 patches)
end

to classroom-3-right
  ; Configura las paredes del aula 3 derecha
  if ( (pycor > -31 and pycor <= -12) and pxcor = -8 ) [
    set pcolor black
    set object "wall"
  ] ; Muro vertical de 57 metros (19 patches)

  if ( (pycor = -31) and (pxcor >= -21 and pxcor <= -8) ) [
    set pcolor black
    set object "wall"
  ] ; Muro horizontal de 39 metros (13 patches)

  if ( pycor = -12 and pxcor > -17 and pxcor < -12 ) [
    set pcolor gray
    set object "wall"
  ] ; Muro de detalle de 15 metros (5 patches)
end

to desks-classroom-1-left
  ; Aula 1 izquierda: escritorios, pasillos y silla del profesor.
  ; Dimensiones reales:
  ; - Escritorios: Ancho = 6 patches (18 m), Alto = 5 patches (15 m).
  ; - Pasillo: Ancho = 6 patches (18 m), Alto = 5 patches (15 m).
  if (
    (pycor >= 15 and pycor < 25 and pycor mod 2 = 0) and ((pxcor = -55 or pxcor = -54) or (pxcor = -50 or pxcor = -49) or (pxcor = -45 or pxcor = -44)) or
    (pycor = 27 and (pxcor = -55 or pxcor = -54))
    )
  [
    set pcolor brown
    set object "obstacle" ; Representa escritorios
  ]
  if ( (pycor mod 2 = 1 and pycor >= 15 and pycor < 25) and ( (pxcor = -55 or pxcor = -54) or (pxcor = -50 or pxcor = -49) or (pxcor = -45 or pxcor = -44) ) ) [ set pcolor blue ]
  if (pycor = 28 and pxcor = -55) [ set pcolor teacher-seat-color ] ; Silla del profesor
end

to desks-classroom-2-left
  ; Aula 2 izquierda: escritorios, pasillos y silla del profesor.
  ; Dimensiones reales:
  ; - Escritorios: Ancho = 6 patches (18 m), Alto = 5 patches (15 m).
  ; - Pasillo: Ancho = 6 patches (18 m), Alto = 5 patches (15 m).
  if (
    (pycor >= -6 and pycor < 4 and pycor mod 2 = 1) and ( (pxcor = -55 or pxcor = -54) or (pxcor = -50 or pxcor = -49) or (pxcor = -45 or pxcor = -44)) or
    (pycor = 4 and (pxcor = -50 or pxcor = -49))
    )
   [
    set pcolor brown
    set object "obstacle" ; Representa escritorios
   ]
  if ( (pycor mod 2 = 0 and pycor >= -6 and pycor < 4) and ( (pxcor = -55 or pxcor = -54) or (pxcor = -50 or pxcor = -49) or (pxcor = -45 or pxcor = -44) ) ) [ set pcolor blue ]
  if (pycor = 5 and pxcor = -49) [set pcolor teacher-seat-color] ; Silla del profesor
end

to desks-classroom-3-left
  ; Aula 3 izquierda: escritorios, pasillos y silla del profesor.
  ; Dimensiones reales:
  ; - Escritorios: Ancho = 6 patches (18 m), Alto = 5 patches (15 m).
  ; - Pasillo: Ancho = 6 patches (18 m), Alto = 5 patches (15 m).
  if (
    (pycor >= -26 and pycor < -16 and pycor mod 2 = 1) and ((pxcor = -55 or pxcor = -54) or (pxcor = -50 or pxcor = -49) or (pxcor = -45 or pxcor = -44)) or
    (pycor = -16 and (pxcor = -50 or pxcor = -49))
    )
  [
    set pcolor brown
    set object "obstacle" ; Representa escritorios
  ]
  if  ( (pycor mod 2 = 0 and pycor >= -26 and pycor < -16) and ((pxcor = -55 or pxcor = -54) or (pxcor = -50 or pxcor = -49) or (pxcor = -45 or pxcor = -44)) ) [ set pcolor blue ]
  if (pycor = -15 and pxcor = -49) [set pcolor teacher-seat-color] ; Silla del profesor
end

to desks-classroom-1-right
  ; Aula 1 derecha: escritorios, pasillos y silla del profesor.
  ; Dimensiones reales:
  ; - Escritorios: Ancho = 6 patches (18 m), Alto = 5 patches (15 m).
  if (
    (pycor >= 15 and pycor < 25 and pycor mod 2 = 0) and ((pxcor = -20 or pxcor = -19) or (pxcor = -15 or pxcor = -14) or (pxcor = -10 or pxcor = -9)) or
    (pycor = 27 and (pxcor = -10 or pxcor = -9))
   )
  [
    set pcolor brown
    set object "obstacle" ; Representa escritorios
  ]
  if ( (pycor mod 2 = 1 and pycor >= 15 and pycor < 25) and ((pxcor = -20 or pxcor = -19) or (pxcor = -15 or pxcor = -14) or (pxcor = -10 or pxcor = -9)) ) [ set pcolor blue ]
  if (pycor = 28 and pxcor = -9) [ set pcolor teacher-seat-color ] ; Silla del profesor
end

to desks-classroom-2-right
  ; Aula 2 derecha: escritorios, pasillos y silla del profesor.
  ; Dimensiones reales:
  ; - Escritorios: Ancho = 6 patches (18 m), Alto = 5 patches (15 m).
  if (
    (pycor >= -6 and pycor < 4 and pycor mod 2 = 1) and ((pxcor = -20 or pxcor = -19) or (pxcor = -15 or pxcor = -14) or (pxcor = -10 or pxcor = -9)) or
    (pycor = 4 and (pxcor = -15 or pxcor = -14))
    )
  [
    set pcolor brown
    set object "obstacle" ; Representa escritorios
  ]
  if ( (pycor mod 2 = 0 and pycor >= -6 and pycor < 4) and ((pxcor = -20 or pxcor = -19) or (pxcor = -15 or pxcor = -14) or (pxcor = -10 or pxcor = -9)) ) [ set pcolor blue ]
  if (pycor = 5 and pxcor = -15) [ set pcolor teacher-seat-color ] ; Silla del profesor
end

to desks-classroom-3-right
  ; Aula 3 derecha: escritorios, pasillos y silla del profesor.
  ; Dimensiones reales:
  ; - Escritorios: Ancho = 6 patches (18 m), Alto = 5 patches (15 m).
  if (
    (pycor >= -26 and pycor < -16 and pycor mod 2 = 1) and ((pxcor = -20 or pxcor = -19) or (pxcor = -15 or pxcor = -14) or (pxcor = -10 or pxcor = -9)) or
    (pycor = -16 and (pxcor = -15 or pxcor = -14))
    )
  [
    set pcolor brown
    set object "obstacle" ; Representa escritorios
  ]
  if ( (pycor mod 2 = 0 and pycor >= -26 and pycor < -16) and ((pxcor = -20 or pxcor = -19) or (pxcor = -15 or pxcor = -14) or (pxcor = -10 or pxcor = -9)) ) [ set pcolor blue ]
  if (pycor = -15 and pxcor = -15) [ set pcolor teacher-seat-color ] ; Silla del profesor
end


to main-wall
  ; Representa una pared principal con una puerta intermedia.

  if (pycor = 16 and (pxcor = -41 or pxcor = -40)) [
    set pcolor black           ; Se asigna el color negro para indicar un muro.
    set object "wall"          ; Se etiqueta como "wall".
  ]   ; => Esta pared tiene un ancho de 1 patch, equivalente a 1 m (en un espacio de 3 m²).

  if (pycor = 16 and (pxcor >= -39 and pxcor <= -37)) [
    set pcolor turquoise       ; Color turquesa indica una puerta.
    set object "intermediate-door"
  ]   ; => Esta puerta tiene un ancho de 1.5 patches, equivalente a 4.5 m.
end


to second-floor-stairs
  ; Representa las paredes y detalles de las escaleras del segundo piso.

  if ((pxcor = -39 and (pycor >= 21 and pycor <= 31))) [
    set pcolor black           ; Se asigna el color negro para indicar un muro.
    set object "wall"
  ]   ; => Pared lateral de las escaleras, con una longitud de 11 patches, equivalente a 33 m.

  if ((pycor >= 17 and pycor <= 30) and pxcor = -35) [
    set pcolor black
    set object "wall"
  ]   ; => Pared lateral opuesta, con una longitud de 14 patches, equivalente a 42 m.

  if ((pycor >= 21 and pycor <= 29 and pycor mod 2 = 0) and (pxcor = -41 or pxcor = -40)) [
    set object "wall"
    set pcolor gray            ; Pared en color gris, alternada.
  ]
  if ((pycor >= 21 and pycor <= 29 and pycor mod 2 = 1) and (pxcor = -41 or pxcor = -40)) [
    set pcolor 7               ; Pared en otro tono, alternada.
    set object "wall"
  ]   ; => Estas paredes alternadas cubren una altura de 9 patches, equivalente a 27 m.

  if ((pycor >= 21 and pycor <= 24 and pycor mod 2 = 0) and (pxcor >= -38 and pxcor <= -36)) [
    set pcolor gray            ; Otro muro con tono gris.
  ]
  if ((pycor >= 21 and pycor <= 24 and pycor mod 2 = 1) and (pxcor >= -38 and pxcor <= -36)) [
    set pcolor 7               ; Alternancia de tonos en esta pared.
  ]   ; => Este tramo alternado tiene una longitud de 3 patches (9 m).

  if ((pycor = 31 and pxcor >= -42 and pxcor <= -35)) [
    set pcolor black
    set object "wall"
  ]   ; => Muro superior, cubriendo 8 patches, equivalente a 24 m.
end


to first-floor-stairs
  ; Representa las paredes y detalles de las escaleras del primer piso.

  if (pycor = -16 and (pxcor >= -35 and pxcor <= -29)) [
    set pcolor black
    set object "wall"
  ]   ; => Pared horizontal de 7 patches, equivalente a 21 m.

  if (pxcor = -32 and (pycor <= -20 and pycor >= -31)) [
    set pcolor black
    set object "wall"
  ]   ; => Pared vertical de 12 patches, equivalente a 36 m.

  if ((pycor <= -16 and pycor >= -26) and pxcor = -28) [
    set pcolor black
    set object "wall"
  ]   ; => Otro muro vertical, de 11 patches, equivalente a 33 m.

  if ((pycor <= -21 and pycor >= -29 and pycor mod 2 = 0) and (pxcor = -34 or pxcor = -33)) [
    set object "wall"
    set pcolor gray
  ]
  if ((pycor <= -21 and pycor >= -29 and pycor mod 2 = 1) and (pxcor = -34 or pxcor = -33)) [
    set pcolor 7
    set object "wall"
  ]   ; => Pared alternada en altura, cubriendo 9 patches (27 m).

  if ((pycor <= -21 and pycor >= -24 and pycor mod 2 = 0) and (pxcor >= -31 and pxcor <= -30)) [
    set pcolor gray
  ]
  if ((pycor <= -21 and pycor >= -24 and pycor mod 2 = 1) and (pxcor >= -31 and pxcor <= -30)) [
    set pcolor 7
  ]   ; => Este segmento alternado cubre una altura de 4 patches (12 m).

  if ((pycor = -31 and (pxcor >= -31 and pxcor <= -29))) [
    set pcolor black
    set object "wall"
  ]   ; => Muro inferior, con una longitud de 3 patches (9 m).
end


to second-floor-door-to-stairs
  ; Define la puerta de acceso a las escaleras en el segundo piso.

  if (pycor = 25 and (pxcor >= -38 and pxcor <= -36)) [
    set pcolor turquoise       ; Se asigna el color turquesa a la puerta.
    set object "intermediate-door"  ; Etiqueta la puerta como "intermediate-door".
  ]   ; => La puerta tiene un ancho de 3 patches, equivalente a 9 m (cada patch representa 3 m²).
end


to first-floor-door-to-stairs
  ; Define la puerta de acceso a las escaleras en el primer piso.

  if (pxcor = -32 and (pycor >= -19 and pycor <= -17)) [
    set pcolor turquoise       ; Se asigna el color turquesa a la puerta.
    set object "intermediate-door"  ; Etiqueta la puerta como "intermediate-door".
  ]   ; => La puerta tiene un alto de 3 patches, equivalente a 9 m.
end


to setup-exit-stairs
  ; Configura la salida de las escaleras traseras.

  let exit-start-pycor 28
  let full-door-width 3      ; El ancho total de la puerta es de 3 patches (9 m).

  if ( (pycor >= exit-start-pycor and pycor < exit-start-pycor + full-door-width) and pxcor = -39 ) [
    let open-door-width 0

    ; Dependiendo del estado de la salida, se ajusta el ancho de la puerta abierta.
    (ifelse
      backdoor-exit = "closed" [set open-door-width 0]
      backdoor-exit = "partially-opened" [set open-door-width full-door-width - 1]
      backdoor-exit = "opened" [ set open-door-width full-door-width ]
      [  ])

    ifelse pycor < exit-start-pycor + open-door-width [
      set pcolor green         ; La puerta abierta se muestra en verde.
      set object "door"
    ]
    [
      set pcolor orange        ; Si está cerrada o parcialmente abierta, se muestra en naranja.
    ]
  ]   ; => La puerta de salida tiene un ancho de 3 patches (9 m) y una altura de 1 patch (3 m).
end

to setup-main-upper-exit
  ; Configura la salida superior principal.

  let exit-start-pxcor -27
  let full-door-width 3      ; El ancho total de la puerta es de 3 patches (9 m).

  if ( (pxcor >= exit-start-pxcor and pxcor < exit-start-pxcor + full-door-width) and pycor = 16 ) [
    let open-door-width 0

    ; Dependiendo del estado de la salida, se ajusta el ancho de la puerta abierta.
    (ifelse
      cafe-exit = "closed" [set open-door-width 0]
      cafe-exit = "partially-opened" [set open-door-width full-door-width - 1]
      cafe-exit = "opened" [set open-door-width full-door-width]
      [ ]
    )

    ifelse pxcor < exit-start-pxcor + open-door-width [
      set pcolor green         ; La puerta abierta se muestra en verde.
      set object "door"
    ]
    [
      set pcolor orange        ; Si está cerrada o parcialmente abierta, se muestra en naranja.
    ]
  ]   ; => La puerta tiene un alto de 1 patch (3 m) y un ancho de 3 patches (9 m).
end


to setup-main-down-exit
  ; Configura la salida inferior principal.

  let exit-start-pxcor -27
  let full-door-width 3      ; El ancho total de la puerta es de 3 patches (9 m).

  if ( (pxcor >= exit-start-pxcor and pxcor < exit-start-pxcor + full-door-width) and pycor = -31 ) [
    let open-door-width 0

    ; Dependiendo del estado de la salida, se ajusta el ancho de la puerta abierta.
    (ifelse
      main-exit = "closed" [set open-door-width 0]
      main-exit = "partially-opened" [set open-door-width full-door-width - 1]
      main-exit = "opened" [set open-door-width full-door-width]
      [ ]
    )

    ifelse pxcor < exit-start-pxcor + open-door-width [
      set pcolor green         ; La puerta abierta se muestra en verde.
      set object "door"
    ]
    [
      set pcolor orange        ; Si está cerrada o parcialmente abierta, se muestra en naranja.
    ]
  ]   ; => La puerta tiene un alto de 1 patch (3 m) y un ancho de 3 patches (9 m).
end


to setup-backdoor-exit-medium
  ; Configura la salida trasera media.

  let exit-start-pycor -2
  let full-door-width 3      ; El ancho total de la puerta es de 3 patches (9 m).

  if ( (pycor >= exit-start-pycor and pycor < exit-start-pycor + full-door-width) and pxcor = -29 ) [
    let open-door-width 0

    ; Dependiendo del estado de la salida, se ajusta el ancho de la puerta abierta.
    (ifelse
      middle-exit = "closed" [set open-door-width 0]
      middle-exit = "partially-opened" [ set open-door-width full-door-width - 1 ]
      middle-exit = "opened" [ set open-door-width full-door-width ]
      [  ])

    ifelse pycor < exit-start-pycor + open-door-width [
      set pcolor green         ; La puerta abierta se muestra en verde.
      set object "door"
    ]
    [
      set pcolor orange        ; Si está cerrada o parcialmente abierta, se muestra en naranja.
    ]
  ]   ; => La puerta tiene un alto de 1 patch (3 m) y un ancho de 3 patches (9 m).
end


to setup-energy
  ; Configura la energía de las puertas en el sistema.

  ask patches with [object = "door"]   ; Selecciona todos los patches que tienen el objeto "door".
  [
    compute-energy 0 self              ; Llama a la función compute-energy con un nivel de energía inicial de 0 para cada puerta.
  ]
end


to compute-energy [energy-level floor-partch]
  ; Calcula la energía de un patche basado en su tipo de objeto (puerta, piso, etc.).

  (ifelse
    object = "door" [set energy energy-level]  ; Si el objeto es una puerta, se asigna el nivel de energía recibido.
    object = "floor" [set energy energy-level + 1]  ; Si el objeto es un piso, aumenta la energía en 1.
    object = "intermediate-door" [set energy energy-level + 1]  ; Si el objeto es una puerta intermedia, también aumenta la energía en 1.
    [ ] )

  set plabel energy  ; Muestra el valor de la energía en la etiqueta del patche.
  let patch-energy energy  ; Guarda el valor de la energía para usarlo en los cálculos siguientes.

  ; Actualiza la energía de los patches vecinos con objetos "floor" o "intermediate-door" y energía mayor que la del patche actual + 1.
  ask neighbors with [object = "floor" and outside = false and energy > [energy] of myself + 1]
  [
    compute-energy patch-energy self
  ]

  ask neighbors with [object = "intermediate-door" and outside = false and energy > [energy] of myself + 1]
  [
    compute-energy patch-energy self
  ]

  ask neighbors with [object = "floor" and outside = false and energy > [energy] of myself + 1]
  [
    compute-energy patch-energy self
  ]

end


to setup-obstacles
  ; Configura los obstáculos en el mapa.

  if (
    ((pxcor >= -42 and pxcor <= -35 ) and (pycor >= -31 and pycor <= 16 )) or
    ((pxcor >= -29 and pxcor <= -22 ) and (pycor >= -16 and pycor <= 16 )) or
    ((pxcor >= -27 and pxcor <= -22 ) and (pycor >= -31 and pycor <= -16 ))
  )
  [
    set outside false  ; Marca el patche como parte del interior (no es un exterior).
    let canPutObstacle true  ; Inicializa la variable que decide si se puede poner un obstáculo.

    ; Si el objeto es "floor" y se genera un obstáculo aleatorio con una probabilidad específica:
    if (object = "floor" and (random-float 100 < %-probability-of-obstacles)) [

      ; Verifica si cerca del patche hay una puerta intermedia o un patche sin energía.
      if ( (any? (patches in-radius 2 with [object = "intermediate-door"])) or (any? (patches in-radius 2 with [energy = 0])) )
        [set canPutObstacle false]  ; Si hay obstáculos cercanos, no permite agregar otro.

      if (canPutObstacle = true)[
        set object "obstacle"      ; Establece el objeto como "obstacle".
        set pcolor obstacles-color  ; Asigna un color específico a los obstáculos.

        ; Determina si el obstáculo es saltable o no (60% de probabilidad de ser saltable).
        ifelse (random 100 < 60)
        [set isJumpable true]  ; Si es saltable, marca el obstáculo como saltable.
        [set isJumpable false]  ; Si no es saltable, marca el obstáculo como no saltable.
      ]
    ]
  ]
end


to setup-outside
  ; Configura las áreas exteriores en el mapa.

  if (
    ((pxcor >= min-pxcor and pxcor <= max-pxcor ) and (pycor >= min-pycor and pycor <= -32 )) or
    ((pxcor >= min-pxcor and pxcor <= max-pxcor ) and (pycor >= 32 and pycor <= min-pycor )) or
    ((pxcor >= min-pxcor and pxcor <= -43 ) and (pycor >= 30 and pycor <= 31 )) or
    ((pxcor >= min-pxcor and pxcor <= -57 ) and (pycor >= -31 and pycor <= 29 )) or
    ((pxcor >= -34 and pxcor <= -30 ) and (pycor >= -15 and pycor <= 31 )) or
    ((pxcor >= -29 and pxcor <= -23 ) and (pycor >= 17 and pycor <= 31 )) or
    ((pxcor >= -22 and pxcor <= max-pxcor ) and (pycor >= 30 and pycor <= 31 )) or
    ((pxcor >= -9 and pxcor <= max-pxcor ) and (pycor >= -31 and pycor <= 29 ))
  )
  [
    set outside true  ; Marca el patche como parte del exterior.
  ]

end


to teleport
  ; Función para teletransportar los estudiantes de las escaleras del segundo piso, a las escaleras del primer piso

  ask turtles with [pycor = 26 and (pxcor >= -38 and pxcor <= -36)]  ; Selecciona las tortugas que están en el área específica (punto en el eje Y=26 y X entre -38 y -36). (Puerta del segundo piso)
  [
    setxy -31 (-19 + random 3)  ; Mueve la tortuga seleccionada a la nueva posición en el eje X=-31 y en el eje Y entre -19 y -21 (aleatoriamente) (Puerta de escaleras en el primer piso).
  ]
end


to go
  ; Función principal que controla el comportamiento de las tortugas durante la simulación.

  tick  ; Incrementa el contador de ticks (pasos del tiempo).

  if not any? turtles [stop]  ; Si no hay tortugas, detiene la simulación.

  ask turtles
  [
    if (ticks = 998)[  ; Si el número de ticks llega a 998, marca la tortuga como "willDie" (morirá).
      set willDie true
    ]
    if (ticks = 1000)  ; Si el número de ticks llega a 1000, la tortuga muere.
    [
      die
    ]

    set current-speed speed  ; Asigna la velocidad actual de la tortuga.

    ; Si la tortuga está en una puerta, registra la distancia y la duración de la evacuación.
    ifelse [object] of patch-at 0 0 = "door"
    [
      set evacuation-distances fput travelled-distance evacuation-distances
      set evacuation-durations fput ticks evacuation-durations

      set average-evacuation-distance mean evacuation-distances  ; Calcula la distancia promedio de evacuación.
      set total-evacuation-distance sum evacuation-distances  ; Calcula la distancia total de evacuación.
      set average-evacuation-duration mean evacuation-durations  ; Calcula la duración promedio de evacuación.

      die  ; La tortuga muere una vez que ha llegado a la puerta.
    ]
    [

      ; Si la tortuga puede ayudar a un compañero con discapacidad, se mueve hacia él.
      ifelse (is-turtle? turtle myteammateID)
      [
        ; Establece el patche al que se debe mover la tortuga que ayuda, basándose en la ubicación de la tortuga con discapacidad.
        let patchToMove 0
        let speedOfTurtleWhoIsHelping 0

        ; Obtiene las coordenadas del patche al que se moverá la tortuga con discapacidad.
        ; Establece la velocidad de la tortuga que ayuda como la velocidad de la tortuga con discapacidad.
        ask turtle myteammateID [
          set patchToMove patch-here
          set speedOfTurtleWhoIsHelping current-speed
        ]

        ; Hace que la tortuga que ayuda siga a la tortuga con discapacidad.
        face patchToMove
        set current-speed speedOfTurtleWhoIsHelping
        fd current-speed  ; La tortuga avanza con la velocidad de la tortuga con discapacidad.
        set travelled-distance travelled-distance + current-speed  ; Actualiza la distancia recorrida.
      ]
      [

        ; Si no hay compañero con discapacidad, busca patches disponibles para moverse.
        let possiblePatches sort-on [energy] neighbors with [(object = "floor" or object = "door" or object = "intermediate-door" or (object = "obstacle" and isJumpable != false) ) and not any? turtles-on self]
        if not empty? possiblePatches  ; Si hay patches disponibles, elige el primero.

        [
          if (travelled-distance > 150)[  ; Si la tortuga ha recorrido más de 150 unidades, se marca como "panicked" (en pánico).
            set isPanicked true
          ]

          ; Verifica si un maestro está cerca.
          let isTeacherNear any? turtles-on neighbors

          ; Elige el próximo patch a mover, preferentemente el primero de los posibles.
          let nextPatch first possiblePatches
          let isTeacherAround neighbors with [object = "teacher"]

          face nextPatch  ; La tortuga se orienta hacia el próximo patch.

          ; Si el maestro está cerca y puede inspirar a los estudiantes, la tortuga se mueve de manera más rápida.
          ifelse (isTeacherNear and inspire-students)
          [
            ifelse (object = "obstacle")
            [fd ((1 + random-float 0.08) * current-speed / 2) ]  ; Si hay un obstáculo, se mueve más lento.
            [fd ((1 + random-float 0.08) * current-speed) ]  ; Si no hay obstáculo, se mueve normalmente.
          ][
            ifelse (object = "obstacle")
            [fd (current-speed / 2) ]  ; Si hay un obstáculo, se mueve más lento.
            [fd current-speed ]  ; Si no hay obstáculo, se mueve normalmente.
          ]

          ; Actualiza la distancia recorrida por la tortuga.
          set travelled-distance travelled-distance + current-speed
        ]

      ]

    ]
  ]
  teleport  ; Al final de cada ciclo de la simulación, se teletransporta a las tortugas que cumplen la condición (de la función).
end
@#$#@#$#@
GRAPHICS-WINDOW
230
33
764
625
-1
-1
8.22
1
10
1
1
1
0
0
0
1
-63
0
-35
35
0
0
1
ticks
30.0

BUTTON
12
14
79
47
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
113
16
176
49
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
12
109
210
142
%-children-evacuation-courses
%-children-evacuation-courses
0
100
0.0
1
1
%
HORIZONTAL

SLIDER
12
147
211
180
%-children-with-disabilities
%-children-with-disabilities
0
20
0.0
1
1
%
HORIZONTAL

CHOOSER
12
225
167
270
cafe-exit
cafe-exit
"closed" "partially-opened" "opened"
2

CHOOSER
12
278
167
323
middle-exit
middle-exit
"closed" "partially-opened" "opened"
2

CHOOSER
12
329
167
374
main-exit
main-exit
"closed" "partially-opened" "opened"
2

SLIDER
12
184
212
217
%-probability-of-obstacles
%-probability-of-obstacles
0
100
0.0
1
1
%
HORIZONTAL

INPUTBOX
17
479
172
539
obstacles-color
126.0
1
0
Color

INPUTBOX
17
546
172
606
teacher-seat-color
6.0
1
0
Color

SWITCH
17
438
179
471
inspire-students
inspire-students
0
1
-1000

SLIDER
12
68
192
101
number-of-children
number-of-children
0
180
180.0
1
1
NIL
HORIZONTAL

PLOT
805
28
1136
178
People on site
time
People
0.0
1000.0
0.0
180.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count turtles"

CHOOSER
16
381
168
426
backdoor-exit
backdoor-exit
"opened" "partially-opened" "closed"
0

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL
Codigo nuevo 87-100

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Scenariu 1 - B+C" repetitions="400" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="449"/>
    <metric>ticks</metric>
    <metric>count turtles with [willDie = true]</metric>
    <enumeratedValueSet variable="%-children-evacuation-courses">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-children">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-children-with-disabilities">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="main-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="office-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles-color">
      <value value="126"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inspire-students">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teacher-seat-color">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="backdoor-exit">
      <value value="&quot;partially-opened&quot;"/>
      <value value="&quot;closed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-probability-of-obstacles">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenariul 2 - A+B" repetitions="400" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="449"/>
    <metric>ticks</metric>
    <metric>count turtles with [willDie = true]</metric>
    <enumeratedValueSet variable="%-children-evacuation-courses">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-children">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-children-with-disabilities">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="main-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="office-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles-color">
      <value value="126"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inspire-students">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teacher-seat-color">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="backdoor-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-probability-of-obstacles">
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenariu 3 - A+B" repetitions="400" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="449"/>
    <metric>ticks</metric>
    <metric>count turtles with [willDie = true]</metric>
    <enumeratedValueSet variable="%-children-evacuation-courses">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-children">
      <value value="153"/>
      <value value="117"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-children-with-disabilities">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="main-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="office-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles-color">
      <value value="126"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inspire-students">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teacher-seat-color">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="backdoor-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-probability-of-obstacles">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="BaseScenario" repetitions="400" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="449"/>
    <metric>ticks</metric>
    <metric>count turtles with [willDie = true]</metric>
    <enumeratedValueSet variable="%-children-evacuation-courses">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-children">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-children-with-disabilities">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="main-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="office-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles-color">
      <value value="126"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inspire-students">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teacher-seat-color">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="backdoor-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-probability-of-obstacles">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenariul 1 - A" repetitions="400" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="449"/>
    <metric>ticks</metric>
    <metric>count turtles with [willDie = true]</metric>
    <enumeratedValueSet variable="%-children-evacuation-courses">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-children">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-children-with-disabilities">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="office-exit">
      <value value="&quot;partially-opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="main-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles-color">
      <value value="126"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inspire-students">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="teacher-seat-color">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="backdoor-exit">
      <value value="&quot;opened&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-probability-of-obstacles">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
