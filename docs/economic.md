
# Cadenas económicas

La v0.1.0 se ejecutará en Anvil con ocho cadenas económicas, una custodia común y un mercado MockUSD/MockETH. La misma dirección de custodia recibe las autorizaciones ERC-20, mantiene las reservas y ejecuta las salidas. Las fichas asignan responsabilidades funcionales. Una operación que afecta a varias cadenas actualiza todas sus partidas en una transacción.

**Configuración de referencia en Anvil.** Las tarifas y los límites siguientes son elecciones de simulación. Se fijan al desplegar cada instancia. El administrador puede actualizar el precio simulado durante la ejecución. Un punto básico (pb) equivale a 1/10 000.

| Parámetro | Básico | De pago |
| --- | ---: | ---: |
| Cuota por periodo de 30 días | 0 | 10 MockUSD |
| Comisión sobre el bruto de una retirada | 10 pb | 5 pb |
| Comisión sobre el bruto de un pago | 20 pb | 5 pb |
| Comisión sobre el principal al abrir | 100 pb | 50 pb |
| Interés simple anual | 800 pb | 500 pb |

Cada comisión se redondea hacia abajo en unidades mínimas del activo. El plan básico es el predeterminado. El de pago rige desde el inicio incluido hasta la caducidad excluida. La tasa y la comisión de apertura del préstamo se fijan al abrirlo. El año de interés tiene 365 días y el tiempo se mide en segundos.

| Parámetro de mercado | Valor de referencia |
| --- | --- |
| Máximo al abrir | Deuda inicial ≤ 60 % del valor de la garantía |
| Liquidación | Deuda actual > 75 % del valor de la garantía |
| Prima del liquidador | 5 % sobre el repago, limitada a la garantía de la posición |
| Precio inicial y antigüedad máxima | 2 000 MockUSD por MockETH, válido hasta 3 600 segundos inclusive |
| Unidad del precio | Unidades mínimas de MockUSD por 1 MockETH entero |
| Mínimo de depósito por token | 0 en la comparación estricta de EC-01. Se acepta desde una unidad mínima. |

**Conciliación por token.** El saldo ERC-20 de la custodia es la suma de los disponibles de usuarios, las garantías bloqueadas, la caja libre del fondo, los ingresos retenidos y cualquier excedente directo sin atribuir. La caja solo existe en MockUSD y la garantía solo en MockETH. Deudas y participaciones representan derechos sobre activos, no tokens adicionales en custodia. La pérdida de un préstamo afecta al patrimonio del fondo. El dinero disponible de otras cuentas sigue respaldado.

Los depósitos y las retiradas de usuario o tesorería son las operaciones del protocolo que mueven tokens entre una cartera y la custodia. Los envíos directos también cambian el balance ERC-20, pero quedan como excedentes sin atribuir. Los pagos, las suscripciones, el fondo y los préstamos se liquidan con movimientos internos.

**Movimientos que debe implementar cada operación.** La tabla recoge las partidas que cambian al mismo instante de bloque. El total disponible de cada token cambia por la suma de los movimientos en las cuentas individuales. Una consulta de saldo o de deuda carece de efectos contables.

| Operación | Cargo y abono | Comprobación al confirmar |
| --- | --- | --- |
| Depósito | De la cartera del titular al disponible del mismo titular y token. | La entrada física y el abono igualan el importe solicitado. |
| Retirada de usuario | Del disponible bruto a la cartera del titular por el neto y a ingresos por la comisión. | La custodia disminuye por el neto. |
| Pago individual | Del disponible bruto del emisor al disponible neto del destinatario y a ingresos por la comisión. | La custodia se conserva y el total disponible disminuye por la comisión. |
| Contratación o renovación | Del disponible de MockUSD del titular a ingresos por la cuota. | Se registra exactamente un periodo por cobro. |
| Aportación o reembolso | Entre el disponible de MockUSD del proveedor y la caja del fondo. | Las participaciones del proveedor y el suministro varían en la misma cantidad. |
| Apertura | La caja cede el bruto, que se reparte entre disponible del prestatario e ingresos. Su MockETH pasa de disponible a bloqueado. | Deuda inicial igual al bruto e interés inicial cero. El patrimonio del fondo se conserva. |
| Devolución | Del disponible de MockUSD del prestatario a caja por el importe aplicado. | Baja primero el interés y después el principal. El pago total acredita toda la garantía y cierra. |
| Liquidación | Del disponible de MockUSD del liquidador a caja por el repago. El bloqueo de MockETH se reparte entre liquidador y prestatario. | Baja toda la deuda de esa posición. El patrimonio pierde exactamente la deuda impagada. |
| Retirada de tesorería | De ingresos retenidos a la cartera fija de tesorería por el importe íntegro del token. | El saldo físico y el retenido disminuyen en igual importe. |

**Consultas para integrar y verificar el MVP.** Deben poder leerse las direcciones de los dos activos y si cada uno está habilitado, los parámetros, el precio y su fecha, los saldos individuales y totales por token, las garantías bloqueadas, el plan efectivo y su caducidad. El fondo expone caja, patrimonio al tiempo del bloque, suministro y participaciones del titular. Un préstamo se identifica por un ID propio y permite consultar titular, estado, principal, interés exigible, deuda total, condiciones de apertura y garantía. La tesorería expone los ingresos retenidos por token. Los importes transferidos y los cambios de estado se reconstruyen a partir de los eventos de las operaciones confirmadas.

**Convención numérica.** Las cantidades de tokens, las participaciones, los precios y los saldos finales se expresan como enteros sin signo de hasta 256 bits. En las fórmulas, los productos, comparaciones y divisiones representan aritmética exacta hasta el redondeo explícito. Un producto temporal ancho puede dar un resultado final representable. La entrada fuera de dominio o el resultado económico final fuera de rango revierte la operación. Las variaciones con signo de las fichas expresan diferencias entre estados.

## `EC-01` Depósitos y Retiradas

[Ficha de EC-01](./chains/ec-01-depositos-y-retiradas.md) · Entrada de tokens, saldo disponible y retirada de fondos.

## `EC-02` Pagos y Transferencias

[Ficha de EC-02](./chains/ec-02-pagos-y-transferencias.md) · Pagos individuales en MockUSD y comisiones.

## `EC-03` Planes y Suscripciones

[Ficha de EC-03](./chains/ec-03-planes-y-suscripciones.md) · Vigencia, contratación, caducidad y renovación manual.

## `EC-04` Aportación y Retirada de Liquidez

[Ficha de EC-04](./chains/ec-04-aportacion-y-retirada.md) · Capital para préstamos, participaciones, rendimiento y reembolso.

## `EC-05` Préstamos y Garantías

[Ficha de EC-05](./chains/ec-05-prestamos-y-garantias.md) · Apertura, desembolso y bloqueo de garantías.

## `EC-06` Intereses y Devolución

[Ficha de EC-06](./chains/ec-06-intereses-y-devolución.md) · Interés simple y devoluciones parciales o completas.

## `EC-07` Liquidaciones y Pérdidas

[Ficha de EC-07](./chains/ec-07-liquidaciones-y-perdidas.md) · Liquidación de posiciones y asignación de pérdidas.

## `EC-08` Ingresos del Protocolo

[Ficha de EC-08](./chains/ec-08-ingresos-del-protocolo.md) · Registro y retirada de comisiones y cuotas cobradas.
