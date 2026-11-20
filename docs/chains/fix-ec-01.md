# `EC-01` Depósitos y Retiradas

La cadena económica `EC-01` gestiona la entrada de tokens, el saldo disponible y la retirada de fondos.

## Objetivo

El objetivo de esta cadena es aceptar depósitos de los tokens permitidos, actualizar el saldo de cada cuenta y procesar retiradas cuando exista saldo disponible y respaldo suficiente, preservando los fondos reservados para otras obligaciones y los ingresos del protocolo.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen tres participantes:

- El usuario deposita **MockUSD** o **MockETH**, consulta su saldo y solicita retiradas de sus propios fondos disponibles.
- El contrato de cuentas de Veyra valida los tokens admitidos, actualiza los saldos y ejecuta las retiradas cuando corresponde.
- El administrador configura la lista blanca de tokens, pero no puede mover fondos de los usuarios ni modificar sus saldos arbitrariamente. En `v0.1.0` no puede desautorizar un token mientras existan saldos disponibles, fondos bloqueados, ingresos del protocolo u otras reservas contabilizadas pendientes para ese token.

## Variables y Estado Contable

Para cada usuario y cada token admitido, Veyra mantiene un saldo disponible que el usuario puede usar o retirar. También registra el saldo disponible total de cada token, que debe coincidir con la suma de los saldos disponibles individuales.

Los estados asociados, pero no modificados por `EC-01`, son los saldos bloqueados por garantías u otras obligaciones, las participaciones del fondo de liquidez y las deudas de los prestatarios. Las aportaciones voluntarias al fondo dejan de formar parte del saldo disponible y se contabilizan en `EC-04`. El bloqueo y la liberación de garantías corresponden a `EC-05`.

Los importes se expresan en unidades mínimas de cada token: MockUSD utiliza 6 decimales y MockETH utiliza 18. El mínimo de depósito se configura por token como un entero no negativo en esas mismas unidades. Los importes de ambos tokens se contabilizan por separado.

**Reglas contables:** los depósitos válidos aumentan el saldo disponible del usuario y el saldo disponible total del token por el importe efectivamente recibido.

Las retiradas reducen ambos saldos por el importe bruto solicitado. Ese importe incluye la cantidad neta enviada al usuario y la comisión del protocolo, calculadas en el mismo token.

Las comisiones cobradas en las retiradas se registran por separado en `EC-08` y permanecen en el contrato de cuentas hasta su retirada por el protocolo. El saldo de ingresos representa únicamente los ingresos ya cobrados y todavía custodiados en ese contrato; no representa el total histórico de ingresos ni comisiones pendientes de cobro.

Si el contrato de cuentas comparte custodia con otras cadenas, mantiene identificada la cantidad de tokens que debe reservar para sus obligaciones, como garantías bloqueadas o capital del fondo custodiado allí. Estas reservas no se incluyen en los saldos disponibles ni en los ingresos del protocolo. No se suman de nuevo las deudas de los prestatarios o el valor de las participaciones como si fueran tokens presentes en el contrato.

Los tokens enviados directamente al contrato fuera del procedimiento de depósito pueden aumentar su saldo real, pero no aumentan automáticamente los saldos disponibles, su total ni los ingresos del protocolo. Constituyen un excedente no asignado, siempre que los activos superen el conjunto de obligaciones contabilizadas.

## Flujo Económico

### Flujo de Depósito

El usuario ordena depositar una cantidad de un token admitido. Veyra valida la operación, recibe los tokens en el contrato de cuentas y comprueba que la cantidad recibida coincide con la solicitada. Después aumenta el saldo disponible de ese usuario y el saldo disponible total del token por dicha cantidad.

El depósito no modifica saldos bloqueados, deudas de los prestatarios ni participaciones del fondo. Los depósitos no generan comisiones ni crean deuda de préstamo.

### Flujo de Retirada

El usuario solicita retirar una cantidad de un token admitido. Veyra comprueba que su saldo disponible cubre el importe bruto solicitado y calcula la comisión aplicable según el plan vigente al ejecutar la operación, conforme a `EC-03`.

Veyra reduce el saldo disponible del usuario y el saldo disponible total por el importe bruto. Transfiere al usuario la cantidad neta, obtenida al descontar la comisión del importe bruto, y registra la comisión como ingreso del protocolo en `EC-08`.

La comisión queda retenida en el contrato de cuentas. Por tanto, el saldo real de tokens del contrato disminuye únicamente en la cantidad neta transferida al usuario. La retirada debe preservar el respaldo de los saldos disponibles restantes, los ingresos retenidos y las demás reservas custodiadas.

Las retiradas no modifican las deudas, las garantías bloqueadas ni las participaciones del fondo. La transferencia y todos los cambios contables forman una única operación atómica.

## Validaciones y Restricciones

### Validaciones de Depósitos

- La dirección del token debe estar autorizada en la lista blanca.
- La cantidad solicitada debe ser mayor que cero y estrictamente mayor que el mínimo configurado para ese token. Una cantidad exactamente igual al mínimo se rechaza.
- El depósito solo se acredita cuando la transferencia se completa correctamente y el contrato recibe exactamente la cantidad solicitada.
- El importe acreditado corresponde exclusivamente a los tokens recibidos durante ese depósito. No incluye tokens que ya estuvieran en el contrato.
- Se utilizan los dos tokens de prueba definidos en `tokens.md`, sin comisiones por transferencia ni cambios automáticos de saldo.

### Validaciones de Retiradas

- La dirección del token debe estar admitida.
- El usuario solo puede retirar su propio saldo disponible.
- La cantidad bruta solicitada debe ser mayor que cero.
- El saldo disponible anterior a la operación debe cubrir el importe bruto solicitado, incluida la comisión.
- Los fondos bloqueados, el capital asignado al fondo de liquidez y los saldos de otros usuarios no pueden utilizarse para completar el saldo disponible del solicitante.
- La comisión debe calcularse según el plan vigente. Debe ser no negativa y no puede superar el importe bruto solicitado.
- La cantidad neta se obtiene restando la comisión al importe bruto. La comisión no se cobra otra vez por encima de ese importe.
- El contrato debe poder entregar la cantidad neta y mantener el respaldo de todas las obligaciones que permanezcan bajo su custodia, conforme a `INV-01`.
- La transferencia de salida debe completarse correctamente por la cantidad neta prevista.

Si falla una validación, una transferencia o un cálculo necesario, se revierte toda la operación, tanto en depósitos como en retiradas. No puede quedar un abono, un descuento de saldo, una comisión ni una transferencia definitiva asociados a una operación fallida. Una transferencia que devuelva `false` también se considera fallida, conforme al [estándar ERC-20](https://eips.ethereum.org/EIPS/eip-20).

## Invariantes y Propiedades

Las invariantes de estado se comprueban en estados consistentes del protocolo, antes y después de las operaciones. Las propiedades de transición comparan el estado inmediatamente anterior y posterior a cada operación individual. La variación $\Delta$ se calcula siempre como valor posterior menos valor anterior.

Todas las cantidades de una misma ecuación están expresadas en unidades mínimas del mismo token. Las categorías de saldo disponible, ingresos retenidos y otras reservas son excluyentes: una misma cantidad no puede contabilizarse en más de una de ellas.

### Invariante `INV-01` - Respaldo de Saldos Disponibles

En `EC-01`, la suma de los saldos disponibles de los usuarios para cada token debe estar respaldada por los tokens realmente custodiados en el contrato de cuentas, descontando los ingresos retenidos del protocolo y las reservas que respalden otras obligaciones dentro del mismo contrato. Las garantías y los demás fondos reservados no pueden utilizarse simultáneamente como respaldo del saldo disponible.

Para cada token admitido, el saldo custodiado menos los ingresos retenidos y las demás reservas debe ser mayor o igual que la suma de los saldos disponibles de todos los usuarios.

$$
\forall t \in T:\quad
B_{\text{contrato}}(t)
-
I_{\text{protocolo}}(t)
-
B_{\text{reservado}}(t)
\geq
\sum_{u \in U} B_{\text{disponible}}(u,t)
$$

**Leyenda:**

- $T$: conjunto de tokens admitidos por Veyra. Un token con saldos u obligaciones pendientes no puede eliminarse de este conjunto.
- $U$: conjunto de usuarios registrados en Veyra.
- $B_{\text{contrato}}(t)$: saldo real del token $t$ custodiado por el contrato de cuentas.
- $I_{\text{protocolo}}(t)$: ingresos del protocolo ya cobrados, pendientes de retirar y todavía custodiados en ese mismo contrato, expresados en el token $t$. Es un saldo actual, no un acumulado histórico.
- $B_{\text{reservado}}(t)$: cantidad del token $t$ que debe mantenerse en este contrato para respaldar garantías bloqueadas y otras reservas de terceros. Excluye los saldos disponibles y los ingresos ya contabilizados por separado. Si esas obligaciones se custodian íntegramente en otros contratos, su contribución a esta variable es cero.
- $B_{\text{disponible}}(u,t)$: saldo disponible del usuario $u$ para el token $t$.

### Invariante `INV-02` - Consistencia Contable

En `EC-01`, para cada token admitido, el saldo disponible total registrado por Veyra debe coincidir exactamente con la suma de los saldos disponibles de todos los usuarios. Cualquier diferencia entre ambos valores representa una inconsistencia en la contabilidad interna del protocolo.

Para cada token admitido, el saldo disponible total es igual a la suma de los saldos disponibles individuales de todos los usuarios.

$$
\forall t \in T:\quad
B_{\text{totalDisponible}}(t)
=
\sum_{u \in U} B_{\text{disponible}}(u,t)
$$

**Leyenda:**

- $T$: conjunto de tokens admitidos por Veyra.
- $U$: conjunto de usuarios registrados en Veyra.
- $B_{\text{totalDisponible}}(t)$: saldo disponible total del token $t$ registrado por Veyra.
- $B_{\text{disponible}}(u,t)$: saldo disponible del usuario $u$ para el token $t$.

### Invariante `INV-03` - Conservación de Depósitos

En `EC-01`, todo depósito realizado correctamente debe incrementar el saldo disponible del usuario exactamente en la cantidad de tokens efectivamente recibidos por el contrato de Veyra. Ningún depósito puede generar saldos adicionales ni acreditar fondos que no hayan sido transferidos al protocolo.

Para cada depósito válido de un token admitido, el incremento del saldo disponible del usuario debe ser igual al incremento de tokens custodiados por el contrato y a la cantidad solicitada durante esa operación.

$$
\forall d \in D:\quad
\Delta B_{\text{disponible}}(u_d,t_d,d)
=
\Delta B_{\text{contrato}}(t_d,d)
=
A_{\text{depositada}}(d)
$$

**Leyenda:**

- $D$: conjunto de operaciones de depósito completadas correctamente.
- $u_d$: usuario que realiza el depósito $d$.
- $t_d$: token admitido utilizado en el depósito $d$.
- $\Delta B_{\text{disponible}}(u_d,t_d,d)$: incremento del saldo disponible del usuario para ese token durante el depósito $d$.
- $\Delta B_{\text{contrato}}(t_d,d)$: incremento real del saldo de ese token custodiado por el contrato durante el depósito $d$.
- $A_{\text{depositada}}(d)$: importe solicitado en el depósito $d$, que debe coincidir exactamente con la cantidad efectivamente recibida para que la operación se complete.

### Invariante `INV-04` - Conservación de Retiradas

En `EC-01`, toda retirada realizada correctamente debe reducir el saldo disponible del usuario en la suma de la cantidad neta transferida y la comisión cobrada. La comisión debe registrarse como ingreso retenido del protocolo. El saldo real del contrato disminuye únicamente en la cantidad neta enviada al usuario.

Para cada retirada válida de un token admitido, el importe bruto descontado debe ser igual a la suma de la cantidad neta transferida y la comisión registrada como ingreso del protocolo.

$$
\forall r \in R:\quad
\begin{aligned}
A_{\text{bruta}}(r)
&=
-\Delta B_{\text{disponible}}(u_r,t_r,r)
=
A_{\text{neta}}(r)+C_{\text{protocolo}}(r) \\
\Delta I_{\text{protocolo}}(t_r,r)
&= C_{\text{protocolo}}(r) \\
\Delta B_{\text{contrato}}(t_r,r)
&= -A_{\text{neta}}(r)
\end{aligned}
$$

**Leyenda:**

- $R$: conjunto de operaciones de retirada completadas correctamente.
- $u_r$: usuario que realiza la retirada $r$.
- $t_r$: token admitido utilizado en la retirada $r$.
- $A_{\text{bruta}}(r)$: importe total solicitado y descontado al usuario durante la retirada $r$, incluida la comisión.
- $\Delta B_{\text{disponible}}(u_r,t_r,r)$: variación del saldo disponible del usuario para ese token durante la retirada $r$.
- $A_{\text{neta}}(r)$: cantidad de tokens efectivamente transferida al usuario durante la retirada $r$.
- $C_{\text{protocolo}}(r)$: comisión aplicada y cobrada en el mismo token durante la retirada $r$.
- $\Delta I_{\text{protocolo}}(t_r,r)$: incremento del saldo de ingresos del protocolo retenido en el contrato para ese token durante la retirada $r$.
- $\Delta B_{\text{contrato}}(t_r,r)$: variación del saldo real de ese token custodiado por el contrato durante la retirada $r$.

### Invariante `INV-05` - Aislamiento de Saldos

En `EC-01`, entre los saldos disponibles individuales, una operación de depósito o retirada solo puede modificar el correspondiente al usuario y al token involucrados. Los saldos disponibles de otros usuarios y de otros tokens permanecen inalterados. Esto no impide actualizar el total disponible del token ni registrar la comisión correspondiente.

Para cada depósito o retirada válida, el saldo disponible de cualquier combinación de usuario y token distinta de la involucrada en la operación debe permanecer exactamente igual antes y después de su ejecución.

$$
\begin{aligned}
&\forall o \in O_{\text{EC01}},\quad
\forall v \in U,\quad
\forall s \in T: \\
&(v,s) \neq (u_o,t_o)
\implies
\Delta B_{\text{disponible}}(v,s,o)=0
\end{aligned}
$$

**Leyenda:**

- $O_{\text{EC01}}$: conjunto de operaciones de depósito y retirada completadas correctamente.
- $U$: conjunto de usuarios registrados en Veyra.
- $T$: conjunto de tokens admitidos por Veyra.
- $o$: operación de depósito o retirada ejecutada.
- $u_o$: usuario que realiza la operación $o$.
- $t_o$: token utilizado en la operación $o$.
- $v$: usuario cuyo saldo se comprueba.
- $s$: token cuyo saldo se comprueba.
- $\Delta B_{\text{disponible}}(v,s,o)$: variación del saldo disponible del usuario $v$ para el token $s$ durante la operación $o$.

### Invariante `INV-06` - Protección de Fondos Bloqueados

En `EC-01`, los depósitos y retiradas no pueden modificar los saldos bloqueados de los usuarios, ya que estos corresponden a fondos comprometidos en otras cadenas económicas. Toda retirada debe realizarse exclusivamente sobre el saldo disponible. Cuando se comparte la custodia, `INV-01` exige además que el respaldo de esos fondos bloqueados permanezca cubierto.

Para cada depósito o retirada válida, los saldos bloqueados permanecen inalterados. Para cada retirada, la disminución del saldo disponible no puede superar el saldo disponible del usuario antes de ejecutar la operación.

$$
\forall o \in O_{\text{EC01}},\quad
\forall u \in U,\quad
\forall t \in T:\quad
\Delta B_{\text{bloqueado}}(u,t,o)=0
$$

$$
\forall r \in R:\quad
0 < A_{\text{bruta}}(r)
\leq
B_{\text{disponible}}^{\text{antes}}(u_r,t_r)
$$

**Leyenda:**

- $O_{\text{EC01}}$: conjunto de operaciones de depósito y retirada completadas correctamente.
- $R$: conjunto de operaciones de retirada completadas correctamente.
- $U$: conjunto de usuarios registrados en Veyra.
- $T$: conjunto de tokens admitidos por Veyra.
- $o$: operación de depósito o retirada ejecutada.
- $r$: operación de retirada ejecutada.
- $u$: usuario cuyo saldo bloqueado se comprueba.
- $t$: token cuyo saldo bloqueado se comprueba.
- $u_r$: usuario que realiza la retirada $r$.
- $t_r$: token utilizado en la retirada $r$.
- $\Delta B_{\text{bloqueado}}(u,t,o)$: variación del saldo bloqueado del usuario $u$ para el token $t$ durante la operación $o$.
- $A_{\text{bruta}}(r)$: importe total solicitado y descontado al usuario durante la retirada $r$, incluida la comisión.
- $B_{\text{disponible}}^{\text{antes}}(u_r,t_r)$: saldo disponible del usuario para el token correspondiente antes de ejecutar la retirada.

### Invariante `INV-07` - Integridad de Depósitos

En `EC-01`, los tokens enviados directamente al contrato fuera del procedimiento de depósito no generan saldos disponibles para ningún usuario. Toda acreditación por depósito en esta cadena debe corresponder a un depósito válido y registrado. La recepción directa tampoco convierte automáticamente esos tokens en ingresos del protocolo.

Para cada transferencia de tokens recibida fuera del procedimiento de depósito, los saldos disponibles de los usuarios, el saldo disponible total y los ingresos contabilizados del protocolo permanecen inalterados.

$$
\forall e \in E_{\text{externas}},\quad
\forall t \in T:\quad
\begin{aligned}
&\forall u \in U:\quad
\Delta B_{\text{disponible}}(u,t,e)=0 \\
&\Delta B_{\text{totalDisponible}}(t,e)=0 \\
&\Delta I_{\text{protocolo}}(t,e)=0
\end{aligned}
$$

**Leyenda:**

- $E_{\text{externas}}$: conjunto de transferencias de tokens recibidas directamente por el contrato fuera del procedimiento autorizado de depósito.
- $U$: conjunto de usuarios registrados en Veyra.
- $T$: conjunto de tokens admitidos por Veyra.
- $e$: transferencia externa de tokens no registrada como depósito.
- $u$: usuario cuyo saldo disponible se comprueba.
- $t$: token admitido cuyo saldo se comprueba.
- $\Delta B_{\text{disponible}}(u,t,e)$: variación del saldo disponible del usuario $u$ para el token $t$ durante la transferencia externa $e$.
- $\Delta B_{\text{totalDisponible}}(t,e)$: variación del saldo disponible total registrado por Veyra para el token $t$ durante la transferencia externa $e$.
- $\Delta I_{\text{protocolo}}(t,e)$: variación del saldo de ingresos del protocolo contabilizado para el token $t$ durante la transferencia externa $e$.

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
