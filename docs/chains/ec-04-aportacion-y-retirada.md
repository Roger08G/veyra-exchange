# `EC-04` Aportación y Retirada de Liquidez

La cadena económica `EC-04` gestiona las aportaciones al fondo de liquidez de Veyra, las participaciones de sus proveedores y la retirada del capital que les corresponde según su valor y la liquidez disponible.

## Objetivo

El objetivo de esta cadena es permitir que los usuarios aporten capital al fondo destinado a préstamos y reciban participaciones a cambio. También permite solicitar la retirada de sus participaciones conforme al valor del fondo y a la liquidez disponible, manteniendo separado el capital del fondo de los saldos disponibles para pagos y de los ingresos del protocolo.

El único fondo presta MockUSD. El rendimiento y las pérdidas cambian el patrimonio y el valor de sus participaciones.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen los siguientes actores:

- El **proveedor de liquidez** aporta capital y solicita la retirada de sus propias participaciones, sujetas a las condiciones del fondo.
- El **contrato del fondo de liquidez de Veyra** valida las operaciones, mantiene las participaciones y los datos contables necesarios, y procesa las retiradas permitidas.
- El **contrato de cuentas** carga o abona el disponible de MockUSD del proveedor.
- La cadena de **préstamos y garantías `EC-05`** utiliza liquidez del fondo para los préstamos conforme a sus propias reglas.
- **EC-06** mantiene principal e intereses. Todo el interés pertenece al fondo y se reconoce al devengarse en unidades enteras.
- La cadena de **liquidaciones y pérdidas `EC-07`** gestiona liquidaciones y pérdidas; la deuda incobrable reduce el patrimonio del fondo según el alcance del MVP.
- El **administrador** configura los parámetros autorizados del fondo. Esta función no le permite apropiarse de las participaciones o saldos de los usuarios ni modificarlos arbitrariamente.

## Variables y Estado Contable

El fondo mantiene la información necesaria para identificar su patrimonio, la liquidez disponible para retiradas y préstamos, y el capital comprometido en préstamos. La liquidez disponible y el patrimonio del fondo son conceptos distintos: una parte del patrimonio puede estar comprometida y no estar disponible para una retirada inmediata.

Cada proveedor tiene participaciones internas con 6 decimales. El suministro es la suma de las participaciones individuales.

En el instante t, el patrimonio H es la caja libre de MockUSD más la suma de principal e interés entero pendiente de cada préstamo activo a t. El riesgo se reconoce como pérdida en el cierre de EC-07. El interés pendiente se valora antes de cualquier emisión o reembolso, incluso si nadie ha ejecutado una devolución. Se proyecta cada préstamo al mismo instante con el resto fraccionario de EC-06, se toma su interés entero y después se suman los créditos. Dos fracciones de préstamos distintos nunca forman una unidad adicional de patrimonio.

**Reglas contables:** Una aportación completada incorpora al fondo el capital efectivamente aportado y asigna al proveedor las participaciones calculadas conforme a la regla vigente.

El proveedor solicita retirar un número de participaciones propias. El fondo abona MockUSD disponible según el patrimonio y el suministro inmediatamente anteriores.

Los saldos disponibles para pagos, los fondos bloqueados como garantías, el patrimonio del fondo y los ingresos del protocolo son partidas diferenciadas. La presencia física de tokens en un contrato no convierte automáticamente una partida en otra.

MockUSD es el único activo aceptado para aportaciones y reembolsos.

## Flujo Económico

### Flujo de Aportación de Liquidez

El usuario solicita aportar una cantidad al fondo. Veyra comprueba que la cuenta, el token, el importe y la fuente de fondos cumplen las condiciones aplicables.

Si la aportación se completa, el capital efectivamente aportado se incorpora a la contabilidad del fondo y el usuario recibe las participaciones calculadas. El total de participaciones se actualiza en consecuencia y la operación queda identificada con los datos necesarios para relacionar el capital aportado con las participaciones asignadas.

Se carga el disponible individual y el total disponible de MockUSD. La caja del fondo aumenta por esa misma cantidad.

Con patrimonio y suministro cero se emite una unidad mínima de participación por unidad mínima de MockUSD. En las aportaciones posteriores se emite la parte entera de `aporte × suministro / patrimonio`, calculada antes de incorporar el aporte.

### Flujo de Retirada de Liquidez

El proveedor solicita retirar parte o la totalidad de su posición en el fondo. Veyra comprueba que la operación está autorizada, que el proveedor posee las participaciones necesarias y que existe liquidez suficiente para el reembolso calculado.

Al ejecutar se reducen el saldo individual de participaciones y el suministro, se debita la caja y se acredita el reembolso al proveedor. Se registran los importes de la operación.

El reembolso se acredita al disponible de MockUSD del proveedor. El retiro externo posterior pertenece a EC-01.

El importe es la parte entera de `participaciones retiradas × patrimonio / suministro`. Se exige resultado positivo y caja suficiente. Un intento sin caja revierte completo.

### Rendimiento y Pérdidas del Fondo

Un cobro de principal o interés pendiente sustituye un derecho de cobro por caja. La pérdida neta reconocida al liquidar reduce el patrimonio y el valor de cada participación.

Los intereses, las devoluciones y las pérdidas se originan y gestionan en sus respectivas cadenas. `EC-04` necesita sus resultados contables para valorar las participaciones, sin ejecutar por sí misma la devolución o liquidación de préstamos.

## Validaciones y Restricciones

### Validaciones de Aportaciones

- El proveedor aporta desde su propio disponible.
- Solo se admite MockUSD por un importe positivo.
- La aportación solo puede completarse si el capital que corresponde se ha incorporado efectivamente al fondo conforme a la fuente y al mecanismo de custodia definidos.
- Si se utiliza saldo disponible, este debe cubrir el cargo y actualizarse junto con el total disponible del token. No pueden utilizarse fondos bloqueados ni saldos de otros usuarios.
- Se rechaza una emisión que redondee a cero o un estado con solo uno de estos dos valores a cero: patrimonio y suministro.
- Las cantidades y los saldos resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.
- Si falla una validación, el movimiento de fondos o una actualización necesaria, la aportación debe revertirse por completo, sin capital ni participaciones parcialmente registrados.

### Validaciones de Retiradas

- El proveedor solo puede solicitar la retirada de su propia posición y debe disponer de las participaciones necesarias para la operación.
- El número de unidades de participación solicitadas debe ser positivo.
- El importe de reembolso debe calcularse con la valoración y el redondeo aplicables en el momento establecido para la operación.
- La caja del fondo debe cubrir todo el reembolso.
- Se exige reembolso positivo y reducción de las mismas participaciones en el saldo del proveedor y en el suministro.
- Si falla una validación, el reembolso o una actualización necesaria, la retirada debe revertirse por completo, sin reducción parcial de participaciones ni reembolso definitivo parcial de esa operación.

### Restricciones del MVP

Las aportaciones y reembolsos son internos, completos y sin comisión. Las participaciones se contabilizan por proveedor y no se transfieren. Un excedente directo queda excluido del patrimonio. Si una pérdida total deja participaciones vivas y patrimonio cero, valen cero y cesan las aportaciones y los reembolsos en esa instancia. Una nueva simulación comienza con un despliegue limpio.

## Invariantes y Propiedades

Las variaciones se calculan como valor posterior menos valor anterior por operación. Para valorar participaciones se usa el patrimonio del fondo al tiempo del bloque.

Las cantidades se expresan en las unidades correspondientes al activo del fondo; las participaciones se expresan en sus propias unidades. No se suman importes de activos distintos sin una regla de valoración definida. Los cambios de otras cadenas se consideran únicamente en la medida en que afecten al fondo.

### Invariante `INV-01` - Conservación de Activos

En `EC-04`, una aportación o retirada completada debe contabilizar los activos efectivamente movidos entre su origen, el fondo, su destino y, en su caso, los ingresos del protocolo. La operación no puede crear ni destruir activos mediante una actualización contable sin respaldo.

En cada aportación o retirada, el cargo al origen coincide con el abono al destino. La comisión de EC-04 es cero.

```math
\forall o \in O:\quad
A_{\text{origen}}(o)=A_{\text{destino}}(o)+C_{\text{protocolo}}(o)
```

**Leyenda:**

- $O$: conjunto de aportaciones y retiradas completadas correctamente.
- $A_{\text{origen}}(o)$: importe efectivamente cargado al origen de la operación $o$.
- $A_{\text{destino}}(o)$: importe efectivamente incorporado al fondo en una aportación o acreditado al destino del proveedor en una retirada.
- $C_{\text{protocolo}}(o)$: cero en las aportaciones y reembolsos del MVP.

Al aportar, el disponible del proveedor disminuye y la caja aumenta. Al reembolsar se invierten ambos movimientos. En los dos sentidos se actualiza por el mismo importe el total disponible de MockUSD.

La valoración de referencia para las pruebas recorre los préstamos activos. La implementación puede mantener un índice de posiciones activas o una representación equivalente siempre que reproduzca esa suma exacta. Un cierre retira el ID de la valoración y conserva su historial.

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
- $\operatorname{emision}$: emisión entera calculada sobre patrimonio y suministro previos.

La emisión registrada debe reflejarse en la cuenta del proveedor y en el suministro total:

```math
\forall a \in A:\quad
\Delta S(u_a,a)=\Delta S_{\text{total}}(a)=S_{\text{emitidas}}(a)
```

- $u_a$: proveedor que realiza la aportación $a$.
- $\Delta S(u_a,a)$ y $\Delta S_{\text{total}}(a)$: variaciones reales de sus participaciones y del suministro atribuibles a la aportación.

Una emisión que resulte cero se rechaza antes de aceptar el capital.

Con patrimonio y suministro positivos, la emisión proporcional teórica es

```math
S_{\text{teoricas}}(a)=
\frac{A_{\text{fondo}}(a)\,S_{\text{antes}}(a)}{H_{\text{antes}}(a)}
```

- $S_{\text{teoricas}}(a)$: valor antes de redondear hacia abajo. El residuo es inferior a una unidad mínima de participación.

### Invariante `INV-03` - Consistencia del Valor por Participación

El valor por participación refleja el patrimonio calculado al mismo instante, incluida la parte comprometida en préstamos.

Con suministro positivo, el valor teórico de una participación es

```math
S_{\text{total}}>0:\quad
V_{\text{teorico}}=\frac{H_{\text{neto}}}{S_{\text{total}}}
```

**Leyenda:**

- $H_{\text{neto}}$: caja más principal e interés entero pendiente de los préstamos activos.
- $S_{\text{total}}$: total de participaciones existentes en el instante de valoración.
- $V_{\text{teorico}}$: valor teórico proporcional de una participación antes de redondeos o ajustes definidos.

Con suministro cero solo cabe la primera emisión si el patrimonio también es cero.

### Invariante `INV-04` - Proporcionalidad de Retiradas

El proveedor recibe el importe entero correspondiente a sus participaciones, calculado sobre la valoración previa al reembolso.

Con suministro positivo, el valor teórico de las participaciones retiradas es

```math
\forall r \in R_{\text{proporcional}}:\quad S_{\text{antes}}(r)>0 \implies
V_{\text{bruto}}(r)=
\frac{S_{\text{retiradas}}(r)\,H_{\text{antes}}(r)}{S_{\text{antes}}(r)}
```

**Leyenda:**

- $R_{\text{proporcional}}$: retiradas completadas de participaciones del fondo.
- $S_{\text{retiradas}}(r)$: participaciones reducidas al proveedor en la retirada $r$.
- $H_{\text{antes}}(r)$: patrimonio neto utilizado para valorar la retirada antes de ejecutarla.
- $S_{\text{antes}}(r)$: total de participaciones utilizado para esa valoración antes de reducirlas.
- $V_{\text{bruto}}(r)$: valor proporcional teórico antes de aplicar redondeo o comisiones.

El reembolso entero se redondea hacia abajo una sola vez. La retirada total del último proveedor obtiene todo el patrimonio si hay caja disponible y el resultado es positivo.

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
- $A_{\text{salidaFondo}}(r)$: importe del reembolso abonado al proveedor en MockUSD.
- $L_{\text{disponible}}^{\text{antes}}(r)$: caja libre de MockUSD antes del reembolso.

Una salida superior a la caja libre revierte íntegramente.

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

El número de participaciones ajenas se conserva. El redondeo deja en el fondo el residuo de la operación.

### Invariante `INV-07` - Contabilización de Rendimientos

El fondo reconoce el interés entero al devengarse. El cobro lo transforma en caja.

Para cada cobro de intereses reconocido, la variación de patrimonio atribuible al evento debe ser igual al efecto neto que corresponda al fondo, considerando cualquier importe previamente reconocido y sin contar dos veces el mismo rendimiento.

```math
\forall i \in I:\quad
\Delta H_{\text{neto}}(i)=E_{\text{interesFondo}}(i)
```

**Leyenda:**

- $I$: conjunto de eventos de cobro de intereses cuyos efectos se reconocen en el fondo.
- $\Delta H_{\text{neto}}(i)$: variación del patrimonio neto atribuible exclusivamente al evento $i$.
- $E_{\text{interesFondo}}(i)$: efecto patrimonial adicional al cobrar un interés ya reconocido, igual a cero al mismo instante.

Al comparar el estado antes y después del cobro al mismo instante, el interés ya está incluido en H y su cobro tiene efecto patrimonial neto cero.

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
- $A_{\text{perdidaFondo}}(p)$: deuda neta dada de baja en el cierre de EC-07.

Con suministro positivo, la baja de deuda de EC-07 reduce H y el valor por participación. El número de participaciones de cada proveedor se conserva.

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

Cada ejecución es atómica.

## Casos Límite y Escenarios de Fallo

Los siguientes casos sirven de referencia para futuras pruebas de `EC-04`. Las referencias `INV-01` a `INV-10` corresponden a esta cadena. En una ejecución de aportación o retirada fallida se revierten sus efectos, incluidos movimientos de fondos, participaciones, comisiones y registros definitivos.

El activo y las participaciones tienen 6 decimales. La valoración usa los enteros previos y aplica el redondeo al final.

### Fondo Inicial y Aportaciones

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | El fondo comienza sin patrimonio y sin participaciones y recibe su primera aportación válida. | Emisión inicial 1:1 en unidades mínimas. Aumentan en igual cantidad el saldo de participaciones del proveedor y el suministro. | `INV-01`, `INV-02`, `INV-09` |
| `CL-02` | El total de participaciones es cero, pero hay patrimonio o activos atribuidos al fondo. | Se rechaza la aportación por estado inconsistente. Un excedente directo queda fuera de H. | `INV-02`, `INV-03`, `INV-06` |
| `CL-03` | Existen participaciones, pero el patrimonio neto es cero. | Las participaciones valen cero. El fondo deja de admitir aportaciones y reembolsos. | `INV-02`, `INV-03`, `INV-08` |
| `CL-04` | Se solicita una aportación de importe cero. | Se rechaza sin movimiento de capital ni emisión de participaciones. | Validaciones, `INV-10` |
| `CL-05` | Se solicita aportar una unidad mínima del activo o un importe de dos unidades. | Se admite una unidad si la emisión calculada es positiva y se cumplen las demás validaciones. | `INV-01`, `INV-02`, `INV-10` |
| `CL-06` | Una aportación positiva produciría cero participaciones después del redondeo. | Se revierte el aporte sin cobrar los activos. | `INV-02`, `INV-06`, `INV-10` |
| `CL-07` | Un usuario aporta de nuevo cuando ya tiene participaciones. | Si se completa, se añade la emisión calculada a su saldo y al total; los saldos de participaciones de otros proveedores no cambian por la operación. | `INV-02`, `INV-06`, `INV-09` |
| `CL-08` | Un nuevo proveedor aporta cuando ya existe patrimonio y suministro positivo. | Se usa la valoración aplicable antes de incorporar su aportación. La emisión y su redondeo deben cumplir la regla definida y evitar transferencias de valor injustificadas entre proveedores. | `INV-02`, `INV-03`, `INV-06` |
| `CL-09` | Una aportación utiliza un token no autorizado para el fondo. | Se rechaza cualquier token distinto de la dirección de MockUSD. | Validaciones, `INV-01`, `INV-10` |
| `CL-10` | Un usuario o el administrador intenta aportar utilizando fondos de otra cuenta sin la autorización requerida. | Se rechaza sin movimiento definitivo ni emisión; administrar el fondo no concede acceso a fondos ajenos. | Validaciones, `INV-06`, `INV-10` |
| `CL-11` | La fuente es el disponible propio de MockUSD. | El saldo individual y el total disponible disminuyen por el aporte, y la caja aumenta por el mismo importe. | `INV-01`, `INV-02` |
| `CL-12` | Se intenta aportar desde una cartera externa. | La aportación requiere saldo disponible. Primero se debe ejecutar un depósito EC-01. | `INV-01`, `INV-02`, `INV-10` |
| `CL-13` | El capital efectivamente incorporado difiere del solicitado. | Se revierte el aporte completo. Las participaciones solo se emiten por la cantidad exacta incorporada. | `INV-01`, `INV-02`, `INV-10` |
| `CL-14` | Hay fondos bloqueados, participaciones ajenas o ingresos del protocolo junto a la fuente utilizada. | No se emplean como aportación del usuario ni se atribuyen al fondo por el mero hecho de estar custodiados en un contrato. | `INV-01`, `INV-06` |

### Valoración, Participaciones y Redondeo

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-15` | El fondo tiene patrimonio y suministro positivos, sin activos comprometidos. | El patrimonio coincide con la caja y el valor teórico por participación es H dividido entre suministro. | `INV-02`, `INV-03`, `INV-04` |
| `CL-16` | Parte del capital está comprometido en préstamos. | El principal y el interés entero por cobrar forman parte de H. Solo la caja libre puede financiar el reembolso inmediato. | `INV-03`, `INV-05` |
| `CL-17` | La emisión o el reembolso teórico produce una fracción de unidad. | Se aplica el redondeo definido una vez conforme a la operación. Deben establecerse el sentido, el límite del error y el destino de cualquier diferencia antes de probar un resultado numérico. | `INV-02`–`INV-04`, `INV-06` |
| `CL-18` | Una cantidad se aporta o retira mediante varias operaciones pequeñas en lugar de una sola. | En cada operación se redondea una sola vez hacia abajo. El residuo de cada división es menor que una unidad mínima del resultado. | `INV-02`–`INV-04`, `INV-06` |
| `CL-19` | Una aportación pequeña sigue a un cambio de patrimonio o a una transferencia directa de tokens al contrato del fondo. | Usar el patrimonio al tiempo de la aportación. Una transferencia directa solo aumenta el excedente sin atribuir. | `INV-01`–`INV-03`, `INV-06` |
| `CL-20` | El patrimonio o suministro previo es inconsistente o no puede valorarse conforme a la configuración. | Detectar la inconsistencia y rechazar la operación que requiere valorar el fondo. | `INV-02`, `INV-03`, `INV-09` |
| `CL-21` | El producto para emitir o reembolsar excede 256 bits, o un resultado final queda fuera de rango. | Se calcula el cociente con la precisión necesaria. Si el patrimonio, el suministro o un saldo resultante excede su rango, se revierte sin movimientos. | `INV-02`–`INV-04`, `INV-09`, `INV-10` |
| `CL-22` | La valoración se consulta y el estado del fondo cambia antes de ejecutarse la operación. | Se utiliza el patrimonio y el suministro al ejecutar, antes de mover las partidas de esa operación. | `INV-02`–`INV-04` |

### Retiradas y Liquidez Disponible

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-23` | La solicitud de retirada es cero. | Se rechaza sin reducir participaciones ni efectuar un reembolso. | Validaciones, `INV-10` |
| `CL-24` | Un proveedor retira parte de sus participaciones con liquidez suficiente. | Si se completa, se reducen sus participaciones y el suministro según la operación, y se acredita el reembolso calculado conforme a la regla definida. | `INV-01`, `INV-04`, `INV-05`, `INV-09` |
| `CL-25` | Un proveedor solicita retirar todas sus participaciones y existen otros proveedores. | Si se completa, su saldo de participaciones queda a cero y los saldos de participaciones ajenos permanecen inalterados; el suministro se reduce por las participaciones retiradas. | `INV-04`, `INV-06`, `INV-09` |
| `CL-26` | El último proveedor solicita retirar todas las participaciones. | Con caja suficiente y patrimonio positivo, el último proveedor recibe todo H. Quedan caja, patrimonio y suministro a cero. | `INV-01`, `INV-04`, `INV-09` |
| `CL-27` | El proveedor solicita retirar más participaciones de las que posee, o no tiene ninguna. | Se rechaza la ejecución sin usar participaciones de otros ni dejar un reembolso o reducción parcial definitiva. | Validaciones, `INV-06`, `INV-10` |
| `CL-28` | Un usuario o el administrador intenta retirar participaciones de otro proveedor. | Se rechaza sin modificar participaciones ni fondos; la administración del fondo no concede ese derecho. | Validaciones, `INV-06`, `INV-10` |
| `CL-29` | La salida total del fondo coincide exactamente con la liquidez disponible. | Se permite agotar la caja si alcanza el reembolso entero. La comisión de EC-04 es cero. | `INV-01`, `INV-04`, `INV-05` |
| `CL-30` | La salida total supera la liquidez disponible en una unidad mínima o más. | Se revierte íntegramente sin quemar participaciones ni encolar la solicitud. | `INV-05`, `INV-10` |
| `CL-31` | El patrimonio es positivo, pero no hay liquidez disponible para un reembolso positivo. | Se rechaza sin quemar participaciones. | `INV-03`, `INV-05` |
| `CL-32` | El valor calculado de una posición o de la retirada es cero. | El reembolso cero se rechaza sin quemar participaciones. | `INV-04`, `INV-08` |
| `CL-33` | Una retirada se acredita al saldo disponible del proveedor. | El saldo individual y el total disponible del token aumentan por el reembolso acreditado; la reducción de participaciones y la salida del fondo corresponden a la misma ejecución. | `INV-01`, `INV-04`, `INV-09` |
| `CL-34` | Se solicita un destino de reembolso distinto del saldo disponible. | Se rechaza. El único destino es el saldo disponible de MockUSD del propio proveedor. | `INV-01`, `INV-05`, `INV-10` |
| `CL-35` | Se intenta cobrar una comisión de aportación o reembolso. | El importe cobrado por EC-04 debe ser cero. | `INV-01`, `INV-02`, `INV-04` |

### Rendimientos y Pérdidas

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-36` | Se ejecuta el primer cobro desde el último registro de interés. | Primero se valora el interés devengado a ese instante y después se reclasifica a caja el importe cobrado. | `INV-03`, `INV-07` |
| `CL-37` | Se cobra interés que ya estaba reconocido como activo del fondo. | Se aplica el tratamiento contable definido sin sumar por segunda vez el mismo rendimiento al patrimonio por el mero hecho del cobro. | `INV-03`, `INV-07` |
| `CL-38` | Se intenta atribuir parte del interés a la tesorería. | El interés es íntegro del fondo. La asignación a tesorería incumpliría la conciliación. | `INV-01`, `INV-07` |
| `CL-39` | Se devuelve principal de un préstamo sin interés nuevo atribuible al fondo. | Aumenta la caja y disminuye el principal por el mismo importe. | `INV-03`, `INV-07` |
| `CL-40` | Se reconoce una pérdida neta positiva del fondo. | El patrimonio disminuye por el efecto neto reconocido. Con valoración proporcional y suministro positivo, disminuye el valor teórico por participación sin alterar por ese hecho su número. | `INV-03`, `INV-08`, `INV-09` |
| `CL-41` | Se intenta reconocer otra vez parte de una pérdida ya registrada al cerrar. | El préstamo cerrado carece de deuda exigible. Rechazar el segundo reconocimiento. | `INV-08` |
| `CL-42` | Las pérdidas reducen el patrimonio a cero o exceden el patrimonio reconocido. | Con H cero cesan aportaciones y reembolsos. Una pérdida superior a la deuda contabilizada es un error de conciliación. | `INV-03`, `INV-08` |
| `CL-43` | Ocurren varios reconocimientos de intereses o pérdidas antes de una aportación o retirada. | La valoración debe considerar los efectos ya reconocidos conforme a las reglas vigentes, cada uno una sola vez y sin anticipar los no reconocidos. | `INV-02`–`INV-04`, `INV-07`, `INV-08` |
| `CL-44` | Se intenta contabilizar dos veces el mismo evento de rendimiento o pérdida. | Detectar el doble cómputo mediante la identidad del préstamo, los intervalos de devengo y el único registro de cierre. | `INV-07`, `INV-08` |

### Suministro, Aislamiento y Atomicidad

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-45` | No existen proveedores con participaciones. | El suministro es cero. La primera emisión 1:1 requiere patrimonio cero. Si existe patrimonio atribuido con suministro cero, se aplica `CL-02`. | `INV-03`, `INV-09` |
| `CL-46` | El suministro registrado difiere de la suma de participaciones individuales, incluso en una unidad. | La comprobación identifica un estado inconsistente. No se presupone un mecanismo de reparación ni que cada operación detecte cualquier inconsistencia previa. | `INV-09` |
| `CL-47` | Existen varios proveedores y uno aporta o retira. | Se actualizan su saldo y el suministro por la emisión o reducción correspondiente; los saldos de participaciones de los demás permanecen iguales. | `INV-02`, `INV-04`, `INV-06`, `INV-09` |
| `CL-48` | Falla una validación antes de mover fondos o participaciones. | La ejecución no deja cambios definitivos en saldos, patrimonio, suministro, comisiones ni registros atribuibles al intento. | `INV-10` |
| `CL-49` | Falla una actualización después de un movimiento de fondos provisional en una aportación. | Se revierte la ejecución completa, incluidos el movimiento, la actualización del fondo y cualquier emisión o registro provisional. | `INV-01`, `INV-02`, `INV-10` |
| `CL-50` | Falla el reembolso después de reducir provisionalmente participaciones. | Se revierte la retirada completa; no quedan participaciones reducidas ni reembolso o comisiones definitivos por ese intento. | `INV-04`, `INV-09`, `INV-10` |
| `CL-51` | Falla el registro o una actualización posterior al reembolso provisional. | Se revierten todos los efectos de la ejecución, incluidos el reembolso, las participaciones, el suministro y las comisiones provisionales. | `INV-01`, `INV-09`, `INV-10` |
| `CL-52` | Una llamada anidada o repetida intenta retirar dos veces las mismas participaciones o emitirlas dos veces por una aportación. | Cada ejecución completada debe basarse en fondos y participaciones efectivamente disponibles y registrar sus movimientos una sola vez. Si no puede garantizarse, se revierte la ejecución afectada. | `INV-01`, `INV-02`, `INV-06`, `INV-09`, `INV-10` |
| `CL-53` | Una secuencia mezcla aportaciones, retiradas, reconocimientos de rendimiento o pérdida y operaciones fallidas. | Tras cada transición se comprueban las propiedades aplicables; cada intento fallido conserva el estado inmediatamente anterior a ese intento, incluidos los efectos válidos anteriores. | `INV-01`–`INV-10` |

### Criterio de Cobertura

Probar uno y varios proveedores, los estados límite de caja, deuda y patrimonio, y la valoración al tiempo de ejecución. En un intento fallido, comparar los saldos individuales y totales antes y después.

Esta matriz sirve para diseñar las pruebas de aportación, valoración y reembolso.
