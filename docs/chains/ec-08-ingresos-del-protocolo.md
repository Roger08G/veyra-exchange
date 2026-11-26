# `EC-08` Ingresos del Protocolo

La cadena económica `EC-08` gestiona la contabilización y retirada de los ingresos propios ya cobrados por el protocolo Veyra.

## Objetivo

EC-08 registra y permite retirar los ingresos que pertenecen al protocolo y ya se han cobrado, preservando las demás partidas de la custodia.

Los orígenes habilitados son retirada de usuario, pago, suscripción y apertura de préstamo.

> Tokens permitidos: [tokens](../tokens.md)

## Actores

En esta cadena intervienen los siguientes actores:

- Las **cadenas de origen** generan operaciones que pueden cobrar importes para el protocolo y deben identificar su importe, token y procedencia.
- La **contabilidad de ingresos de Veyra** registra los importes que correspondan al protocolo y mantiene la información necesaria para conocer los ingresos retenidos y sus retiradas.
- La **tesorería** es una dirección distinta de cero fijada al desplegar. Solo ella puede solicitar una retirada y recibirla.
- La **custodia común** mantiene los activos físicos y separa las partidas contables por token.
- El **administrador** configura los parámetros autorizados del protocolo. Su facultad de configuración no le permite mover fondos de usuarios o del fondo de liquidez ni modificar arbitrariamente sus saldos.
- El **fondo de liquidez `EC-04`** mantiene su patrimonio separado de los ingresos del protocolo; sus rendimientos no se convierten automáticamente en ingresos del protocolo.

## Variables y Estado Contable

El saldo retenido por token agrupa los cobros atribuidos al protocolo que la tesorería todavía no ha retirado.

La información de cada ingreso debe permitir identificar su cadena y operación de origen, el token, el importe efectivamente cobrado y su atribución al protocolo. Cada retirada debe poder relacionarse con el token, el importe, la autorización y el destino correspondientes.

El evento económico de cada retirada de usuario, pago, suscripción o apertura identifica el token y el importe que se atribuye a ingresos. Ese campo es el registro canónico del cobro. El evento de retirada de tesorería identifica la salida. El índice y el hash del recibo permiten distinguir dos operaciones iguales sin duplicar su importe al reconstruir el historial.

Solo los importes cobrados y atribuidos por las cadenas de origen aumentan el saldo retenido. En el MVP no hay ajustes manuales.

El cobro efectivo puede ser un movimiento contable interno de fondos ya custodiados, cuando la cadena de origen lo permita; no exige por sí mismo una transferencia externa de tokens. En todos los casos, la atribución debe quedar respaldada y no contar dos veces la misma cantidad.

La retirada de ingresos reduce el saldo retenido del token y la custodia correspondiente por el importe efectivamente retirado, sin consumir fondos de usuarios, garantías, patrimonio del fondo u otras reservas ajenas. La disponibilidad física de tokens en un contrato no convierte automáticamente esos tokens en ingresos del protocolo.

## Flujo Económico

### Origen y Registro de Ingresos

Se reconocen comisiones de retirada en el token retirado, comisiones de pago y apertura en MockUSD y cuotas en MockUSD. El interés pertenece al fondo, y la prima de liquidación se entrega al liquidador.

Cuando una operación de origen se completa y cobra un importe para el protocolo, Veyra registra una sola vez el ingreso correspondiente para el token utilizado. El registro debe mantener su vínculo con el cobro y con la operación que lo originó.

Si la operación de origen falla o se revierte, no queda un ingreso definitivo por ese intento. Las tasas, los redondeos y las condiciones de cada cobro se rigen por su cadena de origen y, cuando corresponda, por `EC-03`.

### Custodia y Disponibilidad de Ingresos

La custodia debe respaldar simultáneamente los disponibles, las garantías, la caja del fondo y los ingresos. Los excedentes directos conservan su clasificación separada.

Para los ingresos retenidos en el contrato de cuentas, la retirada debe coordinarse con `EC-01`: el saldo real del contrato y los ingresos retenidos disminuyen por la misma cantidad, sin modificar los saldos disponibles de los usuarios ni las reservas de terceros.

Hay un saldo retenido por token en la custodia común. La v0.1.0 excluye traslados y migraciones entre custodias.

### Retirada de Ingresos

La tesorería solicita un importe positivo de un token habilitado. La custodia comprueba el remitente, el saldo retenido, el respaldo y la dirección de destino fijada al desplegar.

La custodia descuenta exactamente el importe solicitado del retenido y lo entrega íntegro a tesorería. Esta salida no genera una nueva comisión. La deuda, las participaciones, las garantías y los disponibles se conservan.

La tesorería puede retirar cualquier cantidad positiva hasta el saldo retenido y respaldado, inclusive. El destino coincide con la dirección de tesorería fijada al desplegar.

### Transferencias Directas y Ajustes

Las transferencias directas quedan como excedentes sin atribuir. Ninguna retirada de tesorería puede consumir ese excedente.

La v0.1.0 excluye reembolsos, correcciones manuales y migraciones de ingresos.

## Validaciones y Restricciones

### Validaciones de Registro de Ingresos

- El ingreso debe proceder de una operación autorizada de una cadena de origen e identificar el token, el importe y la operación que lo generó.
- El importe debe haber sido efectivamente cobrado y atribuido al protocolo conforme a las reglas de origen. Un cálculo provisional o una cantidad pendiente de cobro no es ingreso retirable.
- El mismo cobro no puede registrarse más de una vez. La contabilidad debe distinguir un movimiento interno correctamente atribuido de una transferencia directa no registrada.
- El token debe estar admitido conforme a la configuración aplicable y el importe debe expresarse en sus propias unidades mínimas. No se mezclan ni convierten saldos de tokens distintos sin una regla definida.
- Si falla la operación de origen o una actualización necesaria del registro, sus efectos deben revertirse conforme a la atomicidad de esa operación; no permanece un ingreso definitivo parcial por el intento fallido.
- Los importes y saldos resultantes deben poder representarse sin desbordamientos, subdesbordamientos ni truncamientos silenciosos.

### Validaciones de Retirada de Ingresos

- El solicitante y el destino deben coincidir con la tesorería de la instancia.
- El token debe estar admitido para la operación y el importe solicitado debe ser mayor que cero.
- El saldo de ingresos retenidos del token debe cubrir la retirada y debe existir custodia suficiente para ejecutarla, preservando el respaldo de saldos, garantías, patrimonio del fondo y otras reservas ajenas.
- La retirada solo puede utilizar ingresos propios ya cobrados y retenidos; no puede completarse con fondos de usuarios, garantías, patrimonio del fondo o excedentes no atribuidos.
- Cada retirada confirmada registra token, importe y destino, y debe coincidir con la salida efectiva de la custodia.
- Si falla una validación, la transferencia o una actualización necesaria, la retirada debe revertirse por completo, sin descuento, transferencia ni registro definitivo parcial de ese intento.

### Restricciones del MVP

La tesorería es fija durante la vida de la instancia. Los retiros de MockUSD y MockETH se comprueban por separado. El origen registra cada cobro confirmado una vez e identifica operación, cuenta, token e importe. Cada retirada identifica su token, importe y destino.

Mientras existan saldos disponibles, garantías, ingresos retenidos u otras reservas contabilizadas pendientes para un token, `EC-01` establece que no puede desautorizarse en `v0.1.0`. Cualquier cambio de configuración debe respetar esa restricción.

El saldo retenido parte de cero y cambia exclusivamente por cobro o retirada.

## Invariantes y Propiedades

Cada propiedad se aplica por token a los efectos de la operación. Las variaciones corresponden al valor posterior menos el anterior.

Para cada token se distinguen el histórico bruto cobrado, el retenido tras las salidas y el importe respaldado disponible para retirar de la custodia común.

### Invariante `INV-01` - Integridad de Ingresos

En `EC-08`, cada ingreso registrado debe corresponder a un importe efectivamente cobrado y atribuido al protocolo por una operación de origen autorizada. Una comisión calculada o una cuota pendiente no cumplen esa condición por sí solas.

Cada registro de ingresos positivos debe corresponder a exactamente un cobro de origen y cada cobro positivo debe aparecer exactamente una vez en el histórico.

```math
\begin{aligned}
&\forall i\in I\quad \exists!\, c\in C:\quad \operatorname{vinculado}(i,c),\\
&\forall c\in C\quad \exists!\, i\in I:\quad \operatorname{vinculado}(i,c),\\
&\operatorname{vinculado}(i,c)\implies t_i=t_c\ \land\ A_i=A_{\mathrm{protocolo}}(c).
\end{aligned}
```

**Leyenda:**

- $I$: registros definitivos de ingresos positivos del protocolo.
- $C$: cobros positivos atribuidos al protocolo por EC-01, EC-02, EC-03 y EC-05.
- $\operatorname{vinculado}(i,c)$: indica que el registro $i$ identifica el cobro de origen $c$.
- $t_i$ y $t_c$: token registrado en el ingreso y token del cobro correspondiente.
- $A_i$: importe del ingreso registrado.
- $A_{\text{protocolo}}(c)$: parte del cobro atribuida efectivamente al protocolo conforme a la regla de origen.

Un movimiento interno de fondos custodiados puede hacer efectivo el cobro. El histórico incluye las cuatro fuentes enumeradas en esta ficha.

Un evento con comisión redondeada a cero registra la operación de origen con ese valor. El histórico de cobros positivos y el saldo retenido siguen iguales.

### Invariante `INV-02` - Conservación de Comisiones

Cada comisión o cuota de un origen admitido se registra exactamente una vez por el importe cobrado y el token correcto.

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

Cada unidad física corresponde a una sola partida de la conciliación por token recogida en EC-01.

### Invariante `INV-04` - Respaldo de Ingresos

En `EC-08`, los ingresos retenidos disponibles para retirada deben estar respaldados por tokens efectivamente custodiados y no comprometidos en obligaciones incompatibles.

Para cada token de la custodia común, el saldo retenido se encuentra respaldado tras separar las partidas ajenas.

```math
\forall t\in T,\quad \forall h\in H:\quad
I_{\text{retenido}}(t,h)\leq B_{\text{respaldo}}(t,h)
```

**Leyenda:**

- $T$: conjunto de tokens admitidos.
- $H$: conjunto formado por la custodia común de la instancia.
- $I_{\text{retenido}}(t,h)$: ingresos retenidos del token $t$ atribuidos al ámbito $h$.
- $B_{\text{respaldo}}(t,h)$: cantidad del token efectivamente custodiada en ese ámbito y disponible para respaldar esos ingresos, excluyendo las obligaciones incompatibles.

Solo existe una custodia económica. Los contratos que consulten el saldo común no añaden respaldo por el hecho de registrarlo.

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

La secuencia de eventos reconstruye los cobros y retiradas por token desde el despliegue.

Desde el despliegue, el saldo retenido de cada token coincide con lo cobrado menos lo retirado

```math
\forall t\in T:\quad
I_{\text{retenidoTotal}}(t)=H_{\text{cobrado}}(t)-H_{\text{retirado}}(t)
```

- $I_{\text{retenidoTotal}}(t)$: ingresos retenidos del token $t$ agregados sin duplicaciones entre ámbitos.
- $H_{\text{retirado}}(t)$: suma de las retiradas definitivas al destino final del token $t$ durante el mismo periodo.

Para un intervalo que empieza después del despliegue se añade el saldo inicial del intervalo.

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

La retirada sale de la custodia común y debe preservar el respaldo completo por token.

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

La custodia debe perder exactamente el importe descontado y la tesorería debe recibirlo íntegro. Una diferencia revierte la retirada.

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
- $\operatorname{autorizado}$: el solicitante coincide con la tesorería fija.
- $\operatorname{destinoPermitido}$: el destino coincide con esa misma dirección.

La dirección de tesorería se fija al desplegar. El administrador del precio carece de este permiso por el hecho de administrar el mercado.

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

Un fallo de retirada conserva el saldo retenido inmediatamente anterior.

## Casos Límite y Escenarios de Fallo

Los siguientes casos sirven de referencia para futuras pruebas de `EC-08`. Las referencias `INV-01` a `INV-10` corresponden a esta cadena. En un registro de ingreso o una retirada fallidos se revierten los efectos atribuibles al intento; la operación de origen conserva la atomicidad que le corresponda.

Los importes se expresan en unidades mínimas del token correspondiente.

### Origen y Registro de Ingresos

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-01` | Una comisión de retirada de `EC-01` se cobra correctamente y corresponde al protocolo. | Se registra una sola vez por el importe efectivamente cobrado y el token de la operación, vinculada a su origen. | `INV-01`, `INV-02`, `INV-05` |
| `CL-02` | Una comisión de pago de `EC-02` se cobra mediante una atribución interna de fondos ya custodiados. | Se reconoce una sola vez el importe efectivamente atribuido al protocolo; no se exige una transferencia externa por el mero hecho de registrar el ingreso. | `INV-01`, `INV-02`, `INV-03` |
| `CL-03` | Se cobra una cuota de suscripción de `EC-03`. | La cuota atribuida al protocolo se registra por su importe efectivo y token, vinculada a la operación de origen y al periodo que corresponda. | `INV-01`, `INV-02`, `INV-05` |
| `CL-04` | Una comisión de apertura de `EC-05` se calcula pero aún no se ha cobrado. | No aumenta por ese cálculo el ingreso retenido ni el histórico cobrado. Su tratamiento al cobrarse se rige por la regla de origen definida. | `INV-01`, `INV-02`, `INV-05` |
| `CL-05` | Se propone registrar un interés, una comisión del fondo o una prima de liquidación como ingreso. | EC-04, EC-06 y EC-07 no generan ingresos de tesorería en el MVP. Se rechaza la atribución. | `INV-01`–`INV-03` |
| `CL-06` | Una cantidad se ha calculado o devengado, pero está pendiente de cobro. | No se registra como ingreso cobrado ni como saldo retirable por el mero devengo. | `INV-01`, `INV-04`, `INV-05` |
| `CL-07` | La comisión o cuota aplicable es cero y esa configuración se permite. | Un cargo redondeado a cero se refleja como tal en la operación. El histórico y el saldo retenido no aumentan. | `INV-01`, `INV-02`, `INV-05` |
| `CL-08` | Se cobra una unidad mínima del token. | El ingreso retenido y el histórico aumentan exactamente por esa unidad atribuida al protocolo, sin pérdida de precisión. | `INV-02`, `INV-05` |
| `CL-09` | Una operación reparte un cobro entre el protocolo y otro destinatario. | Solo la parte efectivamente atribuida al protocolo incrementa sus ingresos; la parte ajena se registra en su propia partida sin duplicarla. | `INV-01`–`INV-03` |
| `CL-10` | La operación de origen cobra un importe, pero falla o se revierte antes de completarse. | No permanece un ingreso definitivo de ese intento. Se respetan la atomicidad y los estados previos de la operación de origen. | `INV-01`, `INV-02`, `INV-10` |
| `CL-11` | Se intenta registrar como ingreso un importe sin cobro válido o sin atribución al protocolo. | Se rechaza el registro; un importe previsto o una reserva ajena no se convierte en ingreso por una anotación aislada. | `INV-01`, `INV-03`, `INV-10` |
| `CL-12` | El token o importe del registro no coincide con el cobro de origen atribuido al protocolo. | No se completa un registro que atribuya un token o importe distinto; el intento fallido no deja efectos definitivos. | `INV-01`, `INV-02`, `INV-10` |
| `CL-13` | Se intenta registrar dos veces el mismo cobro. | La identidad del cobro de origen se vincula a un único registro de ingreso. Un segundo registro incumple la invariante. | `INV-01`, `INV-02`, `INV-05` |
| `CL-14` | Dos operaciones independientes cobran el mismo importe en el mismo token. | Cada cobro efectivo y atribuible se registra por separado con su propia procedencia; la igualdad de importes no los convierte automáticamente en el mismo cobro. | `INV-01`, `INV-02`, `INV-05` |
| `CL-15` | El token del cobro no está admitido conforme a la configuración aplicable. | La operación se trata conforme a las validaciones de origen y registro; no se completa un registro de ingresos incompatible con esa configuración. | Validaciones, `INV-01`, `INV-10` |

### Historial, Saldo Retenido y Ajustes

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-16` | Todavía no se han cobrado ingresos para un token. | El histórico y el saldo retenido atribuibles a esos cobros son cero; la custodia de otros fondos no genera ingresos por sí sola. | `INV-01`, `INV-04`, `INV-05` |
| `CL-17` | Se acumulan varios cobros del mismo token. | El histórico bruto y el saldo retenido aumentan por los importes efectivamente atribuidos, cada uno una sola vez y sujetos a las retiradas o ajustes que correspondan. | `INV-02`, `INV-05` |
| `CL-18` | Se cobran ingresos en tokens con decimales diferentes. | Se mantienen históricos y saldos separados en las unidades de cada token; no se suman ni convierten sin una regla definida. | `INV-02`, `INV-05` |
| `CL-19` | Se retira una parte de los ingresos retenidos. | El saldo retenido disminuye por la retirada efectiva; el histórico bruto de cobros anteriores no se borra por ese hecho. | `INV-05`, `INV-07` |
| `CL-20` | Se retira todo el saldo retenido. | El saldo retenido afectado queda a cero y el histórico de cobros permanece identificable. La operación debe cumplir también autorización y respaldo. | `INV-05`–`INV-07`, `INV-09` |
| `CL-21` | Se solicita reembolsar o ajustar un ingreso ya cobrado. | La interfaz de v0.1.0 excluye ajustes y reembolsos. El saldo no cambia. | `INV-03`, `INV-05` |
| `CL-22` | Se solicita corregir o reembolsar un ingreso que ya fue retirado. | Se rechaza. No existe un cargo compensatorio sobre fondos del fondo o de los usuarios. | `INV-03`–`INV-05` |
| `CL-23` | Se intenta migrar ingresos a otra custodia. | El MVP mantiene una sola custodia. No existe una operación de migración. | `INV-04`, `INV-05`, `INV-07` |
| `CL-24` | El saldo retenido o histórico alcanzaría o excedería el máximo representable al registrar un cobro. | Si el resultado exacto cabe y se cumplen las demás condiciones, puede registrarse; si no cabe, la operación afectada se revierte sin truncamiento ni desbordamiento. | `INV-02`, `INV-05`, `INV-10` |
| `CL-25` | El histórico o el saldo registrado no concuerda con los cobros, retiradas y ajustes aplicables. | La comprobación identifica la inconsistencia. No se presupone un mecanismo de reparación ni que cada operación detecte cualquier error previo. | `INV-02`, `INV-05` |

### Custodia y Separación Patrimonial

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-26` | No hay ingresos retenidos, pero el contrato custodia fondos de usuarios o del fondo. | El saldo de ingresos sigue siendo cero; la custodia física de fondos ajenos no autoriza su retirada como ingresos. | `INV-03`, `INV-04`, `INV-06` |
| `CL-27` | Los ingresos comparten contrato con saldos disponibles o garantías. | Las partidas y su respaldo se mantienen separados contablemente. Una misma cantidad no cubre simultáneamente obligaciones incompatibles. | `INV-03`, `INV-04` |
| `CL-28` | Se recibe una transferencia directa fuera de un flujo autorizado. | La transferencia queda como excedente sin atribuir. No se puede retirar como ingreso. | `INV-01`, `INV-03`, `INV-05` |
| `CL-29` | Una transferencia directa precede a un cobro válido. | El ingreso posterior solo aumenta por el cobro propio efectivamente atribuido; no incorpora automáticamente el excedente previo. | `INV-01`, `INV-02`, `INV-05` |
| `CL-30` | El respaldo disponible para ingresos coincide exactamente con el saldo retenido. | Se cumple la comprobación de respaldo en igualdad si se preservan las obligaciones incompatibles y el ámbito de custodia está correctamente definido. | `INV-03`, `INV-04` |
| `CL-31` | El respaldo disponible para ingresos queda una unidad mínima por debajo del saldo retenido. | Se identifica un estado de respaldo insuficiente. No se presume que las reservas ajenas cubran el déficit ni que exista un mecanismo de reparación. | `INV-03`, `INV-04` |
| `CL-32` | El mismo saldo físico se atribuye como respaldo de ingresos en dos ámbitos o contratos. | Solo vale el balance de la custodia común. Duplicarlo al conciliar incumple el respaldo por token. | `INV-03`, `INV-04` |
| `CL-33` | Existen ingresos registrados en un contrato y la retirada se solicita desde otro. | Se rechaza. Solo la custodia común puede transferir sus ingresos retenidos. | `INV-04`, `INV-06`, `INV-07` |
| `CL-34` | Se pretende desautorizar un token con ingresos retenidos u otras reservas contabilizadas pendientes. | Se rechaza la desautorización conforme a la restricción de `EC-01` para `v0.1.0`; los saldos y obligaciones continúan registrados. | Validaciones, `INV-04` |
| `CL-35` | El fondo de liquidez recibe rendimiento que no está atribuido al protocolo. | Ese rendimiento permanece en la partida que corresponda al fondo; no aumenta automáticamente los ingresos retenidos del protocolo. | `INV-01`, `INV-03` |

### Autorización y Retirada de Ingresos

| ID | Caso | Resultado esperado | Referencia |
|---|---|---|---|
| `CL-36` | Un actor sin autorización intenta retirar ingresos. | Solo la tesorería puede efectuar la retirada. Se rechaza la solicitud de cualquier otro actor. | `INV-09`, `INV-10` |
| `CL-37` | Un administrador de parámetros intenta retirar sin tener el permiso específico. | Se rechaza; la facultad de configuración no implica automáticamente autorización para retirar. | `INV-09`, `INV-10` |
| `CL-38` | El actor está autorizado, pero el destino no cumple la regla aplicable. | Se rechaza. El destino debe ser la dirección fija de tesorería. | `INV-09`, `INV-10` |
| `CL-39` | Se solicita una retirada de importe cero. | Se rechaza sin descuento ni transferencia. | Validaciones, `INV-10` |
| `CL-40` | Se solicita retirar una unidad mínima del token. | Puede completarse si la regla de importe, la autorización y el respaldo lo permiten; la reducción de ingresos y custodia coincide con la cantidad entregada. | `INV-06`, `INV-07`, `INV-09` |
| `CL-41` | El importe solicitado es una unidad inferior al saldo retenido y está respaldado. | Puede completarse. Queda una unidad retenida si cumple las demás condiciones. | `INV-06`, `INV-07` |
| `CL-42` | El importe solicitado coincide exactamente con el saldo retenido y está respaldado. | Puede retirarse todo el saldo respaldado. El retenido queda en cero. | `INV-06`, `INV-07` |
| `CL-43` | El importe solicitado supera el saldo retenido en una unidad mínima o más. | Se rechaza la retirada completa; no se usan fondos ajenos o excedentes no atribuidos para completar la diferencia. | `INV-03`, `INV-06`, `INV-10` |
| `CL-44` | El saldo retenido cubre el importe, pero la custodia disponible en el ámbito de ejecución no lo cubre. | Se rechaza la retirada sin mover fondos. La instancia tiene una sola custodia. | `INV-04`, `INV-06`, `INV-10` |
| `CL-45` | La custodia contiene suficientes tokens en total, pero parte respalda saldos de usuarios, garantías u otras reservas. | Solo puede retirarse una cantidad de ingresos propios que preserve el respaldo de las obligaciones incompatibles; la custodia total por sí sola no basta. | `INV-03`, `INV-04`, `INV-06` |
| `CL-46` | Se retiran ingresos retenidos en el contrato de cuentas. | El saldo real del contrato y los ingresos retenidos disminuyen por la misma cantidad; los saldos disponibles y las reservas de terceros permanecen inalterados, conforme a `EC-01`. | `INV-07`, `INV-08` |
| `CL-47` | El token de retirada no está admitido para la operación. | Se rechaza sin descuento ni transferencia; no se usa el saldo de otro token como sustituto. | Validaciones, `INV-06`, `INV-10` |
| `CL-48` | Se intenta cambiar la tesorería después de preparar una retirada. | La dirección es fija desde el despliegue. El intento no concede permisos. | `INV-09`, `INV-10` |
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

Esta matriz sirve para diseñar las pruebas de ingresos y retirada de tesorería.
