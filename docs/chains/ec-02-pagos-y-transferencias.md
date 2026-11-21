# `EC-02` Pagos y Transferencias

La cadena económica `EC-02` gestiona los pagos y las transferencias entre cuentas de Veyra, el importe recibido y las comisiones aplicables.

## Objetivo

El objetivo de esta cadena es permitir que un usuario transfiera fondos desde su saldo disponible a otra cuenta de Veyra, registrar la operación y contabilizar la comisión correspondiente según el plan vigente del emisor. La operación debe respetar los saldos disponibles y mantener separados los fondos bloqueados y los ingresos del protocolo.

> Tokens permitidos: [tokens](../tokens.md)

El README de `v0.1.0` incluye pagos individuales entre cuentas. `economic.md` también menciona pagos por lotes; su inclusión en el MVP y sus reglas concretas están pendientes de definición.

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

**Reglas contables:** El cargo al emisor, el importe acreditado al destinatario y la comisión deben guardar la relación que establezca la regla de cobro finalmente definida.

La comisión cobrada se separa de los saldos disponibles y se registra como ingreso del protocolo en `EC-08`. El importe recibido se acredita al destinatario, no al protocolo.

El pago entre cuentas es un movimiento interno: no constituye un depósito ni una retirada de tokens del contrato de cuentas. Los importes de tokens diferentes no se mezclan ni se convierten entre sí.

Queda pendiente decidir si el importe solicitado incluye la comisión o si esta se añade al importe enviado. Hasta que se decida, no se fija una fórmula para el cargo ni para el importe recibido.

## Flujo Económico

### Flujo de Pago Individual

El emisor ordena un pago a una cuenta destinataria e indica el token y el importe solicitado. Veyra identifica a las partes, comprueba que el token y la operación cumplen las condiciones aplicables y consulta el plan vigente del emisor para calcular la comisión.

Veyra comprueba que el saldo disponible del emisor cubre el cargo total que resulte de la regla de cobro definida. Si se cumplen las validaciones, reduce el saldo disponible del emisor, acredita al destinatario el importe que corresponda y registra la comisión como ingreso del protocolo.

La operación queda registrada con los datos necesarios para identificar el pago, el importe recibido y la comisión. El pago no modifica saldos bloqueados, deudas ni participaciones del fondo.

### Flujo de Pagos por Lotes

Un pago por lote agruparía varias instrucciones de pago de un emisor. Antes de incorporarlo al alcance de `v0.1.0` deben definirse su disponibilidad, la forma de calcular el cargo y la comisión, sus límites y el tratamiento de los fallos.

Hasta que esas reglas se concreten, esta cadena no presupone que un lote se ejecute de forma atómica ni que permita ejecuciones parciales. Cada pago que llegue a completarse deberá respetar las reglas contables y de autorización que le sean aplicables.

## Validaciones y Restricciones

### Validaciones de Pagos Individuales

- El emisor debe ordenar el pago desde su propia cuenta. El administrador no puede utilizar fondos ajenos por el mero hecho de administrar el protocolo; no se define aquí una facultad de pago por cuenta de terceros.
- El destinatario debe identificarse de forma válida para que el importe se acredite a la cuenta prevista. Los requisitos concretos de registro o existencia previa de la cuenta están pendientes de definición.
- El token debe estar autorizado para la operación. `tokens.md` identifica **MockUSD** para pagos y **MockETH** principalmente para garantías; la admisión concreta de MockETH en pagos queda pendiente de definición.
- El importe solicitado debe ser mayor que cero y expresarse en las unidades mínimas del token correspondiente.
- El saldo disponible del emisor debe cubrir el cargo total calculado para la operación. Los fondos bloqueados, las participaciones del fondo y los saldos de terceros no pueden utilizarse para completarlo.
- La comisión debe calcularse con las condiciones del plan vigente del emisor al ejecutar el pago. Si no puede determinarse una configuración válida, la operación se rechaza.
- El cargo, el importe acreditado y la comisión son importes enteros no negativos del mismo token. Su relación debe cumplir `INV-02`; las condiciones adicionales sobre un abono cero y los límites de comisión siguen pendientes.
- Los importes calculados y los saldos resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si falla una validación o una actualización necesaria, el pago individual debe revertirse por completo; no deben quedar cargos, abonos, comisiones ni registros definitivos parciales.

### Restricciones Pendientes de Definición

- Si la comisión se descuenta del importe solicitado o se añade a él; las tasas, el redondeo, sus límites y la admisibilidad de un abono cero que correspondan según `EC-03`.
- Si se permiten pagos a la propia cuenta y qué comportamiento contable y comisión tendrían.
- Los requisitos concretos de identificación, existencia y registro del destinatario.
- La inclusión de pagos por lotes en `v0.1.0`, su tamaño máximo, el tratamiento de destinatarios repetidos, el cálculo de comisiones y si un fallo revierte el lote o permite resultados parciales.
- Si **MockETH**, además de **MockUSD**, puede utilizarse para pagos en esta versión.

Estas decisiones deben concretarse antes de implementar los comportamientos que dependen de ellas y antes de formular invariantes o casos límite que presupongan una opción.

## Invariantes y Propiedades

Las siguientes propiedades se refieren exclusivamente a los efectos atribuibles a `EC-02`, para cada token autorizado para la operación. Los cambios de estado se calculan como valor posterior menos valor anterior. Las operaciones de otras cadenas no se atribuyen al pago al evaluar estas expresiones.

Las fórmulas usan el **cargo total**, el **importe acreditado** y la **comisión cobrada**. Estos valores no deciden si la comisión se incluye en el importe solicitado o se añade a él. La disponibilidad de pagos por lotes y el tratamiento de pagos a la propia cuenta siguen pendientes de definición.

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

Para cada pago completado, el cargo total al emisor es igual a la suma del abono al destinatario y la comisión. Esta relación es válida tanto si la futura regla incluye la comisión en el importe solicitado como si la añade.

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

Si en el futuro se admiten pagos a la propia cuenta, habrá que definir su tratamiento. En ese caso, la variación neta de esa cuenta sería el abono menos el cargo, no el cargo bruto; el total disponible seguiría disminuyendo por la comisión.

### Invariante `INV-03` - Suficiencia de Saldo

En `EC-02`, un pago solo puede completarse si el saldo disponible del emisor antes de ejecutarlo cubre el cargo total. El cargo incluye la comisión cuando corresponda según la regla de cobro que se defina.

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

Las tasas y el redondeo siguen pendientes de definición; esta propiedad no fija sus valores ni determina si la comisión se incluye en el importe solicitado.

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

Esta propiedad se aplica al pago individual. No decide si un eventual lote fallido revierte todas sus instrucciones o permite resultados parciales.

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

Para cada lote y token, la suma de cargos efectivos es igual a la suma de importes acreditados en pagos completados más todas las comisiones efectivamente cobradas por el lote en ese token. Los pagos no completados no aportan cargos, abonos ni comisiones propias definitivas. Una posible comisión independiente del lote sigue pendiente de definición y, si se permite, se contabiliza por separado.

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
- $C_{\text{total}}(l,t)$: suma de todas las comisiones definitivas cobradas por el lote para ese token, contabilizadas una sola vez, incluidas las que se definan a nivel de lote si las hubiera.

Esta propiedad es condicional y no incorpora los lotes al MVP ni decide sus límites, su estructura de comisiones o su política ante fallos. Si se permiten resultados parciales, la igualdad se evalúa sobre los efectos definitivos; si el lote se revierte íntegramente, esos efectos son cero.

## Casos Límite y Escenarios de Fallo

Los siguientes casos son una referencia para las futuras pruebas de `EC-02`. En cada pago individual rechazado o fallido se revierten sus efectos, incluidos cargos, abonos, comisiones y registros definitivos. Las referencias a `EC-03` y `EC-08` identifican dependencias del pago; no amplían estos casos a los flujos propios de esas cadenas.

Los importes se expresan en unidades mínimas del token utilizado. Cuando un caso depende de una regla pendiente, se describen las condiciones que deben mantenerse sin elegir anticipadamente esa regla. Las referencias `INV-01` a `INV-08` corresponden a las invariantes de este documento.

### Autorización, Destinatario y Token

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Un usuario intenta pagar desde su propia cuenta. | Puede completarse si reúne todas las condiciones; el cargo se efectúa sobre su saldo disponible. | Validaciones, `INV-03` |
| `CL-02` | Un usuario o el administrador intenta ordenar un pago con fondos de otra cuenta. | Se rechaza sin cargo, abono, comisión ni registro definitivo. Administrar el protocolo no concede acceso a fondos ajenos y esta cadena no define pagos por cuenta de terceros. | Validaciones, `INV-04`, `INV-06` |
| `CL-03` | El destinatario no puede identificarse válidamente. | Se rechaza el pago sin efectos contables definitivos; no se abona a una cuenta distinta de la prevista. | Validaciones, `INV-04`, `INV-06` |
| `CL-04` | El destinatario todavía no existe o no está registrado. | Pendiente de la regla de existencia y registro. Si la regla lo admite, el abono debe llegar a la cuenta prevista; si lo rechaza, no quedan efectos parciales. | Validaciones, `INV-02`, `INV-06` |
| `CL-05` | El emisor indica su propia cuenta como destinatario. | Pendiente de decidir si se permite. Si se rechaza, no hay efectos; si se permite, deben definirse sus movimientos y comisión, respetando el cargo bruto, el abono y las invariantes aplicables. | `INV-01`–`INV-03`, `INV-05`, `INV-06` |
| `CL-06` | Se utiliza un token no autorizado para pagos, incluso si comparte nombre o símbolo con uno autorizado. | Se rechaza sin efectos. La comprobación identifica el token por su dirección y autorización aplicable. | Validaciones, `INV-06` |
| `CL-07` | Se solicita pagar con MockETH. | Su admisión para pagos está pendiente. Si se autoriza, se aplican las mismas propiedades por token y sus propias unidades mínimas; si no se autoriza, se rechaza sin efectos. | Validaciones, `INV-01`, `INV-06` |
| `CL-08` | Emisor y destinatario mantienen saldos en varios tokens, incluido otro token autorizado que no participa en el pago. | Solo pueden cambiar los saldos de las partes para el token utilizado y los ingresos correspondientes a ese token. No hay conversión ni mezcla entre tokens. | `INV-01`, `INV-04`, `INV-05` |

### Importe, Saldo y Conservación

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-09` | El importe solicitado es cero. | Se rechaza sin cambios definitivos. | Validaciones, `INV-06` |
| `CL-10` | El importe solicitado es una unidad mínima del token. | Se aplican la comisión y el redondeo que se definan. Si el pago es válido, el cargo equivale exactamente al abono más la comisión; si no cumple una condición, se rechaza. | `INV-01`–`INV-03`, `INV-05` |
| `CL-11` | El cargo total es una unidad menor que el saldo disponible previo. | Supera la comprobación de saldo. Si el pago se completa, queda una unidad disponible en el emisor, siempre que emisor y destinatario sean cuentas distintas. | `INV-02`, `INV-03` |
| `CL-12` | El cargo total coincide con el saldo disponible previo. | Supera la comprobación de saldo. Si se completa entre cuentas distintas, el saldo disponible del emisor queda a cero; se cumplen también las demás validaciones. | `INV-02`, `INV-03` |
| `CL-13` | El cargo total supera el saldo disponible previo en una unidad mínima o más. | Se rechaza el pago completo sin utilizar saldos bloqueados ni fondos ajenos. | `INV-03`, `INV-06`, `INV-07` |
| `CL-14` | El saldo disponible del emisor es cero, aunque tenga fondos bloqueados o participaciones del fondo. | Ningún cargo positivo puede cubrirse con esos fondos; el intento se rechaza. | `INV-03`, `INV-06`, `INV-07` |
| `CL-15` | El importe solicitado cabe en el saldo, pero el cargo total no cabe después de calcular la comisión. | Se rechaza el pago. La suficiencia se comprueba sobre el cargo total conforme a la regla de cobro que se defina. | `INV-03`, `INV-06` |
| `CL-16` | El destinatario no tiene saldo previo del token o ya tiene un saldo positivo. | Si el pago se completa, se acredita exactamente el importe recibido sobre el saldo previo, sin modificar sus otros tokens. | `INV-01`, `INV-02`, `INV-04` |
| `CL-17` | Existe un solo usuario con saldo disponible, o varios usuarios comparten saldo del mismo token. | En un pago completado entre cuentas válidas, la suma de las variaciones de todos los saldos disponibles más el ingreso cobrado es cero. Los saldos de terceros permanecen iguales. | `INV-01`, `INV-04`, `INV-05` |
| `CL-18` | Hay ingresos retenidos o un excedente de custodia antes del pago. | El pago no usa el excedente ni atribuye ingresos previos al pago. La custodia no cambia; la variación de ingresos es solo la comisión de la operación. | `INV-01`, `INV-05` |
| `CL-19` | El cargo, el abono, los ingresos o una operación intermedia alcanzan el máximo representable o lo excederían. | Si todos los resultados exactos caben y se cumplen las demás condiciones, puede completarse; si alguno no cabe, se revierte todo el pago sin truncamiento ni desbordamiento. | Validaciones, `INV-01`, `INV-02`, `INV-06` |
| `CL-20` | La contabilidad previa de saldos, ingresos o respaldo ya es inconsistente. | La comprobación debe identificar el incumplimiento de la propiedad correspondiente; un intento rechazado no produce cambios parciales. EC-02 no define aquí cómo reparar ese estado ni establece que cada operación detecte cualquier inconsistencia previa. | `INV-01`, `INV-02`, `INV-06` |

### Comisiones y Plan Vigente

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-21` | La comisión calculada es cero. | Si el pago se completa, el cargo coincide con el abono y los ingresos del protocolo no aumentan. | `INV-01`, `INV-02`, `INV-05` |
| `CL-22` | La comisión calculada es positiva. | Si el pago se completa, se registra exactamente una vez para el token utilizado y el cargo es igual al abono más esa comisión. | `INV-01`, `INV-02`, `INV-05` |
| `CL-23` | La comisión es una unidad mínima o el cálculo produce una fracción de unidad. | Se aplica la regla entera de redondeo que se defina en `EC-03`; el importe cobrado y el registrado coinciden exactamente. No se fija aquí el sentido del redondeo. | `INV-02`, `INV-05` |
| `CL-24` | La comisión calculada es igual al importe solicitado. | Su admisibilidad y el abono resultante dependen de la regla de cobro y de los límites pendientes. Si se permite, se cumplen las relaciones de conservación; si no, se rechaza sin efectos. | `INV-01`, `INV-02`, `INV-05`, `INV-06` |
| `CL-25` | La comisión calculada supera el importe solicitado. | No se presupone que sea válida o inválida: debe aplicarse el límite y la regla de cobro que se definan. No se permite un abono negativo ni una operación que incumpla la conservación. | `INV-01`, `INV-02`, `INV-05`, `INV-06` |
| `CL-26` | La regla finalmente incluye la comisión en el importe solicitado. | Condicional a esa decisión: el cargo, el abono y la comisión deben seguir la regla adoptada y satisfacer cargo igual a abono más comisión; el saldo debe cubrir el cargo. | `INV-02`, `INV-03`, `INV-05` |
| `CL-27` | La regla finalmente añade la comisión al importe solicitado. | Condicional a esa decisión: el cargo, el abono y la comisión deben seguir la regla adoptada y satisfacer cargo igual a abono más comisión; el saldo debe cubrir el cargo completo. | `INV-02`, `INV-03`, `INV-05` |
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
| `CL-39` | Se realizan dos instrucciones independientes con los mismos datos de emisor, destinatario, token e importe. | Cada operación que se complete debe estar autorizada, contar con saldo suficiente y contabilizarse por separado. No se presupone una regla de deduplicación o identificador de solicitud que aún no está definida. | `INV-02`, `INV-03`, `INV-05` |
| `CL-40` | Una secuencia mezcla pagos completados y rechazados entre varias cuentas. | Tras cada pago completado se comprueban las invariantes aplicables; cada intento fallido conserva el estado inmediatamente anterior a ese intento, incluidos los resultados de operaciones previas válidas. | `INV-01`–`INV-07` |

### Pagos por Lotes Condicionales

Los siguientes casos solo se aplican si los lotes se incorporan a `EC-02`. No fijan su inclusión en `v0.1.0`, tamaño, estructura de comisiones ni política de fallos.

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-41` | Se presenta un lote vacío o uno que supera el tamaño permitido. | Pendiente de definir los límites. Si se rechaza, no hay efectos definitivos; si se permite algún caso, sus cargos e ingresos deben respetar la regla de lote y `INV-08`. | `INV-06`, `INV-08` |
| `CL-42` | Un lote contiene un solo pago. | Si el lote se admite, el pago debe cumplir las invariantes individuales y el total del lote debe incluir todos los cargos y comisiones definitivos aplicables. | `INV-01`–`INV-03`, `INV-05`, `INV-08` |
| `CL-43` | Un lote contiene varios pagos válidos a destinatarios distintos. | Los importes efectivamente acreditados y las comisiones definitivas suman el cargo total del lote para cada token. Los saldos de terceros ajenos no cambian por esas instrucciones. | `INV-04`, `INV-08` |
| `CL-44` | Un destinatario aparece más de una vez. | Su admisibilidad está pendiente. Si se permite, se contabiliza cada instrucción completada una sola vez y el total refleja todos sus abonos y comisiones definitivos. | `INV-02`, `INV-05`, `INV-08` |
| `CL-45` | Un lote contiene pagos en distintos tokens. | Su admisibilidad está pendiente. Si se permite, el cargo, los abonos y las comisiones se comprueban por separado para cada token, sin conversión ni mezcla de unidades. | `INV-04`, `INV-05`, `INV-08` |
| `CL-46` | Cada pago por separado parece cubrirse, pero la suma de los cargos definitivos excede el saldo disponible del emisor. | No puede gastarse dos veces el mismo saldo. El resultado del lote depende de la política pendiente; cada pago completado debe tener saldo suficiente y el total definitivo debe conservarse. | `INV-03`, `INV-07`, `INV-08` |
| `CL-47` | El saldo disponible inicial cubre exactamente el total de cargos previstos del lote, o queda una unidad por debajo. | Si se exige cobertura previa del total, la igualdad supera esa comprobación y una unidad por debajo no. La comprobación agregada y el tratamiento de fallos están pendientes; en cualquier caso, cada cargo aplicado debe respetar el saldo disponible que le corresponda y no puede producir doble gasto. | `INV-03`, `INV-08` |
| `CL-48` | Una instrucción es inválida y se adopta una política de lote atómico. | Condicional a esa política: se revierte el lote íntegro y no quedan cargos, abonos, comisiones ni registros definitivos del lote. | `INV-06`, `INV-08` |
| `CL-49` | Una instrucción falla y se adopta una política de resultados parciales. | Condicional a esa política: la instrucción fallida no deja efectos parciales; los efectos definitivos de las completadas y las comisiones de lote permitidas deben satisfacer `INV-08`. | `INV-06`, `INV-08` |
| `CL-50` | Fallan todas las instrucciones del lote. | Ningún pago fallido deja cargo, abono ni comisión propia. La posibilidad de una comisión de lote independiente está pendiente; cualquier efecto definitivo permitido debe cumplir `INV-08` y la política que se defina. | `INV-06`, `INV-08` |
| `CL-51` | El lote tiene una comisión por instrucción, una comisión de lote o ambas, si se definen. | Cada comisión definitiva se cuenta una sola vez y para el token correspondiente; la suma de abonos y comisiones debe igualar el total cargado. | `INV-05`, `INV-08` |
| `CL-52` | La suma de cargos, abonos o comisiones del lote excedería el rango representable. | No se admite truncamiento ni desbordamiento. La reversión total o el tratamiento de instrucciones previas depende de la política de fallos; los efectos definitivos deben satisfacer `INV-08`. | `INV-06`, `INV-08` |
| `CL-53` | Una instrucción posterior falla después de actualizaciones provisionales en el lote. | Se revierte completamente esa instrucción. Las demás siguen la política de lote definida y los efectos definitivos conservan los importes por token. | `INV-06`, `INV-08` |

### Criterio de Cobertura

Aplicar los casos pertinentes a cada token autorizado para pagos, con saldos previos cero y positivos, una o varias cuentas y los valores límite que admita la configuración. Comprobar las ocho propiedades cuando correspondan, tanto por operación como en secuencias, y comparar el estado inmediatamente anterior y posterior a cada intento fallido. Las variantes de lotes, autopagos, comisiones y destinatarios pendientes solo pueden resolverse cuando se definan sus reglas.

Esta matriz enumera clases de límites y fallos identificadas para `EC-02`; no demuestra que se hayan enumerado todas las secuencias posibles ni sustituye las pruebas o una verificación formal. Los estados inconsistentes son escenarios de detección de fallos, no estados que la cadena garantice reparar.
