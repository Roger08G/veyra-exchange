# `EC-01` Depósitos y Retiradas

La cadena económica `EC-01` gestiona la entrada de tokens, el saldo disponible y la retirada de fondos.

## Objetivo

El objetivo de esta cadena es aceptar depósitos de los tokens permitidos, actualizar el saldo de cada cuenta y procesar retiradas solo cuando haya liquidez suficiente, garantizando que lo comprometido en préstamos o comisiones no se pueda retirar.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen tres actores:

- El usuario deposita **MockUSD** o **MockETH**, consulta su saldo y solicita retiradas de sus propios fondos disponibles.
- El contrato de cuentas de Veyra valida los tokens admitidos, actualiza los saldos y ejecuta las retiradas cuando corresponde.
- El administrador configura las dos direcciones autorizadas para la instancia y puede deshabilitar un activo solo cuando no respalde saldos, garantías, caja, ingresos ni obligaciones abiertas del mercado. Estos permisos no le conceden control sobre los saldos de usuarios.

## Variables y Estado Contable

Para cada usuario y cada token admitido, Veyra mantiene un saldo disponible que el usuario puede usar o retirar. Los saldos bloqueados por garantías u otras obligaciones, las participaciones del fondo de liquidez y las deudas de los prestatarios son estados asociados que `EC-01` no modifica.

**Reglas contables:** Los depósitos aumentan el saldo disponible del token correspondiente.

Las retiradas lo reducen siempre que haya liquidez suficiente.

Los tokens enviados directamente al contrato fuera del flujo previsto no aumentan automáticamente el saldo disponible de ningún usuario.

Las comisiones generadas por retiradas se separan del saldo disponible del usuario y se registran como ingreso del protocolo `EC-08`.

## Flujo Económico

### Flujo de Depósito

El titular autoriza a la dirección de custodia a transferir el token desde su cartera. Al depositar, se carga su cartera y se acreditan su disponible y el total disponible solo cuando el incremento de custodia coincide exactamente con el importe solicitado.

Los depósitos no generan comisiones ni crean deuda.

### Flujo de Retirada

El usuario solicita retirar una cantidad de un token admitido, Veyra comprueba que el saldo disponible es suficiente, que no estén bloqueados por garantías u obligaciones y calcula la comisión aplicable según el plan del usuario `EC-03`.

El bruto se descuenta del disponible y del total disponible. La custodia transfiere el neto a la cartera del mismo titular. El token que respalda la comisión permanece en custodia.

La comisión se contabiliza como ingreso del protocolo `EC-08`.

Las retiradas no afectan a deudas ni participaciones del fondo.

## Validaciones y Restricciones

### Validaciones de Depósitos

- El token debe estar autorizado en la lista blanca.
- La cantidad debe superar estrictamente el mínimo por token que figura en la [configuración del MVP](../economic.md).
- Comprobar el éxito de la transferencia desde la cartera del titular y medir el incremento del saldo ERC-20 de la custodia para ese depósito.
- El incremento debe coincidir exactamente con la cantidad solicitada. Un excedente anterior al depósito queda excluido del cálculo.

### Validaciones de Retiradas

- El token debe estar admitido.
- La cantidad solicitada debe ser mayor que cero.
- El saldo disponible debe cubrir el importe total solicitado.
- Los fondos comprometidos en garantías u otras obligaciones no pueden retirarse.
- La comisión debe calcularse según el plan vigente y no puede superar el importe solicitado.
- Si falla alguna validación o transferencia, toda la operación debe revertirse.

## Invariantes y Propiedades

### Invariante `INV-01` - Respaldo de Saldos Disponibles

Cada unidad custodiada se atribuye a una sola partida por token. El total disponible se comprueba contra la suma de cuentas, incluidas las que hayan recibido pagos sin depositar previamente.

Las dos relaciones se comprueban por token. La primera verifica el respaldo de los disponibles. La segunda concilia todas las partidas con el saldo físico.

$$
\begin{aligned}
B_{\text{contrato}}(t) - I_{\text{protocolo}}(t)
&\geq \sum_{u \in U} B_{\text{disponible}}(u,t), \\
B_{\text{contrato}}(t)
&= \sum_{u \in U} B_{\text{disponible}}(u,t) + G(t) + L(t) + I_{\text{protocolo}}(t) + X(t).
\end{aligned}
$$

**Leyenda:**

- $T$: conjunto de tokens admitidos.
- $U$: conjunto de usuarios.
- $B_{\text{contrato}}(t)$: saldo real del token $t$ custodiado por el contrato.
- $I_{\text{protocolo}}(t)$: ingresos cobrados y todavía retenidos en el token $t$, después de restar las retiradas de tesorería.
- $B_{\text{disponible}}(u,t)$: saldo disponible del usuario $u$ para el token $t$.
- $G(t)$ y $L(t)$: garantía bloqueada y caja libre, respectivamente, en el token $t$.
- $X(t)$: excedente de transferencias directas sin atribuir, medido por esas entradas. Un déficit o un descuadre de otra partida no se puede compensar ajustando el excedente. En las pruebas se reconstruye X desde los envíos directos conocidos y se contrasta con el saldo final. Calcular X por diferencia y usar esa misma diferencia para verificar la igualdad ocultaría errores de contabilización.

### Invariante `INV-02` - Consistencia Contable

En `EC-01`, para cada token admitido, el saldo disponible total registrado por Veyra debe coincidir exactamente con la suma de los saldos disponibles de todos los usuarios. Cualquier diferencia entre ambos valores representa una inconsistencia en la contabilidad interna del protocolo.

Para cada token admitido, el *saldo disponible total es igual a la suma de los saldos disponibles individuales* de todos los usuarios.

```math
\forall t \in T:\quad
B_{\text{totalDisponible}}(t)
=
\sum_{u \in U} B_{\text{disponible}}(u,t)
```

**Leyenda:**

- $T$: conjunto de tokens admitidos.
- $U$: conjunto de direcciones de cuenta, incluidas las que reciben su primer abono.
- $B_{\text{totalDisponible}}(t)$: saldo disponible total del token $t$ registrado por Veyra.
- $B_{\text{disponible}}(u,t)$: saldo disponible del usuario $u$ para el token $t$.

### Invariante `INV-03` - Conservación de Depósitos

En `EC-01`, todo depósito realizado correctamente debe incrementar el saldo disponible del usuario exactamente en la cantidad de tokens efectivamente recibidos por el contrato de Veyra. Ningún depósito puede generar saldos adicionales ni acreditar fondos que no hayan sido transferidos al protocolo.

Para cada depósito válido de un token admitido, el incremento del saldo disponible del usuario debe ser igual al incremento de tokens custodiados por el contrato durante dicha operación.

```math
\forall d \in D:\quad
\Delta B_{\text{disponible}}(u,t,d)
=
\Delta B_{\text{contrato}}(t,d)
=
A_{\text{depositada}}(d)
```

**Leyenda:**

- $D$: conjunto de operaciones de depósito completadas correctamente.
- $u$: usuario que realiza el depósito.
- $t$: token admitido utilizado en el depósito.
- $\Delta B_{\text{disponible}}(u,t,d)$: incremento del saldo disponible del usuario $u$ para el token $t$ durante el depósito $d$.
- $\Delta B_{\text{contrato}}(t,d)$: incremento real del saldo del token $t$ custodiado por el contrato durante el depósito $d$.
- $A_{\text{depositada}}(d)$: cantidad de tokens depositada y efectivamente recibida durante la operación $d$.

### Invariante `INV-04` - Conservación de Retiradas

En `EC-01`, toda retirada realizada correctamente debe reducir el saldo disponible del usuario en la suma de la cantidad neta transferida y la comisión cobrada. La comisión debe registrarse como ingreso del protocolo.

Para cada retirada válida de un token admitido, la disminución del *saldo disponible del usuario debe ser igual a la cantidad neta transferida más la comisión registrada como ingreso* del protocolo.

```math
\forall r \in R:\quad
-\Delta B_{\text{disponible}}(u,t,r)
=
A_{\text{neta}}(r)
+
C_{\text{protocolo}}(r)
```

```math
\Delta I_{\text{protocolo}}(t,r)
=
C_{\text{protocolo}}(r)
```

**Leyenda:**

- $R$: conjunto de operaciones de retirada completadas correctamente.
- $u$: usuario que realiza la retirada.
- $t$: token admitido utilizado en la retirada.
- $\Delta B_{\text{disponible}}(u,t,r)$: variación del saldo disponible del usuario $u$ para el token $t$ durante la retirada $r$, calculada como saldo posterior menos saldo anterior.
- $A_{\text{neta}}(r)$: cantidad de tokens efectivamente transferida al usuario durante la retirada $r$.
- $C_{\text{protocolo}}(r)$: comisión aplicada y cobrada por el protocolo durante la retirada $r$.
- $\Delta I_{\text{protocolo}}(t,r)$: incremento de los ingresos contabilizados del protocolo para el token $t$ durante la retirada $r$.

### Invariante `INV-05` - Aislamiento de Saldos

En `EC-01`, toda operación de depósito o retirada realizada correctamente debe modificar únicamente el saldo disponible del usuario y del token involucrados. Los saldos disponibles de otros usuarios y de otros tokens permanecen inalterados.

Para cada depósito o retirada válida, el saldo disponible de cualquier combinación de usuario y token distinta de la involucrada en la operación debe permanecer exactamente igual antes y después de su ejecución.

$$
\forall o \in O_{\text{EC01}},\quad
\forall v \in U,\quad
\forall s \in T:\quad
(v,s) \neq (u_o,t_o)
\implies
\Delta B_{\text{disponible}}(v,s,o) = 0
$$

**Leyenda:**

- $O_{\text{EC01}}$: conjunto de operaciones de depósito y retirada completadas correctamente.
- $U$: conjunto de direcciones de cuenta, incluidas las que reciben su primer abono.
- $T$: conjunto de tokens admitidos.
- $o$: operación de depósito o retirada ejecutada.
- $u_o$: usuario que realiza la operación $o$.
- $t_o$: token utilizado en la operación $o$.
- $v$: usuario cuyo saldo se comprueba.
- $s$: token cuyo saldo se comprueba.
- $\Delta B_{\text{disponible}}(v,s,o)$: variación del saldo disponible del usuario $v$ para el token $s$ durante la operación $o$, calculada como saldo posterior menos saldo anterior.

### Invariante `INV-06` - Protección de Fondos Bloqueados

En `EC-01` los depósitos o retiradas no pueden modificar los saldos bloqueados de los usuarios, ya que estos corresponden a fondos comprometidos en otras cadenas económicas. Toda retirada debe realizarse exclusivamente sobre el saldo disponible.

Para cada depósito o retirada válida, los saldos bloqueados permanecen inalterados. Para cada retirada la disminución del saldo disponible no puede superar el saldo disponible del usuario antes de ejecutar la operación.

$$
\forall o \in O_{\text{EC01}},\quad
\forall u \in U,\quad
\forall t \in T:\quad
\Delta B_{\text{bloqueado}}(u,t,o) = 0
$$

$$
\forall r \in R_{\text{EC01}}:\quad
A_{\text{bruta}}(r)
\leq
B_{\text{disponible}}^{\text{antes}}(u_r,t_r)
$$

**Leyenda:**

- $O_{\text{EC01}}$: conjunto de operaciones de depósito y retirada completadas correctamente.
- $R_{\text{EC01}}$: conjunto de operaciones de retirada completadas correctamente.
- $U$: conjunto de direcciones de cuenta, incluidas las que reciben su primer abono.
- $T$: conjunto de tokens admitidos.
- $o$: operación de depósito o retirada ejecutada.
- $r$: operación de retirada ejecutada.
- $u$: usuario cuyo saldo bloqueado se comprueba.
- $t$: token cuyo saldo bloqueado se comprueba.
- $u_r$: usuario que realiza la retirada $r$.
- $t_r$: token utilizado en la retirada $r$.
- $\Delta B_{\text{bloqueado}}(u,t,o)$: variación del saldo bloqueado del usuario $u$ para el token $t$ durante la operación $o$, calculada como saldo posterior menos saldo anterior.
- $A_{\text{bruta}}(r)$: importe total descontado al usuario durante la retirada $r$, incluida la comisión del protocolo.
- $B_{\text{disponible}}^{\text{antes}}(u_r,t_r)$: saldo disponible del usuario para el token correspondiente antes de ejecutar la retirada.

### Invariante `INV-07` - Integridad de Depósitos

Una transferencia ERC-20 directa fuera del depósito autorizado nunca acredita saldo disponible. En EC-01, un abono por depósito exige recepción efectiva y registro. Un pago recibido (EC-02), un reembolso del fondo (EC-04), el desembolso de un préstamo (EC-05) y una garantía liberada o adjudicada (EC-06/07) son abonos internos autorizados con contrapartida. Cada uno actualiza el saldo individual y el total disponible por token según sus movimientos, sin registrar un nuevo depósito.

Para cada transferencia de tokens recibida fuera del procedimiento de depósito, los saldos disponibles de todos los usuarios para ese token permanecen inalterados.

$$
\forall e \in E_{\text{externas}},\quad
\forall u \in U,\quad
\forall t \in T:\quad
\Delta B_{\text{disponible}}(u,t,e) = 0,\qquad
\Delta B_{\text{totalDisponible}}(t,e) = 0
$$

**Leyenda:**

- $E_{\text{externas}}$: conjunto de transferencias de tokens recibidas directamente por el contrato fuera del procedimiento autorizado de depósito.
- $U$: conjunto de direcciones de cuenta, incluidas las que reciben su primer abono.
- $T$: conjunto de tokens admitidos.
- $e$: transferencia externa de tokens no registrada como depósito.
- $u$: usuario cuyo saldo disponible se comprueba.
- $t$: token admitido cuyo saldo se comprueba.
- $\Delta B_{\text{disponible}}(u,t,e)$: variación del saldo disponible del usuario $u$ para el token $t$ durante la transferencia externa $e$, calculada como saldo posterior menos saldo anterior.
- $\Delta B_{\text{totalDisponible}}(t,e)$: variación del saldo disponible total registrado por Veyra para el token $t$ durante la transferencia externa $e$, calculada como saldo posterior menos saldo anterior.

## Casos Límite y Escenarios de Fallo

Los siguientes casos describen el comportamiento esperado de `EC-01` y sirven de referencia para sus futuras pruebas. En una operación rechazada, los cambios de esa operación se revierten por completo; no se conservan abonos parciales ni comisiones.

### Depósitos

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Depósito con un token cuya dirección no está autorizada, aunque use el mismo nombre o símbolo que un token permitido. | Se rechaza sin acreditar saldo. La autorización se comprueba por dirección. | Validaciones |
| `CL-02` | Depósito de importe cero, inferior al mínimo o exactamente igual al mínimo. | Se rechaza. La regla es estricta: el importe debe ser mayor que el mínimo. Una unidad mínima por encima supera esta comprobación, pero debe cumplir el resto. | Validaciones |
| `CL-03` | El usuario carece de fondos o de autorización suficiente para transferir los tokens. | El depósito no se completa ni acredita saldo. Si la transferencia falla o devuelve `false`, se revierte toda la operación. | `INV-03` |
| `CL-04` | El contrato recibe una cantidad distinta de la solicitada. | Se revierte el depósito. Los dos tokens de prueba deben transferir exactamente el importe esperado; no se aceptan abonos parciales. | `INV-03` |
| `CL-05` | Primer depósito de un usuario o uso de tokens con decimales diferentes. | Se actualizan únicamente el saldo del usuario para ese token y su total. Un MockUSD equivale a `10^6` unidades mínimas y un MockETH a `10^18`. No se mezclan importes de tokens distintos. | `INV-02`, `INV-05` |
| `CL-06` | Un token admitido todavía no tiene usuarios con saldo disponible. | El total disponible y la suma de los saldos individuales son cero. Al completar el primer depósito, ambos aumentan por el importe recibido. | `INV-02`, `INV-03` |
| `CL-07` | Un usuario con saldo previo deposita de nuevo, o varios usuarios depositan el mismo token. | Cada depósito incrementa el saldo correspondiente y el total de ese token exactamente por el importe recibido. La suma de los saldos individuales sigue coincidiendo con el total, sin modificar saldos ajenos. | `INV-02`, `INV-03`, `INV-05` |
| `CL-08` | Una comprobación posterior a la transferencia de entrada impide completar el depósito. | Se revierte toda la operación, incluida la transferencia: el saldo del contrato, el saldo del usuario y el total disponible quedan como antes del intento. | Atomicidad, `INV-02`, `INV-03` |

### Retiradas y Comisiones

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-09` | Retirada de importe cero o superior al saldo disponible. | Se rechaza. Los saldos bloqueados, las participaciones del fondo y los fondos ajenos no completan el importe que falta. | `INV-05`, `INV-06` |
| `CL-10` | Retirada cuyo importe bruto coincide exactamente con el saldo disponible. | Puede completarse si cumple el resto de condiciones. El saldo disponible queda a cero y el usuario recibe el neto, con la comisión contabilizada por separado. | `INV-02`, `INV-04` |
| `CL-11` | Comisión igual a cero. | El neto coincide con el bruto. No aumenta el saldo de ingresos del protocolo. | `INV-04` |
| `CL-12` | Comisión superior al importe bruto. | Se rechaza la retirada. No se transfiere un neto negativo ni se cobra una comisión parcial. | Validaciones, `INV-04` |
| `CL-13` | Frontera matemática de retirada con comisión igual al bruto. | El neto sería cero y la comisión absorbería el bruto. Es una prueba de conservación con parámetros preparados. Con las tarifas de la instancia de referencia cualquier bruto positivo deja un neto positivo. | `INV-04` |
| `CL-14` | El cálculo de la comisión produce una fracción de la unidad mínima del token. | Se aplica una única regla de redondeo definida en `EC-03`. El neto se obtiene como bruto menos esa comisión entera; no se redondean el neto y la comisión de forma independiente. | `INV-04` |
| `CL-15` | Una retirada se divide en varias retiradas pequeñas. | Cada operación conserva exactamente su importe bruto. La suma de las comisiones debe corresponder a la regla de cálculo y redondeo por operación; no se presupone que coincida con la comisión de una única retirada grande. | `EC-03`, `INV-04` |
| `CL-16` | La transferencia de salida falla después de calcular la comisión o actualizar provisionalmente un saldo. | Se revierte toda la retirada. No permanecen el descuento, la comisión ni una transferencia definitiva de esa operación. | Atomicidad, `INV-04` |
| `CL-17` | El plan cambia o caduca antes de ejecutarse la retirada. | Se aplica el plan vigente al ejecutar la operación, según `EC-03`. La comisión utilizada para el neto y para su registro es la misma. Si no puede resolverse una configuración válida, se rechaza la operación. | `EC-03`, `INV-04` |
| `CL-18` | Un saldo o resultado final de depósito o retirada quedaría fuera de rango. | Se revierte íntegramente. Si solo el producto previo a dividir la comisión excede 256 bits, se usa precisión suficiente para obtener el resultado entero correcto. | `INV-02`, `INV-03`, `INV-04` |
| `CL-19` | Retirada parcial o total cuando otros usuarios también tienen saldo del mismo token. | El saldo del usuario y el total disponible disminuyen por el importe bruto; los saldos ajenos permanecen iguales. La suma de saldos individuales sigue coincidiendo con el total. | `INV-02`, `INV-04`, `INV-05` |
| `CL-20` | Varias retiradas correctas generan ingresos para un mismo token. | En cada operación se registra exactamente su comisión. El incremento acumulado de ingresos es la suma de las comisiones efectivamente cobradas, sin duplicaciones ni mezcla con los ingresos de otro token. | `INV-04`, `EC-08` |
| `CL-21` | Una retirada correcta con comisión positiva transfiere un importe neto al usuario. | El saldo disponible del usuario y el total disminuyen por el bruto; el saldo custodiado disminuye por el neto y los ingresos retenidos aumentan por la comisión. El bruto coincide con la suma de neto y comisión. | `INV-01`, `INV-02`, `INV-04` |
| `CL-22` | La transferencia de salida no entrega al usuario exactamente el neto calculado o reduce la custodia en un importe distinto del neto. | La retirada no puede completarse incumpliendo la conservación: se revierte toda la operación, sin cambios definitivos en saldos, custodia ni ingresos. Este caso verifica la compatibilidad de los tokens admitidos; no amplía la lista blanca. | `INV-01`, `INV-02`, `INV-04` |

### Custodia e Interacciones

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-23` | El contrato tiene tokens, pero parte de ellos respalda garantías u otras reservas. | Solo se permite una retirada que mantenga cubierta la suma de obligaciones. La presencia física de tokens reservados no los convierte en saldo disponible. | `INV-01`, `INV-06` |
| `CL-24` | Existe una insuficiencia real de respaldo. | Una retirada que no pueda preservar el respaldo restante se rechaza; no consume garantías ni reservas ajenas. El déficit es un incumplimiento de `INV-01`, no la falta de liquidez ordinaria del fondo de préstamos. | `INV-01`, `INV-06` |
| `CL-25` | Se recibe una transferencia directa, incluso antes de registrar al primer usuario, y después se realiza un depósito válido. | La transferencia directa no acredita saldos ni ingresos. El depósito posterior acredita solo su propio importe recibido, sin apropiarse del excedente previo. | `INV-03`, `INV-07` |
| `CL-26` | Un usuario o el administrador intenta retirar saldo de otra cuenta. | Se rechaza. El permiso para configurar tokens no concede autorización sobre fondos ajenos. | Actores, `INV-05` |
| `CL-27` | Se repite una retirada o se intenta reutilizar el mismo saldo mediante una llamada anidada. | Cada retirada utiliza el saldo disponible que le corresponde tras los movimientos anteriores. Ninguna llamada puede gastar dos veces el mismo saldo ni acreditar dos veces un depósito. | `INV-03`, `INV-04`, `INV-06` |
| `CL-28` | El administrador intenta desautorizar un token con saldos u obligaciones pendientes. | Se rechaza la desautorización. Los saldos siguen registrados, el token continúa sujeto a las invariantes y no se bloquean las retiradas por una baja de la lista blanca. | Actores, `INV-01`, `INV-06` |
| `CL-29` | `EC-08` retira ingresos del protocolo que estaban retenidos en el contrato de cuentas. | El saldo real del contrato y el saldo de ingresos retenidos disminuyen por la misma cantidad. Los saldos disponibles y las reservas de terceros permanecen inalterados. Esta salida se ejecuta en `EC-08`. | `EC-08`, `INV-01` |
| `CL-30` | El respaldo disponible para un token coincide exactamente con el mínimo necesario, o queda una unidad mínima por debajo. | En igualdad se cumple `INV-01`, siempre que las demás reservas también estén cubiertas. Una unidad por debajo incumple `INV-01`; una retirada no puede completar la operación consumiendo reservas ajenas ni empeorando ese respaldo. | `INV-01`, `INV-06` |
| `CL-31` | Hay saldos disponibles y bloqueados del mismo usuario y token durante un depósito o una retirada. | Solo cambia el saldo disponible según la operación; el saldo bloqueado y las demás posiciones descritas como ajenas a `EC-01` permanecen iguales. Una retirada no puede usar el saldo bloqueado para cubrir el bruto. | `INV-05`, `INV-06` |
| `CL-32` | Se recibe una transferencia directa cuando ya existen saldos disponibles e ingresos del protocolo. | Aumenta la custodia por lo recibido, pero no cambian los saldos individuales, el total disponible ni los ingresos contabilizados. El excedente no se atribuye a ningún usuario ni al protocolo. | `INV-01`, `INV-02`, `INV-07` |
| `CL-33` | Una secuencia combina depósitos, retiradas y operaciones rechazadas para varios usuarios y ambos tokens. | Tras cada operación completada se comprueban las invariantes por token y usuario. Cada intento rechazado conserva el estado previo a ese intento, incluidos el total disponible, la custodia y los ingresos. | `INV-01`–`INV-07` |

### Matriz adicional de límites por invariante

Los casos siguientes complementan los anteriores. Se comprueban por separado para cada token admitido, con importes expresados en sus propias unidades mínimas. Cuando un caso parte de una contabilidad o un respaldo ya inconsistentes, describe un estado de fallo para detectar: no presupone que `EC-01` pueda reparar el estado ni que la operación deba aceptarse.

| ID | Invariante | Caso límite | Resultado o comprobación esperada |
|---|---|---|---|
| `CL-34` | `INV-01` | Custodia, ingresos retenidos y saldos disponibles son todos cero. | La desigualdad se cumple en igualdad; ningún usuario dispone de fondos que retirar. |
| `CL-35` | `INV-01` | Los ingresos retenidos igualan la custodia y no hay saldos disponibles. | El respaldo disponible para usuarios es cero. Los ingresos no se tratan como fondos retirables por usuarios y se comprueban también las demás reservas. |
| `CL-36` | `INV-01` | Los ingresos contabilizados superan la custodia. | Se detecta un estado de respaldo inválido; el cálculo no debe presentar un resultado válido por desbordamiento o subdesbordamiento. No se infiere un mecanismo de recuperación. |
| `CL-37` | `INV-01` | La custodia menos ingresos supera la suma disponible en exactamente una unidad mínima o en una cantidad mayor. | La desigualdad se cumple; el excedente no se acredita automáticamente. Se comprueba por separado la cobertura de otras reservas. |
| `CL-38` | `INV-01` | Retirada desde respaldo exacto, con comisión cero o positiva. | La custodia baja por el neto, los ingresos retenidos suben por la comisión y el disponible baja por el bruto. La frontera de neto cero se describe en `CL-13`. |
| `CL-39` | `INV-02` | Total registrado menor o mayor que la suma individual, incluida una diferencia de una unidad mínima. | Se detecta inconsistencia contable. Una operación fallida no la oculta ni modifica; la reparación del estado no está definida en `EC-01`. |
| `CL-40` | `INV-02` | El último saldo disponible de un token se retira por completo. | El saldo del usuario y el total de ese token quedan a cero si no existen otros saldos disponibles; el total del otro token no cambia. |
| `CL-41` | `INV-02` | El saldo individual o el total está en el máximo representable, o a una unidad de él, antes de un depósito. | Si el resultado exacto cabe, y se cumplen las demás condiciones, ambos aumentan por lo recibido; si cualquiera no cabe, se revierte todo el depósito. |
| `CL-42` | `INV-02` | Una retirada reduciría el total registrado por debajo de cero por una inconsistencia previa. | Se detecta el fallo y se revierte la operación; no se permite que la aritmética produzca un total aparente válido. |
| `CL-43` | `INV-03` | El saldo, los ingresos o la custodia ya son distintos de cero antes del depósito. | Solo se acredita el incremento de custodia atribuible a ese depósito, igual al importe solicitado y efectivamente recibido; no se acredita el saldo previo ni se generan ingresos por el depósito. |
| `CL-44` | `INV-03` | La transferencia de entrada entrega cero, menos o más que el importe solicitado. | Se rechaza y revierte la operación completa; ninguna cantidad recibida durante ese intento queda acreditada. Complementa `CL-04`. |
| `CL-45` | `INV-03` | La autorización o el saldo de tokens del usuario es exactamente el importe solicitado, o una unidad inferior. | En igualdad se supera esa comprobación si todas las demás condiciones se cumplen; con una unidad menos no se completa el depósito. La autorización y el saldo se comprueban por separado. |
| `CL-46` | `INV-03` | Una llamada anidada intenta depositar antes de que termine otro depósito. | Ninguna operación completada puede acreditar tokens dos veces ni atribuir a su propio incremento los recibidos por otra. Si no puede garantizarse esa separación, se revierte la operación afectada. |
| `CL-47` | `INV-04` | Retirada de una unidad mínima, con saldo y respaldo suficientes. | Se aplica la comisión entera resultante de la regla vigente; debe estar entre cero y el bruto. El neto, el descuento y el ingreso conservan exactamente esa unidad. |
| `CL-48` | `INV-04` | Comisión de una unidad mínima o de una unidad menos que el bruto, cuando esos valores son posibles. | El neto es exactamente el bruto menos la comisión; se registra una sola vez la comisión calculada y se descuenta el bruto. |
| `CL-49` | `INV-04` | La salida devuelve `false`, revierte o no puede completarse después de actualizar provisionalmente ingresos o saldos. | Se revierte toda la retirada, incluidos el descuento, el total disponible, la transferencia y los ingresos provisionales. |
| `CL-50` | `INV-04` | Los ingresos retenidos están en el máximo representable, o a una unidad de él, antes de sumar una comisión. | Si el ingreso resultante cabe, puede registrarse sujeto al resto de condiciones; si no cabe, se revierte toda la retirada sin truncamiento. |
| `CL-51` | `INV-05` | Dos usuarios operan con el mismo token, o un usuario opera con ambos tokens. | Cada operación cambia solo el saldo disponible de la pareja usuario-token correspondiente; los totales se actualizan únicamente para el token afectado. |
| `CL-52` | `INV-05` | Una operación se rechaza antes o después de cambios provisionales. | Ningún saldo disponible individual ni total conserva cambios del intento, tampoco el de la pareja que lo inició. |
| `CL-53` | `INV-05` | Se intenta acceder a una cuenta o token distinto mediante una llamada anidada o parámetros de la operación. | No se modifica un saldo ajeno sin una operación autorizada que corresponda a esa cuenta y token; una llamada anidada no autoriza por sí sola el movimiento. |
| `CL-54` | `INV-06` | Saldo disponible cero con fondos bloqueados positivos, o disponible positivo sin fondos bloqueados. | El primer usuario no puede retirar importe positivo; el segundo solo puede retirar hasta su disponible. En ambos casos los bloqueos permanecen iguales. |
| `CL-55` | `INV-06` | El bruto solicitado está una unidad por debajo, es igual o está una unidad por encima del disponible. | Los dos primeros superan la comprobación de saldo si el bruto es positivo; el tercero se rechaza. Los casos aceptables siguen sujetos a las demás validaciones. |
| `CL-56` | `INV-06` | Hay bloqueos de otros usuarios o del otro token durante un depósito, una retirada o un intento fallido. | Ningún saldo bloqueado cambia por esa operación; las reservas ajenas no financian una retirada. |
| `CL-57` | `INV-07` | Transferencias directas repetidas de uno o ambos tokens antes, entre o después de operaciones de `EC-01`. | Cada transferencia directa deja inalterados los saldos individuales, los totales disponibles y los ingresos; las operaciones posteriores solo contabilizan sus propios importes. |
| `CL-58` | `INV-07` | Una transferencia directa usa un token no admitido. | No acredita saldos ni ingresos de tokens admitidos y no convierte ese token en admitido. La recuperación de activos enviados directamente no está definida en `EC-01`. |
| `CL-59` | `INV-07` | Una transferencia directa ocurre durante una interacción anidada con un depósito. | El excedente directo no se acredita a ningún usuario. Si no puede distinguirse de lo recibido por el depósito para cumplir sus comprobaciones, el depósito no debe completarse atribuyéndoselo. |
| `CL-60` | `INV-01`–`INV-07` | Un intento falla en cada punto observable: validación, transferencia, actualización contable o comprobación final. | Para cada punto de fallo, el estado posterior al intento coincide con el anterior en todos los saldos, custodia e ingresos afectados por ese intento. |

Para cubrir combinaciones sin enumerar cada secuencia individual, ejecutar las clases anteriores con cada token admitido; con uno y varios usuarios; con saldos iniciales cero y positivos; y con operaciones aisladas y secuencias. Aplicar los límites de una unidad mínima y del máximo representable cuando sean válidos para la configuración. En cada transición completada comprobar las siete invariantes aplicables; en cada transición rechazada comparar el estado con el inmediatamente anterior. Los estados inconsistentes se usan para detectar fallos y no como premisa de que una operación normal pueda corregirlos.

Los mínimos por token, las comisiones de cada plan y el redondeo están recogidos en la [configuración de Anvil](../economic.md). El mínimo de referencia es cero y la primera cantidad válida es una unidad del token.

El depósito exige superar el mínimo. La validación de retirada admite por conservación una comisión igual al bruto. Las tarifas de referencia siempre producen una comisión inferior al bruto positivo.

La eventual recuperación de excedentes recibidos por transferencias directas no forma parte de EC-01. Esta cadena no concede al administrador un permiso para retirarlos ni los convierte automáticamente en ingresos del protocolo.

Estos casos son una referencia para diseñar pruebas de `EC-01`, no una demostración exhaustiva de todas las secuencias o comportamientos posibles. Las referencias a otras cadenas identifican dependencias ya descritas; sus propios flujos quedan fuera del alcance de estos casos.
