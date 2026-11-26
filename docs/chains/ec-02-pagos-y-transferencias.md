# `EC-02` Pagos y Transferencias

La cadena económica `EC-02` gestiona los pagos y las transferencias entre cuentas de Veyra, el importe recibido y las comisiones aplicables.

## Objetivo

El objetivo de esta cadena es permitir que un usuario transfiera fondos desde su saldo disponible a otra cuenta de Veyra, registrar la operación y contabilizar la comisión correspondiente según el plan vigente del emisor. La operación debe respetar los saldos disponibles y mantener separados los fondos bloqueados y los ingresos del protocolo.

> Tokens permitidos: [tokens](../tokens.md)

La v0.1.0 admite pagos individuales en MockUSD entre cuentas distintas.

## Actores

En esta cadena intervienen los siguientes actores:

- El **emisor** ordena un pago desde su propia cuenta y dispone del saldo necesario para cubrir el cargo que corresponda.
- El **destinatario** recibe el importe que corresponda en su cuenta de Veyra.
- El **contrato de cuentas de Veyra** valida la operación, consulta las condiciones aplicables, actualiza los saldos y registra el pago.
- La cadena de **planes y suscripciones `EC-03`** determina las condiciones del plan vigente del emisor que se usan para calcular la comisión.
- La cadena de **ingresos del protocolo `EC-08`** contabiliza las comisiones cobradas como ingresos separados de los saldos disponibles de los usuarios.
- El **administrador** configura los tokens autorizados conforme a las reglas del protocolo; esta función no le permite ordenar pagos con fondos de otros usuarios ni modificar sus saldos arbitrariamente.

## Variables y Estado Contable

Para cada cuenta y token admitido, Veyra mantiene el saldo disponible compartido con `EC-01`. Un pago utiliza ese saldo del emisor y acredita el importe recibido en el saldo disponible del destinatario para el mismo token.

El total disponible registrado por token debe seguir coincidiendo con la suma de los saldos disponibles individuales, como exige `INV-02` de `EC-01`. En un pago individual completado, ese total disminuye exactamente por la comisión cobrada; si la comisión es cero, no cambia.

En cada operación se identifican el emisor, el destinatario, el token, el importe solicitado, el importe efectivamente recibido y la comisión aplicada. El registro debe permitir relacionar estos datos con la operación ejecutada y con la condición del plan utilizada para calcular la comisión.

Los saldos bloqueados por garantías u otras obligaciones, las participaciones del fondo de liquidez y las deudas son estados asociados que `EC-02` no modifica.

**Reglas contables.** El emisor elige el importe bruto que se descuenta de su saldo.

La comisión cobrada se separa de los saldos disponibles y se registra como ingreso del protocolo en `EC-08`. El importe recibido se acredita al destinatario, no al protocolo.

El pago entre cuentas es un movimiento interno: no constituye un depósito ni una retirada de tokens del contrato de cuentas. Los importes de tokens diferentes no se mezclan ni se convierten entre sí.

El destinatario recibe el bruto menos la comisión del plan del emisor. Se redondea la comisión hacia abajo una vez por pago.

## Flujo Económico

### Flujo de Pago Individual

El emisor ordena un pago individual de MockUSD e indica destinatario y bruto. El protocolo comprueba ambas cuentas, el saldo y la tarifa del plan vigente al ejecutar.

Veyra comprueba que el saldo disponible del emisor cubre el cargo total que resulte de la regla de cobro definida. Si se cumplen las validaciones, reduce el saldo disponible del emisor, acredita al destinatario el importe que corresponda y registra la comisión como ingreso del protocolo.

El registro identifica emisor, destinatario, token, bruto cargado, neto acreditado, plan aplicado y comisión. Este abono puede ser la primera operación del destinatario. El pago conserva íntegros el bloqueo de garantías, la deuda y las participaciones.

### Flujo de Pagos por Lotes

La interfaz de la v0.1.0 admite una instrucción de pago por operación.

Las propiedades de lote se conservan como referencia para una ampliación posterior.

## Validaciones y Restricciones

### Validaciones de Pagos Individuales

- El emisor debe ordenar el pago desde su propia cuenta. El administrador no puede utilizar fondos ajenos por el mero hecho de administrar el protocolo; no se define aquí una facultad de pago por cuenta de terceros.
- El destinatario es distinto de cero y del emisor. Las cuentas se identifican por dirección y el primer abono no requiere alta ni depósito previo.
- El token de pago es MockUSD.
- El importe solicitado debe ser mayor que cero y expresarse en las unidades mínimas del token correspondiente.
- El saldo disponible del emisor debe cubrir el cargo total calculado para la operación. Los fondos bloqueados, las participaciones del fondo y los saldos de terceros no pueden utilizarse para completarlo.
- La comisión debe calcularse con las condiciones del plan vigente del emisor al ejecutar el pago. Si no puede determinarse una configuración válida, la operación se rechaza.
- La comisión debe ser inferior al bruto positivo. El abono neto al destinatario es positivo.
- Los importes calculados y los saldos resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si falla una validación o una actualización necesaria, el pago individual debe revertirse por completo; no deben quedar cargos, abonos, comisiones ni registros definitivos parciales.

### Restricciones del MVP

El cargo total coincide con el bruto solicitado. La [tabla de planes](../economic.md) fija la tarifa. Los lotes, el autopago y los pagos en MockETH quedan fuera del alcance.

## Invariantes y Propiedades

Las siguientes propiedades se refieren exclusivamente a los efectos atribuibles a `EC-02`, para cada token autorizado para la operación. Los cambios de estado se calculan como valor posterior menos valor anterior. Las operaciones de otras cadenas no se atribuyen al pago al evaluar estas expresiones.

El cargo total es el importe solicitado. El abono al destinatario y la comisión suman ese cargo.

### Invariante `INV-01` - Conservación de Fondos

En `EC-02`, un pago individual completado redistribuye saldo disponible entre las cuentas y los ingresos del protocolo para el mismo token. El pago interno no crea ni destruye fondos y no modifica la cantidad de ese token custodiada por el contrato de cuentas.

Para cada pago completado, la variación de la suma de saldos disponibles más la variación de los ingresos retenidos por el protocolo es cero. La variación de la custodia atribuible al pago también es cero.

```math
\forall p \in P:\quad
\sum_{u \in U} \Delta B_{\text{disponible}}(u,t_p,p)
+ \Delta I_{\text{protocolo}}(t_p,p) = 0,
\qquad \Delta B_{\text{contrato}}(t_p,p) = 0
```

**Leyenda:**

- $P$: conjunto de pagos individuales completados correctamente en `EC-02`.
- $U$: conjunto de cuentas de Veyra cuyos saldos disponibles se contabilizan.
- $t_p$: token utilizado en el pago $p$.
- $\Delta B_{\text{disponible}}(u,t_p,p)$: variación del saldo disponible de la cuenta $u$ para ese token atribuible al pago.
- $\Delta I_{\text{protocolo}}(t_p,p)$: variación de los ingresos del protocolo retenidos para ese token atribuible al pago.
- $\Delta B_{\text{contrato}}(t_p,p)$: variación de la custodia de ese token atribuible al pago.

### Invariante `INV-02` - Consistencia de Saldos

En `EC-02`, el cargo realizado al emisor en un pago completado debe corresponder exactamente al importe acreditado al destinatario más la comisión cobrada por el protocolo.

Para cada pago completado, el cargo total al emisor es igual a la suma del abono al destinatario y la comisión.

```math
\forall p \in P:\quad
K_{\text{cargo}}(p) = A_{\text{recibida}}(p) + C_{\text{comision}}(p)
```

**Leyenda:**

- $P$: conjunto de pagos individuales completados correctamente.
- $K_{\text{cargo}}(p)$: importe total cargado al saldo disponible del emisor por el pago $p$.
- $A_{\text{recibida}}(p)$: importe acreditado al saldo disponible del destinatario por el pago $p$.
- $C_{\text{comision}}(p)$: comisión efectivamente cobrada por el protocolo en el pago $p$.

El cargo y el abono son movimientos contables brutos de la operación. Para cuentas emisora y destinataria distintas, sus variaciones reales de saldo y la variación del total disponible deben reflejar esos movimientos:

```math
\forall p \in P:\quad e_p \ne d_p \implies
\Delta B_{\text{disponible}}(e_p,t_p,p)=-K_{\text{cargo}}(p),
\qquad \Delta B_{\text{disponible}}(d_p,t_p,p)=A_{\text{recibida}}(p)
```

```math
\forall p \in P:\quad
\Delta B_{\text{totalDisponible}}(t_p,p)=-C_{\text{comision}}(p)
```

- $e_p$ y $d_p$: cuentas emisora y destinataria del pago $p$.
- $t_p$: token utilizado en el pago $p$.
- $\Delta B_{\text{disponible}}(u,t_p,p)$: variación real del saldo disponible de la cuenta $u$ atribuible al pago.
- $\Delta B_{\text{totalDisponible}}(t_p,p)$: variación del total disponible registrado para el token atribuible al pago.

Un autopago se rechaza antes de modificar el saldo o cobrar la comisión.

### Invariante `INV-03` - Suficiencia de Saldo

El saldo disponible del emisor debe cubrir el bruto solicitado.

Para cada pago completado, el cargo total no puede superar el saldo disponible previo del emisor para el token utilizado.

```math
\forall p \in P:\quad
K_{\text{cargo}}(p) \leq
B_{\text{disponible}}^{\text{antes}}(e_p,t_p)
```

**Leyenda:**

- $P$: conjunto de pagos individuales completados correctamente.
- $e_p$: cuenta emisora del pago $p$.
- $t_p$: token utilizado en el pago $p$.
- $K_{\text{cargo}}(p)$: importe total cargado al emisor por el pago.
- $B_{\text{disponible}}^{\text{antes}}(e_p,t_p)$: saldo disponible del emisor para ese token inmediatamente antes de ejecutar el pago.

### Invariante `INV-04` - Aislamiento de Usuarios

En `EC-02`, un pago completado solo puede afectar los saldos disponibles de las cuentas emisora y destinataria para el token de la operación. Los saldos disponibles de terceros y los saldos de otros tokens permanecen inalterados por ese pago.

Para cada pago completado, toda combinación de cuenta y token distinta de las involucradas conserva su saldo disponible.

```math
\forall p \in P,\quad \forall u \in U,\quad \forall t \in T:\quad
(u,t) \notin \{(e_p,t_p),(d_p,t_p)\}
\implies \Delta B_{\text{disponible}}(u,t,p)=0
```

**Leyenda:**

- $P$: conjunto de pagos individuales completados correctamente.
- $U$: conjunto de cuentas de Veyra.
- $T$: conjunto de tokens admitidos en Veyra.
- $e_p$ y $d_p$: cuentas emisora y destinataria del pago $p$.
- $t_p$: token utilizado en el pago $p$.
- $\Delta B_{\text{disponible}}(u,t,p)$: variación del saldo disponible de la cuenta $u$ para el token $t$ atribuible al pago.

### Invariante `INV-05` - Integridad de Comisiones

En `EC-02`, la comisión de cada pago completado debe calcularse con las condiciones aplicables del plan vigente del emisor y contabilizarse exactamente una vez como ingreso del protocolo en `EC-08`, para el token del pago.

Para cada pago completado, el incremento de ingresos retenidos del protocolo es igual a la comisión calculada y cobrada para esa operación. Una comisión cero no incrementa los ingresos.

```math
\forall p \in P:\quad
\Delta I_{\text{protocolo}}(t_p,p)
= C_{\text{comision}}(p)
= C_{\text{vigente}}(p)
```

**Leyenda:**

- $P$: conjunto de pagos individuales completados correctamente.
- $t_p$: token utilizado en el pago $p$.
- $\Delta I_{\text{protocolo}}(t_p,p)$: incremento de ingresos retenidos del protocolo para ese token atribuible al pago.
- $C_{\text{comision}}(p)$: comisión efectivamente cobrada por el pago.
- $C_{\text{vigente}}(p)$: comisión calculada con el plan vigente al ejecutar el pago y las reglas aplicables de `EC-03`.

La comisión es la parte entera de bruto × tarifa del plan / 10 000.

### Invariante `INV-06` - Atomicidad de Pagos

En `EC-02`, si un pago individual falla, ninguno de sus cambios provisionales puede permanecer. Esto incluye cargos, abonos, ingresos y registros definitivos de la operación.

Para cada intento fallido, el estado afectado por ese intento debe ser igual al estado inmediatamente anterior, sin efectos parciales atribuibles a él.

```math
\forall f \in F:\quad
S_{\text{despues}}(f) = S_{\text{antes}}(f)
```

**Leyenda:**

- $F$: conjunto de intentos de pago individual fallidos o rechazados.
- $S_{\text{antes}}(f)$: estado contable y registros de `EC-02` afectados por el intento inmediatamente antes de su ejecución.
- $S_{\text{despues}}(f)$: esos mismos estados y registros después del intento, considerando sus efectos atribuibles.

La transacción individual revierte todos sus efectos ante cualquier fallo.

### Invariante `INV-07` - Protección de Fondos Bloqueados

En `EC-02`, un pago no puede utilizar ni modificar fondos bloqueados por garantías u otras obligaciones. El cargo debe cubrirse exclusivamente con el saldo disponible del emisor.

Para cada pago completado, todos los saldos bloqueados permanecen inalterados y el cargo no supera el saldo disponible previo del emisor.

```math
\forall p \in P,\quad \forall u \in U,\quad \forall t \in T:\quad
\Delta B_{\text{bloqueado}}(u,t,p)=0
```

```math
\forall p \in P:\quad
K_{\text{cargo}}(p) \leq
B_{\text{disponible}}^{\text{antes}}(e_p,t_p)
```

**Leyenda:**

- $P$: conjunto de pagos individuales completados correctamente.
- $U$: conjunto de cuentas de Veyra.
- $T$: conjunto de tokens admitidos en Veyra.
- $e_p$ y $t_p$: emisor y token del pago $p$.
- $\Delta B_{\text{bloqueado}}(u,t,p)$: variación del saldo bloqueado de la cuenta $u$ para el token $t$ atribuible al pago.
- $K_{\text{cargo}}(p)$: importe total cargado al saldo disponible del emisor.
- $B_{\text{disponible}}^{\text{antes}}(e_p,t_p)$: saldo disponible del emisor para ese token inmediatamente antes del pago.

### Invariante `INV-08` - Consistencia de Pagos por Lotes

Si se incorporan pagos por lotes a `EC-02`, los importes completados deberán conservarse para cada token. El cargo total efectivamente aplicado al emisor debe corresponder a los importes acreditados y a las comisiones efectivamente cobradas, sin contar dos veces ninguna comisión.

Esta propiedad describe la suma de movimientos efectivos por token en una futura versión que habilite lotes.

```math
\forall l \in L,\quad \forall t \in T:\quad
K_{\text{total}}(l,t)
= \sum_{p \in P_{l,t}} A_{\text{recibida}}(p)
+ C_{\text{total}}(l,t)
```

**Leyenda:**

- $L$: conjunto de lotes procesados, únicamente si esta funcionalidad se incorpora.
- $T$: conjunto de tokens admitidos en Veyra.
- $P_{l,t}$: conjunto de pagos completados del lote $l$ que utilizan el token $t$.
- $K_{\text{total}}(l,t)$: suma de los cargos definitivos al emisor atribuibles al lote $l$ para el token $t$.
- $A_{\text{recibida}}(p)$: importe acreditado al destinatario por el pago completado $p$.
- $C_{\text{total}}(l,t)$: comisiones definitivas del lote por token en esa extensión.

En v0.1.0 el conjunto de lotes completados es vacío. INV-08 queda reservada para una ampliación.

## Casos Límite y Escenarios de Fallo

Los siguientes casos son una referencia para las futuras pruebas de `EC-02`. En cada pago individual rechazado o fallido se revierten sus efectos, incluidos cargos, abonos, comisiones y registros definitivos. Las referencias a `EC-03` y `EC-08` identifican dependencias del pago; no amplían estos casos a los flujos propios de esas cadenas.

Los importes se expresan en unidades mínimas de MockUSD.

### Autorización, Destinatario y Token

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Un usuario intenta pagar desde su propia cuenta. | Puede completarse si reúne todas las condiciones; el cargo se efectúa sobre su saldo disponible. | Validaciones, `INV-03` |
| `CL-02` | Un usuario o el administrador intenta ordenar un pago con fondos de otra cuenta. | Se rechaza sin cargo, abono, comisión ni registro definitivo. Administrar el protocolo no concede acceso a fondos ajenos y esta cadena no define pagos por cuenta de terceros. | Validaciones, `INV-04`, `INV-06` |
| `CL-03` | El destinatario no puede identificarse válidamente. | Se rechaza el pago sin efectos contables definitivos; no se abona a una cuenta distinta de la prevista. | Validaciones, `INV-04`, `INV-06` |
| `CL-04` | El destinatario todavía no existe o no está registrado. | Se permite el primer abono a una dirección válida y distinta del emisor. | Validaciones, `INV-02`, `INV-06` |
| `CL-05` | El emisor indica su propia cuenta como destinatario. | Se rechaza sin cargo ni comisión. | `INV-01`–`INV-03`, `INV-05`, `INV-06` |
| `CL-06` | Se utiliza un token no autorizado para pagos, incluso si comparte nombre o símbolo con uno autorizado. | Se rechaza sin efectos. La comprobación identifica el token por su dirección y autorización aplicable. | Validaciones, `INV-06` |
| `CL-07` | Se solicita pagar con MockETH. | Se rechaza. Los pagos internos utilizan MockUSD. | Validaciones, `INV-01`, `INV-06` |
| `CL-08` | Emisor y destinatario mantienen saldos en varios tokens, incluido otro token autorizado que no participa en el pago. | Solo pueden cambiar los saldos de las partes para el token utilizado y los ingresos correspondientes a ese token. No hay conversión ni mezcla entre tokens. | `INV-01`, `INV-04`, `INV-05` |

### Importe, Saldo y Conservación

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-09` | El importe solicitado es cero. | Se rechaza sin cambios definitivos. | Validaciones, `INV-06` |
| `CL-10` | El importe solicitado es una unidad mínima del token. | Un bruto de una unidad genera comisión cero y acredita una unidad. | `INV-01`–`INV-03`, `INV-05` |
| `CL-11` | El cargo total es una unidad menor que el saldo disponible previo. | Supera la comprobación de saldo. Si el pago se completa, queda una unidad disponible en el emisor, siempre que emisor y destinatario sean cuentas distintas. | `INV-02`, `INV-03` |
| `CL-12` | El cargo total coincide con el saldo disponible previo. | Supera la comprobación de saldo. Si se completa entre cuentas distintas, el saldo disponible del emisor queda a cero; se cumplen también las demás validaciones. | `INV-02`, `INV-03` |
| `CL-13` | El cargo total supera el saldo disponible previo en una unidad mínima o más. | Se rechaza el pago completo sin utilizar saldos bloqueados ni fondos ajenos. | `INV-03`, `INV-06`, `INV-07` |
| `CL-14` | El saldo disponible del emisor es cero, aunque tenga fondos bloqueados o participaciones del fondo. | Ningún cargo positivo puede cubrirse con esos fondos; el intento se rechaza. | `INV-03`, `INV-06`, `INV-07` |
| `CL-15` | Se intenta sumar la comisión una segunda vez al bruto que cubre el saldo. | El cargo correcto es exactamente el bruto. Un cargo superior incumple la conservación del pago. | `INV-03`, `INV-06` |
| `CL-16` | El destinatario no tiene saldo previo del token o ya tiene un saldo positivo. | Si el pago se completa, se acredita exactamente el importe recibido sobre el saldo previo, sin modificar sus otros tokens. | `INV-01`, `INV-02`, `INV-04` |
| `CL-17` | Existe un solo usuario con saldo disponible, o varios usuarios comparten saldo del mismo token. | En un pago completado entre cuentas válidas, la suma de las variaciones de todos los saldos disponibles más el ingreso cobrado es cero. Los saldos de terceros permanecen iguales. | `INV-01`, `INV-04`, `INV-05` |
| `CL-18` | Hay ingresos retenidos o un excedente de custodia antes del pago. | El pago no usa el excedente ni atribuye ingresos previos al pago. La custodia no cambia; la variación de ingresos es solo la comisión de la operación. | `INV-01`, `INV-05` |
| `CL-19` | El producto de bruto por tarifa excede 256 bits, o un saldo resultante rebasa su máximo. | El primer caso usa el cociente entero exacto. Un saldo final fuera de rango revierte todo el pago. | Validaciones, `INV-01`, `INV-02`, `INV-06` |
| `CL-20` | La contabilidad previa de saldos, ingresos o respaldo ya es inconsistente. | La comprobación debe identificar el incumplimiento de la propiedad correspondiente; un intento rechazado no produce cambios parciales. EC-02 no define aquí cómo reparar ese estado ni establece que cada operación detecte cualquier inconsistencia previa. | `INV-01`, `INV-02`, `INV-06` |

### Comisiones y Plan Vigente

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-21` | La comisión calculada es cero. | Si el pago se completa, el cargo coincide con el abono y los ingresos del protocolo no aumentan. | `INV-01`, `INV-02`, `INV-05` |
| `CL-22` | La comisión calculada es positiva. | Si el pago se completa, se registra exactamente una vez para el token utilizado y el cargo es igual al abono más esa comisión. | `INV-01`, `INV-02`, `INV-05` |
| `CL-23` | La comisión es una unidad mínima o el cálculo produce una fracción de unidad. | Se redondea hacia abajo y se registra exactamente el importe cobrado. | `INV-02`, `INV-05` |
| `CL-24` | La comisión calculada es igual al importe solicitado. | Se rechaza el resultado. Las tarifas del MVP dejan un abono positivo. | `INV-01`, `INV-02`, `INV-05`, `INV-06` |
| `CL-25` | La comisión calculada supera el importe solicitado. | Se rechaza sin efectuar el pago. | `INV-01`, `INV-02`, `INV-05`, `INV-06` |
| `CL-26` | El emisor ordena un pago bruto con comisión positiva. | Se carga el bruto y se acredita el bruto menos la comisión. | `INV-02`, `INV-03`, `INV-05` |
| `CL-27` | El cálculo intenta añadir la comisión al bruto solicitado. | La operación no puede cargar ese exceso. El único cargo autorizado es el bruto. | `INV-02`, `INV-03`, `INV-05` |
| `CL-28` | El plan cambia o caduca antes de ejecutarse el pago. | Se utiliza el plan vigente en el momento de ejecución. Si no puede determinarse una configuración válida, se rechaza sin efectos parciales. | `INV-05`, `INV-06` |
| `CL-29` | Se completan varios pagos con comisiones del mismo token. | Los ingresos aumentan por la suma de las comisiones efectivamente cobradas, cada una una sola vez; no se atribuyen ingresos a otro token. | `INV-01`, `INV-05` |
| `CL-30` | Una misma cantidad se paga mediante varias operaciones pequeñas. | Cada pago aplica el cálculo y redondeo vigentes para esa operación y conserva su propio cargo. No se presupone que sus comisiones sumen lo mismo que la comisión de un único pago. | `INV-02`, `INV-05` |

### Aislamiento, Atomicidad y Fondos Bloqueados

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-31` | Existe un tercer usuario con saldo del mismo token que el pago. | Su saldo disponible y sus fondos bloqueados permanecen inalterados por el pago. | `INV-04`, `INV-07` |
| `CL-32` | El emisor, el destinatario o un tercero tienen fondos bloqueados del token utilizado. | El pago no modifica esos bloqueos y el cargo se cubre solo con el saldo disponible previo del emisor. | `INV-03`, `INV-07` |
| `CL-33` | Existen fondos bloqueados, participaciones o deudas en otro token. | El pago no modifica esos estados ni utiliza esos recursos para financiar el cargo. | `INV-04`, `INV-07` |
| `CL-34` | Falla la validación antes de cualquier actualización contable. | El estado afectado y los registros definitivos quedan como antes del intento. | `INV-06` |
| `CL-35` | Una actualización falla después de calcular la comisión o de un cargo provisional al emisor. | Se revierte el intento completo; no permanecen el cargo ni la comisión. | `INV-02`, `INV-05`, `INV-06` |
| `CL-36` | Una actualización falla después de un abono provisional al destinatario o del registro provisional del ingreso. | Se revierten todos los efectos del intento, incluidos cargo, abono, ingreso y registro definitivo. | `INV-01`, `INV-05`, `INV-06` |
| `CL-37` | No se puede completar el registro necesario del pago tras cambios contables provisionales. | Se revierte el pago completo; no se conserva un pago contable sin su registro definitivo ni un registro de pago completado sin sus movimientos. | `INV-06` |
| `CL-38` | Una llamada anidada o repetida intenta gastar el mismo saldo disponible. | Cada pago que se complete debe estar autorizado y cubrirse con el saldo que le corresponda inmediatamente antes de ejecutarse. Si no puede evitarse un doble gasto o contabilización duplicada, se revierte el intento afectado. | `INV-01`–`INV-03`, `INV-06` |
| `CL-39` | Se realizan dos instrucciones independientes con los mismos datos de emisor, destinatario, token e importe. | Son dos operaciones independientes. Cada pago válido genera sus propios movimientos y su propio registro. | `INV-02`, `INV-03`, `INV-05` |
| `CL-40` | Una secuencia mezcla pagos completados y rechazados entre varias cuentas. | Tras cada pago completado se comprueban las invariantes aplicables; cada intento fallido conserva el estado inmediatamente anterior a ese intento, incluidos los resultados de operaciones previas válidas. | `INV-01`–`INV-07` |

### Pagos por Lotes Condicionales

CL-41 a CL-53 conservan el diseño de pruebas para una ampliación. En v0.1.0 cualquier solicitud por lote queda fuera de la interfaz y no produce movimientos.

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-41` | Se presenta un lote vacío o uno que supera el tamaño permitido. | La interfaz excluye los lotes de cualquier tamaño. El intento no produce cargos ni ingresos. | `INV-06`, `INV-08` |
| `CL-42` | Un lote contiene un solo pago. | Incluso con un solo elemento, el formato de lote queda fuera del MVP. El pago individual tiene su propia entrada. | `INV-01`–`INV-03`, `INV-05`, `INV-08` |
| `CL-43` | Un lote contiene varios pagos válidos a destinatarios distintos. | El lote no se ejecuta. Los pagos individuales requieren operaciones independientes. | `INV-04`, `INV-08` |
| `CL-44` | Un destinatario aparece más de una vez. | La repetición del destinatario no habilita un lote. El intento deja sus saldos intactos. | `INV-02`, `INV-05`, `INV-08` |
| `CL-45` | Un lote contiene pagos en distintos tokens. | La operación por lote se excluye para cualquier combinación de tokens. | `INV-04`, `INV-05`, `INV-08` |
| `CL-46` | Cada pago por separado parece cubrirse, pero la suma de los cargos definitivos excede el saldo disponible del emisor. | No se evalúa ni consume saldo agregado de lote. | `INV-03`, `INV-07`, `INV-08` |
| `CL-47` | El saldo disponible inicial cubre exactamente el total de cargos previstos del lote, o queda una unidad por debajo. | La suficiencia del saldo agregado no habilita la operación por lote. | `INV-03`, `INV-08` |
| `CL-48` | Una instrucción es inválida y se adopta una política de lote atómico. | El MVP carece de ejecución de lote. No se ejecuta ninguna instrucción. | `INV-06`, `INV-08` |
| `CL-49` | Una instrucción falla y se adopta una política de resultados parciales. | La interfaz excluye los resultados parciales de un lote. Ninguna instrucción se confirma por esta vía. | `INV-06`, `INV-08` |
| `CL-50` | Fallan todas las instrucciones del lote. | El intento de lote deja saldos y comisiones sin cambios. | `INV-06`, `INV-08` |
| `CL-51` | El lote tiene una comisión por instrucción, una comisión de lote o ambas, si se definen. | No existen cargos ni comisiones de lote. | `INV-05`, `INV-08` |
| `CL-52` | La suma de cargos, abonos o comisiones del lote excedería el rango representable. | El intento no llega a calcular importes agregados de lote. | `INV-06`, `INV-08` |
| `CL-53` | Una instrucción posterior falla después de actualizaciones provisionales en el lote. | Ninguna instrucción de un lote puede producir cambios definitivos en el MVP. | `INV-06`, `INV-08` |

### Criterio de Cobertura

En v0.1.0 verificar INV-01 a INV-07 con cuentas distintas, saldos límite y secuencias de éxito y fallo. Verificar por separado que la interfaz no permite ejecutar lotes.

Esta matriz enumera clases de límites y fallos identificadas para `EC-02`; no demuestra que se hayan enumerado todas las secuencias posibles ni sustituye las pruebas o una verificación formal. Los estados inconsistentes son escenarios de detección de fallos, no estados que la cadena garantice reparar.
