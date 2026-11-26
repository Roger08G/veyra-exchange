# Seguridad

**Límite de confianza.** El MVP usa Anvil, ERC-20 de prueba con transferencias exactas y un precio local que publica el administrador. Este rol controla la valoración que puede habilitar una apertura o liquidación. Las tarifas y los umbrales quedan fijados al desplegar.

**Permisos.** Cada cuenta opera sobre sus saldos, participaciones y préstamos. Una tercera cuenta puede liquidar una posición elegible usando su propio MockUSD. La dirección de tesorería fijada al desplegar retira exclusivamente sus ingresos hacia esa misma dirección. La emisión de tokens de prueba para el escenario se realiza en carteras externas. Solo un depósito autorizado acredita esos tokens en Veyra.

**Respaldo y ejecución.** En las entradas y salidas ERC-20 comprobar el éxito de la llamada y el importe efectivo en la custodia y en el destinatario. Los movimientos internos solo reclasifican fondos respaldados. Una interacción externa durante una operación no debe poder consumir el mismo saldo desde otra entrada del protocolo. Un fallo revierte también las actualizaciones y eventos provisionales. Los productos y cocientes deben producir el resultado entero especificado, incluido cuando el producto intermedio requiera más precisión que el resultado final. [Reglas de custodia](./economic.md)

**Valoración del fondo.** El patrimonio incluye los préstamos por su deuda nominal actualizada hasta el cierre. Antes de una liquidación puede superar el importe recuperable. La pérdida afecta a las participaciones en circulación al ejecutarse el cierre. En las pruebas se registra el orden de los reembolsos y las liquidaciones.

**Precio y tiempo.** Aperturas y liquidaciones requieren precio positivo con fecha de publicación válida. Una devolución ordinaria depende de la deuda y del tiempo del bloque, por lo que puede reducir o cerrar la deuda aunque el precio haya caducado. Los cambios de precio se registran y se vuelven a evaluar al ejecutar la operación.

**Trazabilidad.** En cada ejecución, identificar los eventos por cadena, dirección del contrato, hash de transacción e índice de log del recibo. Para conciliar ingresos se cuenta una sola vez el cobro de origen. Un evento ERC-20 de transferencia y el evento económico que lo explica pueden describir el mismo movimiento. El escenario de Anvil contrasta los registros con los balances y el estado final.

## Permisos por actor

| Actor | Facultad y alcance | Comprobación de aceptación |
| --- | --- | --- |
| Titular de cuenta | Autoriza el depósito desde su cartera, retira hacia esa misma cartera, paga desde su disponible y contrata o renueva su plan. | Aunque el titular haya dado autorización ERC-20 a la custodia, otro usuario no puede cargar su cartera ni gastar su disponible. |
| Proveedor de liquidez | Aporta su propio MockUSD y reembolsa sus propias participaciones contra la caja disponible. | Un segundo proveedor no puede gastar participaciones del primero. Un reembolso sin caja conserva el suministro y ambos saldos. |
| Prestatario | Abre desde su cuenta y devuelve su propio préstamo activo identificado por ID. | Probar un remitente distinto y un ID ya cerrado después de una nueva apertura. La deuda y la garantía de la posición nueva se conservan. |
| Liquidador | Cualquier tercero distinto del prestatario puede cerrar una posición elegible pagando con su propio disponible. | Comprobar por separado identidad, saldo, umbral estricto y vigencia del precio. El usuario no puede elegir qué cuenta soporta el repago. |
| Administrador | Publica el precio simulado y cambia la habilitación de los dos activos fijados al desplegar. | Rechazar un precio cero, un tercer activo y la baja de un token con obligaciones. También debe fallar una retirada de ingresos solicitada por el administrador. |
| Tesorería | Retira ingresos ya cobrados hasta el retenido respaldado de cada token. El destino está fijado al desplegar. | Revisar el remitente, el destino efectivo, el importe íntegro y la conservación de las reservas de terceros. Un envío directo a la custodia no incrementa el retenido. |
| Emisor de mocks | Emite MockUSD y MockETH en carteras externas del escenario. El despliegue local puede asignar esta función al administrador. | Verificar que otro actor carece de permiso de emisión y que emitir en cartera deja intactos los saldos internos de Veyra. |
| Lector | Cualquier cuenta puede consultar la configuración y el estado económico público. | Comparar el estado antes y después de consultar saldo, plan efectivo, deuda proyectada y patrimonio. |

En `src/security/` se concentran las comprobaciones comunes de roles y transferencias. La titularidad y la elegibilidad se verifican también en la operación que conoce la cuenta o el préstamo. La custodia aplica una protección de reentrada común a sus entradas que modifican estado. Ante una transferencia fallida o de importe distinto al esperado, se revierten tanto las partidas como los eventos de la operación. Las pruebas distinguen administrador, tesorería y usuarios incluso cuando una cuenta de prueba podría desempeñar varias funciones. [Suites de verificación](./tests.md#suites-de-foundry)
