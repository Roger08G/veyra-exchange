# `EC-06` Intereses y Devolución

La cadena económica `EC-06` gestiona la evolución de los intereses de los préstamos de Veyra, sus devoluciones parciales o completas y la liberación de la garantía restante al saldar la deuda.

## Objetivo

El objetivo de esta cadena es calcular el interés simple sobre el principal pendiente de cada préstamo y permitir que su deuda se devuelva conforme a las reglas aplicables. Al saldarse la deuda, debe gestionarse la liberación de la garantía restante, manteniendo separados los fondos del prestatario, el patrimonio del fondo y los ingresos del protocolo.

En `v0.1.0`, la tasa de interés queda fijada al abrir el préstamo según el plan vigente. Las devoluciones pueden ser parciales o completas. La apertura y las condiciones iniciales corresponden a `EC-05`; la liquidación y las pérdidas corresponden a `EC-07`.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen los siguientes actores:

- El **prestatario** consulta el estado de su deuda y solicita devoluciones de su préstamo conforme a las condiciones aplicables.
- El **contrato de préstamos de Veyra** mantiene el estado necesario para calcular intereses, validar devoluciones, actualizar la deuda y coordinar la liberación de la garantía.
- El **contrato de cuentas** mantiene los saldos disponibles y bloqueados. Su relación concreta con la fuente de devolución y el destino de la garantía liberada está pendiente de definición.
- El **fondo de liquidez `EC-04`** recibe los importes que le correspondan por principal e intereses conforme a las reglas que se definan.
- La cadena de **préstamos y garantías `EC-05`** registra la apertura, el principal inicial, la tasa fijada y la garantía asociada al préstamo.
- La cadena de **liquidaciones y pérdidas `EC-07`** gestiona las posiciones liquidables y las pérdidas; la relación entre una devolución y una liquidación en curso debe concretarse con esa cadena.
- La cadena de **ingresos del protocolo `EC-08`** contabiliza únicamente los ingresos que correspondan al protocolo y hayan sido efectivamente cobrados, según las reglas que se definan.
- El **administrador** configura los parámetros autorizados del sistema. Esta función no le permite apropiarse de fondos o garantías ni modificar arbitrariamente la deuda de los usuarios.

## Variables y Estado Contable

Para cada préstamo deben poder identificarse el principal pendiente, el interés devengado y no pagado, la tasa de interés fijada en su apertura y la información temporal necesaria para calcular el interés hasta el momento de consulta o devolución. Los demás componentes de deuda, incluida una posible comisión de apertura financiada, dependen de las reglas pendientes de `EC-05`.

El interés del MVP es **simple sobre el principal pendiente**. Si una devolución reduce el principal, los periodos anteriores y posteriores deben calcularse con el principal que corresponda a cada intervalo. El interés acumulado no se suma automáticamente al principal como base de nuevos intereses.

La deuda pendiente, los fondos recibidos para devolverla, la liquidez del fondo, los ingresos del protocolo y la garantía bloqueada son partidas diferenciadas. Cada devolución completada debe quedar vinculada al préstamo, al importe efectivamente recibido y a la reducción de los componentes de deuda que correspondan.

**Reglas contables:** Una devolución solo reduce la deuda por los importes efectivamente recibidos y aplicados conforme a la regla de imputación que se defina. La devolución de principal y el cobro de intereses deben distinguirse; la devolución de principal no se registra automáticamente como rendimiento nuevo.

Los intereses cobrados se asignan al fondo o al protocolo según las reglas que se definan. Su efecto sobre el patrimonio del fondo debe coordinarse con `EC-04`, evitando reconocer dos veces un importe ya contabilizado. Solo las cantidades efectivamente cobradas que correspondan al protocolo se registran como ingresos en `EC-08`.

La fuente de fondos para devolver la deuda y el destino de la garantía liberada están pendientes de definición. Si se utiliza el saldo disponible de una cuenta, deben actualizarse su saldo individual y el total disponible del token en coherencia con `EC-01`.

## Flujo Económico

### Cálculo y Actualización del Interés

Veyra determina el principal pendiente, la tasa fijada al abrir el préstamo y el tiempo aplicable desde la última referencia contable pertinente. Con esos datos calcula el interés simple correspondiente y actualiza o consulta la deuda conforme a la regla que se defina.

Antes de aplicar una devolución que modifique el principal, debe tenerse en cuenta el interés correspondiente al periodo anterior con el principal vigente en ese intervalo. El interés posterior se calcula sobre el principal que quede pendiente, sin capitalizar automáticamente los intereses ya devengados.

La unidad temporal de la tasa, la precisión, el redondeo, el tratamiento de fracciones acumuladas y el momento exacto en que se registra el devengo están pendientes de definición. Una consulta no debe suponer por sí sola un cobro ni alterar las condiciones fijadas en `EC-05`.

### Flujo de Devolución Parcial

El usuario solicita devolver una cantidad de un préstamo que admita esa operación. Veyra comprueba su estado, determina la deuda aplicable al momento de la operación y valida la fuente y el importe de la devolución.

Si la devolución se completa, los fondos efectivamente recibidos se aplican a los componentes de deuda conforme al orden de imputación que se defina y se registran sus efectos en el préstamo y en las partidas correspondientes. Si se reduce el principal, este será la base para los periodos posteriores de interés simple.

El orden entre intereses, principal y otros componentes; las cantidades mínimas; y el tratamiento de un importe superior a la deuda están pendientes. La posibilidad de liberar parte de la garantía tras una devolución parcial también debe definirse: no se presupone una liberación automática.

### Flujo de Devolución Completa

El usuario solicita saldar el préstamo. Veyra determina los componentes pendientes y el importe necesario en el momento de ejecución, incluida la actualización del interés que corresponda conforme a la regla temporal definida.

Si la devolución completa se ejecuta y se han satisfecho todos los componentes exigibles, la deuda queda saldada, el estado del préstamo se actualiza y se gestiona la liberación de la garantía restante. Los fondos recibidos se contabilizan según su aplicación efectiva.

El destino de la garantía liberada, el tratamiento de posibles fracciones o residuos de deuda y el momento exacto en que el préstamo deja de contar como activo deben concretarse con `EC-05`. No se presupone que un importe consultado con anterioridad siga siendo suficiente si la deuda cambia antes de la ejecución.

### Liberación de la Garantía

Una vez saldada la deuda, la garantía restante atribuida exclusivamente a esa obligación debe quedar habilitada para su liberación. Debe dejar de estar bloqueada para esa obligación al ejecutarse la transición de liberación; si esta puede ser separada o diferida sigue pendiente de definición. La liberación debe respetar cualquier otra obligación legítima que afecte a los mismos activos y las reglas de atribución definidas con `EC-05`.

Si se decide acreditar la garantía liberada al saldo disponible, deben disminuir los saldos bloqueados correspondientes y aumentar el saldo individual y el total disponible del token. La acreditación debe coordinarse con `EC-01`: el texto actual de su `INV-07` indica que toda acreditación de saldo disponible debe proceder de un depósito válido, por lo que esa regla requiere revisión conjunta antes de implementar este destino.

La posible liberación de garantía durante una devolución parcial y el tratamiento de garantías afectadas por una liquidación se definirán con `EC-05` y `EC-07`, respectivamente.

## Validaciones y Restricciones

### Validaciones del Interés y la Deuda

- El préstamo debe estar identificado y su estado debe permitir calcular o consultar la deuda conforme a las reglas que se definan.
- La tasa aplicada debe ser la fijada al abrir el préstamo. Los cambios posteriores de plan no la modifican retroactivamente.
- El interés debe calcularse como interés simple sobre el principal pendiente que corresponda a cada periodo; no se aplican intereses sobre intereses por el mero hecho de acumularlos.
- El tiempo y la última referencia contable deben tratarse de forma coherente para no omitir ni contabilizar dos veces un mismo intervalo. Las unidades temporales y los límites exactos del cómputo están pendientes.
- Los importes, productos, conversiones temporales y estados resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si no pueden determinarse el estado, la tasa o los datos necesarios para una devolución válida, la operación se rechaza sin cambios parciales.

### Validaciones de Devoluciones

- La devolución debe identificar el préstamo y estar autorizada conforme a la regla que se defina. La posibilidad de que pague una cuenta distinta del prestatario permanece pendiente.
- El préstamo debe encontrarse en un estado que permita la devolución. El tratamiento de operaciones durante una liquidación se definirá con `EC-07`.
- El importe solicitado debe ser mayor que cero y utilizar el activo autorizado para devolver ese préstamo. Las direcciones y unidades del mercado se concretarán con `EC-05`.
- Los fondos deben proceder de una fuente autorizada y quedar efectivamente aplicados a la devolución; no puede reducirse la deuda por fondos inexistentes. Si se utiliza saldo disponible, debe cubrir el cargo y efectuarse el movimiento contable correspondiente; no se presupone una transferencia externa de tokens ya custodiados. No pueden usarse fondos bloqueados ni saldos de terceros sin una regla expresa que lo permita.
- La reducción de cada componente debe corresponder al importe efectivamente aplicado conforme al orden de imputación definido. No se permite reducir un componente por debajo de cero ni reconocer una devolución no recibida.
- Una devolución completa solo puede marcar la deuda como saldada si se han satisfecho todos los componentes exigibles conforme a las reglas definidas.
- Si falla una validación, la recepción de fondos o una actualización necesaria, la devolución debe revertirse por completo, sin cobros, reducciones de deuda, ingresos o registros definitivos parciales de ese intento.

### Validaciones de Liberación de Garantía

- La garantía liberada debe corresponder al préstamo y a la cuenta que procedan. No pueden liberarse garantías de otros préstamos o fondos sujetos a otras obligaciones.
- Al saldar la deuda debe gestionarse la liberación de la garantía restante conforme a la transición que se defina. Una devolución parcial no autoriza por sí sola una liberación parcial si no existe una regla que la permita.
- El destino de la garantía y sus actualizaciones contables deben estar definidos. Si se acredita al saldo disponible, debe resolverse la incompatibilidad documental señalada con `EC-01`.
- La devolución completa y la liberación deben coordinar sus estados y fallos conforme a la regla de ejecución que se defina; no se presupone que una liberación diferida o separada esté permitida.

### Restricciones Pendientes de Definición

- La composición exacta de la deuda inicial y de sus componentes posteriores, coordinada con `EC-05`, incluidas las posibles comisiones financiadas.
- La unidad, precisión y valores permitidos de la tasa, incluido el tratamiento de una eventual tasa negativa; el cómputo temporal, la actualización del devengo, el redondeo y el tratamiento de fracciones y residuos.
- El orden de imputación de devoluciones a intereses, principal y otros componentes, así como los mínimos y el tratamiento de pagos superiores a la deuda.
- La fuente autorizada de fondos, la posibilidad de pago por terceros y el destino de la garantía liberada.
- La asignación de intereses cobrados entre el fondo y el protocolo y su reconocimiento contable con `EC-04` y `EC-08`.
- Las condiciones de liberación parcial, la coordinación entre devolución completa y liberación, y el momento en que el préstamo deja de contar como activo.
- El tratamiento de devoluciones durante una liquidación y de cualquier garantía o deuda afectada por `EC-07`.

Estas decisiones deben concretarse antes de implementar los comportamientos que dependen de ellas. La apertura del préstamo y la liquidación conservan las responsabilidades propias de `EC-05` y `EC-07`.

## Invariantes y Propiedades

Las siguientes propiedades son propuestas para `EC-06`. Describen los efectos atribuibles a cada operación y conservan las decisiones pendientes sobre unidades, redondeo, imputación, otros componentes de deuda y tratamiento de garantías. Los importes de deuda se expresan en el activo y las unidades definidos para el préstamo.

Se distingue el **interés devengado acumulado**, antes de descontar pagos, del **interés pendiente**, que sí disminuye cuando se aplica una devolución. Para comparar una devolución con la deuda anterior y posterior, el interés debe estar actualizado al mismo instante de ejecución en ambos estados; los intereses generados por el transcurso del tiempo se evalúan por separado.

### Invariante `INV-01` - Integridad de Intereses

En `EC-06`, el interés simple devengado debe corresponder al principal pendiente durante cada intervalo, la tasa fijada al abrir el préstamo y el tiempo transcurrido. Los intereses ya devengados no se incorporan automáticamente al principal para generar nuevos intereses.

Antes del redondeo, el interés teórico acumulado es la suma de los intereses simples de los intervalos en los que el principal es constante. El cálculo efectivo debe aplicar las unidades, precisión y reglas de fracciones que se definan.

```math
I_{\text{teorico}}(p,\tau)
=\sum_{k\in K(p,\tau)} P_k\,r_p\,\frac{\Delta t_k}{T_r}
```

**Leyenda:**

- $p$: préstamo considerado; $\tau$: instante hasta el que se calcula el interés.
- $K(p,\tau)$: intervalos transcurridos desde el inicio aplicable hasta $\tau$, divididos cuando cambia el principal pendiente.
- $P_k$: principal pendiente durante el intervalo $k$.
- $r_p$: tasa simple fijada al abrir el préstamo, expresada por el periodo de referencia positivo $T_r$.
- $\Delta t_k$: duración del intervalo $k$, expresada en la misma unidad temporal que $T_r$.
- $I_{\text{teorico}}(p,\tau)$: interés devengado acumulado teórico antes de redondeo y sin descontar pagos.

Esta expresión no fija la unidad de la tasa, el instante inicial, el redondeo ni el tratamiento de fracciones. La igualdad del importe efectivo con un valor entero requiere definir esas reglas y su margen de precisión.

### Invariante `INV-02` - Consistencia de Deuda

En `EC-06`, la deuda pendiente debe reflejar todos sus componentes exigibles sin duplicaciones. Si solo existen principal e intereses pendientes, la deuda es su suma.

Para cada préstamo y momento de cálculo, la deuda total es el principal pendiente más el interés pendiente y, si se definen, los demás componentes exigibles.

```math
D(p,\tau)=P(p,\tau)+I_{\text{pendiente}}(p,\tau)+O(p,\tau)
```

**Leyenda:**

- $p$ y $\tau$: préstamo e instante de cálculo.
- $D(p,\tau)$: deuda total pendiente.
- $P(p,\tau)$: principal pendiente.
- $I_{\text{pendiente}}(p,\tau)$: interés devengado y no pagado.
- $O(p,\tau)$: suma de otros componentes exigibles definidos para ese préstamo; es cero si no existen.

La composición de $O$ está pendiente de coordinación con `EC-05`, incluida la posibilidad de una comisión financiada. Si un importe forma parte del principal, no puede contabilizarse de nuevo como otro componente.

### Invariante `INV-03` - Monotonía de Intereses

En `EC-06`, con tasa no negativa y principal no negativo, el interés devengado acumulado no disminuye por el simple transcurso del tiempo. El interés pendiente sí puede disminuir cuando se paga o se aplica otro ajuste autorizado que llegue a definirse.

Para dos instantes ordenados, sin correcciones o ajustes del devengo entre ellos, el interés teórico acumulado posterior no es menor que el anterior.

```math
\tau_2\geq\tau_1,\quad r_p\geq0,\quad
\forall t\in[\tau_1,\tau_2]: P(p,t)\geq0
\implies I_{\text{teorico}}(p,\tau_2)\geq I_{\text{teorico}}(p,\tau_1)
```

**Leyenda:**

- $p$: préstamo considerado.
- $\tau_1$ y $\tau_2$: instantes inicial y final del intervalo.
- $r_p$: tasa simple fijada para el préstamo.
- $P(p,t)$: principal pendiente en cada instante $t$ del intervalo considerado.
- $I_{\text{teorico}}(p,\tau)$: interés devengado acumulado antes de descontar pagos y de aplicar redondeo.

La precisión y el redondeo del importe registrado deben definirse de forma que no introduzcan una disminución indebida del devengo acumulado. Si el principal o la tasa son cero, el devengo del intervalo correspondiente es cero.

### Invariante `INV-04` - Conservación de Devoluciones

En `EC-06`, cada devolución completada debe reducir la deuda por el importe efectivamente recibido y aplicado a sus componentes. El devengo que ocurra antes de la ejecución debe contabilizarse antes de medir esa reducción.

Para cada devolución completada, comparando la deuda inmediatamente antes y después de aplicar el pago al mismo instante, la disminución es igual al importe total aplicado a deuda.

```math
\forall q\in Q:\quad
D_{\text{antes}}(q)-D_{\text{despues}}(q)=A_{\text{aplicado}}(q)
```

**Leyenda:**

- $Q$: conjunto de devoluciones completadas correctamente.
- $D_{\text{antes}}(q)$: deuda actualizada al instante de ejecución, antes de aplicar la devolución $q$.
- $D_{\text{despues}}(q)$: deuda después de aplicar esa devolución al mismo instante.
- $A_{\text{aplicado}}(q)$: importe efectivamente recibido y aplicado a reducir componentes de deuda.

El tratamiento de un eventual excedente recibido permanece pendiente; un importe no aplicado a deuda no se cuenta como reducción. Esta igualdad no presupone condonaciones, liquidaciones ni otros ajustes ajenos a la devolución.

### Invariante `INV-05` - Distribución de Pagos

En `EC-06`, cada devolución debe imputarse entre principal, intereses y otros componentes de deuda conforme a la regla que se defina. Cada reducción debe corresponder al importe efectivamente aplicado a ese componente.

Para cada devolución completada, la suma de los importes aplicados a los componentes es igual al total aplicado a deuda.

```math
\forall q\in Q:\quad
A_{\text{aplicado}}(q)=A_P(q)+A_I(q)+A_O(q)
```

**Leyenda:**

- $Q$: conjunto de devoluciones completadas correctamente.
- $A_P(q)$: importe aplicado al principal.
- $A_I(q)$: importe aplicado al interés pendiente.
- $A_O(q)$: importe aplicado a otros componentes exigibles definidos; es cero si no existen.
- $A_{\text{aplicado}}(q)$: suma efectivamente aplicada a la deuda.

Cada importe aplicado debe ser no negativo y no superar el componente pendiente correspondiente. El orden de imputación y los demás componentes continúan pendientes de definición.

Al comparar los componentes antes y después del pago en el mismo instante, las reducciones reales deben coincidir con los importes imputados:

```math
\forall q\in Q:\quad
P_{\text{antes}}(q)-P_{\text{despues}}(q)=A_P(q),\quad
I_{\text{antes}}(q)-I_{\text{despues}}(q)=A_I(q),\quad
O_{\text{antes}}(q)-O_{\text{despues}}(q)=A_O(q)
```

- $P_{\text{antes}}(q)$, $I_{\text{antes}}(q)$ y $O_{\text{antes}}(q)$: principal, interés pendiente y otros componentes actualizados al instante de la devolución, antes de aplicarla.
- $P_{\text{despues}}(q)$, $I_{\text{despues}}(q)$ y $O_{\text{despues}}(q)$: esos mismos componentes después de aplicar la devolución al mismo instante.

### Invariante `INV-06` - Límite de Devolución

En `EC-06`, una devolución no puede reducir la deuda o sus componentes por debajo de cero ni generar créditos que no correspondan a un importe efectivamente recibido y a una regla autorizada.

Para cada devolución completada, el importe aplicado a deuda no supera la deuda actualizada antes del pago y la deuda resultante es no negativa.

```math
\forall q\in Q:\quad
0\leq A_{\text{aplicado}}(q)\leq D_{\text{antes}}(q),
\qquad D_{\text{despues}}(q)\geq0
```

**Leyenda:**

- $Q$: conjunto de devoluciones completadas correctamente.
- $A_{\text{aplicado}}(q)$: importe aplicado a reducir deuda en la devolución $q$.
- $D_{\text{antes}}(q)$ y $D_{\text{despues}}(q)$: deuda inmediatamente antes y después de aplicar el pago al mismo instante.

La solicitud debe ser positiva, pero el tratamiento de importes superiores a la deuda y de cualquier excedente recibido está pendiente. Esta propiedad no presupone si se rechaza, devuelve o trata de otra forma autorizada.

### Invariante `INV-07` - Integridad Temporal

En `EC-06`, el cálculo del devengo no puede omitir ni contabilizar dos veces un mismo intervalo. Un cambio del principal debe separar el periodo previo del posterior con la base que corresponda a cada uno.

Para intervalos consecutivos y no solapados, el interés teórico acumulado en el intervalo completo es la suma de los intereses teóricos de sus partes, utilizando en cada tramo el principal correspondiente.

```math
I_{\text{teorico}}(p,\tau_0,\tau_2)
=I_{\text{teorico}}(p,\tau_0,\tau_1)
+I_{\text{teorico}}(p,\tau_1,\tau_2)
```

**Leyenda:**

- $p$: préstamo considerado.
- $\tau_0\leq\tau_1\leq\tau_2$: límites de intervalos consecutivos según la convención temporal que se defina.
- $I_{\text{teorico}}(p,a,b)$: interés simple teórico devengado entre los instantes $a$ y $b$, antes de redondeo y utilizando el principal aplicable a cada tramo.

El efecto del redondeo por actualización y de las fracciones pendientes debe definirse antes de exigir una igualdad exacta entre importes enteros registrados. Consultar o actualizar varias veces no debe por sí solo duplicar un intervalo.

### Invariante `INV-08` - Inmutabilidad de Condiciones

En `EC-06`, los cambios posteriores de plan o configuración no modifican retroactivamente la tasa fijada al abrir el préstamo.

Para cada préstamo y cada instante posterior en el que se calcule interés, la tasa aplicable a ese préstamo coincide con la fijada en su apertura.

```math
\forall p\in P,\quad \forall\tau\geq\tau_p:\quad
r_{\text{aplicada}}(p,\tau)=r_{\text{apertura}}(p)
```

**Leyenda:**

- $P$: conjunto de préstamos registrados sujetos al cálculo.
- $\tau_p$: instante de apertura del préstamo $p$.
- $r_{\text{apertura}}(p)$: tasa fijada al abrir el préstamo según `EC-05`.
- $r_{\text{aplicada}}(p,\tau)$: tasa utilizada para calcular su interés en el instante $\tau$.

Esta propiedad no congela el principal pendiente ni el interés acumulado, que evolucionan conforme a las devoluciones y al tiempo.

### Invariante `INV-09` - Consistencia del Fondo de Liquidez

En `EC-06`, los importes efectivamente recibidos y asignados al fondo deben actualizar sus partidas de principal, intereses y liquidez conforme a las reglas acordadas con `EC-04`. Una devolución de principal no se trata automáticamente como rendimiento y un interés ya reconocido no se contabiliza dos veces.

Para cada devolución completada, el importe recibido por el fondo atribuible a esa devolución coincide con la suma de los importes aplicados a sus partidas, según la asignación que se defina.

```math
\forall q\in Q:\quad
A_{\text{fondo}}(q)=\sum_{j\in J_{\text{fondo}}} A_j(q)
```

**Leyenda:**

- $Q$: conjunto de devoluciones completadas correctamente.
- $A_{\text{fondo}}(q)$: importe efectivamente recibido y atribuido al fondo por la devolución $q$.
- $J_{\text{fondo}}$: partidas del fondo a las que se asigna el importe, según la configuración definida.
- $A_j(q)$: importe de la devolución aplicado a la partida $j$ del fondo.

La variación de liquidez y patrimonio debe determinarse con la custodia, la asignación y el reconocimiento previo de activos e intereses. La expresión no presupone que todo el pago sea rendimiento ni que el incremento de patrimonio sea igual al efectivo recibido.

El registro de cada partida debe corresponder a los importes efectivamente asignados y su efecto sobre la liquidez debe reflejar el movimiento contable real. La ecuación identifica el reparto del importe recibido, pero no determina por sí sola la variación de liquidez o patrimonio: sus reglas y las posibles partidas previas deben concretarse con `EC-04`.

### Invariante `INV-10` - Liberación de Garantías

En `EC-06`, al saldar completamente la deuda debe gestionarse la liberación de la garantía restante del préstamo, respetando las demás obligaciones legítimas y las reglas de atribución aplicables.

Para cada devolución completa que salda la deuda, la garantía que queda comprometida exclusivamente por esa deuda pasa a estar disponible para su liberación conforme a la transición que se defina.

```math
\forall q\in Q_{\text{completa}}:\quad
D_{\text{despues}}(q)=0
\implies G_{\text{liberable}}(q)=G_{\text{restante}}(q)
```

**Leyenda:**

- $Q_{\text{completa}}$: devoluciones completadas que satisfacen todos los componentes exigibles.
- $D_{\text{despues}}(q)$: deuda restante tras aplicar la devolución completa $q$.
- $G_{\text{restante}}(q)$: garantía restante atribuida al préstamo y comprometida exclusivamente por esa deuda, una vez satisfechos sus componentes.
- $G_{\text{liberable}}(q)$: cantidad de esa garantía habilitada para liberarse conforme a las reglas aplicables.

El destino de la garantía y si la liberación se ejecuta en la misma operación siguen pendientes. Si se acredita al saldo disponible, debe resolverse la incompatibilidad documental señalada con `EC-01`. La garantía afectada por una liquidación se trata con `EC-07`.

### Invariante `INV-11` - Atomicidad de Devoluciones

En `EC-06`, una devolución fallida no puede dejar pagos, cambios de deuda o interés, movimientos de garantía, ingresos ni registros definitivos parciales atribuibles a ese intento.

Para cada intento fallido, los estados afectados y los registros después del intento coinciden con los inmediatamente anteriores, considerando exclusivamente sus efectos.

```math
\forall f\in F:\quad
S_{\text{despues}}(f)=S_{\text{antes}}(f)
```

**Leyenda:**

- $F$: conjunto de intentos fallidos o rechazados de devolución.
- $S_{\text{antes}}(f)$: estados de deuda, interés, saldos, garantía y registros afectados inmediatamente antes del intento $f$.
- $S_{\text{despues}}(f)$: esos mismos estados y registros después del intento, considerando sus efectos atribuibles.

La regla no elimina el interés correspondiente al paso del tiempo: exige revertir las actualizaciones realizadas por el intento fallido. La coordinación de una eventual liberación de garantía con la devolución completa sigue pendiente de definición.

## Casos Límite y Escenarios de Fallo

Los siguientes casos sirven de referencia para futuras pruebas de `EC-06`. Las referencias `INV-01` a `INV-11` corresponden a esta cadena. En una devolución fallida se revierten los efectos atribuibles al intento, incluidos cobros, actualizaciones de deuda e interés, movimientos de garantía, ingresos y registros definitivos.

Los importes se expresan en unidades mínimas del activo del préstamo. Cuando un resultado depende de una regla pendiente, el caso identifica las condiciones que deben conservarse sin elegir anticipadamente el redondeo, el orden de imputación, el tratamiento de excedentes o la política de liberación de garantía.

### Cálculo de Interés y Tiempo

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Se consulta o actualiza el préstamo sin que haya transcurrido tiempo desde la referencia aplicable. | El interés teórico del intervalo de duración cero es cero; no se duplica ningún devengo previo ni se registra un cobro por la consulta. | `INV-01`, `INV-03`, `INV-07` |
| `CL-02` | La tasa fijada es cero, si esa configuración se admite. | El interés teórico nuevo del intervalo es cero. Los intereses pendientes generados anteriormente no se eliminan por ello. | `INV-01`–`INV-03` |
| `CL-03` | El principal pendiente es cero, pero permanece interés u otro componente exigible. | No se genera interés simple nuevo sobre principal cero; los componentes aún pendientes no desaparecen por ese hecho y el préstamo no se considera saldado si son exigibles. | `INV-01`, `INV-02`, `INV-10` |
| `CL-04` | El principal y la tasa son positivos durante un intervalo válido. | El interés teórico corresponde al principal de ese intervalo, la tasa fijada y el tiempo transcurrido. El importe entero se determina con las reglas de precisión y redondeo que se definan. | `INV-01`, `INV-03` |
| `CL-05` | El cálculo produce una fracción de la unidad mínima del activo. | Se aplica la regla de redondeo y de conservación o tratamiento de fracciones que se defina; no se presupone una dirección de redondeo. | `INV-01`, `INV-07` |
| `CL-06` | Una consulta se repite varias veces en el mismo instante. | No se añade interés por tiempo cero, no se duplica el devengo ya reconocido y no se efectúa un cobro por consultar. | `INV-01`, `INV-07` |
| `CL-07` | Se consulta o actualiza varias veces dentro de un periodo sin cambiar el principal. | Cada intervalo temporal se cuenta una sola vez. La relación entre resultados enteros y fracciones depende de la regla de redondeo, que deberá definir los efectos de actualizaciones frecuentes. | `INV-01`, `INV-07` |
| `CL-08` | Se compara el interés teórico de un intervalo completo con la suma de dos intervalos consecutivos. | Los valores teóricos antes de redondeo coinciden. No se presupone igualdad exacta de importes enteros hasta definir el tratamiento de fracciones. | `INV-01`, `INV-07` |
| `CL-09` | La referencia temporal disponible es posterior al instante que se pretende calcular o los datos temporales son inválidos. | No se calcula un intervalo negativo ni se produce un devengo inventado. Si no puede resolverse un cálculo válido para la devolución, esta se rechaza sin efectos parciales. | `INV-01`, `INV-07`, `INV-11` |
| `CL-10` | La tasa, el principal, el tiempo o un cálculo intermedio excederían el rango representable. | Se rechaza el cálculo u operación afectada conforme a sus reglas; no se admiten desbordamientos, subdesbordamientos ni truncamientos silenciosos. Si falla una devolución, se revierten sus efectos. | `INV-01`, `INV-07`, `INV-11` |
| `CL-11` | La configuración contempla una tasa negativa. | Su admisibilidad está pendiente. La propiedad de monotonía solo se aplica a tasas no negativas; no se presupone cómo afectaría una tasa negativa a la deuda. | `INV-03` |
| `CL-12` | El plan cambia o caduca después de abrir el préstamo. | El cálculo del préstamo conserva la tasa fijada en su apertura; no se recalculan periodos anteriores ni posteriores con la nueva tasa del plan por ese cambio. | `INV-01`, `INV-08` |

### Deuda y Devoluciones Parciales

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-13` | La deuda solo tiene principal pendiente y el interés pendiente es cero. | La deuda total coincide con el principal, siempre que no existan otros componentes exigibles. | `INV-02` |
| `CL-14` | Hay principal, interés pendiente y otros componentes exigibles definidos. | La deuda total es la suma de los componentes sin duplicar ninguno. Si una comisión forma parte del principal, no se suma otra vez como componente separado. | `INV-02` |
| `CL-15` | El interés devengado acumulado es positivo, pero parte ya se ha pagado. | La deuda incluye el interés pendiente de pago, no todo el interés histórico devengado. La aplicación del pago no borra el historial del devengo. | `INV-02`, `INV-03`, `INV-05` |
| `CL-16` | El importe solicitado para la devolución es cero. | Se rechaza la devolución sin cobro ni efectos definitivos atribuibles al intento. | Validaciones, `INV-11` |
| `CL-17` | Se solicita devolver una unidad mínima del activo. | Se aplican el mínimo adicional y el orden de imputación que se definan. Si se completa, la reducción de deuda coincide con el importe efectivamente aplicado. | `INV-04`–`INV-06` |
| `CL-18` | Una devolución parcial se aplica solo a intereses, si la regla de imputación lo permite. | El interés pendiente disminuye por lo aplicado; el principal no cambia por ese pago y sigue siendo la base para el interés simple posterior. | `INV-01`, `INV-04`, `INV-05` |
| `CL-19` | Una devolución parcial reduce el principal. | Se tiene en cuenta primero el interés del intervalo anterior con su principal previo; el interés posterior usa el principal restante. La reducción de deuda coincide con lo aplicado. | `INV-01`, `INV-04`, `INV-05`, `INV-07` |
| `CL-20` | Una devolución se reparte entre principal, intereses y, si existen, otros componentes. | Las reducciones siguen el orden que se defina, no superan los componentes pendientes y suman exactamente el importe aplicado a deuda. | `INV-02`, `INV-04`–`INV-06` |
| `CL-21` | El importe aplicado coincide exactamente con uno de los componentes pendientes. | Ese componente queda a cero si la regla lo imputa íntegramente a él; los demás solo cambian por los importes que efectivamente les correspondan. | `INV-02`, `INV-05`, `INV-06` |
| `CL-22` | Se realizan varias devoluciones parciales en momentos distintos. | Cada operación actualiza primero el interés que le corresponde y aplica el pago conforme a la regla vigente; el principal de cada intervalo se utiliza una sola vez como base de ese intervalo. | `INV-01`, `INV-04`, `INV-05`, `INV-07` |
| `CL-23` | Se divide una devolución en varios pagos pequeños. | Cada pago se imputa conforme a las reglas definidas. No se presupone igualdad exacta con un único pago si cambian los instantes o el efecto del redondeo; no deben duplicarse intervalos ni reducciones. | `INV-04`, `INV-05`, `INV-07` |
| `CL-24` | El importe solicitado supera la deuda actualizada al ejecutar. | El rechazo o tratamiento del excedente está pendiente. Nunca se aplica a deuda más de lo pendiente ni se genera un crédito sin fondos efectivamente recibidos y una regla autorizada. | `INV-04`, `INV-06` |
| `CL-25` | Una cantidad previamente consultada coincidía con la deuda, pero transcurre tiempo antes de la ejecución. | Se calcula la deuda aplicable en el momento de ejecución. Si el importe ya no cubre todos los componentes, no se marca la deuda como saldada por basarse en la consulta anterior. | `INV-01`, `INV-02`, `INV-07`, `INV-10` |
| `CL-26` | El pago reduciría un componente por debajo de cero por un cálculo o estado inconsistente. | No se permite la reducción inválida; la devolución afectada se rechaza y revierte. La detección y reparación general del estado previo siguen pendientes. | `INV-05`, `INV-06`, `INV-11` |

### Autorización, Cobro y Asignación

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-27` | La devolución identifica un préstamo inexistente o uno cuyo estado no permite pagar. | Se rechaza sin cobro ni reducción de deuda definitivos. Los estados concretos deben definirse con `EC-05` y `EC-07`. | Validaciones, `INV-11` |
| `CL-28` | Una cuenta distinta del prestatario intenta pagar el préstamo. | La admisibilidad del pago por terceros está pendiente. Si se permite, debe existir autorización de la fuente y el pago solo afecta al préstamo identificado; si se rechaza, no hay efectos parciales. | Validaciones, `INV-04`, `INV-11` |
| `CL-29` | El pago utiliza un token no autorizado para devolver el préstamo. | Se rechaza sin reducir la deuda ni registrar un ingreso. La identidad del token se comprueba conforme a la configuración del mercado. | Validaciones, `INV-04`, `INV-11` |
| `CL-30` | La fuente es el saldo disponible de una cuenta, si se autoriza, y cubre exactamente el cargo. | Si se cumplen las demás condiciones, el pago puede completarse y el saldo individual queda a cero; el total disponible del token disminuye por el cargo correspondiente. El movimiento interno no presupone una transferencia externa de los tokens custodiados. | `INV-04`, `INV-06` |
| `CL-31` | La fuente autorizada es saldo disponible, pero queda una unidad mínima por debajo del cargo. | Se rechaza la devolución desde esa fuente; no se utilizan fondos bloqueados o ajenos para cubrir la diferencia sin una regla expresa. | `INV-04`, `INV-06`, `INV-11` |
| `CL-32` | Se autoriza una fuente externa y falla su autorización, transferencia o recepción. | No se reduce la deuda por fondos no recibidos; se revierten los efectos del intento. | `INV-04`, `INV-11` |
| `CL-33` | El importe efectivamente recibido difiere del solicitado. | No se reduce la deuda por más de lo recibido y aplicado. La admisibilidad de la diferencia depende del mecanismo definido; si no cumple sus condiciones, se revierte la devolución. | `INV-04`–`INV-06`, `INV-11` |
| `CL-34` | Se reciben fondos y una parte se asigna al fondo y otra al protocolo, si esa distribución se define. | Cada importe se registra una sola vez en su partida y los importes aplicados a deuda siguen la imputación definida; no se atribuye al fondo la parte asignada al protocolo. | `INV-04`, `INV-05`, `INV-09` |
| `CL-35` | Se devuelve principal sin interés nuevo atribuible al fondo. | El fondo refleja la devolución conforme a su contabilidad y custodia; la devolución de principal no se registra automáticamente como rendimiento adicional. | `INV-05`, `INV-09` |
| `CL-36` | Se cobra interés que el fondo ya había reconocido como activo, si esa regla de reconocimiento se adopta. | Se actualizan las partidas correspondientes sin sumar una segunda vez el mismo rendimiento al patrimonio por el mero cobro. | `INV-09` |
| `CL-37` | Una parte del interés se destina al protocolo conforme a una regla definida. | Solo se registra en `EC-08` el importe que corresponda y haya sido efectivamente cobrado; no se reconoce también como parte del fondo. | `INV-05`, `INV-09` |

### Devolución Completa y Garantía

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-38` | El importe aplicado coincide exactamente con la deuda actualizada y satisface todos sus componentes. | La deuda queda saldada y se gestiona la liberación de la garantía restante conforme a la transición definida. El tratamiento de residuos y el momento en que el préstamo deja de estar activo siguen pendientes. | `INV-02`, `INV-04`, `INV-06`, `INV-10` |
| `CL-39` | El importe aplicado deja una unidad mínima o un residuo exigible de deuda. | No se considera completamente saldada mientras exista un componente exigible; la regla de fracciones y residuos debe concretarse. No se libera automáticamente toda la garantía por este pago parcial. | `INV-02`, `INV-06`, `INV-10` |
| `CL-40` | El principal queda a cero, pero queda interés pendiente u otro componente exigible. | La deuda total conserva esos componentes y no se trata como saldada por el mero hecho de que el principal sea cero. | `INV-02`, `INV-06`, `INV-10` |
| `CL-41` | El interés pendiente queda a cero, pero sigue existiendo principal. | La deuda conserva el principal y puede seguir devengando interés simple conforme a la tasa y tiempo aplicables. | `INV-01`–`INV-03` |
| `CL-42` | Una devolución parcial solicita liberar parte de la garantía. | La admisibilidad y las condiciones están pendientes con `EC-05`. Una devolución parcial no autoriza por sí sola esa liberación. | `INV-10` |
| `CL-43` | La deuda se salda y existe garantía restante comprometida exclusivamente por ella. | Esa garantía queda disponible para su liberación conforme a la transición definida. El destino y si se libera en la misma operación permanecen pendientes. | `INV-10` |
| `CL-44` | Parte de los activos está sujeta legítimamente a otra obligación o ya ha sido afectada por una liquidación. | No se libera como garantía restante del préstamo una cantidad que no corresponda. La atribución y el tratamiento de liquidación se coordinan con `EC-05` y `EC-07`. | `INV-10` |
| `CL-45` | Se decide acreditar la garantía liberada al saldo disponible. | La cantidad correspondiente deja de estar bloqueada y se acredita al saldo individual y al total disponible conforme a la regla acordada. Antes de implementarlo debe resolverse la incompatibilidad señalada con `INV-07` de `EC-01`. | `INV-10` |
| `CL-46` | Se intenta devolver o liberar garantía mientras la posición está en liquidación. | La interacción y los estados permitidos están pendientes de definir con `EC-07`. No se presupone que ambas operaciones puedan consumir los mismos fondos o garantías. | `INV-06`, `INV-10`, `INV-11` |

### Integridad Temporal, Aislamiento y Atomicidad

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-47` | Se realiza una devolución y se intenta reutilizar la misma referencia temporal en una actualización posterior. | El intervalo anterior no se devenga por segunda vez; el siguiente cálculo usa la referencia y el principal correspondientes según la regla definida. | `INV-01`, `INV-07` |
| `CL-48` | Una devolución falla después de actualizar provisionalmente el interés. | Se revierten las actualizaciones atribuibles al intento. El interés por el tiempo transcurrido no se perdona: debe poder calcularse correctamente en una operación posterior. | `INV-01`, `INV-07`, `INV-11` |
| `CL-49` | Una validación falla antes de recibir los fondos. | No quedan cobros, reducciones de deuda, cambios de garantía, ingresos ni registros definitivos atribuibles al intento. | `INV-11` |
| `CL-50` | Falla una actualización después de recibir fondos o reducir provisionalmente la deuda. | Se revierte el intento completo, incluidos los movimientos de fondos y las actualizaciones de componentes e ingresos. | `INV-04`, `INV-05`, `INV-11` |
| `CL-51` | Falla el registro definitivo después de aplicar provisionalmente una devolución. | No permanece un cobro o una reducción de deuda definitivos sin el registro correspondiente; se revierten los efectos del intento. | `INV-04`, `INV-11` |
| `CL-52` | Falla la liberación de garantía durante una devolución completa. | Si se define como parte de la misma ejecución atómica, se revierten todos sus efectos. Si se define un proceso separado, deben establecerse sus estados, obligaciones y tratamiento de fallos antes de implementarlo. | `INV-10`, `INV-11` |
| `CL-53` | Una llamada anidada o repetida intenta aplicar dos veces los mismos fondos a la deuda. | Cada devolución completada debe corresponder a fondos efectivamente recibidos y aplicados una sola vez. Si no puede garantizarse, se revierte el intento afectado. | `INV-04`–`INV-06`, `INV-11` |
| `CL-54` | Una devolución afecta a una cuenta mientras otra mantiene deuda y garantía. | No se modifican por ese hecho la deuda ni la garantía de la otra cuenta; las partidas compartidas del fondo solo reflejan los importes que correspondan a la operación. | `INV-09`, `INV-11` |
| `CL-55` | Una secuencia combina consultas, pagos parciales, paso del tiempo y un intento fallido. | Se comprueban los intervalos y componentes tras cada transición. El intento fallido conserva el estado anterior a ese intento sin borrar el devengo económico del tiempo transcurrido. | `INV-01`–`INV-11` |
| `CL-56` | El estado previo contiene deuda total distinta de la suma de componentes, o referencias temporales incompatibles. | La comprobación identifica la inconsistencia correspondiente; no se presupone una reparación ni que cada operación detecte cualquier error previo. | `INV-02`, `INV-07` |

### Criterio de Cobertura

Aplicar los casos pertinentes con tasa y principal en sus límites admitidos, intervalos temporales diversos, una y varias devoluciones, componentes de deuda distintos y cada fuente y destino que se autoricen. Comparar la deuda antes y después de cada pago al mismo instante y comprobar por separado el devengo por el paso del tiempo. Las interacciones con `EC-04`, `EC-05`, `EC-07` y `EC-08` se consideran aquí solo en cuanto afecten a `EC-06`.

Esta matriz identifica clases de límites y fallos para `EC-06`; no demuestra que se hayan enumerado todas las secuencias posibles ni sustituye las pruebas o una verificación formal. Los resultados dependientes de la imputación, el redondeo, las fracciones y las transiciones pendientes deben concretarse antes de convertirlos en pruebas ejecutables.
