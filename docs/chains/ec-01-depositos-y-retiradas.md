# `EC-01` Depósitos y Retiradas

La cadena económica `EC-01` gestiona la entrada de tokens, el saldo disponible y la retirada de fondos.

## Objetivo

El objetivo de esta cadena es aceptar depósitos de los tokens permitidos, actualizar el saldo de cada cuenta y procesar retiradas solo cuando haya liquidez suficiente, garantizando que lo comprometido en préstamos o comisiones no se pueda retirar.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen tres actores:

- El usuario deposita **MockUSD** o **MockETH**, consulta su saldo y solicita retiradas de sus propios fondos disponibles.
- El contrato de cuentas de Veyra valida los tokens admitidos, actualiza los saldos y ejecuta las retiradas cuando corresponde.
- El administrador configura la lista blanca de tokens, pero no puede mover fondos de los usuarios ni modificar sus saldos arbitrariamente. En `v0.1.0` no puede desautorizar un token mientras existan saldos disponibles, fondos bloqueados, ingresos del protocolo u otras reservas contabilizadas pendientes para ese token.

## Variables y Estado Contable

Para cada usuario y cada token admitido, Veyra mantiene un saldo disponible que el usuario puede usar o retirar. Los saldos bloqueados por garantías u otras obligaciones, las participaciones del fondo de liquidez y las deudas de los prestatarios son estados asociados que `EC-01` no modifica.

**Reglas contables:** Los depósitos aumentan el saldo disponible del token correspondiente.

Las retiradas lo reducen siempre que haya liquidez suficiente.

Los tokens enviados directamente al contrato fuera del flujo previsto no aumentan automáticamente el saldo disponible de ningún usuario.

Las comisiones generadas por retiradas se separan del saldo disponible del usuario y se registran como ingreso del protocolo `EC-08`.

## Flujo Económico

### Flujo de Deposito

El usuario ordena depositar una cantidad de un token admitido, Veyra recibe los tokens en el contrato de cuentas, aumenta el saldo disponible de ese usuario para ese token y no toca saldos bloqueados, ni deudas, ni participaciones del fondo.

Los depósitos no generan comisiones ni crean deuda.

### Flujos de Retirada

El usuario solicita retirar una cantidad de un token admitido, Veyra comprueba que el saldo disponible es suficiente, que no estén bloqueados por garantías u obligaciones y calcula la comisión aplicable según el plan del usuario `EC-03`.

Reduce del saldo disponible el importe total solicitado y envía al usuario la cantidad neta descontada la comisión.

La comisón se contabiliza como ingreso del protocolo `EC-08`.

Las retiradas no afectan a deudas ni participaciones del fondo.

## Validaciones y Restricciones

### Validaciones de Depósitos

- El token debe estar autorizado en la lista blanca.
- La cantidad depositada debe ser mayor que el mínimo permitido.
- El depósito solo se acredita si los tokens han sido efectivamente recibidos por el contrato.
- Veyra debe verificar que los tokens se hayan recibido correctamente antes de acreditar el saldo.

### Validaciones de Retiradas

- El token debe estar admitido.
- La cantidad solicitada debe ser mayor que cero.
- El saldo disponible debe cubrir el importe total solicitado.
- Los fondos comprometidos en garantías u otras obligaciones no pueden retirarse.
- La comisión debe calcularse según el plan vigente y no puede superar el importe solicitado.
- Si falla alguna validación o transferencia, toda la operación debe revertirse.

## Invariantes y Propiedades

### Invariante `INV-01` - Respaldo de Saldos Disponibles

En `EC-01` la suma de los saldos disponibles de los usuarios para un token nunca supera los tokens realmente custodiados por el contrato para ese token, descontando lo que esté claramente contabilizado como ingreso del protocolo.

Para cada token admitido: *el saldo custodiado menos ingresos del protocolo mayor o igual que la suma de los saldos disponibles* de todos los usuarios.

$$
\forall t \in T:\quad
B_{\text{contrato}}(t) - I_{\text{protocolo}}(t)
\geq
\sum_{u \in U} B_{\text{disponible}}(u,t)
$$

**Leyenda:**

- $T$: conjunto de tokens admitidos.
- $U$: conjunto de usuarios.
- $B_{\text{contrato}}(t)$: saldo real del token $t$ custodiado por el contrato.
- $I_{\text{protocolo}}(t)$: ingresos del protocolo contabilizados en el token $t$.
- $B_{\text{disponible}}(u,t)$: saldo disponible del usuario $u$ para el token $t$.

### Invariante `INV-02` - Consistencia Contable

En `EC-01`, para cada token admitido, el saldo disponible total registrado por Veyra debe coincidir exactamente con la suma de los saldos disponibles de todos los usuarios. Cualquier diferencia entre ambos valores representa una inconsistencia en la contabilidad interna del protocolo.

Para cada token admitido, el *saldo disponible total es igual a la suma de los saldos disponibles individuales* de todos los usuarios.

$$
\forall t \in T:\quad
B_{\text{totalDisponible}}(t)
=
\sum_{u \in U} B_{\text{disponible}}(u,t)
$$

**Leyenda:**

- $T$: conjunto de tokens admitidos.
- $U$: conjunto de usuarios registrados en Veyra.
- $B_{\text{totalDisponible}}(t)$: saldo disponible total del token $t$ registrado por Veyra.
- $B_{\text{disponible}}(u,t)$: saldo disponible del usuario $u$ para el token $t$.

### Invariante `INV-03` - Conservación de Depósitos

En `EC-01`, todo depósito realizado correctamente debe incrementar el saldo disponible del usuario exactamente en la cantidad de tokens efectivamente recibidos por el contrato de Veyra. Ningún depósito puede generar saldos adicionales ni acreditar fondos que no hayan sido transferidos al protocolo.

Para cada depósito válido de un token admitido, el incremento del saldo disponible del usuario debe ser igual al incremento de tokens custodiados por el contrato durante dicha operación.

$$
\forall d \in D:\quad
\Delta B_{\text{disponible}}(u,t,d)
=
\Delta B_{\text{contrato}}(t,d)
=
A_{\text{depositada}}(d)
$$

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

$$
\forall r \in R:\quad
-\Delta B_{\text{disponible}}(u,t,r)
=
A_{\text{neta}}(r)
+
C_{\text{protocolo}}(r)
$$

$$
\Delta I_{\text{protocolo}}(t,r)
=
C_{\text{protocolo}}(r)
$$

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
- $U$: conjunto de usuarios registrados en Veyra.
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
- $U$: conjunto de usuarios registrados en Veyra.
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

En `EC-01`, los tokens enviados directamente al contrato fuera del procedimiento de depósito no generan saldos disponibles para ningún usuario. Toda acreditación de saldo disponible debe venir de un depósito válido y registrado.

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
- $U$: conjunto de usuarios registrados en Veyra.
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

### Retiradas y Comisiones

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-06` | Retirada de importe cero o superior al saldo disponible. | Se rechaza. Los saldos bloqueados, las participaciones del fondo y los fondos ajenos no completan el importe que falta. | `INV-05`, `INV-06` |
| `CL-07` | Retirada cuyo importe bruto coincide exactamente con el saldo disponible. | Puede completarse si cumple el resto de condiciones. El saldo disponible queda a cero y el usuario recibe el neto, con la comisión contabilizada por separado. | `INV-02`, `INV-04` |
| `CL-08` | Comisión igual a cero. | El neto coincide con el bruto. No aumenta el saldo de ingresos del protocolo. | `INV-04` |
| `CL-09` | Comisión superior al importe bruto. | Se rechaza la retirada. No se transfiere un neto negativo ni se cobra una comisión parcial. | Validaciones, `INV-04` |
| `CL-10` | Comisión exactamente igual al importe bruto. | La condición actual permite este límite: el neto es cero y todo el importe bruto se registra como comisión. El saldo disponible disminuye por el bruto y el saldo real del contrato no disminuye. | `INV-04` |
| `CL-11` | El cálculo de la comisión produce una fracción de la unidad mínima del token. | Se aplica una única regla de redondeo definida en `EC-03`. El neto se obtiene como bruto menos esa comisión entera; no se redondean el neto y la comisión de forma independiente. | `INV-04` |
| `CL-12` | Una retirada se divide en varias retiradas pequeñas. | Cada operación conserva exactamente su importe bruto. La suma de las comisiones debe corresponder a la regla de cálculo y redondeo por operación; no se presupone que coincida con la comisión de una única retirada grande. | `EC-03`, `INV-04` |
| `CL-13` | La transferencia de salida falla después de calcular la comisión o actualizar provisionalmente un saldo. | Se revierte toda la retirada. No permanecen el descuento, la comisión ni una transferencia definitiva de esa operación. | Atomicidad, `INV-04` |
| `CL-14` | El plan cambia o caduca antes de ejecutarse la retirada. | Se aplica el plan vigente al ejecutar la operación, según `EC-03`. La comisión utilizada para el neto y para su registro es la misma. Si no puede resolverse una configuración válida, se rechaza la operación. | `EC-03`, `INV-04` |
| `CL-15` | Un importe o un cálculo excede el rango de representación elegido para la implementación. | Se rechaza la operación en lugar de truncar, desbordar o ajustar silenciosamente los saldos. | `INV-02`, `INV-03`, `INV-04` |

### Custodia e Interacciones

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-16` | El contrato tiene tokens, pero parte de ellos respalda garantías u otras reservas. | Solo se permite una retirada que mantenga cubierta la suma de obligaciones. La presencia física de tokens reservados no los convierte en saldo disponible. | `INV-01`, `INV-06` |
| `CL-17` | Existe una insuficiencia real de respaldo. | Una retirada que no pueda preservar el respaldo restante se rechaza; no consume garantías ni reservas ajenas. El déficit es un incumplimiento de `INV-01`, no la falta de liquidez ordinaria del fondo de préstamos. | `INV-01`, `INV-06` |
| `CL-18` | Se recibe una transferencia directa, incluso antes de registrar al primer usuario, y después se realiza un depósito válido. | La transferencia directa no acredita saldos ni ingresos. El depósito posterior acredita solo su propio importe recibido, sin apropiarse del excedente previo. | `INV-03`, `INV-07` |
| `CL-19` | Un usuario o el administrador intenta retirar saldo de otra cuenta. | Se rechaza. El permiso para configurar tokens no concede autorización sobre fondos ajenos. | Actores, `INV-05` |
| `CL-20` | Se repite una retirada o se intenta reutilizar el mismo saldo mediante una llamada anidada. | Cada retirada utiliza el saldo disponible que le corresponde tras los movimientos anteriores. Ninguna llamada puede gastar dos veces el mismo saldo ni acreditar dos veces un depósito. | `INV-03`, `INV-04`, `INV-06` |
| `CL-21` | El administrador intenta desautorizar un token con saldos u obligaciones pendientes. | Se rechaza la desautorización. Los saldos siguen registrados, el token continúa sujeto a las invariantes y no se bloquean las retiradas por una baja de la lista blanca. | Actores, `INV-01`, `INV-06` |
| `CL-22` | `EC-08` retira ingresos del protocolo que estaban retenidos en el contrato de cuentas. | El saldo real del contrato y el saldo de ingresos retenidos disminuyen por la misma cantidad. Los saldos disponibles y las reservas de terceros permanecen inalterados. Esta salida se ejecuta en `EC-08`. | `EC-08`, `INV-01` |

**Parámetros que se concretarán en la configuración y en EC-03:** los valores mínimos de depósito por token, las tasas de comisión de cada plan y el sentido del redondeo. Estos valores no se fijan en EC-01; deben quedar definidos antes de implementar los casos que dependan de ellos.

La regla vigente de depósito es estricta: importe mayor que el mínimo. La regla vigente de retirada permite una comisión igual al bruto. Cambiar cualquiera de estos límites requiere actualizar conjuntamente las validaciones y sus casos límite.

La eventual recuperación de excedentes recibidos por transferencias directas no forma parte de EC-01. Esta cadena no concede al administrador un permiso para retirarlos ni los convierte automáticamente en ingresos del protocolo.
