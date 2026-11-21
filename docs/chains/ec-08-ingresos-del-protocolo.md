# `EC-08` Ingresos del Protocolo

La cadena económica `EC-08` gestiona la contabilización y retirada de los ingresos propios ya cobrados por el protocolo Veyra.

## Objetivo

El objetivo de esta cadena es identificar los ingresos efectivamente cobrados que corresponden al protocolo, mantenerlos separados de los saldos y garantías de los usuarios y del patrimonio del fondo, y permitir su retirada conforme a las autorizaciones y condiciones que se definan.

En `v0.1.0`, los ingresos del protocolo incluyen comisiones y cuotas ya cobradas que le correspondan. La existencia, el importe y el destino de otras posibles partidas dependen de las reglas de sus respectivas cadenas.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen los siguientes actores:

- Las **cadenas de origen** generan operaciones que pueden cobrar importes para el protocolo y deben identificar su importe, token y procedencia.
- La **contabilidad de ingresos de Veyra** registra los importes que correspondan al protocolo y mantiene la información necesaria para conocer los ingresos retenidos y sus retiradas.
- El **actor autorizado para retirar ingresos** solicita la retirada conforme a la regla de permisos que se defina. Su identidad, las facultades concretas y el destino autorizado están pendientes.
- El **contrato o contratos de custodia** mantienen los tokens que respaldan los ingresos y otras partidas. La distribución concreta de custodia entre contratos está pendiente de definición.
- El **administrador** configura los parámetros autorizados del protocolo. Su facultad de configuración no le permite mover fondos de usuarios o del fondo de liquidez ni modificar arbitrariamente sus saldos.
- El **fondo de liquidez `EC-04`** mantiene su patrimonio separado de los ingresos del protocolo; sus rendimientos no se convierten automáticamente en ingresos del protocolo.

## Variables y Estado Contable

Para cada token admitido, Veyra necesita distinguir el **saldo de ingresos del protocolo retenidos** de los saldos disponibles de usuarios, las garantías bloqueadas, el patrimonio del fondo y otras reservas. El saldo retenido representa ingresos propios ya cobrados que todavía no se han retirado ni aplicado a un ajuste autorizado que llegue a definirse.

La información de cada ingreso debe permitir identificar su cadena y operación de origen, el token, el importe efectivamente cobrado y su atribución al protocolo. Cada retirada debe poder relacionarse con el token, el importe, la autorización y el destino correspondientes.

El historial de ingresos cobrados y retiradas realizadas debe distinguirse del saldo actualmente retenido. La forma concreta de conservar o consultar ese historial, así como el tratamiento de reembolsos y ajustes, está pendiente de definición.

**Reglas contables:** Solo los importes efectivamente cobrados y atribuidos al protocolo conforme a la cadena de origen pueden aumentar el saldo total de ingresos retenidos por un nuevo cobro. Una comisión calculada, devengada o pendiente de cobro no se convierte por sí sola en ingreso retirable. Los posibles ajustes autorizados siguen pendientes de definición.

El cobro efectivo puede ser un movimiento contable interno de fondos ya custodiados, cuando la cadena de origen lo permita; no exige por sí mismo una transferencia externa de tokens. En todos los casos, la atribución debe quedar respaldada y no contar dos veces la misma cantidad.

La retirada de ingresos reduce el saldo retenido del token y la custodia correspondiente por el importe efectivamente retirado, sin consumir fondos de usuarios, garantías, patrimonio del fondo u otras reservas ajenas. La disponibilidad física de tokens en un contrato no convierte automáticamente esos tokens en ingresos del protocolo.

## Flujo Económico

### Origen y Registro de Ingresos

Las operaciones de `EC-01` pueden generar comisiones de retirada; las de `EC-02`, comisiones de pago; y las de `EC-03`, cuotas de suscripción. `EC-05` puede generar una comisión de apertura conforme a su regla de cobro. Las posibles comisiones de `EC-04`, las asignaciones de interés de `EC-06` y los importes propios de `EC-07` solo constituyen ingresos del protocolo si sus reglas los atribuyen a él y se cobran efectivamente.

Cuando una operación de origen se completa y cobra un importe para el protocolo, Veyra registra una sola vez el ingreso correspondiente para el token utilizado. El registro debe mantener su vínculo con el cobro y con la operación que lo originó.

Si la operación de origen falla o se revierte, no queda un ingreso definitivo por ese intento. Las tasas, los redondeos y las condiciones de cada cobro se rigen por su cadena de origen y, cuando corresponda, por `EC-03`.

### Custodia y Disponibilidad de Ingresos

Los ingresos retenidos deben estar respaldados por tokens efectivamente custodiados conforme al modelo que se defina. Si comparten custodia con otras partidas, la contabilidad debe distinguir sus importes y preservar el respaldo de las obligaciones ajenas.

Para los ingresos retenidos en el contrato de cuentas, la retirada debe coordinarse con `EC-01`: el saldo real del contrato y los ingresos retenidos disminuyen por la misma cantidad, sin modificar los saldos disponibles de los usuarios ni las reservas de terceros.

La ubicación de los fondos y la relación entre saldos de ingresos registrados en distintos contratos están pendientes de definición. Un importe reconocido en una ubicación no puede retirarse dos veces ni utilizarse simultáneamente para cubrir otra obligación incompatible. Un movimiento autorizado entre ámbitos puede aumentar el saldo atribuido al destino y disminuir el del origen, pero no es un nuevo cobro ni aumenta por sí solo el total retenido del protocolo.

### Retirada de Ingresos

El actor autorizado solicita retirar una cantidad de un token hacia un destino permitido. Veyra comprueba la autorización, el saldo retenido del token, la custodia disponible y el respaldo de las demás partidas que compartan esa custodia.

Si la retirada se completa, se reduce el saldo de ingresos retenidos, se transfieren los tokens al destino autorizado y se registra la operación. La retirada no modifica los saldos disponibles de usuarios, sus garantías, sus deudas ni las participaciones del fondo.

La identidad del actor autorizado, el destino, los límites y la posibilidad de retirar una parte o la totalidad del saldo deben concretarse. No se presupone que la facultad de configurar el protocolo incluya automáticamente la de retirar ingresos.

### Transferencias Directas y Ajustes

Los tokens enviados directamente a un contrato fuera de un flujo autorizado no se registran automáticamente como ingresos del protocolo ni dan derecho a retirarlos como tales. El tratamiento de posibles excedentes y su eventual recuperación están fuera de las reglas actualmente definidas.

El tratamiento de reembolsos, correcciones contables, recuperaciones u otros ajustes de ingresos, si llegan a permitirse, está pendiente de definición. Estos ajustes no deben presumirse ni utilizarse para modificar arbitrariamente saldos de usuarios o del fondo.

## Validaciones y Restricciones

### Validaciones de Registro de Ingresos

- El ingreso debe proceder de una operación autorizada de una cadena de origen e identificar el token, el importe y la operación que lo generó.
- El importe debe haber sido efectivamente cobrado y atribuido al protocolo conforme a las reglas de origen. Un cálculo provisional o una cantidad pendiente de cobro no es ingreso retirable.
- El mismo cobro no puede registrarse más de una vez. La contabilidad debe distinguir un movimiento interno correctamente atribuido de una transferencia directa no registrada.
- El token debe estar admitido conforme a la configuración aplicable y el importe debe expresarse en sus propias unidades mínimas. No se mezclan ni convierten saldos de tokens distintos sin una regla definida.
- Si falla la operación de origen o una actualización necesaria del registro, sus efectos deben revertirse conforme a la atomicidad de esa operación; no permanece un ingreso definitivo parcial por el intento fallido.
- Los importes y saldos resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.

### Validaciones de Retirada de Ingresos

- El solicitante debe estar autorizado expresamente para retirar ingresos del protocolo y el destino debe cumplir la regla que se defina.
- El token debe estar admitido para la operación y el importe solicitado debe ser mayor que cero.
- El saldo de ingresos retenidos del token debe cubrir la retirada y debe existir custodia suficiente para ejecutarla, preservando el respaldo de saldos, garantías, patrimonio del fondo y otras reservas ajenas.
- La retirada solo puede utilizar ingresos propios ya cobrados y retenidos; no puede completarse con fondos de usuarios, garantías, patrimonio del fondo o excedentes no atribuidos.
- La disminución del saldo de ingresos y la transferencia efectiva deben corresponder a la misma retirada. Sus datos deben quedar registrados conforme a la regla que se defina.
- Si falla una validación, la transferencia o una actualización necesaria, la retirada debe revertirse por completo, sin descuento, transferencia ni registro definitivo parcial de ese intento.

### Restricciones Pendientes de Definición

- El actor o rol autorizado para retirar ingresos, el destino permitido y el procedimiento para configurar o cambiar esos permisos.
- La ubicación y el modelo de custodia de los ingresos, incluidos los movimientos entre contratos y la conciliación de sus saldos.
- Los tokens admitidos para cada origen y para las retiradas, las unidades, los posibles mínimos y los límites aplicables.
- La identificación y trazabilidad de cada cobro, retirada y posible ajuste, y la forma de conservar o consultar su historial.
- Los reembolsos, correcciones y otros ajustes autorizados, su contabilización y sus efectos sobre ingresos ya retirados o retenidos.
- La atribución de posibles comisiones de `EC-04`, intereses de `EC-06` e importes de `EC-07`, conforme a las reglas que se definan en esas cadenas.
- El tratamiento de excedentes enviados directamente, sin presumir que puedan convertirse en ingresos o retirarse.

Mientras existan saldos disponibles, garantías, ingresos retenidos u otras reservas contabilizadas pendientes para un token, `EC-01` establece que no puede desautorizarse en `v0.1.0`. Cualquier cambio de configuración debe respetar esa restricción.

Estas decisiones deben concretarse antes de implementar los comportamientos que dependen de ellas. Las cadenas de origen conservan la responsabilidad de calcular y cobrar sus propias comisiones o cuotas.

## Invariantes y Propiedades

Las siguientes propiedades son propuestas para `EC-08`. Se aplican por token y a los efectos atribuibles a cada operación; las variaciones se calculan como valor posterior menos valor anterior. Las comisiones y cuotas son ingresos de las cadenas de origen cuando se han cobrado y atribuido al protocolo; otras posibles fuentes solo se incluyen si sus reglas llegan a definirlas expresamente.

Se distingue el **historial de ingresos cobrados** del **saldo de ingresos retenidos** y del importe **disponible para una retirada concreta**. El saldo retenido no implica por sí solo que una retirada desde cualquier ubicación pueda ejecutarse: también deben cumplirse la autorización, la custodia y el respaldo de las demás obligaciones.

### Invariante `INV-01` - Integridad de Ingresos

En `EC-08`, cada ingreso registrado debe corresponder a un importe efectivamente cobrado y atribuido al protocolo por una operación de origen autorizada. Una comisión calculada o una cuota pendiente no cumplen esa condición por sí solas.

Para cada registro definitivo de ingreso existe un cobro válido asociado, con el mismo token y el importe atribuido al protocolo que corresponda.

```math
\forall i\in I:\quad \exists c\in C:\quad
\operatorname{vinculado}(i,c)\land t_i=t_c\land A_i=A_{\text{protocolo}}(c)
```

**Leyenda:**

- $I$: conjunto de registros definitivos de ingresos del protocolo.
- $C$: conjunto de cobros efectivos de operaciones autorizadas que atribuyen un importe al protocolo.
- $\operatorname{vinculado}(i,c)$: indica que el registro $i$ identifica el cobro de origen $c$.
- $t_i$ y $t_c$: token registrado en el ingreso y token del cobro correspondiente.
- $A_i$: importe del ingreso registrado.
- $A_{\text{protocolo}}(c)$: parte del cobro atribuida efectivamente al protocolo conforme a la regla de origen.

El cobro puede ser una atribución contable interna respaldada de fondos ya custodiados. La existencia y el tratamiento de ingresos distintos de comisiones y cuotas siguen dependiendo de sus cadenas de origen.

Cada importe atribuible de un cobro debe quedar identificado una sola vez en los registros definitivos, conforme a la relación anterior. Si en el futuro se permite dividir un cobro entre varios registros, deberá revisarse esta fórmula y definirse cómo evitar solapamientos.

### Invariante `INV-02` - Conservación de Comisiones

En `EC-08`, cada comisión efectivamente cobrada y atribuida al protocolo debe registrarse por el mismo importe y token, una sola vez. Las cuotas y otras fuentes que se definan siguen el mismo criterio de atribución efectiva.

Para cada cobro completado y atribuido al protocolo, el incremento de ingresos retenidos causado por ese cobro coincide con la parte efectivamente cobrada que corresponde al protocolo.

```math
\forall c\in C:\quad
\Delta I_{\text{retenido}}(t_c,c)=A_{\text{protocolo}}(c)
```

**Leyenda:**

- $C$: conjunto de cobros efectivos autorizados atribuidos al protocolo.
- $t_c$: token del cobro $c$.
- $A_{\text{protocolo}}(c)$: importe efectivamente cobrado que corresponde al protocolo.
- $\Delta I_{\text{retenido}}(t_c,c)$: variación del saldo de ingresos retenidos para ese token atribuible exclusivamente al cobro.

Si una operación también distribuye importes al fondo u otros destinatarios, solo se registra como ingreso del protocolo la parte que le corresponde. Los reembolsos o ajustes futuros requieren reglas separadas y no alteran retroactivamente el importe histórico cobrado sin una contabilización definida.

### Invariante `INV-03` - Separación Patrimonial

En `EC-08`, los ingresos del protocolo deben mantenerse contablemente separados de los fondos disponibles y garantías de usuarios, del patrimonio del fondo de liquidez y de otras reservas ajenas. Una misma unidad de respaldo no puede utilizarse simultáneamente para obligaciones incompatibles.

Para cada token, las unidades atribuidas a ingresos retenidos no deben estar atribuidas a la vez a partidas ajenas que no puedan compartir ese respaldo.

```math
\forall t\in T:\quad
R_{\text{ingresos}}(t)\cap R_{\text{ajenas}}(t)=\varnothing
```

**Leyenda:**

- $T$: conjunto de tokens admitidos en la contabilidad correspondiente.
- $R_{\text{ingresos}}(t)$: unidades de respaldo del token $t$ atribuidas a ingresos retenidos del protocolo.
- $R_{\text{ajenas}}(t)$: unidades de ese token atribuidas a saldos, garantías, patrimonio del fondo u otras reservas que no puedan compartir respaldo con esos ingresos.
- $\varnothing$: conjunto vacío.

La expresión representa separación de atribuciones contables; no exige que los tokens estén físicamente en contratos distintos. El modelo concreto de custodia y conciliación debe definir cómo se comprueba esta propiedad sin duplicar obligaciones.

### Invariante `INV-04` - Respaldo de Ingresos

En `EC-08`, los ingresos retenidos disponibles para retirada deben estar respaldados por tokens efectivamente custodiados y no comprometidos en obligaciones incompatibles.

Para cada token y ámbito de custodia que se defina, el saldo de ingresos retenidos atribuido a ese ámbito no supera el respaldo efectivamente disponible para esos ingresos.

```math
\forall t\in T,\quad \forall h\in H:\quad
I_{\text{retenido}}(t,h)\leq B_{\text{respaldo}}(t,h)
```

**Leyenda:**

- $T$: conjunto de tokens admitidos.
- $H$: ámbitos de custodia y atribución que se definan.
- $I_{\text{retenido}}(t,h)$: ingresos retenidos del token $t$ atribuidos al ámbito $h$.
- $B_{\text{respaldo}}(t,h)$: cantidad del token efectivamente custodiada en ese ámbito y disponible para respaldar esos ingresos, excluyendo las obligaciones incompatibles.

Los ámbitos no deben contar dos veces un mismo respaldo. La agregación entre contratos y la liquidez para ejecutar una retirada concreta dependen del modelo de custodia pendiente.

### Invariante `INV-05` - Consistencia de Ingresos Acumulados

En `EC-08`, el historial de ingresos cobrados debe representar la suma de los cobros efectivos atribuidos al protocolo, sin registrar dos veces un mismo importe. Una retirada reduce el saldo retenido, pero no borra por sí misma el historial de cobros.

Para cada token y periodo completo de historial considerado, el ingreso histórico bruto es igual a la suma de los importes de los cobros definitivos atribuidos al protocolo durante ese periodo.

```math
\forall t\in T:\quad
H_{\text{cobrado}}(t)=\sum_{c\in C_t} A_{\text{protocolo}}(c)
```

**Leyenda:**

- $T$: conjunto de tokens admitidos.
- $C_t$: conjunto de cobros definitivos del token $t$ atribuidos al protocolo en el periodo completo considerado, cada uno una sola vez.
- $A_{\text{protocolo}}(c)$: importe del cobro $c$ atribuido al protocolo.
- $H_{\text{cobrado}}(t)$: total histórico bruto de esos cobros para el token $t$.

El historial puede obtenerse mediante el mecanismo de registro o consulta que se defina; la fórmula no exige un contador concreto. Si se admiten reembolsos, migraciones o correcciones, deberá definirse su representación sin confundir el bruto histórico con el saldo retenido ni borrar su trazabilidad.

Si el periodo considerado comienza con saldo retenido cero y no existen ajustes ni migraciones que afecten al total, el saldo retenido global de cada token coincide con lo cobrado menos lo retirado:

```math
\forall t\in T:\quad
I_{\text{retenidoTotal}}(t)=H_{\text{cobrado}}(t)-H_{\text{retirado}}(t)
```

- $I_{\text{retenidoTotal}}(t)$: ingresos retenidos del token $t$ agregados sin duplicaciones entre ámbitos.
- $H_{\text{retirado}}(t)$: suma de las retiradas definitivas al destino final del token $t$ durante el mismo periodo.

La igualdad es condicional: con saldo inicial positivo o ajustes autorizados deberán incorporarse esos efectos según las reglas que se definan. Un traslado entre custodias no se cuenta como nuevo cobro ni como retirada al destino final.

### Invariante `INV-06` - Integridad de Retiradas

En `EC-08`, una retirada de ingresos solo puede completarse si el saldo retenido del token y el respaldo disponible para la operación cubren la cantidad retirada, respetando las obligaciones ajenas.

Para cada retirada completada, el importe no supera el saldo retenido anterior ni el respaldo disponible en el ámbito desde el que se ejecuta.

```math
\forall w\in W:\quad
0<A_{\text{retirada}}(w)\leq I_{\text{antes}}(t_w,h_w),\quad
A_{\text{retirada}}(w)\leq B_{\text{disponible}}(t_w,h_w)
```

**Leyenda:**

- $W$: conjunto de retiradas de ingresos completadas correctamente.
- $t_w$ y $h_w$: token y ámbito de custodia desde el que se ejecuta la retirada $w$.
- $A_{\text{retirada}}(w)$: importe efectivamente retirado en esa operación.
- $I_{\text{antes}}(t_w,h_w)$: ingresos retenidos atribuibles a ese ámbito inmediatamente antes de la retirada.
- $B_{\text{disponible}}(t_w,h_w)$: respaldo disponible para la retirada después de proteger las obligaciones incompatibles.

Si se definen movimientos previos entre custodias, cada uno deberá contabilizarse conforme a su propia regla; no puede presumirse disponible en un contrato un saldo respaldado exclusivamente en otro.

### Invariante `INV-07` - Conservación de Retiradas

En `EC-08`, una retirada completada debe disminuir el saldo de ingresos retenidos y la custodia correspondiente exactamente por el importe efectivamente transferido al destino autorizado.

Para cada retirada completada, el descuento de ingresos y la disminución de custodia atribuibles a ella coinciden con la cantidad transferida.

```math
\forall w\in W:\quad
-\Delta I_{\text{retenido}}(t_w,h_w,w)
=-\Delta B_{\text{custodia}}(t_w,h_w,w)
=A_{\text{transferida}}(w)
```

**Leyenda:**

- $W$: conjunto de retiradas de ingresos completadas correctamente.
- $t_w$ y $h_w$: token y ámbito de custodia de la retirada $w$.
- $\Delta I_{\text{retenido}}(t_w,h_w,w)$: variación de ingresos retenidos atribuible a la retirada.
- $\Delta B_{\text{custodia}}(t_w,h_w,w)$: variación del saldo real custodiado en ese ámbito atribuible a la retirada.
- $A_{\text{transferida}}(w)$: cantidad efectivamente recibida por el destino autorizado.

La igualdad requiere que el token y el mecanismo entreguen exactamente esa cantidad. Si una transferencia no permite cumplirla, la retirada no puede completarse bajo estas reglas. Los movimientos entre custodias, si se incorporan, deben distinguirse de una retirada al destino final.

### Invariante `INV-08` - Aislamiento Contable

En `EC-08`, una retirada de ingresos no puede modificar saldos disponibles de usuarios, garantías, deudas o participaciones del fondo por el mero hecho de ejecutarse.

Para cada retirada completada, la variación atribuible a ella en cada una de esas partidas ajenas es cero.

```math
\forall w\in W,\quad \forall x\in X_{\text{ajenas}}:\quad
\Delta S(x,w)=0
```

**Leyenda:**

- $W$: conjunto de retiradas de ingresos completadas correctamente.
- $X_{\text{ajenas}}$: partidas de saldos disponibles, garantías, deudas y participaciones que no pertenecen a los ingresos del protocolo.
- $\Delta S(x,w)$: variación de la partida $x$ atribuible exclusivamente a la retirada $w$.

El cobro de una comisión en su cadena de origen sí puede modificar las partidas necesarias para esa operación, por ejemplo el saldo disponible del usuario que la paga. Esta propiedad se refiere a la retirada posterior de ingresos y no prohíbe esos efectos autorizados del cobro.

### Invariante `INV-09` - Integridad de Autorización

En `EC-08`, solo un actor expresamente autorizado puede ejecutar una retirada de ingresos y solo hacia un destino permitido por las reglas aplicables.

Para cada retirada completada, el actor y el destino cumplen la autorización vigente en el momento de ejecución.

```math
\forall w\in W:\quad
\operatorname{autorizado}(a_w,t_w,\tau_w)
\land\operatorname{destinoPermitido}(d_w,t_w,\tau_w)
```

**Leyenda:**

- $W$: conjunto de retiradas de ingresos completadas correctamente.
- $a_w$, $d_w$ y $t_w$: actor, destino y token de la retirada $w$.
- $\tau_w$: instante de ejecución de la retirada.
- $\operatorname{autorizado}$: condición de permiso del actor que se defina.
- $\operatorname{destinoPermitido}$: condición aplicable al destino que se defina.

La identidad del rol, su configuración y sus cambios permanecen pendientes. La facultad de administrar parámetros no implica automáticamente la autorización para retirar ingresos.

### Invariante `INV-10` - Atomicidad de Operaciones

En `EC-08`, un registro de ingreso o una retirada fallidos no pueden dejar ingresos, saldos, transferencias o registros definitivos parciales atribuibles al intento. La operación de origen debe conservar la atomicidad que le corresponde.

Para cada intento fallido, los estados afectados y registros posteriores coinciden con los inmediatamente anteriores en lo relativo a los efectos de ese intento.

```math
\forall f\in F:\quad
S_{\text{despues}}(f)=S_{\text{antes}}(f)
```

**Leyenda:**

- $F$: conjunto de intentos fallidos o rechazados de registro de ingresos o retirada.
- $S_{\text{antes}}(f)$: estados contables, de custodia y registros afectados inmediatamente antes del intento $f$.
- $S_{\text{despues}}(f)$: esos mismos estados y registros después del intento, considerando sus efectos atribuibles.

La propiedad no revierte operaciones anteriores completadas ni da por implementados mecanismos de reembolso o ajuste aún pendientes de definición.

## Casos Límite y Escenarios de Fallo

Los siguientes casos sirven de referencia para futuras pruebas de `EC-08`. Las referencias `INV-01` a `INV-10` corresponden a esta cadena. En un registro de ingreso o una retirada fallidos se revierten los efectos atribuibles al intento; la operación de origen conserva la atomicidad que le corresponda.

Los importes se expresan en unidades mínimas del token correspondiente. Los casos que dependen de permisos, custodia, ajustes u otras fuentes de ingreso aún no definidos se presentan como condicionales. Las cadenas de origen se consideran aquí solo en cuanto generan, respaldan o afectan a ingresos del protocolo.

### Origen y Registro de Ingresos

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Una comisión de retirada de `EC-01` se cobra correctamente y corresponde al protocolo. | Se registra una sola vez por el importe efectivamente cobrado y el token de la operación, vinculada a su origen. | `INV-01`, `INV-02`, `INV-05` |
| `CL-02` | Una comisión de pago de `EC-02` se cobra mediante una atribución interna de fondos ya custodiados. | Se reconoce una sola vez el importe efectivamente atribuido al protocolo; no se exige una transferencia externa por el mero hecho de registrar el ingreso. | `INV-01`, `INV-02`, `INV-03` |
| `CL-03` | Se cobra una cuota de suscripción de `EC-03`. | La cuota atribuida al protocolo se registra por su importe efectivo y token, vinculada a la operación de origen y al periodo que corresponda. | `INV-01`, `INV-02`, `INV-05` |
| `CL-04` | Una comisión de apertura de `EC-05` se calcula pero aún no se ha cobrado. | No aumenta por ese cálculo el ingreso retenido ni el histórico cobrado. Su tratamiento al cobrarse se rige por la regla de origen definida. | `INV-01`, `INV-02`, `INV-05` |
| `CL-05` | Se define una comisión de `EC-04`, una asignación de interés de `EC-06` o un importe de `EC-07` para el protocolo. | Solo la parte efectivamente cobrada y atribuida al protocolo se registra como ingreso, si la regla de origen la permite. No se cuenta también como rendimiento del fondo. | `INV-01`–`INV-03` |
| `CL-06` | Una cantidad se ha calculado o devengado, pero está pendiente de cobro. | No se registra como ingreso cobrado ni como saldo retirable por el mero devengo. | `INV-01`, `INV-04`, `INV-05` |
| `CL-07` | La comisión o cuota aplicable es cero y esa configuración se permite. | No aumenta el saldo retenido ni el histórico por un importe positivo. La forma de registrar una operación de importe cero depende de la regla de origen. | `INV-01`, `INV-02`, `INV-05` |
| `CL-08` | Se cobra una unidad mínima del token. | El ingreso retenido y el histórico aumentan exactamente por esa unidad atribuida al protocolo, sin pérdida de precisión. | `INV-02`, `INV-05` |
| `CL-09` | Una operación reparte un cobro entre el protocolo y otro destinatario. | Solo la parte efectivamente atribuida al protocolo incrementa sus ingresos; la parte ajena se registra en su propia partida sin duplicarla. | `INV-01`–`INV-03` |
| `CL-10` | La operación de origen cobra un importe, pero falla o se revierte antes de completarse. | No permanece un ingreso definitivo de ese intento. Se respetan la atomicidad y los estados previos de la operación de origen. | `INV-01`, `INV-02`, `INV-10` |
| `CL-11` | Se intenta registrar como ingreso un importe sin cobro válido o sin atribución al protocolo. | Se rechaza el registro; un importe previsto o una reserva ajena no se convierte en ingreso por una anotación aislada. | `INV-01`, `INV-03`, `INV-10` |
| `CL-12` | El token o importe del registro no coincide con el cobro de origen atribuido al protocolo. | No se completa un registro que atribuya un token o importe distinto; el intento fallido no deja efectos definitivos. | `INV-01`, `INV-02`, `INV-10` |
| `CL-13` | Se intenta registrar dos veces el mismo cobro. | El mismo importe no aumenta dos veces los ingresos retenidos ni el histórico. El mecanismo concreto de identificación y trazabilidad debe definirse. | `INV-01`, `INV-02`, `INV-05` |
| `CL-14` | Dos operaciones independientes cobran el mismo importe en el mismo token. | Cada cobro efectivo y atribuible se registra por separado con su propia procedencia; la igualdad de importes no los convierte automáticamente en el mismo cobro. | `INV-01`, `INV-02`, `INV-05` |
| `CL-15` | El token del cobro no está admitido conforme a la configuración aplicable. | La operación se trata conforme a las validaciones de origen y registro; no se completa un registro de ingresos incompatible con esa configuración. | Validaciones, `INV-01`, `INV-10` |

### Historial, Saldo Retenido y Ajustes

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-16` | Todavía no se han cobrado ingresos para un token. | El histórico y el saldo retenido atribuibles a esos cobros son cero; la custodia de otros fondos no genera ingresos por sí sola. | `INV-01`, `INV-04`, `INV-05` |
| `CL-17` | Se acumulan varios cobros del mismo token. | El histórico bruto y el saldo retenido aumentan por los importes efectivamente atribuidos, cada uno una sola vez y sujetos a las retiradas o ajustes que correspondan. | `INV-02`, `INV-05` |
| `CL-18` | Se cobran ingresos en tokens con decimales diferentes. | Se mantienen históricos y saldos separados en las unidades de cada token; no se suman ni convierten sin una regla definida. | `INV-02`, `INV-05` |
| `CL-19` | Se retira una parte de los ingresos retenidos. | El saldo retenido disminuye por la retirada efectiva; el histórico bruto de cobros anteriores no se borra por ese hecho. | `INV-05`, `INV-07` |
| `CL-20` | Se retira todo el saldo retenido, si la regla de retirada lo permite. | El saldo retenido afectado queda a cero y el histórico de cobros permanece identificable. La operación debe cumplir también autorización y respaldo. | `INV-05`–`INV-07`, `INV-09` |
| `CL-21` | Se define un reembolso o ajuste de un ingreso ya cobrado. | Su admisibilidad, fuente y tratamiento están pendientes. Si se permite, debe quedar trazado por separado sin confundir el histórico bruto con el saldo retenido ni modificar arbitrariamente partidas ajenas. | `INV-03`, `INV-05` |
| `CL-22` | Se solicita corregir o reembolsar un ingreso que ya fue retirado. | El mecanismo y la fuente para ese ajuste están pendientes. No se presupone que exista saldo retenido suficiente ni se autoriza usar fondos ajenos para completarlo. | `INV-03`–`INV-05` |
| `CL-23` | Se migra el historial o el saldo entre sistemas o custodias, si se permite. | Deben definirse el periodo inicial, la trazabilidad y la conciliación. El mismo cobro o respaldo no puede contarse dos veces; el movimiento no se presume una retirada al destino final. | `INV-04`, `INV-05`, `INV-07` |
| `CL-24` | El saldo retenido o histórico alcanzaría o excedería el máximo representable al registrar un cobro. | Si el resultado exacto cabe y se cumplen las demás condiciones, puede registrarse; si no cabe, la operación afectada se revierte sin truncamiento ni desbordamiento. | `INV-02`, `INV-05`, `INV-10` |
| `CL-25` | El histórico o el saldo registrado no concuerda con los cobros, retiradas y ajustes aplicables. | La comprobación identifica la inconsistencia. No se presupone un mecanismo de reparación ni que cada operación detecte cualquier error previo. | `INV-02`, `INV-05` |

### Custodia y Separación Patrimonial

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-26` | No hay ingresos retenidos, pero el contrato custodia fondos de usuarios o del fondo. | El saldo de ingresos sigue siendo cero; la custodia física de fondos ajenos no autoriza su retirada como ingresos. | `INV-03`, `INV-04`, `INV-06` |
| `CL-27` | Los ingresos comparten contrato con saldos disponibles o garantías. | Las partidas y su respaldo se mantienen separados contablemente. Una misma cantidad no cubre simultáneamente obligaciones incompatibles. | `INV-03`, `INV-04` |
| `CL-28` | Se recibe una transferencia directa fuera de un flujo autorizado. | No se atribuye automáticamente al protocolo ni aumenta sus ingresos retenidos o su histórico. La recuperación del excedente está pendiente de definición. | `INV-01`, `INV-03`, `INV-05` |
| `CL-29` | Una transferencia directa precede a un cobro válido. | El ingreso posterior solo aumenta por el cobro propio efectivamente atribuido; no incorpora automáticamente el excedente previo. | `INV-01`, `INV-02`, `INV-05` |
| `CL-30` | El respaldo disponible para ingresos coincide exactamente con el saldo retenido. | Se cumple la comprobación de respaldo en igualdad si se preservan las obligaciones incompatibles y el ámbito de custodia está correctamente definido. | `INV-03`, `INV-04` |
| `CL-31` | El respaldo disponible para ingresos queda una unidad mínima por debajo del saldo retenido. | Se identifica un estado de respaldo insuficiente. No se presume que las reservas ajenas cubran el déficit ni que exista un mecanismo de reparación. | `INV-03`, `INV-04` |
| `CL-32` | El mismo saldo físico se atribuye como respaldo de ingresos en dos ámbitos o contratos. | No puede contarse dos veces. La conciliación entre ámbitos debe identificar la atribución válida conforme al modelo de custodia definido. | `INV-03`, `INV-04` |
| `CL-33` | Existen ingresos registrados en un contrato y la retirada se solicita desde otro. | No se presume que la custodia del segundo respalde ese saldo. Si se permiten movimientos entre custodias, deben ejecutarse y contabilizarse conforme a la regla definida antes de la retirada final. | `INV-04`, `INV-06`, `INV-07` |
| `CL-34` | Se pretende desautorizar un token con ingresos retenidos u otras reservas contabilizadas pendientes. | Se rechaza la desautorización conforme a la restricción de `EC-01` para `v0.1.0`; los saldos y obligaciones continúan registrados. | Validaciones, `INV-04` |
| `CL-35` | El fondo de liquidez recibe rendimiento que no está atribuido al protocolo. | Ese rendimiento permanece en la partida que corresponda al fondo; no aumenta automáticamente los ingresos retenidos del protocolo. | `INV-01`, `INV-03` |

### Autorización y Retirada de Ingresos

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-36` | Un actor sin autorización intenta retirar ingresos. | Se rechaza sin descuento, transferencia ni registro definitivo. La identidad de los roles autorizados permanece pendiente. | `INV-09`, `INV-10` |
| `CL-37` | Un administrador de parámetros intenta retirar sin tener el permiso específico. | Se rechaza; la facultad de configuración no implica automáticamente autorización para retirar. | `INV-09`, `INV-10` |
| `CL-38` | El actor está autorizado, pero el destino no cumple la regla aplicable. | Se rechaza la retirada sin efectos definitivos. Los destinos permitidos siguen pendientes de definición. | `INV-09`, `INV-10` |
| `CL-39` | Se solicita una retirada de importe cero. | Se rechaza sin descuento ni transferencia. | Validaciones, `INV-10` |
| `CL-40` | Se solicita retirar una unidad mínima del token. | Puede completarse si la regla de importe, la autorización y el respaldo lo permiten; la reducción de ingresos y custodia coincide con la cantidad entregada. | `INV-06`, `INV-07`, `INV-09` |
| `CL-41` | El importe solicitado es una unidad inferior al saldo retenido y está respaldado. | Supera esa comprobación. Si se permite la retirada parcial y se cumplen las demás condiciones, queda una unidad retenida en ese ámbito. | `INV-06`, `INV-07` |
| `CL-42` | El importe solicitado coincide exactamente con el saldo retenido y está respaldado. | Supera esa comprobación. Si se permite retirar la totalidad y se cumplen las demás condiciones, el saldo retenido afectado queda a cero. | `INV-06`, `INV-07` |
| `CL-43` | El importe solicitado supera el saldo retenido en una unidad mínima o más. | Se rechaza la retirada completa; no se usan fondos ajenos o excedentes no atribuidos para completar la diferencia. | `INV-03`, `INV-06`, `INV-10` |
| `CL-44` | El saldo retenido cubre el importe, pero la custodia disponible en el ámbito de ejecución no lo cubre. | No se completa la retirada desde ese ámbito. Los posibles movimientos previos entre custodias deben seguir la regla pendiente y preservar las obligaciones ajenas. | `INV-04`, `INV-06`, `INV-10` |
| `CL-45` | La custodia contiene suficientes tokens en total, pero parte respalda saldos de usuarios, garantías u otras reservas. | Solo puede retirarse una cantidad de ingresos propios que preserve el respaldo de las obligaciones incompatibles; la custodia total por sí sola no basta. | `INV-03`, `INV-04`, `INV-06` |
| `CL-46` | Se retiran ingresos retenidos en el contrato de cuentas. | El saldo real del contrato y los ingresos retenidos disminuyen por la misma cantidad; los saldos disponibles y las reservas de terceros permanecen inalterados, conforme a `EC-01`. | `INV-07`, `INV-08` |
| `CL-47` | El token de retirada no está admitido para la operación. | Se rechaza sin descuento ni transferencia; no se usa el saldo de otro token como sustituto. | Validaciones, `INV-06`, `INV-10` |
| `CL-48` | El actor o destino deja de estar autorizado después de preparar la solicitud y antes de ejecutarla. | Se aplica la autorización vigente al ejecutar. Si ya no se cumplen las condiciones, se rechaza sin efectos definitivos. | `INV-09`, `INV-10` |
| `CL-49` | La transferencia devuelve `false`, revierte o falla después de un descuento provisional. | Se revierte toda la retirada, incluidos el descuento y los registros provisionales. | `INV-07`, `INV-10` |
| `CL-50` | La salida de custodia o la cantidad recibida por el destino difiere del importe descontado. | La retirada no puede completarse incumpliendo la igualdad de `INV-07`; se revierte la ejecución afectada conforme al mecanismo definido. | `INV-07`, `INV-10` |

### Aislamiento, Trazabilidad y Atomicidad

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-51` | Una retirada de ingresos ocurre mientras existen saldos disponibles, garantías, deudas y participaciones. | Esas partidas no cambian por la retirada; se verifica por separado el respaldo de las obligaciones que compartan custodia. | `INV-03`, `INV-04`, `INV-08` |
| `CL-52` | Una comisión de origen reduce el saldo disponible del usuario antes de su registro como ingreso. | La operación de origen puede efectuar ese cargo autorizado y registrar el ingreso correspondiente. El aislamiento de `INV-08` se aplica a la retirada posterior de ingresos. | `INV-02`, `INV-08` |
| `CL-53` | Falla una validación antes de registrar un ingreso o transferir una retirada. | No quedan cambios definitivos de ingresos, custodia o registros atribuibles al intento. | `INV-10` |
| `CL-54` | Falla el registro del ingreso después de un cobro provisional de la operación de origen. | Se revierten los efectos del intento conforme a la atomicidad de esa operación; no queda cobro o ingreso parcial definitivo que la regla de origen exija ejecutar conjuntamente. | `INV-01`, `INV-02`, `INV-10` |
| `CL-55` | Falla una actualización o el registro definitivo después de una transferencia provisional de ingresos. | Se revierte la retirada completa, incluida la transferencia, el descuento y los registros del intento. | `INV-07`, `INV-10` |
| `CL-56` | Una llamada anidada o repetida intenta retirar dos veces el mismo saldo retenido. | Cada retirada completada debe contar con autorización, saldo y respaldo disponibles en su momento. No se gasta dos veces la misma cantidad; si no puede garantizarse, se revierte el intento afectado. | `INV-04`, `INV-06`, `INV-09`, `INV-10` |
| `CL-57` | Una secuencia combina cobros de varias cadenas, retiradas, transferencias directas e intentos fallidos. | Tras cada transición se comprueban las propiedades aplicables por token y custodia. Cada intento fallido conserva el estado inmediatamente anterior sin borrar operaciones previas válidas. | `INV-01`–`INV-10` |

### Criterio de Cobertura

Aplicar los casos pertinentes a cada token, cadena de origen y ámbito de custodia autorizados; con saldos cero y positivos, una y varias operaciones, y límites de representación. Comprobar por separado el historial bruto, el saldo retenido, el respaldo y los efectos reales de cada retirada. Comparar los estados afectados inmediatamente antes y después de cada intento fallido.

Esta matriz identifica clases de límites y fallos para `EC-08`; no demuestra que se hayan enumerado todas las secuencias posibles ni sustituye las pruebas o una verificación formal. Los resultados que dependen de permisos, custodia, ajustes o fuentes pendientes deben concretarse antes de convertirlos en pruebas ejecutables.
