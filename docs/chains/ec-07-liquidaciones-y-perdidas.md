# `EC-07` Liquidaciones y Pérdidas

La cadena económica `EC-07` gestiona la liquidación de posiciones que incumplen el umbral de garantía y el reconocimiento de las pérdidas que correspondan al fondo de liquidez de Veyra.

## Objetivo

EC-07 cierra una posición que ha superado el umbral, cobra MockUSD al liquidador, distribuye el MockETH bloqueado y reconoce la pérdida del fondo cuando la recuperación resulta insuficiente.

El precio simulado se comprueba al ejecutar. El fondo soporta la deuda incobrable y sus proveedores conservan su número de participaciones.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen los siguientes actores:

- El **prestatario** es titular del préstamo y de la garantía asociada a la posición que se evalúa.
- El **liquidador** es cualquier cuenta distinta del prestatario que disponga del MockUSD necesario y actúe con fondos propios.
- El **contrato de préstamos de Veyra** mantiene la información del préstamo, su deuda y garantía, y coordina los cambios de estado que correspondan a la liquidación.
- El **fondo EC-04** recibe todo el repago y soporta la baja del crédito incobrable.
- La cadena de **préstamos y garantías `EC-05`** mantiene las condiciones de apertura y la información de la garantía asociada al préstamo.
- **EC-06** determina principal e interés exigible al tiempo del bloque, con la tasa fijada al abrir.
- **EC-08** queda fuera de la distribución. La liquidación carece de comisión de tesorería.
- El **administrador** configura los parámetros autorizados del mercado y los precios simulados del entorno local. Esta función no le concede permiso para apropiarse arbitrariamente de fondos o garantías ni para declarar pérdidas fuera de las reglas del protocolo.

## Variables y Estado Contable

Para evaluar la posición se necesitan la deuda entera actualizada D en unidades mínimas de MockUSD, la garantía bloqueada C en unidades mínimas de MockETH y el precio p en unidades mínimas de MockUSD por MockETH entero.

Se utilizan las direcciones, escalas y reglas de vigencia del precio de EC-05. El resultado se calcula al tiempo de ejecución.

La garantía bloqueada, los saldos disponibles de los usuarios, el patrimonio del fondo y los ingresos del protocolo son partidas diferenciadas. Una liquidación solo puede afectar la garantía y la deuda de la posición autorizada y las demás partidas que correspondan a esa operación.

**Reglas contables:** El valor estimado de una garantía y los fondos efectivamente recuperados son magnitudes distintas. Un precio simulado permite valorar la posición, pero no acredita por sí solo que se hayan recibido o convertido activos para pagar la deuda.

Cada liquidación completada debe registrar la deuda considerada, la garantía utilizada o liberada y los importes efectivamente recibidos y aplicados, así como cualquier comisión, incentivo o pérdida reconocida que corresponda según las reglas definidas. Los importes de activos diferentes no se suman sin una conversión establecida.

La deuda incobrable es D menos el repago efectivo cuando se ha adjudicado toda la garantía en un cierre válido. Se da de baja una sola vez en esa misma ejecución.

## Flujo Económico

### Evaluación de la Posición

Veyra identifica el préstamo y su estado, determina los componentes de deuda que correspondan y valora la garantía con el precio y los parámetros aplicables. Con esos datos comprueba si la posición cumple la condición de liquidación definida para el mercado.

La posición activa es liquidable exactamente cuando `D × 10¹⁸ × 10 000 > C × p × 7 500`. La igualdad sigue siendo solvente a estos efectos. Se comparan productos sin truncar ratios.

### Ejecución de la Liquidación

El liquidador solicita el cierre total. Se comprueban de nuevo la elegibilidad y su disponible de MockUSD. Sea `ceil` la división entera redondeada hacia arriba.

La cantidad entera necesaria para comprar toda la garantía con prima del 5 % es `Q = ceil(C × p / 1 050 000 000 000 000 000)`. El denominador incorpora la escala de MockETH y la prima. El repago es `R = min(D, Q)`. Se mueve exactamente R del disponible del liquidador a la caja del fondo. Con C y p positivos, Q es al menos una unidad mínima.

El abono de MockETH al liquidador es `G = min(C, ceil(R × 1 050 000 000 000 000 000 / p))`. Las divisiones conservan toda la precisión hasta aplicar el redondeo indicado. Si R alcanza Q, se adjudica toda C. El prestatario recupera C − G en su disponible.

El repago cubre primero el interés entero y después principal. La prima ya está incluida en G. La custodia ERC-20 de ambos tokens permanece constante.

### Garantía y Deuda Restantes

Una ejecución correcta termina con deuda y bloqueo cero para esa posición. Se registran por separado repago, baja, garantía adjudicada y garantía devuelta.

Si R es inferior a D, se ha agotado toda la garantía. Los componentes impagados se dan de baja y su suma D − R reduce el patrimonio. En ambos tipos de cierre se descarta el resto fraccionario de EC-06, que nunca formó parte de D ni del patrimonio entero.

El disponible total de MockETH aumenta por C. Los abonos a liquidador y prestatario suman exactamente el bloqueo que desaparece.

### Reconocimiento de Pérdidas

Valorar el patrimonio al mismo instante antes y después de la operación, con el interés entero ya devengado. Se sustituye el crédito D por caja R. La pérdida es D − R.

El cierre es definitivo. La v0.1.0 excluye la reapertura de la deuda y las recuperaciones posteriores del préstamo cerrado.

## Validaciones y Restricciones

### Validaciones de Elegibilidad

- El préstamo debe estar identificado y encontrarse en un estado que permita evaluar y, en su caso, ejecutar una liquidación.
- El liquidador debe ser distinto del prestatario y disponer al menos de R en MockUSD.
- La deuda considerada debe actualizarse o determinarse conforme a las reglas de `EC-06` para el momento aplicable. No se debe omitir ni contar dos veces el interés correspondiente.
- La garantía utilizada en la comprobación debe corresponder a la posición y estar efectivamente atribuida y bloqueada conforme a `EC-05`.
- El precio debe ser positivo, publicado a más tardar en este bloque y con una antigüedad de hasta 3 600 segundos.
- Se exige superar estrictamente el 75 % al ejecutar.

### Validaciones de Ejecución y Contabilidad

- La única garantía repartida es C. El único saldo utilizado para el repago es el del liquidador.
- La suma de repago y baja debe ser exactamente D. La baja solo procede tras adjudicar toda C y cobrar R.
- La valoración de la garantía y las recuperaciones efectivas deben distinguirse. Cualquier conversión entre activos requiere un mecanismo y una regla de contabilización definidos.
- Las dos cuentas reciben en total C y la caja recibe R. La tesorería no participa.
- Los cálculos, las conversiones y los estados resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si falla una validación, un movimiento necesario o una actualización contable, la ejecución afectada debe revertirse por completo, sin transferencias, reducciones de deuda, cambios de garantía, ingresos o pérdidas definitivos parciales de ese intento. La posibilidad de una liquidación parcial se refiere a su alcance permitido, no a conservar efectos de una ejecución fallida.

### Validaciones de Pérdidas y Estado

- La incobrabilidad exige garantía agotada y diferencia positiva D − R en un cierre válido.
- Las recuperaciones, pérdidas e importes reconocidos previamente deben tenerse en cuenta una sola vez al determinar el efecto neto sobre el patrimonio del fondo.
- El cierre confirmado elimina el préstamo del conjunto activo. Una segunda operación sobre ese ID debe encontrar el estado cerrado, incluso si el titular ya abrió otro.
- Una pérdida atribuible al fondo no puede cargarse arbitrariamente a saldos disponibles, garantías de terceros ni ingresos del protocolo; su efecto sobre patrimonio y participaciones se coordina con `EC-04`.

### Restricciones del MVP

El mercado usa liquidaciones totales en una transacción. Se rechaza solicitar un importe parcial o aplicar una pérdida discrecional. Cada cierre identifica el préstamo y la transacción, y registra el precio, el repago, su imputación, la garantía distribuida y la baja.

## Invariantes y Propiedades

Las propiedades se aplican al cierre total de la posición. INV-05 conserva la referencia a una posible extensión de liquidaciones parciales.

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

La posición ha de estar activa, el precio vigente y el umbral estrictamente superado. La capacidad de pago del liquidador se verifica por separado.

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
- $\operatorname{evaluar}$: comparación estricta por productos entre deuda y el 75 % del valor de la garantía.

La comparación se hace mediante productos exactos en las escalas del mercado. Con precio inválido o en igualdad con el umbral la liquidación se rechaza.

### Invariante `INV-03` - Conservación de Deuda Liquidada

En `EC-07`, una reducción de la deuda durante una liquidación debe corresponder a importes efectivamente aplicados a su pago o a deuda dada de baja conforme a una regla válida de reconocimiento de incobrabilidad. Una valoración estimada de garantía no constituye por sí sola un repago efectivo.

Para cada cierre, la reducción de deuda es el repago más la baja por incobrabilidad en esa misma transacción. El saldo exigible posterior es cero.

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

En el cierre se registra por separado la disminución por repago R y la disminución por baja D − R. Ambas forman una única transición atómica.

### Invariante `INV-04` - Conservación de Garantías

En `EC-07`, la garantía retirada de la posición durante una liquidación debe corresponder a cantidades efectivamente transferidas o reasignadas a destinos contables autorizados. La garantía valorada no debe contarse como garantía movida si no lo ha sido.

El término «utilizada» designa exclusivamente la garantía adjudicada al liquidador, incluida su prima. El resto del bloqueo se libera al prestatario según INV-07.

```math
\begin{aligned}
G_{\mathrm{utilizada}}(l) &= G(l) = \Delta B_{\mathrm{disponible}}(e_l,\mathrm{MockETH},l),\\
G_{\mathrm{liberada}}(l) &= C(l)-G(l) = \Delta B_{\mathrm{disponible}}(u_l,\mathrm{MockETH},l).
\end{aligned}
```

**Leyenda:**

- $L$: conjunto de ejecuciones de liquidación completadas correctamente.
- $C(l)$ y $G(l)$: bloqueo inicial y adjudicación entera calculada para el cierre.
- $e_l$ y $u_l$: liquidador y prestatario, que son cuentas distintas.
- $\Delta B_{\mathrm{disponible}}$: variación del saldo individual causada por el cierre.

La suma de los dos abonos debe igualar la reducción de garantía bloqueada. El incentivo ya forma parte de G.

### Invariante `INV-05` - Límites de Liquidación Parcial

La v0.1.0 excluye los cierres parciales. La siguiente propiedad conserva la especificación para una ampliación que los admita.

Para cada ejecución parcial completada, el repago y la garantía utilizada no superan sus límites ni las cantidades disponibles inmediatamente antes de la operación. Además, la reducción total de deuda por repago y baja no supera la deuda anterior.

```math
\forall l\in L_{\text{parcial}}:\quad
A_{\text{repago}}(l)\leq\min(D_{\text{antes}}(l),M_D(l)),\quad
G_{\text{utilizada}}(l)\leq\min(G_{\text{antes}}(l),M_G(l)),\quad
A_{\text{repago}}(l)+A_{\text{baja}}(l)\leq D_{\text{antes}}(l)
```

**Leyenda:**

- $L_{\text{parcial}}$: conjunto vacío en v0.1.0.
- $A_{\text{repago}}(l)$: importe efectivamente aplicado al pago de deuda en la ejecución.
- $A_{\text{baja}}(l)$: importe de la baja registrada en una ejecución.
- $D_{\text{antes}}(l)$: deuda de la posición antes de la ejecución, actualizada al momento aplicable.
- $G_{\text{utilizada}}(l)$ y $G_{\text{antes}}(l)$: garantía utilizada y garantía atribuida disponible antes de la ejecución.
- $M_D(l)$ y $M_G(l)$: límites de una eventual liquidación parcial, fuera del MVP.

La interfaz de v0.1.0 solo acepta el cierre total. Por tanto, el conjunto de liquidaciones parciales completadas es vacío.

### Invariante `INV-06` - Integridad del Incentivo de Liquidación

El incentivo procede de la propia garantía y está incluido en la adjudicación calculada al liquidador.

La prima máxima se incluye en G mediante el factor 10 500 / 10 000 y el límite C.

```math
\forall l\in L:\quad
A_{\mathrm{incentivo}}(l)
= G(l)-\min\!\left(G(l),\left\lceil \frac{R(l)\,10^{18}}{p(l)}\right\rceil\right)
```

**Leyenda:**

- $L$: conjunto de ejecuciones de liquidación completadas correctamente.
- $A_{\text{incentivo}}(l)$: incentivo efectivamente pagado o asignado al ejecutor conforme al mecanismo definido.
- $R(l)$, $p(l)$ y $G(l)$: repago de MockUSD, precio vigente y MockETH adjudicado, respectivamente, en sus escalas de mercado.

La parte restante de G corresponde al intercambio por el repago. El total acreditado al liquidador sigue siendo G aunque se registre la prima como dato del evento.

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
- $G_{\text{utilizada}}(l)$: abono G al liquidador, incluida la prima.
- $G_{\text{liberada}}(l)$: garantía que deja de estar comprometida para esa posición y se libera o reasigna válidamente al titular en esa ejecución.
- $G_{\text{restante}}(l)$: cero después del cierre total.

La adjudicación G y la liberación C − G se ejecutan al cerrar. La garantía bloqueada posterior es cero.

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

La garantía se reparte en el cierre. El mercado excluye aportaciones adicionales a un préstamo activo.

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
- $\operatorname{criterios}(b)$: se cobró R, se agotó C y queda deuda positiva por dar de baja en ese cierre.

El cierre agota garantía o paga toda la deuda. Solo en el primer caso puede quedar pérdida positiva. El crédito que se da de baja deja de ser exigible.

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
- $P_{\text{netaFondo}}(b)$: diferencia D − R dada de baja en ese cierre.

El número de participaciones se conserva. Si se pierde todo el patrimonio se aplican las reglas del fondo con H cero de EC-04.

### Invariante `INV-11` - Prevención de Doble Contabilización

En `EC-07`, un mismo importe de deuda, garantía, recuperación o pérdida no puede aplicarse o reconocerse más de una vez para producir el mismo efecto contable. Un mismo evento puede tener registros relacionados en distintas partidas cuando describen efectos diferentes.

Para cada unidad contable identificada y cada tipo de efecto, el número de aplicaciones definitivas de esa misma unidad para ese efecto no puede superar uno.

```math
\forall x\in X,\quad \forall e\in E:\quad
N_{\text{aplicaciones}}(x,e)\leq1
```

**Leyenda:**

- $X$: importes identificables por préstamo, transacción y registro de cierre.
- $E$: tipos de efecto contable, como aplicación a deuda, asignación de garantía o reconocimiento de pérdida.
- $N_{\text{aplicaciones}}(x,e)$: número de aplicaciones definitivas de la unidad $x$ al mismo efecto $e$.

El identificador del préstamo y su cierre permiten verificar que solo se aplique una vez cada recuperación o baja.

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

La ejecución del cierre es atómica. Los intentos fallidos conservan el último estado confirmado.

## Casos Límite y Escenarios de Fallo

Los siguientes casos sirven de referencia para futuras pruebas de `EC-07`. Las referencias `INV-01` a `INV-13` corresponden a esta cadena. En cada ejecución fallida se revierten sus efectos, incluidos movimientos de garantía, reducciones de deuda, incentivos, ingresos, pérdidas y registros definitivos.

La deuda y el repago se expresan en unidades de MockUSD, y la adjudicación y liberación en unidades de MockETH.

### Elegibilidad, Precio y Umbral

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Se intenta liquidar una posición que no cumple la condición de liquidación. | Se rechaza la ejecución sin movimientos de garantía, reducción de deuda ni otros efectos definitivos. | `INV-01`, `INV-13` |
| `CL-02` | Una posición incumple el umbral conforme a datos válidos y su estado permite liquidarla. | Puede ejecutarse si el solicitante está autorizado y se cumplen todas las demás condiciones; la elegibilidad por sí sola no acredita fondos recuperados. | `INV-01`, `INV-02` |
| `CL-03` | La posición está exactamente en el umbral configurado. | En la igualdad se rechaza la liquidación. | `INV-01`, `INV-02` |
| `CL-04` | La posición queda una unidad de la representación aplicable a cada lado del umbral. | Se evalúa cada lado con las unidades, precisión y redondeo definidos. La comparación y el tratamiento de la igualdad deben ser coherentes. | `INV-01`, `INV-02` |
| `CL-05` | El préstamo no existe, está cerrado o se encuentra en un estado que no permite liquidación. | Solo un préstamo activo admite liquidación. Un cierre previo impide repetirla. | `INV-01`, `INV-13` |
| `CL-06` | El propio prestatario intenta ejecutar su liquidación. | Se rechaza. La devolución ordinaria permanece disponible mientras el préstamo siga activo. | Validaciones, `INV-01`, `INV-13` |
| `CL-07` | Falta el precio, no está configurado o no cumple las condiciones de validez definidas. | Se rechaza la liquidación que dependa de él; no se utiliza un precio inventado ni una valoración inválida. | `INV-01`, `INV-02`, `INV-13` |
| `CL-08` | El precio o el valor calculado de la garantía es cero. | Un precio cero invalida la operación. Con p y C positivos se usan productos exactos, incluso si una valoración truncada parecería cero. | `INV-01`, `INV-02`, `INV-13` |
| `CL-09` | El precio cambia entre una consulta y la ejecución. | Se recalculan elegibilidad, R y G con la publicación vigente al ejecutar. | `INV-01`, `INV-02` |
| `CL-10` | Los activos de deuda y garantía o el precio utilizan decimales distintos. | La valoración aplica las escalas, unidades y redondeo definidos; no se comparan ni suman directamente cantidades de tokens diferentes. | `INV-02` |
| `CL-11` | Los productos de valoración o adjudicación requieren más de 256 bits. | Se usan la comparación, el redondeo y los límites exactos de R y G. Si un saldo final queda fuera de rango, revierte todo el cierre. | `INV-02`, `INV-13` |
| `CL-12` | La deuda cambia por el paso del tiempo o una devolución antes de ejecutar la liquidación. | La elegibilidad y las cantidades se determinan con la deuda aplicable al momento definido, conforme a `EC-06`; no se omiten ni duplican intereses por reutilizar una consulta anterior. | `INV-01`–`INV-03` |

### Repago, Deuda y Garantía

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-13` | La operación reduce deuda mediante un repago efectivamente recibido. | La reducción atribuible al repago coincide con el importe aplicado a los componentes correspondientes, sin superar la deuda pendiente. | `INV-03`, `INV-08` |
| `CL-14` | El valor estimado de la garantía cubre la deuda, pero no se han recibido fondos de repago ni existe una baja autorizada. | No se reduce la deuda solo por la valoración. El mecanismo de recuperación o conversión debe producir y registrar los efectos aplicables. | `INV-03`, `INV-08` |
| `CL-15` | Se valora garantía en MockETH y la deuda está denominada en MockUSD. | El precio simulado no implica por sí solo una conversión ni la recepción de MockUSD. Cualquier aplicación a deuda requiere el mecanismo y la contabilización definidos. | `INV-02`–`INV-04` |
| `CL-16` | El importe efectivamente recibido es menor que el calculado o solicitado. | Si el disponible del liquidador o el importe efectivamente cobrado no cubren R por completo, revierte toda la operación. | `INV-03`, `INV-08`, `INV-13` |
| `CL-17` | El importe recibido excede la deuda elegible o el importe máximo aplicable. | El cierre calcula R internamente y solo puede debitar esa cantidad, nunca más que D. | `INV-03`, `INV-08` |
| `CL-18` | La deuda contiene principal e interés entero pendiente. | R se imputa primero al interés y el resto al principal. Se dan de baja los componentes que queden al agotarse la garantía. | `INV-03`, `INV-08` |
| `CL-19` | Se intenta reconocer una pérdida fuera del cierre con garantía agotada. | Se rechaza el reconocimiento aislado. La baja y la pérdida nacen del mismo cierre confirmado. | `INV-03`, `INV-09`, `INV-10` |
| `CL-20` | Se da de baja una parte de la deuda conforme a una regla válida de incobrabilidad. | La reducción de deuda atribuible a la baja coincide con el importe autorizado y no se confunde con un repago recibido ni se cuenta dos veces. | `INV-03`, `INV-09`, `INV-11` |
| `CL-21` | Basta con adjudicar solo parte de la garantía al liquidador. | El liquidador recibe G, el prestatario recupera C − G y la posición queda cerrada con bloqueo cero. | `INV-04`, `INV-07`, `INV-08` |
| `CL-22` | Se intenta utilizar una cantidad superior a la garantía atribuida y disponible para la posición. | Se rechaza la ejecución; no se completan cantidades con garantías, saldos o reservas de terceros. | `INV-04`, `INV-05`, `INV-12`, `INV-13` |
| `CL-23` | La garantía registrada no está efectivamente respaldada o no corresponde a la posición. | Detectar la falta de respaldo. Una ejecución no puede adjudicar garantía ficticia ni ajena. | `INV-01`, `INV-04`, `INV-13` |
| `CL-24` | Una unidad de garantía se reasigna contablemente y después se transfiere físicamente. | Se vinculan ambos pasos sin contar la misma unidad dos veces como garantía adicional utilizada o como dos recuperaciones independientes. | `INV-04`, `INV-11` |
| `CL-25` | Existe garantía sobrante una vez realizados los movimientos de una liquidación. | El sobrante C − G se acredita al prestatario en MockETH al cerrar. | `INV-07`, `INV-08` |
| `CL-26` | Se acredita al prestatario la garantía sobrante. | Aumenta su disponible de MockETH por C − G con contrapartida en el bloqueo de la posición. | `INV-07`, `INV-08` |

### Liquidación Parcial e Incentivos

CL-27 a CL-33 delimitan la funcionalidad excluida de liquidación parcial. Los casos de incentivo se evalúan con la adjudicación de garantía del cierre total.

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-27` | Se solicita una liquidación parcial cuando la funcionalidad no está permitida. | Se rechaza toda solicitud parcial sin cobrar ni mover garantía. | `INV-05`, `INV-13` |
| `CL-28` | El repago de una ejecución parcial coincide con su límite o queda una unidad por debajo. | El mercado excluye el cierre parcial incluso si el repago propuesto coincide con un límite. | `INV-05` |
| `CL-29` | El repago de una ejecución parcial supera el límite o, sumado a una baja en la misma ejecución, supera la deuda pendiente. | Se rechaza la solicitud parcial. En el cierre admitido, R más la baja deben igualar D. | `INV-03`, `INV-05`, `INV-13` |
| `CL-30` | La garantía utilizada en una ejecución parcial coincide con su límite o con la disponible. | Se rechaza como operación parcial. El cierre total calcula G automáticamente. | `INV-04`, `INV-05`, `INV-07` |
| `CL-31` | Una ejecución parcial deja deuda y garantía en la posición. | Ese resultado no es un estado final admisible. La liquidación debe cerrar la posición o revertir. | `INV-08`, `INV-09` |
| `CL-32` | Una segunda liquidación parcial se solicita tras una primera ejecución completada. | Una primera liquidación parcial no puede confirmarse. Un préstamo ya cerrado tampoco puede liquidarse de nuevo. | `INV-01`, `INV-05`, `INV-11` |
| `CL-33` | Se permiten liquidaciones parciales y una ejecución individual falla tras movimientos provisionales. | La ejecución parcial está excluida. Ante cualquier fallo en el cierre completo deben revertirse todos los movimientos. | `INV-05`, `INV-13` |
| `CL-34` | Se agota la garantía y el redondeo deja una prima efectiva cero. | Se contabiliza únicamente G y se comprueba la fórmula entera. No se paga una recompensa adicional. | `INV-06` |
| `CL-35` | El cálculo de la prima redondea en torno a una unidad mínima. | La parte atribuida al incentivo debe coincidir exactamente con INV-06 y estar incluida en el abono G. | `INV-06` |
| `CL-36` | El incentivo calculado o solicitado supera el máximo permitido. | Se rechaza cualquier adjudicación que exceda G. La prima está incluida en el cálculo y limitada por C. | `INV-06`, `INV-13` |
| `CL-37` | El incentivo se paga con parte de la garantía. | La garantía del incentivo se incluye una sola vez entre los destinos de la garantía utilizada y no se trata automáticamente como ingreso del protocolo. | `INV-04`, `INV-06`, `INV-11` |
| `CL-38` | Se calcula una recompensa, pero falla su pago o asignación requerida. | Si el pago o asignación es necesario para esa ejecución, se revierte la liquidación completa; un cálculo provisional no se registra como recompensa cobrada. | `INV-06`, `INV-13` |

### Deuda Incobrable y Pérdidas

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-39` | Se intenta cerrar con deuda impagada y garantía todavía utilizable. | El estado final es inválido. Se revierte la liquidación. | `INV-03`, `INV-09` |
| `CL-40` | Existe deuda real pendiente que cumple los criterios de incobrabilidad definidos. | Se da de baja la parte impagada D − R y se reconoce esa misma pérdida en la transacción de cierre. | `INV-09`, `INV-10` |
| `CL-41` | Se intenta declarar incobrable deuda inexistente, ya pagada o ya reconocida para el mismo efecto. | No se reconoce nuevamente ese importe ni se reduce otra vez el patrimonio por el mismo efecto. | `INV-09`–`INV-11` |
| `CL-42` | El importe propuesto como incobrable supera la deuda elegible en una unidad o más. | Se rechaza cualquier baja superior a D − R. La pérdida y la baja deben coincidir con la diferencia íntegra. | `INV-09`, `INV-13` |
| `CL-43` | La garantía recuperada cubre solo una parte de la deuda. | El repago R consume el disponible propio del ejecutor. Agotada la garantía, D − R se da de baja y reduce el patrimonio. | `INV-03`, `INV-09` |
| `CL-44` | Se intenta reconocer por segunda vez una recuperación o pérdida de una posición cerrada. | La operación se rechaza. No hay un segundo ajuste patrimonial. | `INV-10`, `INV-11` |
| `CL-45` | Se reconoce una pérdida neta positiva atribuible al fondo. | El patrimonio neto disminuye por el efecto adicional reconocido. La pérdida no altera por sí sola el número de participaciones de los proveedores. | `INV-10` |
| `CL-46` | La pérdida neta atribuible al fondo es cero. | Ese reconocimiento no reduce el patrimonio por ese concepto. Los demás movimientos de la operación se contabilizan por separado. | `INV-10`, `INV-11` |
| `CL-47` | La pérdida reconocida reduce el patrimonio del fondo a cero o lo excede. | Con pérdida igual a H, el patrimonio y el valor de las participaciones quedan en cero. Una baja superior a H es inconsistente con una deuda reconocida dentro de H. | `INV-10` |
| `CL-48` | Se envían fondos tras el cierre de una posición liquidada. | Una transferencia directa es un excedente sin atribuir. No restablece la deuda ni revierte la pérdida del cierre. | `INV-10`, `INV-11` |
| `CL-49` | La liquidación origina una pérdida para el fondo y afecta al valor de sus participaciones. | El efecto patrimonial se comunica o registra conforme a `EC-04`; no se modifica por esa pérdida el número individual de participaciones. La valoración y el redondeo siguen las reglas del fondo. | `INV-10`, `INV-12` |

### Trazabilidad, Aislamiento y Atomicidad

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-50` | Se intenta aplicar dos veces a deuda el mismo repago o recuperación. | La posición ya cerrada y su identificador impiden volver a aplicar el mismo repago o pérdida. | `INV-03`, `INV-11` |
| `CL-51` | Un mismo movimiento tiene registros de recepción y de reducción de deuda. | Se permiten como efectos contables relacionados y distintos, siempre que cada importe se aplique una sola vez a cada efecto y los registros coincidan. | `INV-03`, `INV-11` |
| `CL-52` | Se intenta utilizar o liberar dos veces la misma unidad de garantía. | La unidad no puede atribuirse simultáneamente a categorías o destinos incompatibles; la ejecución que no pueda cumplir esa condición no se completa. | `INV-04`, `INV-07`, `INV-11` |
| `CL-53` | Se liquida una posición mientras otra cuenta mantiene deuda y garantía. | La deuda y la garantía de la otra posición no cambian por esa liquidación; los efectos legítimos sobre el patrimonio compartido del fondo se contabilizan por separado. | `INV-10`, `INV-12` |
| `CL-54` | Falla una validación antes de mover garantía o aplicar deuda. | No quedan movimientos, reducciones, incentivos, ingresos, pérdidas ni registros definitivos atribuibles al intento. | `INV-13` |
| `CL-55` | Falla el mecanismo de recuperación después de mover o reasignar provisionalmente garantía. | Se revierte la ejecución completa, incluida la garantía provisional y cualquier aplicación de deuda o incentivo del intento. | `INV-03`, `INV-04`, `INV-13` |
| `CL-56` | Falla una actualización después de aplicar provisionalmente el repago a deuda. | Se revierten todos los efectos del intento, incluidos repago, deuda, garantía y demás partidas provisionales. | `INV-03`, `INV-08`, `INV-13` |
| `CL-57` | Falla un registro o actualización después de reconocer provisionalmente una pérdida o incentivo. | Se revierte el cierre completo, incluidas la adjudicación y la baja provisionales. | `INV-10`, `INV-13` |
| `CL-58` | Una llamada anidada o repetida intenta liquidar dos veces la misma posición usando los mismos fondos o garantía. | Cada ejecución completada debe volver a comprobar estado, elegibilidad y cantidades disponibles; no se aplican dos veces los mismos recursos. Si no puede garantizarse, se revierte el intento afectado. | `INV-01`, `INV-04`, `INV-11`, `INV-13` |
| `CL-59` | Una devolución de `EC-06` y una liquidación intentan afectar la misma deuda o garantía. | Rige el orden de transacciones. Si primero hay devolución, se reevalúa la posición. Después de un cierre confirmado se rechaza el segundo intento. | `INV-03`, `INV-07`, `INV-11`, `INV-13` |
| `CL-60` | Una secuencia combina cambios de precio, liquidaciones, recuperaciones, reconocimientos de pérdida e intentos fallidos. | Tras cada transición se comprueban las propiedades aplicables; cada intento fallido conserva el estado inmediatamente anterior sin borrar el interés correspondiente al tiempo transcurrido ni los efectos previos válidos. | `INV-01`–`INV-13` |

### Criterio de Cobertura

Probar precios y deuda a ambos lados del umbral, incluida la igualdad, garantía con valor inferior a una unidad de deuda, caja del liquidador insuficiente y asignaciones exactas de ambos tokens.

Esta matriz sirve para diseñar las pruebas de elegibilidad, cierre, recuperación y pérdida.
