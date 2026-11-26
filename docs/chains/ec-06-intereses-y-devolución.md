# `EC-06` Intereses y Devolución

La cadena económica `EC-06` gestiona la evolución de los intereses de los préstamos de Veyra, sus devoluciones parciales o completas y la liberación de la garantía restante al saldar la deuda.

## Objetivo

El objetivo de esta cadena es calcular el interés simple sobre el principal pendiente de cada préstamo y permitir que su deuda se devuelva conforme a las reglas aplicables. Al saldarse la deuda, debe gestionarse la liberación de la garantía restante, manteniendo separados los fondos del prestatario, el patrimonio del fondo y los ingresos del protocolo.

El préstamo conserva la tasa de su plan de apertura. El interés simple se devenga por segundo hasta el cierre.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen los siguientes actores:

- El **prestatario** consulta el estado de su deuda y solicita devoluciones de su préstamo conforme a las condiciones aplicables.
- El **contrato de préstamos de Veyra** mantiene el estado necesario para calcular intereses, validar devoluciones, actualizar la deuda y coordinar la liberación de la garantía.
- El **contrato de cuentas** carga el disponible propio de MockUSD y acredita la garantía liberada en MockETH.
- El **fondo de liquidez EC-04** recibe íntegramente el principal y el interés.
- La cadena de **préstamos y garantías `EC-05`** registra la apertura, el principal inicial, la tasa fijada y la garantía asociada al préstamo.
- **EC-07** puede cerrar un préstamo elegible. Cada operación parte del estado confirmado por la anterior.
- **EC-08** registra la comisión de apertura en su cadena de origen. El interés de EC-06 corresponde al fondo.
- El **administrador** configura los parámetros autorizados del sistema. Esta función no le permite apropiarse de fondos o garantías ni modificar arbitrariamente la deuda de los usuarios.

## Variables y Estado Contable

Cada préstamo activo registra principal, interés entero pendiente, resto fraccionario, tasa anual de apertura y última marca de tiempo.

El interés del MVP es **simple sobre el principal pendiente**. Si una devolución reduce el principal, los periodos anteriores y posteriores deben calcularse con el principal que corresponda a cada intervalo. El interés acumulado no se suma automáticamente al principal como base de nuevos intereses.

La deuda pendiente, los fondos recibidos para devolverla, la liquidez del fondo, los ingresos del protocolo y la garantía bloqueada son partidas diferenciadas. Cada devolución completada debe quedar vinculada al préstamo, al importe efectivamente recibido y a la reducción de los componentes de deuda que correspondan.

**Reglas contables.** La devolución cubre primero el interés entero pendiente y después el principal.

El fondo reconoce todo el interés entero devengado al valorar su patrimonio. Cuando cobra, aumenta su caja y disminuye su crédito por igual importe.

La devolución sale del disponible de MockUSD del prestatario. Al saldar, la garantía vuelve a su disponible de MockETH.

## Flujo Económico

### Cálculo y Actualización del Interés

El interés se calcula desde la última actualización con el principal de ese intervalo y la tasa fijada al abrir.

Antes de aplicar una devolución que modifique el principal, debe tenerse en cuenta el interés correspondiente al periodo anterior con el principal vigente en ese intervalo. El interés posterior se calcula sobre el principal que quede pendiente, sin capitalizar automáticamente los intereses ya devengados.

Sea `K = 10 000 × 365 × 86 400`. Para un intervalo de `s` segundos con principal constante, calcular `N = resto_anterior + principal × tasa_en_pb × s`. Añadir `floor(N / K)` al interés pendiente y conservar `N mod K` para el próximo intervalo, incluso tras un pago parcial. La consulta proyecta el mismo resultado sin consumir el resto ni cambiar el reloj. En la apertura el resto y el interés pendiente empiezan en cero. Las marcas de devengo usan segundos de bloque. Dos operaciones del mismo préstamo en ese bloque se aplican en orden y la segunda tiene intervalo cero.

### Flujo de Devolución Parcial

El usuario solicita devolver una cantidad de un préstamo que admita esa operación. Veyra comprueba su estado, determina la deuda aplicable al momento de la operación y valida la fuente y el importe de la devolución.

Cada pago acredita la caja por el total cobrado. Se descuenta primero el interés entero y el sobrante reduce el principal que devengará en el siguiente intervalo.

Solo se admiten importes positivos de hasta la deuda entera actualizada, expresados en unidades mínimas de MockUSD. La garantía sigue bloqueada durante las devoluciones parciales.

### Flujo de Devolución Completa

El titular puede ordenar el cierre por el ID del préstamo. La deuda íntegra se calcula al ejecutar y se exige saldo disponible suficiente para ese importe exacto. También cierra una devolución por importe explícito que iguale la deuda actualizada. Si el importe explícito es inferior, solo se aplica ese pago. Si la supera, la operación revierte.

Si la devolución completa se ejecuta y se han satisfecho todos los componentes exigibles, la deuda queda saldada, el estado del préstamo se actualiza y se gestiona la liberación de la garantía restante. Los fondos recibidos se contabilizan según su aplicación efectiva.

En el cierre se descarta la fracción inferior a una unidad mínima de MockUSD, se abona la garantía y se marca el préstamo como cerrado, todo en la misma transacción.

### Liberación de la Garantía

El cierre mueve toda la garantía de la posición desde bloqueado hasta disponible del prestatario.

Se actualizan el saldo individual y el total disponible de MockETH. La contrapartida es la disminución exacta del bloqueo, conforme a EC-01.

Una liquidación utiliza el cierre de EC-07 y puede adjudicar parte o toda la garantía al liquidador.

## Validaciones y Restricciones

### Validaciones del Interés y la Deuda

- Solo se devenga sobre un préstamo activo.
- La tasa aplicada debe ser la fijada al abrir el préstamo. Los cambios posteriores de plan no la modifican retroactivamente.
- El interés debe calcularse como interés simple sobre el principal pendiente que corresponda a cada periodo; no se aplican intereses sobre intereses por el mero hecho de acumularlos.
- El devengo empieza al abrir y cada actualización contabiliza el intervalo transcurrido en segundos una sola vez.
- Los importes, productos, conversiones temporales y estados resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si no pueden determinarse el estado, la tasa o los datos necesarios para una devolución válida, la operación se rechaza sin cambios parciales.

### Validaciones de Devoluciones

- Solo el prestatario devuelve con su propio disponible mediante EC-06.
- La posición debe estar activa al ejecutar. Un cierre previo por EC-07 impide una nueva devolución.
- El activo es la dirección de MockUSD y la cantidad debe ser positiva.
- Se exige disponible propio de MockUSD suficiente. El cargo interno y la entrada en caja deben coincidir.
- La reducción de cada componente debe corresponder al importe efectivamente aplicado conforme al orden de imputación definido. No se permite reducir un componente por debajo de cero ni reconocer una devolución no recibida.
- Una devolución completa solo puede marcar la deuda como saldada si se han satisfecho todos los componentes exigibles conforme a las reglas definidas.
- Si falla una validación, la recepción de fondos o una actualización necesaria, la devolución debe revertirse por completo, sin cobros, reducciones de deuda, ingresos o registros definitivos parciales de ese intento.

### Validaciones de Liberación de Garantía

- La garantía liberada debe corresponder al préstamo y a la cuenta que procedan. No pueden liberarse garantías de otros préstamos o fondos sujetos a otras obligaciones.
- Una devolución parcial conserva el bloqueo completo.
- Un pago total acredita la garantía restante al disponible propio de MockETH.
- Si falla la liberación al cierre, revierte también la devolución.

### Restricciones del MVP

La tasa se expresa en puntos básicos anuales no negativos. Los componentes exigibles son el principal y el interés entero pendiente. El resto fraccionario se conserva hasta el cierre. La devolución y la liquidación leen el estado al ejecutar y solo una puede cerrar el préstamo.

## Invariantes y Propiedades

Las propiedades se comprueban al tiempo del bloque y en unidades mínimas de cada token.

Se distingue el **interés devengado acumulado**, antes de descontar pagos, del **interés pendiente**, que sí disminuye cuando se aplica una devolución. Para comparar una devolución con la deuda anterior y posterior, el interés debe estar actualizado al mismo instante de ejecución en ambos estados; los intereses generados por el transcurso del tiempo se evalúan por separado.

### Invariante `INV-01` - Integridad de Intereses

En `EC-06`, el interés simple devengado debe corresponder al principal pendiente durante cada intervalo, la tasa fijada al abrir el préstamo y el tiempo transcurrido. Los intereses ya devengados no se incorporan automáticamente al principal para generar nuevos intereses.

El interés teórico acumulado suma los intervalos en que el principal es constante. El resto arrastrado convierte esa suma en unidades enteras exigibles.

```math
I_{\text{teorico}}(p,\tau)
=\sum_{k\in K(p,\tau)} P_k\,r_p\,\frac{\Delta t_k}{T_r}
```

**Leyenda:**

- $p$: préstamo considerado; $\tau$: instante hasta el que se calcula el interés.
- $K(p,\tau)$: intervalos transcurridos desde el inicio aplicable hasta $\tau$, divididos cuando cambia el principal pendiente.
- $P_k$: principal pendiente durante el intervalo $k$.
- $r_p$: tasa anual expresada como fracción (puntos básicos divididos por 10 000). $T_r$ equivale a 31 536 000 segundos.
- $\Delta t_k$: duración del intervalo $k$, expresada en la misma unidad temporal que $T_r$.
- $I_{\text{teorico}}(p,\tau)$: interés devengado acumulado teórico antes de redondeo y sin descontar pagos.

El devengo efectivo usa segundos y conserva el resto de la división entre actualizaciones. Al cerrar se descarta únicamente el resto inferior a una unidad.

### Invariante `INV-02` - Consistencia de Deuda

La deuda pendiente del MVP es la suma de principal e interés entero pendiente.

La deuda entera es la suma del principal pendiente y el interés entero pendiente.

```math
D(p,\tau)=P(p,\tau)+I_{\text{pendiente}}(p,\tau)+O(p,\tau)
```

**Leyenda:**

- $p$ y $\tau$: préstamo e instante de cálculo.
- $D(p,\tau)$: deuda total pendiente.
- $P(p,\tau)$: principal pendiente.
- $I_{\text{pendiente}}(p,\tau)$: interés devengado y no pagado.
- $O(p,\tau)$: cero en el MVP. El préstamo exige exclusivamente principal e interés entero pendiente.

En v0.1.0, $O=0$ durante toda la vida del préstamo. La comisión de apertura ya se cobró.

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

El resto conservado evita perder fracciones al dividir un intervalo. Con principal o tasa cero el incremento teórico es cero.

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

Una solicitud superior a la deuda revierte íntegramente antes de aplicar fondos.

### Invariante `INV-05` - Distribución de Pagos

Cada devolución reduce primero el interés pendiente y después el principal, hasta agotar el pago.

Para cada devolución completada, la suma de los importes aplicados a los componentes es igual al total aplicado a deuda.

```math
\forall q\in Q:\quad
A_{\text{aplicado}}(q)=A_P(q)+A_I(q)+A_O(q)
```

**Leyenda:**

- $Q$: conjunto de devoluciones completadas correctamente.
- $A_P(q)$: importe aplicado al principal.
- $A_I(q)$: importe aplicado al interés pendiente.
- $A_O(q)$: cero en el MVP. La comisión de apertura ya se cobró.
- $A_{\text{aplicado}}(q)$: suma efectivamente aplicada a la deuda.

El mínimo entre el pago y el interés pendiente se aplica a interés. El resto reduce principal.

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

Se admite `0 < pago ≤ deuda` al tiempo de ejecución.

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
- $\tau_0\leq\tau_1\leq\tau_2$: marcas temporales consecutivas en segundos.
- $I_{\text{teorico}}(p,a,b)$: interés simple teórico devengado entre los instantes $a$ y $b$, antes de redondeo y utilizando el principal aplicable a cada tramo.

Con principal y tasa constantes, dividir el intervalo produce el mismo interés entero y el mismo resto que actualizarlo una vez.

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

En cada devolución la caja recibe la suma de los importes aplicados a principal e interés.

```math
\forall q\in Q:\quad
A_{\text{fondo}}(q)=\sum_{j\in J_{\text{fondo}}} A_j(q)
```

**Leyenda:**

- $Q$: conjunto de devoluciones completadas correctamente.
- $A_{\text{fondo}}(q)$: importe efectivamente recibido y atribuido al fondo por la devolución $q$.
- $J_{\text{fondo}}$: partidas del fondo a las que se asigna el importe, según la configuración definida.
- $A_j(q)$: importe de la devolución aplicado a la partida $j$ del fondo.

El cobro aumenta la caja y reduce los derechos por principal o intereses. Al mismo instante, el patrimonio del fondo se conserva.

EC-08 recibe cero por las devoluciones.

### Invariante `INV-10` - Liberación de Garantías

En `EC-06`, al saldar completamente la deuda debe gestionarse la liberación de la garantía restante del préstamo, respetando las demás obligaciones legítimas y las reglas de atribución aplicables.

La devolución total mueve en la misma transacción toda la garantía bloqueada por ese préstamo al disponible de su titular.

```math
\begin{aligned}
D_{\mathrm{despues}}(q)&=0,\qquad G_{\mathrm{bloqueada,despues}}(q)=0,\\
\Delta B_{\mathrm{disponible}}(u_q,\mathrm{MockETH},q)
&=G_{\mathrm{bloqueada,antes}}(q)
=-\Delta G_{\mathrm{bloqueada}}(q).
\end{aligned}
```

**Leyenda:**

- $Q_{\text{completa}}$: devoluciones completadas que satisfacen todos los componentes exigibles.
- $u_q$: titular del préstamo cerrado por la devolución $q$.
- $G_{\mathrm{bloqueada,antes}}(q)$ y $G_{\mathrm{bloqueada,despues}}(q)$: garantía de ese préstamo antes y después de la misma transacción.
- $\Delta B_{\mathrm{disponible}}$: abono efectivo de MockETH al titular. El total disponible del token aumenta por ese mismo importe.

La garantía restante se libera en la misma ejecución. El bloqueo baja y el disponible de MockETH del prestatario aumenta por el mismo importe.

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

Un fallo revierte también la liberación. El interés correspondiente al tiempo transcurrido puede volver a calcularse desde la última marca confirmada.

## Casos Límite y Escenarios de Fallo

Los siguientes casos sirven de referencia para futuras pruebas de `EC-06`. Las referencias `INV-01` a `INV-11` corresponden a esta cadena. En una devolución fallida se revierten los efectos atribuibles al intento, incluidos cobros, actualizaciones de deuda e interés, movimientos de garantía, ingresos y registros definitivos.

Los resultados se calculan en unidades mínimas. La deuda se compara al mismo instante antes y después del pago.

### Cálculo de Interés y Tiempo

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Se consulta o actualiza el préstamo sin que haya transcurrido tiempo desde la referencia aplicable. | El interés teórico del intervalo de duración cero es cero; no se duplica ningún devengo previo ni se registra un cobro por la consulta. | `INV-01`, `INV-03`, `INV-07` |
| `CL-02` | Se evalúa el límite matemático de interés con tasa cero. | El incremento es cero. La prueba de frontera de la fórmula se distingue del escenario de referencia, cuyas tasas son positivas. | `INV-01`–`INV-03` |
| `CL-03` | Estado preparado con principal cero e interés entero pendiente. | El devengo nuevo es cero y la deuda preparada conserva el interés entero. Este estado no se alcanza mediante las devoluciones ordinarias, que pagan interés antes de principal. | `INV-01`, `INV-02`, `INV-10` |
| `CL-04` | El principal y la tasa son positivos durante un intervalo válido. | El cociente entero y el resto se calculan sobre N con el denominador K establecido en esta cadena. | `INV-01`, `INV-03` |
| `CL-05` | El cálculo produce una fracción de la unidad mínima del activo. | Se conserva el resto de la división por K. Solo las unidades enteras entran en la deuda exigible. | `INV-01`, `INV-07` |
| `CL-06` | Una consulta se repite varias veces en el mismo instante. | No se añade interés por tiempo cero, no se duplica el devengo ya reconocido y no se efectúa un cobro por consultar. | `INV-01`, `INV-07` |
| `CL-07` | Se consulta o actualiza varias veces dentro de un periodo sin cambiar el principal. | Las consultas no cambian el estado. Las actualizaciones conservan el resto y producen el mismo resultado que el intervalo continuo. | `INV-01`, `INV-07` |
| `CL-08` | Se compara el interés teórico de un intervalo completo con la suma de dos intervalos consecutivos. | Coinciden el interés entero y el resto al final de ambos recorridos. | `INV-01`, `INV-07` |
| `CL-09` | La referencia temporal disponible es posterior al instante que se pretende calcular o los datos temporales son inválidos. | No se calcula un intervalo negativo ni se produce un devengo inventado. Si no puede resolverse un cálculo válido para la devolución, esta se rechaza sin efectos parciales. | `INV-01`, `INV-07`, `INV-11` |
| `CL-10` | El numerador de devengo exige más precisión que su cociente y su resto. | Se obtienen ambos con precisión suficiente. Un interés o una deuda final fuera de rango impide confirmar la operación y sus efectos. | `INV-01`, `INV-07`, `INV-11` |
| `CL-11` | Se intenta usar una tasa negativa. | Se rechaza la configuración. El interés simple del mercado se calcula con tasa anual no negativa. | `INV-03` |
| `CL-12` | El plan cambia o caduca después de abrir el préstamo. | El cálculo del préstamo conserva la tasa fijada en su apertura; no se recalculan periodos anteriores ni posteriores con la nueva tasa del plan por ese cambio. | `INV-01`, `INV-08` |

### Deuda y Devoluciones Parciales

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-13` | La deuda solo tiene principal pendiente y el interés pendiente es cero. | La deuda total coincide con el principal, siempre que no existan otros componentes exigibles. | `INV-02` |
| `CL-14` | Se intenta añadir la comisión de apertura a una deuda con principal e intereses. | La comisión ya se retuvo. La deuda exigible es principal más interés entero pendiente. | `INV-02` |
| `CL-15` | El interés devengado acumulado es positivo, pero parte ya se ha pagado. | La deuda incluye el interés pendiente de pago, no todo el interés histórico devengado. La aplicación del pago no borra el historial del devengo. | `INV-02`, `INV-03`, `INV-05` |
| `CL-16` | El importe solicitado para la devolución es cero. | Se rechaza la devolución sin cobro ni efectos definitivos atribuibles al intento. | Validaciones, `INV-11` |
| `CL-17` | Se solicita devolver una unidad mínima del activo. | Se admite con saldo y deuda suficientes. La unidad se aplica primero a interés y después a principal. | `INV-04`–`INV-06` |
| `CL-18` | Una devolución parcial se aplica solo a intereses. | El interés pendiente disminuye por lo aplicado; el principal no cambia por ese pago y sigue siendo la base para el interés simple posterior. | `INV-01`, `INV-04`, `INV-05` |
| `CL-19` | Una devolución parcial reduce el principal. | Se tiene en cuenta primero el interés del intervalo anterior con su principal previo; el interés posterior usa el principal restante. La reducción de deuda coincide con lo aplicado. | `INV-01`, `INV-04`, `INV-05`, `INV-07` |
| `CL-20` | Una devolución se reparte entre principal, intereses y, si existen, otros componentes. | La parte de interés es el mínimo entre pago e interés pendiente. Todo lo que reste reduce principal. | `INV-02`, `INV-04`–`INV-06` |
| `CL-21` | El importe aplicado coincide exactamente con uno de los componentes pendientes. | Ese componente queda a cero si la regla lo imputa íntegramente a él; los demás solo cambian por los importes que efectivamente les correspondan. | `INV-02`, `INV-05`, `INV-06` |
| `CL-22` | Se realizan varias devoluciones parciales en momentos distintos. | Cada operación actualiza primero el interés que le corresponde y aplica el pago conforme a la regla vigente; el principal de cada intervalo se utiliza una sola vez como base de ese intervalo. | `INV-01`, `INV-04`, `INV-05`, `INV-07` |
| `CL-23` | Se divide una devolución en varios pagos pequeños. | Cada pago se imputa conforme a las reglas definidas. No se presupone igualdad exacta con un único pago si cambian los instantes o el efecto del redondeo; no deben duplicarse intervalos ni reducciones. | `INV-04`, `INV-05`, `INV-07` |
| `CL-24` | El importe solicitado supera la deuda actualizada al ejecutar. | Se rechaza el importe completo sin debitar saldo ni modificar la deuda. | `INV-04`, `INV-06` |
| `CL-25` | Una cantidad previamente consultada coincidía con la deuda, pero transcurre tiempo antes de la ejecución. | Se calcula la deuda aplicable en el momento de ejecución. Si el importe ya no cubre todos los componentes, no se marca la deuda como saldada por basarse en la consulta anterior. | `INV-01`, `INV-02`, `INV-07`, `INV-10` |
| `CL-26` | El pago reduciría un componente por debajo de cero por un cálculo o estado inconsistente. | Se rechaza y revierte la operación. La prueba debe detectar la inconsistencia del estado. | `INV-05`, `INV-06`, `INV-11` |

### Autorización, Cobro y Asignación

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-27` | La devolución identifica un préstamo inexistente o uno cuyo estado no permite pagar. | Se rechaza. Solo una posición activa admite devoluciones. | Validaciones, `INV-11` |
| `CL-28` | Una cuenta distinta del prestatario intenta pagar el préstamo. | Se rechaza el pago por cuenta ajena. EC-07 regula los aportes del liquidador. | Validaciones, `INV-04`, `INV-11` |
| `CL-29` | El pago utiliza un token no autorizado para devolver el préstamo. | Se rechaza sin reducir la deuda ni registrar un ingreso. La identidad del token se comprueba conforme a la configuración del mercado. | Validaciones, `INV-04`, `INV-11` |
| `CL-30` | La fuente es el saldo disponible de una cuenta, y cubre exactamente el cargo. | Si se cumplen las demás condiciones, el pago puede completarse y el saldo individual queda a cero; el total disponible del token disminuye por el cargo correspondiente. El movimiento interno no presupone una transferencia externa de los tokens custodiados. | `INV-04`, `INV-06` |
| `CL-31` | La fuente autorizada es saldo disponible, pero queda una unidad mínima por debajo del cargo. | Se rechaza la devolución desde esa fuente; no se utilizan fondos bloqueados o ajenos para cubrir la diferencia sin una regla expresa. | `INV-04`, `INV-06`, `INV-11` |
| `CL-32` | Se intenta pagar directamente desde una cartera externa. | La devolución exige un disponible de MockUSD previamente respaldado. Se rechaza el cargo directo. | `INV-04`, `INV-11` |
| `CL-33` | El importe efectivamente recibido difiere del solicitado. | La devolución revierte si la caja no recibe exactamente el importe cargado. | `INV-04`–`INV-06`, `INV-11` |
| `CL-34` | Se intenta repartir una devolución entre fondo y tesorería. | El importe completo se asigna a la caja del fondo. EC-08 no recibe ninguna parte. | `INV-04`, `INV-05`, `INV-09` |
| `CL-35` | Se devuelve principal sin interés nuevo atribuible al fondo. | El fondo refleja la devolución conforme a su contabilidad y custodia; la devolución de principal no se registra automáticamente como rendimiento adicional. | `INV-05`, `INV-09` |
| `CL-36` | Se cobra interés que el fondo ya había reconocido como activo. | Se actualizan las partidas correspondientes sin sumar una segunda vez el mismo rendimiento al patrimonio por el mero cobro. | `INV-09` |
| `CL-37` | Se intenta asignar parte del interés a EC-08. | Se detecta una atribución incorrecta. El fondo recibe todo el interés. | `INV-05`, `INV-09` |

### Devolución Completa y Garantía

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-38` | El importe aplicado coincide exactamente con la deuda actualizada y satisface todos sus componentes. | Se cierra el préstamo, se descarta únicamente el resto fraccionario y se acredita la garantía en la misma transacción. | `INV-02`, `INV-04`, `INV-06`, `INV-10` |
| `CL-39` | El importe aplicado deja una unidad mínima o un residuo exigible de deuda. | Una unidad entera exigible mantiene el préstamo activo. Un resto inferior a esa unidad se descarta al saldar íntegramente principal e interés entero. | `INV-02`, `INV-06`, `INV-10` |
| `CL-40` | Una devolución pretende dejar el principal en cero con interés entero sin pagar. | Incumple el orden de imputación. La ejecución debe agotar el interés antes de tocar principal y cerrar al dejar la deuda entera a cero. | `INV-02`, `INV-06`, `INV-10` |
| `CL-41` | El interés pendiente queda a cero, pero sigue existiendo principal. | La deuda conserva el principal y puede seguir devengando interés simple conforme a la tasa y tiempo aplicables. | `INV-01`–`INV-03` |
| `CL-42` | Una devolución parcial solicita liberar parte de la garantía. | Se rechaza la liberación anticipada y la garantía sigue bloqueada mientras quede deuda. | `INV-10` |
| `CL-43` | La deuda se salda y existe garantía restante comprometida exclusivamente por ella. | La misma transacción devuelve toda la garantía de la posición al disponible del prestatario. | `INV-10` |
| `CL-44` | Parte de los activos está sujeta legítimamente a otra obligación o ya ha sido afectada por una liquidación. | Solo se libera la garantía de esta posición. Un cierre previo por liquidación impide otra liberación. | `INV-10` |
| `CL-45` | Se acredita la garantía al saldo disponible al cerrar. | El abono individual y el aumento del total disponible igualan el descenso del bloqueo propio de MockETH. | `INV-10` |
| `CL-46` | Se intenta devolver o liberar garantía mientras la posición está en liquidación. | Las transacciones se ordenan por ejecución. La segunda comprueba la deuda y el estado que dejó la primera. El cierre impide nuevas operaciones sobre esa posición. | `INV-06`, `INV-10`, `INV-11` |

### Integridad Temporal, Aislamiento y Atomicidad

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-47` | Se realiza una devolución y se intenta reutilizar la misma referencia temporal en una actualización posterior. | El intervalo anterior no se devenga por segunda vez; el siguiente cálculo usa la referencia y el principal correspondientes según la regla definida. | `INV-01`, `INV-07` |
| `CL-48` | Una devolución falla después de actualizar provisionalmente el interés. | Se revierten las actualizaciones atribuibles al intento. El interés por el tiempo transcurrido no se perdona: debe poder calcularse correctamente en una operación posterior. | `INV-01`, `INV-07`, `INV-11` |
| `CL-49` | Una validación falla antes de recibir los fondos. | No quedan cobros, reducciones de deuda, cambios de garantía, ingresos ni registros definitivos atribuibles al intento. | `INV-11` |
| `CL-50` | Falla una actualización después de recibir fondos o reducir provisionalmente la deuda. | Se revierte el intento completo, incluidos los movimientos de fondos y las actualizaciones de componentes e ingresos. | `INV-04`, `INV-05`, `INV-11` |
| `CL-51` | Falla el registro definitivo después de aplicar provisionalmente una devolución. | No permanece un cobro o una reducción de deuda definitivos sin el registro correspondiente; se revierten los efectos del intento. | `INV-04`, `INV-11` |
| `CL-52` | Falla la liberación de garantía durante una devolución completa. | Se revierten pago, cierre y movimientos de garantía en la misma transacción. | `INV-10`, `INV-11` |
| `CL-53` | Una llamada anidada o repetida intenta aplicar dos veces los mismos fondos a la deuda. | Cada devolución completada debe corresponder a fondos efectivamente recibidos y aplicados una sola vez. Si no puede garantizarse, se revierte el intento afectado. | `INV-04`–`INV-06`, `INV-11` |
| `CL-54` | Una devolución afecta a una cuenta mientras otra mantiene deuda y garantía. | No se modifican por ese hecho la deuda ni la garantía de la otra cuenta; las partidas compartidas del fondo solo reflejan los importes que correspondan a la operación. | `INV-09`, `INV-11` |
| `CL-55` | Una secuencia combina consultas, pagos parciales, paso del tiempo y un intento fallido. | Se comprueban los intervalos y componentes tras cada transición. El intento fallido conserva el estado anterior a ese intento sin borrar el devengo económico del tiempo transcurrido. | `INV-01`–`INV-11` |
| `CL-56` | El estado previo contiene deuda total distinta de la suma de componentes, o referencias temporales incompatibles. | La comprobación identifica la inconsistencia correspondiente; no se presupone una reparación ni que cada operación detecte cualquier error previo. | `INV-02`, `INV-07` |

### Criterio de Cobertura

Probar varios prestatarios, fracciones conservadas al actualizar, pagos de intereses y principal y cierre con liberación atómica. Comparar las deudas al mismo instante.

Esta matriz sirve para diseñar las pruebas de devengo, imputación y cierre.
