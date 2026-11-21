# `EC-05` Préstamos y Garantías

La cadena económica `EC-05` gestiona la apertura y el desembolso de préstamos con garantía, los límites aplicables y el bloqueo o la liberación de garantías que corresponda.

## Objetivo

El objetivo de esta cadena es permitir que una cuenta solicite un préstamo respaldado por una garantía suficiente y que el fondo desembolse el capital conforme a sus límites y liquidez. La garantía debe permanecer separada de los fondos disponibles mientras respalde obligaciones, y la deuda y las condiciones del préstamo deben quedar registradas.

En `v0.1.0` existe un único mercado de préstamos y cada cuenta puede tener como máximo un préstamo activo. La tasa de interés y la comisión de apertura se fijan al abrirlo según el plan vigente. La devolución de la deuda corresponde a `EC-06` y la liquidación y las pérdidas, a `EC-07`.

> Tokens permitidos: [tokens](../tokens.md)

El README distingue un activo para préstamos y otro para garantías; `tokens.md` identifica **MockUSD** para préstamos y **MockETH** principalmente para garantías. Las direcciones y la configuración exacta del mercado deben concretarse antes de implementarlo.

## Actores

En esta cadena intervienen los siguientes actores:

- El **prestatario** solicita el préstamo para su propia cuenta y aporta la garantía exigida.
- El **contrato de préstamos de Veyra** valida la solicitud, registra el préstamo y sus condiciones, y coordina el bloqueo de la garantía y el desembolso.
- El **contrato de cuentas** mantiene los saldos disponibles y bloqueados. La forma concreta de aportar la garantía y de recibir el desembolso está pendiente de definición.
- El **fondo de liquidez `EC-04`** proporciona el capital disponible para los préstamos; la liquidez del fondo es distinta de los saldos disponibles de los usuarios, las garantías y los ingresos del protocolo.
- La cadena de **planes y suscripciones `EC-03`** proporciona las condiciones aplicables al plan vigente al abrir el préstamo.
- La cadena de **intereses y devolución `EC-06`** gestiona la evolución de la deuda y su devolución, incluida la liberación de la garantía restante al saldarla.
- La cadena de **liquidaciones y pérdidas `EC-07`** gestiona las posiciones que incumplen el umbral de garantía y las pérdidas que correspondan.
- La cadena de **ingresos del protocolo `EC-08`** contabiliza la comisión de apertura efectivamente cobrada, según la regla de cobro que se defina.
- El **administrador** configura los parámetros autorizados del mercado y los precios simulados del entorno local. Esta función no le permite apropiarse de los fondos o garantías de los usuarios ni alterar arbitrariamente sus deudas.

## Variables y Estado Contable

Para cada préstamo debe poder identificarse al prestatario, su estado, el activo y el principal del préstamo, el activo y la cantidad de garantía bloqueada, y las condiciones fijadas en la apertura. Entre estas condiciones se incluyen la tasa de interés y la comisión de apertura determinadas según el plan vigente en ese momento.

El préstamo registra la deuda y el capital desembolsado conforme a la regla de apertura que se defina. La forma de calcular y cobrar la comisión de apertura, así como su relación con el principal y el importe recibido por el prestatario, está pendiente de definición. Una comisión solo se contabiliza como ingreso del protocolo cuando se ha cobrado efectivamente.

La garantía bloqueada para un préstamo debe distinguirse del saldo disponible del prestatario, de las garantías de otras cuentas, del patrimonio del fondo y de los ingresos del protocolo. No puede utilizarse como saldo disponible mientras permanezca comprometida.

El fondo mantiene separadas su liquidez disponible y las cantidades comprometidas en préstamos, conforme a `EC-04`. El desembolso y el reconocimiento del crédito deben contabilizarse sin atribuir al fondo fondos ajenos ni confundir la salida de liquidez con una pérdida.

Para valorar la garantía se utilizan precios simulados y configurables en el entorno local de `v0.1.0`. Las unidades, la precisión, los límites de validez del precio y la forma de obtenerlo y actualizarlo deben definirse antes de implementar las comprobaciones dependientes de él.

## Flujo Económico

### Flujo de Apertura del Préstamo

El usuario solicita abrir un préstamo e indica los datos necesarios para determinar el capital solicitado y la garantía que respaldará la operación. Veyra comprueba la identidad del prestatario, que no tenga otro préstamo activo, las condiciones del plan vigente y la configuración aplicable del mercado.

Veyra valora la garantía mediante el precio configurado, comprueba que el capital solicitado no exceda el límite permitido para esa garantía y verifica que el fondo dispone de liquidez suficiente para el desembolso y las demás salidas del fondo que correspondan.

Si se cumplen las validaciones, se bloquea la garantía, se registra el préstamo con su principal y condiciones de apertura y se efectúa el desembolso. Cualquier comisión de apertura efectivamente cobrada se contabiliza como ingreso; si su cobro se difiere, su tratamiento queda pendiente de definición. La operación queda registrada con los datos necesarios para relacionar estos movimientos.

El importe bruto, el importe recibido, el cobro de la comisión y la deuda inicial deben guardar la relación que establezca la regla de apertura que se defina. No se presupone que la comisión se descuente del desembolso, se añada a la deuda o se cobre por separado.

### Bloqueo y Gestión de la Garantía

La garantía debe quedar atribuida al préstamo y mantenerse bloqueada mientras corresponda. Si la garantía procede del saldo disponible de la cuenta, el bloqueo debe reducir ese saldo y el total disponible del token y aumentar el saldo bloqueado correspondiente, en coherencia con `EC-01`.

La admisibilidad de aportar garantía desde otra fuente, añadir o retirar garantía durante la vida del préstamo, y las condiciones de estas operaciones están pendientes de definición. Ninguna liberación puede convertir en disponible una garantía que deba seguir respaldando obligaciones conforme a las reglas aplicables.

### Desembolso y Liquidez del Fondo

El desembolso utiliza liquidez disponible del fondo. La reducción de esa liquidez y el registro del capital comprometido deben reflejar el movimiento efectivo, sin utilizar saldos disponibles, garantías o ingresos ajenos al fondo.

El destino del importe desembolsado está pendiente de definición. Si se acredita al saldo disponible del prestatario, deben aumentar su saldo individual y el total disponible correspondiente; si se utiliza un destino externo, deben definirse su autorización y efecto sobre la custodia.

La acreditación interna de un desembolso, si se adopta, requiere resolver una incompatibilidad documental con `INV-07` de `EC-01`: su texto indica que toda acreditación de saldo disponible debe provenir de un depósito válido y registrado. Un desembolso de préstamo es una operación distinta y no debe presentarse como depósito externo ni atribuir al usuario una transferencia directa no registrada. Antes de implementar ese destino deberán acordarse y actualizarse conjuntamente las reglas afectadas; esta cadena no modifica por sí sola la regla de `EC-01`.

### Devolución, Liberación y Liquidación

La evolución del interés simple sobre el principal pendiente y las devoluciones parciales o totales corresponden a `EC-06`. Al saldar la deuda, esa cadena gestiona la liberación de la garantía restante conforme a sus reglas; `EC-05` debe mantener los estados y límites necesarios para reflejarla.

Si la posición incumple el umbral de garantía, la liquidación y las pérdidas corresponden a `EC-07`. Los umbrales, la valoración durante la vida del préstamo y el tratamiento de la garantía y de la deuda tras una liquidación deben definirse con esa cadena.

El significado exacto de préstamo activo y el momento en que una cuenta puede abrir otro préstamo, después de una devolución completa o liquidación, están pendientes de definición. En ningún caso deben coexistir dos préstamos activos para la misma cuenta en `v0.1.0`.

## Validaciones y Restricciones

### Validaciones de Apertura

- El solicitante debe actuar para su propia cuenta y no tener otro préstamo activo según el estado que se defina para el mercado.
- El activo del préstamo y el de la garantía deben ser los configurados y autorizados para el mercado. Las direcciones se comprueban conforme a la configuración, no solo por nombre o símbolo.
- El capital solicitado y la garantía requerida deben ser mayores que cero y expresarse en las unidades mínimas de sus respectivos activos.
- La garantía debe estar disponible desde la fuente autorizada y quedar efectivamente bloqueada para la operación. No pueden utilizarse fondos bloqueados por otras obligaciones ni saldos de terceros.
- El precio y los parámetros utilizados para valorar la garantía deben estar configurados y ser válidos conforme a las reglas que se definan. Si no puede determinarse una valoración válida, la apertura se rechaza.
- El importe solicitado debe respetar el límite de préstamo calculado a partir del valor de la garantía. La fórmula, los umbrales, las unidades, la precisión, el redondeo y el tratamiento de la igualdad están pendientes de definición.
- El fondo debe disponer de liquidez suficiente para cubrir la salida total que le corresponda en la apertura. La liquidez comprometida o las reservas ajenas no completan el importe faltante.
- La tasa de interés y la comisión de apertura deben poder determinarse con las condiciones válidas del plan vigente y quedar fijadas para el préstamo. Si no puede resolverse una configuración válida, se rechaza la apertura.
- Los importes, las conversiones, los límites y los estados resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si falla una validación, el bloqueo, el desembolso, el cobro de una comisión exigible en la apertura o una actualización necesaria, la apertura debe revertirse por completo, sin garantía bloqueada, deuda, desembolso o ingreso definitivos parciales de ese intento.

### Validaciones de Garantías y Estado

- Cada garantía bloqueada debe estar asociada al préstamo y a la cuenta que corresponden. No puede utilizarse simultáneamente para cubrir otra obligación sin una regla expresa que lo permita.
- Cualquier modificación o liberación de garantía debe estar autorizada y cumplir las condiciones de cobertura que establezcan las cadenas responsables. Las operaciones que aún no estén definidas no se presuponen permitidas.
- Los cambios posteriores de plan no modifican retroactivamente la tasa de interés ni la comisión de apertura fijadas al abrir un préstamo existente.
- Los cambios de precio pueden afectar a la valoración de la garantía y al riesgo de la posición, pero no deben alterar por sí solos la cantidad de tokens bloqueados ni crear un desembolso o una devolución.
- El estado del préstamo debe permitir aplicar el límite de un préstamo activo por cuenta y distinguir la apertura de su posterior devolución o liquidación.

### Restricciones Pendientes de Definición

- Las direcciones de los activos del mercado, las fuentes autorizadas de garantía, el destino del desembolso y su integración contable con `EC-01` y `EC-04`.
- La fórmula del límite de préstamo, los parámetros de cobertura y liquidación, las unidades, los precios y sus condiciones de validez y actualización.
- El importe o tasa de la comisión de apertura, su fuente de cobro, el momento en que se cobra y su relación con el principal, el desembolso y la deuda inicial.
- La tasa de interés aplicable por plan, sus unidades y los datos necesarios para que `EC-06` calcule el interés simple sobre el principal pendiente.
- La posibilidad de añadir o retirar garantía durante el préstamo y las condiciones de autorización y cobertura para hacerlo.
- Los estados del préstamo, las transiciones tras devolución o liquidación y el momento en que la cuenta puede volver a solicitar otro préstamo.
- Los mínimos, el redondeo y los límites de representación de los cálculos y movimientos de la operación.

Estas decisiones deben concretarse antes de implementar los comportamientos que dependen de ellas. La devolución de deuda y la liquidación conservan las responsabilidades propias de `EC-06` y `EC-07`.

## Invariantes y Propiedades

Las siguientes propiedades son propuestas para `EC-05`. Describen los efectos atribuibles a cada operación y no fijan los parámetros ni las transiciones que siguen pendientes. Las variaciones se calculan como valor posterior menos valor anterior; los importes de activos diferentes no se suman sin una conversión definida.

Las comprobaciones de cobertura y LTV se refieren a los momentos expresamente indicados. Una variación posterior del precio puede dejar una posición por encima de un umbral sin que la apertura original haya incumplido sus condiciones; su tratamiento corresponde a las reglas de seguimiento y a `EC-07`.

### Invariante `INV-01` - Respaldo de Préstamos

En `EC-05`, cada préstamo debe abrirse con garantía suficiente conforme a la valoración, los parámetros de cobertura y el límite aplicables en ese momento.

Para cada apertura completada, la exposición que se defina para esa comprobación no puede superar la capacidad de endeudamiento calculada a partir de la garantía efectivamente bloqueada.

```math
\forall p \in P_{\text{apertura}}:\quad
E_{\text{apertura}}(p) \leq K_{\text{garantia}}(p)
```

**Leyenda:**

- $P_{\text{apertura}}$: conjunto de préstamos abiertos correctamente.
- $E_{\text{apertura}}(p)$: exposición utilizada para comprobar la apertura del préstamo $p$.
- $K_{\text{garantia}}(p)$: capacidad permitida para ese préstamo, calculada con la garantía bloqueada, su valoración y los parámetros aplicables al abrirlo.

La composición de la exposición, la fórmula de capacidad, el redondeo y la admisibilidad exacta de la igualdad están pendientes. La desigualdad expresa el límite máximo, sin decidir si la regla final exige un margen estricto.

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

La definición de custodia y reservas compartidas debe concretarse con las cadenas correspondientes. La presencia de tokens en un contrato no autoriza por sí sola a asignarlos a una garantía.

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
- $K_{\text{aplicable}}(p)$: límite resultante de las restricciones de garantía, mercado y cuenta que se definan para esa apertura.

Los límites adicionales, la composición de la exposición y el tratamiento exacto de la igualdad siguen pendientes. Esta propiedad no afirma que una posición conserve su capacidad inicial después de cambios de precio.

### Invariante `INV-04` - Conservación del Desembolso

En `EC-05`, la apertura debe relacionar la salida efectiva de liquidez del fondo, el importe recibido por el prestatario, las comisiones cobradas y la deuda inicial, sin crear fondos ni registrar movimientos inexistentes.

Para cada apertura, la salida del fondo debe coincidir con la suma de los importes que efectivamente reciben sus destinos como consecuencia de esa salida. El principal y la deuda inicial deben registrarse según la regla de apertura que se defina.

```math
\forall p \in P_{\text{apertura}}:\quad
A_{\text{salidaFondo}}(p)=\sum_{d \in D_p} A_{\text{recibido}}(p,d)
```

**Leyenda:**

- $P_{\text{apertura}}$: conjunto de préstamos abiertos correctamente.
- $A_{\text{salidaFondo}}(p)$: importe efectivamente cargado a la liquidez del fondo por la apertura $p$.
- $D_p$: destinos de esa salida en el mismo activo, incluido el prestatario y, si corresponde, el protocolo.
- $A_{\text{recibido}}(p,d)$: importe efectivamente acreditado al destino $d$ procedente de esa salida.

Una comisión cobrada desde otra fuente no se suma como destino de la salida del fondo: su cobro efectivo debe registrarse separadamente y una sola vez en `EC-08`. La relación exacta entre principal solicitado, principal registrado, deuda inicial y comisión financiada, descontada o cobrada por separado permanece pendiente. Hasta definirla, la fórmula anterior verifica los movimientos del fondo, pero no demuestra por sí sola la correspondencia de la deuda creada. La documentación y las pruebas deberán vincular la deuda inicial registrada con los movimientos y cargos que realmente la originen, conforme a la regla que finalmente se adopte.

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
- $\operatorname{activo}(p,\tau)$: indica que el préstamo $p$ está activo en ese instante según los estados y transiciones que se definan.
- $|\cdot|$: número de elementos del conjunto.

Los estados posteriores a la devolución o liquidación y el momento en que se permite una nueva apertura siguen pendientes.

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

La liberación de garantía restante al saldar la deuda corresponde a `EC-06`; la utilización o liberación en liquidación corresponde a `EC-07`. La expresión anterior se refiere a la liberación al prestatario, no al importe de garantía utilizado o adjudicado en una liquidación. Una posible retirada parcial de garantía durante el préstamo sigue pendiente de definición.

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
- $\operatorname{valorar}$: cálculo de valoración que debe definirse con sus unidades y límites.

El modelo local usa precios simulados configurables; los criterios de validez, actualización y precisión siguen pendientes. La igualdad no fija por sí sola una fórmula de conversión ni demuestra la calidad del precio.

### Invariante `INV-08` - Integridad del LTV

En `EC-05`, la apertura debe respetar el límite de relación préstamo-valor que se defina. Si se permiten modificaciones de garantía, sus condiciones de cobertura también deberán especificarse y comprobarse.

Para cada apertura completada con garantía valorada positivamente, el LTV calculado con la exposición definida y la valoración aplicable no supera el límite de apertura configurado.

```math
\forall p \in P_{\text{apertura}}:\quad
V_{\text{garantia}}(p)>0 \implies
\operatorname{LTV}_{\text{apertura}}(p)\leq L_{\text{maximo}}(p)
```

**Leyenda:**

- $P_{\text{apertura}}$: conjunto de préstamos abiertos correctamente.
- $V_{\text{garantia}}(p)$: valor de la garantía utilizado al abrir el préstamo $p$.
- $\operatorname{LTV}_{\text{apertura}}(p)$: relación préstamo-valor calculada con la exposición, valoración, unidades y redondeo que se definan.
- $L_{\text{maximo}}(p)$: límite de LTV aplicable a esa apertura.

Una valoración cero o inválida no puede utilizarse para completar una apertura que requiera esa comprobación. La regla exacta de igualdad, la exposición que integra el numerador y el tratamiento de modificaciones de garantía siguen pendientes. En particular, debe decidirse si se permite añadir garantía parcialmente a una posición ya por encima del límite; esta propiedad no impone una respuesta. La liquidación por cambios posteriores corresponde a `EC-07`.

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

Los importes se expresan en las unidades mínimas del activo correspondiente. Los casos que dependen de reglas pendientes se presentan como condicionales; no fijan la fórmula de LTV, el cobro de comisiones ni las transiciones de otras cadenas. Las pruebas de `EC-06` y `EC-07` se consideran aquí únicamente por sus efectos sobre las condiciones de `EC-05`.

### Apertura, Autorización y Estado del Préstamo

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Una cuenta sin préstamo activo solicita una apertura válida. | Puede completarse si cumple todas las condiciones de garantía, límite, liquidez y plan. Se registra un único préstamo con sus condiciones y movimientos correspondientes. | `INV-01`, `INV-04`, `INV-05`, `INV-10`, `INV-11` |
| `CL-02` | Una cuenta ya tiene un préstamo activo y solicita otro. | Se rechaza la apertura sin bloquear más garantía, crear deuda, desembolsar fondos ni cobrar una comisión definitiva. | `INV-05`, `INV-12` |
| `CL-03` | Una cuenta conserva registros de préstamos anteriores que ya no están activos. | Los registros históricos no cuentan automáticamente como activos. La posibilidad de abrir otro préstamo depende de los estados y transiciones que se definan. | `INV-05` |
| `CL-04` | Se intenta abrir otro préstamo después de una devolución total o liquidación. | El momento en que el préstamo anterior deja de estar activo y se permite una nueva apertura está pendiente. No pueden coexistir dos préstamos activos de la misma cuenta. | `INV-05` |
| `CL-05` | Un usuario o el administrador intenta abrir un préstamo con fondos o garantía de otra cuenta. | Se rechaza sin efectos definitivos. Administrar el mercado no concede acceso a fondos ajenos. | Validaciones, `INV-09`, `INV-12` |
| `CL-06` | Dos solicitudes simultáneas o anidadas intentan abrir préstamos para la misma cuenta. | Como máximo una puede quedar activa. Cada intento fallido revierte sus efectos; no se permite eludir la comprobación mediante una llamada anidada. | `INV-05`, `INV-12` |
| `CL-07` | El activo de préstamo o el token de garantía no coincide con la dirección autorizada, aunque comparta nombre o símbolo. | Se rechaza sin garantía bloqueada, deuda ni desembolso definitivos. | Validaciones, `INV-02`, `INV-12` |
| `CL-08` | El capital solicitado o la cantidad de garantía requerida es cero. | Se rechaza la apertura sin efectos definitivos. Los posibles mínimos superiores están pendientes de definición. | Validaciones, `INV-01`, `INV-12` |
| `CL-09` | El capital o la garantía es una unidad mínima o está cerca de un mínimo configurado. | Se aplican los mínimos, la valoración y el redondeo definidos para cada activo. Si no se cumplen todas las condiciones, se rechaza sin efectos parciales. | `INV-01`, `INV-03`, `INV-07`, `INV-12` |

### Garantía, Custodia y Aislamiento

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-10` | La garantía procede del saldo disponible, si esa fuente se autoriza. | El saldo individual y el total disponible del token disminuyen por la cantidad bloqueada; la misma cantidad queda atribuida a la garantía del préstamo, sin descontarla dos veces. | `INV-02`, `INV-06` |
| `CL-11` | El saldo disponible de garantía coincide con lo requerido o queda una unidad mínima por debajo. | En igualdad se supera esa comprobación si se cumplen las demás condiciones; una unidad por debajo impide cubrir el bloqueo con ese saldo. | `INV-02`, `INV-06`, `INV-12` |
| `CL-12` | La cuenta tiene saldo disponible insuficiente, pero posee fondos bloqueados por otra obligación. | No se reutilizan esos fondos para completar la garantía. Si no existe una fuente autorizada suficiente, se rechaza la apertura. | `INV-02`, `INV-06`, `INV-12` |
| `CL-13` | Se autoriza una fuente externa de garantía, pero falla su autorización o recepción. | La apertura se revierte; no quedan garantía bloqueada, deuda, desembolso ni comisión definitivos. | `INV-02`, `INV-12` |
| `CL-14` | La garantía efectivamente recibida o bloqueada no coincide con la requerida. | No se registra como respaldo una cantidad que no esté efectivamente disponible para el préstamo. La admisibilidad de diferencias depende de la regla definida; si no se cumplen sus condiciones, se revierte. | `INV-01`, `INV-02`, `INV-12` |
| `CL-15` | Hay garantías de varios prestatarios custodiadas en un mismo contrato. | Cada cantidad queda atribuida al préstamo y cuenta correspondientes; el respaldo debe cubrir la suma sin atribuir una misma unidad a obligaciones incompatibles. | `INV-02`, `INV-09` |
| `CL-16` | La garantía registrada supera el respaldo realmente custodiado o comparte indebidamente activos con otra reserva. | Se identifica un estado inconsistente respecto de la garantía. No se presupone un mecanismo de reparación ni que cada operación detecte cualquier inconsistencia previa. | `INV-02` |
| `CL-17` | El prestatario intenta retirar del saldo disponible una garantía que sigue comprometida. | La cantidad comprometida no está disponible para la retirada. La posible liberación requiere cumplir las reglas y autorización aplicables. | `INV-06` |
| `CL-18` | Se solicita liberar parte de la garantía durante la vida del préstamo. | La funcionalidad y su regla de cobertura están pendientes. Si se permite, solo se libera la cantidad autorizada para ese estado; si falla, no quedan cambios parciales. | `INV-06`, `INV-08`, `INV-12` |
| `CL-19` | Se solicita añadir garantía a una posición que ya supera un límite tras una caída de precio. | Su admisibilidad y la posibilidad de una mejora parcial están pendientes. Si se permite, se registra la cantidad efectivamente incorporada sin alterar garantías ajenas ni presentar el préstamo como automáticamente regularizado. | `INV-02`, `INV-08`, `INV-09` |
| `CL-20` | La deuda se salda y queda garantía bloqueada. | La liberación de la garantía restante corresponde a `EC-06` y debe reflejarse en el estado de garantía según sus reglas. No se presupone el destino ni una operación adicional no definida. | `INV-06` |
| `CL-21` | Una operación de un prestatario ocurre mientras otro tiene deuda y garantía. | La operación no modifica la deuda ni la garantía del otro prestatario por ese hecho, aunque ambos compartan mercado o token. | `INV-02`, `INV-09` |

### Valoración, Capacidad y LTV

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-22` | El precio requerido no está configurado o no cumple las condiciones de validez definidas. | Se rechaza la apertura que depende de ese precio, sin usar un valor inventado ni dejar efectos definitivos. | `INV-01`, `INV-07`, `INV-12` |
| `CL-23` | El precio o la valoración calculada de la garantía es cero. | No se completa una apertura que requiera una valoración positiva; no se divide entre cero para calcular el LTV. | `INV-01`, `INV-07`, `INV-08`, `INV-12` |
| `CL-24` | Un precio simulado cambia después de una consulta y antes de ejecutar la apertura. | Se utiliza el precio válido correspondiente al momento de comprobación definido para la operación. No se presupone que una consulta previa congele el precio ni que exista una protección de deslizamiento aún no definida. | `INV-01`, `INV-07`, `INV-08` |
| `CL-25` | Los activos de préstamo y garantía, o el precio, utilizan escalas y decimales distintos. | La valoración aplica las unidades, conversiones y redondeo definidos; no compara cantidades de activos distintos sin convertirlas. | `INV-07`, `INV-08` |
| `CL-26` | La conversión o el cálculo del límite produce una fracción de unidad mínima. | Se aplica el redondeo que se defina y se comprueba la exposición con ese mismo resultado. No se fija aquí el sentido del redondeo. | `INV-01`, `INV-03`, `INV-07`, `INV-08` |
| `CL-27` | La exposición está una unidad por debajo del límite aplicable. | Supera esa comprobación si la comparación en esas unidades es válida y se cumplen las demás condiciones; no se presupone aprobación de toda la apertura. | `INV-01`, `INV-03`, `INV-08` |
| `CL-28` | La exposición coincide exactamente con el límite aplicable. | La admisibilidad de la igualdad está pendiente. Si se acepta o rechaza, debe hacerse conforme a la regla final y de forma coherente con el cálculo del LTV. | `INV-01`, `INV-03`, `INV-08` |
| `CL-29` | La exposición supera el límite aplicable en una unidad o más. | Se rechaza la apertura sin efectos definitivos, incluso si existe liquidez suficiente en el fondo. | `INV-01`, `INV-03`, `INV-08`, `INV-12` |
| `CL-30` | El límite del mercado o de la cuenta es más restrictivo que el derivado de la garantía. | Si se configura ese límite, la apertura debe respetarlo además del límite de garantía; no se presume qué límites adicionales existirán. | `INV-01`, `INV-03` |
| `CL-31` | La composición de la exposición depende de una comisión financiada o de otra condición pendiente. | No se da por válida una apertura hasta definir qué integra la exposición y cómo se compara con el límite. La comisión no se omite ni se suma dos veces. | `INV-03`, `INV-04`, `INV-08` |
| `CL-32` | Un precio, una multiplicación, una conversión o un estado resultante excedería el rango representable. | Se rechaza y revierte la operación; no se acepta un límite o valoración truncados, desbordados o subdesbordados. | `INV-03`, `INV-07`, `INV-08`, `INV-12` |
| `CL-33` | Tras una apertura válida baja el precio y el LTV supera un umbral. | La apertura original no se considera inválida retroactivamente; el seguimiento y la eventual liquidación corresponden a las reglas que se definan con `EC-07`. El precio por sí solo no mueve la garantía. | `INV-01`, `INV-06`–`INV-08` |
| `CL-34` | Tras la apertura sube el precio de la garantía. | Cambia su valoración según la regla aplicable, pero no la cantidad de tokens bloqueados, la deuda registrada ni el desembolso por el mero cambio de precio. Una posible liberación requiere su propia regla. | `INV-06`–`INV-08` |

### Desembolso, Deuda y Comisión de Apertura

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-35` | El fondo tiene liquidez exactamente igual a la salida total de la apertura. | Supera la comprobación de liquidez si se cumplen las demás condiciones; la salida incluye las cantidades que deban salir del fondo por esa operación. | `INV-04`, `INV-10` |
| `CL-36` | La salida total requerida supera la liquidez disponible en una unidad mínima o más. | Se rechaza la apertura completa sin utilizar capital comprometido ni reservas ajenas para completar la diferencia. | `INV-10`, `INV-12` |
| `CL-37` | El patrimonio del fondo es positivo, pero su liquidez disponible es cero o insuficiente. | No se completa una salida superior a la liquidez disponible; no se confunde patrimonio con efectivo disponible. | `INV-10`, `INV-12` |
| `CL-38` | El desembolso se acredita al saldo disponible del prestatario, si se adopta ese destino. | Su saldo individual y el total disponible aumentarían por el importe acreditado. Antes de implementarlo debe resolverse la incompatibilidad con el texto de `INV-07` de `EC-01`; no se presenta como depósito externo ni como transferencia directa no registrada. | `INV-04`, `INV-09` |
| `CL-39` | Se utiliza un destino externo de desembolso, si se autoriza. | El importe efectivamente entregado y la salida del fondo se registran conforme a la regla definida; si el desembolso falla, se revierte la apertura. | `INV-04`, `INV-12` |
| `CL-40` | La comisión de apertura es cero. | Si la configuración la permite, no se reconoce ingreso positivo por esa comisión; los movimientos y la deuda inicial siguen la regla de apertura definida. | `INV-04`, `INV-11` |
| `CL-41` | La comisión se descuenta de la salida del fondo, si se adopta esa regla. | El importe recibido por el prestatario y la comisión procedente del fondo se contabilizan como destinos de esa salida, sin duplicarla. La deuda inicial sigue la regla que se defina. | `INV-04`, `INV-10` |
| `CL-42` | La comisión se cobra por separado desde una fuente autorizada, si se adopta esa regla. | El cobro y su ingreso se registran una sola vez; no se cuentan como salida del fondo si no proceden de él. Si el cobro requerido falla, se revierte la apertura. | `INV-04`, `INV-12` |
| `CL-43` | La comisión se financia o incorpora a la deuda, si se adopta esa regla. | Deben definirse el principal, la deuda inicial, la exposición para cobertura y la contabilización de la comisión. No se reconoce ingreso como cobrado sin el cobro efectivo que exijan las reglas. | `INV-03`, `INV-04`, `INV-08` |
| `CL-44` | La comisión calculada es igual o superior al importe solicitado. | Su admisibilidad depende de la regla de cobro y los límites pendientes. No se acepta un importe recibido negativo ni una apertura que incumpla conservación o cobertura. | `INV-03`, `INV-04`, `INV-12` |
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

Aplicar los casos pertinentes a las fuentes de garantía y destinos de desembolso que se autoricen, con una y varias cuentas, límites de importe y precio, y estados distintos de liquidez y garantía. Comprobar la cobertura en los momentos que se definan y comparar el estado inmediatamente anterior y posterior a cada intento fallido. La devolución, la liquidación y sus pérdidas se prueban aquí solo en cuanto afectan a las responsabilidades de `EC-05`.

Esta matriz identifica clases de límites y fallos para `EC-05`; no demuestra que se hayan enumerado todas las secuencias posibles ni sustituye las pruebas o una verificación formal. Las reglas pendientes de LTV, precios, comisiones, fuentes y transiciones deben concretarse antes de convertir los resultados condicionales en pruebas ejecutables.
