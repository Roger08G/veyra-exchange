# `EC-04` Aportación y Retirada de Liquidez

La cadena económica `EC-04` gestiona las aportaciones al fondo de liquidez de Veyra, las participaciones de sus proveedores y la retirada del capital que les corresponde según su valor y la liquidez disponible.

## Objetivo

El objetivo de esta cadena es permitir que los usuarios aporten capital al fondo destinado a préstamos y reciban participaciones a cambio. También permite solicitar la retirada de sus participaciones conforme al valor del fondo y a la liquidez disponible, manteniendo separado el capital del fondo de los saldos disponibles para pagos y de los ingresos del protocolo.

En `v0.1.0` existe un único fondo de liquidez y un único mercado de préstamos. El rendimiento y las pérdidas pueden afectar al patrimonio del fondo y, por tanto, al valor de sus participaciones. Las reglas concretas de valoración y cálculo quedan pendientes de definición.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen los siguientes actores:

- El **proveedor de liquidez** aporta capital y solicita la retirada de sus propias participaciones, sujetas a las condiciones del fondo.
- El **contrato del fondo de liquidez de Veyra** valida las operaciones, mantiene las participaciones y los datos contables necesarios, y procesa las retiradas permitidas.
- El **contrato de cuentas** mantiene los saldos disponibles de los usuarios. Su relación concreta con los flujos de aportación y retirada del fondo está pendiente de definición.
- La cadena de **préstamos y garantías `EC-05`** utiliza liquidez del fondo para los préstamos conforme a sus propias reglas.
- La cadena de **intereses y devolución `EC-06`** gestiona la devolución de préstamos y los intereses. Su efecto concreto sobre el patrimonio del fondo debe quedar definido entre ambas cadenas.
- La cadena de **liquidaciones y pérdidas `EC-07`** gestiona liquidaciones y pérdidas; la deuda incobrable reduce el patrimonio del fondo según el alcance del MVP.
- El **administrador** configura los parámetros autorizados del fondo. Esta función no le permite apropiarse de las participaciones o saldos de los usuarios ni modificarlos arbitrariamente.

## Variables y Estado Contable

El fondo mantiene la información necesaria para identificar su patrimonio, la liquidez disponible para retiradas y préstamos, y el capital comprometido en préstamos. La liquidez disponible y el patrimonio del fondo son conceptos distintos: una parte del patrimonio puede estar comprometida y no estar disponible para una retirada inmediata.

Para cada proveedor se registran sus participaciones en el fondo. También se mantiene el total de participaciones emitidas, necesario para valorar la parte del patrimonio que corresponde a cada proveedor según la regla que se defina.

El rendimiento y las pérdidas pueden modificar el patrimonio y el valor de las participaciones. La forma de reconocer intereses, préstamos pendientes, deuda incobrable y otros componentes del patrimonio está pendiente de definición en las cadenas correspondientes.

**Reglas contables:** Una aportación completada incorpora al fondo el capital efectivamente aportado y asigna al proveedor las participaciones calculadas conforme a la regla vigente.

Una retirada completada reduce las participaciones del proveedor y el total de participaciones, y reembolsa el importe que corresponda según su valor y la liquidez disponible. La forma de expresar la solicitud y de calcular el importe está pendiente de definición.

Los saldos disponibles para pagos, los fondos bloqueados como garantías, el patrimonio del fondo y los ingresos del protocolo son partidas diferenciadas. La presencia física de tokens en un contrato no convierte automáticamente una partida en otra.

El README identifica un activo de prueba para pagos y préstamos, y otro para garantías; `tokens.md` identifica **MockUSD** para préstamos y **MockETH** principalmente para garantías. El activo concreto del fondo y los tokens admitidos para aportaciones y reembolsos deben quedar definidos antes de implementar estas operaciones.

## Flujo Económico

### Flujo de Aportación de Liquidez

El usuario solicita aportar una cantidad al fondo. Veyra comprueba que la cuenta, el token, el importe y la fuente de fondos cumplen las condiciones aplicables.

Si la aportación se completa, el capital efectivamente aportado se incorpora a la contabilidad del fondo y el usuario recibe las participaciones calculadas. El total de participaciones se actualiza en consecuencia y la operación queda identificada con los datos necesarios para relacionar el capital aportado con las participaciones asignadas.

La fuente de la aportación está pendiente de definición. Si se utiliza el saldo disponible del usuario, su saldo individual y el total disponible de ese token deben reducirse por el importe correspondiente, en coherencia con `EC-01`. Si se admite una fuente externa, deben definirse su autorización, recepción y efecto sobre la custodia.

La primera aportación requiere una regla inicial de emisión de participaciones. La valoración para aportaciones posteriores, las unidades de las participaciones y el redondeo también están pendientes de definición.

### Flujo de Retirada de Liquidez

El proveedor solicita retirar parte o la totalidad de su posición en el fondo. Veyra comprueba que la operación está autorizada, que el proveedor posee las participaciones necesarias y que existe liquidez suficiente para el reembolso calculado.

Para ejecutar la retirada, Veyra calcula el importe que corresponde conforme a la valoración aplicable y comprueba la salida total del fondo. Si la operación se completa, reduce las participaciones del proveedor y el total de participaciones y reembolsa el importe que corresponda por el destino que se defina. La operación queda registrada con los datos necesarios para relacionar las participaciones retiradas con el importe reembolsado.

El destino del reembolso está pendiente de definición. Si se acredita al saldo disponible del usuario, deben aumentar su saldo individual y el total disponible correspondiente; una retirada posterior de tokens del contrato de cuentas sería una operación de `EC-01`.

La solicitud de retirada por participaciones o por importe, el tratamiento del redondeo y la posibilidad de una ejecución parcial o diferida ante falta de liquidez están pendientes. Hasta que se definan, no se presupone un mecanismo de cola ni una retirada parcial.

### Rendimiento y Pérdidas del Fondo

El valor de las participaciones depende del patrimonio del fondo y de las participaciones existentes conforme al método de valoración que se defina. Por ello, una posición puede valer más o menos que el capital aportado inicialmente: el reembolso no se considera garantizado por el importe original.

Los intereses, las devoluciones y las pérdidas se originan y gestionan en sus respectivas cadenas. `EC-04` necesita sus resultados contables para valorar las participaciones, sin ejecutar por sí misma la devolución o liquidación de préstamos.

## Validaciones y Restricciones

### Validaciones de Aportaciones

- El usuario debe estar autorizado para aportar desde la fuente de fondos que se defina. La administración del fondo no concede acceso a fondos ajenos.
- El token debe estar autorizado para el fondo y la cantidad solicitada debe ser mayor que cero. Los posibles importes mínimos adicionales están pendientes de definición.
- La aportación solo puede completarse si el capital que corresponde se ha incorporado efectivamente al fondo conforme a la fuente y al mecanismo de custodia definidos.
- Si se utiliza saldo disponible, este debe cubrir el cargo y actualizarse junto con el total disponible del token. No pueden utilizarse fondos bloqueados ni saldos de otros usuarios.
- La emisión de participaciones debe calcularse con la valoración y el redondeo aplicables. Las reglas para la primera aportación y para situaciones sin patrimonio o sin participaciones deben definirse antes de ejecutar esos casos.
- Las cantidades y los saldos resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si falla una validación, el movimiento de fondos o una actualización necesaria, la aportación debe revertirse por completo, sin capital ni participaciones parcialmente registrados.

### Validaciones de Retiradas

- El proveedor solo puede solicitar la retirada de su propia posición y debe disponer de las participaciones necesarias para la operación.
- La cantidad solicitada debe ser mayor que cero y ajustarse a la unidad de solicitud que se defina.
- El importe de reembolso debe calcularse con la valoración y el redondeo aplicables en el momento establecido para la operación.
- La liquidez disponible debe cubrir la salida total que se vaya a ejecutar, incluido el reembolso y cualquier comisión separada del fondo que se defina. El capital comprometido en préstamos y los fondos correspondientes a saldos, garantías o ingresos ajenos al fondo no pueden utilizarse como liquidez disponible del fondo.
- La reducción de participaciones y el reembolso deben corresponder a la misma operación. No pueden reducirse participaciones sin aplicar el importe que corresponda según las reglas definidas ni efectuarse un reembolso sin la reducción correspondiente. La admisibilidad de retirar una posición cuyo valor sea cero está pendiente.
- Si falla una validación, el reembolso o una actualización necesaria, la retirada debe revertirse por completo, sin reducción parcial de participaciones ni reembolso definitivo parcial de esa operación.

### Restricciones Pendientes de Definición

- El activo del fondo, los tokens admitidos para aportación y reembolso, la fuente de la aportación y el destino del reembolso.
- La composición y valoración del patrimonio, incluidos préstamos pendientes, intereses, pérdidas y cualquier reserva aplicable.
- La emisión inicial y posterior de participaciones, sus unidades, la valoración para retiradas y el sentido del redondeo.
- El tratamiento de las situaciones en que el patrimonio o el total de participaciones sea cero, así como de pérdidas que reduzcan el valor de la posición.
- Los importes mínimos, las posibles comisiones y las condiciones aplicables a cada operación.
- La unidad de solicitud de retirada y el tratamiento de solicitudes sin liquidez suficiente, incluida la posible existencia de ejecuciones parciales o diferidas.
- El momento de valoración y la información que debe registrarse para cada aportación y retirada.
- La atribución de transferencias directas al contrato del fondo y su posible efecto en la valoración, respetando las reglas de `EC-01` para las transferencias directas al contrato de cuentas.

Estas decisiones deben concretarse antes de implementar los comportamientos que dependen de ellas. Las operaciones de otras cadenas conservan sus propias reglas y responsabilidades.

## Invariantes y Propiedades

Las siguientes propiedades son propuestas para `EC-04` y describen los efectos atribuibles a cada operación. Una variación se calcula como valor posterior menos valor anterior. El patrimonio neto del fondo, los activos que lo integran, la asignación de intereses, las comisiones, la valoración y el redondeo deben concretarse antes de convertir estas propiedades en reglas ejecutables.

Las cantidades se expresan en las unidades correspondientes al activo del fondo; las participaciones se expresan en sus propias unidades. No se suman importes de activos distintos sin una regla de valoración definida. Los cambios de otras cadenas se consideran únicamente en la medida en que afecten al fondo.

### Invariante `INV-01` - Conservación de Activos

En `EC-04`, una aportación o retirada completada debe contabilizar los activos efectivamente movidos entre su origen, el fondo, su destino y, en su caso, los ingresos del protocolo. La operación no puede crear ni destruir activos mediante una actualización contable sin respaldo.

Para cada operación completada, el cargo total atribuible a la operación coincide con el importe acreditado al destino más las comisiones efectivamente separadas, si se definen y aplican. El origen y el destino dependen del tipo de operación.

```math
\forall o \in O:\quad
A_{\text{origen}}(o)=A_{\text{destino}}(o)+C_{\text{protocolo}}(o)
```

**Leyenda:**

- $O$: conjunto de aportaciones y retiradas completadas correctamente.
- $A_{\text{origen}}(o)$: importe efectivamente cargado al origen de la operación $o$.
- $A_{\text{destino}}(o)$: importe efectivamente incorporado al fondo en una aportación o acreditado al destino del proveedor en una retirada.
- $C_{\text{protocolo}}(o)$: comisión efectivamente separada para el protocolo por esa operación, si se define; es cero si no se aplica.

La fuente de aportación, el destino del reembolso y las posibles comisiones siguen pendientes. Si se utilizan saldos disponibles de `EC-01`, deben actualizarse tanto el saldo individual como el total correspondiente. Esta relación de movimientos no equivale a afirmar que el patrimonio del fondo siempre coincida con su liquidez física.

El cargo, el importe acreditado y la comisión son magnitudes contables reales atribuibles a una misma ejecución y a un mismo activo. Una comisión definida para el protocolo debe registrarse como ingreso separado una sola vez; su posible existencia y cálculo permanecen pendientes.

### Invariante `INV-02` - Integridad de Participaciones

En `EC-04`, las participaciones asignadas en una aportación deben corresponder al capital efectivamente incorporado al fondo, conforme a la valoración y el redondeo aplicables. No pueden asignarse participaciones por capital que no se haya aportado.

Para cada aportación completada, la emisión debe calcularse con la regla vigente a partir del capital efectivo y del estado del fondo utilizado para valorar la operación.

```math
\forall a \in A:\quad
S_{\text{emitidas}}(a)
= \operatorname{emision}(A_{\text{fondo}}(a),H_{\text{antes}}(a),S_{\text{antes}}(a))
```

**Leyenda:**

- $A$: conjunto de aportaciones completadas correctamente.
- $S_{\text{emitidas}}(a)$: participaciones asignadas al proveedor por la aportación $a$.
- $A_{\text{fondo}}(a)$: capital efectivamente incorporado al fondo por la aportación.
- $H_{\text{antes}}(a)$: patrimonio neto del fondo utilizado para valorar la aportación antes de incorporarla.
- $S_{\text{antes}}(a)$: total de participaciones utilizado para esa valoración antes de emitir las nuevas.
- $\operatorname{emision}$: regla de emisión y redondeo que debe definirse, incluida la primera aportación.

La emisión registrada debe reflejarse en la cuenta del proveedor y en el suministro total:

```math
\forall a \in A:\quad
\Delta S(u_a,a)=\Delta S_{\text{total}}(a)=S_{\text{emitidas}}(a)
```

- $u_a$: proveedor que realiza la aportación $a$.
- $\Delta S(u_a,a)$ y $\Delta S_{\text{total}}(a)$: variaciones reales de sus participaciones y del suministro atribuibles a la aportación.

La regla deberá especificar cómo se relaciona el valor de las participaciones emitidas con el capital aportado, el efecto del redondeo y los estados con patrimonio o suministro cero. La igualdad anterior identifica los datos de los que depende el cálculo; por sí sola no fija una fórmula proporcional ni un margen de error.

Como referencia, si se adopta una emisión proporcional sin ajustes adicionales y el patrimonio y el suministro anteriores son positivos, la emisión teórica antes de redondear sería:

```math
S_{\text{teoricas}}(a)=
\frac{A_{\text{fondo}}(a)\,S_{\text{antes}}(a)}{H_{\text{antes}}(a)}
```

- $S_{\text{teoricas}}(a)$: participaciones proporcionales antes del redondeo. La emisión entera efectiva y el límite del error deben definirse.

### Invariante `INV-03` - Consistencia del Valor por Participación

En `EC-04`, el valor de las participaciones debe reflejar el patrimonio neto atribuible al fondo, teniendo en cuenta sus activos y obligaciones según la valoración que se defina. La liquidez disponible por sí sola no representa necesariamente todo ese patrimonio.

Cuando el suministro sea positivo y se defina una valoración proporcional sin ajustes adicionales, el valor teórico por participación es el patrimonio neto dividido entre el total de participaciones. El valor utilizado en operaciones debe aplicar las unidades y el redondeo que se definan.

```math
S_{\text{total}}>0:\quad
V_{\text{teorico}}=\frac{H_{\text{neto}}}{S_{\text{total}}}
```

**Leyenda:**

- $H_{\text{neto}}$: patrimonio neto atribuible al fondo, valorado según las reglas que se definan.
- $S_{\text{total}}$: total de participaciones existentes en el instante de valoración.
- $V_{\text{teorico}}$: valor teórico proporcional de una participación antes de redondeos o ajustes definidos.

Esta expresión es una referencia condicional, no una decisión sobre los componentes del patrimonio, las escalas numéricas o los ajustes permitidos. Cuando el suministro es cero no se realiza esta división; el tratamiento de ese estado permanece pendiente.

### Invariante `INV-04` - Proporcionalidad de Retiradas

En `EC-04`, el proveedor debe recibir el importe que corresponda a las participaciones reducidas en su retirada, con la valoración, el redondeo y las posibles comisiones definidos para la operación.

Cuando exista suministro positivo y se use valoración proporcional sin ajustes adicionales, el valor bruto teórico de las participaciones retiradas es su fracción del patrimonio neto utilizado para valorar la retirada. Bajo esas condiciones, el reembolso efectivo se obtiene aplicando las reglas de redondeo y comisiones que se definan.

```math
\forall r \in R_{\text{proporcional}}:\quad S_{\text{antes}}(r)>0 \implies
V_{\text{bruto}}(r)=
\frac{S_{\text{retiradas}}(r)\,H_{\text{antes}}(r)}{S_{\text{antes}}(r)}
```

**Leyenda:**

- $R_{\text{proporcional}}$: conjunto de retiradas completadas correctamente a las que se aplica la valoración proporcional sin ajustes adicionales, si se adopta esa regla.
- $S_{\text{retiradas}}(r)$: participaciones reducidas al proveedor en la retirada $r$.
- $H_{\text{antes}}(r)$: patrimonio neto utilizado para valorar la retirada antes de ejecutarla.
- $S_{\text{antes}}(r)$: total de participaciones utilizado para esa valoración antes de reducirlas.
- $V_{\text{bruto}}(r)$: valor proporcional teórico antes de aplicar redondeo o comisiones.

La fórmula no decide si se solicita una cantidad de participaciones o de activos, ni permite una ejecución que exceda la liquidez disponible. El tratamiento del valor cero, las comisiones y el redondeo permanece pendiente.

En cualquier retirada completada, independientemente del método de valoración, la reducción debe reflejarse tanto en la posición del proveedor como en el suministro total:

```math
\forall r \in R:\quad
\Delta S(u_r,r)=\Delta S_{\text{total}}(r)=-S_{\text{retiradas}}(r)
```

- $R$: conjunto de retiradas completadas correctamente.
- $u_r$: proveedor que realiza la retirada $r$.
- $\Delta S(u_r,r)$ y $\Delta S_{\text{total}}(r)$: variaciones reales de sus participaciones y del suministro atribuibles a la retirada.

### Invariante `INV-05` - Protección de Liquidez Disponible

En `EC-04`, una retirada solo puede ejecutarse si la liquidez del fondo disponible para esa operación cubre el importe que deba salir del fondo. El patrimonio comprometido en préstamos y las reservas ajenas no pueden tratarse como liquidez libre.

Para cada retirada completada, la salida total atribuible a la operación no puede superar la liquidez disponible del fondo inmediatamente antes de ejecutarla.

```math
\forall r \in R:\quad
A_{\text{salidaFondo}}(r) \leq L_{\text{disponible}}^{\text{antes}}(r)
```

**Leyenda:**

- $R$: conjunto de retiradas completadas correctamente.
- $A_{\text{salidaFondo}}(r)$: importe total que deja de estar disponible para el fondo por la retirada $r$, incluidos los importes separados como comisión si se definen.
- $L_{\text{disponible}}^{\text{antes}}(r)$: liquidez del fondo disponible para esa retirada inmediatamente antes de ejecutarla, según la regla que se defina.

La expresión se aplica a cada ejecución efectiva y no decide si una solicitud insuficientemente cubierta se rechaza, se ejecuta parcialmente o se difiere.

### Invariante `INV-06` - Aislamiento de Proveedores

En `EC-04`, una aportación o retirada de un proveedor solo modifica sus propias participaciones y el suministro total correspondiente. Las participaciones registradas de otros proveedores permanecen inalteradas por esa operación.

Para cada operación completada, la variación de las participaciones de cualquier proveedor distinto del que la realiza es cero.

```math
\forall o \in O,\quad \forall v \in U:\quad
v\ne u_o \implies \Delta S(v,o)=0
```

**Leyenda:**

- $O$: conjunto de aportaciones y retiradas completadas correctamente.
- $U$: conjunto de proveedores del fondo.
- $u_o$: proveedor que realiza la operación $o$.
- $v$: otro proveedor cuyas participaciones se comprueban.
- $\Delta S(v,o)$: variación de las participaciones registradas de $v$ atribuible a la operación $o$.

El número de participaciones ajenas no cambia por la operación, aunque su valor económico puede verse afectado por la valoración y el redondeo que se definan. La regla final deberá controlar esos efectos y evitar transferencias de valor injustificadas entre proveedores.

### Invariante `INV-07` - Contabilización de Rendimientos

En `EC-04`, los intereses cobrados que correspondan al fondo deben reflejarse correctamente en su patrimonio y, por tanto, en la valoración de las participaciones. La asignación de intereses y su reconocimiento contable deben definirse con `EC-06` y `EC-08`.

Para cada cobro de intereses reconocido, la variación de patrimonio atribuible al evento debe ser igual al efecto neto que corresponda al fondo, considerando cualquier importe previamente reconocido y sin contar dos veces el mismo rendimiento.

```math
\forall i \in I:\quad
\Delta H_{\text{neto}}(i)=E_{\text{interesFondo}}(i)
```

**Leyenda:**

- $I$: conjunto de eventos de cobro de intereses cuyos efectos se reconocen en el fondo.
- $\Delta H_{\text{neto}}(i)$: variación del patrimonio neto atribuible exclusivamente al evento $i$.
- $E_{\text{interesFondo}}(i)$: efecto patrimonial neto atribuible al fondo por ese evento, calculado según las reglas de reconocimiento y asignación que se definan.

El efecto neto no tiene por qué coincidir con todo el efectivo recibido: parte del interés podría haber sido reconocida previamente o asignarse fuera del fondo, según las reglas pendientes. Esta propiedad no presupone que los intereses se reconozcan solo cuando se cobran.

### Invariante `INV-08` - Distribución de Pérdidas

En `EC-04`, las pérdidas reconocidas que correspondan al fondo deben reducir su patrimonio neto y reflejarse en la valoración de las participaciones. La deuda incobrable reduce el patrimonio del fondo conforme al alcance del MVP.

Para cada pérdida neta reconocida y atribuible al fondo, la variación de patrimonio causada exclusivamente por ese reconocimiento es igual a su importe negativo.

```math
\forall p \in P:\quad
\Delta H_{\text{neto}}(p)=-A_{\text{perdidaFondo}}(p)
```

**Leyenda:**

- $P$: conjunto de eventos de pérdida reconocidos que afectan al fondo.
- $\Delta H_{\text{neto}}(p)$: variación del patrimonio neto atribuible exclusivamente al evento $p$.
- $A_{\text{perdidaFondo}}(p)$: pérdida neta no negativa atribuible al fondo por ese evento, determinada conforme a las reglas que se definan.

La pérdida neta debe tener en cuenta los efectos ya reconocidos y las recuperaciones o garantías según las reglas de `EC-07`, sin contabilizarlos dos veces. Con valoración proporcional y suministro positivo, una pérdida reduce el valor teórico por participación; las reglas para patrimonio cero o insuficiente están pendientes.

### Invariante `INV-09` - Integridad del Suministro

En `EC-04`, el total de participaciones registrado debe coincidir con la suma de las participaciones existentes de todos los proveedores. Las aportaciones y retiradas deben actualizar el saldo individual y el total de forma coherente.

En cada estado contable, el suministro total es igual a la suma de las participaciones individuales registradas.

```math
S_{\text{total}}=\sum_{u \in U} S(u)
```

**Leyenda:**

- $U$: conjunto de proveedores con participaciones registradas.
- $S(u)$: participaciones existentes del proveedor $u$.
- $S_{\text{total}}$: total de participaciones existentes registrado por el fondo.

### Invariante `INV-10` - Atomicidad de Operaciones

En `EC-04`, una aportación o retirada fallida no puede dejar movimientos de fondos, cambios de participaciones, comisiones ni registros definitivos parciales atribuibles a ese intento.

Para cada intento fallido, los estados afectados y los registros correspondientes después del intento coinciden con los inmediatamente anteriores.

```math
\forall f \in F:\quad
E_{\text{despues}}(f)=E_{\text{antes}}(f)
```

**Leyenda:**

- $F$: conjunto de intentos fallidos o rechazados de aportación o retirada.
- $E_{\text{antes}}(f)$: estado contable, de participaciones y registros afectados inmediatamente antes del intento $f$.
- $E_{\text{despues}}(f)$: esos mismos estados y registros después del intento, considerando sus efectos atribuibles.

La atomicidad se refiere a cada ejecución. No decide la política pendiente de solicitudes parciales o diferidas ni altera los efectos de operaciones anteriores completadas.

## Casos Límite y Escenarios de Fallo

Los siguientes casos sirven de referencia para futuras pruebas de `EC-04`. Las referencias `INV-01` a `INV-10` corresponden a esta cadena. En una ejecución de aportación o retirada fallida se revierten sus efectos, incluidos movimientos de fondos, participaciones, comisiones y registros definitivos.

Los importes se expresan en unidades mínimas del activo correspondiente y las participaciones en sus propias unidades. Cuando el resultado depende de una decisión pendiente, el caso describe las condiciones que deben mantenerse sin elegir anticipadamente esa decisión. Las referencias a otras cadenas se limitan a sus efectos sobre el fondo.

### Fondo Inicial y Aportaciones

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | El fondo comienza sin patrimonio y sin participaciones y recibe su primera aportación válida. | Se aplica la regla inicial de emisión, pendiente de definición. El capital efectivamente incorporado y las participaciones asignadas se registran coherentemente; el total coincide con las participaciones del proveedor. | `INV-01`, `INV-02`, `INV-09` |
| `CL-02` | El total de participaciones es cero, pero hay patrimonio o activos atribuidos al fondo. | El tratamiento del estado y la primera emisión están pendientes. No se divide entre cero ni se asigna automáticamente ese patrimonio al primer proveedor sin una regla definida. | `INV-02`, `INV-03`, `INV-06` |
| `CL-03` | Existen participaciones, pero el patrimonio neto es cero. | La emisión de nuevas participaciones y el tratamiento de las existentes están pendientes. No se divide entre cero ni se presume una recuperación de valor. | `INV-02`, `INV-03`, `INV-08` |
| `CL-04` | Se solicita una aportación de importe cero. | Se rechaza sin movimiento de capital ni emisión de participaciones. | Validaciones, `INV-10` |
| `CL-05` | Se solicita aportar una unidad mínima del activo o un importe cercano al mínimo adicional, si se define. | Se aplican el mínimo, la emisión y el redondeo definidos. Si la operación no cumple las condiciones, se revierte sin registrar capital ni participaciones parciales. | `INV-01`, `INV-02`, `INV-10` |
| `CL-06` | Una aportación positiva produciría cero participaciones después del redondeo. | Su admisibilidad y tratamiento están pendientes. No se debe completar atribuyendo silenciosamente capital sin las participaciones que correspondan conforme a la regla definida. | `INV-02`, `INV-06`, `INV-10` |
| `CL-07` | Un usuario aporta de nuevo cuando ya tiene participaciones. | Si se completa, se añade la emisión calculada a su saldo y al total; los saldos de participaciones de otros proveedores no cambian por la operación. | `INV-02`, `INV-06`, `INV-09` |
| `CL-08` | Un nuevo proveedor aporta cuando ya existe patrimonio y suministro positivo. | Se usa la valoración aplicable antes de incorporar su aportación. La emisión y su redondeo deben cumplir la regla definida y evitar transferencias de valor injustificadas entre proveedores. | `INV-02`, `INV-03`, `INV-06` |
| `CL-09` | Una aportación utiliza un token no autorizado para el fondo o distinto del activo que se defina. | Se rechaza sin modificar fondos ni participaciones. El activo concreto del fondo sigue pendiente de definición. | Validaciones, `INV-01`, `INV-10` |
| `CL-10` | Un usuario o el administrador intenta aportar utilizando fondos de otra cuenta sin la autorización requerida. | Se rechaza sin movimiento definitivo ni emisión; administrar el fondo no concede acceso a fondos ajenos. | Validaciones, `INV-06`, `INV-10` |
| `CL-11` | La fuente es el saldo disponible de la cuenta, si esa fuente se autoriza. | El saldo individual y el total disponible del token disminuyen por el cargo correspondiente; el fondo recibe el capital efectivo y se contabilizan separadamente las comisiones que se definan. | `INV-01`, `INV-02` |
| `CL-12` | Se autoriza una fuente externa, pero falla la autorización o el movimiento de entrada. | La aportación no se completa y se revierten los efectos del intento, sin capital ni participaciones definitivos. | `INV-01`, `INV-02`, `INV-10` |
| `CL-13` | El capital efectivamente incorporado difiere del solicitado. | No se emiten participaciones como si se hubiera incorporado un importe distinto. La admisibilidad de cualquier diferencia depende del mecanismo que se defina; si no cumple sus reglas, se revierte. | `INV-01`, `INV-02`, `INV-10` |
| `CL-14` | Hay fondos bloqueados, participaciones ajenas o ingresos del protocolo junto a la fuente utilizada. | No se emplean como aportación del usuario ni se atribuyen al fondo por el mero hecho de estar custodiados en un contrato. | `INV-01`, `INV-06` |

### Valoración, Participaciones y Redondeo

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-15` | El fondo tiene patrimonio y suministro positivos, sin activos comprometidos. | La valoración utiliza el patrimonio neto definido y el suministro anterior a la operación; si se adopta la regla proporcional, el valor teórico por participación es patrimonio dividido entre suministro. | `INV-02`, `INV-03`, `INV-04` |
| `CL-16` | Parte del capital está comprometido en préstamos. | El patrimonio y la liquidez disponible se calculan por separado conforme a las reglas definidas; no se presume que el capital prestado sea efectivo disponible para retirar. | `INV-03`, `INV-05` |
| `CL-17` | La emisión o el reembolso teórico produce una fracción de unidad. | Se aplica el redondeo definido una vez conforme a la operación. Deben establecerse el sentido, el límite del error y el destino de cualquier diferencia antes de probar un resultado numérico. | `INV-02`–`INV-04`, `INV-06` |
| `CL-18` | Una cantidad se aporta o retira mediante varias operaciones pequeñas en lugar de una sola. | Cada ejecución sigue su propia valoración y redondeo. No se presupone que el resultado acumulado coincida con el de una sola operación; las diferencias deben respetar los límites que se definan. | `INV-02`–`INV-04`, `INV-06` |
| `CL-19` | Una aportación pequeña sigue a un cambio de patrimonio o a una transferencia directa de tokens al contrato del fondo. | La emisión debe usar el patrimonio reconocido conforme a la regla vigente, no una valoración obsoleta. La atribución de transferencias directas al fondo y la protección frente a efectos injustificados están pendientes; si la transferencia se hace al contrato de cuentas, se respetan las reglas de `EC-01`. | `INV-01`–`INV-03`, `INV-06` |
| `CL-20` | El patrimonio o suministro previo es inconsistente o no puede valorarse conforme a la configuración. | Se identifica como estado de fallo; no se aplica una valoración inventada. La detección y reparación general del estado deben definirse y no se dan por implementadas. | `INV-02`, `INV-03`, `INV-09` |
| `CL-21` | Un cálculo intermedio, el patrimonio, el saldo de participaciones o el suministro excedería el rango representable. | Se rechaza y revierte la ejecución afectada; no se aceptan desbordamientos, subdesbordamientos ni truncamientos silenciosos. | `INV-02`–`INV-04`, `INV-09`, `INV-10` |
| `CL-22` | La valoración se consulta y el estado del fondo cambia antes de ejecutarse la operación. | Se usa el estado correspondiente al momento de valoración que se defina para la ejecución; no se presupone protección frente a variaciones de precio o un límite de deslizamiento aún no especificado. | `INV-02`–`INV-04` |

### Retiradas y Liquidez Disponible

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-23` | La solicitud de retirada es cero. | Se rechaza sin reducir participaciones ni efectuar un reembolso. | Validaciones, `INV-10` |
| `CL-24` | Un proveedor retira parte de sus participaciones con liquidez suficiente. | Si se completa, se reducen sus participaciones y el suministro según la operación, y se acredita el reembolso calculado conforme a la regla definida. | `INV-01`, `INV-04`, `INV-05`, `INV-09` |
| `CL-25` | Un proveedor solicita retirar todas sus participaciones y existen otros proveedores. | Si se completa, su saldo de participaciones queda a cero y los saldos de participaciones ajenos permanecen inalterados; el suministro se reduce por las participaciones retiradas. | `INV-04`, `INV-06`, `INV-09` |
| `CL-26` | El último proveedor solicita retirar todas las participaciones. | Si se completa, el suministro queda a cero. El tratamiento de posibles residuos de patrimonio o redondeo debe estar definido; no se presume que desaparezcan ni que se asignen a alguien automáticamente. | `INV-01`, `INV-04`, `INV-09` |
| `CL-27` | El proveedor solicita retirar más participaciones de las que posee, o no tiene ninguna. | Se rechaza la ejecución sin usar participaciones de otros ni dejar un reembolso o reducción parcial definitiva. | Validaciones, `INV-06`, `INV-10` |
| `CL-28` | Un usuario o el administrador intenta retirar participaciones de otro proveedor. | Se rechaza sin modificar participaciones ni fondos; la administración del fondo no concede ese derecho. | Validaciones, `INV-06`, `INV-10` |
| `CL-29` | La salida total del fondo coincide exactamente con la liquidez disponible. | Supera la comprobación de liquidez si se cumplen las demás condiciones. La salida incluye las comisiones separadas del fondo que correspondan, si se definen. | `INV-01`, `INV-04`, `INV-05` |
| `CL-30` | La salida total supera la liquidez disponible en una unidad mínima o más. | No puede ejecutarse esa salida completa consumiendo capital comprometido o reservas ajenas. El rechazo, ejecución parcial o aplazamiento de la solicitud sigue pendiente; cada ejecución efectiva debe estar cubierta. | `INV-05`, `INV-10` |
| `CL-31` | El patrimonio es positivo, pero no hay liquidez disponible para un reembolso positivo. | No puede ejecutarse el reembolso positivo sin liquidez. La política de solicitud, cola o aplazamiento permanece pendiente. | `INV-03`, `INV-05` |
| `CL-32` | El valor calculado de una posición o de la retirada es cero. | La posibilidad de reducir participaciones con reembolso cero y sus condiciones están pendientes; no se presume que la posición conserve el capital originalmente aportado. | `INV-04`, `INV-08` |
| `CL-33` | Una retirada se acredita al saldo disponible del proveedor, si ese destino se autoriza. | El saldo individual y el total disponible del token aumentan por el reembolso acreditado; la reducción de participaciones y la salida del fondo corresponden a la misma ejecución. | `INV-01`, `INV-04`, `INV-09` |
| `CL-34` | Se solicita un destino de reembolso distinto del saldo disponible. | El destino y su autorización deben estar definidos. Un reembolso completado se acredita al destino autorizado y cumple conservación y liquidez; si falla, la ejecución se revierte. | `INV-01`, `INV-05`, `INV-10` |
| `CL-35` | Se define una comisión de aportación o retirada. | Se aplica únicamente conforme a la regla que se establezca. El importe separado para el protocolo se contabiliza una sola vez, sin confundirse con el capital incorporado o el reembolso recibido. | `INV-01`, `INV-02`, `INV-04` |

### Rendimientos y Pérdidas

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-36` | Se cobra interés que corresponde al fondo y no se había reconocido previamente en su patrimonio. | El patrimonio refleja el efecto neto que se atribuya al fondo según las reglas definidas; no se presupone que todo el cobro pertenezca al fondo. | `INV-03`, `INV-07` |
| `CL-37` | Se cobra interés que ya estaba reconocido como activo del fondo. | Se aplica el tratamiento contable definido sin sumar por segunda vez el mismo rendimiento al patrimonio por el mero hecho del cobro. | `INV-03`, `INV-07` |
| `CL-38` | Una parte del interés cobrado se asigna al protocolo o a otra partida conforme a una regla definida. | Solo el efecto neto atribuible al fondo modifica su patrimonio por ese concepto; la parte separada no se cuenta también como rendimiento del fondo. | `INV-01`, `INV-07` |
| `CL-39` | Se devuelve principal de un préstamo sin interés nuevo atribuible al fondo. | Se aplica la reclasificación y valoración que se definan; la devolución de principal no se cuenta automáticamente como rendimiento adicional. | `INV-03`, `INV-07` |
| `CL-40` | Se reconoce una pérdida neta positiva del fondo. | El patrimonio disminuye por el efecto neto reconocido. Con valoración proporcional y suministro positivo, disminuye el valor teórico por participación sin alterar por ese hecho su número. | `INV-03`, `INV-08`, `INV-09` |
| `CL-41` | Una pérdida se había reconocido parcialmente antes de su liquidación o existe una recuperación de garantías. | La pérdida neta adicional se determina conforme a `EC-07`, evitando duplicar importes ya reconocidos o ignorar recuperaciones que correspondan al fondo. | `INV-08` |
| `CL-42` | Las pérdidas reducen el patrimonio a cero o exceden el patrimonio reconocido. | La valoración, las obligaciones y los estados permitidos deben definirse; no se presume un valor negativo representable, un rescate ni una recuperación automática. | `INV-03`, `INV-08` |
| `CL-43` | Ocurren varios reconocimientos de intereses o pérdidas antes de una aportación o retirada. | La valoración debe considerar los efectos ya reconocidos conforme a las reglas vigentes, cada uno una sola vez y sin anticipar los no reconocidos. | `INV-02`–`INV-04`, `INV-07`, `INV-08` |
| `CL-44` | Se intenta contabilizar dos veces el mismo evento de rendimiento o pérdida. | El mismo efecto económico no se incorpora dos veces al patrimonio. El mecanismo concreto de identificación y registro del evento debe definirse. | `INV-07`, `INV-08` |

### Suministro, Aislamiento y Atomicidad

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-45` | No existen proveedores con participaciones. | El suministro registrado y la suma de saldos individuales son cero; la existencia o tratamiento de patrimonio residual se evalúa por separado. | `INV-03`, `INV-09` |
| `CL-46` | El suministro registrado difiere de la suma de participaciones individuales, incluso en una unidad. | La comprobación identifica un estado inconsistente. No se presupone un mecanismo de reparación ni que cada operación detecte cualquier inconsistencia previa. | `INV-09` |
| `CL-47` | Existen varios proveedores y uno aporta o retira. | Se actualizan su saldo y el suministro por la emisión o reducción correspondiente; los saldos de participaciones de los demás permanecen iguales. | `INV-02`, `INV-04`, `INV-06`, `INV-09` |
| `CL-48` | Falla una validación antes de mover fondos o participaciones. | La ejecución no deja cambios definitivos en saldos, patrimonio, suministro, comisiones ni registros atribuibles al intento. | `INV-10` |
| `CL-49` | Falla una actualización después de un movimiento de fondos provisional en una aportación. | Se revierte la ejecución completa, incluidos el movimiento, la actualización del fondo y cualquier emisión o registro provisional. | `INV-01`, `INV-02`, `INV-10` |
| `CL-50` | Falla el reembolso después de reducir provisionalmente participaciones. | Se revierte la retirada completa; no quedan participaciones reducidas ni reembolso o comisiones definitivos por ese intento. | `INV-04`, `INV-09`, `INV-10` |
| `CL-51` | Falla el registro o una actualización posterior al reembolso provisional. | Se revierten todos los efectos de la ejecución, incluidos el reembolso, las participaciones, el suministro y las comisiones provisionales. | `INV-01`, `INV-09`, `INV-10` |
| `CL-52` | Una llamada anidada o repetida intenta retirar dos veces las mismas participaciones o emitirlas dos veces por una aportación. | Cada ejecución completada debe basarse en fondos y participaciones efectivamente disponibles y registrar sus movimientos una sola vez. Si no puede garantizarse, se revierte la ejecución afectada. | `INV-01`, `INV-02`, `INV-06`, `INV-09`, `INV-10` |
| `CL-53` | Una secuencia mezcla aportaciones, retiradas, reconocimientos de rendimiento o pérdida y operaciones fallidas. | Tras cada transición se comprueban las propiedades aplicables; cada intento fallido conserva el estado inmediatamente anterior a ese intento, incluidos los efectos válidos anteriores. | `INV-01`–`INV-10` |

### Criterio de Cobertura

Aplicar los casos pertinentes a cada fuente, destino y activo que se autoricen; con uno y varios proveedores; con patrimonio y suministro en sus estados límite; y con liquidez libre y comprometida. Comprobar la valoración y el suministro tras cada transición relevante y comparar los estados afectados antes y después de cada ejecución fallida. Los efectos de `EC-05`, `EC-06`, `EC-07` y `EC-08` se consideran aquí solo en lo que afecten al fondo.

Esta matriz identifica clases de límites y fallos para `EC-04`; no demuestra que se hayan enumerado todas las secuencias posibles ni sustituye las pruebas o una verificación formal. Las reglas pendientes de valoración, redondeo, comisiones y reconocimiento deben concretarse antes de convertir sus resultados condicionales en pruebas ejecutables.
