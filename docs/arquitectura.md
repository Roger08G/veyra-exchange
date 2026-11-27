# Arquitectura de integración del MVP

El MVP despliega tres contratos en Anvil. `MockUSD` y `MockETH` emiten los activos de prueba. `Veyra` recibe las autorizaciones ERC-20, custodia ambos activos y ejecuta las operaciones. Sus módulos internos permiten que una apertura mueva caja, disponible, garantía, deuda e ingresos en una sola transacción. Las reglas y las unidades de cada partida se mantienen en las [ocho fichas económicas](./economic.md).

La [interfaz pública](../src/interface/IVeyra.sol) reúne los dominios del mercado. El [contrato de custodia](../src/core/Veyra.sol) compone las operaciones. Las bibliotecas `Accounts`, `Loans`, `Pool` y `MarketPrice` gestionan el estado que se describe a continuación.

## Directorios

| Ruta | Contenido |
| --- | --- |
| `src/core/` | Contrato de entrada `Veyra`, inicialización, configuración de la instancia y composición de operaciones. |
| `src/interface/` | Interfaces externas por dominio, sus eventos y errores públicos. `IVeyra` reúne las interfaces del protocolo en una ABI para integradores. |
| `src/modules/` | Lógica interna de cuentas, pagos, planes, fondo, préstamos, liquidaciones, ingresos y precio. Cada partida tiene un único módulo responsable de escribirla. |
| `src/security/` | Comprobaciones de identidad y permisos, protección de reentrada compartida y verificación de transferencias exactas. |
| `src/tokens/` | Implementaciones de MockUSD y MockETH con emisión de prueba restringida. Las participaciones se registran en el fondo. |
| `src/libraries/` | Cálculos puros usados en varios dominios, como productos y cocientes con redondeo explícito. |
| `test/` | Suites `unit/`, `sanity/`, `integration/`, `regression/`, `security/`, `invariant/` y `performance/`. |
| `test/support/` | Actores, despliegue de prueba, dobles de tokens, generadores de operaciones y modelo contable independiente. |
| `script/deploy/` | Despliegue e inicialización de una instancia de Anvil con sus cuentas y parámetros. |
| `script/verify/` | Lectura de la configuración desplegada, ejecución de los escenarios con sus participantes y conciliación de recibos y estado. |
| `.github/workflows/` | Validación de cambios, aceptación sobre Anvil y preparación de entregas reproducibles. |

## Interfaces y propiedad del estado

Las interfaces declaran lo que pueden llamar usuarios, scripts e integradores. La implementación en `core/` comprueba el actor y coordina funciones internas de los módulos. Cada módulo recibe su porción de almacenamiento por referencia. Los módulos no se llaman a través de la ABI pública ni se asignan permisos entre contratos. Los scripts y las pruebas de integración entran por la misma ABI que los usuarios.

Al componer una operación, `core/` pasa a cada módulo solo los datos que necesita. Por ejemplo, para reembolsar participaciones obtiene la deuda proyectada de préstamos y se la pasa al fondo para valorar el reembolso. Préstamos y fondo pueden así compartir la misma valoración sin importarse mutuamente. Las bibliotecas de cálculo operan sobre argumentos explícitos, lo que permite reutilizarlas y probar sus redondeos por separado.

| Interfaz | Entradas y consultas | Módulo responsable |
| --- | --- | --- |
| `IAccounts` | Depositar, retirar y consultar disponible individual y total por token. | Cuentas (EC-01) actualiza ambas cifras en la misma operación, también cuando otro dominio necesita cargar o abonar un disponible. |
| `IPayments` | Pagar en MockUSD desde la cuenta del emisor. | Pagos (EC-02) calcula el reparto con el plan vigente y coordina cuentas e ingresos. El evento identifica el pago. |
| `IPlans` | Contratar, renovar y consultar vigencia y caducidad. | Planes (EC-03) mantiene el periodo del titular y resuelve las condiciones aplicables en un instante. |
| `IPool` | Aportar, reembolsar y consultar caja, patrimonio, participaciones y suministro. | Fondo (EC-04) escribe la caja y las participaciones. Para valorar el fondo usa la deuda proyectada por préstamos al mismo instante. |
| `ILoans` | Abrir, devolver y consultar por ID el titular, estado, condiciones, garantía y deuda. | Préstamos (EC-05 y EC-06) mantiene el índice de activos, el principal, el interés con su resto fraccionario y el bloqueo por posición. Los ID cerrados conservan su identidad. |
| `ILiquidations` | Liquidar una posición identificada desde una cuenta distinta del prestatario. | Liquidaciones (EC-07) calcula elegibilidad, repago, reparto y pérdida. Cuentas, fondo y préstamos aplican sus respectivas variaciones en el mismo cierre. |
| `ITreasury` | Consultar el retenido por token y retirarlo hacia la tesorería fija. | Ingresos (EC-08) registra los cobros de origen y descuenta el importe retirado. Solo las operaciones económicas previstas pueden registrar cobros. |
| `IMarketConfig` | Leer activos, permisos, parámetros, precio y fecha. Publicar precio y cambiar la habilitación de los activos configurados. | Configuración conserva las direcciones, parámetros fijos y habilitación. El módulo de precio registra cada publicación con el tiempo del bloque. |

El adaptador de transferencias en `security/` usa la interfaz ERC-20 y comprueba la variación real de balances. Solo el depósito y las retiradas de usuario o tesorería lo necesitan. Las operaciones internas liquidan sobre saldos ya custodiados. El código de `src/` no depende de scripts, pruebas ni funciones de emisión de los mocks. Las interfaces públicas tampoco exponen primitivas internas como acreditar un saldo, declarar una pérdida o registrar una comisión. [Permisos por actor](./security.md#permisos-por-actor)

Para integrarse por ABI, `deposit(token, amount)` requiere una autorización ERC-20 previa a la custodia. `supply(amount)`, `pay(recipient, gross)` y `repay(id, amount)` utilizan el disponible interno en MockUSD. `redeem(shares)` abona MockUSD al disponible del proveedor. `repayAll(id)` calcula el importe de cierre al ejecutar. Las cantidades de MockUSD y participaciones usan 6 decimales, y las de MockETH usan 18. El campo `status` de `loan(id)` vale 1 para un préstamo activo, 2 para uno devuelto y 3 para uno liquidado. La consulta de un ID inexistente revierte.

### Ejemplo de integración de una apertura

1. `Veyra` identifica al prestatario por el remitente. Planes entrega las condiciones vigentes y el módulo de precio aporta la última publicación válida.
2. Préstamos comprueba que el titular puede abrir, que su garantía permite el principal solicitado y que se cumplen el límite de una posición activa y la disponibilidad de fondos.
3. Fondo descuenta el principal bruto de caja. Cuentas descuenta el MockETH disponible y acredita el MockUSD neto. Préstamos registra el bloqueo, el ID y la deuda con las condiciones de apertura. Ingresos contabiliza la comisión efectivamente cobrada.
4. El evento de apertura identifica la operación y el cobro. La integración comprueba que caja, disponible e ingresos cuadran con el bruto, que la custodia física de ambos tokens permanece constante y que la nueva deuda mantiene el patrimonio del fondo en ese instante. [Regla de apertura](./chains/ec-05-prestamos-y-garantias.md)

## Orden de integración

| Hito | Entrega verificable |
| --- | --- |
| 1. Instancia y custodia | Desplegar los mocks y la custodia. Leer parámetros, roles y decimales. Depositar y retirar ambos tokens con el plan básico, contabilizar la comisión y retirarla como tesorería. Cubrir EC-01, la tarifa básica de EC-03 y el registro y retiro de EC-08. |
| 2. Planes y pagos | Contratar y renovar desde un disponible real. Pagar antes y en el instante de caducidad. Conciliar neto, cuota y comisiones de EC-02, EC-03 y EC-08. |
| 3. Fondo | Aportar y reembolsar con dos proveedores. Verificar caja, disponibles, participaciones y redondeo de EC-04 con el fondo vacío y con capital previo. |
| 4. Crédito | Abrir, proyectar deuda, devolver parcialmente y cerrar. Comprobar el bloqueo, el patrimonio con varios préstamos y la devolución con precio caducado (EC-04 a EC-06). |
| 5. Liquidación | Ejecutar un cierre con pérdida y otro con sobrante en las instancias previstas. Conciliar el cierre de EC-07 con la caja, los disponibles, la garantía y el patrimonio. |
| 6. Aceptación | Repetir el despliegue en instancias limpias, comparar los resultados económicos y comprobar permisos, regresiones y presupuestos de gas. Conservar la evidencia para el mismo commit. |

El [plan de pruebas](./tests.md) fija los resultados de aceptación. El [procedimiento de CI/CD](./deploy.md#entrega-continua-en-anvil) define cuándo se ejecutan y qué evidencia permite preparar una entrega.
