# `EC-07` Liquidaciones y Pérdidas

La cadena económica `EC-07` gestiona la liquidación de posiciones que incumplen el umbral de garantía y el reconocimiento de las pérdidas que correspondan al fondo de liquidez de Veyra.

## Objetivo

El objetivo de esta cadena es identificar las posiciones de préstamo que puedan liquidarse conforme a las reglas del mercado, procesar la garantía y los importes aplicables a la deuda, y reflejar las pérdidas reconocidas sin disponer indebidamente de fondos o garantías de terceros. El mecanismo que se defina podrá contemplar fondos propios aportados y autorizados por un ejecutor.

En `v0.1.0`, los préstamos están respaldados por garantía y se valoran con precios simulados y configurables en el entorno local. La deuda incobrable reduce el patrimonio del fondo y el valor de sus participaciones. Los umbrales y el mecanismo concreto de liquidación y reconocimiento de pérdidas están pendientes de definición.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen los siguientes actores:

- El **prestatario** es titular del préstamo y de la garantía asociada a la posición que se evalúa.
- El **ejecutor de la liquidación** inicia la operación si está autorizado conforme a la regla que se defina. No se presupone si será un tercero, una función del protocolo u otro actor.
- El **contrato de préstamos de Veyra** mantiene la información del préstamo, su deuda y garantía, y coordina los cambios de estado que correspondan a la liquidación.
- El **fondo de liquidez `EC-04`** recibe las recuperaciones que le correspondan y soporta las pérdidas netas atribuibles a él conforme a las reglas que se definan.
- La cadena de **préstamos y garantías `EC-05`** mantiene las condiciones de apertura y la información de la garantía asociada al préstamo.
- La cadena de **intereses y devolución `EC-06`** determina la deuda y el interés aplicables conforme a sus reglas. La interacción entre una devolución y una liquidación en curso está pendiente de definición.
- La cadena de **ingresos del protocolo `EC-08`** contabiliza únicamente los importes que correspondan al protocolo y se hayan cobrado efectivamente, conforme a las reglas que se definan.
- El **administrador** configura los parámetros autorizados del mercado y los precios simulados del entorno local. Esta función no le concede permiso para apropiarse arbitrariamente de fondos o garantías ni para declarar pérdidas fuera de las reglas del protocolo.

## Variables y Estado Contable

Para cada posición deben poder identificarse el prestatario, el estado del préstamo, los componentes de deuda aplicables y la cantidad de garantía bloqueada que le corresponde. La información de deuda e intereses debe ser coherente con `EC-05` y `EC-06` en el momento que se defina para evaluar y ejecutar la liquidación.

La evaluación necesita el precio y las unidades de los activos, el valor de la garantía y los parámetros que determinen si la posición incumple el umbral de liquidación. El README identifica un activo para préstamos y otro para garantías; `tokens.md` describe **MockUSD** para préstamos y **MockETH** principalmente para garantías. Las direcciones, las unidades, la precisión y las reglas de valoración deben concretarse con `EC-05`.

La garantía bloqueada, los saldos disponibles de los usuarios, el patrimonio del fondo y los ingresos del protocolo son partidas diferenciadas. Una liquidación solo puede afectar la garantía y la deuda de la posición autorizada y las demás partidas que correspondan a esa operación.

**Reglas contables:** El valor estimado de una garantía y los fondos efectivamente recuperados son magnitudes distintas. Un precio simulado permite valorar la posición, pero no acredita por sí solo que se hayan recibido o convertido activos para pagar la deuda.

Cada liquidación completada debe registrar la deuda considerada, la garantía utilizada o liberada y los importes efectivamente recibidos y aplicados, así como cualquier comisión, incentivo o pérdida reconocida que corresponda según las reglas definidas. Los importes de activos diferentes no se suman sin una conversión establecida.

La deuda que no se cubra en una operación no se considera automáticamente incobrable: deben definirse los criterios, el momento y la transición para reconocerla como tal. La pérdida neta atribuible al fondo debe considerar las recuperaciones y los importes previamente reconocidos, evitando contabilizarlos dos veces.

## Flujo Económico

### Evaluación de la Posición

Veyra identifica el préstamo y su estado, determina los componentes de deuda que correspondan y valora la garantía con el precio y los parámetros aplicables. Con esos datos comprueba si la posición cumple la condición de liquidación definida para el mercado.

La fórmula del umbral, el tratamiento de la igualdad, la precisión, el redondeo y las condiciones de validez del precio están pendientes. Una posición no debe liquidarse únicamente por una valoración que no pueda determinarse válidamente.

### Ejecución de la Liquidación

Un ejecutor autorizado solicita liquidar la posición. Veyra vuelve a comprobar las condiciones aplicables para la ejecución, incluida la deuda, la garantía disponible y el precio que corresponda según la regla temporal que se defina.

Si la operación se completa, se utilizan, transfieren o asignan las cantidades de garantía y se aplican a la deuda los importes efectivamente recibidos conforme al mecanismo definido. Se actualizan los estados y registros del préstamo, de la garantía y de las demás partidas afectadas.

El mecanismo de recuperación o conversión, la fuente de los fondos aplicados a la deuda, la participación de un tercero y la admisibilidad de una liquidación parcial están pendientes de definición. En particular, la valoración simulada de **MockETH** no implica por sí misma una conversión ni una entrada efectiva de **MockUSD**.

También están pendientes el orden de aplicación a principal, intereses y otros componentes, los posibles incentivos o comisiones y su fuente de cobro. No se presupone que un importe calculado como incentivo sea un ingreso del protocolo ni que se haya cobrado sin un movimiento efectivo.

### Garantía y Deuda Restantes

Tras la ejecución, la garantía restante y la deuda pendiente deben quedar atribuidas y registradas conforme al resultado real de la operación. Si una parte de la garantía deja de ser necesaria o la deuda queda saldada, su liberación o destino se determina mediante las reglas que se definan con `EC-05` y `EC-06`.

El tratamiento de una garantía sobrante, una deuda residual, una posible recuperación posterior y el estado de la posición después de una liquidación parcial o completa están pendientes de definición. No se presupone la liberación automática de toda la garantía ni la cancelación automática de toda la deuda.

Si se decide acreditar garantía liberada al saldo disponible del prestatario, esa regla debe coordinarse con `EC-01`: el texto actual de su `INV-07` indica que toda acreditación de saldo disponible debe proceder de un depósito válido y registrado. Antes de implementar ese destino deben acordarse y actualizarse conjuntamente las reglas afectadas.

### Reconocimiento de Pérdidas

Cuando se cumplan los criterios que se definan para reconocer una deuda como incobrable, Veyra debe determinar la pérdida neta atribuible al fondo considerando la deuda, las recuperaciones y los efectos ya reconocidos conforme a la contabilidad aplicable.

La pérdida reconocida reduce el patrimonio del fondo según el alcance del MVP y debe reflejarse en el valor de sus participaciones conforme a `EC-04`. La pérdida no modifica por sí sola el número de participaciones registradas de cada proveedor. El tratamiento de recuperaciones posteriores y de situaciones en que el patrimonio sea insuficiente sigue pendiente.

## Validaciones y Restricciones

### Validaciones de Elegibilidad

- El préstamo debe estar identificado y encontrarse en un estado que permita evaluar y, en su caso, ejecutar una liquidación.
- El ejecutor debe cumplir la regla de autorización que se defina. La configuración administrativa no concede por sí sola permiso para apropiarse de garantías o fondos ajenos.
- La deuda considerada debe actualizarse o determinarse conforme a las reglas de `EC-06` para el momento aplicable. No se debe omitir ni contar dos veces el interés correspondiente.
- La garantía utilizada en la comprobación debe corresponder a la posición y estar efectivamente atribuida y bloqueada conforme a `EC-05`.
- El precio y los parámetros necesarios deben estar configurados y ser válidos según las reglas que se definan. Si no puede determinarse una valoración válida, se rechaza la liquidación que dependa de ella.
- La posición debe cumplir la condición de liquidación aplicable al ejecutar la operación. El umbral, la igualdad y la relación entre una consulta previa y la ejecución están pendientes de definición.

### Validaciones de Ejecución y Contabilidad

- La garantía utilizada no puede superar la cantidad atribuida y disponible para esa posición. No pueden utilizarse garantías, saldos o reservas de terceros sin derecho o autorización para completar la operación. Los fondos propios que aporte voluntariamente un ejecutor, si el mecanismo los permite, se identifican y contabilizan por separado.
- La reducción de cada componente de deuda debe corresponder a los importes efectivamente aplicados como repago o a una baja autorizada por incobrabilidad, conforme al mecanismo y al orden de imputación definidos. El reconocimiento contable de una pérdida no supone por sí solo una baja de deuda. No puede reducirse un componente por debajo de cero ni registrar como recuperación una cantidad no recibida.
- La valoración de la garantía y las recuperaciones efectivas deben distinguirse. Cualquier conversión entre activos requiere un mecanismo y una regla de contabilización definidos.
- Los importes asignados al fondo, al protocolo, al ejecutor o al prestatario deben corresponder a las reglas de la operación y contabilizarse sin duplicaciones. Las comisiones e incentivos, si se establecen, deben tener una fuente y un destino definidos.
- Los cálculos, las conversiones y los estados resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si falla una validación, un movimiento necesario o una actualización contable, la ejecución afectada debe revertirse por completo, sin transferencias, reducciones de deuda, cambios de garantía, ingresos o pérdidas definitivos parciales de ese intento. La posibilidad de una liquidación parcial se refiere a su alcance permitido, no a conservar efectos de una ejecución fallida.

### Validaciones de Pérdidas y Estado

- El reconocimiento de una pérdida debe apoyarse en los criterios de incobrabilidad y la información contable que se definan. Una falta de liquidez inmediata o una deuda residual no bastan por sí solas para darla por incobrable.
- Las recuperaciones, pérdidas e importes reconocidos previamente deben tenerse en cuenta una sola vez al determinar el efecto neto sobre el patrimonio del fondo.
- El estado resultante debe distinguir las posiciones que mantienen deuda o garantía de las que se hayan cerrado conforme a las reglas aplicables. El momento en que la cuenta puede abrir otro préstamo debe coordinarse con `EC-05`.
- Una pérdida atribuible al fondo no puede cargarse arbitrariamente a saldos disponibles, garantías de terceros ni ingresos del protocolo; su efecto sobre patrimonio y participaciones se coordina con `EC-04`.

### Restricciones Pendientes de Definición

- La fórmula y los parámetros del umbral de liquidación, el tratamiento de la igualdad, las unidades, la precisión y el redondeo.
- Las condiciones de validez y actualización de precios y el momento de valoración de deuda y garantía para ejecutar la operación.
- Quién puede liquidar, el mecanismo de recuperación o conversión de garantía y la fuente de los fondos aplicados a la deuda.
- La posibilidad y los límites de liquidaciones parciales, los incentivos y comisiones, y su fuente y destino.
- El orden de imputación, el tratamiento de deuda y garantía residuales y la interacción con devoluciones de `EC-06`.
- Los criterios y el momento de reconocimiento de deuda incobrable, la cuantificación de la pérdida neta y el tratamiento de recuperaciones posteriores o patrimonio insuficiente.
- Los estados de la posición y el momento de cierre o de apertura de un nuevo préstamo, coordinados con `EC-05`.
- El destino de la garantía sobrante y la integración contable con `EC-01`, `EC-04`, `EC-05`, `EC-06` y `EC-08` cuando corresponda.

Estas decisiones deben concretarse antes de implementar los comportamientos que dependen de ellas. La apertura del préstamo, las devoluciones ordinarias y la contabilidad general del fondo conservan las responsabilidades propias de sus cadenas.

## Invariantes y Propiedades

Las siguientes propiedades son propuestas para `EC-07`. Describen los efectos atribuibles a cada operación y no fijan los umbrales, el mecanismo de recuperación, los incentivos, los límites de liquidación ni los criterios de incobrabilidad pendientes.

La deuda se compara antes y después de una ejecución al mismo instante de valoración, una vez determinado el interés que corresponda conforme a `EC-06`. Las cantidades de garantía se expresan en su propio token y las de deuda en el activo del préstamo; no se suman entre sí sin un mecanismo de conversión y contabilización definido. Una variación representa el valor posterior menos el anterior.

### Invariante `INV-01` - Elegibilidad de Liquidación

En `EC-07`, solo puede completarse la liquidación de una posición cuyo estado, autorización y condición de solvencia cumplan las reglas aplicables al ejecutar la operación.

Para cada liquidación completada, la posición debe ser elegible en el momento de ejecución según el umbral y los datos válidos correspondientes.

```math
\forall l\in L:\quad
\operatorname{elegible}(p_l,\tau_l)=\text{verdadero}
```

**Leyenda:**

- $L$: conjunto de ejecuciones de liquidación completadas correctamente.
- $p_l$: posición liquidada en la ejecución $l$.
- $\tau_l$: instante aplicable de comprobación al ejecutar $l$.
- $\operatorname{elegible}(p_l,\tau_l)$: resultado de aplicar las condiciones de estado y solvencia definidas para la posición, con datos válidos en ese instante.

La autorización del ejecutor debe comprobarse separadamente. La fórmula de elegibilidad, la igualdad con el umbral y el tratamiento de precios inválidos están pendientes de definición.

### Invariante `INV-02` - Integridad del Umbral de Liquidación

En `EC-07`, la evaluación de solvencia debe utilizar la deuda aplicable, la garantía atribuida a la posición, el precio válido y el umbral configurado, respetando las unidades y el redondeo definidos.

Para cada liquidación completada, el resultado de elegibilidad utilizado debe coincidir con el cálculo aplicado a esos datos en el momento correspondiente.

```math
\forall l\in L:\quad
E_{\text{utilizado}}(l)=
\operatorname{evaluar}(D_l,G_l,P_l,U_l,R_l)
```

**Leyenda:**

- $L$: conjunto de ejecuciones de liquidación completadas correctamente.
- $D_l$: deuda utilizada en la evaluación, determinada conforme a `EC-06`.
- $G_l$: garantía atribuida a la posición y utilizada en la evaluación.
- $P_l$: precio válido y escalas necesarias para valorar esa garantía.
- $U_l$: umbral y demás parámetros de solvencia aplicables.
- $R_l$: reglas de unidades, precisión y redondeo aplicables.
- $E_{\text{utilizado}}(l)$: resultado de elegibilidad empleado por la ejecución.
- $\operatorname{evaluar}$: cálculo que debe definirse para determinar ese resultado.

Esta igualdad identifica los datos necesarios, pero no fija la fórmula de LTV, el signo de la comparación ni el tratamiento de la igualdad. Si no puede obtenerse una valoración válida, no puede completarse la liquidación que dependa de ella.

### Invariante `INV-03` - Conservación de Deuda Liquidada

En `EC-07`, una reducción de la deuda durante una liquidación debe corresponder a importes efectivamente aplicados a su pago o a deuda dada de baja conforme a una regla válida de reconocimiento de incobrabilidad. Una valoración estimada de garantía no constituye por sí sola un repago efectivo.

Para cada ejecución completada, la disminución de deuda atribuible a ella coincide con el repago aplicado más la deuda dada de baja por incobrabilidad, si esa baja se ejecuta en la misma operación.

```math
\forall l\in L:\quad
D_{\text{antes}}(l)-D_{\text{despues}}(l)
=A_{\text{repago}}(l)+A_{\text{baja}}(l)
```

**Leyenda:**

- $L$: conjunto de ejecuciones de liquidación completadas correctamente.
- $D_{\text{antes}}(l)$ y $D_{\text{despues}}(l)$: deuda de la posición inmediatamente antes y después de la ejecución $l$, comparada al mismo instante de valoración.
- $A_{\text{repago}}(l)$: importe efectivamente recibido y aplicado a reducir deuda en esa ejecución.
- $A_{\text{baja}}(l)$: importe de deuda dado de baja en esa ejecución conforme a una regla válida de incobrabilidad; es cero si no se produce esa baja.

Todos los importes de la relación son no negativos y no pueden reducir un componente por debajo de cero. Reconocer una pérdida contable no implica necesariamente dar de baja la deuda del prestatario: esa transición y sus efectos deben definirse por separado. Los intereses del tiempo transcurrido se actualizan antes de comparar la deuda.

### Invariante `INV-04` - Conservación de Garantías

En `EC-07`, la garantía retirada de la posición durante una liquidación debe corresponder a cantidades efectivamente transferidas o reasignadas a destinos contables autorizados. La garantía valorada no debe contarse como garantía movida si no lo ha sido.

Para cada ejecución y token de garantía, la cantidad utilizada es igual a la suma de las cantidades realmente transferidas o reasignadas a sus destinos, contando cada unidad una sola vez.

```math
\forall l\in L:\quad
G_{\text{utilizada}}(l)=\sum_{d\in D_l} G_{\text{destino}}(l,d)
```

**Leyenda:**

- $L$: conjunto de ejecuciones de liquidación completadas correctamente.
- $G_{\text{utilizada}}(l)$: cantidad del token de garantía retirada de la posición para los destinos de la ejecución $l$.
- $D_l$: destinos efectivos o contables autorizados de esa garantía.
- $G_{\text{destino}}(l,d)$: cantidad atribuida al destino $d$ procedente de la garantía utilizada.

Una reasignación contable y su eventual transferencia física posterior no son dos destinos económicos de la misma unidad. El mecanismo y los destinos concretos siguen pendientes.

### Invariante `INV-05` - Límites de Liquidación Parcial

Si `EC-07` permite liquidaciones parciales, cada ejecución debe respetar los límites definidos tanto para la deuda aplicada como para la garantía utilizada, sin superar los saldos reales de la posición.

Para cada ejecución parcial completada, el repago y la garantía utilizada no superan sus límites ni las cantidades disponibles inmediatamente antes de la operación. Además, la reducción total de deuda por repago y baja no supera la deuda anterior.

```math
\forall l\in L_{\text{parcial}}:\quad
A_{\text{repago}}(l)\leq\min(D_{\text{antes}}(l),M_D(l)),\quad
G_{\text{utilizada}}(l)\leq\min(G_{\text{antes}}(l),M_G(l)),\quad
A_{\text{repago}}(l)+A_{\text{baja}}(l)\leq D_{\text{antes}}(l)
```

**Leyenda:**

- $L_{\text{parcial}}$: liquidaciones parciales completadas, únicamente si se permiten.
- $A_{\text{repago}}(l)$: importe efectivamente aplicado al pago de deuda en la ejecución.
- $A_{\text{baja}}(l)$: deuda dada de baja por incobrabilidad en la misma ejecución, si se permite; es cero si no se produce esa baja.
- $D_{\text{antes}}(l)$: deuda de la posición antes de la ejecución, actualizada al momento aplicable.
- $G_{\text{utilizada}}(l)$ y $G_{\text{antes}}(l)$: garantía utilizada y garantía atribuida disponible antes de la ejecución.
- $M_D(l)$ y $M_G(l)$: límites aplicables al importe de repago y a la utilización de garantía que se definan para la operación.

Los límites, el posible reconocimiento separado de pérdida y la admisibilidad de liquidaciones parciales siguen pendientes. Debe definirse si un límite adicional afecta también a la baja de deuda, además del límite de repago representado por $M_D$. La fórmula no permite dar de baja deuda o utilizar garantía fuera de las demás reglas aplicables.

### Invariante `INV-06` - Integridad del Incentivo de Liquidación

Si se establece un incentivo para el ejecutor, su cálculo, fuente y pago deben respetar las tasas y límites configurados. Un incentivo calculado no equivale a uno efectivamente pagado.

Para cada liquidación completada, el incentivo pagado no puede superar el máximo aplicable según la regla que se defina; si no existe incentivo, ambos importes son cero.

```math
\forall l\in L:\quad
0\leq A_{\text{incentivo}}(l)\leq M_{\text{incentivo}}(l)
```

**Leyenda:**

- $L$: conjunto de ejecuciones de liquidación completadas correctamente.
- $A_{\text{incentivo}}(l)$: incentivo efectivamente pagado o asignado al ejecutor conforme al mecanismo definido.
- $M_{\text{incentivo}}(l)$: máximo aplicable calculado con la tasa, base, unidades y redondeo que se definan.

La fórmula no fija la tasa, el activo ni la fuente del incentivo, ni basta por sí sola para verificar su cálculo exacto. Si se establece una recompensa exigible, su importe pagado o asignado debe corresponder también al cálculo configurado y al redondeo aplicable. Si procede de la garantía, debe estar incluido una sola vez en los destinos de `INV-04`; no se considera automáticamente ingreso del protocolo.

### Invariante `INV-07` - Protección de Garantías Restantes

En `EC-07`, la garantía no utilizada por una liquidación debe permanecer correctamente atribuida a la posición o a su titular según la transición autorizada. No puede asignarse arbitrariamente al ejecutor, al fondo o al protocolo.

Para cada ejecución completada, la garantía anterior se distribuye entre la garantía utilizada, la liberada o reasignada válidamente al titular y la que permanece atribuida a la posición.

```math
\forall l\in L:\quad
G_{\text{antes}}(l)=G_{\text{utilizada}}(l)
+G_{\text{liberada}}(l)+G_{\text{restante}}(l)
```

**Leyenda:**

- $L$: conjunto de ejecuciones de liquidación completadas correctamente.
- $G_{\text{antes}}(l)$: garantía atribuida a la posición inmediatamente antes de la ejecución.
- $G_{\text{utilizada}}(l)$: garantía retirada de la posición para los destinos de la liquidación, según `INV-04`.
- $G_{\text{liberada}}(l)$: garantía que deja de estar comprometida para esa posición y se libera o reasigna válidamente al titular en esa ejecución.
- $G_{\text{restante}}(l)$: garantía que continúa atribuida a la posición tras la ejecución.

Las categorías deben ser excluyentes: una misma unidad no puede figurar simultáneamente como utilizada, liberada y restante. El destino y momento de liberación siguen pendientes, incluida su coordinación con `EC-01`.

### Invariante `INV-08` - Consistencia Posterior a la Liquidación

En `EC-07`, la deuda y la garantía registradas después de una ejecución deben reflejar exactamente los movimientos efectivamente realizados, sin saldos negativos ni cambios no justificados.

Para cada ejecución, las variaciones reales de deuda y garantía coinciden con los importes aplicados, dados de baja, utilizados y liberados que le correspondan.

```math
\forall l\in L:\quad
\Delta D(l)=-A_{\text{repago}}(l)-A_{\text{baja}}(l),\quad
\Delta G(l)=-G_{\text{utilizada}}(l)-G_{\text{liberada}}(l)
```

**Leyenda:**

- $L$: conjunto de ejecuciones de liquidación completadas correctamente.
- $\Delta D(l)$ y $\Delta G(l)$: variaciones registradas de deuda y garantía atribuida a la posición, comparadas al mismo instante de ejecución.
- $A_{\text{repago}}(l)$ y $A_{\text{baja}}(l)$: repago efectivamente aplicado y deuda dada de baja, según `INV-03`.
- $G_{\text{utilizada}}(l)$ y $G_{\text{liberada}}(l)$: garantía utilizada o liberada, según `INV-07`.

La fórmula se refiere a los efectos atribuibles exclusivamente a los movimientos enumerados de la liquidación. Si una operación autorizada incorpora garantía adicional u otro ajuste al mismo tiempo, debe identificarse y contabilizarse por separado; la variación total observada deberá incluir también ese efecto.

### Invariante `INV-09` - Reconocimiento de Deuda Incobrable

En `EC-07`, una deuda solo puede declararse incobrable si corresponde a una obligación real pendiente y cumple los criterios y el procedimiento de reconocimiento que establezca el protocolo.

Para cada reconocimiento completado, el importe declarado incobrable no puede superar la deuda pendiente elegible para ese reconocimiento y debe cumplir los criterios aplicables.

```math
\forall b\in B:\quad
0\leq A_{\text{incobrable}}(b)\leq D_{\text{elegible}}(b),\quad
\operatorname{criterios}(b)=\text{verdadero}
```

**Leyenda:**

- $B$: conjunto de reconocimientos completados de deuda incobrable.
- $A_{\text{incobrable}}(b)$: importe reconocido como incobrable en $b$.
- $D_{\text{elegible}}(b)$: deuda real pendiente que puede evaluarse en ese reconocimiento, excluidos importes ya reconocidos o cancelados según las reglas aplicables.
- $\operatorname{criterios}(b)$: resultado de aplicar el procedimiento y los criterios de incobrabilidad que deben definirse.

Una deuda residual después de liquidar no es automáticamente incobrable. El reconocimiento contable, una posible baja de deuda y las recuperaciones posteriores son transiciones distintas cuya relación permanece pendiente.

### Invariante `INV-10` - Distribución de Pérdidas

En `EC-07`, la pérdida neta reconocida que corresponda al fondo debe reducir su patrimonio y reflejarse en el valor de las participaciones conforme a `EC-04`, sin atribuirle dos veces un importe ya reconocido.

Para cada reconocimiento, la variación de patrimonio atribuible exclusivamente a la pérdida neta adicional del fondo coincide con el negativo de esa pérdida.

```math
\forall b\in B:\quad
\Delta H_{\text{fondo}}(b)=-P_{\text{netaFondo}}(b)
```

**Leyenda:**

- $B$: reconocimientos completados de pérdidas que afectan al fondo.
- $\Delta H_{\text{fondo}}(b)$: variación del patrimonio neto del fondo atribuible exclusivamente al reconocimiento $b$.
- $P_{\text{netaFondo}}(b)$: pérdida neta adicional no negativa atribuible al fondo, calculada considerando recuperaciones y efectos previamente reconocidos conforme a las reglas que se definan.

La pérdida no modifica por sí sola el número de participaciones. El tratamiento de patrimonio insuficiente y recuperaciones posteriores sigue pendiente; no se presupone una fórmula final de valoración.

### Invariante `INV-11` - Prevención de Doble Contabilización

En `EC-07`, un mismo importe de deuda, garantía, recuperación o pérdida no puede aplicarse o reconocerse más de una vez para producir el mismo efecto contable. Un mismo evento puede tener registros relacionados en distintas partidas cuando describen efectos diferentes.

Para cada unidad contable identificada y cada tipo de efecto, el número de aplicaciones definitivas de esa misma unidad para ese efecto no puede superar uno.

```math
\forall x\in X,\quad \forall e\in E:\quad
N_{\text{aplicaciones}}(x,e)\leq1
```

**Leyenda:**

- $X$: unidades o importes identificables mediante el mecanismo de trazabilidad que se defina.
- $E$: tipos de efecto contable, como aplicación a deuda, asignación de garantía o reconocimiento de pérdida.
- $N_{\text{aplicaciones}}(x,e)$: número de aplicaciones definitivas de la unidad $x$ al mismo efecto $e$.

El mecanismo de identificación, la granularidad de los importes y la relación entre recuperaciones posteriores y pérdidas previas deben definirse. Esta propiedad no prohíbe registrar, por ejemplo, un cobro y la reducción de deuda correspondiente como efectos distintos del mismo movimiento.

### Invariante `INV-12` - Aislamiento de Posiciones

En `EC-07`, la liquidación de una posición no puede modificar indebidamente la deuda o la garantía de otra. Las operaciones y ajustes autorizados de otras cadenas conservan sus propias reglas.

Para cada liquidación completada, la variación atribuible a esa ejecución en la deuda y garantía de cualquier otra posición es cero.

```math
\forall l\in L,\quad \forall p\in P:\quad
p\ne p_l\implies\Delta D(p,l)=0\quad\land\quad\Delta G(p,l)=0
```

**Leyenda:**

- $L$: conjunto de ejecuciones de liquidación completadas correctamente.
- $P$: conjunto de posiciones de préstamo registradas.
- $p_l$: posición liquidada en la ejecución $l$.
- $\Delta D(p,l)$ y $\Delta G(p,l)$: variaciones de deuda y garantía de la posición $p$ atribuibles exclusivamente a $l$.

Los efectos compartidos legítimos sobre el patrimonio del fondo se registran en sus propias partidas y no autorizan modificar la deuda o garantía de otra posición.

### Invariante `INV-13` - Atomicidad de Liquidaciones

En `EC-07`, una ejecución fallida no puede dejar reducciones de deuda, movimientos de garantía, incentivos, ingresos o pérdidas definitivas parciales atribuibles a ese intento.

Para cada intento fallido, los estados afectados y registros posteriores coinciden con los inmediatamente anteriores en lo relativo a los efectos de ese intento.

```math
\forall f\in F:\quad
S_{\text{despues}}(f)=S_{\text{antes}}(f)
```

**Leyenda:**

- $F$: conjunto de intentos fallidos o rechazados de liquidación.
- $S_{\text{antes}}(f)$: estados de deuda, garantía, saldos, incentivos, pérdidas y registros afectados inmediatamente antes del intento $f$.
- $S_{\text{despues}}(f)$: esos mismos estados y registros después del intento, considerando sus efectos atribuibles.

La atomicidad se refiere a cada ejecución, incluso si se permiten liquidaciones parciales. No elimina el interés que corresponda por el transcurso del tiempo ni revierte operaciones anteriores completadas.

## Casos Límite y Escenarios de Fallo

Los siguientes casos sirven de referencia para futuras pruebas de `EC-07`. Las referencias `INV-01` a `INV-13` corresponden a esta cadena. En cada ejecución fallida se revierten sus efectos, incluidos movimientos de garantía, reducciones de deuda, incentivos, ingresos, pérdidas y registros definitivos.

Las cantidades de deuda se expresan en las unidades del activo del préstamo y las de garantía en las unidades de su propio token. Los resultados que dependen del umbral, el mecanismo de recuperación, los incentivos, las liquidaciones parciales o los criterios de incobrabilidad se indican como condicionales y deben concretarse antes de implementarlos.

### Elegibilidad, Precio y Umbral

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Se intenta liquidar una posición que no cumple la condición de liquidación. | Se rechaza la ejecución sin movimientos de garantía, reducción de deuda ni otros efectos definitivos. | `INV-01`, `INV-13` |
| `CL-02` | Una posición incumple el umbral conforme a datos válidos y su estado permite liquidarla. | Puede ejecutarse si el solicitante está autorizado y se cumplen todas las demás condiciones; la elegibilidad por sí sola no acredita fondos recuperados. | `INV-01`, `INV-02` |
| `CL-03` | La posición está exactamente en el umbral configurado. | La admisibilidad de la igualdad está pendiente. Se aplica la comparación que se defina, sin aceptar ni rechazar anticipadamente ese límite. | `INV-01`, `INV-02` |
| `CL-04` | La posición queda una unidad de la representación aplicable a cada lado del umbral. | Se evalúa cada lado con las unidades, precisión y redondeo definidos. La comparación y el tratamiento de la igualdad deben ser coherentes. | `INV-01`, `INV-02` |
| `CL-05` | El préstamo no existe, está cerrado o se encuentra en un estado que no permite liquidación. | Se rechaza sin efectos definitivos. Los estados exactos y sus transiciones siguen pendientes de definición. | `INV-01`, `INV-13` |
| `CL-06` | El solicitante no cumple la regla de autorización que se defina. | Se rechaza sin afectar deuda, garantía, incentivos ni otras partidas. La administración del mercado no concede por sí sola una facultad arbitraria sobre garantías. | Validaciones, `INV-01`, `INV-13` |
| `CL-07` | Falta el precio, no está configurado o no cumple las condiciones de validez definidas. | Se rechaza la liquidación que dependa de él; no se utiliza un precio inventado ni una valoración inválida. | `INV-01`, `INV-02`, `INV-13` |
| `CL-08` | El precio o el valor calculado de la garantía es cero. | Se aplica la regla de validez que se defina; no se divide entre cero ni se presume automáticamente un resultado de liquidación. Si la valoración no es válida para la ejecución, se rechaza. | `INV-01`, `INV-02`, `INV-13` |
| `CL-09` | El precio cambia entre una consulta y la ejecución. | Se comprueban nuevamente los datos aplicables al momento de ejecución. No se presupone que la consulta previa congele el precio ni que exista protección de deslizamiento no definida. | `INV-01`, `INV-02` |
| `CL-10` | Los activos de deuda y garantía o el precio utilizan decimales distintos. | La valoración aplica las escalas, unidades y redondeo definidos; no se comparan ni suman directamente cantidades de tokens diferentes. | `INV-02` |
| `CL-11` | La conversión, la valoración o un cálculo intermedio excedería el rango representable. | Se rechaza y revierte la ejecución afectada; no se acepta un umbral, deuda o cantidad de garantía truncados o desbordados. | `INV-02`, `INV-13` |
| `CL-12` | La deuda cambia por el paso del tiempo o una devolución antes de ejecutar la liquidación. | La elegibilidad y las cantidades se determinan con la deuda aplicable al momento definido, conforme a `EC-06`; no se omiten ni duplican intereses por reutilizar una consulta anterior. | `INV-01`–`INV-03` |

### Repago, Deuda y Garantía

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-13` | La operación reduce deuda mediante un repago efectivamente recibido. | La reducción atribuible al repago coincide con el importe aplicado a los componentes correspondientes, sin superar la deuda pendiente. | `INV-03`, `INV-08` |
| `CL-14` | El valor estimado de la garantía cubre la deuda, pero no se han recibido fondos de repago ni existe una baja autorizada. | No se reduce la deuda solo por la valoración. El mecanismo de recuperación o conversión debe producir y registrar los efectos aplicables. | `INV-03`, `INV-08` |
| `CL-15` | Se valora garantía en MockETH y la deuda está denominada en MockUSD. | El precio simulado no implica por sí solo una conversión ni la recepción de MockUSD. Cualquier aplicación a deuda requiere el mecanismo y la contabilización definidos. | `INV-02`–`INV-04` |
| `CL-16` | El importe efectivamente recibido es menor que el calculado o solicitado. | No se aplica a deuda más de lo efectivamente recibido. La admisibilidad de completar la ejecución con esa diferencia depende del mecanismo definido; si no se cumplen sus condiciones, se revierte. | `INV-03`, `INV-08`, `INV-13` |
| `CL-17` | El importe recibido excede la deuda elegible o el importe máximo aplicable. | No se reduce la deuda por debajo de cero. El rechazo, devolución o tratamiento del excedente debe definirse; no se genera un crédito sin respaldo y regla autorizada. | `INV-03`, `INV-08` |
| `CL-18` | La deuda tiene principal, intereses y otros componentes exigibles. | La aplicación sigue el orden que se defina y no reduce ningún componente por debajo de cero. El total de reducciones corresponde al repago aplicado y, si procede, a la baja autorizada. | `INV-03`, `INV-08` |
| `CL-19` | Se reconoce una pérdida contable, pero no existe una regla que dé de baja la deuda del prestatario. | El reconocimiento de la pérdida no cancela automáticamente la deuda. Cualquier baja debe tener una transición y una contabilización propias definidas. | `INV-03`, `INV-09`, `INV-10` |
| `CL-20` | Se da de baja una parte de la deuda conforme a una regla válida de incobrabilidad. | La reducción de deuda atribuible a la baja coincide con el importe autorizado y no se confunde con un repago recibido ni se cuenta dos veces. | `INV-03`, `INV-09`, `INV-11` |
| `CL-21` | La posición tiene garantía bloqueada y se utiliza solo una parte. | La cantidad utilizada corresponde a sus destinos efectivos o contables autorizados; el resto permanece atribuido o se libera conforme a las reglas aplicables. | `INV-04`, `INV-07`, `INV-08` |
| `CL-22` | Se intenta utilizar una cantidad superior a la garantía atribuida y disponible para la posición. | Se rechaza la ejecución; no se completan cantidades con garantías, saldos o reservas de terceros. | `INV-04`, `INV-05`, `INV-12`, `INV-13` |
| `CL-23` | La garantía registrada no está efectivamente respaldada o no corresponde a la posición. | No puede tratarse como garantía válida para esa ejecución. La comprobación debe identificar la inconsistencia aplicable; la reparación general del estado está pendiente. | `INV-01`, `INV-04`, `INV-13` |
| `CL-24` | Una unidad de garantía se reasigna contablemente y después se transfiere físicamente. | Se vinculan ambos pasos sin contar la misma unidad dos veces como garantía adicional utilizada o como dos recuperaciones independientes. | `INV-04`, `INV-11` |
| `CL-25` | Existe garantía sobrante una vez realizados los movimientos de una liquidación. | La garantía no utilizada permanece atribuida a la posición o se libera al titular según la transición definida; no se asigna arbitrariamente al ejecutor, fondo o protocolo. | `INV-07`, `INV-08` |
| `CL-26` | Se decide acreditar al saldo disponible la garantía liberada al prestatario. | La cantidad debe corresponder al titular y a la transición autorizada. Antes de implementar ese destino debe resolverse la incompatibilidad señalada con `INV-07` de `EC-01`. | `INV-07`, `INV-08` |

### Liquidación Parcial e Incentivos

Los siguientes casos sobre liquidación parcial e incentivos se aplican solo si esas funcionalidades se definen y autorizan.

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-27` | Se solicita una liquidación parcial cuando la funcionalidad no está permitida. | Se rechaza la solicitud sin efectos definitivos; una liquidación parcial no se presupone disponible en el MVP. | `INV-05`, `INV-13` |
| `CL-28` | El repago de una ejecución parcial coincide con su límite o queda una unidad por debajo. | La admisibilidad exacta y el redondeo dependen de la regla definida. Si se completa, no se supera el límite aplicable ni la deuda pendiente. | `INV-05` |
| `CL-29` | El repago de una ejecución parcial supera el límite o, sumado a una baja en la misma ejecución, supera la deuda pendiente. | La ejecución no puede aplicar el exceso. Debe definirse si existen límites adicionales para la baja y si se rechaza o ajusta la solicitud; si falla, no quedan efectos parciales definitivos. | `INV-03`, `INV-05`, `INV-13` |
| `CL-30` | La garantía utilizada en una ejecución parcial coincide con su límite o con la disponible. | Se aplica la regla definida, incluida su comparación de igualdad. No se utiliza una cantidad superior al límite ni a la garantía atribuida disponible. | `INV-04`, `INV-05`, `INV-07` |
| `CL-31` | Una ejecución parcial deja deuda y garantía en la posición. | Ambas quedan registradas por sus cantidades reales. No se presume que la deuda residual sea incobrable ni que la posición haya quedado regularizada. | `INV-08`, `INV-09` |
| `CL-32` | Una segunda liquidación parcial se solicita tras una primera ejecución completada. | Se vuelve a evaluar la elegibilidad y los límites con el estado y precio aplicables. No se reutilizan la deuda ya aplicada ni la garantía ya utilizada. | `INV-01`, `INV-05`, `INV-11` |
| `CL-33` | Se permiten liquidaciones parciales y una ejecución individual falla tras movimientos provisionales. | La ejecución fallida se revierte completamente. Una liquidación parcial permitida no autoriza conservar efectos parciales de una ejecución fallida. | `INV-05`, `INV-13` |
| `CL-34` | No se ha definido incentivo, o el incentivo permitido es cero. | No se registra ni paga un incentivo positivo. Los demás movimientos siguen sus propias reglas. | `INV-06` |
| `CL-35` | El incentivo calculado coincide con el límite definido o es una unidad inferior. | Se aplican la comparación, tasa y redondeo configurados. Si se paga, el importe no supera el máximo aplicable y se identifica su fuente. | `INV-06` |
| `CL-36` | El incentivo calculado o solicitado supera el máximo permitido. | No puede pagarse por encima del máximo. El rechazo o ajuste debe seguir la regla definida; un intento fallido se revierte. | `INV-06`, `INV-13` |
| `CL-37` | El incentivo se paga con parte de la garantía, si esa fuente se autoriza. | La garantía del incentivo se incluye una sola vez entre los destinos de la garantía utilizada y no se trata automáticamente como ingreso del protocolo. | `INV-04`, `INV-06`, `INV-11` |
| `CL-38` | Se calcula una recompensa, pero falla su pago o asignación requerida. | Si el pago o asignación es necesario para esa ejecución, se revierte la liquidación completa; un cálculo provisional no se registra como recompensa cobrada. | `INV-06`, `INV-13` |

### Deuda Incobrable y Pérdidas

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-39` | Tras una liquidación queda deuda residual, pero no se han cumplido los criterios de incobrabilidad. | La deuda no se declara automáticamente incobrable ni se cancela por el mero hecho de quedar pendiente. | `INV-03`, `INV-09` |
| `CL-40` | Existe deuda real pendiente que cumple los criterios de incobrabilidad definidos. | Puede reconocerse conforme al procedimiento autorizado, sin superar el importe elegible y distinguiendo el reconocimiento de una eventual baja de deuda. | `INV-09`, `INV-10` |
| `CL-41` | Se intenta declarar incobrable deuda inexistente, ya pagada o ya reconocida para el mismo efecto. | No se reconoce nuevamente ese importe ni se reduce otra vez el patrimonio por el mismo efecto. | `INV-09`–`INV-11` |
| `CL-42` | El importe propuesto como incobrable supera la deuda elegible en una unidad o más. | No puede reconocerse por encima de esa deuda. El tratamiento del intento debe respetar el procedimiento definido; si falla, no deja reconocimiento parcial definitivo. | `INV-09`, `INV-13` |
| `CL-43` | La garantía recuperada cubre solo una parte de la deuda. | Solo los importes efectivamente aplicados reducen la deuda por repago. La posible deuda residual y su eventual incobrabilidad se tratan según las reglas que se definan. | `INV-03`, `INV-09` |
| `CL-44` | Se han contabilizado recuperaciones o pérdidas antes del reconocimiento definitivo. | La pérdida neta adicional del fondo considera esos efectos sin duplicarlos. No se presume que toda la deuda nominal residual sea pérdida adicional. | `INV-10`, `INV-11` |
| `CL-45` | Se reconoce una pérdida neta positiva atribuible al fondo. | El patrimonio neto disminuye por el efecto adicional reconocido. La pérdida no altera por sí sola el número de participaciones de los proveedores. | `INV-10` |
| `CL-46` | La pérdida neta atribuible al fondo es cero. | Ese reconocimiento no reduce el patrimonio por ese concepto. Los demás movimientos de la operación se contabilizan por separado. | `INV-10`, `INV-11` |
| `CL-47` | La pérdida reconocida reduce el patrimonio del fondo a cero o lo excede. | La representación, las obligaciones y el tratamiento del patrimonio insuficiente están pendientes. No se presupone un rescate, una absorción por usuarios ajenos ni una recuperación automática. | `INV-10` |
| `CL-48` | Se recuperan fondos después de reconocer una pérdida. | Se aplica la regla de recuperación posterior que se defina, vinculándola al reconocimiento previo y evitando contar el mismo efecto dos veces. No se presupone cómo se distribuye esa recuperación. | `INV-10`, `INV-11` |
| `CL-49` | La liquidación origina una pérdida para el fondo y afecta al valor de sus participaciones. | El efecto patrimonial se comunica o registra conforme a `EC-04`; no se modifica por esa pérdida el número individual de participaciones. La valoración y el redondeo siguen las reglas del fondo. | `INV-10`, `INV-12` |

### Trazabilidad, Aislamiento y Atomicidad

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-50` | Se intenta aplicar dos veces a deuda el mismo repago o recuperación. | El mismo importe no produce dos reducciones de deuda. El mecanismo de identificación y trazabilidad debe definirse. | `INV-03`, `INV-11` |
| `CL-51` | Un mismo movimiento tiene registros de recepción y de reducción de deuda. | Se permiten como efectos contables relacionados y distintos, siempre que cada importe se aplique una sola vez a cada efecto y los registros coincidan. | `INV-03`, `INV-11` |
| `CL-52` | Se intenta utilizar o liberar dos veces la misma unidad de garantía. | La unidad no puede atribuirse simultáneamente a categorías o destinos incompatibles; la ejecución que no pueda cumplir esa condición no se completa. | `INV-04`, `INV-07`, `INV-11` |
| `CL-53` | Se liquida una posición mientras otra cuenta mantiene deuda y garantía. | La deuda y la garantía de la otra posición no cambian por esa liquidación; los efectos legítimos sobre el patrimonio compartido del fondo se contabilizan por separado. | `INV-10`, `INV-12` |
| `CL-54` | Falla una validación antes de mover garantía o aplicar deuda. | No quedan movimientos, reducciones, incentivos, ingresos, pérdidas ni registros definitivos atribuibles al intento. | `INV-13` |
| `CL-55` | Falla el mecanismo de recuperación después de mover o reasignar provisionalmente garantía. | Se revierte la ejecución completa, incluida la garantía provisional y cualquier aplicación de deuda o incentivo del intento. | `INV-03`, `INV-04`, `INV-13` |
| `CL-56` | Falla una actualización después de aplicar provisionalmente el repago a deuda. | Se revierten todos los efectos del intento, incluidos repago, deuda, garantía y demás partidas provisionales. | `INV-03`, `INV-08`, `INV-13` |
| `CL-57` | Falla un registro o actualización después de reconocer provisionalmente una pérdida o incentivo. | Se revierte la ejecución afectada sin dejar pérdida, incentivo ni movimientos parciales definitivos. Una transición separada, si se permite, debe tener sus propios estados y atomicidad definidos. | `INV-10`, `INV-13` |
| `CL-58` | Una llamada anidada o repetida intenta liquidar dos veces la misma posición usando los mismos fondos o garantía. | Cada ejecución completada debe volver a comprobar estado, elegibilidad y cantidades disponibles; no se aplican dos veces los mismos recursos. Si no puede garantizarse, se revierte el intento afectado. | `INV-01`, `INV-04`, `INV-11`, `INV-13` |
| `CL-59` | Una devolución de `EC-06` y una liquidación intentan afectar la misma deuda o garantía. | Su orden y estados compatibles deben definirse. Ninguna transición puede usar dos veces la misma deuda, fondos o garantía; cada ejecución fallida revierte sus efectos. | `INV-03`, `INV-07`, `INV-11`, `INV-13` |
| `CL-60` | Una secuencia combina cambios de precio, liquidaciones, recuperaciones, reconocimientos de pérdida e intentos fallidos. | Tras cada transición se comprueban las propiedades aplicables; cada intento fallido conserva el estado inmediatamente anterior sin borrar el interés correspondiente al tiempo transcurrido ni los efectos previos válidos. | `INV-01`–`INV-13` |

### Criterio de Cobertura

Aplicar los casos pertinentes a los estados de préstamo, activos, precios, umbrales y mecanismos que se definan; con una y varias posiciones; y con garantías, deuda, recuperaciones y patrimonio en sus límites representables. Comparar la deuda al mismo instante antes y después de cada ejecución, y comprobar por separado el interés del tiempo transcurrido. Las interacciones con `EC-04`, `EC-05`, `EC-06` y `EC-08` se consideran aquí solo en cuanto afecten a `EC-07`.

Esta matriz identifica clases de límites y fallos para `EC-07`; no demuestra que se hayan enumerado todas las secuencias posibles ni sustituye las pruebas o una verificación formal. Los resultados dependientes de reglas pendientes deben concretarse antes de convertirlos en pruebas ejecutables.
