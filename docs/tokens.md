
# Tokens

Veyra admite dos ERC-20 identificados por sus direcciones locales. Cada transferencia mueve exactamente las unidades solicitadas. El emisor de pruebas crea los tokens en las carteras del escenario. La emisión no modifica las partidas contables de Veyra.

| Activo | Decimales | Operaciones |
| --- | ---: | --- |
| MockUSD | 6 | Depósitos, retiradas, pagos, suscripciones, caja del fondo, préstamos, devoluciones y repago del liquidador. |
| MockETH | 18 | Depósitos, retiradas y garantía. Su bloqueo, liberación o adjudicación mueve saldos internos del mismo token. |

La comisión de una retirada de usuario se cobra en el propio token. La retirada de ingresos de tesorería entrega el importe retenido íntegro. Un MockETH entero contiene 10¹⁸ unidades y un MockUSD entero contiene 10⁶. Un precio de 2 000 MockUSD por MockETH se registra como el entero 2 000 000 000.

Las dos direcciones son distintas, válidas y fijas durante la instancia. El administrador puede habilitar o deshabilitar únicamente esas direcciones. La baja exige que el disponible, el bloqueo, la caja y los ingresos del token sean cero y que ningún préstamo activo lo use como deuda o garantía. Un excedente directo, por sí solo, no es una obligación con un titular. La baja conserva el historial y cualquier excedente. Mientras un activo esté deshabilitado se rechazan las operaciones que lo necesitan.
