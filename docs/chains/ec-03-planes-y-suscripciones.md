# `EC-03` Planes y Suscripciones

La cadena económica `EC-03` gestiona los planes de las cuentas de Veyra, la contratación y renovación de suscripciones, sus cambios, su caducidad y las condiciones asociadas a cada plan.

## Objetivo

El objetivo de esta cadena es determinar el plan vigente de cada cuenta y proporcionar sus condiciones a las operaciones que dependen de él. También gestiona la contratación y la renovación manual del plan de pago, así como el registro de las cuotas efectivamente cobradas como ingresos del protocolo.

En `v0.1.0` se contemplan un plan básico y un plan de pago. El plan de pago tiene una duración fija, caducidad y renovación manual. Los importes, las condiciones concretas y las reglas de transición que aún no están definidos deben establecerse antes de implementar los comportamientos que dependen de ellos.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen los siguientes actores:

- El **usuario** consulta el plan de su cuenta y solicita la contratación, renovación o cambio de plan que esté permitido.
- El **contrato de planes de Veyra** valida las solicitudes, mantiene la información de la suscripción y permite resolver las condiciones del plan vigente.
- El **administrador** configura las condiciones y parámetros autorizados de los planes. Esta función no le concede permiso para mover fondos de usuarios ni modificar arbitrariamente sus saldos o suscripciones.
- Las cadenas consumidoras, como **`EC-01` y `EC-02`**, consultan las condiciones aplicables al ejecutar operaciones sujetas a un plan.
- La cadena de **ingresos del protocolo `EC-08`** contabiliza las cuotas efectivamente cobradas, separadas de los saldos de los usuarios y del patrimonio del fondo.

## Variables y Estado Contable

Para cada cuenta, Veyra necesita identificar el plan que le corresponde y la información necesaria para determinar si una suscripción de pago está vigente o ha caducado. Esta información incluye la fecha de inicio y la fecha de caducidad de cada periodo contratado o renovado, según las reglas de vigencia que se definan.

La configuración de cada plan comprende las condiciones aplicables a las operaciones que dependen de él, incluidas las comisiones de retirada y de pago. Las tasas, los importes, las unidades, los límites y las reglas de redondeo están pendientes de concretar.

Para cada cuota efectivamente cobrada se debe poder identificar la cuenta, el importe, el token y el periodo de suscripción al que corresponde. La cuota cobrada se registra como ingreso del protocolo en `EC-08`; una cuota no cobrada no se contabiliza como ingreso.

La fuente de fondos para abonar la cuota y el token o tokens admitidos para ese pago están pendientes de definición. Si se utiliza el saldo disponible de la cuenta, el cargo debe reflejarse también en el total disponible registrado para ese token, en coherencia con `EC-01`.

Los fondos bloqueados por garantías u otras obligaciones, las participaciones del fondo de liquidez y las deudas de los prestatarios son estados asociados que `EC-03` no modifica al gestionar una suscripción.

## Flujo Económico

### Plan Básico

El plan básico forma parte del alcance de `v0.1.0`. Sus condiciones concretas, su posible precio y las circunstancias en las que se asigna a una cuenta están pendientes de definición.

Una operación que dependa del plan debe utilizar las condiciones del plan que corresponda a la cuenta en el momento definido para esa operación. No se presupone que una suscripción de pago caducada se convierta automáticamente en plan básico hasta que se establezca esa transición.

### Contratación del Plan de Pago

El usuario solicita contratar el plan de pago para su cuenta. Veyra comprueba que la solicitud, las condiciones configuradas y el cobro de la cuota cumplen las reglas aplicables.

Si la contratación se completa, se registra el periodo de suscripción de duración fija, se aplican las condiciones del plan de pago durante su vigencia y la cuota efectivamente cobrada se contabiliza como ingreso del protocolo en `EC-08`.

La fuente del cobro, el token, el importe, el instante de inicio y los límites exactos del periodo deben definirse antes de implementar este flujo.

### Renovación Manual

El usuario solicita renovar su suscripción de pago. Veyra valida la solicitud, las condiciones vigentes para la renovación y el cobro de la cuota que corresponda.

Si la renovación se completa, se registra el nuevo periodo y se contabiliza la cuota efectivamente cobrada en `EC-08`. No hay renovación ni cobro automático por el mero transcurso del tiempo.

Quedan pendientes las reglas para renovar antes o después de la caducidad, el momento desde el que se cuenta el nuevo periodo y el tratamiento del tiempo que pudiera quedar de una suscripción vigente.

### Cambio de Plan

El usuario puede solicitar un cambio de plan cuando la transición esté permitida por las reglas que se definan. Veyra debe identificar el plan anterior y el nuevo, las condiciones aplicables y cualquier cuota o ajuste que corresponda antes de completar el cambio.

Están pendientes de definición las transiciones permitidas, su momento de efecto, el tratamiento del tiempo ya pagado y la existencia o no de reembolsos, prorrateos o cargos adicionales. No se presupone ninguna de estas opciones.

### Caducidad y Consulta de Condiciones

Una suscripción de pago tiene un periodo de vigencia limitado. Al consultar el plan de una cuenta, Veyra debe tener en cuenta su caducidad conforme a la regla temporal que se defina, sin suponer una renovación automática.

El comportamiento posterior a la caducidad, incluido el plan aplicable y si se necesita una operación explícita para actualizar el estado registrado, está pendiente de definición. Mientras no pueda resolverse una configuración válida para una operación que depende del plan, esa operación debe rechazarse conforme a las reglas documentadas en `EC-01` y `EC-02`.

Las condiciones de los préstamos ya abiertos que el README fija en su apertura, como la tasa de interés y la comisión de apertura, no se modifican retroactivamente por un cambio, renovación o caducidad del plan.

## Validaciones y Restricciones

### Validaciones de Contratación y Renovación

- El usuario debe solicitar la operación para su propia cuenta; la administración de planes no concede acceso a fondos o suscripciones ajenos.
- El plan solicitado, su duración y las condiciones necesarias para la operación deben estar definidos y ser válidos para la transición solicitada.
- La contratación o renovación del plan de pago requiere una solicitud del usuario y el cobro de la cuota que corresponda conforme a la configuración aplicable.
- La fuente de fondos y el token utilizado para la cuota deben estar permitidos por las reglas que se definan. Si se utiliza saldo disponible, debe cubrir el cargo y no pueden emplearse fondos bloqueados ni saldos de terceros.
- Solo se registra como ingreso la cuota efectivamente cobrada. El importe cobrado, el token y el periodo deben poder asociarse a la operación.
- El cálculo del periodo, los importes y los saldos resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si falla una validación, el cobro o una actualización necesaria, la contratación o renovación debe revertirse por completo; no deben permanecer cambios parciales de suscripción, cobro o ingreso.

### Validaciones de Cambio y Consulta del Plan

- Un cambio solo puede completarse si la transición solicitada está permitida y sus condiciones económicas y temporales están definidas.
- La consulta debe distinguir la información registrada de la vigencia efectiva según la regla de caducidad que se establezca. Una suscripción caducada no debe tratarse como vigente por el mero hecho de conservar datos almacenados.
- Las operaciones sujetas al plan deben utilizar las condiciones que correspondan al momento de ejecución, salvo que la propia operación tenga condiciones fijadas previamente, como las del préstamo al abrirse.
- Ninguna operación de `EC-03` puede modificar saldos bloqueados, participaciones del fondo o deudas para completar una contratación, renovación o cambio.

### Restricciones Pendientes de Definición

- El precio y las condiciones de cada plan, la duración fija del plan de pago y las reglas de inicio, caducidad y cómputo temporal.
- La asignación del plan básico, su posible precio y el plan aplicable tras la caducidad del plan de pago.
- La fuente de fondos y el token o tokens admitidos para el cobro de cuotas, así como las condiciones de autorización del cobro.
- Las renovaciones anticipadas o posteriores a la caducidad y el tratamiento del tiempo restante.
- Las transiciones permitidas entre planes, su momento de efecto y los posibles reembolsos, prorrateos o cargos adicionales.
- Las tasas y reglas de cálculo y redondeo aplicables por plan y operación, incluidos los límites ya documentados por cada cadena consumidora.
- El efecto de los cambios de configuración sobre suscripciones vigentes y operaciones posteriores, respetando las condiciones previamente fijadas para préstamos abiertos.

Estas decisiones deben concretarse antes de implementar los comportamientos que dependen de ellas.

## Invariantes y Propiedades

Las siguientes propiedades son propuestas para `EC-03`. Describen los efectos atribuibles a cada operación y no deciden los parámetros ni las transiciones que siguen pendientes. Una variación de estado se calcula como valor posterior menos valor anterior.

Las fórmulas que se refieren a cuotas se aplican a la cuota efectivamente cobrada, en su propio token y sin incluir posibles reembolsos u otros ajustes todavía no definidos. La fuente de fondos para su cobro sigue pendiente; cuando se utilice el saldo disponible de la cuenta, se aplican además las relaciones con el total disponible de `EC-01`.

### Invariante `INV-01` - Unicidad del Plan Activo

En `EC-03`, una cuenta no puede tener simultáneamente más de un plan activo. La existencia de registros históricos, periodos futuros o datos de una suscripción caducada no implica que esos planes estén activos.

Para cada cuenta y cada instante, el número de planes activos es como máximo uno. Esta propiedad no decide qué plan corresponde tras la caducidad ni obliga a que siempre exista uno activo.

```math
\forall u \in U,\quad \forall \tau:\quad
\left|\{q \in Q : \operatorname{activo}(u,q,\tau)\}\right| \leq 1
```

**Leyenda:**

- $U$: conjunto de cuentas de Veyra.
- $Q$: conjunto de planes admitidos.
- $\tau$: instante en el que se comprueba la vigencia.
- $\operatorname{activo}(u,q,\tau)$: indica que el plan $q$ está efectivamente activo para la cuenta $u$ en ese instante, según las reglas de vigencia que se definan.
- $|\cdot|$: número de elementos del conjunto.

### Invariante `INV-02` - Integridad de Suscripciones

En `EC-03`, un periodo del plan de pago solo puede activarse si la cuota correspondiente ha sido cobrada correctamente y la suscripción se ha registrado. Una solicitud o un cobro fallido no activa el periodo.

Para cada periodo de pago activo, existe una operación completada que identifica la cuenta, el periodo y su cuota efectivamente cobrada. Esta propiedad no presupone el token ni la fuente del cobro.

```math
\forall u \in U,\quad \forall s \in S,\quad \forall \tau:\quad
\operatorname{activoPago}(u,s,\tau)
\implies \exists o \in O:\quad
\operatorname{vincula}(o,u,s) \land \operatorname{cuotaCobrada}(o,s)
```

**Leyenda:**

- $U$: conjunto de cuentas de Veyra.
- $S$: conjunto de periodos registrados del plan de pago.
- $O$: conjunto de contrataciones, renovaciones o cambios completados que puedan activar un periodo de pago según las reglas que se definan.
- $\operatorname{activoPago}(u,s,\tau)$: indica que el periodo $s$ de la cuenta $u$ está activo en el instante $\tau$.
- $\operatorname{vincula}(o,u,s)$: indica que la operación completada $o$ registra el periodo $s$ para la cuenta $u$.
- $\operatorname{cuotaCobrada}(o,s)$: indica que la cuota exigible para ese periodo se ha cobrado correctamente y está asociada a la operación. La admisibilidad de una cuota cero permanece pendiente de definición.

La duración, los límites temporales y los periodos futuros o renovados deben cumplir la regla de vigencia que se defina; un cobro por sí solo no determina el instante de activación.

### Invariante `INV-03` - Conservación de Cuotas

En `EC-03`, toda cuota efectivamente cobrada debe descontarse de los fondos autorizados del usuario y contabilizarse exactamente una vez como ingreso del protocolo en el mismo token. Una cuota no cobrada no genera ese ingreso.

Para cada cobro completado, el cargo al usuario coincide con la cuota cobrada y con el incremento de los ingresos retenidos del protocolo atribuible a esa cuota.

```math
\forall c \in C:\quad
K_{\text{usuario}}(c) = A_{\text{cuota}}(c)
= \Delta I_{\text{protocolo}}(t_c,c)
```

**Leyenda:**

- $C$: conjunto de cobros de cuotas completados correctamente en `EC-03`.
- $t_c$: token en el que se cobra la cuota $c$.
- $K_{\text{usuario}}(c)$: importe efectivamente cargado a los fondos autorizados del usuario para el cobro $c$.
- $A_{\text{cuota}}(c)$: importe efectivamente cobrado de la cuota $c$.
- $\Delta I_{\text{protocolo}}(t_c,c)$: incremento de los ingresos retenidos del protocolo en ese token atribuible a la cuota $c$.

Si la cuota se cobra del saldo disponible de la cuenta, tanto su saldo individual como el total disponible del token disminuyen por la cuota. La variación de custodia depende de la fuente de cobro que se defina; no se presupone una transferencia externa cuando se emplea saldo ya custodiado.

### Invariante `INV-04` - Aplicación Correcta de Comisiones

En las operaciones que dependen del plan, las tasas y condiciones utilizadas deben corresponder al plan efectivamente vigente de la cuenta en el momento previsto para esa operación. `EC-03` debe permitir resolver las condiciones aplicables sin utilizar una suscripción caducada como si estuviera vigente.

Para cada operación cuyo plan se determina al ejecutarse, la tasa utilizada coincide con la tasa aplicable al plan vigente en ese momento. Si no puede resolverse una configuración válida, la operación sujeta al plan se rechaza conforme a las reglas de su cadena.

```math
\forall o \in X:\quad
\operatorname{tasaUtilizada}(o)
= \operatorname{tasaVigente}(u_o,\operatorname{tipo}(o),\tau_o)
```

**Leyenda:**

- $X$: conjunto de operaciones completadas que resuelven su tasa según el plan al ejecutarse.
- $u_o$: cuenta cuyo plan determina la tasa de la operación $o$.
- $\operatorname{tipo}(o)$: tipo de operación para el que se consulta la condición.
- $\tau_o$: instante de ejecución en el que corresponde resolver el plan.
- $\operatorname{tasaUtilizada}(o)$: tasa aplicada a la operación.
- $\operatorname{tasaVigente}(u_o,\operatorname{tipo}(o),\tau_o)$: tasa aplicable según el plan efectivamente vigente y la configuración correspondiente.

Esta propiedad no fija las tasas, las comisiones resultantes ni el redondeo. Las condiciones fijadas previamente para préstamos abiertos se rigen por `INV-07` y no se recalculan por un cambio posterior de plan.

### Invariante `INV-05` - Caducidad de Planes

En `EC-03`, un periodo del plan de pago que ha caducado no puede proporcionar sus beneficios exclusivos. Los datos almacenados de una suscripción no demuestran por sí solos que siga vigente.

Para cada cuenta y periodo de pago, si el periodo está caducado en el instante de consulta, ese periodo no puede ser la fuente de beneficios exclusivos aplicados en ese instante.

```math
\forall u \in U,\quad \forall s \in S,\quad \forall \tau:\quad
\operatorname{caducado}(u,s,\tau)
\implies \neg\operatorname{beneficioPor}(u,s,\tau)
```

**Leyenda:**

- $U$: conjunto de cuentas de Veyra.
- $S$: conjunto de periodos registrados del plan de pago.
- $\tau$: instante de consulta o aplicación de condiciones.
- $\operatorname{caducado}(u,s,\tau)$: indica que el periodo $s$ de la cuenta $u$ ha caducado según la regla temporal que se defina.
- $\operatorname{beneficioPor}(u,s,\tau)$: indica que se aplica un beneficio exclusivo por la vigencia de ese periodo concreto.

Otro periodo de pago válidamente renovado puede proporcionar sus propios beneficios. La transición posterior a la caducidad y el tratamiento exacto del instante límite siguen pendientes.

### Invariante `INV-06` - Integridad de Renovaciones

En `EC-03`, cada renovación manual completada debe corresponder a un cobro correcto de su cuota y a un periodo de suscripción definido y registrado para la misma cuenta.

Para cada renovación completada existe un periodo identificado y una cuota cobrada vinculados a esa renovación. Una operación fallida no crea un periodo ni un cobro definitivo.

```math
\forall r \in R:\quad
\exists s \in S:\quad
\operatorname{vincula}(r,u_r,s) \land \operatorname{cuotaCobrada}(r,s)
```

**Leyenda:**

- $R$: conjunto de renovaciones manuales completadas correctamente.
- $S$: conjunto de periodos registrados del plan de pago.
- $u_r$: cuenta que solicita la renovación $r$.
- $\operatorname{vincula}(r,u_r,s)$: indica que la renovación $r$ registra el periodo $s$ para esa cuenta.
- $\operatorname{cuotaCobrada}(r,s)$: indica que la cuota exigible para ese periodo se ha cobrado correctamente y está asociada a la renovación.

El comienzo del periodo renovado, el tratamiento del tiempo restante y la posibilidad de renovar antes o después de la caducidad permanecen pendientes. La relación anterior no exige que el nuevo periodo comience inmediatamente.

### Invariante `INV-07` - Consistencia de Cambios de Plan

En `EC-03`, una contratación, renovación, cambio o caducidad del plan no modifica retroactivamente las condiciones que quedaron fijadas al abrir un préstamo existente. Esto incluye la tasa de interés y la comisión de apertura fijadas en ese momento.

Para cada transición de plan y cada préstamo existente afectado por la cuenta, los valores fijados al abrirlo permanecen inalterados por esa transición.

```math
\forall o \in O_{\text{plan}},\quad \forall l \in L_{u_o}:\quad
\Delta H_{\text{fijadas}}(l,o)=0
```

**Leyenda:**

- $O_{\text{plan}}$: conjunto de contrataciones, renovaciones, cambios y efectos de caducidad de planes considerados en `EC-03`.
- $u_o$: cuenta cuya situación de plan se evalúa en la transición $o$.
- $L_{u_o}$: conjunto de préstamos existentes de esa cuenta con condiciones fijadas en su apertura.
- $H_{\text{fijadas}}(l)$: conjunto de valores fijados al abrir el préstamo $l$, incluida su tasa de interés y su comisión de apertura.
- $\Delta H_{\text{fijadas}}(l,o)=0$: indica que ninguno de esos valores cambia por la transición de plan $o$.

Esta propiedad no impide los cambios propios del préstamo que correspondan a otras cadenas, como la evolución de la deuda.

### Invariante `INV-08` - Aislamiento de Suscripciones

En `EC-03`, una operación sobre la suscripción de una cuenta no altera la suscripción ni el plan efectivo de otra cuenta por el hecho de realizarse. Los cambios generales de configuración autorizados se evalúan por separado y sus efectos permanecen pendientes de definición.

Para cada operación completada sobre una cuenta, los datos de suscripción y las condiciones de plan de cualquier otra cuenta permanecen inalterados por esa operación.

```math
\forall o \in O_{\text{cuenta}},\quad \forall v \in U:\quad
v \ne u_o \implies \Delta S_{\text{plan}}(v,o)=0
```

**Leyenda:**

- $O_{\text{cuenta}}$: conjunto de contrataciones, renovaciones y cambios de plan completados para una cuenta.
- $U$: conjunto de cuentas de Veyra.
- $u_o$: cuenta titular de la operación $o$.
- $v$: otra cuenta cuya suscripción se comprueba.
- $S_{\text{plan}}(v)$: datos de suscripción y condiciones efectivas del plan de la cuenta $v$.
- $\Delta S_{\text{plan}}(v,o)=0$: indica que la operación $o$ no modifica esos datos ni condiciones de la cuenta $v$.

### Invariante `INV-09` - Atomicidad de Operaciones

En `EC-03`, una contratación, renovación o cambio de plan fallido no puede dejar cobros, ingresos ni cambios parciales de suscripción o registros definitivos atribuibles a ese intento.

Para cada intento fallido, el estado afectado por ese intento después de su ejecución coincide con el inmediatamente anterior.

```math
\forall f \in F:\quad
S_{\text{despues}}(f)=S_{\text{antes}}(f)
```

**Leyenda:**

- $F$: conjunto de intentos fallidos o rechazados de contratación, renovación o cambio de plan.
- $S_{\text{antes}}(f)$: estado contable, de suscripción y registros afectados inmediatamente antes del intento $f$.
- $S_{\text{despues}}(f)$: esos mismos estados y registros después del intento, considerando sus efectos atribuibles.

## Casos Límite y Escenarios de Fallo

Los siguientes casos sirven de referencia para futuras pruebas de `EC-03`. Las referencias `INV-01` a `INV-09` corresponden a las invariantes de esta cadena. En una contratación, renovación o cambio fallido se revierten sus efectos, incluidos cobros, ingresos, cambios de suscripción y registros definitivos.

Cuando el resultado depende de una decisión pendiente, el caso indica qué debe cumplirse para cada opción sin elegirla anticipadamente. Los importes se expresan en unidades mínimas del token que se autorice para el cobro.

### Plan Activo, Contratación y Autorización

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Una cuenta todavía no tiene un plan asignado o no puede resolverse su plan. | La asignación inicial está pendiente. No se presupone un plan básico activo; una operación que requiera condiciones de plan y no pueda resolverlas se rechaza conforme a su cadena. | `INV-01`, `INV-04` |
| `CL-02` | La cuenta tiene un plan básico activo y contrata el plan de pago. | Si la transición se permite y se completa, el periodo de pago queda asociado a su cuota cobrada. En ningún instante se consideran activos simultáneamente ambos planes. | `INV-01`, `INV-02`, `INV-03` |
| `CL-03` | Una cuenta con plan de pago vigente solicita otra contratación del mismo plan. | La admisibilidad y el tratamiento del periodo previo están pendientes. Si se permite, cada periodo activado debe tener su cobro y mantenerse la unicidad del plan activo. | `INV-01`, `INV-02`, `INV-06` |
| `CL-04` | Un usuario o el administrador intenta contratar, renovar o cambiar la suscripción de otra cuenta. | Se rechaza la solicitud; la administración de planes no concede acceso a suscripciones o fondos ajenos. | Validaciones, `INV-08`, `INV-09` |
| `CL-05` | Se solicita un plan inexistente, no configurado o una transición no permitida. | Se rechaza sin cobro, ingreso ni cambio definitivo de suscripción. | Validaciones, `INV-01`, `INV-09` |
| `CL-06` | La cuota exigible no puede cobrarse o el cobro falla. | No se activa ni registra definitivamente el nuevo periodo y no se reconoce ingreso por esa cuota; se revierte el intento completo. | `INV-02`, `INV-03`, `INV-09` |
| `CL-07` | Se registra una solicitud o se inicia un cobro, pero la contratación no se completa. | No se considera activo el nuevo periodo por esos pasos provisionales; el estado afectado se revierte. | `INV-02`, `INV-09` |
| `CL-08` | El cobro se completa, pero el periodo registrado pertenece a otra cuenta o no corresponde a la operación. | La contratación no puede completarse como válida: cuota, cuenta, operación y periodo deben quedar vinculados correctamente; un fallo revierte sus efectos. | `INV-02`, `INV-03`, `INV-08`, `INV-09` |
| `CL-09` | Un periodo está pagado y registrado, pero su inicio es futuro. | Su eventual admisibilidad depende de la regla temporal. Si se permite, el cobro no adelanta por sí solo la activación ni convierte en activos dos planes. | `INV-01`, `INV-02` |
| `CL-10` | Se conservan registros históricos de varias suscripciones. | Los registros anteriores o futuros no se cuentan automáticamente como planes activos. La vigencia efectiva se resuelve por separado. | `INV-01`, `INV-05` |

### Cuotas, Fondos e Ingresos

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-11` | La configuración permite una cuota de importe cero. | Su admisibilidad y el significado de cobro correcto para importe cero están pendientes. Si se admite, debe existir el vínculo exigido con el periodo y no se genera un ingreso positivo. | `INV-02`, `INV-03`, `INV-06` |
| `CL-12` | La cuota es positiva y se cobra correctamente. | El importe cargado a los fondos autorizados coincide con el cobrado y con el incremento de ingresos retenidos, una sola vez y en el mismo token. | `INV-03` |
| `CL-13` | Se intenta cobrar con un token o una fuente de fondos no permitidos por la configuración aplicable. | Se rechaza sin activar el periodo ni dejar cobro o ingreso definitivo. Los tokens y fuentes admitidos para cuotas siguen pendientes de definición. | Validaciones, `INV-02`, `INV-03`, `INV-09` |
| `CL-14` | Se permite cobrar desde saldo disponible y este cubre exactamente la cuota. | Si se cumplen las demás condiciones, el cobro puede completarse y el saldo individual queda a cero; el total disponible del token disminuye por la cuota. | `INV-03` |
| `CL-15` | Se permite cobrar desde saldo disponible y este queda una unidad mínima por debajo de la cuota. | Se rechaza el cobro y se revierte la operación; no se utilizan fondos bloqueados ni saldos de terceros. | Validaciones, `INV-02`, `INV-03`, `INV-09` |
| `CL-16` | Se permite cobrar desde saldo disponible y el usuario tiene fondos bloqueados, deudas o participaciones del fondo. | Solo se carga el saldo disponible autorizado; esos otros estados no se utilizan ni se modifican para completar la operación. | Validaciones, `INV-03`, `INV-08` |
| `CL-17` | Se permite una fuente de cobro distinta del saldo disponible. | El cargo a la fuente autorizada y el ingreso deben coincidir con la cuota efectivamente cobrada. El efecto sobre custodia depende de la fuente y del flujo que se definan. | `INV-03` |
| `CL-18` | La transferencia o mecanismo de cobro falla, revierte o devuelve un resultado de fallo. | No se considera cobrada la cuota; se revierte la operación completa, sin ingreso ni periodo definitivos. | `INV-02`, `INV-03`, `INV-09` |
| `CL-19` | La cantidad efectivamente cobrada no coincide con la cuota exigible. | No se da por cumplido el cobro de la cuota completa ni se activa el periodo con un ingreso incorrecto. La operación fallida revierte sus efectos; no se presupone aceptación de pagos parciales. | `INV-02`, `INV-03`, `INV-09` |
| `CL-20` | Ya existen ingresos retenidos o saldos previos antes del cobro. | La operación atribuye a la cuota solo su propio cargo e incremento de ingresos; los importes previos no se cuentan nuevamente. | `INV-03` |
| `CL-21` | Varias cuentas pagan cuotas en el mismo token. | Cada cobro queda asociado a su propia cuenta y periodo; el aumento acumulado de ingresos es la suma de las cuotas efectivamente cobradas, cada una una sola vez. | `INV-02`, `INV-03`, `INV-08` |
| `CL-22` | Se admiten cuotas en distintos tokens. | Condicional a esa configuración: cada cobro e ingreso se contabiliza en su propio token, sin convertir ni sumar unidades de tokens distintos. | `INV-03` |
| `CL-23` | Un importe, ingreso acumulado o resultado de saldo alcanza o excedería el máximo representable. | Si todos los resultados exactos caben y se cumplen las demás condiciones, puede completarse; si alguno no cabe, se revierte la operación sin truncamiento ni desbordamiento. | Validaciones, `INV-03`, `INV-09` |

### Vigencia, Caducidad y Condiciones del Plan

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-24` | Se consulta inmediatamente antes, exactamente en y después del instante de caducidad. | Se aplica la regla temporal que se defina para cada instante. El límite exacto permanece pendiente; un periodo ya caducado no proporciona sus beneficios exclusivos. | `INV-01`, `INV-05` |
| `CL-25` | Un periodo ha caducado, pero sus datos siguen almacenados. | No se considera vigente por esos datos ni proporciona beneficios exclusivos. El plan aplicable después depende de la transición pendiente. | `INV-01`, `INV-05` |
| `CL-26` | Transcurre el tiempo de vigencia sin que el usuario solicite renovación. | No se produce renovación ni cobro automático. Una vez caducado, el periodo no proporciona sus beneficios exclusivos. | `INV-05`, `INV-06` |
| `CL-27` | El periodo anterior ha caducado y existe otro periodo de pago válidamente renovado. | El periodo anterior no proporciona beneficios; el nuevo solo los proporciona cuando esté vigente según la regla temporal definida. | `INV-01`, `INV-02`, `INV-05`, `INV-06` |
| `CL-28` | Una operación consulta el plan antes de un cambio, renovación o caducidad y se ejecuta después. | Si su cadena resuelve el plan al ejecutar, utiliza las condiciones vigentes en ese momento; no se presupone que la consulta anterior las congele. | `INV-04`, `INV-05` |
| `CL-29` | No puede resolverse una configuración de plan válida para una retirada o un pago. | La operación dependiente se rechaza conforme a `EC-01` o `EC-02`, sin aplicar una tasa inventada ni conservar efectos parciales. | `INV-04`, `INV-05` |
| `CL-30` | Las condiciones de dos planes o tipos de operación tienen tasas diferentes. | La operación usa la tasa que corresponda a su tipo y al plan vigente de la cuenta; no utiliza la de otro plan o tipo por error. | `INV-04` |
| `CL-31` | Una tasa o comisión calculada da una fracción de unidad mínima. | Se aplica la regla de cálculo y redondeo que se defina para esa operación y plan, respetando los límites de la cadena consumidora. | `INV-04` |
| `CL-32` | El administrador cambia una configuración mientras hay suscripciones vigentes. | El efecto sobre suscripciones y operaciones posteriores está pendiente. No se alteran por ello las condiciones fijadas previamente para préstamos existentes. | `INV-04`, `INV-07`, `INV-08` |

### Renovaciones y Cambios de Plan

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-33` | El usuario solicita renovar antes de la caducidad. | Su admisibilidad, inicio y tratamiento del tiempo restante están pendientes. Si se completa, debe haber cuota cobrada y periodo registrado sin vulnerar la unicidad del plan activo. | `INV-01`, `INV-02`, `INV-06` |
| `CL-34` | El usuario solicita renovar exactamente en la caducidad o después de ella. | Se aplican las reglas temporales y de renovación que se definan. Una renovación completada debe vincular su cuota y periodo; no activa retroactivamente el periodo caducado. | `INV-02`, `INV-05`, `INV-06` |
| `CL-35` | La renovación se solicita, pero falla el cobro o el registro del nuevo periodo. | Se revierte el intento. Una suscripción anterior conserva el estado que le corresponda por su propia vigencia; no aparece un nuevo periodo o cobro definitivo. | `INV-06`, `INV-09` |
| `CL-36` | Se solicitan renovaciones repetidas o mediante una llamada anidada. | Cada renovación completada debe ser manual, autorizada y tener su propia cuota y periodo correctamente vinculados. No se permite cobrar dos veces por una única operación ni crear periodos no respaldados. | `INV-02`, `INV-03`, `INV-06`, `INV-09` |
| `CL-37` | Una renovación válida registra un periodo que empieza en el futuro. | Si la regla lo permite, se registra y vincula a su cuota; sus beneficios solo se aplican durante su vigencia efectiva. | `INV-01`, `INV-02`, `INV-05`, `INV-06` |
| `CL-38` | Una cuenta solicita cambiar del plan de pago al básico antes de caducar. | La transición, su fecha de efecto y el tratamiento del tiempo pagado están pendientes. Si se permite, no deben quedar dos planes activos ni aplicarse ajustes no definidos. | `INV-01`, `INV-09` |
| `CL-39` | Un cambio de plan contempla un reembolso, prorrateo o cargo adicional. | Su existencia y cálculo están pendientes. Si se incorporan, deben definirse sus efectos contables y de autorización antes de ejecutar el flujo; la cuota cobrada no se confunde con el ajuste. | `INV-03`, `INV-09` |
| `CL-40` | La duración configurada, el instante de inicio o el cálculo de caducidad son inválidos o exceden el rango representable. | La operación se rechaza y revierte; no se registra un periodo truncado ni se deja un cobro definitivo. | Validaciones, `INV-02`, `INV-06`, `INV-09` |
| `CL-41` | Una cuenta cambia, renueva, contrata o deja caducar su plan con un préstamo existente. | La tasa de interés y la comisión de apertura fijadas al abrir el préstamo permanecen inalteradas por esa transición. La evolución propia de la deuda corresponde a su cadena. | `INV-07` |
| `CL-42` | Una cuenta sin préstamo existente cambia de plan y posteriormente abre uno. | `INV-07` no fija condiciones para un préstamo que aún no existe; la apertura debe usar las condiciones aplicables según las reglas de su cadena en ese momento. | `INV-04`, `INV-07` |

### Aislamiento y Atomicidad

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-43` | Dos cuentas tienen el mismo plan y una de ellas renueva o cambia. | La operación no modifica los datos ni las condiciones efectivas de la otra cuenta por ese hecho. | `INV-08` |
| `CL-44` | Una cuenta tiene una suscripción vigente y otra una suscripción caducada. | La operación de una cuenta no modifica la suscripción de la otra; la vigencia de cada una se resuelve según su propio periodo. | `INV-05`, `INV-08` |
| `CL-45` | Una validación falla antes de efectuar un cobro. | No queda cambio definitivo de suscripción, ingreso o registro atribuible al intento. | `INV-09` |
| `CL-46` | Falla una actualización después de un cargo o ingreso provisional. | Se revierte el intento completo, incluidos el cargo, el ingreso, el periodo y sus registros provisionales. | `INV-03`, `INV-09` |
| `CL-47` | Falla el registro definitivo después de actualizar provisionalmente la suscripción. | Se revierte la operación: no queda suscripción activa o renovada sin su cobro y registro correspondientes, ni cobro definitivo por el intento fallido. | `INV-02`, `INV-06`, `INV-09` |
| `CL-48` | Una secuencia combina contrataciones, renovaciones, cambios y solicitudes fallidas de varias cuentas. | Se comprueban las propiedades aplicables tras cada transición. Cada intento fallido conserva el estado inmediatamente anterior a ese intento, incluidos los efectos previos válidos. | `INV-01`–`INV-09` |
| `CL-49` | El estado previo ya contiene planes activos simultáneos o un periodo activo sin cobro vinculado. | La comprobación identifica el incumplimiento correspondiente. `EC-03` no define aquí un mecanismo de reparación ni garantiza que cada operación detecte cualquier inconsistencia previa. | `INV-01`, `INV-02` |

### Criterio de Cobertura

Aplicar los casos pertinentes a las transiciones permitidas y a cada fuente y token de cobro que se definan; comprobar cuentas individuales y múltiples, estados previos distintos y límites temporales y numéricos de la configuración. En las operaciones fallidas, comparar los estados afectados con los inmediatamente anteriores al intento. Las condiciones de `EC-01`, `EC-02`, `EC-08` y los préstamos se comprueban aquí solo en lo que depende de `EC-03`.

Esta matriz identifica clases de límites y fallos para `EC-03`; no demuestra que estén enumeradas todas las secuencias posibles ni sustituye las pruebas o una verificación formal. Los resultados dependientes de reglas pendientes deben concretarse antes de convertirlos en pruebas ejecutables.
