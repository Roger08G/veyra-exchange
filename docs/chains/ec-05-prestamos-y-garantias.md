# `EC-05` Préstamos y Garantías

La cadena económica `EC-05` gestiona la apertura y el desembolso de préstamos con garantía, los límites aplicables y el bloqueo o la liberación de garantías que corresponda.

## Objetivo

El objetivo de esta cadena es permitir que una cuenta solicite un préstamo respaldado por una garantía suficiente y que el fondo desembolse el capital conforme a sus límites y liquidez. La garantía debe permanecer separada de los fondos disponibles mientras respalde obligaciones, y la deuda y las condiciones del préstamo deben quedar registradas.

En `v0.1.0` existe un único mercado de préstamos y cada cuenta puede tener como máximo un préstamo activo. La tasa de interés y la comisión de apertura se fijan al abrirlo según el plan vigente. La devolución de la deuda corresponde a `EC-06` y la liquidación y las pérdidas, a `EC-07`.

> Tokens permitidos: [tokens](../tokens.md)

El mercado usa las direcciones de MockUSD para los préstamos y de MockETH para las garantías.

## Actores

En esta cadena intervienen los siguientes actores:

- El **prestatario** solicita el préstamo para su propia cuenta y aporta la garantía exigida.
- El **contrato de préstamos de Veyra** valida la solicitud, registra el préstamo y sus condiciones, y coordina el bloqueo de la garantía y el desembolso.
- El **contrato de cuentas** bloquea MockETH del prestatario y acredita el desembolso en su disponible de MockUSD.
- El **fondo de liquidez `EC-04`** proporciona el capital disponible para los préstamos; la liquidez del fondo es distinta de los saldos disponibles de los usuarios, las garantías y los ingresos del protocolo.
- La cadena de **planes y suscripciones `EC-03`** proporciona las condiciones aplicables al plan vigente al abrir el préstamo.
- La cadena de **intereses y devolución `EC-06`** gestiona la evolución de la deuda y su devolución, incluida la liberación de la garantía restante al saldarla.
- La cadena de **liquidaciones y pérdidas `EC-07`** gestiona las posiciones que incumplen el umbral de garantía y las pérdidas que correspondan.
- **EC-08** registra la comisión retenida al desembolsar.
- El **administrador** configura los parámetros autorizados del mercado y los precios simulados del entorno local. Esta función no le permite apropiarse de los fondos o garantías de los usuarios ni alterar arbitrariamente sus deudas.

## Variables y Estado Contable

Cada apertura crea un ID único de préstamo que nunca se reutiliza. Se asocian a él el prestatario, el estado, el principal, el MockETH bloqueado, las condiciones del plan y el instante inicial. Cada cuenta puede consultar el ID activo. Un préstamo cerrado sigue identificándose por su ID histórico.

El principal bruto solicitado P es la deuda inicial. El fondo entrega P de su caja. El prestatario recibe P menos la comisión y EC-08 recibe la comisión.

La garantía bloqueada para un préstamo debe distinguirse del saldo disponible del prestatario, de las garantías de otras cuentas, del patrimonio del fondo y de los ingresos del protocolo. No puede utilizarse como saldo disponible mientras permanezca comprometida.

El fondo mantiene separadas su liquidez disponible y las cantidades comprometidas en préstamos, conforme a `EC-04`. El desembolso y el reconocimiento del crédito deben contabilizarse sin atribuir al fondo fondos ajenos ni confundir la salida de liquidez con una pérdida.

El administrador publica un precio positivo p en unidades mínimas de MockUSD por MockETH entero, estampado con el tiempo del bloque. La ejecución requiere `0 ≤ ahora − publicación ≤ 3 600` segundos. Una nueva publicación válida sustituye a la anterior incluso dentro del mismo bloque. Una publicación de cero revierte y conserva el último precio y su fecha. Antes de la primera publicación, y desde el segundo 3 601 sin actualizar, se rechazan aperturas y liquidaciones.

## Flujo Económico

### Flujo de Apertura del Préstamo

El usuario solicita abrir un préstamo e indica los datos necesarios para determinar el capital solicitado y la garantía que respaldará la operación. Veyra comprueba la identidad del prestatario, que no tenga otro préstamo activo, las condiciones del plan vigente y la configuración aplicable del mercado.

Veyra valora la garantía mediante el precio configurado, comprueba que el capital solicitado no exceda el límite permitido para esa garantía y verifica que el fondo dispone de liquidez suficiente para el desembolso y las demás salidas del fondo que correspondan.

En una sola transacción se bloquea la garantía, se abre la deuda, se desembolsa el neto y se retiene la comisión.

Con tasa de apertura f en puntos básicos, la comisión es `floor(P × f / 10 000)`. Se exige neto positivo.

### Bloqueo y Gestión de la Garantía

Se resta la garantía C del disponible individual y total en MockETH y se suma al bloqueo de ese préstamo.

La garantía se fija al abrir. La v0.1.0 permite devolver deuda durante la vida del préstamo y liberar o adjudicar la garantía al cierre.

### Desembolso y Liquidez del Fondo

El desembolso utiliza liquidez disponible del fondo. La reducción de esa liquidez y el registro del capital comprometido deben reflejar el movimiento efectivo, sin utilizar saldos disponibles, garantías o ingresos ajenos al fondo.

El neto aumenta el saldo disponible de MockUSD del prestatario y el total disponible. El mismo movimiento reduce la caja libre junto con la comisión.

El abono es una reclasificación respaldada por la caja del fondo, autorizada según INV-07 de EC-01.

### Devolución, Liberación y Liquidación

La evolución del interés simple sobre el principal pendiente y las devoluciones parciales o totales corresponden a `EC-06`. Al saldar la deuda, esa cadena gestiona la liberación de la garantía restante conforme a sus reglas; `EC-05` debe mantener los estados y límites necesarios para reflejarla.

Al incumplir el umbral de EC-07, una liquidación puede cerrar la posición y asignar la garantía.

Una cuenta puede volver a abrir tras confirmarse el cierre por devolución total o liquidación.

## Validaciones y Restricciones

### Validaciones de Apertura

- El solicitante abre para su cuenta y carece de otro préstamo activo.
- El activo del préstamo y el de la garantía deben ser los configurados y autorizados para el mercado. Las direcciones se comprueban conforme a la configuración, no solo por nombre o símbolo.
- El capital solicitado y la garantía requerida deben ser mayores que cero y expresarse en las unidades mínimas de sus respectivos activos.
- La garantía debe estar disponible desde la fuente autorizada y quedar efectivamente bloqueada para la operación. No pueden utilizarse fondos bloqueados por otras obligaciones ni saldos de terceros.
- El precio cumple las comprobaciones de signo y antigüedad del mercado.
- Con C en unidades mínimas de MockETH, se acepta `P × 10¹⁸ × 10 000 ≤ C × p × 6 000`. Comparar productos antes de dividir. La igualdad es válida.
- El fondo debe disponer de liquidez suficiente para cubrir la salida total que le corresponda en la apertura. La liquidez comprometida o las reservas ajenas no completan el importe faltante.
- La tasa de interés y la comisión de apertura deben poder determinarse con las condiciones válidas del plan vigente y quedar fijadas para el préstamo. Si no puede resolverse una configuración válida, se rechaza la apertura.
- Los importes, las conversiones, los límites y los estados resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si falla una validación, el bloqueo, el desembolso, el cobro de una comisión exigible en la apertura o una actualización necesaria, la apertura debe revertirse por completo, sin garantía bloqueada, deuda, desembolso o ingreso definitivos parciales de ese intento.

### Validaciones de Garantías y Estado

- Cada garantía bloqueada debe estar asociada al préstamo y a la cuenta que corresponden. No puede utilizarse simultáneamente para cubrir otra obligación sin una regla expresa que lo permita.
- El prestatario no puede añadir ni retirar garantía durante la vida del préstamo.
- Los cambios posteriores de plan no modifican retroactivamente la tasa de interés ni la comisión de apertura fijadas al abrir un préstamo existente.
- Los cambios de precio pueden afectar a la valoración de la garantía y al riesgo de la posición, pero no deben alterar por sí solos la cantidad de tokens bloqueados ni crear un desembolso o una devolución.
- El estado del préstamo debe permitir aplicar el límite de un préstamo activo por cuenta y distinguir la apertura de su posterior devolución o liquidación.

### Restricciones del MVP

La garantía se toma del disponible propio y el neto se acredita internamente. La [configuración de referencia](../economic.md) fija las tarifas, la tasa anual y el límite de apertura. La comisión se cobra inmediatamente. El interés inicial es cero y el devengo comienza en el instante de apertura. Los estados persistentes son activo, cerrado por devolución y cerrado por liquidación.

## Invariantes y Propiedades

Las propiedades de apertura se aplican a la ejecución y a sus efectos contables por token.

Las comprobaciones de cobertura y LTV se refieren a los momentos expresamente indicados. Una variación posterior del precio puede dejar una posición por encima de un umbral sin que la apertura original haya incumplido sus condiciones; su tratamiento corresponde a las reglas de seguimiento y a `EC-07`.

### Invariante `INV-01` - Respaldo de Préstamos

En `EC-05`, cada préstamo debe abrirse con garantía suficiente conforme a la valoración, los parámetros de cobertura y el límite aplicables en ese momento.

La exposición al abrir es el principal bruto. Se compara con la capacidad calculada a partir de la garantía.

```math
\forall p \in P_{\text{apertura}}:\quad
E_{\text{apertura}}(p) \leq K_{\text{garantia}}(p)
```

**Leyenda:**

- $P_{\text{apertura}}$: conjunto de préstamos abiertos correctamente.
- $E_{\text{apertura}}(p)$: exposición utilizada para comprobar la apertura del préstamo $p$.
- $K_{\text{garantia}}(p)$: capacidad permitida para ese préstamo, calculada con la garantía bloqueada, su valoración y los parámetros aplicables al abrirlo.

La capacidad máxima entera en MockUSD es `floor(C × p × 6 000 / (10¹⁸ × 10 000))`.

### Invariante `INV-02` - Integridad de Garantías

En `EC-05`, las garantías registradas como bloqueadas deben corresponder a activos efectivamente custodiados y no pueden atribuirse simultáneamente a varias obligaciones incompatibles.

Para cada token de garantía, la suma de garantías bloqueadas de préstamos no puede superar la cantidad efectivamente custodiada y disponible para respaldarlas, una vez excluidos los activos atribuidos a otras partidas no compartibles.

```math
\forall t \in T_{\text{garantia}}:\quad
\sum_{p \in P_t} G_{\text{bloqueada}}(p,t)
\leq B_{\text{respaldoGarantias}}(t)
```

**Leyenda:**

- $T_{\text{garantia}}$: conjunto de tokens autorizados como garantía.
- $P_t$: préstamos con garantía bloqueada del token $t$.
- $G_{\text{bloqueada}}(p,t)$: cantidad del token $t$ atribuida como garantía bloqueada al préstamo $p$.
- $B_{\text{respaldoGarantias}}(t)$: cantidad realmente custodiada y disponible para respaldar esas garantías, excluidas las partidas que no pueden compartir ese respaldo.

El bloqueo se concilia por token en la custodia común con el total bloqueado de los préstamos activos.

### Invariante `INV-03` - Límite de Endeudamiento

En `EC-05`, la apertura de un préstamo debe respetar tanto la capacidad determinada por su garantía como los demás límites configurados para el mercado y la cuenta.

Para cada apertura completada, la exposición comprobada no supera el límite aplicable, calculado con todas las restricciones vigentes para esa operación.

```math
\forall p \in P_{\text{apertura}}:\quad
E_{\text{apertura}}(p) \leq K_{\text{aplicable}}(p)
```

**Leyenda:**

- $P_{\text{apertura}}$: conjunto de préstamos abiertos correctamente.
- $E_{\text{apertura}}(p)$: exposición utilizada para comprobar el préstamo $p$.
- $K_{\text{aplicable}}(p)$: principal máximo admisible según garantía y caja libre para esa apertura.

Se admite llegar exactamente al límite de apertura, sujeto a la caja del fondo y al resto de validaciones.

### Invariante `INV-04` - Conservación del Desembolso

En `EC-05`, la apertura debe relacionar la salida efectiva de liquidez del fondo, el importe recibido por el prestatario, las comisiones cobradas y la deuda inicial, sin crear fondos ni registrar movimientos inexistentes.

La salida de caja es idéntica al principal inicial. La suma del neto acreditado y la comisión retenida iguala esa salida.

```math
\forall p \in P_{\text{apertura}}:\quad
D_{\mathrm{inicial}}(p)=P_{\mathrm{bruto}}(p)=A_{\text{salidaFondo}}(p)
=\sum_{d \in D_p} A_{\text{recibido}}(p,d)
```

**Leyenda:**

- $P_{\text{apertura}}$: conjunto de préstamos abiertos correctamente.
- $D_{\mathrm{inicial}}(p)$ y $P_{\mathrm{bruto}}(p)$: deuda registrada al abrir y principal solicitado en unidades mínimas de MockUSD.
- $A_{\text{salidaFondo}}(p)$: importe efectivamente cargado a la liquidez del fondo por la apertura $p$.
- $D_p$: destinos de esa salida en el mismo activo, incluido el prestatario y, si corresponde, el protocolo.
- $A_{\text{recibido}}(p,d)$: importe efectivamente acreditado al destino $d$ procedente de esa salida.

La deuda inicial coincide con la salida del fondo. El disponible del prestatario aumenta por el neto y el retenido de EC-08 por la diferencia.

### Invariante `INV-05` - Unicidad de Préstamos

En el MVP, cada cuenta puede mantener como máximo un préstamo activo. Los préstamos históricos no cuentan como activos por el mero hecho de conservarse sus registros.

Para cada cuenta y cada instante, el número de préstamos considerados activos según la regla de estados del mercado no puede superar uno.

```math
\forall u \in U,\quad \forall \tau:\quad
\left|\{p \in P_u:\operatorname{activo}(p,\tau)\}\right|\leq 1
```

**Leyenda:**

- $U$: conjunto de cuentas de Veyra.
- $P_u$: conjunto de préstamos registrados para la cuenta $u$.
- $\tau$: instante de comprobación.
- $\operatorname{activo}(p,\tau)$: el préstamo está abierto y todavía carece de un cierre confirmado.
- $|\cdot|$: número de elementos del conjunto.

Al cerrar, la cuenta deja de tener ese préstamo activo. Una apertura posterior crea otro ID, incluso si ocurre en el mismo bloque. Una orden dirigida al ID anterior nunca alcanza a la nueva posición.

### Invariante `INV-06` - Protección de Garantías

En `EC-05`, una garantía comprometida no puede convertirse en saldo disponible ni retirarse mientras deba permanecer bloqueada para respaldar la deuda. Las modificaciones y liberaciones deben cumplir las reglas de la cadena responsable.

Para cualquier liberación completada, el importe liberado no puede superar la parte que las reglas aplicables permitan liberar en ese estado.

```math
\forall o \in O_{\text{liberacion}}:\quad
G_{\text{liberada}}(o)\leq G_{\text{liberable}}(o)
```

**Leyenda:**

- $O_{\text{liberacion}}$: operaciones completadas que liberan garantía conforme a las reglas aplicables.
- $G_{\text{liberada}}(o)$: cantidad de garantía liberada por la operación $o$.
- $G_{\text{liberable}}(o)$: cantidad que puede liberarse en ese estado según las reglas de cobertura y de la cadena responsable.

La garantía se libera al cierre por devolución o se distribuye al cierre por liquidación.

### Invariante `INV-07` - Consistencia de Valoración

En `EC-05`, el valor de la garantía utilizado en una comprobación debe calcularse con el precio válido, las unidades, los decimales y el redondeo aplicables al momento de esa comprobación.

Para cada valoración utilizada por una operación completada, el valor aplicado coincide con el resultado de la regla configurada para la cantidad y el precio correspondientes.

```math
\forall o \in O_{\text{valoracion}}:\quad
V_{\text{utilizado}}(o)=
\operatorname{valorar}(G(o),P(o),D(o),R(o))
```

**Leyenda:**

- $O_{\text{valoracion}}$: operaciones completadas que requieren valorar garantía.
- $G(o)$: cantidad de garantía utilizada en la comprobación.
- $P(o)$: precio válido utilizado para esa operación.
- $D(o)$: escalas y decimales aplicables a los activos y al precio.
- $R(o)$: regla de precisión y redondeo aplicable.
- $V_{\text{utilizado}}(o)$: valor de garantía utilizado por la operación.
- $\operatorname{valorar}$: valoración de C mediante el precio válido p y la escala 10¹⁸ de MockETH.

La valoración usa la publicación vigente en el bloque de ejecución y conserva la precisión al comparar productos.

### Invariante `INV-08` - Integridad del LTV

Al abrir se compara el principal bruto con el límite del 60 % del valor de la garantía.

Para cada apertura completada con garantía valorada positivamente, el LTV calculado con la exposición definida y la valoración aplicable no supera el límite de apertura configurado.

```math
\forall p \in P_{\text{apertura}}:\quad
V_{\text{garantia}}(p)>0 \implies
\operatorname{LTV}_{\text{apertura}}(p)\leq L_{\text{maximo}}(p)
```

**Leyenda:**

- $P_{\text{apertura}}$: conjunto de préstamos abiertos correctamente.
- $V_{\text{garantia}}(p)$: valor de la garantía utilizado al abrir el préstamo $p$.
- $\operatorname{LTV}_{\text{apertura}}(p)$: principal bruto dividido entre valor de garantía, en la misma moneda.
- $L_{\text{maximo}}(p)$: límite de LTV aplicable a esa apertura.

Una publicación inválida o caducada impide abrir. Las variaciones posteriores de precio se evalúan mediante EC-07.

### Invariante `INV-09` - Aislamiento de Prestatarios

En `EC-05`, una operación de un prestatario no puede modificar indebidamente las garantías o deudas de otra cuenta. Las operaciones autorizadas de otras cadenas conservan sus propias reglas.

Para cada operación de un prestatario, la variación de la garantía y la deuda registradas de cualquier otro prestatario atribuible a esa operación es cero.

```math
\forall o \in O_{\text{cuenta}},\quad \forall v \in U:\quad
v\ne u_o \implies
\Delta G(v,o)=0\quad\land\quad\Delta D(v,o)=0
```

**Leyenda:**

- $O_{\text{cuenta}}$: operaciones completadas de `EC-05` realizadas para una cuenta prestataria.
- $U$: conjunto de cuentas de Veyra.
- $u_o$: cuenta para la que se ejecuta la operación $o$.
- $v$: otra cuenta prestataria.
- $\Delta G(v,o)$ y $\Delta D(v,o)$: variaciones de la garantía y la deuda registradas de $v$ atribuibles a la operación $o$.

### Invariante `INV-10` - Disponibilidad de Liquidez

En `EC-05`, el fondo solo puede desembolsar un préstamo si dispone de liquidez suficiente para la salida total que le corresponda en la apertura. El patrimonio comprometido y las reservas ajenas no se consideran liquidez disponible para esa salida.

Para cada apertura completada, la salida efectiva total del fondo no supera la liquidez disponible inmediatamente antes de ejecutarla.

```math
\forall p \in P_{\text{apertura}}:\quad
A_{\text{salidaFondo}}(p)\leq L_{\text{disponible}}^{\text{antes}}(p)
```

**Leyenda:**

- $P_{\text{apertura}}$: conjunto de préstamos abiertos correctamente.
- $A_{\text{salidaFondo}}(p)$: salida total del fondo atribuible a la apertura $p$.
- $L_{\text{disponible}}^{\text{antes}}(p)$: liquidez del fondo disponible para esa apertura inmediatamente antes de ejecutarla, según `EC-04` y los parámetros aplicables.

### Invariante `INV-11` - Integridad de Condiciones

En `EC-05`, la tasa de interés y la comisión de apertura fijadas al abrir un préstamo no se modifican retroactivamente por cambios posteriores de plan o de su configuración.

Para cada apertura completada, la tasa y la condición de comisión fijadas deben corresponder al plan vigente y a la configuración aplicable en ese instante. Para cada préstamo existente y cada cambio posterior de plan, esos valores permanecen inalterados por ese cambio.

```math
\forall p \in P_{\text{apertura}}:\quad
H_{\text{fijadas}}(p)=H_{\text{aplicables}}(u_p,\tau_p)
```

```math
\forall p \in P,\quad \forall c \in C_p:\quad
\Delta H_{\text{fijadas}}(p,c)=0
```

**Leyenda:**

- $P$: conjunto de préstamos registrados.
- $P_{\text{apertura}}$: conjunto de préstamos abiertos correctamente.
- $u_p$ y $\tau_p$: cuenta prestataria e instante de apertura del préstamo $p$.
- $C_p$: cambios posteriores de plan o de configuración considerados para el prestatario del préstamo $p$.
- $H_{\text{fijadas}}(p)$: condiciones fijadas al abrir el préstamo, incluida la tasa de interés y la comisión de apertura.
- $H_{\text{aplicables}}(u_p,\tau_p)$: esas mismas condiciones conforme al plan vigente y la configuración aplicable al abrir el préstamo.
- $\Delta H_{\text{fijadas}}(p,c)=0$: indica que el cambio $c$ no modifica esos valores.

Esta propiedad no impide la evolución del principal pendiente o del interés devengado conforme a `EC-06`.

### Invariante `INV-12` - Atomicidad de Préstamos

En `EC-05`, una apertura o modificación fallida no puede dejar deuda, garantía bloqueada, desembolsos, comisiones o registros definitivos parciales atribuibles al intento.

Para cada intento fallido de una operación de esta cadena, los estados y registros afectados después del intento coinciden con los inmediatamente anteriores.

```math
\forall f \in F:\quad
S_{\text{despues}}(f)=S_{\text{antes}}(f)
```

**Leyenda:**

- $F$: conjunto de intentos fallidos o rechazados de operaciones definidas en `EC-05`.
- $S_{\text{antes}}(f)$: estados contables, de garantía y de préstamo y registros afectados inmediatamente antes del intento $f$.
- $S_{\text{despues}}(f)$: esos mismos estados y registros después del intento, considerando sus efectos atribuibles.

## Casos Límite y Escenarios de Fallo

Los siguientes casos sirven de referencia para futuras pruebas de `EC-05`. Las referencias `INV-01` a `INV-12` corresponden a esta cadena. En una apertura o modificación fallida se revierten los efectos atribuibles al intento, incluidos deuda, garantías, desembolsos, comisiones y registros definitivos.

Los casos se evalúan con las direcciones y parámetros del mercado de referencia.

### Apertura, Autorización y Estado del Préstamo

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Una cuenta sin préstamo activo solicita una apertura válida. | Puede completarse si cumple todas las condiciones de garantía, límite, liquidez y plan. Se registra un único préstamo con sus condiciones y movimientos correspondientes. | `INV-01`, `INV-04`, `INV-05`, `INV-10`, `INV-11` |
| `CL-02` | Una cuenta ya tiene un préstamo activo y solicita otro. | Se rechaza la apertura sin bloquear más garantía, crear deuda, desembolsar fondos ni cobrar una comisión definitiva. | `INV-05`, `INV-12` |
| `CL-03` | Una cuenta conserva registros de préstamos anteriores que ya no están activos. | El historial cerrado permite otra apertura si la cuenta carece de préstamo activo y supera las demás validaciones. | `INV-05` |
| `CL-04` | Se intenta abrir otro préstamo después de una devolución total o liquidación. | Puede abrir después de un cierre confirmado por devolución total o por liquidación. | `INV-05` |
| `CL-05` | Un usuario o el administrador intenta abrir un préstamo con fondos o garantía de otra cuenta. | Se rechaza sin efectos definitivos. Administrar el mercado no concede acceso a fondos ajenos. | Validaciones, `INV-09`, `INV-12` |
| `CL-06` | Dos solicitudes simultáneas o anidadas intentan abrir préstamos para la misma cuenta. | Como máximo una puede quedar activa. Cada intento fallido revierte sus efectos; no se permite eludir la comprobación mediante una llamada anidada. | `INV-05`, `INV-12` |
| `CL-07` | El activo de préstamo o el token de garantía no coincide con la dirección autorizada, aunque comparta nombre o símbolo. | Se rechaza sin garantía bloqueada, deuda ni desembolso definitivos. | Validaciones, `INV-02`, `INV-12` |
| `CL-08` | El capital solicitado o la cantidad de garantía requerida es cero. | Se rechaza. El mínimo admisible para cada importe es una unidad, sujeto a todas las validaciones. | Validaciones, `INV-01`, `INV-12` |
| `CL-09` | El capital o la garantía es una unidad mínima o está cerca de un mínimo configurado. | Se aplican los mínimos, la valoración y el redondeo definidos para cada activo. Si no se cumplen todas las condiciones, se rechaza sin efectos parciales. | `INV-01`, `INV-03`, `INV-07`, `INV-12` |

### Garantía, Custodia y Aislamiento

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-10` | La garantía procede del saldo disponible. | El saldo individual y el total disponible del token disminuyen por la cantidad bloqueada; la misma cantidad queda atribuida a la garantía del préstamo, sin descontarla dos veces. | `INV-02`, `INV-06` |
| `CL-11` | El saldo disponible de garantía coincide con lo requerido o queda una unidad mínima por debajo. | En igualdad se supera esa comprobación si se cumplen las demás condiciones; una unidad por debajo impide cubrir el bloqueo con ese saldo. | `INV-02`, `INV-06`, `INV-12` |
| `CL-12` | La cuenta tiene saldo disponible insuficiente, pero posee fondos bloqueados por otra obligación. | No se reutilizan esos fondos para completar la garantía. Si no existe una fuente autorizada suficiente, se rechaza la apertura. | `INV-02`, `INV-06`, `INV-12` |
| `CL-13` | Se intenta abrir con garantía externa sin saldo disponible. | Se rechaza hasta que el titular efectúe el depósito de MockETH. | `INV-02`, `INV-12` |
| `CL-14` | La garantía efectivamente recibida o bloqueada no coincide con la requerida. | Se revierte la apertura si el bloqueo no coincide con la garantía solicitada. | `INV-01`, `INV-02`, `INV-12` |
| `CL-15` | Hay garantías de varios prestatarios custodiadas en un mismo contrato. | Cada cantidad queda atribuida al préstamo y cuenta correspondientes; el respaldo debe cubrir la suma sin atribuir una misma unidad a obligaciones incompatibles. | `INV-02`, `INV-09` |
| `CL-16` | La garantía registrada supera el respaldo realmente custodiado o comparte indebidamente activos con otra reserva. | Se identifica un estado inconsistente respecto de la garantía. No se presupone un mecanismo de reparación ni que cada operación detecte cualquier inconsistencia previa. | `INV-02` |
| `CL-17` | El prestatario intenta retirar del saldo disponible una garantía que sigue comprometida. | La cantidad comprometida no está disponible para la retirada. La posible liberación requiere cumplir las reglas y autorización aplicables. | `INV-06` |
| `CL-18` | Se solicita liberar parte de la garantía durante la vida del préstamo. | Se rechaza. La garantía permanece vinculada al préstamo activo. | `INV-06`, `INV-08`, `INV-12` |
| `CL-19` | Se solicita añadir garantía a una posición que ya supera un límite tras una caída de precio. | La v0.1.0 excluye los aumentos de garantía sobre una posición abierta. El prestatario sí puede reducir deuda mediante EC-06. | `INV-02`, `INV-08`, `INV-09` |
| `CL-20` | La deuda se salda y queda garantía bloqueada. | El cierre por devolución acredita toda la garantía al disponible del prestatario en la misma transacción. | `INV-06` |
| `CL-21` | Una operación de un prestatario ocurre mientras otro tiene deuda y garantía. | La operación no modifica la deuda ni la garantía del otro prestatario por ese hecho, aunque ambos compartan mercado o token. | `INV-02`, `INV-09` |

### Valoración, Capacidad y LTV

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-22` | El precio requerido no está configurado o no cumple las condiciones de validez definidas. | Se rechaza la apertura que depende de ese precio, sin usar un valor inventado ni dejar efectos definitivos. | `INV-01`, `INV-07`, `INV-12` |
| `CL-23` | El precio o la valoración calculada de la garantía es cero. | No se completa una apertura que requiera una valoración positiva; no se divide entre cero para calcular el LTV. | `INV-01`, `INV-07`, `INV-08`, `INV-12` |
| `CL-24` | Un precio simulado cambia después de una consulta y antes de ejecutar la apertura. | Se usa la publicación válida vigente al ejecutar y se vuelve a comprobar el límite de apertura. | `INV-01`, `INV-07`, `INV-08` |
| `CL-25` | Los activos de préstamo y garantía, o el precio, utilizan escalas y decimales distintos. | La valoración aplica las unidades, conversiones y redondeo definidos; no compara cantidades de activos distintos sin convertirlas. | `INV-07`, `INV-08` |
| `CL-26` | La conversión o el cálculo del límite produce una fracción de unidad mínima. | Para el límite máximo en unidades de deuda se toma la parte entera de la capacidad. La comparación por productos es equivalente. | `INV-01`, `INV-03`, `INV-07`, `INV-08` |
| `CL-27` | La exposición está una unidad por debajo del límite aplicable. | Supera esa comprobación si la comparación en esas unidades es válida y se cumplen las demás condiciones; no se presupone aprobación de toda la apertura. | `INV-01`, `INV-03`, `INV-08` |
| `CL-28` | La exposición coincide exactamente con el límite aplicable. | La igualdad supera la comprobación de cobertura. | `INV-01`, `INV-03`, `INV-08` |
| `CL-29` | La exposición supera el límite aplicable en una unidad o más. | Se rechaza la apertura sin efectos definitivos, incluso si existe liquidez suficiente en el fondo. | `INV-01`, `INV-03`, `INV-08`, `INV-12` |
| `CL-30` | El límite por garantía permite el préstamo, pero la cuenta ya tiene uno activo. | El límite de un préstamo activo por cuenta impide la nueva apertura. | `INV-01`, `INV-03` |
| `CL-31` | Se intenta sumar la comisión de apertura al principal para valorar la exposición. | La exposición es el principal bruto. La comisión ya está incluida en la distribución de su desembolso. | `INV-03`, `INV-04`, `INV-08` |
| `CL-32` | Los productos de la comprobación de cobertura exceden 256 bits. | Se compara su valor matemático exacto. Una entrada inválida o un resultado final irrepresentable revierte la apertura. | `INV-03`, `INV-07`, `INV-08`, `INV-12` |
| `CL-33` | Tras una apertura válida baja el precio y el LTV supera un umbral. | La apertura conserva sus condiciones históricas. La nueva valoración solo permite liquidar si supera estrictamente el umbral de EC-07. | `INV-01`, `INV-06`–`INV-08` |
| `CL-34` | Tras abrir sube el precio de la garantía. | Cambia la valoración al precio vigente. Se mantienen las unidades bloqueadas y el principal. Solo un cierre por EC-06 o EC-07 puede liberar o adjudicar esa garantía. | `INV-06`–`INV-08` |

### Desembolso, Deuda y Comisión de Apertura

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-35` | El fondo tiene liquidez exactamente igual a la salida total de la apertura. | Supera la comprobación de liquidez si se cumplen las demás condiciones; la salida incluye las cantidades que deban salir del fondo por esa operación. | `INV-04`, `INV-10` |
| `CL-36` | La salida total requerida supera la liquidez disponible en una unidad mínima o más. | Se rechaza la apertura completa sin utilizar capital comprometido ni reservas ajenas para completar la diferencia. | `INV-10`, `INV-12` |
| `CL-37` | El patrimonio del fondo es positivo, pero su liquidez disponible es cero o insuficiente. | No se completa una salida superior a la liquidez disponible; no se confunde patrimonio con efectivo disponible. | `INV-10`, `INV-12` |
| `CL-38` | Se acredita internamente el desembolso neto. | Aumentan el disponible individual y el total de MockUSD por el neto. La caja disminuye por el bruto y la diferencia es ingreso EC-08. | `INV-04`, `INV-09` |
| `CL-39` | Se solicita un destino externo de desembolso. | Se rechaza sin bloquear garantía ni registrar deuda. | `INV-04`, `INV-12` |
| `CL-40` | La comisión de apertura es cero. | Si la configuración la permite, no se reconoce ingreso positivo por esa comisión; los movimientos y la deuda inicial siguen la regla de apertura definida. | `INV-04`, `INV-11` |
| `CL-41` | Se retiene la comisión al desembolsar. | Neto más comisión igualan la salida de caja y el principal bruto registrado. | `INV-04`, `INV-10` |
| `CL-42` | Se intenta volver a cobrar la comisión desde otra fuente. | Se rechaza el segundo cargo. | `INV-04`, `INV-12` |
| `CL-43` | Se intenta capitalizar la comisión además del principal bruto. | El principal debe coincidir con el bruto. La comisión no genera deuda adicional. | `INV-03`, `INV-04`, `INV-08` |
| `CL-44` | La comisión calculada es igual o superior al importe solicitado. | Se rechaza una apertura cuyo cálculo produzca un neto nulo o negativo. | `INV-03`, `INV-04`, `INV-12` |
| `CL-45` | El fondo registra el capital comprometido al abrir el préstamo. | El reconocimiento del crédito y la disminución de liquidez reflejan el movimiento efectivo conforme a `EC-04`; la salida de liquidez no se registra automáticamente como pérdida. | `INV-04`, `INV-10` |

### Condiciones del Plan y Atomicidad

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-46` | El plan cambia o caduca entre la solicitud y la ejecución de la apertura. | Se determinan y fijan las condiciones del plan vigente al ejecutar la apertura. Si no se resuelve una configuración válida, se rechaza sin efectos definitivos. | `INV-11`, `INV-12` |
| `CL-47` | El plan o su configuración cambia después de abrir el préstamo. | La tasa de interés y la comisión de apertura fijadas para ese préstamo no cambian retroactivamente por ese hecho. | `INV-11` |
| `CL-48` | El préstamo evoluciona mediante devolución o devengo de interés. | Se aplican las reglas de `EC-06`; la evolución del principal pendiente o del interés devengado no modifica por sí sola la tasa fijada en la apertura. | `INV-11` |
| `CL-49` | Falla una validación antes del bloqueo de garantía. | El estado de deuda, garantía, liquidez, ingresos y registros queda como antes del intento. | `INV-12` |
| `CL-50` | Falla una actualización después de bloquear provisionalmente la garantía. | Se revierte la apertura completa y la garantía recupera el estado que tenía antes del intento; no quedan deuda ni desembolso definitivos. | `INV-02`, `INV-06`, `INV-12` |
| `CL-51` | Falla el desembolso después de registrar provisionalmente la deuda. | Se revierten deuda, bloqueo de garantía y demás efectos del intento, incluidos cobros o ingresos provisionales. | `INV-04`, `INV-12` |
| `CL-52` | Falla el cobro requerido de la comisión o su registro después de un desembolso provisional. | Se revierte toda la apertura, incluidos el desembolso, la deuda y el bloqueo; no permanece ingreso definitivo parcial. | `INV-04`, `INV-12` |
| `CL-53` | Falla el registro definitivo o una actualización posterior a los movimientos provisionales. | Se revierten todos los efectos del intento. No queda un préstamo activo sin sus movimientos y condiciones correspondientes. | `INV-04`, `INV-11`, `INV-12` |
| `CL-54` | Una secuencia combina aperturas de varias cuentas, cambios de precio y solicitudes fallidas. | Se comprueban las propiedades aplicables en cada transición. Un intento fallido conserva el estado inmediatamente anterior a ese intento, incluidos los efectos previos válidos. | `INV-01`–`INV-12` |

### Criterio de Cobertura

Comprobar el límite por productos exactos, la caja disponible, el abono del neto y la conservación del bloqueo para cuentas distintas y precios en sus límites.

Esta matriz sirve para diseñar las pruebas de apertura, desembolso y bloqueo.
